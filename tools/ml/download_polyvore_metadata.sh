#!/usr/bin/env bash
set -euo pipefail

# Downloads Polyvore metadata bundle (NOT images) into Datasets/polyvore.
# Images are typically sourced separately (often via Kaggle), and may require
# separate terms acceptance.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/Datasets/polyvore}"

mkdir -p "$OUT_DIR"

URL="https://github.com/xthan/polyvore-dataset/raw/refs/heads/master/polyvore.tar.gz"
ARCHIVE="$OUT_DIR/polyvore.tar.gz"

echo "Downloading Polyvore metadata -> $ARCHIVE"
curl -L "$URL" -o "$ARCHIVE"

echo "Extracting -> $OUT_DIR"
tar -xzf "$ARCHIVE" -C "$OUT_DIR"

# Some files are not in the tarball; fetch them directly from the repo.
CAT_URL="https://github.com/xthan/polyvore-dataset/raw/refs/heads/master/category_id.txt"
echo "Fetching category map -> $OUT_DIR/category_id.txt"
curl -L "$CAT_URL" -o "$OUT_DIR/category_id.txt"

echo "Verifying expected files"

# Archive filename variants observed in the wild.
if [[ -f "$OUT_DIR/fill_in_blank_test.json" ]]; then
  true
elif [[ -f "$OUT_DIR/fill_in_the_blank_test.json" ]]; then
  true
else
  echo "Missing expected FITB file (fill_in_blank_test.json or fill_in_the_blank_test.json)" >&2
  exit 1
fi

if [[ -f "$OUT_DIR/fashion_compatibility_prediction.txt" ]]; then
  true
elif [[ -f "$OUT_DIR/fashion-compatibility-prediction.txt" ]]; then
  true
else
  echo "Missing expected compatibility labels file (fashion_compatibility_prediction.txt or fashion-compatibility-prediction.txt)" >&2
  exit 1
fi

for f in train_no_dup.json valid_no_dup.json test_no_dup.json category_id.txt; do
  if [[ ! -f "$OUT_DIR/$f" ]]; then
    echo "Missing expected file: $OUT_DIR/$f" >&2
    exit 1
  fi
done

echo "OK: Polyvore metadata ready at $OUT_DIR"