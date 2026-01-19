import os
from contextlib import asynccontextmanager
import asyncpg
from fastapi import FastAPI


def get_pg_dsn() -> dict:
    """Read connection details from standard PG* environment variables."""
    return {
        "host": os.environ.get("PGHOST", "localhost"),
        "port": int(os.environ.get("PGPORT", 5432)),
        "user": os.environ.get("PGUSER", "postgres"),
        "password": os.environ.get("PGPASSWORD"),
        "database": os.environ.get("PGDATABASE", "antonidebicki"),
        "ssl": os.environ.get("PGSSLMODE") == "require",
    }


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage database connection pool lifecycle."""
    app.state.pool = await asyncpg.create_pool(**get_pg_dsn())
    yield
    await app.state.pool.close()
