package handler

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/gorilla/websocket"
	"github.com/migom/realtime_service/internal/auth"
	"github.com/migom/realtime_service/internal/hub"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// Разрешаем все origins - контроль доступа через токен Keycloak
	CheckOrigin: func(r *http.Request) bool { return true },
}

type WSHandler struct {
	hub      *hub.Hub
	resolver *auth.Resolver
}

func NewWSHandler(h *hub.Hub, r *auth.Resolver) *WSHandler {
	return &WSHandler{hub: h, resolver: r}
}

func (wh *WSHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Токен передаётся как query-параметр: /ws?token=<access-токен Keycloak>
	token := r.URL.Query().Get("token")
	if token == "" {
		http.Error(w, "token обязателен", http.StatusUnauthorized)
		return
	}

	identity, err := wh.resolver.Resolve(r.Context(), token)
	if err != nil {
		if errors.Is(err, auth.ErrInvalidToken) {
			http.Error(w, "невалидный токен", http.StatusUnauthorized)
		} else {
			slog.Warn("не удалось проверить токен", "err", err)
			http.Error(w, "проверка токена временно недоступна", http.StatusServiceUnavailable)
		}
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		slog.Warn("ошибка upgrade", "err", err)
		return
	}

	slog.Info("новое WS-соединение", "user_id", identity.UserID, "role", identity.Role)
	wh.hub.Register(conn, identity.UserID, identity.Role, identity.OutletID)
}
