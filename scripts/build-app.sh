#!/bin/zsh
set -eu
cd "${0:A:h:h}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
swift build -c release --disable-sandbox --cache-path .build/cache
zsh scripts/build-icon.sh
app="$PWD/build/Pomodoro.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/PomodoroTasks "$app/Contents/MacOS/Pomodoro"
cp Assets/Pomodoro.icns "$app/Contents/Resources/Pomodoro.icns"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Pomodoro</string>
<key>CFBundleIdentifier</key><string>local.rayan.pomodoro-tasks</string>
<key>CFBundleName</key><string>Pomodoro</string>
<key>CFBundleDisplayName</key><string>Pomodoro</string>
<key>CFBundleIconFile</key><string>Pomodoro</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.11</string>
<key>CFBundleVersion</key><string>12</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
ditto -c -k --sequesterRsrc --keepParent "$app" "$PWD/build/Pomodoro.zip"
print "Built: $app"
