#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="AlwaysHDR"
BUNDLE_ID="com.alwayshdr.app"
APP_DIR="$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RES_DIR="$CONTENTS/Resources"

echo "→ Building release binary..."
if swift build -c release --arch arm64 --arch x86_64 2>/dev/null; then
    BIN_PATH=".build/apple/Products/Release"
else
    swift build -c release
    BIN_PATH="$(swift build -c release --show-bin-path)"
fi

echo "→ Assembling $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"
cp "$BIN_PATH/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>12.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict>
</plist>
PLIST

echo "→ Ad-hoc signing..."
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo
echo "Built $APP_DIR"
echo "Run:    open $APP_DIR"
echo "Install: mv $APP_DIR /Applications/"
