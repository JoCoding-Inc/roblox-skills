#!/usr/bin/env python3
"""Roblox market snapshot from public, no-login endpoints. Read-only, low volume.

Usage: python3 -I market.py COMMAND [args] [--out DIR] [--device D] [--country C]
  sorts                        list the chart ids Roblox serves right now
  charts [SORT ...] [--top N]  rank, CCU, age, visits/day, likes per game across charts
                               (default: top-trending up-and-coming top-playing-now top-earning)
  keyword TERM [TERM ...]      search competition per term (top 40 results)
  suggest TERM [--expand]      search autocomplete; --expand adds "TERM a".."TERM z"
  game UNIVERSE_ID [...]       teardown: details, passes, badges (progress funnel)
  history ROOT_PLACE_ID [...]  CCU curve from Rolimon's (third party): peak, now, half-life

Raw JSON goes to --out (default ./market-YYYYMMDD) so every number can be cited.
--device: all, computer, high_end_phone, low_end_phone, high_end_tablet, low_end_tablet,
console, vr (default computer). --country: 2-letter code or all (default all).
"""
import json, sys, time, uuid, re, pathlib, statistics, datetime, urllib.request, urllib.parse

UA = {"User-Agent": "roblox-skills-market-research/1.0"}
SHORT = {"top-trending": "trend", "up-and-coming": "up", "top-playing-now": "now", "top-earning": "earn",
         "top-revisited": "revisit", "fun-with-friends": "friends", "top-rated": "rated", "most-popular": "popular"}
SID = str(uuid.uuid4())
NOW = datetime.datetime.now(datetime.timezone.utc)


def fetch(url, delay=0.4):
    time.sleep(delay)  # stay far below the published per-minute limits
    for i in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
                return r.read().decode("utf8", "replace")
        except Exception as e:
            err = e
            time.sleep(2 * (i + 1))
    print(f"FAILED {url} ({err})", file=sys.stderr)
    return None


def jget(url, delay=0.4):
    t = fetch(url, delay)
    return json.loads(t) if t else {}


def save(name, data):
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{name}.json").write_text(json.dumps(data, ensure_ascii=False))


def days(iso):
    return (NOW - datetime.datetime.fromisoformat(iso.replace("Z", "+00:00"))).days if iso else None


def details(ids):
    out = {}
    ids = list(dict.fromkeys(ids))
    for i in range(0, len(ids), 50):
        d = jget("https://games.roblox.com/v1/games?universeIds=" + ",".join(map(str, ids[i:i + 50])))
        for g in d.get("data", []):
            out[g["id"]] = g
    return out


def sort_content(sid_):
    q = urllib.parse.urlencode({"sessionId": SID, "sortId": sid_, "device": DEVICE, "country": COUNTRY})
    d = jget(f"https://apis.roblox.com/explore-api/v1/get-sort-content?{q}")
    save(f"sort-{sid_}", d)
    return d.get("games", [])


def table(rows, cols):
    print("| " + " | ".join(cols) + " |")
    print("|" + "---|" * len(cols))
    for r in rows:
        print("| " + " | ".join("" if r.get(c) is None else str(r.get(c)) for c in cols) + " |")


def cmd_sorts(_):
    tok, ids = "", []
    for _ in range(6):
        q = {"sessionId": SID, "device": DEVICE, "country": COUNTRY}
        if tok:
            q["sortsPageToken"] = tok
        d = jget("https://apis.roblox.com/explore-api/v1/get-sorts?" + urllib.parse.urlencode(q))
        ids += [s.get("sortId") for s in d.get("sorts", []) if s.get("sortId")]
        tok = d.get("nextSortsPageToken")
        if not tok:
            break
    save("sorts", ids)
    print("\n".join(i for i in ids if not i.startswith("filters")))


