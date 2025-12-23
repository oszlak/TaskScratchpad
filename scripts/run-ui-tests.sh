#!/bin/bash
# Run XCUITests locally

set -e

echo "🧪 Running UI Tests for TaskScratchpad..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build the app first
echo "📦 Building the app..."
swift build

# Create app bundle for testing
ARCH=$(uname -m)
APP_BUNDLE="build/TaskScratchpad.app"

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp ".build/${ARCH}-apple-macosx/debug/TaskScratchpad" "$APP_BUNDLE/Contents/MacOS/"

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TaskScratchpad</string>
    <key>CFBundleIdentifier</key>
    <string>com.taskscratchpad.app</string>
    <key>CFBundleName</key>
    <string>TaskScratchpad</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo -e "${GREEN}✓ App bundle created${NC}"

# Run UI tests
echo "🏃 Running UI tests..."
xcodebuild test \
    -project TaskScratchpad.xcodeproj \
    -scheme TaskScratchpad \
    -destination 'platform=macOS' \
    -derivedDataPath build/DerivedData \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | xcbeautify || {
        echo -e "${YELLOW}Note: Install xcbeautify for prettier output: brew install xcbeautify${NC}"
        xcodebuild test \
            -project TaskScratchpad.xcodeproj \
            -scheme TaskScratchpad \
            -destination 'platform=macOS' \
            -derivedDataPath build/DerivedData \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO
    }

echo -e "${GREEN}✅ UI Tests completed!${NC}"

