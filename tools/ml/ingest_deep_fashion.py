#!/usr/bin/env python3
"""Build a simple training manifest from a local 'deep_fashion' folder.

Expected layout:
  <root>/purchase_history.csv
  <root>/images/train/*.jpg
  <root>/images/val/*.jpg
  <root>/images/test/*.jpg

This script outputs a JSONL manifest of outfit-photo records keyed by image_id.

Notes:
- Some Kaggle exports have a corrupted header where 'rating' is split across a newline
  ('rati\nng'). This script repairs that during parsing.
- We do not assume per-item bounding boxes; items are tag-level (category/style).

Usage:
  python3 tools/ml/ingest_deep_fashion.py \
    --dataset-root "/Users/parth/Downloads/deep_fashion" \
    --out-manifest "tools/_out/manifests/deep_fashion.jsonl" \
    --out-stats "tools/_out/manifests/deep_fashion.stats.json"
"""

from __future__ import annotations

import argparse
import csv
import io
import json
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ImageRecord:
    outfit_uid: str
    image_id: str
    split: str
    image_relpath: str


def _iter_images(dataset_root: Path) -> list[ImageRecord]:
    """Return ImageRecord list from images/{train,val,test}/*.jpg.

    Some exports reuse the same numeric filename across splits (e.g. 000152.jpg
    appears in train *and* val). To preserve splits, we emit a unique
    `outfit_uid = "<split>:<image_id>"`.
    """
    images_dir = dataset_root / "images"
    out: list[ImageRecord] = []
    for split in ("train", "val", "test"):
        split_dir = images_dir / split
        if not split_dir.exists():
            continue
        for p in sorted(split_dir.glob("*.jpg")):
            image_id = p.stem
            rel = p.relative_to(dataset_root).as_posix()
            outfit_uid = f"{split}:{image_id}"
            out.append(ImageRecord(outfit_uid=outfit_uid, image_id=image_id, split=split, image_relpath=rel))
    return out


def _repair_purchase_history_csv(raw: bytes) -> str:
    """Repair a common broken-header variant and return a decoded CSV string."""
    text = raw.decode("utf-8", errors="replace")

    # Fast path: header is fine.
    first_line_end = text.find("\n")
    if first_line_end != -1:
        header = text[:first_line_end]
        if "rating" in header and "occasion" in header:
            return text

    # Repair known corruption: 'rati\nng' split across newline.
    text = text.replace("rati\nng", "rating")

    # Sometimes the file contains an extra newline only in the header; ensure we have a single header line.
    lines = text.splitlines(keepends=True)
    if not lines:
        return ""

    header_lines: list[str] = []
    while lines and len(header_lines) < 5:
        header_lines.append(lines.pop(0))
        candidate = "".join(header_lines)
        # Heuristic: header line should contain these columns.
        if "user_id" in candidate and "image_id" in candidate and "rating" in candidate and "occasion" in candidate:
            # Collapse any embedded newlines in the header candidate.
            header_one_line = candidate.replace("\r", "").replace("\n", "")
            remainder = "".join(lines)
            return header_one_line + "\n" + remainder

    # Fallback: return whatever we have (best effort).
    return text


def _load_purchase_history(dataset_root: Path) -> list[dict[str, str]]:
    path = dataset_root / "purchase_history.csv"
    raw = path.read_bytes()
    repaired = _repair_purchase_history_csv(raw)
    if not repaired.strip():
        return []

    reader = csv.DictReader(io.StringIO(repaired))
    rows: list[dict[str, str]] = []
    for row in reader:
        # Some rows may be malformed; keep best-effort.
        if not row:
            continue
        rows.append({k: (v or "").strip() for k, v in row.items() if k is not None})
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset-root", required=True, help="Path to deep_fashion root")
    parser.add_argument("--out-manifest", required=True, help="Output JSONL path")
    parser.add_argument("--out-stats", default="", help="Optional output stats JSON")
    args = parser.parse_args()

    dataset_root = Path(args.dataset_root).expanduser().resolve()
    if not dataset_root.exists():
        raise SystemExit(f"Dataset root not found: {dataset_root}")

    images = _iter_images(dataset_root)
    if not images:
        raise SystemExit(f"No images found under: {dataset_root / 'images'}")

    rows = _load_purchase_history(dataset_root)

    # Group purchase_history by image_id.
    by_image: dict[str, list[dict[str, str]]] = defaultdict(list)
    for r in rows:
        image_id = r.get("image_id", "")
        if not image_id:
            continue
        by_image[image_id].append(r)

    out_path = Path(args.out_manifest).expanduser().resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)

    split_counts = Counter()
    with_meta = 0
    missing_meta = 0
    category_counts = Counter()
    style_counts = Counter()

    # Emit one record per image in images/*.
    ordered = sorted(images, key=lambda r: (r.split, r.image_id))
    with out_path.open("w", encoding="utf-8") as f:
        for img in ordered:
            meta_rows = by_image.get(img.image_id, [])

            user_ids: list[str] = []
            items: list[dict[str, str]] = []
            seasons: list[str] = []
            occasions: list[str] = []
            ratings: list[str] = []

            for m in meta_rows:
                uid = m.get("user_id", "")
                if uid and uid not in user_ids:
                    user_ids.append(uid)

                cat = m.get("category", "")
                sty = m.get("style", "")
                if cat or sty:
                    items.append({"category": cat, "style": sty})
                if cat:
                    category_counts[cat] += 1
                if sty:
                    style_counts[sty] += 1

                if m.get("season"):
                    seasons.append(m["season"])
                if m.get("occasion"):
                    occasions.append(m["occasion"])
                if m.get("rating"):
                    ratings.append(m["rating"])

            split_counts[img.split] += 1
            if meta_rows:
                with_meta += 1
            else:
                missing_meta += 1

            record = {
                "source": "deep_fashion",
                "outfit_uid": img.outfit_uid,
                "image_id": img.image_id,
                "split": img.split,
                "image_relpath": img.image_relpath,
                "dataset_root": str(dataset_root),
                "user_ids": user_ids,
                "items": items,
                "seasons": seasons,
                "occasions": occasions,
                "ratings": ratings,
            }
            f.write(json.dumps(record, ensure_ascii=False) + "\n")

    stats = {
        "dataset_root": str(dataset_root),
        "images_total": sum(split_counts.values()),
        "images_by_split": dict(split_counts),
        "records_with_metadata": with_meta,
        "records_missing_metadata": missing_meta,
        "top_categories": category_counts.most_common(30),
        "top_styles": style_counts.most_common(30),
    }

    if args.out_stats:
        stats_path = Path(args.out_stats).expanduser().resolve()
        stats_path.parent.mkdir(parents=True, exist_ok=True)
        stats_path.write_text(json.dumps(stats, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(json.dumps(stats, indent=2, ensure_ascii=False))
    print(f"\nWrote manifest: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
