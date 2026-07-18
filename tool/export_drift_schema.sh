#!/usr/bin/env bash
set -euo pipefail

SCHEMA_DIRECTORY="${1:-drift_schemas}"

mkdir -p "$SCHEMA_DIRECTORY"
dart run drift_dev schema dump \
  lib/core/database/app_database.dart \
  "$SCHEMA_DIRECTORY/"

echo "Drift schema exported to $SCHEMA_DIRECTORY."
