#!/bin/bash
# Helper script to run the database schema setup with the correct Python environment

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

cd "$PROJECT_ROOT"

# Check if virtual environment exists
if [ -d ".venv" ]; then
    echo "🐍 Using virtual environment Python..."
    PYTHON_CMD=".venv/bin/python"
else
    echo "⚠️  No virtual environment found, using system Python"
    PYTHON_CMD="python3"
fi

# Load environment variables from .env if it exists
if [ -f "secrets/.env" ]; then
    echo "🔐 Loading environment variables from secrets/.env..."
    export $(cat secrets/.env | grep -v '^#' | xargs)
fi

echo "🗄️  Applying database schema..."
echo ""

# Run the schema script
$PYTHON_CMD database/run_schema.py "$@"