def cmd_charts(args):
    sorts = [a for a in args if not a.isdigit()] or ["top-trending", "up-and-coming", "top-playing-now", "top-earning"]
    rank, base, sponsored = {}, {}, 0
    for s in sorts:
        n = 0
        for g in sort_content(s):
            if g.get("isSponsored"):
                sponsored += 1
                continue
            n += 1
            if n > TOP:
                break
            rank.setdefault(g["universeId"], {})[s] = n
            base[g["universeId"]] = g
    det = details(list(base))
    save("details", det)
    rows = []
    for u, g in base.items():
        d = det.get(u, {})
        up, dn = g.get("totalUpVotes", 0), g.get("totalDownVotes", 0)
        age = days(d.get("created"))
        r = rank[u]
        rows.append({
            "name": g["name"][:32], "universeId": u, "ccu": g.get("playerCount"),
            "genre": g.get("genreL1"), "age_d": age, "upd_d": days(d.get("updated")),
            "visits/day": int(d.get("visits", 0) / max(age or 1, 1)),
            "fav/1k": round(1000 * d.get("favoritedCount", 0) / max(d.get("visits", 1), 1), 1),
            "like%": round(100 * up / (up + dn)) if up + dn else None, "maxP": d.get("maxPlayers"),
            "ranks": " ".join(f"{SHORT.get(k, k)}#{v}" for k, v in r.items()),
            "flag": ("rising " if ("up-and-coming" in r or "top-trending" in r) and "top-playing-now" not in r else "")
                    + ("earner" if "top-earning" in r and r["top-earning"] < r.get("top-playing-now", 999) else ""),
            "_best": min(r.values()),
        })
    rows.sort(key=lambda x: (x["_best"], -(x["ccu"] or 0)))
    print(f"# charts {DEVICE}/{COUNTRY} {NOW:%Y-%m-%d %H:%M} UTC, top {TOP} per sort, {sponsored} sponsored rows skipped")
    table(rows, ["name", "universeId", "ccu", "genre", "age_d", "upd_d", "visits/day", "fav/1k", "like%", "maxP", "ranks", "flag"])
    young = [r for r in rows if (r["age_d"] or 9999) <= 90]
    print(f"\n{len(young)}/{len(rows)} games are 90 days old or younger. Genres: "
          + ", ".join(f"{k} {v}" for k, v in sorted(_count(r["genre"] for r in rows).items(), key=lambda x: -x[1])[:8]))


def _count(xs):
    c = {}
    for x in xs:
        c[x] = c.get(x, 0) + 1
    return c


def cmd_keyword(terms):
    summary = []
    for t in terms:
        q = urllib.parse.urlencode({"searchQuery": t, "sessionId": SID, "pageType": "all"})
        d = jget(f"https://apis.roblox.com/search-api/omni-search?{q}", delay=0.5)
        save(f"search-{re.sub(r'[^a-z0-9]+', '-', t.lower())}", d)
        res = [g["contents"][0] for g in d.get("searchResults", []) if g.get("contents")]
        res = [g for g in res if g.get("contentType", "Game") == "Game" and g.get("universeId")]
        det = details([g["universeId"] for g in res])
        ccu = [g.get("playerCount") or 0 for g in res]
        ages = [days(det.get(g["universeId"], {}).get("created")) for g in res]
        top10 = [a for a in ages[:10] if a is not None]
        summary.append({
            "term": t, "results": len(res), "top10_ccu": sum(ccu[:10]), "rank1_ccu": ccu[0] if ccu else None,
            "max_ccu@rank": f"{max(ccu)}@{ccu.index(max(ccu)) + 1}" if ccu else None,
            "top10_med_age_d": int(statistics.median(top10)) if top10 else None,
            "exact_title": sum(t.lower() in g["name"].lower() for g in res),
            "new<=90d%": round(100 * sum(a is not None and a <= 90 for a in ages) / max(len(res), 1)),
            "sponsored": sum(bool(g.get("isSponsored")) for g in res),
        })
        print(f"\n## {t}: top 10 results (relevance order, not CCU)")
        table([{"#": i + 1, "name": g["name"][:36], "ccu": g.get("playerCount"),
                "age_d": ages[i], "universeId": g["universeId"]} for i, g in enumerate(res[:10])],
              ["#", "name", "ccu", "age_d", "universeId"])
    print("\n## keyword summary (no official search volume exists; these are competition proxies)")
    table(summary, list(summary[0]) if summary else [])


def cmd_suggest(args):
    expand = "--expand" in args
    terms = [a for a in args if a != "--expand"]
    for t in terms:
        prefixes = [t] + ([f"{t} {c}" for c in "abcdefghijklmnopqrstuvwxyz"] if expand else [])
        seen = []
        for p in prefixes:
            d = jget("https://apis.roblox.com/games-autocomplete/v1/get-suggestion/" + urllib.parse.quote(p), delay=0.7)
            for e in d.get("entries", []):
                if e.get("searchQuery") not in seen:
                    seen.append(e.get("searchQuery"))
        save(f"suggest-{re.sub(r'[^a-z0-9]+', '-', t.lower())}", seen)
        print(f"## {t}: {len(seen)} suggestions (Roblox order, no counts)")
        print("\n".join(seen))


