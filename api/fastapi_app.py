from fastapi import FastAPI

from api.config import lifespan
from api.routes.users import router as users_router
from api.routes.teams import router as teams_router
from api.routes.leagues import router as leagues_router
from api.routes.seasons import router as seasons_router
from api.routes.matches import router as matches_router
from api.auth.routes import router as auth_router
from api.auth.register import router as register_router
from api.auth.login import router as login_router


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

