#!/usr/bin/env python3
"""Sanity-check a local DeepFashion2 download.

DeepFashion2 commonly ships as encrypted zip files containing:

    train/
        image/*.jpg
        annos/*.json
    validation/
        image/*.jpg
        annos/*.json
    test/
        image/*.jpg

This script supports either:
- extracted folders (preferred), or
- a folder that still contains the zip bundles (it will warn).

Usage:
    python3 tools/deepfashion2/verify_deepfashion2.py Datasets/DeepFashion2
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def _find_files(root: Path, patterns: list[str]) -> list[Path]:
    out: list[Path] = []
    for pat in patterns:
        out.extend(root.rglob(pat))
    # dedupe while preserving order
    seen: set[Path] = set()
    unique: list[Path] = []
    for p in out:
        if p not in seen:
            seen.add(p)
            unique.append(p)
    return unique


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: verify_deepfashion2.py <deepfashion2_root>")
        return 2

    root = Path(sys.argv[1]).expanduser().resolve()
    if not root.exists():
        print(f"Not found: {root}")
        return 2

    print(f"DeepFashion2 root: {root}")

    # If the user has only the zips downloaded (common), detect that quickly.
    zip_candidates = [p for p in root.glob("*.zip") if p.is_file()]
    if zip_candidates:
        names = {p.name for p in zip_candidates}
        if {"train.zip", "validation.zip", "test.zip"}.intersection(names):
            print("\nDetected DeepFashion2 zip bundles (not extracted yet):")
            for p in sorted(zip_candidates)[:20]:
                size_mb = p.stat().st_size / (1024 * 1024)
                print(f"  - {p.name} ({size_mb:,.1f} MB)")
            print("\nThese zips are often encrypted. Extract them first (password required) then re-run this verifier.")
            print("Repo helper: tools/deepfashion2/extract_deepfashion2.sh (in the app repo)")
            # Continue checking extracted layout too in case both exist.

    # Prefer DeepFashion2 native layout checks.
    def count_split(split: str) -> tuple[int, int]:
        img_dir = root / split / "image"
        anno_dir = root / split / "annos"
        imgs = 0
        annos = 0
        if img_dir.exists():
            imgs = len(list(img_dir.glob("*.jpg"))) + len(list(img_dir.glob("*.jpeg"))) + len(list(img_dir.glob("*.png")))
        if anno_dir.exists():
            annos = len(list(anno_dir.glob("*.json")))
        return imgs, annos

    train_imgs, train_annos = count_split("train")
    val_imgs, val_annos = count_split("validation")
    test_imgs, test_annos = count_split("test")

    if any([train_imgs, train_annos, val_imgs, val_annos, test_imgs]):
        print("\nExtracted DeepFashion2 layout detected:")
        print(f"  train: images={train_imgs:,} annos={train_annos:,}")
        print(f"  validation: images={val_imgs:,} annos={val_annos:,}")
        print(f"  test: images={test_imgs:,} annos={test_annos:,}")

        ok = train_imgs > 0 and train_annos > 0 and val_imgs > 0 and val_annos > 0
        if not ok:
            print("\nWARNING: Some splits look incomplete (images/annos missing).")
            return 1

        return 0

    # Fallback: try COCO-style json detection if the dataset is pre-converted.
    jsons = _find_files(root, ["*.json"])
    candidates: list[Path] = []
    for p in jsons:
        name = p.name.lower()
        if any(k in name for k in ["coco", "instances", "annotations", "train", "val", "test"]):
            candidates.append(p)

    coco: tuple[Path, dict] | None = None
    for p in candidates:
        try:
            with p.open("r", encoding="utf-8") as f:
                data = json.load(f)
            if isinstance(data, dict) and {"images", "annotations"}.issubset(data.keys()):
                coco = (p, data)
                break
        except Exception:
            continue

    if coco:
        p, data = coco
        images = data.get("images", [])
        annotations = data.get("annotations", [])
        categories = data.get("categories", [])
        print("\nCOCO annotation detected:")
        print(f"  file: {p.relative_to(root)}")
        print(f"  images: {len(images)}")
        print(f"  annotations: {len(annotations)}")
        print(f"  categories: {len(categories)}")
        return 0

    print("\nNo extracted DeepFashion2 folders detected yet (and no COCO json found).")
    print("If you only have encrypted zip bundles, extract them first with the dataset password.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
