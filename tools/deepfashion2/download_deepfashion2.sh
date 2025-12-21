#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-Datasets/DeepFashion2}"

mkdir -p "$TARGET_DIR"

echo "Downloading OpenDataLab/DeepFashion2 into: $TARGET_DIR"
echo "NOTE: This script assumes you already ran: openxlab login"

echo "Attempting: openxlab dataset get (full dataset)"
if openxlab dataset get --dataset-repo OpenDataLab/DeepFashion2 --target-path "$TARGET_DIR"; then
  echo "Download complete."
  exit 0
fi

echo "Your openxlab version may not support --target-path for 'dataset get'."
echo "Falling back to running without --target-path (downloads into current directory)."
(
  cd "$TARGET_DIR"
  openxlab dataset get --dataset-repo OpenDataLab/DeepFashion2
)

echo "Download complete."
