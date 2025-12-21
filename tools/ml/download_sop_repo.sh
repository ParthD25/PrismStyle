#!/usr/bin/env bash
set -euo pipefail

# Clones the SOP Stylish Outfit of Personality dataset repo.
# Note: This repo contains CSV/JSON splits; underlying outfit content may depend on O4U.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/Datasets/sop}"

mkdir -p "$OUT_DIR"

if [[ -d "$OUT_DIR/repo/.git" ]]; then
  echo "SOP repo already present; pulling latest..."
  git -C "$OUT_DIR/repo" pull --ff-only
else
  echo "Cloning SOP repo -> $OUT_DIR/repo"
  git clone https://github.com/dm-mo/SOP-Stylish-Outfit-of-Personality-dataset "$OUT_DIR/repo"
fi

echo "Verifying expected files"
if [[ ! -d "$OUT_DIR/repo/data_train_testing" ]]; then
  echo "Missing: $OUT_DIR/repo/data_train_testing" >&2
  exit 1
fi

ls "$OUT_DIR/repo/data_train_testing" >/dev/null

echo "OK: SOP repo ready at $OUT_DIR/repo"