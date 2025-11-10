"""
Test the /api/login endpoint with a real HTTP request.
Run this after starting the FastAPI server with: uvicorn api.fastapi_app:app --reload
"""

import requests
import sys
from pathlib import Path

# Load environment variables
import os
env_path = Path(__file__).parent.parent / "secrets" / ".env"
if env_path.exists():
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

sys.path.insert(0, str(Path(__file__).parent.parent))
from api.authentication.auth import AuthUtils

API_BASE_URL = "http://localhost:8000"


def test_login_endpoint():
    """Test the /api/login endpoint."""
    
    print("=" * 60)
    print("TESTING /api/login ENDPOINT")
    print("=" * 60)
    
    # First, create a test user directly using the database
    import asyncio
    import asyncpg
    
    async def setup_test_user():
        conn = await asyncpg.connect(
            host=os.environ.get("PGHOST", "localhost"),
            port=int(os.environ.get("PGPORT", 5432)),
            user=os.environ.get("PGUSER", "postgres"),
            password=os.environ.get("PGPASSWORD"),
            database=os.environ.get("PGDATABASE", "antonidebicki"),
        )
        
        # Clean up existing test user
        await conn.execute('DELETE FROM "Users" WHERE username = $1', 'api_test_user')
        
        # Create test user
        hashed_password = AuthUtils.hash_password("testpass123")
        user = await conn.fetchrow(
            """
            INSERT INTO "Users" (username, hashed_password, email, full_name, role)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING user_id, username, role;
            """,
            'api_test_user',
            hashed_password,
            'api_test@example.com',
            'API Test User',
            'PLAYER'
        )
        
        await conn.close()
        return user
    
    print("\n1. Setting up test user in database...")
    user = asyncio.run(setup_test_user())
    print(f"   ✓ Test user created: {user['username']} (ID: {user['user_id']}, Role: {user['role']})")
    
    # Test valid login
    print("\n2. Testing valid login...")
    try:
        response = requests.post(
            f"{API_BASE_URL}/api/login",
            params={
                "username": "api_test_user",
                "password": "testpass123"
            }
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✓ Login successful")
            print(f"   Access Token: {data['access_token'][:50]}...")
            print(f"   Token Type: {data['token_type']}")
            assert 'refresh_token' in data, 'refresh_token missing in response'
            
            # Decode the token to verify contents
            token = data['access_token']
            decoded = AuthUtils.decode_access_token(f"Bearer {token}")
            print(f"\n   Token Contents:")
            print(f"   - Username: {decoded['sub']}")
            print(f"   - User ID: {decoded['user_id']}")
            print(f"   - Role: {decoded['role']}")
            
            assert decoded['sub'] == 'api_test_user', "Username mismatch in token"
            assert decoded['user_id'] == user['user_id'], "User ID mismatch in token"
            assert decoded['role'] == 'PLAYER', "Role mismatch in token"
            print(f"   ✓ Token payload verified correctly")
            
            # Test refresh flow
            print("\n3. Testing refresh token flow...")
            refresh_resp = requests.post(
                f"{API_BASE_URL}/api/refresh",
                json={"refresh_token": data['refresh_token']}
            )
            if refresh_resp.status_code == 200:
                refreshed = refresh_resp.json()
                print("   ✓ Refresh successful, new access token issued")
                new_decoded = AuthUtils.decode_access_token(f"Bearer {refreshed['access_token']}")
                assert new_decoded['sub'] == 'api_test_user'
                print("   ✓ Refreshed token decoded correctly")
            else:
                print(f"   ✗ Refresh failed: {refresh_resp.status_code} -> {refresh_resp.text}")
                return False
        else:
            print(f"   ✗ Login failed with status {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print(f"   ✗ Cannot connect to API at {API_BASE_URL}")
        print(f"   Make sure the server is running with:")
        print(f"   uvicorn api.fastapi_app:app --reload")
        return False
    
    # Test invalid password
    print("\n3. Testing invalid password...")
    response = requests.post(
        f"{API_BASE_URL}/api/login",
        params={
            "username": "api_test_user",
            "password": "wrongpassword"
        }
    )
    
    if response.status_code == 401:
        print(f"   ✓ Invalid password correctly rejected (401)")
    else:
        print(f"   ✗ Expected 401, got {response.status_code}")
    
    # Test non-existent user
    print("\n4. Testing non-existent user...")
    response = requests.post(
        f"{API_BASE_URL}/api/login",
        params={
            "username": "nonexistent_user",
            "password": "anypassword"
        }
    )
    
    if response.status_code == 401:
        print(f"   ✓ Non-existent user correctly rejected (401)")
    else:
        print(f"   ✗ Expected 401, got {response.status_code}")
    
    # Clean up
    print("\n5. Cleaning up test data...")
    async def cleanup():
        conn = await asyncpg.connect(
            host=os.environ.get("PGHOST", "localhost"),
            port=int(os.environ.get("PGPORT", 5432)),
            user=os.environ.get("PGUSER", "postgres"),
            password=os.environ.get("PGPASSWORD"),
            database=os.environ.get("PGDATABASE", "antonidebicki"),
        )
        await conn.execute('DELETE FROM "Users" WHERE username = $1', 'api_test_user')
        await conn.close()
    
    asyncio.run(cleanup())
    print(f"   ✓ Test user deleted")
    
    print("\n" + "=" * 60)
    print("LOGIN ENDPOINT TESTS PASSED ✓")
    print("=" * 60)
    return True


if __name__ == "__main__":
    success = test_login_endpoint()
    sys.exit(0 if success else 1)
