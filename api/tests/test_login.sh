#!/bin/bash

# Quick test script for the login endpoint
# Usage: ./test_login.sh <username> <password>

API_URL="http://localhost:8000/api/login"

if [ $# -eq 0 ]; then
    echo "Usage: ./test_login.sh <username> <password>"
    echo ""
    echo "Example:"
    echo "  ./test_login.sh testuser mypassword"
    exit 1
fi

USERNAME=$1
PASSWORD=$2

echo "Testing login for user: $USERNAME"
echo "API URL: $API_URL"
echo ""

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "username": "$USERNAME",
  "password": "$PASSWORD"
}
EOF
)

response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

echo "Response Code: $http_code"
echo "Response Body:"
echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"

if [ "$http_code" = "200" ]; then
    echo ""
    echo "✓ Login successful!"
    
    # Extract and decode the token
    token=$(echo "$body" | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)
    
    if [ ! -z "$token" ]; then
        echo ""
        echo "Token: $token"
        echo ""
        echo "Decoding token payload..."
        
        # Decode JWT payload (middle part between the dots)
        payload=$(echo "$token" | cut -d'.' -f2)
        # Add padding if needed
        while [ $((${#payload} % 4)) -ne 0 ]; do
            payload="${payload}="
        done
        decoded=$(echo "$payload" | base64 -d 2>/dev/null)
        
        echo "$decoded" | python3 -m json.tool 2>/dev/null || echo "$decoded"
    fi
else
    echo ""
    echo "✗ Login failed"
fi
