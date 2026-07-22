#!/usr/bin/env bash
set -euo pipefail

apk="${1:-}"
output="${2:-build/release-evidence/APK-PERMISSIONS.txt}"

if [[ -z "$apk" || ! -f "$apk" ]]; then
  echo "Usage: bash tool/check_apk_permissions.sh path/to/app.apk [output.txt]" >&2
  exit 2
fi

android_sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$android_sdk_root" ]]; then
  echo "ANDROID_SDK_ROOT or ANDROID_HOME is required." >&2
  exit 1
fi

apkanalyzer="$(find "$android_sdk_root" -type f -name apkanalyzer 2>/dev/null | sort -V | tail -n 1)"
if [[ -z "$apkanalyzer" || ! -x "$apkanalyzer" ]]; then
  echo "apkanalyzer was not found in the Android SDK." >&2
  exit 1
fi

mkdir -p "$(dirname "$output")"
"$apkanalyzer" manifest permissions "$apk" | sort -u | tee "$output"

for permission in \
  android.permission.INTERNET \
  android.permission.ACCESS_NETWORK_STATE \
  android.permission.ACCESS_FINE_LOCATION \
  android.permission.ACCESS_COARSE_LOCATION \
  android.permission.CAMERA \
  android.permission.RECORD_AUDIO \
  android.permission.READ_CONTACTS \
  android.permission.WRITE_CONTACTS \
  android.permission.READ_PHONE_STATE \
  android.permission.READ_SMS \
  android.permission.SEND_SMS \
  android.permission.READ_EXTERNAL_STORAGE \
  android.permission.WRITE_EXTERNAL_STORAGE \
  android.permission.MANAGE_EXTERNAL_STORAGE \
  android.permission.SCHEDULE_EXACT_ALARM \
  android.permission.USE_EXACT_ALARM; do
  if grep -Fq "$permission" "$output"; then
    echo "Forbidden release permission: $permission" >&2
    exit 1
  fi
done
