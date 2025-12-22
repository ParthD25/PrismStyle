#!/usr/bin/env python3
"""Smoke-train a detector on DeepFashion2 COCO export.

This is intentionally minimal and meant to run on macOS (MPS/CPU).
It trains for a few iterations to validate:
- COCO JSON is valid
- images load
- torchvision detection training loop runs

Usage:
  python3 tools/ml/train_deepfashion2_frcnn_smoke.py \
    --df2-root Datasets/DeepFashion2 \
    --coco tools/_out/deepfashion2_coco/instances_train.json \
    --split train \
    --max-images 200 \
    --steps 50

Requires: torch, torchvision, pillow
"""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path


def _choose_device() -> str:
    import torch

    if torch.backends.mps.is_available() and torch.backends.mps.is_built():
        return "mps"
    if torch.cuda.is_available():
        return "cuda"
    return "cpu"


def _load_coco(coco_path: Path) -> dict:
    with coco_path.open("r", encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--df2-root", required=True)
    ap.add_argument("--coco", required=True)
    ap.add_argument("--split", required=True, choices=["train", "validation"])
    ap.add_argument("--max-images", type=int, default=200)
    ap.add_argument("--steps", type=int, default=50)
    ap.add_argument("--seed", type=int, default=1337)
    args = ap.parse_args()

    random.seed(args.seed)

    df2_root = Path(args.df2_root).expanduser().resolve()
    images_dir = df2_root / args.split / "image"
    coco_path = Path(args.coco).expanduser().resolve()

    coco = _load_coco(coco_path)
    images = coco.get("images") or []
    anns = coco.get("annotations") or []
    cats = coco.get("categories") or []

    if not images:
        raise SystemExit("COCO has no images")

    # Build image_id -> annotations
    imgid_to_anns: dict[int, list[dict]] = {}
    for a in anns:
        imgid_to_anns.setdefault(int(a["image_id"]), []).append(a)

    # Determine class id mapping (COCO category_id can be non-contiguous)
    cat_ids = sorted({int(c["id"]) for c in cats})
    if not cat_ids:
        raise SystemExit("COCO has no categories")

    # Map DF2 category ids to contiguous [1..K] (0 is background)
    cat_to_contig = {cid: i + 1 for i, cid in enumerate(cat_ids)}
    num_classes = 1 + len(cat_ids)

    import torch
    from PIL import Image
    from torchvision import transforms
    from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn

    device = _choose_device()
    print(f"Using device: {device}")
    print(f"num_classes (incl bg): {num_classes}")

    tfm = transforms.Compose([
        transforms.ToTensor(),
    ])

    # Sample a subset for smoke
    subset = images[:]
    random.shuffle(subset)
    subset = subset[: min(len(subset), args.max_images)]

    class DS(torch.utils.data.Dataset):
        def __init__(self, subset_images: list[dict]):
            self.images = subset_images

        def __len__(self):
            return len(self.images)

        def __getitem__(self, idx):
            im = self.images[idx]
            img_id = int(im["id"])
            fp = images_dir / im["file_name"]
            img = tfm(Image.open(fp).convert("RGB"))

            ann_list = imgid_to_anns.get(img_id, [])
            boxes = []
            labels = []
            areas = []
            for a in ann_list:
                x, y, w, h = a["bbox"]
                if w <= 1 or h <= 1:
                    continue
                boxes.append([x, y, x + w, y + h])
                labels.append(cat_to_contig[int(a["category_id"])])
                areas.append(float(a.get("area", w * h)))

            target = {
                "boxes": torch.tensor(boxes, dtype=torch.float32),
                "labels": torch.tensor(labels, dtype=torch.int64),
                "image_id": torch.tensor([img_id], dtype=torch.int64),
                "area": torch.tensor(areas, dtype=torch.float32) if areas else torch.zeros((0,), dtype=torch.float32),
                "iscrowd": torch.zeros((len(boxes),), dtype=torch.int64),
            }
            return img, target

    def collate(batch):
        imgs, targets = zip(*batch)
        return list(imgs), list(targets)

    dl = torch.utils.data.DataLoader(DS(subset), batch_size=2, shuffle=True, num_workers=0, collate_fn=collate)

    model = fasterrcnn_mobilenet_v3_large_fpn(weights=None, weights_backbone=None, num_classes=num_classes)
    model.to(device)

    params = [p for p in model.parameters() if p.requires_grad]
    opt = torch.optim.SGD(params, lr=0.005, momentum=0.9, weight_decay=0.0005)

    model.train()
    step = 0
    for epoch in range(10_000):
        for imgs, targets in dl:
            imgs = [im.to(device) for im in imgs]
            targets = [{k: v.to(device) for k, v in t.items()} for t in targets]

            loss_dict = model(imgs, targets)
            loss = sum(loss_dict.values())

            opt.zero_grad(set_to_none=True)
            loss.backward()
            opt.step()

            step += 1
            if step % 10 == 0:
                ld = {k: float(v.detach().cpu().item()) for k, v in loss_dict.items()}
                print(f"step={step} loss={float(loss.detach().cpu().item()):.4f} parts={ld}")
            if step >= args.steps:
                print("DeepFashion2 detector smoke train complete.")
                return 0


if __name__ == "__main__":
    raise SystemExit(main())
