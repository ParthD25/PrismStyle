#!/usr/bin/env python3
"""Augment Polyvore outfit manifest with local image paths.

Reads:
- outfits JSONL from tools/ml/ingest_polyvore.py
- item image mapping JSONL from tools/ml/index_polyvore_images.py

Writes:
- a new outfits JSONL where each item gains:
  - local_image_relpath (relative to images_root)
  - local_image_abspath

Usage:
  python3 tools/ml/augment_polyvore_outfits_with_images.py \
    --outfits-in tools/_out/manifests/polyvore_outfits.jsonl \
    --item-images tools/_out/manifests/polyvore_item_images.jsonl \
    --images-root Datasets/polyvore_images \
    --outfits-out tools/_out/manifests/polyvore_outfits_with_images.jsonl
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def _load_item_map(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            uid = obj.get("item_uid")
            rel = obj.get("image_relpath")
            if uid and rel:
                out[uid] = rel
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--outfits-in", required=True)
    ap.add_argument("--item-images", required=True)
    ap.add_argument("--images-root", required=True)
    ap.add_argument("--outfits-out", required=True)
    args = ap.parse_args()

    outfits_in = Path(args.outfits_in).expanduser().resolve()
    item_images = Path(args.item_images).expanduser().resolve()
    images_root = Path(args.images_root).expanduser().resolve()
    outfits_out = Path(args.outfits_out).expanduser().resolve()
    outfits_out.parent.mkdir(parents=True, exist_ok=True)

    if not images_root.exists():
        raise SystemExit(f"Not found: {images_root}")

    mapping = _load_item_map(item_images)

    total_outfits = 0
    total_items = 0
    resolved = 0

    with outfits_in.open("r", encoding="utf-8") as fin, outfits_out.open("w", encoding="utf-8") as fout:
        for line in fin:
            line = line.strip()
            if not line:
                continue
            o = json.loads(line)
            items = o.get("items") or []
            for it in items:
                total_items += 1
                uid = it.get("item_uid")
                rel = mapping.get(uid)
                if rel:
                    it["local_image_relpath"] = rel
                    it["local_image_abspath"] = str((images_root / rel).resolve())
                    resolved += 1
            total_outfits += 1
            fout.write(json.dumps(o, ensure_ascii=False) + "\n")

    pct = (resolved / total_items * 100.0) if total_items else 0.0
    print(f"Outfits: {total_outfits}")
    print(f"Items: {total_items}")
    print(f"Resolved images: {resolved} ({pct:.1f}%)")
    print(f"Wrote: {outfits_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
