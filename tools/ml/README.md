# ML Training (Offline)

This folder contains **offline** dataset ingestion + training helpers.

- The iOS app stays **on-device**.
- Datasets are **not** committed to git (see `.gitignore` for `Datasets/`).

## Current implementation status

- ✅ DeepFashion2: download/extract/verify helpers live in `tools/deepfashion2/`.
- ✅ DeepFashion (Kaggle-style folder): ingestion script exists (see below).
- ⏳ Polyvore / SOP: planned (not implemented yet).

## Download linked datasets

Polyvore (metadata, small):

```bash
bash tools/ml/download_polyvore_metadata.sh
```

Polyvore images (Kaggle; requires `kaggle` CLI + credentials):

```bash
bash tools/ml/download_polyvore_images_kaggle.sh
```

SOP (repo contains CSV/JSON splits):

```bash
bash tools/ml/download_sop_repo.sh
```

FashionRecommender (code repo):

```bash
bash tools/ml/download_fashionrecommender_repo.sh
```

## DeepFashion (local folder) ingestion

Given a folder like:

- `/Users/<you>/Downloads/deep_fashion/`
  - `purchase_history.csv`
  - `images/train/*.jpg`
  - `images/val/*.jpg`
  - `images/test/*.jpg`

Generate a JSONL manifest:

```bash
python3 tools/ml/ingest_deep_fashion.py \
  --dataset-root "/Users/parth/Downloads/deep_fashion" \
  --out-manifest "tools/_out/manifests/deep_fashion.jsonl" \
  --out-stats "tools/_out/manifests/deep_fashion.stats.json"
```

The manifest is a set of **outfit-photo records** keyed by `image_id` with:
- split (train/val/test)
- relative image path within the dataset
- associated user IDs
- category/style tags from `purchase_history.csv`

This is intentionally light-weight (stdlib only), so it runs on macOS without extra deps.
