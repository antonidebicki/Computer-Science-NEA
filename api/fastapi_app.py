import os

import asyncpg
from fastapi import FastAPI

from .get_users_endpoint import router as get_users_router
from .post_user_endpoint import router as post_user_router
from .teams_endpoints import router as teams_router
from .leagues_endpoints import router as leagues_router
from .seasons_endpoints import router as seasons_router
from .matches_endpoints import router as matches_router



def _pg_dsn() -> dict:
  """Read connection details from standard PG* environment variables."""
  return {
      "host": os.environ.get("PGHOST", "localhost"),
      "port": int(os.environ.get("PGPORT", 5432)),
      "user": os.environ.get("PGUSER", "postgres"),
      "password": os.environ.get("PGPASSWORD"),
      "database": os.environ.get("PGDATABASE", "volleyleague"),
      "ssl": os.environ.get("PGSSLMODE") == "require",
  }


app = FastAPI(title="VolleyLeague API")


@app.on_event("startup")
async def startup_event() -> None:
  app.state.pool = await asyncpg.create_pool(**_pg_dsn())


@app.on_event("shutdown")
async def shutdown_event() -> None:
  await app.state.pool.close()


app.include_router(get_users_router)
app.include_router(post_user_router)
app.include_router(teams_router)
app.include_router(leagues_router)
app.include_router(seasons_router)
app.include_router(matches_router)

