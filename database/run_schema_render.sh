#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT"

if [ -d ".venv" ]; then
    PYTHON_CMD=".venv/bin/python"
else
    PYTHON_CMD="python3"
fi

DB_URL="${1:-${RENDER_DATABASE_URL:-${DATABASE_URL:-}}}"

if [ -n "$DB_URL" ]; then
    if [[ "$DB_URL" == *"USER"* || "$DB_URL" == *"PASSWORD"* || "$DB_URL" == *"HOST"* || "$DB_URL" == *"PORT"* || "$DB_URL" == *"DBNAME"* || "$DB_URL" == *"<"* || "$DB_URL" == *">"* ]]; then
        echo "❌ Detected placeholder values in database URL."
        echo "Use the real External Database URL from Render dashboard."
        exit 1
    fi

    DB_EXPORTS="$($PYTHON_CMD - "$DB_URL" <<'PY'
import shlex
import sys
from urllib.parse import urlparse, parse_qs

url = sys.argv[1]
parsed = urlparse(url)
if parsed.scheme not in ("postgres", "postgresql"):
    raise SystemExit("DATABASE URL must start with postgres:// or postgresql://")

try:
    parsed_port = parsed.port
except ValueError as exc:
    raise SystemExit(f"Invalid database URL port: {exc}")

host = parsed.hostname or ""
port = str(parsed_port or 5432)
user = parsed.username or ""
password = parsed.password or ""
database = (parsed.path or "").lstrip("/")
query = parse_qs(parsed.query or "")
sslmode = (query.get("sslmode", [""])[0] or "require")

if not host or not user or not password or not database:
    raise SystemExit("DATABASE URL is missing required host/user/password/database values")

exports = {
    "PGHOST": host,
    "PGPORT": port,
    "PGUSER": user,
    "PGPASSWORD": password,
    "PGDATABASE": database,
    "PGSSLMODE": sslmode,
}
for key, value in exports.items():
    print(f"export {key}={shlex.quote(value)}")
PY
)"
    eval "$DB_EXPORTS"
fi

: "${PGHOST:?PGHOST is required}"
: "${PGPORT:?PGPORT is required}"
: "${PGUSER:?PGUSER is required}"
: "${PGPASSWORD:?PGPASSWORD is required}"
: "${PGDATABASE:?PGDATABASE is required}"
export PGSSLMODE="${PGSSLMODE:-require}"

if [ "$PGHOST" = "localhost" ] || [ "$PGHOST" = "127.0.0.1" ]; then
    echo "❌ PGHOST resolved to localhost. For Render, set RENDER_DATABASE_URL or pass the Render DB URL argument."
    exit 1
fi

echo "Applying schema to $PGHOST:$PGPORT/$PGDATABASE"
"$PYTHON_CMD" database/run_schema.py

echo "Schema applied successfully."
