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
	// Разрешаем все origins - контроль доступа через JWT
	CheckOrigin: func(r *http.Request) bool { return true },
}

type WSHandler struct {
	hub    *hub.Hub
	parser *auth.Parser
}

func NewWSHandler(h *hub.Hub, p *auth.Parser) *WSHandler {
	return &WSHandler{hub: h, parser: p}
}

func (wh *WSHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Токен передаётся как query-параметр: /ws?token=<JWT>
	token := r.URL.Query().Get("token")
	if token == "" {
		http.Error(w, "token обязателен", http.StatusUnauthorized)
		return
	}

	claims, err := wh.parser.Parse(token)
	if err != nil {
		if errors.Is(err, auth.ErrWrongType) {
			http.Error(w, "ожидается access-токен", http.StatusUnauthorized)
		} else {
			http.Error(w, "невалидный токен", http.StatusUnauthorized)
		}
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		slog.Warn("ошибка upgrade", "err", err)
		return
	}

	slog.Info("новое WS-соединение", "user_id", claims.UserID, "role", claims.Role)
	wh.hub.Register(conn, claims.UserID, claims.Role, claims.OutletID)
}
