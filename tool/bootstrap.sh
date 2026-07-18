#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or is not on PATH." >&2
  exit 1
fi

if [[ ! -d android ]]; then
  flutter create \
    --platforms=android \
    --org ir.emadkarimi \
    --project-name daro_ta_key_daram \
    .
fi

flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

echo "Bootstrap and validation completed successfully."
