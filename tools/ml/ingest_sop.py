#!/usr/bin/env python3
"""Ingest SOP Stylish Outfit of Personality CSVs into JSONL manifests.

This dataset is primarily user<->outfit interaction pairs (pos/neg).
It does not necessarily include outfit images/items, so we store only IDs and labels.

Usage:
  python3 tools/ml/ingest_sop.py \
    --sop-dir "Datasets/sop/repo/data_train_testing" \
    --out "tools/_out/manifests/sop_interactions.jsonl"
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


def _iter_csv_rows(path: Path):
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            yield {k: (v or "").strip() for k, v in row.items() if k is not None}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sop-dir", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    root = Path(args.sop_dir).expanduser().resolve()
    if not root.exists():
        raise SystemExit(f"Not found: {root}")

    out_path = Path(args.out).expanduser().resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # Prefer the explicit train/val/test splits if present.
    candidates = sorted(root.glob("user_outfit_*_*.csv"))
    if not candidates:
        raise SystemExit(f"No SOP CSVs found under: {root}")

    written = 0
    with out_path.open("w", encoding="utf-8") as f:
        for p in candidates:
            name = p.name
            # crude split inference from filename
            split = None
            for s in ("train", "val", "test", "testing", "testing100"):
                if name.endswith(f"_{s}.csv"):
                    split = s
                    break

            for row in _iter_csv_rows(p):
                # common columns: user_idx,user_id,outfit_id,matched
                rec = {
                    "source": "sop",
                    "split": split,
                    "file": name,
                    "user_id": row.get("user_id") or row.get("user_idx"),
                    "outfit_id": row.get("outfit_id"),
                    "matched": row.get("matched"),
                }
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")
                written += 1

    print(f"Wrote SOP interactions: {written} -> {out_path}")
    print("NOTE: SOP does not include outfit item images by itself; link via O4U if available.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
