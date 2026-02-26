# Device Connection Setup

This guide explains how to run the VolleyLeague app on a physical device with database connectivity.

## Quick Start

### 1. Start the API Server

From the project root:

```bash
./start_api.sh
```

The API will be accessible at `http://10.103.137.94:8000` on your local network.

### 2. Run the App on Your Phone

From the `volleyleague` directory:

```bash
cd volleyleague
./run_phone.sh
```

Or with the `--release` flag for optimized performance (default):

```bash
./run_phone.sh --release
```

For debugging:

```bash
./run_phone.sh --debug
```

## Configuration

### API Server

The API server configuration is in `secrets/.env`:

- `API_HOST=0.0.0.0` - Allows connections from any device on the network
- `API_PORT=8000` - The port the API runs on

### Flutter App

The API endpoint is configured in `volleyleague/lib/core/constants.dart`:

```dart
static const String apiBaseUrl = 'http://10.103.137.94:8000';
```

**Important**: Update this IP address if your Mac's local IP changes. You can find your current IP with:

```bash
ipconfig getifaddr en0
```

## Device Setup

### iOS Device

1. Connect your iPhone via USB
2. Trust the computer when prompted
3. In Xcode, add your Apple Developer account (free account works)
4. Run `./run_phone.sh`

### Android Device

1. Enable Developer Options on your Android device:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging in Developer Options
3. Connect via USB
4. Accept the debugging authorization prompt
5. Run `./run_phone.sh`

## Troubleshooting

### "No devices found"

- Ensure your device is connected via USB
- Check that USB debugging is enabled (Android)
- Check that you trust the computer (iOS)
- Run `flutter devices` to see available devices

### "Connection refused" errors in app

- Verify the API server is running (`./start_api.sh`)
- Check that your phone and Mac are on the same WiFi network
- Update the IP address in `constants.dart` to your current local IP
- Ensure your firewall allows connections on port 8000

### API not accessible from device

- Make sure `API_HOST=0.0.0.0` in `secrets/.env`
- Check your Mac's firewall settings
- Verify both devices are on the same network

## Network Configuration

The app is currently configured for:

- **Physical devices**: `http://10.103.137.94:8000`
- **iOS Simulator**: Use `http://localhost:8000`
- **Android Emulator**: Use `http://10.0.2.2:8000`

Switch between these by uncommenting the appropriate line in `constants.dart`.

