#!/usr/bin/env bash
set -euo pipefail

# Extract DeepFashion2 encrypted zip bundles into a target folder.
#
# Usage:
#   bash tools/deepfashion2/extract_deepfashion2.sh \
#     "/Users/you/Downloads/DeepFashion2" \
#     "Datasets/DeepFashion2"
#
# Password handling:
# - Prefer env var: DEEPFASHION2_ZIP_PASSWORD
# - Otherwise prompts (input hidden)

SRC_DIR="${1:-}"
DST_DIR="${2:-}"

if [[ -z "$SRC_DIR" || -z "$DST_DIR" ]]; then
  echo "Usage: extract_deepfashion2.sh <source_dir_with_zips> <dest_dir>" >&2
  exit 2
fi

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Not found: $SRC_DIR" >&2
  exit 2
fi

mkdir -p "$DST_DIR"

PASS="${DEEPFASHION2_ZIP_PASSWORD:-}"
if [[ -z "$PASS" ]]; then
  echo "DeepFashion2 zip files appear encrypted. Enter the zip password." >&2
  read -r -s -p "Password: " PASS
  echo "" >&2
fi

extract_one() {
  local zip_path="$1"
  if [[ ! -f "$zip_path" ]]; then
    echo "Missing: $zip_path" >&2
    return 1
  fi
  echo "Extracting: $(basename "$zip_path") -> $DST_DIR" >&2
  # -q quiet, -o overwrite
  unzip -P "$PASS" -q -o "$zip_path" -d "$DST_DIR"
}

extract_one "$SRC_DIR/train.zip"
extract_one "$SRC_DIR/validation.zip"
extract_one "$SRC_DIR/test.zip"

# Optional extra validation metadata (not required for training)
if [[ -f "$SRC_DIR/json_for_validation.zip" ]]; then
  extract_one "$SRC_DIR/json_for_validation.zip"
fi

echo "Done. Extracted to: $DST_DIR" >&2
echo "Next: python3 tools/deepfashion2/verify_deepfashion2.py \"$DST_DIR\"" >&2
