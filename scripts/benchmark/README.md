# Live chart benchmark

Pulls public data for the games on the Top Playing Now, Top Trending and Up-and-Coming charts and prints distributions (players per server, thumbnails, game pass counts and prices, like ratio, maturity, genre).

```sh
W=$(mktemp -d)
scripts/benchmark/fetch_sorts.sh "$W"
cd "$W" && python3 -I /path/to/repo/scripts/benchmark/collect.py && python3 -I /path/to/repo/scripts/benchmark/analyze.py
```

Takes about 5 minutes (one pass request per game). Only public endpoints, no login. The developer-products endpoint needs auth (404), so product prices are not collected.

## Icon and thumbnail stats

After `collect.py` (needs `bench.json` in the working directory and Pillow): `python3 -I art_fetch.py` downloads each game's 512 px icon and first 768x432 thumbnail into `icons/` and `thumbs/`, then `python3 -I art_stats.py` prints saturation, brightness, contrast and hue-count distributions. Title text, avatars and hooks were tallied by eye from contact sheets (see `roblox-store-art-pack` section 5), so they are approximate.
