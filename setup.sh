#!/bin/bash
# Run this once after installing Flutter to scaffold the platform files.
# https://flutter.dev/docs/get-started/install

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Creating Flutter project scaffold..."
flutter create . \
  --project-name emirates_wash \
  --org com.emirateswash \
  --platforms android,ios \
  --no-overwrite

echo "==> Patching Android permissions..."
ANDROID_MANIFEST="android/app/src/main/AndroidManifest.xml"
if ! grep -q "ACCESS_FINE_LOCATION" "$ANDROID_MANIFEST"; then
  sed -i '' 's|<manifest|<manifest|' "$ANDROID_MANIFEST"  # no-op to test sed works
  # Insert permissions before <application tag
  sed -i '' 's|<application|<uses-permission android:name="android.permission.INTERNET"/>\
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\
    <application|' "$ANDROID_MANIFEST"
  echo "    Android permissions added."
else
  echo "    Android permissions already present."
fi

echo "==> Patching iOS Info.plist..."
IOS_PLIST="ios/Runner/Info.plist"
if ! grep -q "NSLocationWhenInUseUsageDescription" "$IOS_PLIST"; then
  sed -i '' 's|<dict>|<dict>\
\t<key>NSLocationWhenInUseUsageDescription</key>\
\t<string>Emirates Wash needs your location to find nearby car washes.</string>\
\t<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>\
\t<string>Emirates Wash needs your location to find nearby car washes.</string>|' "$IOS_PLIST"
  echo "    iOS location permissions added."
else
  echo "    iOS permissions already present."
fi

echo "==> Getting Flutter packages..."
flutter pub get

echo ""
echo "Setup complete! Run the app with:"
echo "  flutter run"
