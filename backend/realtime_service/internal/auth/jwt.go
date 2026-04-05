package auth

import (
	"errors"
	"fmt"

	"github.com/golang-jwt/jwt/v5"
)

var (
	ErrInvalidToken = errors.New("невалидный или истёкший токен")
	ErrWrongType    = errors.New("ожидается access-токен")
)

// Claims - данные из JWT-токена (тот же формат что у business_service)
type Claims struct {
	UserID   int    `json:"-"`
	Role     string `json:"role"`
	TokenType string `json:"type"`
	// outlet_id присутствует только у outlet_manager
	OutletID *int `json:"outlet_id,omitempty"`

	jwt.RegisteredClaims
}

type Parser struct {
	secret []byte
}

func NewParser(secret string) *Parser {
	return &Parser{secret: []byte(secret)}
}

func (p *Parser) Parse(tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("неожиданный алгоритм подписи: %v", t.Header["alg"])
		}
		return p.secret, nil
	})
	if err != nil {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	if claims.TokenType != "access" {
		return nil, ErrWrongType
	}

	// sub хранится как строка - парсим в int
	sub, err := claims.GetSubject()
	if err != nil {
		return nil, ErrInvalidToken
	}
	userID := 0
	if _, err := fmt.Sscanf(sub, "%d", &userID); err != nil {
		return nil, ErrInvalidToken
	}
	claims.UserID = userID

	return claims, nil
}
