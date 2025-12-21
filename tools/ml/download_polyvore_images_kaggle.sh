#!/usr/bin/env bash
set -euo pipefail

# Downloads Polyvore images from Kaggle if kaggle CLI is configured.
# Requires: Kaggle account + accepted dataset terms + ~/.kaggle/kaggle.json

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/Datasets/polyvore_images}"

DATASET="dnepozitek/maryland-polyvore-images"

mkdir -p "$OUT_DIR"

if ! command -v kaggle >/dev/null 2>&1; then
  echo "kaggle CLI not found. Install it with: pip install kaggle" >&2
  echo "and ensure ~/.kaggle/kaggle.json exists." >&2
  exit 2
fi

echo "Downloading Kaggle dataset: $DATASET -> $OUT_DIR"
# Kaggle downloads as a zip file.
kaggle datasets download -d "$DATASET" -p "$OUT_DIR" --force

ZIP=$(ls -1 "$OUT_DIR"/*.zip | head -n 1 || true)
if [[ -z "$ZIP" ]]; then
  echo "No zip downloaded into $OUT_DIR" >&2
  exit 1
fi

echo "Extracting: $ZIP"
unzip -q -o "$ZIP" -d "$OUT_DIR"

echo "OK: Polyvore images downloaded to $OUT_DIR"