package auth

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"
)

// ErrInvalidToken - business_service не принял токен: истёк, выдан не для Мигома
// или пользователя нет в Мигоме.
var ErrInvalidToken = errors.New("невалидный или истёкший токен")

// Identity - пользователь Мигома, которому выдан токен Keycloak.
type Identity struct {
	UserID int    `json:"user_id"`
	Role   string `json:"role"`
	// OutletID есть только у outlet_manager
	OutletID *int `json:"outlet_id"`
}

// Resolver узнаёт у business_service, кто владелец токена. Сам токен realtime не разбирает:
// правило проверки одно на все сервисы, а id пользователя Мигома в токене Keycloak нет.
type Resolver struct {
	url    string
	client *http.Client
}

func NewResolver(businessURL string) *Resolver {
	return &Resolver{
		url:    businessURL + "/api/v1/auth/identity",
		client: &http.Client{Timeout: 5 * time.Second},
	}
}

func (r *Resolver) Resolve(ctx context.Context, token string) (*Identity, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, r.url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := r.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("business_service недоступен: %w", err)
	}
	defer resp.Body.Close()

	switch resp.StatusCode {
	case http.StatusOK:
		var identity Identity
		if err := json.NewDecoder(resp.Body).Decode(&identity); err != nil {
			return nil, fmt.Errorf("ответ business_service: %w", err)
		}
		return &identity, nil
	// 403 - пользователь заблокирован
	case http.StatusUnauthorized, http.StatusForbidden:
		return nil, ErrInvalidToken
	default:
		return nil, fmt.Errorf("business_service ответил %d", resp.StatusCode)
	}
}
