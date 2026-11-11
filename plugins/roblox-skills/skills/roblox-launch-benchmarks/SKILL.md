---
name: roblox-launch-benchmarks
description: "Use before launching or tuning a Roblox game to set store-page and shop values from what live top-chart games actually do: thumbnails, description length, players per server, game pass count and price points, like ratio, maturity. Gives a pre-launch checklist with benchmark numbers. Also when choosing game pass prices, deciding how many passes or thumbnails to ship, setting max players, writing the description, or when asked whether a value is normal. Re-measure with this skill's scripts/ before quoting numbers older than a month."
last_reviewed: 2026-11-03
sources:
  - https://apis.roblox.com/explore-api/v1/get-sort-content (Top Playing Now, Top Trending, Up-and-Coming, read 2026-11-01)
  - https://games.roblox.com/v1/games, https://thumbnails.roblox.com/v1/games/multiget/thumbnails, https://apis.roblox.com/game-passes/v1/universes/{id}/game-passes
  - https://www.gameanalytics.com/reports/2026-roblox-report (vendor; retention percentiles)
  - https://create.roblox.com/docs/production/promotion/experience-events (event surfaces)
  - original (scripts/ in this skill)
---

# Launch benchmarks from live top-chart games

Numbers below were measured on **2026-11-01** from 76 games: the top 40 of Top Playing Now plus the top 30 of Top Trending and Up-and-Coming (deduplicated). 46 were created within 120 days ("young"), 30 older. Regenerate with `scripts/README.md` in this skill; do not quote these after about a month without re-measuring. For one competitor, a keyword or a decay curve, use `roblox-market-research`.

**Read the limits first.** This is survivorship data: games that reached the charts, not games that failed with the same settings. It shows what winners do, not what causes winning. Chart sample is skewed to Simulation (31 of 76) and Survival (16). Developer product prices are not available without login, so only game passes are covered. A value close to the median is a safe default, not proof of quality. Thumbnails are capped at 10 by the platform, so the p90 of 10 is the ceiling.

## Measured values

| Item | Young games (n=46) | Older games (n=30) | Use |
|---|---|---|---|
| Thumbnails (images/videos) | median 3, p10 2, p90 6 | median 8, p10 3, p90 10 | Ship at least 3 custom at launch, add toward 8-10 as the game matures |
| Description length (chars) | median 507, p10 244, p90 936 | median 504, p10 147 | Aim 250-900 chars; the first lines carry the how-to-play |
| Max players per server | median 15, p10 5, p90 30 | median 20, p10 10, p90 45 | 12-20 is the common band; common values 7, 10, 12, 15, 16, 20, 30 |
| Active game passes | median 6, p10 0, p90 14 (7 of 46 have none) | median 6, p10 1, p90 14 | Plan about 4-8 passes; 0 is possible but rare |
| Pass price (Robux) | median 199, p10 50, p90 699 | median 350, p10 95, p90 1,600 | Price ladder below |
| Like ratio | median 0.906, p10 0.76 | median 0.908, p10 0.84 | A new game under about 0.76 is in the bottom decile of chart games |
| Content maturity | minimal 27, mild 13, moderate 6 | minimal 14, mild 13, moderate 3 | Almost all chart games are minimal or mild; none are restricted |

Pass price points that repeat most (all 543 passes): 99 (46), 299 (43), 199 (37), 149 (32), 399 (27), 499 (20), 249 (16), 799 (14), 349 (11), 79 (10). Young games lean cheaper: 99, 149 and 199 are the top three (40, 31, 31 of 316 passes); older games lean 299-500 and reach 1,600 at p90. Pass names mention "pack" 79 times, "VIP" 42, "bundle" 41, "2x" 33, "x2" 20, "speed" 20, "luck" 15, "auto" 12: multipliers, auto features, luck and bundles dominate. A luck pass changes odds, so it counts as a paid random item modifier: odds rules in `roblox-design-and-launch` section 2.

Other facts from the sample: 69 of 76 are group-owned; 61 of 76 carry an emoji or bracket tag in the title (events, update numbers; Halloween inflates this: The Hollow event ended 2026-11-02 and 64 of 212 chart titles still carried Halloween tags on 2026-11-03, so do not quote tag shares until after about 2026-11-20); no game had `minimumAge` above 0 in the chart payload; the median game was updated the same day and the 90th percentile within 1 day (live ops cadence is the norm in the top charts).

## Pre-launch checklist (with benchmark gates)

Mark each PASS with evidence (screenshot, dashboard, readback). Hard gates block release; soft gates compare with the table.

**Hard gates (policy and function)**
1. Maturity questionnaire done; label matches the content (`roblox-design-and-launch` section 4).
2. At least one custom thumbnail, or the game gets no Home recommendations.
3. No free-text between players outside `TextChatService` (or rate limited to 1 per minute) (`roblox-engine-2026` section 5).
4. Purchases grant through `ProcessReceipt`; shop prices are read at runtime, not hard-coded (Plus discounts, `roblox-design-and-launch` section 2); paid random items and luck boosts show odds that sum to 100%; DataStore load/save/rejoin tested; a rollback version noted (`roblox-release-automation` section 4a, `roblox-design-and-launch` section 2).
5. Every asset loads in a live client, not only in Studio (`roblox-pitfalls`).
6. Tested on a low-end phone and at the device simulator sizes (`roblox-engine-2026` section 3).

**Soft gates (benchmark)**
7. Thumbnails: 3 or more at launch, 2-5 of them active for Home thumbnail personalization (Roblox reports +8.5% average qualified play-through rate); plan 8 or more by month three. Icon and thumbnail craft: `roblox-store-art-pack` section 5.
8. Description: 250-900 characters, controls and how-to-play first.
9. Max players: inside 7-30; justify values outside it.
10. Passes: 4-8 live at launch with prices from the ladder (99, 149, 199, 299, 399, 499, 799); no price above 800 before there is player demand.
11. Like ratio after the first 1,000 votes: target 0.85 or higher; below 0.76 investigate onboarding and monetization pressure first.
12. Loading: custom loading screen only if `ReplicatedFirst` stays lean and the screen closes as soon as the game loads (`roblox-store-art-pack` section 7); no forced wait; only first-screen assets are preloaded (tier 0), the rest loads in the background or on demand, with a measured join time.
13. Update cadence: a published update or event within each week once live; tag the title or thumbnail with the update (35 of 37 chart games with 20K+ players had updated within 7 days, measured 2026-11-03). Event surfaces have gates: Trending Events in Experiences needs a public event started within 7 days with 1,000+ RSVPs; Off-Platform Featuring needs the event submitted at least 7 days ahead (docs `experience-events`).
14. Retention after the first week, against GameAnalytics 2026 (V, 500+ games): median D1 10.3 / D7 1.6 / D30 0.5%, p25 8.4 / 1.0 / 0.3%, top 1% 22.2 / 9.1 / 4.7%. Below p25: fix onboarding and the first session before spending on ads.

## How to refresh

```sh
W=$(mktemp -d); sh <skill dir>/scripts/fetch_sorts.sh "$W"; cd "$W"
python3 -I <skill dir>/scripts/collect.py && python3 -I <skill dir>/scripts/analyze.py
```

Update the table, the date and the sample size together. When a value drifts by more than a quarter from this file, say so in the PR.
