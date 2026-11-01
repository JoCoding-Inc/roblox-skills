# Live chart benchmark

Pulls public data for the games on the Top Playing Now, Top Trending and Up-and-Coming charts and prints distributions (players per server, thumbnails, game pass counts and prices, like ratio, maturity, genre).

```sh
W=$(mktemp -d)
scripts/benchmark/fetch_sorts.sh "$W"
cd "$W" && python3 -I /path/to/repo/scripts/benchmark/collect.py && python3 -I /path/to/repo/scripts/benchmark/analyze.py
```

Takes about 5 minutes (one pass request per game). Only public endpoints, no login. The developer-products endpoint needs auth (404), so product prices are not collected.
