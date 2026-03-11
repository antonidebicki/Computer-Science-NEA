# Security and Design Analysis Report

## Executive Summary

This document provides a comprehensive security and design analysis of the VolleyLeague application, consisting of a FastAPI backend and Flutter mobile frontend. The analysis covers authentication, authorization, data protection, API security, and general design patterns.

---

## 🔴 Critical Security Issues

### 1. **Hardcoded Default Secret Keys in Seed Data**

**Location:** `database/seed/seed_data.sql`

**Issue:** All seed users share the same bcrypt password hash (`$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa` = "AdminPass123"). While acceptable for development, this creates a significant risk if seed data is accidentally deployed to production.

**Risk:** HIGH - If production database is seeded with this data, all accounts would share a known password.

**Recommendation:**
- Add clear warnings in seed scripts about production usage
- Consider generating random passwords for seed users with a separate credentials file
- Ensure production deployment scripts skip or modify seed data

### 2. **Missing Rate Limiting**

**Location:** `api/auth/login.py`, `api/auth/register.py`

**Issue:** The login and registration endpoints lack rate limiting protection, making them vulnerable to:
- Brute force password attacks
- Credential stuffing attacks
- Account enumeration via timing attacks
- Denial of Service through resource exhaustion

**Risk:** HIGH - Attackers can attempt unlimited login attempts without restriction.

**Recommendation:**
```python
# Example using slowapi or fastapi-limiter
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/login")
@limiter.limit("5/minute")  # 5 attempts per minute per IP
async def login(...):
```

### 3. **Generic Error Messages May Leak Information**

**Location:** `api/routes/matches.py:168-171`, `api/routes/seasons.py:374-376`

**Issue:** Exception messages sometimes include internal error details:
```python
detail=f"Failed to create set: {str(exc)}"  # May expose internal details
detail=f"Failed to process match: {str(e)}"
```

**Risk:** MEDIUM - Could reveal database structure, internal paths, or technology stack to attackers.

**Recommendation:**
- Log detailed errors server-side
- Return generic error messages to clients
- Use error codes for debugging without exposing internals

---

## 🟠 Medium Security Issues

### 4. **Registration Endpoint Allows Self-Assignment of ADMIN Role**

**Location:** `api/auth/register.py`, `api/models/schemas.py:29-34`

**Issue:** The `RegisterRequest` model allows users to specify their own role during registration, including "ADMIN":
```python
class RegisterRequest(BaseModel):
    # ...
    role: Literal["PLAYER", "COACH", "ADMIN"] = Field(...)
```

**Risk:** MEDIUM - Without additional validation, any user could register as an admin.

**Recommendation:**
- Remove "ADMIN" from allowed roles in public registration
- Create a separate admin creation flow protected by existing admin authentication
- Or implement email verification/approval workflow for privileged roles

```python
# Safer registration schema
class RegisterRequest(BaseModel):
    role: Literal["PLAYER", "COACH"] = Field(...)  # Remove ADMIN
```

### 5. **Missing Input Validation on Several Endpoints**

**Location:** Multiple routes including `api/routes/teams.py:41-61`

**Issue:** Some endpoints accept `created_by_user_id` from the payload without verifying it matches the authenticated user:
```python
async def create_team(request: Request, payload: TeamCreate, user: dict = ...):
    # payload.created_by_user_id is used directly without validation
    # Should verify: payload.created_by_user_id == user["user_id"] or user is admin
```

**Risk:** MEDIUM - Users could potentially create resources attributed to other users.

**Recommendation:**
- Always use `user["user_id"]` from the JWT token for ownership
- Validate that payload IDs match authenticated user unless admin

### 6. **JWT Token Claims Not Validated Against Database**

**Location:** `api/auth/utils.py:116-160`

**Issue:** The `get_current_user()` dependency returns token payload directly without checking if the user still exists or has been banned/deactivated.

**Risk:** MEDIUM - Tokens remain valid even after user deletion or role changes.

**Recommendation:**
```python
@staticmethod
async def get_current_user_with_db_check(authorization: str, db_pool) -> dict:
    payload = AuthUtils.get_current_user(authorization)
    # Verify user still exists and role matches
    user = await db_pool.fetchrow("SELECT * FROM Users WHERE user_id = $1", payload["user_id"])
    if not user or user["role"] != payload["role"]:
        raise HTTPException(status_code=401, detail="Token invalid")
    return payload
```

### 7. **Password Validation Only on Client Side**

**Location:** `api/models/schemas.py:45-56`

**Issue:** While password validation exists in `RegisterRequest`, users could bypass this by calling the internal `create_user()` directly or by manipulating requests.

**Risk:** MEDIUM - Weak passwords could be accepted if validation is bypassed.

**Recommendation:**
- Add password validation in the `AuthUtils.hash_password()` method
- Validate password strength server-side before hashing

---

## 🟡 Low Security Issues

### 8. **Verbose Error Messages in Token Validation**

**Location:** `api/auth/utils.py:179-181`

**Issue:** Role-based authorization reveals which roles are required:
```python
detail=f"Access forbidden. Required roles: {', '.join(allowed_roles)}"
```

**Risk:** LOW - Could help attackers understand authorization structure.

**Recommendation:**
- Return generic "Access forbidden" message
- Log detailed information server-side

