# VolleyLeague API Structure

## Directory Organization

```
api/
├── __init__.py              # API package initialization
├── fastapi_app.py           # Main FastAPI application with lifespan and routers
├── core/                    # Core configuration and shared models
│   ├── __init__.py
│   └── models.py            # Pydantic models for request/response validation
└── routes/                  # API endpoint routers organized by resource
    ├── __init__.py
    ├── users.py             # User endpoints (GET /api/users, POST /api/users)
    ├── teams.py             # Team endpoints
    ├── leagues.py           # League endpoints
    ├── seasons.py           # Season endpoints
    └── matches.py           # Match endpoints
```

## Route Structure

All routes are prefixed with `/api`:
- `GET/POST /api/users` - User management
- `GET/POST /api/teams` - Team management
- `GET/POST /api/leagues` - League management
- `GET/POST /api/seasons` - Season management
- `GET/POST /api/matches` - Match management

## Running the API

```bash
# From the project root
uvicorn api.fastapi_app:app --reload

# API will be available at http://localhost:8000
# Interactive docs at http://localhost:8000/docs
```

## Adding New Endpoints

1. Create/update router file in `api/routes/`
2. Import models from `api.core.models`
3. Register router in `fastapi_app.py`
