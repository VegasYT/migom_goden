"""Настройки для тестов без базы и сети: читаются при импорте app.config, поэтому задаются здесь, до тестов."""
import os

os.environ.update({
    "DB_HOST": "-", "DB_NAME": "-", "DB_USER": "-", "DB_PASSWORD": "-",
    "KEYCLOAK_REALM_URL": "http://keycloak/realms/goden",
    "KEYCLOAK_ISSUER": "http://localhost:8180/realms/goden",
    "GODEN_API_URL": "http://goden/api/v1",
    "GODEN_CLIENT_SECRET": "integration-secret",
})
