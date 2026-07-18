#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or is not on PATH." >&2
  exit 1
fi

if [[ ! -f android/app/build.gradle.kts ]]; then
  echo "The committed Android project is missing." >&2
  exit 1
fi

flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug

echo "Bootstrap, validation, and Android debug build completed successfully."
