#!/usr/bin/env bash
set -euo pipefail

mode="${1:-candidate}"
if [[ "$mode" != "candidate" && "$mode" != "publish" ]]; then
  echo "Usage: bash tool/release_readiness.sh [candidate|publish]" >&2
  exit 2
fi

python3 tool/check_release_candidate.py
bash -n tool/bootstrap.sh
bash -n tool/export_drift_schema.sh
bash -n tool/build_signed_android_release.sh
bash -n tool/check_apk_permissions.sh

flutter pub get
dart run build_runner build --delete-conflicting-outputs
rm -rf /tmp/daro_release_schemas
bash tool/export_drift_schema.sh /tmp/daro_release_schemas
diff -u drift_schemas/drift_schema_v2.json /tmp/daro_release_schemas/drift_schema_v2.json
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage

if [[ "$mode" == "candidate" ]]; then
  echo "Candidate engineering checks passed. Publication-owner gates remain separate."
  exit 0
fi

: "${PUBLISHER_LEGAL_NAME:?PUBLISHER_LEGAL_NAME is required for publication}"
: "${SUPPORT_EMAIL:?SUPPORT_EMAIL is required for publication}"
: "${PRIVACY_POLICY_URL:?PRIVACY_POLICY_URL is required for publication}"

if [[ ! "$SUPPORT_EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
  echo "SUPPORT_EMAIL is not a valid email shape." >&2
  exit 1
fi
if [[ ! "$PRIVACY_POLICY_URL" =~ ^https:// ]]; then
  echo "PRIVACY_POLICY_URL must be a stable HTTPS URL." >&2
  exit 1
fi
if grep -R -Fq '[تکمیل شود]' docs/09-privacy-policy-fa.md store/metadata store/release; then
  echo "Publication placeholders remain in policy or store material." >&2
  exit 1
fi
if [[ ! -f android/key.properties ]]; then
  echo "Permanent release signing configuration is missing." >&2
  exit 1
fi

bash tool/build_signed_android_release.sh --build-name 1.0.0 --build-number 1
bash tool/check_apk_permissions.sh \
  build/app/outputs/internal-release/daro-ta-key-arm64-release.apk

echo "Publication automation passed. Store account, legal, asset, and physical-device approvals still require recorded human evidence."
