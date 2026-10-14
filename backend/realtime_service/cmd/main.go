package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/migom/realtime_service/internal/auth"
	"github.com/migom/realtime_service/internal/config"
	"github.com/migom/realtime_service/internal/handler"
	"github.com/migom/realtime_service/internal/hub"
	"github.com/migom/realtime_service/internal/kafka"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	cfg := config.Load()

	h := hub.New()
	go h.Run()

	// Kafka consumer - запускаем с отменяемым контекстом
	consumer := kafka.NewConsumer(cfg.KafkaBrokers, cfg.KafkaGroupID, h)
	consumerCtx, cancelConsumer := context.WithCancel(context.Background())
	go consumer.Run(consumerCtx)

	resolver := auth.NewResolver(cfg.BusinessURL)
	wsHandler := handler.NewWSHandler(h, resolver)

	mux := http.NewServeMux()
	mux.Handle("/ws", wsHandler)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		stats := h.Stats()
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, `{"status":"ok","connections":%d,"unique_users":%d}`,
			stats.Connections, stats.UniqueUsers)
	})

	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: mux,
	}

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		slog.Info("сервер запущен", "port", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("ошибка сервера", "err", err)
			os.Exit(1)
		}
	}()

	<-stop
	slog.Info("завершение работы...")

	// Останавливаем consumer
	cancelConsumer()

	// Graceful shutdown HTTP
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		slog.Error("ошибка при завершении", "err", err)
	}

	slog.Info("сервер остановлен")
}
