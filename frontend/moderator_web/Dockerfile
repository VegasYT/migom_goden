# Сборка кабинета модератора и раздача статики. Сборка: docker build frontend/moderator_web
FROM node:22-alpine AS build
WORKDIR /src
RUN corepack enable
# зависимости отдельным слоем: он переиспользуется, пока не менялся pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
# Vite подставляет VITE_API_URL при сборке: адрес API вшивается в бандл
ARG VITE_API_URL
# Keycloak Goden для единого входа; без аргумента - локальный http://localhost:8180
ARG VITE_KEYCLOAK_URL
ENV VITE_API_URL=$VITE_API_URL VITE_KEYCLOAK_URL=$VITE_KEYCLOAK_URL
RUN pnpm build

FROM caddy:2.10-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /src/dist /srv
