#!/bin/bash
# Flutter Phone Runner Script
# Automatically detects IP and runs the VolleyLeague app on a connected physical device

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "📱 VolleyLeague - Physical Device Runner"
echo "========================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Check for connected devices
echo "🔍 Looking for connected devices..."
if ! flutter devices | grep -q -E "android|ios|physical"; then
    echo "❌ No physical devices found!"
    echo "Please connect a device via USB and enable USB debugging."
    exit 1
fi

echo "✅ Device found!"
echo ""

# Determine run mode (default to release)
MODE="--release"
if [[ "$*" == *"--debug"* ]]; then
    MODE="--debug"
    echo "🐛 Debug mode"
elif [[ "$*" == *"--profile"* ]]; then
    MODE="--profile"
    echo "📊 Profile mode"
else
    echo "🚀 Release mode"
fi

# Use Render backend URL
echo ""
echo "🌐 Using Render backend"
BACKEND_URL="https://volleyleague-api.onrender.com"
echo "🔗 Attempting to connect to backend at $BACKEND_URL..."

# Try a quick ping
if curl -s --max-time 5 "$BACKEND_URL/docs" > /dev/null 2>&1; then
    echo "✅ Backend is reachable!"
else
    echo "⚠️  Backend test inconclusive (timeout or not responding)"
    echo ""
    echo "If you just started the backend, it may need a moment to fully initialize."
    echo "The app will attempt to connect when you log in."
    echo ""
fi

echo ""
echo "🚀 Launching app..."
echo "Backend: $BACKEND_URL"
echo ""

# Run Flutter with the detected IP
flutter run $MODE --dart-define=API_BASE_URL="$BACKEND_URL"


