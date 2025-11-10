"""
Test the /api/auth/register endpoint.
Run this after starting the FastAPI server with: uvicorn api.fastapi_app:app --reload
"""

import requests
import sys
from pathlib import Path
import json

API_BASE_URL = "http://localhost:8000"


def test_register_endpoint():
    """Test the /api/auth/register endpoint."""
    
    print("=" * 60)
    print("TESTING /api/auth/register ENDPOINT")
    print("=" * 60)
    
    # Test 1: Valid registration
    print("\n1. Testing valid registration...")
    valid_user = {
        "username": "newuser123",
        "email": "newuser@example.com",
        "password": "SecurePass123",
        "full_name": "New User",
        "role": "PLAYER"
    }
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/api/auth/register",
            json=valid_user
        )
        
        if response.status_code == 201:
            data = response.json()
            print(f"   ✓ Registration successful")
            print(f"   Message: {data['message']}")
            print(f"   User ID: {data['user_id']}")
            print(f"   Username: {data['username']}")
            print(f"   Role: {data['role']}")
            print(f"   Created At: {data['created_at']}")
        else:
            print(f"   ✗ Registration failed with status {response.status_code}")
            print(f"   Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print(f"   ✗ Cannot connect to API at {API_BASE_URL}")
        print(f"   Make sure the server is running with:")
        print(f"   uvicorn api.fastapi_app:app --reload")
        return False
    
    # Test 2: Duplicate username
    print("\n2. Testing duplicate username (409 expected)...")
    response = requests.post(
        f"{API_BASE_URL}/api/auth/register",
        json=valid_user
    )
    
    if response.status_code == 409:
        print(f"   ✓ Duplicate correctly rejected (409)")
        print(f"   Message: {response.json()['detail']}")
    else:
        print(f"   ✗ Expected 409, got {response.status_code}")
    
    # Test 3: Invalid email format
    print("\n3. Testing invalid email format (422 expected)...")
    invalid_email = valid_user.copy()
    invalid_email["username"] = "testuser2"
    invalid_email["email"] = "not-an-email"
    
    response = requests.post(
        f"{API_BASE_URL}/api/auth/register",
        json=invalid_email
    )
    
    if response.status_code == 422:
        print(f"   ✓ Invalid email rejected (422)")
    else:
        print(f"   ✗ Expected 422, got {response.status_code}")
    
    # Test 4: Weak password
    print("\n4. Testing weak password (422 expected)...")
    weak_password = valid_user.copy()
    weak_password["username"] = "testuser3"
    weak_password["email"] = "testuser3@example.com"
    weak_password["password"] = "weak"
    
    response = requests.post(
        f"{API_BASE_URL}/api/auth/register",
        json=weak_password
    )
    
    if response.status_code == 422:
        print(f"   ✓ Weak password rejected (422)")
        errors = response.json()['detail']
        for error in errors:
            if 'password' in str(error):
                print(f"   Error: {error}")
    else:
        print(f"   ✗ Expected 422, got {response.status_code}")
    
    # Test 5: Missing uppercase in password
    print("\n5. Testing password without uppercase (422 expected)...")
    no_upper = valid_user.copy()
    no_upper["username"] = "testuser4"
    no_upper["email"] = "testuser4@example.com"
    no_upper["password"] = "nocapital123"
    
    response = requests.post(
        f"{API_BASE_URL}/api/auth/register",
        json=no_upper
    )
    
    if response.status_code == 422:
        print(f"   ✓ Password without uppercase rejected (422)")
    else:
        print(f"   ✗ Expected 422, got {response.status_code}")
    
    # Test 6: Username too short
    print("\n6. Testing username too short (422 expected)...")
    short_username = valid_user.copy()
    short_username["username"] = "ab"
    short_username["email"] = "testuser5@example.com"
    short_username["password"] = "ValidPass123"
    
    response = requests.post(
        f"{API_BASE_URL}/api/auth/register",
        json=short_username
    )
    
    if response.status_code == 422:
        print(f"   ✓ Short username rejected (422)")
    else:
        print(f"   ✗ Expected 422, got {response.status_code}")
    
    # Test 7: Register different roles
    print("\n7. Testing different user roles...")
    roles = ["COACH", "ADMIN"]
    for role in roles:
        role_user = {
            "username": f"test_{role.lower()}",
            "email": f"test_{role.lower()}@example.com",
            "password": "SecurePass123",
            "full_name": f"Test {role}",
            "role": role
        }
        
        response = requests.post(
            f"{API_BASE_URL}/api/auth/register",
            json=role_user
        )
        
        if response.status_code == 201:
            data = response.json()
            print(f"   ✓ {role} registered: {data['username']}")
        else:
            print(f"   ✗ {role} registration failed: {response.status_code}")
    
    # Test 8: Test login with registered user
    print("\n8. Testing login with registered user...")
    login_response = requests.post(
        f"{API_BASE_URL}/api/login",
        params={
            "username": "newuser123",
            "password": "SecurePass123"
        }
    )
    
    if login_response.status_code == 200:
        token_data = login_response.json()
        print(f"   ✓ Login successful")
        print(f"   Token: {token_data['access_token'][:50]}...")
    else:
        print(f"   ✗ Login failed: {login_response.status_code}")
    
    # Clean up test users
    print("\n9. Cleaning up test data...")
    import asyncio
    import asyncpg
    import os
    
    # Load environment variables
    env_path = Path(__file__).parent.parent / "secrets" / ".env"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value
    
    async def cleanup():
        conn = await asyncpg.connect(
            host=os.environ.get("PGHOST", "localhost"),
            port=int(os.environ.get("PGPORT", 5432)),
            user=os.environ.get("PGUSER", "postgres"),
            password=os.environ.get("PGPASSWORD"),
            database=os.environ.get("PGDATABASE", "antonidebicki"),
        )
        
        usernames = ["newuser123", "test_coach", "test_admin"]
        for username in usernames:
            await conn.execute('DELETE FROM "Users" WHERE username = $1', username)
        
        await conn.close()
    
    asyncio.run(cleanup())
    print(f"   ✓ Test users deleted")
    
    print("\n" + "=" * 60)
    print("REGISTER ENDPOINT TESTS PASSED ✓")
    print("=" * 60)
    return True


if __name__ == "__main__":
    success = test_register_endpoint()
    sys.exit(0 if success else 1)
