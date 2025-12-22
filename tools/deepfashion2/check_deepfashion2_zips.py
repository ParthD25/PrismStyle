#!/usr/bin/env python3
"""Validate DeepFashion2 zip bundles before extraction.

Why:
- The dataset is large; partial/corrupt downloads waste time.
- Info-ZIP 'unzip' output can be noisy; this script gives a clean yes/no.

It checks that each zip exists and that we can decrypt and read at least
one encrypted annotation JSON entry using the provided password.

Usage:
  python3 tools/deepfashion2/check_deepfashion2_zips.py \
    /path/to/DeepFashion2_zips \
    --password 2019Deepfashion2**

Exit codes:
- 0: all zips look readable
- 2: missing inputs / bad args
- 3: one or more zips failed to decrypt/read
"""

from __future__ import annotations

import argparse
from pathlib import Path

try:
    import pyzipper
except Exception as e:  # pragma: no cover
    raise SystemExit(
        "Missing dependency 'pyzipper'. Install with: pip install pyzipper"
    ) from e


ZIP_NAMES = ["train.zip", "validation.zip", "test.zip"]
OPTIONAL_ZIPS = ["json_for_validation.zip"]


def _pick_encrypted_json(zf: pyzipper.ZipFile) -> str | None:
    # Prefer annotation JSONs if present.
    for info in zf.infolist():
        if info.is_dir():
            continue
        if not info.filename.endswith(".json"):
            continue
        # zipcrypto sets bit0; AES entries also generally have it.
        if info.flag_bits & 0x1:
            return info.filename
    return None


def _check_zip(zip_path: Path, password: bytes) -> tuple[bool, str]:
    if not zip_path.exists():
        return False, f"missing: {zip_path.name}"

    try:
        with pyzipper.AESZipFile(zip_path) as zf:
            target = _pick_encrypted_json(zf)
            if not target:
                return False, "no encrypted json entries found (unexpected)"
            zf.setpassword(password)
            data = zf.read(target)
            if not data:
                return False, f"read 0 bytes from {target}"
            # Heuristic sanity: JSON should start with '{' or '['
            head = data.lstrip()[:1]
            if head not in (b"{", b"["):
                return False, f"decrypted bytes do not look like JSON for {target}"
            return True, f"ok (sample={target})"
    except RuntimeError as e:
        # pyzipper uses RuntimeError for bad password / CRC mismatch.
        return False, f"decrypt/read failed: {e}"
    except Exception as e:
        return False, f"error: {type(e).__name__}: {e}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src_dir", help="Directory containing DeepFashion2 zip bundles")
    ap.add_argument("--password", required=True)
    args = ap.parse_args()

    src = Path(args.src_dir).expanduser().resolve()
    if not src.is_dir():
        print(f"Not a directory: {src}")
        return 2

    password = args.password.encode("utf-8")

    failed = False
    for name in ZIP_NAMES + OPTIONAL_ZIPS:
        zp = src / name
        ok, msg = _check_zip(zp, password)
        if ok:
            print(f"{name}: OK - {msg}")
        else:
            if name in OPTIONAL_ZIPS and not zp.exists():
                print(f"{name}: SKIP (not present)")
                continue
            print(f"{name}: FAIL - {msg}")
            failed = True

    return 3 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
