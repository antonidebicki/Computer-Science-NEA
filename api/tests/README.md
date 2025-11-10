# API Tests

This directory contains all test files for the VolleyLeague API backend.

## Test Files

### `test_authentication_roles.py` (DEV_STAGES 1.1f)
Comprehensive test suite for authentication and role-based access control.

**What it tests:**
1. User registration with different roles (PLAYER, COACH, ADMIN)
2. User login and JWT token generation
3. Access token validation (contains user_id, role, type='access')
4. Refresh token validation (contains jti, type='refresh')
5. Token type separation (refresh tokens can't be used as access tokens)
6. `get_current_user()` dependency function
7. `require_role()` dependency function with various role combinations

**Run:**
```bash
python3 api/tests/test_authentication_roles.py
```

**Expected output:**
- ✓ All users registered successfully
- ✓ All users logged in successfully
- ✓ All tokens validated correctly
- ✓ Token type separation working
- ✓ Role-based access control working
- ✅ ALL TESTS PASSED

### `test_auth.py`
Unit tests for authentication utilities (password hashing, JWT creation/decoding, database integration).

**Run:**
```bash
python3 api/tests/test_auth.py
```

### `test_login_endpoint.py`
Integration tests for login and refresh endpoints (requires running server).

**Run:**
```bash
# Start server first
uvicorn api.fastapi_app:app --reload

# In another terminal
python3 api/tests/test_login_endpoint.py
```

### `test_register_endpoint.py`
Integration tests for registration endpoint (requires running server).

**Run:**
```bash
# Start server first
uvicorn api.fastapi_app:app --reload

# In another terminal
python3 api/tests/test_register_endpoint.py
```

### `test_login.sh`
Shell script for quick manual testing of login endpoint.

**Run:**
```bash
chmod +x api/tests/test_login.sh
./api/tests/test_login.sh <username> <password>
```

## Running All Tests

### Unit Tests (no server needed)
```bash
python3 api/tests/test_auth.py
python3 api/tests/test_authentication_roles.py
```

### Integration Tests (server required)
```bash
# Terminal 1: Start server
cd /Users/antonidebicki/Documents/GitHub/NEA/vbLeague/Computer-Science-NEA
uvicorn api.fastapi_app:app --reload

# Terminal 2: Run tests
python3 api/tests/test_login_endpoint.py
python3 api/tests/test_register_endpoint.py
```

## Test Coverage

### Authentication (1.1a - 1.1f)
- ✅ Password hashing with bcrypt
- ✅ JWT token creation (access + refresh)
- ✅ JWT token validation
- ✅ Token type separation
- ✅ User registration
- ✅ User login
- ✅ Token refresh flow
- ✅ Role-based access control
- ✅ `get_current_user()` dependency
- ✅ `require_role()` dependency

### Endpoints
- ✅ POST /api/login
- ✅ POST /api/refresh
- ✅ POST /api/auth/register
- ⏳ Protected endpoints (GET /api/leagues, etc.)
- ⏳ Role-restricted endpoints (POST /api/leagues, etc.)

## Test Environment

**Database:** PostgreSQL
**Requirements:**
- Database schema applied (see `database/schema.sql`)
- Environment variables set (see `secrets/.env`)
  - `SECRET_KEY`
  - `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`

## Adding New Tests

1. Create test file in `api/tests/`
2. Follow naming convention: `test_<feature>.py`
3. Import necessary modules:
   ```python
   import sys
   from pathlib import Path
   sys.path.insert(0, str(Path(__file__).parent.parent.parent))
   ```
4. Load environment variables from `secrets/.env`
5. Use asyncio for async tests
6. Clean up test data after tests complete

## Debugging Failed Tests

### "Authorization header missing"
- Check that token is being passed correctly
- Verify token format: `Authorization: Bearer <token>`

### "Invalid or expired token"
- Check SECRET_KEY matches between test and auth module
- Verify token hasn't expired (24h for access, 30d for refresh)

### "Access forbidden"
- Check user has correct role for endpoint
- Verify `require_role()` is using correct allowed_roles list

### Database connection errors
- Ensure PostgreSQL is running
- Check environment variables are set correctly
- Verify database exists and schema is applied
