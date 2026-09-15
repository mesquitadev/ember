#!/bin/bash
# Compila e monta Ember.app em dist/. Uso: Scripts/bundle.sh [debug|release]
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/Ember.app"

cd "$ROOT"
ARCHS=(--arch arm64 --arch x86_64)
if ! swift build -c "$CONFIG" "${ARCHS[@]}" >/dev/null 2>&1; then
  ARCHS=()
  swift build -c "$CONFIG"
fi
BIN="$(swift build -c "$CONFIG" "${ARCHS[@]+"${ARCHS[@]}"}" --show-bin-path)/Ember"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Ember"
cp "$ROOT/Scripts/Info.plist" "$APP/Contents/Info.plist"

ICONSET="$(mktemp -d)/Ember.iconset"
swiftc -swift-version 5 -O "$ROOT/Scripts/icon/main.swift" -o "$(dirname "$ICONSET")/gen" >/dev/null
"$(dirname "$ICONSET")/gen" "$ICONSET" >/dev/null
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Ember.icns"

codesign --force --sign - --identifier dev.mesquita.Ember "$APP" >/dev/null

echo "Pronto: $APP"
