#!/usr/bin/env python3
"""Smoke-train an image embedder on Polyvore using positive/negative pairs.

This is a quick sanity check that:
- Polyvore outfits can be resolved to local item images
- We can build pair samples (positive = same outfit; negative = different outfit)
- A small model trains on MPS/CPU end-to-end

Task: binary classify whether a pair of items comes from the same outfit.
This is NOT the final compatibility model (which should be type-aware and set-aware),
but it validates the data plumbing.

Usage:
  python3 tools/ml/train_polyvore_pairwise_smoke.py \
    --outfits tools/_out/manifests/polyvore_outfits_with_images.jsonl \
    --max-outfits 2000 \
    --pairs 4000 \
    --epochs 1

Requires: torch, torchvision, pillow
"""

from __future__ import annotations

import argparse
import json
import random
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
class Pair:
    a: Path
    b: Path
    y: int


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--outfits", required=True)
    ap.add_argument("--max-outfits", type=int, default=2000)
    ap.add_argument("--pairs", type=int, default=4000)
    ap.add_argument("--epochs", type=int, default=1)
    ap.add_argument("--seed", type=int, default=1337)
    args = ap.parse_args()

    random.seed(args.seed)

    outfits_path = Path(args.outfits).expanduser().resolve()
    outfits = []
    with outfits_path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            o = json.loads(line)
            items = o.get("items") or []
            # Use only items with resolved local image.
            paths = []
            for it in items:
                p = it.get("local_image_abspath")
                if p and Path(p).exists():
                    paths.append(Path(p))
            if len(paths) >= 2:
                outfits.append(paths)
            if len(outfits) >= args.max_outfits:
                break

    if len(outfits) < 10:
        raise SystemExit("Not enough outfits with images to train")

    pairs: list[Pair] = []
    # Positive pairs: two items from same outfit.
    for _ in range(args.pairs // 2):
        items = random.choice(outfits)
        a, b = random.sample(items, 2)
        pairs.append(Pair(a=a, b=b, y=1))

    # Negative pairs: items from different outfits.
    for _ in range(args.pairs - len(pairs)):
        o1, o2 = random.sample(outfits, 2)
        a = random.choice(o1)
        b = random.choice(o2)
        pairs.append(Pair(a=a, b=b, y=0))

    random.shuffle(pairs)

    import torch
    import torch.nn as nn
    import torch.optim as optim
    from PIL import Image
    from torchvision import models, transforms

    device = _choose_device()
    print(f"Using device: {device}")
    print(f"Outfits used: {len(outfits)}")
    print(f"Pairs: {len(pairs)}")

    tfm = transforms.Compose(
        [
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )

    class DS(torch.utils.data.Dataset):
        def __init__(self, pairs: list[Pair]):
            self.pairs = pairs

        def __len__(self):
            return len(self.pairs)

        def __getitem__(self, idx):
            p = self.pairs[idx]
            xa = tfm(Image.open(p.a).convert("RGB"))
            xb = tfm(Image.open(p.b).convert("RGB"))
            y = torch.tensor([p.y], dtype=torch.float32)
            return xa, xb, y

    dl = torch.utils.data.DataLoader(DS(pairs), batch_size=16, shuffle=True, num_workers=0)

    # Small siamese-ish model: shared backbone -> embedding -> pair classifier.
    backbone = models.resnet18(weights=None)
    backbone.fc = nn.Identity()

    embed_dim = 256
    proj = nn.Sequential(
        nn.Linear(512, embed_dim),
        nn.ReLU(),
        nn.Linear(embed_dim, embed_dim),
    )

    head = nn.Sequential(
        nn.Linear(embed_dim * 2, 128),
        nn.ReLU(),
        nn.Linear(128, 1),
    )

    model = nn.Module()
    model.backbone = backbone
    model.proj = proj
    model.head = head

    def forward(xa, xb):
        ea = model.proj(model.backbone(xa))
        eb = model.proj(model.backbone(xb))
        z = torch.cat([ea, eb], dim=1)
        return model.head(z)

    model = model.to(device)

    opt = optim.Adam(model.parameters(), lr=1e-3)
    loss_fn = nn.BCEWithLogitsLoss()

    for epoch in range(args.epochs):
        model.train()
        total_loss = 0.0
        correct = 0
        seen = 0
        for xa, xb, y in dl:
            xa = xa.to(device)
            xb = xb.to(device)
            y = y.to(device)

            opt.zero_grad(set_to_none=True)
            logits = forward(xa, xb)
            loss = loss_fn(logits, y)
            loss.backward()
            opt.step()

            total_loss += float(loss.item()) * int(xa.size(0))
            pred = (torch.sigmoid(logits) >= 0.5).to(torch.float32)
            correct += int((pred == y).sum().item())
            seen += int(xa.size(0))

        print(f"epoch={epoch+1} loss={total_loss/seen:.4f} acc={correct/seen:.3f}")

    print("Polyvore pairwise smoke train complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
