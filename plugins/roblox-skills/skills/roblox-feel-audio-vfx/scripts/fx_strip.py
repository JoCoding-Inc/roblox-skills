#!/usr/bin/env python3
"""Lay freeze-frame captures of one effect cast into a labelled grid (roblox-feel-audio-vfx section 3d).

  python3 -I fx_strip.py <out.jpg> "<title>" <frame>... [--crop x,y,w,h] [--cols 4] [--width 1800]

Frames are read in the order given; each is labelled with the beat time taken from a "_t<seconds>" part of
its file name (FireSlash_03_t0.165.jpg -> "t=0.165 s"). --crop takes fractions 0-1 or pixels of the source.
The grid is scaled so the sheet is at most --width px wide. Needs Pillow.
"""
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def font(size):
    for name in ("Arial Bold.ttf", "DejaVuSans-Bold.ttf", "Helvetica.ttc"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def main(argv):
    crop, cols, width, rest = None, 4, 1800, []
    i = 0
    while i < len(argv):
        if argv[i] == "--crop":
            crop = [float(v) for v in argv[i + 1].split(",")]
            i += 2
        elif argv[i] == "--cols":
            cols = int(argv[i + 1])
            i += 2
        elif argv[i] == "--width":
            width = int(argv[i + 1])
            i += 2
        else:
            rest.append(argv[i])
            i += 1
    out, title, frames = rest[0], rest[1], rest[2:]
    gap, head = 4, 34
    tiles = []
    for p in frames:
        im = Image.open(p).convert("RGB")
        if crop:
            x, y, w, h = crop
            if max(crop) <= 1.0:
                x, y, w, h = x * im.width, y * im.height, w * im.width, h * im.height
            im = im.crop((int(x), int(y), int(x + w), int(y + h)))
        tiles.append((im, p))
    cols = min(cols, len(tiles))
    rows = (len(tiles) + cols - 1) // cols
    tw = (width - gap * (cols - 1)) // cols
    th = int(tiles[0][0].height * tw / tiles[0][0].width)
    sheet = Image.new("RGB", (cols * tw + gap * (cols - 1), head + rows * th + gap * (rows - 1)), (16, 16, 18))
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 6), title, fill=(255, 255, 255), font=font(20))
    lf = font(max(14, th // 14))
    for k, (im, p) in enumerate(tiles):
        im = im.resize((tw, th), Image.LANCZOS)
        m = re.search(r"_t([0-9.]+)\.(?:png|jpe?g)$", Path(p).name)
        label = "t=%s s" % m.group(1) if m else Path(p).stem
        d = ImageDraw.Draw(im)
        d.rectangle((0, 0, d.textlength(label, font=lf) + 8, lf.size + 8), fill=(0, 0, 0))
        d.text((4, 4), label, fill=(255, 255, 80), font=lf)
        sheet.paste(im, ((k % cols) * (tw + gap), head + (k // cols) * (th + gap)))
    sheet.save(out, quality=82, optimize=True)
    print("wrote %s %dx%d" % (out, sheet.width, sheet.height))


if __name__ == "__main__":
    main(sys.argv[1:])
