import os
from contextlib import asynccontextmanager

import asyncpg
from fastapi import FastAPI

from api.routes.users import router as users_router
from api.routes.teams import router as teams_router
from api.routes.leagues import router as leagues_router
from api.routes.seasons import router as seasons_router
from api.routes.matches import router as matches_router
from api.routes.auth import router as auth_router
from api.routes.register import router as register_router
from api.routes.login import router as login_router



def _pg_dsn() -> dict:
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
  # Startup: create the database connection pool
  app.state.pool = await asyncpg.create_pool(**_pg_dsn())
  yield
  # Shutdown: close the database connection pool
  await app.state.pool.close()


app = FastAPI(title="VolleyLeague API", lifespan=lifespan)

# Authentication routes
app.include_router(login_router, prefix="/api", tags=["auth"])
app.include_router(auth_router, prefix="/api", tags=["auth"])
app.include_router(register_router, prefix="/api/auth", tags=["auth"])

# Entity routes
app.include_router(users_router, prefix="/api", tags=["users"])
app.include_router(teams_router, prefix="/api", tags=["teams"])
app.include_router(leagues_router, prefix="/api", tags=["leagues"])
app.include_router(seasons_router, prefix="/api", tags=["seasons"])
app.include_router(matches_router, prefix="/api", tags=["matches"])