### 9. **Missing HTTPS Enforcement**

**Location:** `api/fastapi_app.py`, deployment configurations

**Issue:** No explicit HTTPS enforcement in the API configuration.

**Risk:** LOW (assuming deployment platform handles this) - Credentials could be intercepted if HTTP is allowed.

**Recommendation:**
- Add middleware to redirect HTTP to HTTPS
- Set secure cookie flags

### 10. **Debug Information in Seed Data README**

**Location:** `database/seed/README.md:167-181`

**Issue:** Test credentials are documented with clear password ("AdminPass123"), which could accidentally be used in production.

**Risk:** LOW - Documentation of test credentials is acceptable but should have prominent warnings.

---

## 🔵 Design Issues

### 11. **Database Connection Pool Not Configurable**

**Location:** `api/config/database.py`

**Issue:** The database connection pool uses defaults without configuration options:
```python
app.state.pool = await asyncpg.create_pool(**get_pg_dsn())
# No min_size, max_size, or timeout configuration
```

**Recommendation:**
```python
app.state.pool = await asyncpg.create_pool(
    **get_pg_dsn(),
    min_size=5,
    max_size=20,
    command_timeout=60
)
```

### 12. **Inconsistent Error Handling Pattern**

**Location:** Various routes

**Issue:** Error handling is inconsistent across endpoints:
- Some use `from exc` for chaining
- Some catch generic `Exception`
- Some expose internal errors, others don't

**Recommendation:**
- Create a consistent exception handler middleware
- Define custom exception classes for different error types

### 13. **Missing Database Indexes**

**Location:** `database/schema.sql`

**Issue:** The schema lacks indexes on frequently queried foreign keys and search fields, which will impact performance at scale:
- `TeamMembers.user_id`
- `Matches.season_id`
- `Seasons.league_id`
- `Users.username` (for login lookups)

**Recommendation:**
```sql
CREATE INDEX idx_teammembers_user_id ON "TeamMembers"(user_id);
CREATE INDEX idx_matches_season_id ON "Matches"(season_id);
CREATE INDEX idx_seasons_league_id ON "Seasons"(league_id);
-- username already has UNIQUE constraint which creates an index
```

### 14. **Unused Import**

**Location:** `api/auth/utils.py:5`

**Issue:** `import cryptography` is imported but never used.

**Recommendation:** Remove unused import to clean up code.

### 15. **Missing API Versioning**

**Location:** `api/fastapi_app.py`

**Issue:** API routes use `/api/` prefix without versioning, making future breaking changes difficult.

**Recommendation:**
```python
app.include_router(users_router, prefix="/api/v1", tags=["users"])
```

### 16. **Missing Request/Response Logging**

**Location:** API-wide

**Issue:** No request logging middleware for debugging and audit trails.

**Recommendation:**
- Add logging middleware for request/response logging
- Include request ID for tracing
- Log authentication attempts

### 17. **Missing Health Check Endpoint**

**Location:** `api/fastapi_app.py`

**Issue:** No health check endpoint for deployment monitoring.

**Recommendation:**
```python
@app.get("/health")
async def health_check():
    # Could add database connectivity check
    return {"status": "healthy"}
```

### 18. **Hardcoded Default Values in Database Config**

**Location:** `api/config/database.py:7-16`

**Issue:** Database configuration includes hardcoded fallback values:
```python
"database": os.environ.get("PGDATABASE", "antonidebicki"),  # Hardcoded default
```

**Recommendation:**
- Remove hardcoded defaults or use more generic ones
- Require explicit configuration in production

---

## ✅ Security Strengths

The codebase demonstrates several good security practices:

1. **Proper Password Hashing:** Uses bcrypt with automatic salt generation
2. **JWT Token Separation:** Access and refresh tokens with different expiries
3. **Role-Based Access Control:** Consistent use of `require_role()` decorator
4. **Secure Token Storage (Frontend):** Uses `flutter_secure_storage` for encrypted token storage
5. **Parameterized Queries:** All SQL queries use parameterized placeholders ($1, $2, etc.)
6. **Input Validation:** Pydantic models provide type validation
7. **Constant-Time Password Comparison:** Using `bcrypt.checkpw()` which is timing-safe
8. **Token Type Verification:** Checks token "type" field to prevent misuse
9. **Automatic Token Refresh:** Client-side automatic refresh before expiry
10. **Secrets in Environment:** Uses environment variables for sensitive config

---

## Priority Remediation Order

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| 1 | Add rate limiting to login/register | Medium | High |
| 2 | Remove ADMIN from self-registration | Low | High |
| 3 | Validate `created_by_user_id` against auth token | Low | Medium |
| 4 | Sanitize error messages | Low | Medium |
| 5 | Add database indexes | Low | Medium |
| 6 | Add health check endpoint | Low | Low |
| 7 | Add API versioning | Medium | Low |
| 8 | Add request logging | Medium | Low |

---

## Conclusion

The VolleyLeague application demonstrates a solid security foundation with proper authentication, password hashing, and role-based access control. The primary concerns are the lack of rate limiting on authentication endpoints and the ability for users to self-assign admin roles during registration. Addressing these issues, along with the design improvements noted, will significantly enhance the application's security posture.

For a student NEA project, the security implementation shows good understanding of authentication principles. The recommendations above would bring it closer to production-ready standards.
