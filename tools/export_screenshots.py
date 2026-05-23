#!/usr/bin/env python3
"""
Resize iPhone screenshots to App Store Connect required dimensions.
Letterboxes with black padding; no overlays or text.
"""

from __future__ import annotations

import sys
from pathlib import Path

try:
    from PIL import Image, ImageOps
except ImportError:
    print("Pillow is required: pip install -r requirements.txt", file=sys.stderr)
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = REPO_ROOT / "appstore" / "raw"
EXPORT_DIR = REPO_ROOT / "appstore" / "export"

SIZES: list[tuple[int, int, str]] = [
    (1290, 2796, "1290x2796"),
    (1284, 2778, "1284x2778"),
    (1242, 2688, "1242x2688"),
]

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".heic", ".heif"}


def list_source_images() -> list[Path]:
    if not RAW_DIR.is_dir():
        raise SystemExit(
            f"Source folder missing: {RAW_DIR}\n"
            "Create it and add screenshots, then run again."
        )

    files = [
        p
        for p in RAW_DIR.iterdir()
        if p.is_file() and p.suffix.lower() in IMAGE_EXTENSIONS
    ]
    return sorted(files, key=lambda p: p.name)


def export_one(src: Path, dest: Path, width: int, height: int) -> None:
    with Image.open(src) as im:
        im = ImageOps.exif_transpose(im)
        im = im.convert("RGBA")
        fitted = ImageOps.contain(im, (width, height), method=Image.Resampling.LANCZOS)
        canvas = Image.new("RGB", (width, height), (0, 0, 0))
        x = (width - fitted.width) // 2
        y = (height - fitted.height) // 2
        canvas.paste(fitted, (x, y), fitted)
        dest.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(dest, format="PNG", optimize=True)


def main() -> None:
    sources = list_source_images()
    if not sources:
        print(f"No images found in {RAW_DIR}", file=sys.stderr)
        print("Supported: .png .jpg .jpeg .webp .heic .heif", file=sys.stderr)
        sys.exit(1)

    exported = 0
    for src in sources:
        base = src.stem
        for width, height, label in SIZES:
            dest = EXPORT_DIR / label / f"{base}.png"
            export_one(src, dest, width, height)
            exported += 1
            print(f"✓ {label}/{base}.png")

    print(
        f"\nDone: {len(sources)} source(s) → {exported} file(s) in {EXPORT_DIR}"
    )


if __name__ == "__main__":
    main()
