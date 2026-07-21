#!/usr/bin/env bash
set -euo pipefail

build_name=""
build_number=""

usage() {
  cat <<'EOF'
Usage: bash tool/build_signed_android_release.sh [options]

Options:
  --build-name VERSION   Optional semantic version, for example 0.1.0
  --build-number NUMBER  Optional positive Android version code
  -h, --help             Show this help
EOF
}

while (($# > 0)); do
  case "$1" in
    --build-name)
      [[ $# -ge 2 ]] || { echo "--build-name requires a value." >&2; exit 2; }
      build_name="$2"
      shift 2
      ;;
    --build-number)
      [[ $# -ge 2 ]] || { echo "--build-number requires a value." >&2; exit 2; }
      build_number="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -n "$build_name" && ! "$build_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
  echo "--build-name must be a semantic version such as 0.1.0." >&2
  exit 2
fi

if [[ -n "$build_number" && ! "$build_number" =~ ^[1-9][0-9]*$ ]]; then
  echo "--build-number must be a positive integer." >&2
  exit 2
fi

for command_name in flutter dart jarsigner; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name is not installed or is not on PATH." >&2
    exit 1
  fi
done

if [[ ! -f android/key.properties ]]; then
  echo "android/key.properties is missing." >&2
  echo "Copy android/key.properties.example and configure the ignored upload keystore." >&2
  exit 1
fi

flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
(cd android && ./gradlew :app:verifyReleaseSigning)

args=(--release)
[[ -z "$build_name" ]] || args+=(--build-name "$build_name")
[[ -z "$build_number" ]] || args+=(--build-number "$build_number")
flutter build appbundle "${args[@]}"

bundle="build/app/outputs/bundle/release/app-release.aab"
test -f "$bundle"

signature_log="$(mktemp)"
trap 'rm -f "$signature_log"' EXIT
jarsigner -verify -verbose -certs "$bundle" | tee "$signature_log"
grep -F 'jar verified.' "$signature_log" >/dev/null

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$bundle" | tee "$bundle.sha256"
elif command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$bundle" | tee "$bundle.sha256"
else
  echo "Neither sha256sum nor shasum is available." >&2
  exit 1
fi

printf '\nSigned Android App Bundle created successfully:\n%s\n' "$bundle"
printf 'Checksum file:\n%s.sha256\n' "$bundle"
