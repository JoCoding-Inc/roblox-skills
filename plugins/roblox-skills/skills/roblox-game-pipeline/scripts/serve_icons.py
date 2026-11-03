#!/usr/bin/env python3
"""Serve PNG icons to Studio for ui_style_mock.luau without uploading them.

Each <name>.png in the given folders becomes <name>.rgba (square, SIZE x SIZE, raw RGBA),
served on 127.0.0.1. Run in the background, then run the Luau mock; stop it afterwards.

  python3 -I serve_icons.py <skill dir>/assets/ui-styles/icons [more dirs] [--port 18765] [--size 192]

Later folders override earlier ones by name (put the game's own icons last). Needs Pillow.
"""
import argparse
import functools
import http.server
import pathlib
import tempfile

from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument("dirs", nargs="+")
ap.add_argument("--port", type=int, default=18765)
ap.add_argument("--size", type=int, default=192)
args = ap.parse_args()

out = pathlib.Path(tempfile.mkdtemp(prefix="ui-icons-"))
names = []
for d in args.dirs:
    for png in sorted(pathlib.Path(d).glob("*.png")):
        im = Image.open(png).convert("RGBA")
        side = max(im.size)
        sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
        sq = sq.resize((args.size, args.size), Image.LANCZOS)
        (out / f"{png.stem}.rgba").write_bytes(sq.tobytes())
        names.append(png.stem)

print(f"serving {len(names)} icons at http://127.0.0.1:{args.port}/ : {' '.join(sorted(set(names)))}", flush=True)
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(out))
http.server.ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()
