package hub

import (
	"encoding/json"
	"testing"
)

func ptr(i int) *int { return &i }

// fakeClient создаёт клиента с буферизованным каналом без реального WS
func fakeClient(h *Hub, userID int, role string, outletID *int) *Client {
	c := newClient(h, nil, userID, role, outletID)
	h.addClient(c)
	return c
}

func TestDispatch_OrderCreated_GoesToOutlet(t *testing.T) {
	h := New()
	manager := fakeClient(h, 10, "outlet_manager", ptr(5))
	other := fakeClient(h, 20, "outlet_manager", ptr(9))

	payload, _ := json.Marshal(map[string]any{"order_id": 1, "outlet_id": 5})
	h.dispatch(Event{Topic: "order.created", Payload: payload})

	if len(manager.send) != 1 {
		t.Error("менеджер точки 5 должен получить событие")
	}
	if len(other.send) != 0 {
		t.Error("менеджер точки 9 не должен получить событие")
	}
}

func TestDispatch_OrderStatusUpdated_GoesToCustomerAndOutlet(t *testing.T) {
	h := New()
	customer := fakeClient(h, 1, "customer", nil)
	outlet := fakeClient(h, 2, "outlet_manager", ptr(3))

	payload, _ := json.Marshal(map[string]any{
		"order_id":    42,
		"status":      "assembling",
		"customer_id": 1,
		"outlet_id":   3,
	})
	h.dispatch(Event{Topic: "order.status_updated", Payload: payload})

	if len(customer.send) != 1 {
		t.Error("покупатель должен получить обновление статуса")
	}
	if len(outlet.send) != 1 {
		t.Error("менеджер точки должен получить обновление статуса")
	}
}

func TestDispatch_UnknownTopic_NoSend(t *testing.T) {
	h := New()
	c := fakeClient(h, 1, "customer", nil)

	payload, _ := json.Marshal(map[string]any{"foo": "bar"})
	h.dispatch(Event{Topic: "unknown.topic", Payload: payload})

	if len(c.send) != 0 {
		t.Error("неизвестный топик не должен ничего отправлять")
	}
}

func TestRemoveClient(t *testing.T) {
	h := New()
	c := fakeClient(h, 1, "customer", nil)

	if h.totalClients() != 1 {
		t.Fatalf("ожидается 1 клиент, получено %d", h.totalClients())
	}

	h.removeClient(c)

	if h.totalClients() != 0 {
		t.Errorf("ожидается 0 клиентов после удаления, получено %d", h.totalClients())
	}
}

func TestIntField(t *testing.T) {
	p := map[string]any{"id": float64(42)}
	v, ok := intField(p, "id")
	if !ok || v != 42 {
		t.Errorf("ожидается 42, получено %d, ok=%v", v, ok)
	}

	_, ok = intField(p, "missing")
	if ok {
		t.Error("отсутствующий ключ должен возвращать ok=false")
	}
}
