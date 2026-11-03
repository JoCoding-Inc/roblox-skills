#!/usr/bin/env python3
"""Grab UI frames from recent YouTube videos of named Roblox games and tile them into one sheet.

The frames are other people's game art: look at them, show them to the user, never commit them.
Needs uvx (runs the latest yt-dlp; older yt-dlp builds get HTTP 403) and ffmpeg.

usage: python3 -I ui_refs.py OUTDIR "Game A" "Game B" ... [--frames 8] [--days 90] [--query guide]
"""
import argparse, datetime, pathlib, subprocess, tempfile
from PIL import Image, ImageDraw, ImageFont

YT = ["uvx", "--from", "yt-dlp", "yt-dlp", "--no-warnings"]

ap = argparse.ArgumentParser()
ap.add_argument("out")
ap.add_argument("games", nargs="+")
ap.add_argument("--frames", type=int, default=8)
ap.add_argument("--days", type=int, default=90, help="only videos uploaded in the last N days")
ap.add_argument("--query", default="guide", help="words added to the search; 'shop inventory' finds more panels")
a = ap.parse_args()
out = pathlib.Path(a.out); out.mkdir(parents=True, exist_ok=True)
since = (datetime.date.today() - datetime.timedelta(days=a.days)).strftime("%Y%m%d")

done = []
for g in a.games:
    slug = "".join(c if c.isalnum() else "-" for c in g.lower()).strip("-")
    r = subprocess.run(YT + ["--match-filter", f"upload_date>={since} & duration>=150 & duration<=1500 & !is_live",
                             "--print", "%(upload_date)s\t%(duration)s\t%(webpage_url)s\t%(title)s",
                             f"ytsearch12:{g} roblox {a.query}"], capture_output=True, text=True, timeout=300)
    rows = [l.split("\t") for l in r.stdout.splitlines() if l.count("\t") == 3]
    if not rows:
        print(f"{g}: no video since {since}", flush=True)
        continue
    date, dur, url, title = rows[0]
    dur = int(float(dur))
    print(f"{g}: {title} ({date}, {dur} s) {url}", flush=True)
    tmp = pathlib.Path(tempfile.mkdtemp())
    secs = []
    for i in range(a.frames):
        t = int(dur * (i + 1) / (a.frames + 1))
        secs += ["--download-sections", f"*{t}-{t + 1}"]
    subprocess.run(YT + ["-q", "-f", "bv*[height<=720]/b", *secs, "-o", str(tmp / "c_%(section_start)s.%(ext)s"), url],
                   capture_output=True, timeout=900)
    clips = sorted(tmp.iterdir(), key=lambda p: float(p.stem.split("_")[1]))
    for i, c in enumerate(clips):
        subprocess.run(["ffmpeg", "-loglevel", "quiet", "-y", "-i", str(c), "-frames:v", "1",
                        str(out / f"{slug}_{i:02d}.jpg")], timeout=60)
    done.append(slug)

try:
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 16)
except OSError:
    font = ImageFont.load_default()
frames = [p for s in done for p in sorted(out.glob(f"{s}_*.jpg"))]
if frames:
    w, h, cols = 320, 180, 4
    rows = (len(frames) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (w + 2), rows * (h + 2)), "white")
    d = ImageDraw.Draw(sheet)
    for i, p in enumerate(frames):
        x, y = (i % cols) * (w + 2), (i // cols) * (h + 2)
        sheet.paste(Image.open(p).convert("RGB").resize((w, h)), (x, y))
        d.rectangle([x, y, x + d.textlength(p.stem, font=font) + 8, y + 20], fill="black")
        d.text((x + 4, y + 1), p.stem, font=font, fill="yellow")
    sheet.save(out / "sheet.jpg", quality=82)
    print(f"{len(frames)} frames, sheet at {out / 'sheet.jpg'}")
