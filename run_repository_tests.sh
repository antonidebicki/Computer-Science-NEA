#!/bin/bash

# Repository Integration Test Runner
# Tests Flutter repositories against real backend

echo "🏐 VolleyLeague Repository Tests"
echo "================================"
echo ""

# Check if backend is running
echo "[INFO] Checking backend connection..."
if curl -s http://localhost:8000/docs > /dev/null 2>&1; then
    echo "[PASS] Backend is running at http://localhost:8000"
else
    echo "[FAIL] Backend is not running!"
    echo ""
    echo "Please start the backend first:"
    echo "  cd /path/to/project"
    echo "  uvicorn api.fastapi_app:app --reload"
    echo ""
    exit 1
fi

echo ""
echo "[TEST] Running repository tests..."
echo ""

cd volleyleague

# Run the tests
flutter test tests/repository_test.dart --reporter expanded

echo ""
echo "[PASS] Tests completed!"
