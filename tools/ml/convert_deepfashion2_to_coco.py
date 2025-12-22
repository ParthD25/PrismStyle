#!/usr/bin/env python3
"""Convert DeepFashion2 annotations to COCO detection format.

DeepFashion2 per-image annotations live in:
  <root>/<split>/annos/<image_id>.json
Images live in:
  <root>/<split>/image/<image_id>.jpg

Each JSON contains keys like 'source', 'pair_id', and 'item1', 'item2', ...
Each item has:
  - 'bounding_box': [x1, y1, x2, y2]
  - 'category_id': int (1..13)
  - 'category_name': str

This script produces COCO *detection* annotations (bbox only). Segmentation
polygons/masks are not exported here.

Usage:
  python3 tools/ml/convert_deepfashion2_to_coco.py \
    --df2-root Datasets/DeepFashion2 \
    --out-dir tools/_out/deepfashion2_coco \
    --split train

Run once per split (train/validation/test). For test, annotations may be absent.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def _iter_annos(annos_dir: Path):
    for p in sorted(annos_dir.glob("*.json")):
        yield p


def _load_json(p: Path) -> dict:
    with p.open("r", encoding="utf-8") as f:
        return json.load(f)


def _ensure_dir(p: Path) -> None:
    p.mkdir(parents=True, exist_ok=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--df2-root", required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--split", required=True, choices=["train", "validation", "test"])
    ap.add_argument("--limit", type=int, default=0, help="Optional cap on number of images")
    args = ap.parse_args()

    df2_root = Path(args.df2_root).expanduser().resolve()
    split = args.split
    annos_dir = df2_root / split / "annos"
    images_dir = df2_root / split / "image"

    if split == "test" and not annos_dir.exists():
        raise SystemExit("Test annotations not present; cannot build COCO labels")

    if not annos_dir.is_dir():
        raise SystemExit(f"Missing annos dir: {annos_dir}")
    if not images_dir.is_dir():
        raise SystemExit(f"Missing image dir: {images_dir}")

    out_dir = Path(args.out_dir).expanduser().resolve()
    _ensure_dir(out_dir)

    coco = {
        "info": {"description": f"DeepFashion2 {split} -> COCO"},
        "licenses": [],
        "images": [],
        "annotations": [],
        "categories": [],
    }

    cat_id_to_name: dict[int, str] = {}
    image_id = 0
    ann_id = 0

    for anno_path in _iter_annos(annos_dir):
        anno = _load_json(anno_path)
        img_stem = anno_path.stem
        img_name = f"{img_stem}.jpg"
        img_path = images_dir / img_name
        if not img_path.exists():
            # Some datasets might have png; try fallback.
            alt = images_dir / f"{img_stem}.png"
            if alt.exists():
                img_name = alt.name
                img_path = alt
            else:
                continue

        # Image size is stored in annotation JSON for DF2.
        # But to be safe, prefer annotation fields if present.
        height = anno.get("height")
        width = anno.get("width")
        if not (isinstance(height, int) and isinstance(width, int)):
            # Fall back to PIL if missing.
            from PIL import Image

            with Image.open(img_path) as im:
                width, height = im.size

        coco["images"].append(
            {"id": image_id, "file_name": img_name, "width": int(width), "height": int(height)}
        )

        for k, v in anno.items():
            if not (isinstance(k, str) and k.startswith("item")):
                continue
            if not isinstance(v, dict):
                continue

            bbox = v.get("bounding_box")
            cat_id = v.get("category_id")
            cat_name = v.get("category_name")
            if (
                not isinstance(bbox, list)
                or len(bbox) != 4
                or not all(isinstance(x, (int, float)) for x in bbox)
            ):
                continue
            if not isinstance(cat_id, int):
                continue
            if isinstance(cat_name, str):
                cat_id_to_name.setdefault(cat_id, cat_name)

            x1, y1, x2, y2 = bbox
            w = max(0.0, float(x2) - float(x1))
            h = max(0.0, float(y2) - float(y1))
            if w <= 1.0 or h <= 1.0:
                continue

            coco["annotations"].append(
                {
                    "id": ann_id,
                    "image_id": image_id,
                    "category_id": cat_id,
                    "bbox": [float(x1), float(y1), w, h],
                    "area": float(w * h),
                    "iscrowd": 0,
                    "segmentation": [],
                }
            )
            ann_id += 1

        image_id += 1
        if args.limit and image_id >= args.limit:
            break

    # COCO categories: ids should be contiguous in many trainers, but we keep DF2 ids.
    for cid in sorted(cat_id_to_name.keys()):
        coco["categories"].append({"id": cid, "name": cat_id_to_name[cid], "supercategory": "clothing"})

    out_json = out_dir / f"instances_{split}.json"
    out_classes = out_dir / "classes.txt"

    with out_json.open("w", encoding="utf-8") as f:
        json.dump(coco, f)

    with out_classes.open("w", encoding="utf-8") as f:
        for cid in sorted(cat_id_to_name.keys()):
            f.write(f"{cid}\t{cat_id_to_name[cid]}\n")

    print(f"Wrote: {out_json}")
    print(f"Images: {len(coco['images'])}  Annotations: {len(coco['annotations'])}  Categories: {len(coco['categories'])}")
    print(f"Wrote: {out_classes}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
