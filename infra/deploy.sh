#!/bin/sh
# Выкладка Мигома на сервере: привести рабочую копию к коммиту и перезапустить изменившиеся сервисы.
# Запускает GitHub Actions по SSH; вручную: sh infra/deploy.sh [коммит], по умолчанию origin/master.
# Goden должен быть уже выложен: Мигом подключается к его сети goden-prod_default.
set -eu

# Выкладки Goden и Мигома на одном сервере идут по очереди: две сборки сразу не помещаются в память
exec 9>/tmp/server-deploy.lock
flock 9

cd "$(dirname "$0")/.."
git fetch --quiet origin
# Рабочая копия сервера не редактируется вручную: локальные правки отслеживаемых файлов
# здесь отбрасываются. infra/.env в репозиторий не входит и сохраняется.
git checkout --quiet --force -B master "${1:-origin/master}"

compose="docker compose -f infra/compose.prod.yaml"
# Кабинеты собираются по очереди: вместе со сборкой остальных сервисов им не хватает памяти сервера.
# Команда up ниже берёт уже собранные слои из кеша.
$compose build migom-owner-web
$compose build migom-admin-web
$compose up -d --build --remove-orphans
# nginx узнаёт адреса сервисов только при загрузке конфига: пересозданный сервис получает новый IP
$compose exec -T migom-nginx nginx -s reload
# старые слои после пересборки, иначе диск сервера заполнится
docker image prune --force > /dev/null
git log --oneline -1
