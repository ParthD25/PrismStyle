#!/usr/bin/env python3
"""Smoke-train a tiny image embedder on deep_fashion.

Goal: verify end-to-end training wiring on macOS (MPS if available, else CPU).
This is intentionally minimal and not a final model.

We treat the task as multi-class classification over the *most common category*
in the manifest record (first item category). This is a quick sanity check.

Usage:
  python3 tools/ml/train_deep_fashion_embedder_smoke.py \
    --manifest tools/_out/manifests/deep_fashion.jsonl \
    --max-samples 256 \
    --epochs 1

Notes:
- Requires: torch, torchvision, pillow
- Does not write large checkpoints by default.
"""

from __future__ import annotations

import argparse
import json
import random
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


def _choose_device() -> str:
    import torch

    if torch.backends.mps.is_available() and torch.backends.mps.is_built():
        return "mps"
    if torch.cuda.is_available():
        return "cuda"
    return "cpu"


@dataclass
class Sample:
    image_path: Path
    label: int


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--max-samples", type=int, default=256)
    ap.add_argument("--epochs", type=int, default=1)
    ap.add_argument(
        "--pretrained",
        action="store_true",
        help="Use torchvision pretrained weights (may require network access).",
    )
    ap.add_argument("--seed", type=int, default=1337)
    args = ap.parse_args()

    random.seed(args.seed)

    manifest_path = Path(args.manifest).expanduser().resolve()
    rows = []
    with manifest_path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            rows.append(json.loads(line))

    # Build label space from most common categories.
    cat_counter = Counter()
    for r in rows:
        items = r.get("items") or []
        if not items:
            continue
        cat = (items[0].get("category") or "").strip()
        if cat:
            cat_counter[cat] += 1

    if not cat_counter:
        raise SystemExit("No categories found in manifest")

    # Keep a manageable number of classes for the smoke run.
    top_cats = [c for c, _ in cat_counter.most_common(12)]
    cat_to_idx = {c: i for i, c in enumerate(top_cats)}

    samples: list[Sample] = []
    for r in rows:
        items = r.get("items") or []
        if not items:
            continue
        cat = (items[0].get("category") or "").strip()
        if cat not in cat_to_idx:
            continue
        dataset_root = Path(r["dataset_root"])
        image_relpath = r["image_relpath"]
        p = dataset_root / image_relpath
        if not p.exists():
            continue
        samples.append(Sample(image_path=p, label=cat_to_idx[cat]))

    random.shuffle(samples)
    samples = samples[: max(1, min(args.max_samples, len(samples)))]

    print(f"Loaded {len(samples)} samples across {len(cat_to_idx)} classes")
    print("Top classes:")
    for c in top_cats:
        print(f"  - {c}: {cat_counter[c]}")

    # Torch bits
    import torch
    import torch.nn as nn
    import torch.optim as optim
    from PIL import Image
    from torchvision import models, transforms

    device = _choose_device()
    print(f"Using device: {device}")

    tfm = transforms.Compose(
        [
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )

    class DS(torch.utils.data.Dataset):
        def __init__(self, samples: list[Sample]):
            self.samples = samples

        def __len__(self):
            return len(self.samples)

        def __getitem__(self, idx):
            s = self.samples[idx]
            img = Image.open(s.image_path).convert("RGB")
            x = tfm(img)
            y = torch.tensor(s.label, dtype=torch.long)
            return x, y

    ds = DS(samples)
    dl = torch.utils.data.DataLoader(ds, batch_size=16, shuffle=True, num_workers=0)

    # Small model: resnet18 head. Default to random init to avoid network downloads.
    weights = models.ResNet18_Weights.DEFAULT if args.pretrained else None
    model = models.resnet18(weights=weights)
    model.fc = nn.Linear(model.fc.in_features, len(cat_to_idx))
    model = model.to(device)

    opt = optim.Adam(model.parameters(), lr=1e-3)
    loss_fn = nn.CrossEntropyLoss()

    model.train()
    for epoch in range(args.epochs):
        total = 0.0
        correct = 0
        seen = 0
        for xb, yb in dl:
            xb = xb.to(device)
            yb = yb.to(device)

            opt.zero_grad(set_to_none=True)
            logits = model(xb)
            loss = loss_fn(logits, yb)
            loss.backward()
            opt.step()

            total += float(loss.item()) * int(xb.size(0))
            pred = logits.argmax(dim=1)
            correct += int((pred == yb).sum().item())
            seen += int(xb.size(0))

        print(f"epoch={epoch+1} loss={total/seen:.4f} acc={correct/seen:.3f}")

    print("Smoke train complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
