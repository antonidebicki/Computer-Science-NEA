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

## Authentication

The API includes JWT-based authentication with the following features:

### Login Endpoint
- **POST** `/api/login?username=<username>&password=<password>`
- Returns: `{"access_token": "<jwt>", "refresh_token": "<jwt>", "token_type": "bearer"}`
- Token payload includes: `user_id`, `role`, and `sub` (username)

### Token Usage (Access Token)
Include the token in requests:
```
Authorization: Bearer <access_token>
```

### Refreshing Tokens (So users don't re-login every 24h)

- Access tokens expire after 24h by default.
- Clients should store the long-lived `refresh_token` and call:
    - **POST** `/api/refresh` with body: `{ "refresh_token": "<refresh>" }`
    - Response: new `access_token` and `refresh_token` pair.
    - Rotate stored refresh token each time.

Environment variables:
- `SECRET_KEY` signs access tokens (24h default)
- `REFRESH_SECRET_KEY` (optional) signs refresh tokens (30 days default). Falls back to `SECRET_KEY`.

### Testing Authentication
See [TESTING.md](./TESTING.md) for comprehensive testing instructions.

Quick tests:
```bash
# Test auth functions and database integration
python3 api/test_auth.py

# Test login endpoint (requires running server)
./api/test_login.sh <username> <password>
```

## Adding New Endpoints

1. Create/update router file in `api/routes/`
2. Import models from `api.core.models`
3. Register router in `fastapi_app.py`
