"""
Test suite for DEV_STAGES 1.1f - Authentication & Role-Based Access Control
Tests user registration, login, and role restrictions on protected endpoints.
"""

import os
import sys
import asyncio
import asyncpg
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

# Load environment variables from secrets/.env
env_path = Path(__file__).parent.parent.parent / "secrets" / ".env"
if env_path.exists():
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

from api.auth import AuthUtils


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


class TestUser:
    """Helper class to represent a test user"""
    def __init__(self, username: str, password: str, email: str, full_name: str, role: str):
        self.username = username
        self.password = password
        self.email = email
        self.full_name = full_name
        self.role = role
        self.user_id: int | None = None
        self.access_token: str | None = None
        self.refresh_token: str | None = None


async def cleanup_test_users(pool):
    """Delete test users created during testing"""
    test_usernames = [
        "test_player_auth",
        "test_coach_auth",
        "test_admin_auth"
    ]
    
    async with pool.acquire() as connection:
        for username in test_usernames:
            await connection.execute(
                'DELETE FROM "Users" WHERE username = $1',
                username
            )
    print("✓ Cleaned up test users")


async def register_user(pool, user: TestUser) -> bool:
    """Register a new user and return success status"""
    async with pool.acquire() as connection:
        try:
            hashed_password = AuthUtils.hash_password(user.password)
            row = await connection.fetchrow(
                """
                INSERT INTO "Users" (username, hashed_password, email, full_name, role)
                VALUES ($1, $2, $3, $4, $5)
                RETURNING user_id;
                """,
                user.username,
                hashed_password,
                user.email,
                user.full_name,
                user.role
            )
            user.user_id = row['user_id']
            print(f"✓ Registered user: {user.username} (role: {user.role}, id: {user.user_id})")
            return True
        except asyncpg.UniqueViolationError:
            print(f"✗ User {user.username} already exists")
            return False
        except Exception as e:
            print(f"✗ Failed to register {user.username}: {e}")
            return False


async def login_user(pool, user: TestUser) -> bool:
    """Login user and store tokens"""
    async with pool.acquire() as connection:
        try:
            row = await connection.fetchrow(
                """
                SELECT user_id, username, hashed_password, email, full_name, role
                FROM "Users"
                WHERE username = $1;
                """,
                user.username
            )
            
            if not row:
                print(f"✗ User {user.username} not found")
                return False
            
            if not AuthUtils.verify_password(user.password, row['hashed_password']):
                print(f"✗ Invalid password for {user.username}")
                return False
            
            # Create tokens
            claims = {
                "sub": row["username"],
                "user_id": row["user_id"],
                "role": row["role"]
            }
            user.user_id = row['user_id']
            user.access_token = AuthUtils.create_access_token(claims)
            user.refresh_token = AuthUtils.create_refresh_token(claims)
            
            print(f"✓ Logged in: {user.username} (role: {user.role})")
            print(f"  Token preview: {user.access_token[:50]}...")
            return True
            
        except Exception as e:
            print(f"✗ Login failed for {user.username}: {e}")
            return False


async def test_token_validation(user: TestUser):
    """Test that tokens can be decoded and contain correct information"""
    try:
        # Decode access token
        payload = AuthUtils.decode_access_token(f"Bearer {user.access_token}")
        
        if "error" in payload:
            print(f"✗ Token validation failed: {payload['error']}")
            return False
        
        # Verify claims
        if payload.get("user_id") != user.user_id:
            print(f"✗ Token user_id mismatch: expected {user.user_id}, got {payload.get('user_id')}")
            return False
        
        if payload.get("role") != user.role:
            print(f"✗ Token role mismatch: expected {user.role}, got {payload.get('role')}")
            return False
        
        if payload.get("type") != "access":
            print(f"✗ Token type mismatch: expected 'access', got {payload.get('type')}")
            return False
        
        print(f"✓ Token validation passed for {user.username}")
        print(f"  Payload: user_id={payload['user_id']}, role={payload['role']}, type={payload['type']}")
        return True
        
    except Exception as e:
        print(f"✗ Token validation exception: {e}")
        return False


async def test_refresh_token_validation(user: TestUser):
    """Test that refresh tokens are validated correctly"""
    try:
        if not user.refresh_token:
            print(f"✗ User {user.username} has no refresh token")
            return False
        
        # Decode refresh token
        payload = AuthUtils.decode_refresh_token(user.refresh_token)
        
        if "error" in payload:
            print(f"✗ Refresh token validation failed: {payload['error']}")
            return False
        
        # Verify claims
        if payload.get("user_id") != user.user_id:
            print(f"✗ Refresh token user_id mismatch")
            return False
        
        if payload.get("type") != "refresh":
            print(f"✗ Refresh token type mismatch: expected 'refresh', got {payload.get('type')}")
            return False
        
        if "jti" not in payload:
            print(f"✗ Refresh token missing jti (token ID)")
            return False
        
        print(f"✓ Refresh token validation passed for {user.username}")
        print(f"  JTI: {payload['jti'][:20]}...")
        return True
        
    except Exception as e:
        print(f"✗ Refresh token validation exception: {e}")
        return False


async def test_token_type_separation(user: TestUser):
    """Test that refresh tokens cannot be used as access tokens"""
    try:
        # Try to use refresh token as access token
        payload = AuthUtils.decode_access_token(f"Bearer {user.refresh_token}")
        
        if "error" in payload:
            if "Invalid token type" in payload["error"]:
                print(f"✓ Token type separation working: Refresh token rejected as access token")
                return True
            else:
                print(f"✗ Wrong error message: {payload['error']}")
                return False
        else:
            print(f"✗ SECURITY ISSUE: Refresh token accepted as access token!")
            return False
            
    except Exception as e:
        print(f"✗ Token type separation test exception: {e}")
        return False


