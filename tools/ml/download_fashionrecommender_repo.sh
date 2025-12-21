#!/usr/bin/env bash
set -euo pipefail

# Clones the FashionRecommender repo. Dataset download is separate (often via Kaggle).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/Datasets/fashionrecommender}"

mkdir -p "$OUT_DIR"

if [[ -d "$OUT_DIR/repo/.git" ]]; then
  echo "FashionRecommender repo already present; pulling latest..."
  git -C "$OUT_DIR/repo" pull --ff-only
else
  echo "Cloning FashionRecommender repo -> $OUT_DIR/repo"
  git clone https://github.com/meddjilani/FashionRecommender "$OUT_DIR/repo"
fi

echo "OK: FashionRecommender repo ready at $OUT_DIR/repo"

echo "NOTE: To download its referenced Kaggle dataset you still need Kaggle credentials and python deps."
