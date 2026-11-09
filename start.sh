#!/usr/bin/env bash
# Sirve la app en http://127.0.0.1:5173/
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${PORT:-5173}"
URL="http://127.0.0.1:${PORT}/"

if [ "${NO_OPEN:-0}" != "1" ] && command -v xdg-open >/dev/null 2>&1; then
  (sleep 1; xdg-open "$URL" >/dev/null 2>&1 || true) &
fi

echo "ERD local: $URL"
echo "Ejemplo sintético: $APP_DIR/examples/demo-150-mysql.sql"
echo "Ctrl+C para detener el servidor."
echo

cd "$APP_DIR"
exec python3 -m http.server "$PORT" --bind 127.0.0.1
