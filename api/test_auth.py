#Test script for authentication

import os
import sys
import asyncio
import asyncpg
from datetime import timedelta
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

# Load environment variables from secrets/.env
env_path = Path(__file__).parent.parent / "secrets" / ".env"
if env_path.exists():
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

from api.core.auth import AuthUtils


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


async def test_auth():
    """Test authentication functions with database."""
    
    print("=" * 60)
    print("AUTHENTICATION TEST SUITE")
    print("=" * 60)
    
    # Test 1: Password Hashing
    print("\n1. Testing Password Hashing...")
    test_password = "secure_password_123"
    hashed = AuthUtils.hash_password(test_password)
    print(f"   ✓ Password hashed successfully")
    print(f"   Original: {test_password}")
    print(f"   Hashed: {hashed[:50]}...")
    
    # Test 2: Password Verification
    print("\n2. Testing Password Verification...")
    is_valid = AuthUtils.verify_password(test_password, hashed)
    is_invalid = AuthUtils.verify_password("wrong_password", hashed)
    assert is_valid, "Valid password should verify"
    assert not is_invalid, "Invalid password should not verify"
    print(f"   ✓ Correct password verified: {is_valid}")
    print(f"   ✓ Wrong password rejected: {not is_invalid}")
    
    # Test 3: JWT Token Creation
    print("\n3. Testing JWT Token Creation...")
    token_data = {
        "sub": "testuser",
        "user_id": 123,
        "role": "ADMIN"
    }
    token = AuthUtils.create_access_token(token_data)
    print(f"   ✓ Token created successfully")
    print(f"   Token: {token[:50]}...")
    
    # Test 4: JWT Token Decoding
    print("\n4. Testing JWT Token Decoding...")
    auth_header = f"Bearer {token}"
    decoded = AuthUtils.decode_access_token(auth_header)
    assert "error" not in decoded, f"Token decode failed: {decoded}"
    assert decoded["sub"] == "testuser", "Username mismatch"
    assert decoded["user_id"] == 123, "User ID mismatch"
    assert decoded["role"] == "ADMIN", "Role mismatch"
    print(f"   ✓ Token decoded successfully")
    print(f"   Username: {decoded['sub']}")
    print(f"   User ID: {decoded['user_id']}")
    print(f"   Role: {decoded['role']}")
    
    # Test 5: Role Authorization
    print("\n5. Testing Role Authorization...")
    has_admin = AuthUtils.require_role(["ADMIN", "COACH"], decoded)
    has_player = AuthUtils.require_role(["PLAYER"], decoded)
    assert has_admin, "Admin should have access"
    assert not has_player, "Admin should not match PLAYER role"
    print(f"   ✓ Admin role check: {has_admin}")
    print(f"   ✓ Player role check (should fail): {has_player}")
    
    # Test 6: Database Integration
    print("\n6. Testing Database Integration...")
    try:
        conn = await asyncpg.connect(**_pg_dsn())
        print(f"   ✓ Database connection established")
        
        # Create a test user
        test_username = "test_auth_user"
        test_email = "test_auth@example.com"
        
        # Clean up any existing test user
        await conn.execute('DELETE FROM "Users" WHERE username = $1', test_username)
        
        # Insert test user
        hashed_password = AuthUtils.hash_password("test123")
        user = await conn.fetchrow(
            """
            INSERT INTO "Users" (username, hashed_password, email, full_name, role)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING user_id, username, role;
            """,
            test_username,
            hashed_password,
            test_email,
            "Test User",
            "COACH"
        )
        print(f"   ✓ Test user created: {user['username']} (ID: {user['user_id']})")
        
        # Test 7: Login Flow Simulation
        print("\n7. Testing Login Flow...")
        
        # Fetch user and verify password
        db_user = await conn.fetchrow(
            'SELECT user_id, username, hashed_password, role FROM "Users" WHERE username = $1',
            test_username
        )
        
        password_match = AuthUtils.verify_password("test123", db_user["hashed_password"])
        assert password_match, "Password should match"
        print(f"   ✓ User retrieved from database")
        print(f"   ✓ Password verified successfully")
        
        # Create access token
        access_token = AuthUtils.create_access_token({
            "sub": db_user["username"],
            "user_id": db_user["user_id"],
            "role": db_user["role"]
        })
        print(f"   ✓ Access token created")
        
        # Decode and verify token
        decoded_token = AuthUtils.decode_access_token(f"Bearer {access_token}")
        assert decoded_token["user_id"] == db_user["user_id"], "User ID mismatch"
        assert decoded_token["role"] == db_user["role"], "Role mismatch"
        print(f"   ✓ Token decoded and verified")
        print(f"   User ID: {decoded_token['user_id']}")
        print(f"   Role: {decoded_token['role']}")
        
        # Test 8: Test all user roles
        print("\n8. Testing All User Roles...")
        roles = ["ADMIN", "COACH", "PLAYER", "REFEREE"]
        for role in roles:
            role_username = f"test_{role.lower()}_user"
            await conn.execute('DELETE FROM "Users" WHERE username = $1', role_username)
            
            role_user = await conn.fetchrow(
                """
                INSERT INTO "Users" (username, hashed_password, email, role)
                VALUES ($1, $2, $3, $4)
                RETURNING user_id, username, role;
                """,
                role_username,
                AuthUtils.hash_password("test123"),
                f"{role_username}@example.com",
                role
            )
            print(f"   ✓ {role} user created: {role_user['username']}")
        
        # Clean up test users
        print("\n9. Cleaning Up Test Data...")
        deleted = await conn.execute('DELETE FROM "Users" WHERE username LIKE $1', 'test_%')
        print(f"   ✓ Test users cleaned up")
        
        await conn.close()
        print(f"   ✓ Database connection closed")
        
    except Exception as e:
        print(f"   ✗ Database test failed: {e}")
        raise
    
    print("\n" + "=" * 60)
    print("ALL TESTS PASSED ✓")
    print("=" * 60)
    print("\nSummary:")
    print("  - Password hashing works correctly")
    print("  - Password verification works correctly")
    print("  - JWT tokens are created with user_id and role")
    print("  - JWT tokens can be decoded and verified")
    print("  - Role-based authorization works correctly")
    print("  - Database integration works correctly")
    print("  - All user roles (ADMIN, COACH, PLAYER, REFEREE) work")
    print("\nYour authentication system is ready to use!")


if __name__ == "__main__":
    asyncio.run(test_auth())
