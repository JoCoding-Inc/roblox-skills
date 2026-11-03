#!/bin/sh
# Download the live chart lists next to collect.py's working dir. Usage: fetch_sorts.sh <outdir>
set -e
OUT=${1:-.}; mkdir -p "$OUT"; cd "$OUT"
SID=$(uuidgen)
for s in top-playing-now top-trending up-and-coming; do
  curl -s -m 20 "https://apis.roblox.com/explore-api/v1/get-sort-content?sessionId=$SID&sortId=$s&device=computer&country=all" -o "$s.json"
done
