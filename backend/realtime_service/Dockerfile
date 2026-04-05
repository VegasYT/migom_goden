FROM golang:1.23-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o realtime_service ./cmd/main.go


FROM alpine:3.20

WORKDIR /app

COPY --from=builder /app/realtime_service .

EXPOSE 8080

CMD ["./realtime_service"]
