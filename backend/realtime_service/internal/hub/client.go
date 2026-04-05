package hub

import (
	"log/slog"
	"time"

	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

// Client - одно WebSocket-соединение
type Client struct {
	hub      *Hub
	conn     *websocket.Conn
	send     chan []byte

	UserID   int
	Role     string
	OutletID *int // только для outlet_manager
}

func newClient(hub *Hub, conn *websocket.Conn, userID int, role string, outletID *int) *Client {
	return &Client{
		hub:      hub,
		conn:     conn,
		send:     make(chan []byte, 64),
		UserID:   userID,
		Role:     role,
		OutletID: outletID,
	}
}

// readPump читает входящие сообщения (только ping/pong - клиент не шлёт данные)
func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, _, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				slog.Warn("ws read error", "user_id", c.UserID, "err", err)
			}
			break
		}
	}
}

// writePump отправляет события клиенту и держит соединение живым через ping
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case msg, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// hub закрыл канал
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				slog.Warn("ws write error", "user_id", c.UserID, "err", err)
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
