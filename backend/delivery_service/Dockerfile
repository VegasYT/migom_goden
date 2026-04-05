FROM python:3.12-slim AS builder

WORKDIR /app

RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt


FROM python:3.12-slim

WORKDIR /app

COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels /wheels/*

COPY ./app ./app
COPY ./migrations ./migrations
COPY alembic.ini .

EXPOSE 8001

CMD alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8001 --log-level info
