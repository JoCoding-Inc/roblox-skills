#!/usr/bin/env python3
"""Build a labeled contact sheet of the style lane cards, or of any folder of option images.

Usage: python3 -I <skill dir>/scripts/style_board.py OUT.png [--only name ...] [--dir DIR]
Needs Pillow. Default dir: ../assets/lanes next to this script (the lane cards).
"""
import sys, pathlib
from PIL import Image, ImageDraw, ImageFont

args = sys.argv[1:]
if not args:
    sys.exit(__doc__)
out = args.pop(0)
only, d = [], pathlib.Path(__file__).resolve().parent.parent / "assets" / "lanes"
while args:
    a = args.pop(0)
    if a == "--only":
        while args and not args[0].startswith("--"):
            only.append(args.pop(0))
    elif a == "--dir":
        d = pathlib.Path(args.pop(0))
files = sorted(f for f in d.iterdir() if f.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp"))
if only:
    files = [f for f in files if f.stem in only]
if not files:
    sys.exit("no images found")
W, H, L = 640, 360, 36
cols = 2
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (W * cols, (H + L) * rows), "white")
dr = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 22)
except Exception:
    font = ImageFont.load_default()
for i, f in enumerate(files):
    im = Image.open(f).convert("RGB")
    im.thumbnail((W, H))
    x, y = (i % cols) * W, (i // cols) * (H + L)
    sheet.paste(im, (x, y))
    name = f.stem.replace("-", " ")
    label = name if f.stem[:2].isupper() and f.stem[1:2] == "-" else f"{i + 1}. {name}"
    dr.text((x + 10, y + H + 6), label, fill="black", font=font)
sheet.save(out)
print(out, len(files), "cards")
