#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$ROOT_DIR/healthbridge_mobile"
VENV_PYTHON="$ROOT_DIR/.venv/bin/python"
BACKEND_PORT="${BACKEND_PORT:-8001}"
DEVICE_ID="${1:-}"

detect_lan_ip() {
  local ip

  ip="$(ipconfig getifaddr en0 2>/dev/null || true)"
  if [[ -n "$ip" ]]; then
    printf '%s\n' "$ip"
    return 0
  fi

  ip="$(ipconfig getifaddr en1 2>/dev/null || true)"
  if [[ -n "$ip" ]]; then
    printf '%s\n' "$ip"
    return 0
  fi

  ip="$(ifconfig | awk '/inet (192\.168|10\.|172\.(1[6-9]|2[0-9]|3[0-1]))/ {print $2; exit}')"
  if [[ -n "$ip" ]]; then
    printf '%s\n' "$ip"
    return 0
  fi

  return 1
}

wait_for_backend() {
  local attempt
  for attempt in {1..10}; do
    if curl -sf "http://127.0.0.1:${BACKEND_PORT}/api/" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

if [[ ! -x "$VENV_PYTHON" ]]; then
  echo "Virtual environment not found at $VENV_PYTHON" >&2
  exit 1
fi

LAN_IP="$(detect_lan_ip || true)"
if [[ -z "$LAN_IP" ]]; then
  echo "Could not detect a LAN IP address on this Mac." >&2
  exit 1
fi

LOG_DIR="$ROOT_DIR/.tmp"
LOG_FILE="$LOG_DIR/healthbridge_backend.log"
PID_FILE="$LOG_DIR/healthbridge_backend.pid"
mkdir -p "$LOG_DIR"

if ! curl -sf "http://127.0.0.1:${BACKEND_PORT}/api/" >/dev/null 2>&1; then
  echo "Starting Django backend on 0.0.0.0:${BACKEND_PORT} ..."
  (
    cd "$ROOT_DIR"
    DJANGO_DEV_LAN_HOST="$LAN_IP" \
      nohup "$VENV_PYTHON" manage.py runserver "0.0.0.0:${BACKEND_PORT}" \
      >"$LOG_FILE" 2>&1 &
    echo $! >"$PID_FILE"
  )

  if ! wait_for_backend; then
    echo "Backend did not start correctly. Check $LOG_FILE" >&2
    exit 1
  fi
else
  echo "Backend already running on port ${BACKEND_PORT}."
fi

API_URL="http://${LAN_IP}:${BACKEND_PORT}/api"
echo "Using LAN API URL: ${API_URL}"

cd "$MOBILE_DIR"
if [[ -n "$DEVICE_ID" ]]; then
  flutter run -d "$DEVICE_ID" --dart-define="DEV_LAN_API_BASE_URL=${API_URL}"
else
  flutter run --dart-define="DEV_LAN_API_BASE_URL=${API_URL}"
fi
