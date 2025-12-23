# Training + Storage Status (Dec 23, 2025)

## What we have in this repo

- iOS app code: `PrismStyle/` (SwiftUI app, CoreML/Vision-related utilities)
- Offline training/data-prep tooling: `tools/`
  - `tools/deepfashion2/` includes scripts/docs for downloading/verifying/extracting DeepFashion2 locally
  - `tools/ml/` includes scripts for Polyvore metadata/images and data augmentation/indexing
- Local datasets folder (on this machine): `Datasets/`
  - **Very large**: `Datasets/DeepFashion2/` (~17GB)
  - **Very large**: `Datasets/polyvore_images/` (~14GB)
  - Smaller/metadata: `Datasets/polyvore/` (~64MB), `Datasets/sop/` (~24MB), `Datasets/fashionrecommender/` (~3MB)

## What we changed today

- Confirmed this workspace is a git repo with remote: `https://github.com/ParthD25/PrismStyle.git`.
- Identified that local datasets total ~31GB, which is not realistic to push to GitHub as normal git content.
- Updated `.gitignore` to:
  - Keep **multi-GB** dataset folders ignored (`Datasets/DeepFashion2/`, `Datasets/polyvore_images/`).
  - Allow lightweight metadata to be tracked (ex: `Datasets/polyvore/polyvore.tar.gz`).
  - Ignore the raw 148MB `phpnBqZGZ.arff` file (too big for normal GitHub pushes).
- Created a compressed version `phpnBqZGZ.arff.gz` (~38MB) so it *can* be committed and pushed.

## What we still need to do (training checklist)

### A) Decide the training target(s)
- **Garment detection/segmentation** (DeepFashion2) → train on GPU (PyTorch/Detectron2/MMDetection/YOLO-seg), export to CoreML.
- **Outfit compatibility / recommendation** (Polyvore) → train a ranking/compatibility model; optionally add image embeddings.

### B) Make training reproducible
- Record exact training commands + dependencies:
  - Create/confirm `tools/ml/requirements.txt` (or a `pyproject.toml`) and pin versions.
  - Document entrypoints: which script to run first, expected outputs, where models land.

### C) Data availability strategy (important)
GitHub is not a good place for the full datasets:
- GitHub has practical limits (large repos and large files cause push/clone failures).
- Even with Git LFS, you’ll run into quota/bandwidth limits quickly for tens of GB.

Recommended approach:
- Keep only *scripts + small metadata* in git.
- Store big datasets in one of:
  - External SSD
  - Cloud bucket (S3/GCS/Azure)
  - Kaggle datasets / HuggingFace datasets (where applicable)
- Use the existing download helpers:
  - `tools/deepfashion2/README.md` and scripts in `tools/deepfashion2/`
  - `tools/ml/download_polyvore_metadata.sh`
  - `tools/ml/download_polyvore_images_kaggle.sh`

### D) Storage triage (so you don’t run out again)
- Move `Datasets/DeepFashion2` and `Datasets/polyvore_images` to an external drive, then symlink back:
  - Example: move to `/Volumes/External/Datasets/...` and `ln -s` back into repo `Datasets/`.
- Keep derived outputs out of the repo (write them into `tools/_out/` or another ignored folder).

## Notes / open questions

- If you *truly* want to back up the full 31GB dataset folders, we should use a dataset storage approach (external drive or cloud), not GitHub.
- If you want, I can add a small script that prints dataset sizes and verifies expected files exist before training.
