#!/usr/bin/env python3
"""
normalise-icons.py - make every project icon sit in the same visual box.

The project icons were drawn at different sizes and with different amounts of
padding, so they render inconsistently in the navbar and in the profile list.
This trims the transparent border, scales the artwork so its longest side fills
the canvas, and re-centres it on a 128x128 square canvas with 6px of padding.

Usage:
  ./scripts/normalise-icons.py <input.png> [...] -o <outdir>
  ./scripts/normalise-icons.py --all -o docs/theme/images

Requires Pillow.
"""

import argparse
import glob
import os
import sys

from PIL import Image

CANVAS = 128
PAD = 6


def normalise(src: str, out: str) -> str:
    im = Image.open(src).convert("RGBA")
    bbox = im.getbbox()
    if bbox is None:
        raise ValueError(f"{src} is completely transparent")

    im = im.crop(bbox)
    scale = (CANVAS - 2 * PAD) / max(im.size)
    im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(im, ((CANVAS - im.width) // 2, (CANVAS - im.height) // 2), im)
    canvas.save(out, optimize=True)
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="*", help="png files to normalise")
    parser.add_argument("--all", action="store_true", help="every png in the given directories")
    parser.add_argument("-o", "--out", default="docs/theme/images", help="output directory")
    args = parser.parse_args()

    sources = list(args.files)
    if args.all:
        for d in args.files or ["docs/images"]:
            sources.extend(glob.glob(os.path.join(d, "*.png")))

    if not sources:
        parser.print_help()
        return 1

    os.makedirs(args.out, exist_ok=True)
    for src in sources:
        out = os.path.join(args.out, os.path.basename(src))
        before = os.path.getsize(src)
        after = os.path.getsize(normalise(src, out))
        print(f"{src} -> {out}  ({before // 1024} KB -> {after // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
