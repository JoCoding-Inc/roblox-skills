#!/usr/bin/env python3
"""Reference-game sheet: one tile per game (first thumbnail, icon, name, players now, age, last update).

  python3 -I ref_sheet.py "Grow a Garden" 7436755782 "steal a brainrot" --out refs.png

Each argument is a universe id or a name (the top game result of Roblox search; check the printed
match). Prints one row per game and writes the sheet. Other creators' art: keep the sheet private
(send it to the user, never commit or upload it). No login. Needs Pillow.
"""
import argparse, io, json, time, uuid, urllib.parse, urllib.request
from datetime import datetime, timezone
from PIL import Image, ImageDraw

UA = {"User-Agent": "roblox-skills-market-research/1.0"}


def get(url, raw=False):
    for _ in range(3):
        try:
            b = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30).read()
            return b if raw else json.loads(b)
        except Exception:
            time.sleep(1)
    return None


def days(iso):
    if not iso:
        return None
    t = datetime.fromisoformat(iso[:19]).replace(tzinfo=timezone.utc)
    return (datetime.now(timezone.utc) - t).days


ap = argparse.ArgumentParser()
ap.add_argument("games", nargs="+")
ap.add_argument("--out", default="refs.png")
a = ap.parse_args()

sid = str(uuid.uuid4())
ids = []
for g in a.games:
    if g.isdigit():
        ids.append(int(g))
        continue
    q = urllib.parse.urlencode({"searchQuery": g, "sessionId": sid, "pageType": "all"})
    d = get(f"https://apis.roblox.com/search-api/omni-search?{q}") or {}
    hit = next((r["contents"][0] for r in d.get("searchResults", []) if r.get("contents")
                and r["contents"][0].get("universeId") and r["contents"][0].get("contentType", "Game") == "Game"), None)
    if hit:
        print(f"'{g}' -> {hit['name']} ({hit['universeId']})")
        ids.append(hit["universeId"])
    else:
        print(f"'{g}' -> no game found")

det = {x["id"]: x for x in (get("https://games.roblox.com/v1/games?universeIds=" + ",".join(map(str, ids))) or {}).get("data", [])}
q = ",".join(map(str, ids))
icons = {x["targetId"]: x.get("imageUrl") for x in (get(f"https://thumbnails.roblox.com/v1/games/icons?universeIds={q}&size=150x150&format=Png&isCircular=false") or {}).get("data", [])}
thumbs = {x["universeId"]: (x["thumbnails"][0].get("imageUrl") if x.get("thumbnails") else None)
          for x in (get(f"https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds={q}&countPerUniverse=1&size=768x432&format=Png&isCircular=false") or {}).get("data", [])}

tw, th, cols = 480, 270, 3
rows = max(1, -(-len(ids) // cols))
sheet = Image.new("RGB", (cols * (tw + 10) + 10, rows * (th + 50) + 10), (30, 30, 34))
draw = ImageDraw.Draw(sheet)
print("universe\tplaying\tage_d\tupdated_d\tmax_players\tname")
for n, u in enumerate(ids):
    g = det.get(u, {})
    name = " ".join(str(g.get("name", u)).encode("ascii", "ignore").decode().split())  # the default font has no emoji
    x, y = 10 + (n % cols) * (tw + 10), 10 + (n // cols) * (th + 50)
    b = get(thumbs[u], raw=True) if thumbs.get(u) else None
    if b:
        sheet.paste(Image.open(io.BytesIO(b)).convert("RGB").resize((tw, th)), (x, y))
    b = get(icons[u], raw=True) if icons.get(u) else None
    if b:
        im = Image.open(io.BytesIO(b)).convert("RGBA").resize((90, 90))
        sheet.paste(im, (x + 6, y + th - 96), im)
    line = f"{name[:40]} | {g.get('playing', 0):,} now | {days(g.get('created'))} d old | upd {days(g.get('updated'))} d"
    draw.text((x, y + th + 8), line, fill=(255, 255, 255))
    draw.text((x, y + th + 26), f"universe {u}  #{n + 1}", fill=(170, 170, 170))
    print(f"{u}\t{g.get('playing')}\t{days(g.get('created'))}\t{days(g.get('updated'))}\t{g.get('maxPlayers')}\t{name}")
sheet.save(a.out)
print("sheet:", a.out)
