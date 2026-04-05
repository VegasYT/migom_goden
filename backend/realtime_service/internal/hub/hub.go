package hub

import (
	"encoding/json"
	"log/slog"
	"sync"

	"github.com/gorilla/websocket"
)

// Event - событие из Kafka
type Event struct {
	Topic   string          `json:"topic"`
	Payload json.RawMessage `json:"payload"`
}

// Hub управляет всеми WebSocket-соединениями и маршрутизирует события
type Hub struct {
	mu sync.RWMutex

	// Индексы для быстрой маршрутизации
	byUserID   map[int][]*Client
	byOutletID map[int][]*Client

	register   chan *Client
	unregister chan *Client
	route      chan Event
}

func New() *Hub {
	return &Hub{
		byUserID:   make(map[int][]*Client),
		byOutletID: make(map[int][]*Client),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		route:      make(chan Event, 256),
	}
}

// Run запускает основной цикл обработки событий - вызывать в горутине
func (h *Hub) Run() {
	for {
		select {
		case c := <-h.register:
			h.addClient(c)
			slog.Info("клиент подключился",
				"user_id", c.UserID,
				"role", c.Role,
				"total", h.totalClients(),
			)

		case c := <-h.unregister:
			h.removeClient(c)
			slog.Info("клиент отключился",
				"user_id", c.UserID,
				"total", h.totalClients(),
			)

		case event := <-h.route:
			h.dispatch(event)
		}
	}
}

// Register регистрирует нового клиента и запускает его горутины
func (h *Hub) Register(conn *websocket.Conn, userID int, role string, outletID *int) {
	c := newClient(h, conn, userID, role, outletID)
	h.register <- c
	go c.writePump()
	go c.readPump()
}

// RouteEvent принимает событие из Kafka и направляет его в цикл обработки
func (h *Hub) RouteEvent(topic string, payload json.RawMessage) {
	h.route <- Event{Topic: topic, Payload: payload}
}

// Stats возвращает метрики активных соединений
type Stats struct {
	Connections int `json:"connections"`
	UniqueUsers int `json:"unique_users"`
}

func (h *Hub) Stats() Stats {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return Stats{
		Connections: h.totalClients(),
		UniqueUsers: len(h.byUserID),
	}
}

// TotalClients возвращает количество активных соединений (для health/metrics)
func (h *Hub) TotalClients() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return h.totalClients()
}

// --- внутренние методы ---

func (h *Hub) addClient(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.byUserID[c.UserID] = append(h.byUserID[c.UserID], c)
	if c.OutletID != nil {
		h.byOutletID[*c.OutletID] = append(h.byOutletID[*c.OutletID], c)
	}
}

func (h *Hub) removeClient(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	h.byUserID[c.UserID] = removeFrom(h.byUserID[c.UserID], c)
	if len(h.byUserID[c.UserID]) == 0 {
		delete(h.byUserID, c.UserID)
	}

	if c.OutletID != nil {
		h.byOutletID[*c.OutletID] = removeFrom(h.byOutletID[*c.OutletID], c)
		if len(h.byOutletID[*c.OutletID]) == 0 {
			delete(h.byOutletID, *c.OutletID)
		}
	}

	close(c.send)
}

func (h *Hub) dispatch(event Event) {
	msg, err := json.Marshal(event)
	if err != nil {
		slog.Error("ошибка сериализации события", "topic", event.Topic, "err", err)
		return
	}

	// Парсим payload для маршрутизации
	var p map[string]any
	if err := json.Unmarshal(event.Payload, &p); err != nil {
		slog.Error("ошибка парсинга payload", "topic", event.Topic, "err", err)
		return
	}

	h.mu.RLock()
	defer h.mu.RUnlock()

	switch event.Topic {

	case "order.created":
		// → outlet (owner и manager точки)
		if outletID, ok := intField(p, "outlet_id"); ok {
			h.sendToOutlet(outletID, msg)
		}

	case "order.status_updated":
		// → customer (по customer_id), outlet (по outlet_id), courier (по courier_id)
		slog.Info("dispatch order.status_updated", "payload", p)
		if customerID, ok := intField(p, "customer_id"); ok {
			clients := h.byUserID[customerID]
			slog.Info("отправка клиенту", "customer_id", customerID, "connected_clients", len(clients))
			h.sendToUser(customerID, msg)
		}
		if outletID, ok := intField(p, "outlet_id"); ok {
			h.sendToOutlet(outletID, msg)
		}
		if courierUserID, ok := intField(p, "courier_user_id"); ok {
			h.sendToUser(courierUserID, msg)
		}

	case "courier.assigned":
		// → customer (по customer_id), outlet (по outlet_id)
		if customerID, ok := intField(p, "customer_id"); ok {
			h.sendToUser(customerID, msg)
		}
		if outletID, ok := intField(p, "outlet_id"); ok {
			h.sendToOutlet(outletID, msg)
		}

	case "courier.location_updated":
		// → customer чей активный заказ везёт этот курьер
		// payload содержит customer_id если delivery_service его передаёт
		if customerID, ok := intField(p, "customer_id"); ok {
			h.sendToUser(customerID, msg)
		}

	case "courier.order_offer":
		// → конкретному курьеру (по courier_user_id)
		if courierUserID, ok := intField(p, "courier_user_id"); ok {
			h.sendToUser(courierUserID, msg)
		}

	default:
		slog.Debug("неизвестный топик, игнорируем", "topic", event.Topic)
	}
}

func (h *Hub) sendToUser(userID int, msg []byte) {
	for _, c := range h.byUserID[userID] {
		select {
		case c.send <- msg:
		default:
			slog.Warn("буфер клиента переполнен, пропускаем", "user_id", userID)
		}
	}
}

func (h *Hub) sendToOutlet(outletID int, msg []byte) {
	for _, c := range h.byOutletID[outletID] {
		select {
		case c.send <- msg:
		default:
			slog.Warn("буфер клиента переполнен, пропускаем", "outlet_id", outletID)
		}
	}
}

func (h *Hub) totalClients() int {
	total := 0
	for _, clients := range h.byUserID {
		total += len(clients)
	}
	return total
}

func removeFrom(slice []*Client, target *Client) []*Client {
	result := slice[:0]
	for _, c := range slice {
		if c != target {
			result = append(result, c)
		}
	}
	return result
}

// intField безопасно извлекает int из map[string]any (json.Number или float64)
func intField(p map[string]any, key string) (int, bool) {
	v, ok := p[key]
	if !ok {
		return 0, false
	}
	switch val := v.(type) {
	case float64:
		return int(val), true
	case json.Number:
		n, err := val.Int64()
		if err != nil {
			return 0, false
		}
		return int(n), true
	}
	return 0, false
}
