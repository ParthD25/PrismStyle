#!/usr/bin/env python3
"""Index Polyvore images to item_uids.

Expected image layout (as in the common Kaggle mirror):
  <images_root>/images/<set_id>/<index>.jpg

Our Polyvore ingestion emits items with:
  item_uid = "polyvore:<set_id>_<index>"

This script produces a JSONL mapping:
  {"item_uid": ..., "image_relpath": ..., "exists": true}

Usage:
  python3 tools/ml/index_polyvore_images.py \
    --images-root "Datasets/polyvore_images" \
    --out "tools/_out/manifests/polyvore_item_images.jsonl"
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--images-root", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    root = Path(args.images_root).expanduser().resolve()
    if not root.exists():
        raise SystemExit(f"Not found: {root}")

    # Find the base images folder.
    base = root / "images"
    if not base.exists():
        # allow pointing directly at the 'images' folder
        if root.name == "images":
            base = root
        else:
            raise SystemExit(f"Missing expected folder: {root / 'images'}")

    out_path = Path(args.out).expanduser().resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)

    written = 0
    # One directory per set_id
    with out_path.open("w", encoding="utf-8") as f:
        for set_dir in sorted(p for p in base.iterdir() if p.is_dir()):
            set_id = set_dir.name
            for jpg in sorted(set_dir.glob("*.jpg")):
                idx = jpg.stem
                item_uid = f"polyvore:{set_id}_{idx}"
                f.write(
                    json.dumps(
                        {
                            "item_uid": item_uid,
                            "set_id": set_id,
                            "index": idx,
                            "image_relpath": jpg.relative_to(root).as_posix(),
                            "exists": True,
                        },
                        ensure_ascii=False,
                    )
                    + "\n"
                )
                written += 1

    print(f"Wrote {written} item image mappings -> {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
