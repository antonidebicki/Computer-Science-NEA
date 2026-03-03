import os
import ssl
from contextlib import asynccontextmanager
import asyncpg
from fastapi import FastAPI


def _get_ssl_config():
    """Build SSL config for asyncpg from PGSSLMODE.

    PGSSLMODE semantics:
    - disable / allow / prefer: no enforced TLS
    - require: TLS without certificate verification (common for hosted DBs)
    - verify-ca: verify certificate chain
    - verify-full: verify certificate chain and hostname
    """
    mode = os.environ.get("PGSSLMODE", "disable").lower()

    if mode in {"disable", "allow", "prefer"}:
        return False

    if mode == "require":
        tls_context = ssl.create_default_context()
        tls_context.check_hostname = False
        tls_context.verify_mode = ssl.CERT_NONE
        return tls_context

    if mode == "verify-ca":
        tls_context = ssl.create_default_context()
        tls_context.check_hostname = False
        return tls_context

    if mode == "verify-full":
        return ssl.create_default_context()

    return False


def get_pg_dsn() -> dict:
    """Read connection details from standard PG* environment variables."""
    return {
        "host": os.environ.get("PGHOST", "localhost"),
        "port": int(os.environ.get("PGPORT", 5432)),
        "user": os.environ.get("PGUSER", "postgres"),
        "password": os.environ.get("PGPASSWORD"),
        "database": os.environ.get("PGDATABASE", "antonidebicki"),
        "ssl": _get_ssl_config(),
    }


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage database connection pool lifecycle."""
    app.state.pool = await asyncpg.create_pool(**get_pg_dsn())
    yield
    await app.state.pool.close()
