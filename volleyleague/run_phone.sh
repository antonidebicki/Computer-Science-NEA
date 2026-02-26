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

# Get local machine IP address
echo ""
echo "🔧 Detecting network IP..."

LOCAL_IP=""

# Try multiple methods to get the local IP (order matters for reliability)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - try en0 first (WiFi), then en1, then others
    for interface in en0 en1 en2 en3 eth0 wlan0; do
        LOCAL_IP=$(ipconfig getifaddr "$interface" 2>/dev/null)
        if [ -n "$LOCAL_IP" ] && [ "$LOCAL_IP" != "127.0.0.1" ]; then
            break
        fi
    done
    
    # If still not found, try alternative method
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(ifconfig | grep -E "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
    fi
else
    # Linux - try multiple methods
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(hostname -i 2>/dev/null | grep -v "127.0.0.1")
    fi
fi

if [ -z "$LOCAL_IP" ] || [ "$LOCAL_IP" = "127.0.0.1" ]; then
    echo "❌ Could not detect local IP address"
    echo ""
    echo "Please try one of the following:"
    echo "1. Check your network with: ifconfig (macOS) or ip addr (Linux)"
    echo "2. Make sure you're connected to WiFi or network"
    echo "3. Manually edit the script to set your IP"
    exit 1
fi

echo "✅ Local IP: $LOCAL_IP"


# Check if backend is reachable
BACKEND_URL="http://$LOCAL_IP:8000"
echo "🔗 Attempting to connect to backend at $BACKEND_URL..."

# Try a quick ping but don't wait too long
if timeout 2 curl -s "$BACKEND_URL/" > /dev/null 2>&1; then
    echo "✅ Backend is reachable!"
elif timeout 2 curl -s "$BACKEND_URL/docs" > /dev/null 2>&1; then
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


