# DeepFashion2 (Offline Training Pipeline)

This repo **does not** include DeepFashion2 (it’s multi‑GB). The app stays **on-device**; training happens **offline** and you ship only a Core ML model.

## Security note
- Do **not** paste AK/SK into this repo or scripts.
- Run `openxlab login` interactively on your machine.
- Rotate any keys that were exposed.

## 1) Install + login (local)
```bash
pip install -U openxlab
openxlab login
```

## 2) Download dataset (local)
This repo already ignores `Datasets/` in `.gitignore`.

Recommended target:
- `Datasets/DeepFashion2/`

Run:
```bash
bash tools/deepfashion2/download_deepfashion2.sh "Datasets/DeepFashion2"
```

## 3) Verify dataset structure
```bash
python3 tools/deepfashion2/verify_deepfashion2.py "Datasets/DeepFashion2"
```

## 4) Training + export (next step)
DeepFashion2 training is typically done with a GPU using PyTorch (Detectron2 / MMDetection / YOLO‑seg).
Once you have a trained model, export to Core ML and integrate via `VNCoreMLRequest`.

This repo currently provides:
- Download helper: `tools/deepfashion2/download_deepfashion2.sh`
- Dataset sanity-checker: `tools/deepfashion2/verify_deepfashion2.py`

If you want, we can add:
- COCO -> YOLO conversion scripts
- A reproducible training command (YOLOv8-seg recommended for practicality)
- Core ML export + quantization (coremltools)
