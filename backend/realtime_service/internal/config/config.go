package config

import (
	"os"
	"strings"
)

type Config struct {
	Port string
	// BusinessURL - business_service, который по токену Keycloak называет пользователя Мигома
	BusinessURL  string
	KafkaBrokers []string
	KafkaGroupID string
}

func Load() *Config {
	return &Config{
		Port:         getEnv("PORT", "8080"),
		BusinessURL:  getEnv("BUSINESS_URL", "http://business_service:8000"),
		KafkaBrokers: strings.Split(getEnv("KAFKA_BROKERS", "kafka:9092"), ","),
		KafkaGroupID: getEnv("KAFKA_GROUP_ID", "realtime_service"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
