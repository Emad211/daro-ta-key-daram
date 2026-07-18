#!/usr/bin/env bash
set -euo pipefail

REPO="Emad211/daro-ta-key-daram"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required." >&2
  exit 1
fi

gh auth status

if gh repo view "$REPO" >/dev/null 2>&1; then
  echo "Repository $REPO already exists."
else
  gh repo create "$REPO" \
    --private \
    --description "اپ فارسی آفلاین برای تخمین زمان اتمام موجودی دارو" \
    --source . \
    --remote origin
fi

git push -u origin main
