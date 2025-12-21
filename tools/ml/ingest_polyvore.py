#!/usr/bin/env python3
"""Ingest Polyvore metadata into a simple JSONL manifest.

This supports the file layout produced by tools/ml/download_polyvore_metadata.sh.

Outputs:
- A JSONL file of outfit records (train/val/test)
- A JSONL file of FITB questions (test only)

We intentionally keep this stdlib-only.

Usage:
  python3 tools/ml/ingest_polyvore.py \
    --polyvore-dir "Datasets/polyvore" \
    --out-outfits "tools/_out/manifests/polyvore_outfits.jsonl" \
    --out-fitb "tools/_out/manifests/polyvore_fitb.jsonl"
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def _read_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _pick_fitb_file(root: Path) -> Path:
    for name in ("fill_in_blank_test.json", "fill_in_the_blank_test.json"):
        p = root / name
        if p.exists():
            return p
    raise FileNotFoundError("Missing FITB json (fill_in_blank_test.json or fill_in_the_blank_test.json)")


def _pick_compat_file(root: Path) -> Path:
    for name in ("fashion_compatibility_prediction.txt", "fashion-compatibility-prediction.txt"):
        p = root / name
        if p.exists():
            return p
    raise FileNotFoundError("Missing compatibility txt (fashion_compatibility_prediction.txt or fashion-compatibility-prediction.txt)")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--polyvore-dir", required=True)
    ap.add_argument("--out-outfits", required=True)
    ap.add_argument("--out-fitb", required=True)
    args = ap.parse_args()

    root = Path(args.polyvore_dir).expanduser().resolve()
    if not root.exists():
        raise SystemExit(f"Not found: {root}")

    out_outfits = Path(args.out_outfits).expanduser().resolve()
    out_fitb = Path(args.out_fitb).expanduser().resolve()
    out_outfits.parent.mkdir(parents=True, exist_ok=True)
    out_fitb.parent.mkdir(parents=True, exist_ok=True)

    split_map = {
        "train": root / "train_no_dup.json",
        "val": root / "valid_no_dup.json",
        "test": root / "test_no_dup.json",
    }

    outfits_written = 0
    items_written = 0

    with out_outfits.open("w", encoding="utf-8") as f:
        for split, path in split_map.items():
            if not path.exists():
                raise SystemExit(f"Missing split file: {path}")
            outfits = _read_json(path)
            if not isinstance(outfits, list):
                raise SystemExit(f"Unexpected JSON structure in {path}")

            for o in outfits:
                set_id = str(o.get("set_id", ""))
                if not set_id:
                    continue
                items = o.get("items", []) or []
                norm_items = []
                for it in items[:8]:
                    idx = it.get("index")
                    cid = it.get("categoryid")
                    norm_items.append(
                        {
                            "item_uid": f"polyvore:{set_id}_{idx}",
                            "set_id": set_id,
                            "index": idx,
                            "categoryid": cid,
                            "name": it.get("name"),
                            "price": it.get("price"),
                            "likes": it.get("likes"),
                            "image_url": it.get("image"),
                        }
                    )
                    items_written += 1

                rec = {
                    "source": "polyvore",
                    "split": split,
                    "outfit_uid": f"polyvore:{set_id}",
                    "set_id": set_id,
                    "set_url": o.get("set_url"),
                    "date": o.get("date"),
                    "desc": o.get("desc"),
                    "items": norm_items,
                }
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")
                outfits_written += 1

    # FITB questions
    fitb_path = _pick_fitb_file(root)
    fitb = _read_json(fitb_path)
    fitb_written = 0

    with out_fitb.open("w", encoding="utf-8") as f:
        # Expected: list[dict]
        for q in fitb:
            qid = q.get("question")
            blank_pos = q.get("blank_position")
            answers = q.get("answers") or []
            f.write(
                json.dumps(
                    {
                        "source": "polyvore",
                        "question_id": qid,
                        "blank_position": blank_pos,
                        "answers": answers,
                        "correct_answer": answers[0] if answers else None,
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )
            fitb_written += 1

    # Compatibility labels file presence check (we don't parse it yet; different formats exist).
    _ = _pick_compat_file(root)

    print(f"Wrote outfits: {outfits_written} -> {out_outfits}")
    print(f"Wrote FITB questions: {fitb_written} -> {out_fitb}")
    print(f"Total items referenced (first 8 per outfit): {items_written}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
