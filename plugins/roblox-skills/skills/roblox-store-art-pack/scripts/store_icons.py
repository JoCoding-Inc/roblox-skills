#!/usr/bin/env python3
"""Rank free Creator Store packs (icon packs, world-prop packs) or single icons and make a contact sheet.

  python3 -I store_icons.py "simulator icon pack" "icon pack" --type model
  python3 -I store_icons.py "rebirth icon" "shop icon" --type decal --out sheet.png

Models are ranked by up-votes (the store shows no votes on decals; those keep search order).
Prints one row per asset: id, up/down votes, image id (decals; use this, never the decal id)
or hasScripts (models), creator, name. Then open the sheet and look.
Uses the unauthenticated toolbox-service v1 endpoints (undocumented, may change; Studio MCP
search_asset is the supported fallback). Needs Pillow.
"""
import argparse, io, json, time, urllib.parse, urllib.request
from PIL import Image, ImageDraw

def get(url):
    for _ in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            return urllib.request.urlopen(req, timeout=30).read()
        except Exception:
            time.sleep(1)
    return None

ap = argparse.ArgumentParser()
ap.add_argument("keywords", nargs="+")
ap.add_argument("--type", choices=["model", "decal"], default="model")
ap.add_argument("--num", type=int, default=20, help="results per keyword")
ap.add_argument("--out", default="store_icons.png")
a = ap.parse_args()
cat = 10 if a.type == "model" else 13

ids = []
for kw in a.keywords:
    r = get(f"https://apis.roblox.com/toolbox-service/v1/marketplace/{cat}?keyword={urllib.parse.quote(kw)}&num={a.num}")
    for x in json.loads(r or b'{"data":[]}')["data"][:a.num]:
        if x["id"] not in ids:
            ids.append(x["id"])

rows = []
for i in range(0, len(ids), 30):
    r = get("https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=" + ",".join(map(str, ids[i:i + 30])))
    for x in json.loads(r or b'{"data":[]}')["data"]:
        v = x.get("voting") or {}
        price = (x.get("fiatProduct") or {}).get("purchasePrice") or {}
        if price and price.get("quantity", {}).get("significand"):
            continue  # paid
        rows.append({"id": x["asset"]["id"], "name": x["asset"]["name"], "creator": x["creator"]["name"],
                     "up": v.get("upVotes", 0), "down": v.get("downVotes", 0),
                     "image": x["asset"].get("textureId") or "", "scripts": x["asset"].get("hasScripts")})
if a.type == "model":
    rows.sort(key=lambda r: -r["up"])

thumbs = {}
for i in range(0, len(rows), 50):
    q = ",".join(str(r["id"]) for r in rows[i:i + 50])
    r = get(f"https://thumbnails.roblox.com/v1/assets?assetIds={q}&size=150x150&format=Png")
    for t in json.loads(r or b'{"data":[]}')["data"]:
        thumbs[t["targetId"]] = t.get("imageUrl")

cols, cell = 8, 170
sheet = Image.new("RGB", (cols * cell, max(1, -(-len(rows) // cols)) * (cell + 20)), (70, 90, 120))
draw = ImageDraw.Draw(sheet)
for n, r in enumerate(rows):
    x, y = (n % cols) * cell, (n // cols) * (cell + 20)
    b = get(thumbs[r["id"]]) if thumbs.get(r["id"]) else None
    if b:
        im = Image.open(io.BytesIO(b)).convert("RGBA").resize((150, 150))
        sheet.paste(im, (x + 10, y + 5), im)
    draw.text((x + 10, y + 158), f"{r['id']} +{r['up']}", fill=(255, 255, 255))
    extra = f"image={r['image']}" if a.type == "decal" else f"scripts={r['scripts']}"
    print(f"{r['id']}\t+{r['up']}/-{r['down']}\t{extra}\t{r['creator']}\t{r['name'][:60]}")
sheet.save(a.out)
print("sheet:", a.out)
