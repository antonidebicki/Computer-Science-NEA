Start Server Command

⚠️ **IMPORTANT:** Environment variables must be set before starting the server.

## Development (Quick Start)
```bash
# Load environment variables and start server (one command)
export $(cat secrets/.env | xargs) && uvicorn api.fastapi_app:app --reload --host 0.0.0.0 --port 8000
```

## Alternative: Create Start Script
```bash
# Create start_api.sh
chmod +x start_api.sh

# Then run:
./start_api.sh
```

See `secrets/SETUP.md` for full environment setup instructions.