def cmd_game(ids):
    det = details([int(i) for i in ids])
    save("game-details", det)
    for u in ids:
        u = int(u)
        d = det.get(u, {})
        p = jget(f"https://apis.roblox.com/game-passes/v1/universes/{u}/game-passes?passView=Full&pageSize=100")
        b = jget(f"https://badges.roblox.com/v1/universes/{u}/badges?limit=100&sortOrder=Asc")
        save(f"game-{u}", {"details": d, "passes": p, "badges": b})
        age = days(d.get("created"))
        print(f"\n## {d.get('name')} ({u}) root place {d.get('rootPlaceId')}")
        print(f"CCU {d.get('playing')} | visits {d.get('visits')} | age {age} d | updated {days(d.get('updated'))} d ago"
              f" | maxPlayers {d.get('maxPlayers')} | genre {d.get('genre_l1')}/{d.get('genre_l2')} | favorites {d.get('favoritedCount')}")
        passes = [(x.get("name"), x.get("price")) for x in p.get("gamePasses", []) if x.get("isForSale")]
        print(f"passes for sale ({len(passes)}): " + "; ".join(f"{n} {pr}" for n, pr in sorted(passes, key=lambda x: x[1] or 0)))
        bs = [x for x in b.get("data", []) if x.get("enabled")]
        if bs:
            print("badges as a progress funnel (awarded total, winRate%):")
            for x in sorted(bs, key=lambda x: -(x.get("statistics") or {}).get("awardedCount", 0))[:15]:
                s = x.get("statistics") or {}
                print(f"  {x.get('name')[:40]}: {s.get('awardedCount')} ({s.get('winRatePercentage')})")


def rolimons(pid):
    h = fetch(f"https://www.rolimons.com/game/{pid}", delay=2.0)  # robots.txt asks for a 2 s crawl delay
    m = re.search(r'<script[^>]*id="game_history_json"[^>]*>(.*?)</script>', h or "", re.S)
    return json.loads(m.group(1)) if m else None


def cmd_history(ids):
    for pid in ids:
        j = rolimons(pid)
        if not j:  # maybe a universe id: resolve to the root place and retry once
            root = details([int(pid)]).get(int(pid), {}).get("rootPlaceId")
            j = rolimons(root) if root else None
        if not j:
            print(f"{pid}: no history (Rolimon's tracks only some games)")
            continue
        save(f"history-{pid}", j)
        daily = {}
        for t, p in zip(j["timestamps"], j["players"]):
            d = datetime.datetime.fromtimestamp(t, datetime.timezone.utc).strftime("%Y-%m-%d")
            daily[d] = max(daily.get(d, 0), p)
        dates = sorted(daily)
        peaks = [daily[d] for d in dates]
        avg7 = [sum(peaks[max(0, k - 6):k + 1]) / len(peaks[max(0, k - 6):k + 1]) for k in range(len(peaks))]
        i = max(range(len(avg7)), key=lambda k: avg7[k])
        half = next((k for k in range(i, len(avg7)) if avg7[k] <= avg7[i] / 2), None)
        print(f"{pid}: tracked {dates[0]} to {dates[-1]} | spike max {max(peaks)} | 7-day avg of daily peaks: "
              f"top {int(avg7[i])} on {dates[i]}, now {int(avg7[-1])} ({avg7[-1] / max(avg7[i], 1):.0%}) | half-life "
              + (f"{half - i} days" if half is not None else "not reached")
              + f" | avg playtime now {j.get('avg_playtime', [None])[-1]} min")


if __name__ == "__main__":
    a = sys.argv[1:]

    def opt(name, default):
        if name in a:
            k = a.index(name)
            v = a[k + 1]
            del a[k:k + 2]
            return v
        return default

    OUT = pathlib.Path(opt("--out", f"market-{NOW:%Y%m%d}"))
    DEVICE = opt("--device", "computer")
    COUNTRY = opt("--country", "all")
    TOP = int(opt("--top", "25"))
    cmds = {"sorts": cmd_sorts, "charts": cmd_charts, "keyword": cmd_keyword, "suggest": cmd_suggest,
            "game": cmd_game, "history": cmd_history}
    if not a or a[0] not in cmds:
        sys.exit(__doc__)
    cmds[a[0]](a[1:])
