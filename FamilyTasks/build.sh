#!/bin/bash
# Сборка и запуск FamilyTasks в симуляторе.
# Использует отдельный регистрозависимый диск-образ для DerivedData/SourcePackages —
# на дефолтном регистронезависимом APFS сборка пакета nanopb (файл BUILD/build) ломается.
set -e

cd "$(dirname "$0")"
eval "$(/opt/homebrew/bin/brew shellenv)"

IMAGE="$(pwd)/FamilyTasksBuild.sparseimage"
VOLUME="/Volumes/FamilyTasksBuild"

if [ ! -d "$VOLUME" ]; then
  if [ ! -f "$IMAGE" ]; then
    hdiutil create -type SPARSE -fs "Case-sensitive APFS" -size 6g -volname FamilyTasksBuild "$IMAGE"
  fi
  hdiutil attach "$IMAGE"
fi

xcodegen generate

xcodebuild -project FamilyTasks.xcodeproj -scheme FamilyTasks \
  -derivedDataPath "$VOLUME/DerivedData" \
  -clonedSourcePackagesDirPath "$VOLUME/SourcePackages" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build

APP_PATH="$VOLUME/DerivedData/Build/Products/Debug-iphonesimulator/FamilyTasks.app"
xcrun simctl boot "iPhone 15" 2>/dev/null || true
xcrun simctl install "iPhone 15" "$APP_PATH"
xcrun simctl launch "iPhone 15" com.todofromdashenka.app
