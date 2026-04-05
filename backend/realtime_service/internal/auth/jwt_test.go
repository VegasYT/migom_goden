package auth_test

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/migom/realtime_service/internal/auth"
)

const testSecret = "test_secret"

func makeToken(userID int, role string, outletID *int, tokenType string, expired bool) string {
	exp := time.Now().Add(time.Hour)
	if expired {
		exp = time.Now().Add(-time.Hour)
	}

	claims := jwt.MapClaims{
		"sub":  "1",
		"role": role,
		"type": tokenType,
		"exp":  exp.Unix(),
	}
	if userID != 0 {
		claims["sub"] = string(rune('0' + userID))
	}
	if outletID != nil {
		claims["outlet_id"] = *outletID
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, _ := token.SignedString([]byte(testSecret))
	return signed
}

func TestParse_ValidCustomer(t *testing.T) {
	p := auth.NewParser(testSecret)
	tok := makeToken(1, "customer", nil, "access", false)
	claims, err := p.Parse(tok)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if claims.Role != "customer" {
		t.Errorf("expected role=customer, got %s", claims.Role)
	}
	if claims.OutletID != nil {
		t.Errorf("expected nil outlet_id for customer")
	}
}

func TestParse_ValidManager(t *testing.T) {
	p := auth.NewParser(testSecret)
	outletID := 42
	tok := makeToken(1, "outlet_manager", &outletID, "access", false)
	claims, err := p.Parse(tok)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if claims.Role != "outlet_manager" {
		t.Errorf("expected role=outlet_manager, got %s", claims.Role)
	}
}

func TestParse_ExpiredToken(t *testing.T) {
	p := auth.NewParser(testSecret)
	tok := makeToken(1, "customer", nil, "access", true)
	_, err := p.Parse(tok)
	if err == nil {
		t.Fatal("expected error for expired token")
	}
}

func TestParse_RefreshToken(t *testing.T) {
	p := auth.NewParser(testSecret)
	tok := makeToken(1, "customer", nil, "refresh", false)
	_, err := p.Parse(tok)
	if err != auth.ErrWrongType {
		t.Fatalf("expected ErrWrongType, got %v", err)
	}
}

func TestParse_WrongSecret(t *testing.T) {
	p := auth.NewParser("wrong_secret")
	tok := makeToken(1, "customer", nil, "access", false)
	_, err := p.Parse(tok)
	if err == nil {
		t.Fatal("expected error for wrong secret")
	}
}
