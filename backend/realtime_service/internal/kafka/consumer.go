package kafka

import (
	"context"
	"encoding/json"
	"log/slog"
	"time"

	"github.com/segmentio/kafka-go"
	"github.com/migom/realtime_service/internal/hub"
)

var topics = []string{
	"order.created",
	"order.status_updated",
	"courier.assigned",
	"courier.location_updated",
	"courier.order_offer",
}

type Consumer struct {
	readers []*kafka.Reader
	hub     *hub.Hub
}

func NewConsumer(brokers []string, groupID string, h *hub.Hub) *Consumer {
	readers := make([]*kafka.Reader, 0, len(topics))
	for _, topic := range topics {
		r := kafka.NewReader(kafka.ReaderConfig{
			Brokers:        brokers,
			GroupID:        groupID,
			Topic:          topic,
			MinBytes:       1,
			MaxBytes:       1 << 20, // 1 MB
			MaxWait:        500 * time.Millisecond,
			CommitInterval: time.Second,
			StartOffset:    kafka.LastOffset, // читаем только новые сообщения
		})
		readers = append(readers, r)
	}
	return &Consumer{readers: readers, hub: h}
}

// Run запускает горутину-читатель на каждый топик. Блокируется до отмены контекста.
func (c *Consumer) Run(ctx context.Context) {
	for _, r := range c.readers {
		go c.readTopic(ctx, r)
	}
	<-ctx.Done()
	c.close()
}

func (c *Consumer) readTopic(ctx context.Context, r *kafka.Reader) {
	slog.Info("kafka consumer запущен", "topic", r.Config().Topic)
	for {
		msg, err := r.ReadMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				return // контекст отменён - нормальное завершение
			}
			slog.Error("ошибка чтения из kafka", "topic", r.Config().Topic, "err", err)
			time.Sleep(time.Second)
			continue
		}

		slog.Info("получено сообщение из kafka", "topic", msg.Topic, "offset", msg.Offset)

		// Валидируем что payload - корректный JSON
		if !json.Valid(msg.Value) {
			slog.Warn("некорректный JSON в сообщении", "topic", msg.Topic)
			continue
		}

		c.hub.RouteEvent(msg.Topic, json.RawMessage(msg.Value))
	}
}

func (c *Consumer) close() {
	for _, r := range c.readers {
		if err := r.Close(); err != nil {
			slog.Warn("ошибка закрытия kafka reader", "topic", r.Config().Topic, "err", err)
		}
	}
	slog.Info("kafka consumers остановлены")
}
