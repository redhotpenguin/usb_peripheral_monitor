#!/bin/bash
set -e

APP_NAME="USBMonitorDesktop"
BUNDLE_ID="com.yourcompany.usbmonitor.desktop"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"

echo "==> Building release binary..."
swift build -c release

echo "==> Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

echo "==> Copying binary..."
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

echo "==> Writing Info.plist..."
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>USB Monitor</string>
    <key>CFBundleDisplayName</key>
    <string>USB Monitor</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Ad-hoc signing..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Creating DMG..."
rm -f "${DMG_NAME}"
hdiutil create \
    -volname "USB Monitor" \
    -srcfolder "${APP_BUNDLE}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

echo ""
echo "Done: ${DMG_NAME}"
echo ""
echo "NOTE: Your friend will need to right-click the app and choose Open"
echo "      the first time, since it is not notarized with Apple."
