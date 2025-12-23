# Distributing Task Scratchpad

## Quick Build (DMG)

Run the included script to build and package:

```bash
cd /Users/tomer.oszlak/workspace/MyScratchpadApp
./scripts/create-dmg.sh
```

This creates:
- `dist/TaskScratchpad.app` — The app bundle
- `dist/TaskScratchpad-1.0.0.dmg` — Distributable disk image

## Manual Process

### 1. Build Release

```bash
swift build --configuration release
```

### 2. Create App Bundle

macOS apps require a `.app` bundle structure:

```
TaskScratchpad.app/
├── Contents/
│   ├── Info.plist      # App metadata
│   ├── PkgInfo         # Package type
│   ├── MacOS/
│   │   └── TaskScratchpad  # Executable
│   └── Resources/
│       └── AppIcon.icns    # (optional) App icon
```

### 3. Code Signing

**For personal/local use (ad-hoc):**
```bash
codesign --force --deep --sign - dist/TaskScratchpad.app
```

**For distribution (requires Apple Developer account):**
```bash
codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" dist/TaskScratchpad.app
```

### 4. Create DMG

```bash
hdiutil create -volname "TaskScratchpad" \
    -srcfolder dist/TaskScratchpad.app \
    -ov -format UDZO \
    dist/TaskScratchpad.dmg
```

## Distribution Options

### Option A: Direct Sharing (Unsigned)

1. Build the DMG using the script
2. Share the `.dmg` file directly
3. Recipients will need to right-click → Open to bypass Gatekeeper

### Option B: Notarized Distribution (Recommended)

Requires an Apple Developer account ($99/year):

1. **Code sign** with Developer ID:
   ```bash
   codesign --force --deep --options runtime \
       --sign "Developer ID Application: Your Name (TEAM_ID)" \
       dist/TaskScratchpad.app
   ```

2. **Notarize** the app:
   ```bash
   xcrun notarytool submit dist/TaskScratchpad.dmg \
       --apple-id "your@email.com" \
       --password "app-specific-password" \
       --team-id "TEAM_ID" \
       --wait
   ```

3. **Staple** the ticket:
   ```bash
   xcrun stapler staple dist/TaskScratchpad.dmg
   ```

### Option C: Mac App Store

Requires additional entitlements, sandboxing, and App Store review.

## Adding an App Icon

1. Create a 1024×1024 PNG icon
2. Use `iconutil` to create `.icns`:
   ```bash
   mkdir AppIcon.iconset
   sips -z 16 16     icon.png --out AppIcon.iconset/icon_16x16.png
   sips -z 32 32     icon.png --out AppIcon.iconset/icon_16x16@2x.png
   sips -z 32 32     icon.png --out AppIcon.iconset/icon_32x32.png
   sips -z 64 64     icon.png --out AppIcon.iconset/icon_32x32@2x.png
   sips -z 128 128   icon.png --out AppIcon.iconset/icon_128x128.png
   sips -z 256 256   icon.png --out AppIcon.iconset/icon_128x128@2x.png
   sips -z 256 256   icon.png --out AppIcon.iconset/icon_256x256.png
   sips -z 512 512   icon.png --out AppIcon.iconset/icon_256x256@2x.png
   sips -z 512 512   icon.png --out AppIcon.iconset/icon_512x512.png
   sips -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png
   iconutil -c icns AppIcon.iconset
   ```
3. Place `AppIcon.icns` in `Resources/` folder

## Troubleshooting

### "App is damaged and can't be opened"
The app isn't signed. User should:
```bash
xattr -cr /Applications/TaskScratchpad.app
```

### "App can't be opened because it is from an unidentified developer"
Right-click the app → Open → Open anyway

### Gatekeeper blocks the app
Notarize the app (see Option B above)

