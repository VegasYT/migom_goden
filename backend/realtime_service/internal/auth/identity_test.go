package auth_test

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/migom/realtime_service/internal/auth"
)

func TestResolve(t *testing.T) {
	tests := []struct {
		name    string
		status  int
		body    string
		want    *auth.Identity
		invalid bool
	}{
		{name: "manager", status: http.StatusOK, body: `{"user_id":7,"role":"outlet_manager","outlet_id":3}`,
			want: &auth.Identity{UserID: 7, Role: "outlet_manager", OutletID: ptr(3)}},
		{name: "courier", status: http.StatusOK, body: `{"user_id":4,"role":"courier","outlet_id":null}`,
			want: &auth.Identity{UserID: 4, Role: "courier"}},
		{name: "rejected token", status: http.StatusUnauthorized, invalid: true},
		{name: "blocked user", status: http.StatusForbidden, invalid: true},
		{name: "business down", status: http.StatusBadGateway},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if r.URL.Path != "/api/v1/auth/identity" || r.Header.Get("Authorization") != "Bearer token-1" {
					t.Errorf("unexpected request %s %q", r.URL.Path, r.Header.Get("Authorization"))
				}
				w.WriteHeader(tt.status)
				_, _ = w.Write([]byte(tt.body))
			}))
			defer server.Close()

			got, err := auth.NewResolver(server.URL).Resolve(context.Background(), "token-1")

			switch {
			case tt.want != nil:
				if err != nil {
					t.Fatalf("unexpected error: %v", err)
				}
				if got.UserID != tt.want.UserID || got.Role != tt.want.Role || !sameOutlet(got.OutletID, tt.want.OutletID) {
					t.Fatalf("got %+v, want %+v", got, tt.want)
				}
			case tt.invalid:
				if !errors.Is(err, auth.ErrInvalidToken) {
					t.Fatalf("want ErrInvalidToken, got %v", err)
				}
			default:
				if err == nil || errors.Is(err, auth.ErrInvalidToken) {
					t.Fatalf("want an availability error, got %v", err)
				}
			}
		})
	}
}

func ptr(v int) *int { return &v }

func sameOutlet(a, b *int) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}
