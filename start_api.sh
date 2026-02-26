#!/bin/bash
# API Server Startup Script
# Loads environment variables from secrets/.env and starts FastAPI server

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if .env exists
if [ ! -f "secrets/.env" ]; then
    echo "❌ Error: secrets/.env file not found!"
    echo ""
    echo "Please create it from the template:"
    echo "  cd secrets/"
    echo "  cp .env.example .env"
    echo "  # Then edit .env with your actual values"
    echo ""
    echo "See secrets/SETUP.md for detailed instructions."
    exit 1
fi

# Load environment variables
echo "🔐 Loading environment variables from secrets/.env..."
export $(cat secrets/.env | grep -v '^#' | xargs)

# Verify SECRET_KEY is set
if [ -z "$SECRET_KEY" ]; then
    echo "❌ Error: SECRET_KEY not set in secrets/.env"
    echo "Generate one with: python3 -c \"import secrets; print(secrets.token_urlsafe(32))\""
    exit 1
fi

echo "✅ Environment configured"
echo "🚀 Starting FastAPI server..."
echo "📡 Server will be accessible from: http://<your-machine-ip>:8000"
echo ""

# Start the server with explicit host binding
# --host 0.0.0.0 makes it accessible from physical devices on the network
# --reload enables auto-reload when files change
python -m uvicorn api.fastapi_app:app --host 0.0.0.0 --port 8000 --reload
