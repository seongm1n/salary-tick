#!/bin/sh
# swiftc로 .app 번들 직접 조립. Xcode 프로젝트 불필요.
set -e
cd "$(dirname "$0")"
APP=build/SalaryTick.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -parse-as-library -o "$APP/Contents/MacOS/SalaryTick" App.swift
cp Info.plist "$APP/Contents/Info.plist"

# 아이콘: 1024 PNG 한 장 렌더 → sips로 축소 → iconutil
mkdir -p "$APP/Contents/Resources" build/AppIcon.iconset
swift make-icon.swift >/dev/null
sips -z 1024 1024 build/icon-1024.png --out build/icon-1024.png >/dev/null
for s in 16 32 64 128 256 512 1024; do
	sips -z $s $s build/icon-1024.png --out "build/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
done
cd build/AppIcon.iconset
mv icon_32x32.png icon_16x16@2x.png;   cp icon_16x16@2x.png icon_32x32.png
mv icon_64x64.png icon_32x32@2x.png
mv icon_256x256.png icon_128x128@2x.png; cp icon_128x128@2x.png icon_256x256.png
mv icon_512x512.png icon_256x256@2x.png; cp icon_256x256@2x.png icon_512x512.png
mv icon_1024x1024.png icon_512x512@2x.png
cd ../..
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
echo "✅ $APP"
if [ "$1" = "install" ]; then
	codesign --force --deep -s - "$APP"
	pkill -x SalaryTick 2>/dev/null || true
	rm -rf /Applications/SalaryTick.app && cp -R "$APP" /Applications/ && open /Applications/SalaryTick.app
	echo "✅ /Applications/SalaryTick.app"; exit 0
fi
if [ "$1" = "preview" ]; then exec "$APP/Contents/MacOS/SalaryTick" --preview; fi
if [ "$1" = "test" ]; then exec "$APP/Contents/MacOS/SalaryTick" --selftest; fi
if [ "$1" = "run" ]; then pkill -x SalaryTick 2>/dev/null || true; open "$APP"; fi
