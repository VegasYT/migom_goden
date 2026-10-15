# Сборка кабинета владельца и раздача статики. Сборка: docker build frontend/owner_web
FROM node:22-alpine AS build
WORKDIR /src
RUN corepack enable
# зависимости отдельным слоем: он переиспользуется, пока не менялся pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
# Vite подставляет переменные VITE_* при сборке: адрес API и ключ Яндекс Карт вшиваются в бандл
ARG VITE_API_URL
ARG VITE_YANDEX_MAPS_API_KEY
ENV VITE_API_URL=$VITE_API_URL VITE_YANDEX_MAPS_API_KEY=$VITE_YANDEX_MAPS_API_KEY
RUN pnpm build

FROM caddy:2.10-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /src/dist /srv