async def test_get_current_user(user: TestUser):
    """Test the get_current_user dependency function"""
    try:
        # Valid token
        auth_header = f"Bearer {user.access_token}"
        payload = AuthUtils.get_current_user(auth_header)
        
        if payload.get("user_id") != user.user_id or payload.get("role") != user.role:
            print(f"✗ get_current_user returned incorrect data")
            return False
        
        print(f"✓ get_current_user works for {user.username}")
        
        # Test missing header
        try:
            AuthUtils.get_current_user(None)
            print(f"✗ get_current_user should raise exception for missing header")
            return False
        except Exception:
            print(f"✓ get_current_user correctly rejects missing header")
        
        # Test invalid token
        try:
            AuthUtils.get_current_user("Bearer invalid_token_here")
            print(f"✗ get_current_user should raise exception for invalid token")
            return False
        except Exception:
            print(f"✓ get_current_user correctly rejects invalid token")
        
        return True
        
    except Exception as e:
        print(f"✗ get_current_user test exception: {e}")
        return False


async def test_require_role(user: TestUser, allowed_roles: list):
    """Test the require_role dependency function"""
    try:
        role_checker = AuthUtils.require_role(allowed_roles)
        auth_header = f"Bearer {user.access_token}"
        
        try:
            payload = role_checker(auth_header)
            
            if user.role in allowed_roles:
                print(f"✓ require_role({allowed_roles}) allowed {user.username} ({user.role})")
                return True
            else:
                print(f"✗ require_role({allowed_roles}) should have rejected {user.username} ({user.role})")
                return False
                
        except Exception as e:
            if user.role not in allowed_roles and "Access forbidden" in str(e):
                print(f"✓ require_role({allowed_roles}) correctly rejected {user.username} ({user.role})")
                return True
            else:
                print(f"✗ Unexpected exception: {e}")
                return False
                
    except Exception as e:
        print(f"✗ require_role test exception: {e}")
        return False


async def main():
    """Main test runner for 1.1f - Authentication Testing"""
    print("\n" + "="*70)
    print("DEV_STAGES 1.1f - Authentication & Role-Based Access Control Tests")
    print("="*70 + "\n")
    
    # Create database connection pool
    pool = await asyncpg.create_pool(**_pg_dsn())
    
    # Clean up any existing test users
    await cleanup_test_users(pool)
    
    # Define test users
    test_users = [
        TestUser("test_player_auth", "PlayerPass123", "player@test.com", "Test Player", "PLAYER"),
        TestUser("test_coach_auth", "CoachPass123", "coach@test.com", "Test Coach", "COACH"),
        TestUser("test_admin_auth", "AdminPass123", "admin@test.com", "Test Admin", "ADMIN"),
    ]
    
    all_tests_passed = True
    
    # Test 1: Register users with different roles
    print("\n--- Test 1: User Registration ---")
    for user in test_users:
        if not await register_user(pool, user):
            all_tests_passed = False
    
    # Test 2: Login users and get JWT tokens
    print("\n--- Test 2: User Login & Token Generation ---")
    for user in test_users:
        if not await login_user(pool, user):
            all_tests_passed = False
    
    # Test 3: Validate access tokens contain correct user_id and role
    print("\n--- Test 3: Access Token Validation ---")
    for user in test_users:
        if not await test_token_validation(user):
            all_tests_passed = False
    
    # Test 4: Validate refresh tokens
    print("\n--- Test 4: Refresh Token Validation ---")
    for user in test_users:
        if not await test_refresh_token_validation(user):
            all_tests_passed = False
    
    # Test 5: Test token type separation (refresh tokens can't be used as access tokens)
    print("\n--- Test 5: Token Type Separation ---")
    for user in test_users:
        if not await test_token_type_separation(user):
            all_tests_passed = False
    
    # Test 6: Test get_current_user dependency
    print("\n--- Test 6: get_current_user Dependency ---")
    for user in test_users:
        if not await test_get_current_user(user):
            all_tests_passed = False
    
    # Test 7: Test role-based access control
    print("\n--- Test 7: Role-Based Access Control ---")
    
    # Test ADMIN-only access
    print("\nTesting ADMIN-only endpoint:")
    for user in test_users:
        if not await test_require_role(user, ["ADMIN"]):
            all_tests_passed = False
    
    # Test COACH or ADMIN access
    print("\nTesting COACH/ADMIN endpoint:")
    for user in test_users:
        if not await test_require_role(user, ["COACH", "ADMIN"]):
            all_tests_passed = False
    
    # Test PLAYER (should be rejected from admin endpoints)
    print("\nTesting PLAYER access to ADMIN endpoint:")
    player = test_users[0]  # PLAYER
    if not await test_require_role(player, ["ADMIN"]):
        all_tests_passed = False
    
    # Clean up
    print("\n--- Cleanup ---")
    await cleanup_test_users(pool)
    await pool.close()
    
    # Final results
    print("\n" + "="*70)
    if all_tests_passed:
        print("✅ ALL TESTS PASSED - Authentication system working correctly!")
    else:
        print("❌ SOME TESTS FAILED - Review errors above")
    print("="*70 + "\n")
    
    return all_tests_passed


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
