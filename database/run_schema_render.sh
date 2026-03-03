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

if [ -f "secrets/.env" ]; then
    export $(cat secrets/.env | grep -v '^#' | xargs)
fi

DB_URL="${1:-${RENDER_DATABASE_URL:-${DATABASE_URL:-}}}"

if [ -n "$DB_URL" ]; then
    eval "$("$PYTHON_CMD" - "$DB_URL" <<'PY'
import shlex
import sys
from urllib.parse import urlparse, parse_qs

url = sys.argv[1]
parsed = urlparse(url)
if parsed.scheme not in ("postgres", "postgresql"):
    raise SystemExit("DATABASE URL must start with postgres:// or postgresql://")

host = parsed.hostname or ""
port = str(parsed.port or 5432)
user = parsed.username or ""
password = parsed.password or ""
database = (parsed.path or "").lstrip("/")
query = parse_qs(parsed.query or "")
sslmode = (query.get("sslmode", [""])[0] or "require")

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
fi

: "${PGHOST:?PGHOST is required}"
: "${PGPORT:?PGPORT is required}"
: "${PGUSER:?PGUSER is required}"
: "${PGPASSWORD:?PGPASSWORD is required}"
: "${PGDATABASE:?PGDATABASE is required}"
export PGSSLMODE="${PGSSLMODE:-require}"

echo "Applying schema to $PGHOST:$PGPORT/$PGDATABASE"
"$PYTHON_CMD" database/run_schema.py

echo "Schema applied successfully."
