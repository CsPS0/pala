"""Converts build/previews/*.png into the website's hero preview images.

Resizes each capture to its display size and writes website/public/previews/<name>.webp.
Fails if any file is over 150 KB. Needs Pillow:  python scripts/previews/to_webp.py
"""
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
SRC = REPO / "build" / "previews"
DST = REPO / "website" / "public" / "previews"
MAX_BYTES = 150 * 1024
# Width per client; height follows the capture's aspect ratio.
WIDTHS = {"desktop": 1600, "phone": 780, "popup": 760}


def main() -> None:
    pngs = sorted(SRC.glob("*.png"))
    if not pngs:
        sys.exit(f"No captures in {SRC}; run the capture steps in docs/DEV.md first.")
    DST.mkdir(parents=True, exist_ok=True)
    too_big = []
    for png in pngs:
        width = WIDTHS[png.stem.split("-")[0]]
        with Image.open(png) as im:
            im = im.convert("RGB")
            height = round(im.height * width / im.width)
            im = im.resize((width, height), Image.LANCZOS)
            out = DST / f"{png.stem}.webp"
            im.save(out, "WEBP", quality=80, method=6)
        size = out.stat().st_size
        print(f"{out.relative_to(REPO)}  {width}x{height}  {size // 1024} KB")
        if size > MAX_BYTES:
            too_big.append(out.name)
    if too_big:
        sys.exit(f"Over 150 KB: {', '.join(too_big)}")


if __name__ == "__main__":
    main()
