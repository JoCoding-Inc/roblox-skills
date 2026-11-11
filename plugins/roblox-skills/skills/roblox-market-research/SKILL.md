---
name: roblox-market-research
description: "Use when ideating or judging a Roblox game idea against the live market: what is trending or rising, which genres and themes are crowded, search keyword competition, competitor teardown (players, age, passes, badges), how fast hits decay, and which sites and public APIs hold Roblox charts, stats and keyword data. Also when the user asks 'what do you think of this game idea', 'how about a gym tycoon (or any genre) idea', 'is X a good idea', 'what should I make', 'what is popular on Roblox now', 'is this genre saturated', 'who are the competitors', picks a game name or title keywords, times an update to a season or event, or wants sources for Roblox trends. Run in roblox-game-pipeline stages 1-2, before the brief is fixed."
last_reviewed: 2026-11-04
sources:
  - https://create.roblox.com/docs/discovery
  - https://create.roblox.com/docs/production/analytics/analytics-dashboard
  - https://s27.q4cdn.com/984876518/files/content_files/Q3-2026-Earnings-Shareholder-Letter.pdf
  - https://corp.roblox.com/newsroom/2025/12/roblox-replay-decoded-search-style
  - https://gameanalytics.com/reports/2026-roblox-report
  - https://www.rolimons.com (third party, game history)
  - original (public endpoints tested 2026-11-03; scripts/market.py)
---

# Market research for Roblox games

Model memory of "what is popular on Roblox" is months old, and hits on Roblox rise and fall within weeks. Before advising on an idea, pull today's data, write it down with the date, and grade every claim: **O** official Roblox, **M** measured by you today, **V** vendor or tracker estimate, **C** community or analyst opinion. Never present a V or C number as fact.

`<skill dir>` below is the base directory shown when this skill loads.

## 1. When to run what

| Moment | Run | Record in |
|---|---|---|
| "What should I make?" or a fuzzy idea | Recipe in section 5, steps 1-4 | `docs/research.md` |
| "What do you think of this idea?" | `charts`, then `keyword` for the idea's theme, then `game` on the 2-3 closest competitors | `docs/research.md`, 3 findings to the user |
| Naming the game, title keywords | `suggest --expand`, `keyword` (section 4) | brief: name + keywords |
| Planning an update or event | `history` on the game and 2 rivals, check the season (section 6) | `docs/plan.md` |
| Before launch | `roblox-launch-benchmarks` (store page values) plus `charts --device high_end_phone` | release notes |

Give the user at most 3 findings, each as "data -> what it means for your idea -> suggested change", with the grade. The user decides.

## 2. The script (no login, read-only)

```sh
python3 -I <skill dir>/scripts/market.py sorts                       # chart ids served today
python3 -I <skill dir>/scripts/market.py charts --top 25             # trending, up-and-coming, playing now, earning
python3 -I <skill dir>/scripts/market.py charts trending-in-survival up-and-coming --device high_end_phone --country us
python3 -I <skill dir>/scripts/market.py keyword "steal" "fishing"   # search competition per term
python3 -I <skill dir>/scripts/market.py suggest "tycoon" --expand   # autocomplete long tail
python3 -I <skill dir>/scripts/market.py game 10563114921            # teardown by universe id
python3 -I <skill dir>/scripts/market.py history 107778070777162     # Rolimon's CCU curve, root place or universe id
python3 -I <skill dir>/scripts/ref_sheet.py "grow a garden" 7709344486 --out refs.png   # reference-game sheet for the user
```

Raw JSON lands in `./market-YYYYMMDD/` so every number can be cited. Sponsored rows are skipped and counted. `charts` flags `rising` (on trending or up-and-coming but not on playing-now) and `earner` (earning rank above its playing rank). Calls are spaced out; do not loop the script.

## 3. Source catalog

| Source | Gives | Access | Grade | Use |
|---|---|---|---|---|
| Explore API `apis.roblox.com/explore-api/v1/get-sorts`, `get-sort-content` (same data as roblox.com/charts) | About 25 charts: top-trending, up-and-coming, top-playing-now, top-earning (rank only), top-revisited, fun-with-friends, top-rated, top-paid-access, trending-in-genre x13; CCU, votes, genre, maturity, sponsored flag | Open JSON, needs `sessionId` (any UUID); 80-100 rows, no second page; filter by device and country | O/M | Ideation, genre check |
| `games.roblox.com/v1/games?universeIds=` (50 ids max), `/v1/games/votes` | playing, visits, created, updated, maxPlayers, genre_l1/l2, favorites, description | Open JSON | O/M | Competitor teardown |
| `apis.roblox.com/search-api/omni-search` | Search results in relevance order (40 per page) with CCU | Open JSON, needs `sessionId` | O/M | Keyword competition |
| `apis.roblox.com/games-autocomplete/v1/get-suggestion/<prefix>` | Up to 10 suggestions per prefix, in Roblox order, no counts | Open JSON | O/M | Long-tail keywords |
| `apis.roblox.com/game-passes/v1/universes/<id>/game-passes?passView=Full` | Pass names, prices, for sale | Open JSON | O/M | Price ladder |
| `badges.roblox.com/v1/universes/<id>/badges` | awardedCount, pastDayAwardedCount, winRatePercentage per badge | Open JSON | O/M | Progress funnel proxy |
| `thumbnails.roblox.com/v1/games/multiget/thumbnails`, `/v1/games/icons` | Store art | Open JSON | O | Art references (`roblox-launch-benchmarks` scripts) |
| Roblox shareholder letters (Q3 2026 PDF above) | DAU, bookings, discovery direction | Open PDF (ir.roblox.com blocks curl) | O | Market frame |
| Roblox Replay (yearly, December) | Top searches, seasonal spikes, device and country habits | Open | O | Themes, seasons |
| Creator Hub analytics, peer benchmarks | Your game against similar games (p50-p90) | Login, own game only | O | After launch |
| DevForum `devforum.roblox.com/latest.json`, `/search.json?q=` | Policy and algorithm changes, weekly recaps, roadmap | Open JSON | O/C | Risk check |
| Rolimon's `www.rolimons.com/game/<rootPlaceId>`, `api.rolimons.com/games/v1/gamelist` | CCU history (6-hourly points), avg playtime, visits; about 7,900 games tracked | Open; crawl delay 2 s | M/V | Decay, half-life |
| RoTerminal agent API `roterminal.co/api/agent/<tool>` (spec: `roterminal.co/agents.md`) | `trends?word=` (game-title words, last 30 days vs the 30 before), `rising?range=7d&genre=`, `screen?theme=` (filters the top 600), `charts?chart=&country=` (daily Roblox charts, 60 countries), `updates?game=` (players before and after each update) | Open JSON, no login, 50 calls a day per address; repackaged Roblox data, matched the games API within 0-5.5% on 9 games (2026-11-04); history only since 2026-09-27; Robux estimates paid | M/V | Theme crowding, breakouts per genre, country charts. Rolimon's stays the source for decay |
| RoTrends `rotrends.com/genres` | Genre table: game count, visits, CCU, session, rating | Open HTML, but its terms bar bots: let the user open it, or read one page by hand | M/V | Genre crowding |
| RobloxGameStats, RoWatcher | CCU, records, emerging games; revenue estimates | Open pages; revenue paywalled; error 30-50% by their own method page | V | Revenue sanity only |
| GameAnalytics 2026 Roblox report | D1/D7/D30, session length, device mix, payer share | Open | V | Retention targets (`roblox-design-and-launch` 1a) |
| Naavik, Deconstructor of Fun, GameDev Reports (Substack) | Analysis, market sizing, weekly recaps | Open | C | Strategy context |
| Google Trends (`roblox <term>`) | Relative interest 0-100, seasonality | Unofficial; needs a cookie jar; breaks often | M | Seasons, rising themes |
| Reddit `reddit.com/r/roblox/top/.rss?t=week` | Hype and complaints | RSS open (JSON blocked) | C | Social signal |
| YouTube, TikTok, X, Twitch | Gameplay views, hashtags | API key or a browser | C | Only with the user's OK (browser tools) |

Do not use: retention tables from bloxg.com or genre D1 targets from blogs without a method (they claim 25-35 % D1 against a GameAnalytics median of 10.3 %); keyword tools that show placeholder rows (ROLearn's keyword page on 2026-11-03).

## 4. Keyword research (no official search volume exists)

Roblox publishes no search volume or keyword rank. Use proxies and say so:

1. `suggest "<theme>" --expand`: the order and number of long-tail suggestions show what players type.
2. `keyword` per candidate: top-10 summed CCU (demand), rank-1 CCU (a low number means weak competition), median age of the top 10, titles containing the exact word, share of results created in the last 90 days (clone pressure).
3. Google Trends for up to 5 `roblox <term>` queries, 12 months: seasonality and direction.
4. Count title words on trending, up-and-coming and trending-in-genre charts.
5. Search results reshuffle within a day or two and differ by country: repeat after 24 h with `--country` set before trusting an order.

Example (M, 2026-11-03): "steal" had 39 of 40 results with the word in the title, 75 % created in the last 90 days, and one game holding most of the CCU. "fishing" had a rank-1 game with about 2K players and the biggest game at rank 4. The first is crowded with clones; the second has room for a strong entry.

## 5. Research recipe (ideation, about 15 minutes)

1. **Frame.** Read the latest shareholder letter and GameAnalytics medians. Note DAU, discovery direction and season.
2. **Charts.** `charts --top 25`, then the trending-in-genre sorts that fit the idea, for computer and high_end_phone. Note rank, CCU, age and flags.
3. **Shortlist.** Pick 3-5 games closest to the idea. Run `game` on each for passes, max players, update recency and the badge funnel.
4. **Decay.** Run `history` on the shortlist. Note peak (7-day average of daily peaks), now/peak and half-life.
5. **Keywords.** Section 4 for 2-3 candidate themes or names. Add RoTerminal `trends?word=<theme>` for how many new games used the word in the last 30 days against the 30 before (clone pressure), one call per theme.
6. **Verdict.** Write `docs/research.md`: date, table of findings with grades, then 3 findings for the user, each with "pattern -> your plan -> suggested change". End with go, change or stop, and what evidence would flip it.

## 6. Reading the numbers (judgment unless graded)

- **Size for week 8, not launch day.** Viral hits decay fast. Measured 2026-11-03 (M): 99 Nights in the Forest fell to 12 % of its peak 7-day average with a half-life of 82 days, and it updates often. Trackers (V) show Grow a Garden 2 going from about 976K at its June 2026 peak to under 1K, and Kick a Lucky Block from about 1.7M (May 2026) to about 10K. Plan servers, economy and live ops for the week-8 audience, with D8-28 hooks and weekly drops ready before launch.
- **New games do break in.** Roblox says about 40 % of the weekly RFY top 100 by impressions were created in the last three months (Q3 2026 letter, O), and RFY is tuned for long-term retention with age-cohort weighting. A fresh game with good retention is not locked out; a fast clone with poor retention is.
- **Clone check.** If most top results for the theme are under 90 days old and share the title word, the idea needs a twist: name one thing it does that the top clone does not. Speed to market is not a moat; Roblox reports AI-built fast follows reaching the top 20 (Q3 2026 letter, O). A presentation twist is copyable too: Throw An Egg! had the tap meter, PERFECT and chase camera of Throw Food For Animals two days before it and stayed at about 1.3K CCU, and a paid template of Throw Food For Animals was on sale 3 days after its breakout (M, 2026-11-03). Treat a cinematic or a meter as table stakes; the moat is execution and update speed.
- **Ignition lag.** Hits took off 1-5 weeks after creation (Steal An Egg about 19 days, Throw Food For Animals about 5 weeks; M/V dates), and YouTube videos came after the ramp had started. Their shops were live before the ramp: Throw Food For Animals had 33 developer products, +1 Spider Arm 13 passes 3 hours after creation (M, 2026-11-03). Ship the shop, group reward and update rhythm with the first public release, and launch a seasonal game weeks before its date (J).
- **Monetization signal.** A game ranked higher on top-earning than on playing-now earns above its size; open its passes with `game` to see the ladder.
- **Badge funnel.** Award counts of the first badge vs later badges approximate how far players get. Rough; badges can be granted in different orders.
- **Seasons and events.** Event tags (for example a pumpkin emoji in October titles) skew chart titles for weeks: The Hollow ended 2026-11-02 and many titles still carried Halloween tags the next day. Do not count tags or event frames in or right after an event window. Event weekends inflate peaks too: the Halloween weekend (2026-10-31 and 11-01) lifted every current peak, so re-pull a week later before reading decay (V/M). Replay shows horror and Halloween searches peak in September and October (O).
- **Trackers disagree.** Steal An Egg's all-time peak is reported as 9.9M and as 14.2M by different trackers (V). Quote a range and a source, or your own measured number.
- **Device and country.** Charts differ by device and country; check `high_end_phone` before a phone-first plan.

## 7. Snapshot 2026-11-03 (expires about 2026-12-15; re-run section 5 after that)

| Game | What it proves | Grade |
|---|---|---|
| Steal An Egg (created 2026-07-25, about 700K CCU, 7 per server) | Steal-from-bases plus RNG hatching, short risk runs, small servers | M |
| Break and Steal an Egg (about 2 months old, about 120K) | AI-built fast follows reach the top 20 | M/O |
| Animal Hospital (Best New Game 2026) | Shift-based 4-player co-op job sim with light horror; slow-burn growth | O/V |
| 99 Nights in the Forest | Shared-resource co-op survival stays evergreen with frequent updates | M |
| Murder Mystery 2 | A seasonal event plus pass lifts an old social game (+146 % Sep to Oct, vendor) | V |
| RIVALS | Short ranked duels plus cosmetics hold a mid-size audience; earns above its CCU | M |
| Grow a Garden 2, Kick a Lucky Block | Huge launch spikes without retention fade within weeks | V |
| Throw Food For Animals (ramped about 5 weeks after creation) | One tap per throw, then a fixed 3.8 s chase-camera flight and 9 s from tap to the item card; small servers that stay full (5 of 5) | M |

First reward after spawning, from footage of 5 hits (M, 2026-11-03): Steal An Egg about 2 s (egg) and 9 s (pet), Ragdoll Playground 6 s, +1 Spider Arm 13 s, Throw Food For Animals 16-27 s; a skill run (DONT SPLASH) 33-55 s.

Genre share of plays 2026-08-24 to 2026-09-20 (V, dubit.io): Simulation 36.7 %, Survival 14.6 %, Obby 8.5 %, Roleplay 8.4 %. On 2026-11-03, 10 of the top 20 chart games were 90 days old or younger (M).

## 8. Etiquette and terms

- Read-only, low volume, cached: one run per question, results saved, never a loop or a crawler.
- Roblox's public gateway endpoints above are undocumented; the Terms of Use allow API use only "as described in the documentation". Keep use light and manual, and never bulk-harvest descriptions or images into a model.
- Respect third-party rules: Rolimon's asks for a 2 s crawl delay; RoTrends bars bots; RobloxGameStats disallows `/api/`; RoTerminal allows its `/api/agent/*` within the daily limit, bans bulk resale, copies of the site and limit dodging, asks for a link to roterminal.co when its numbers are shown publicly, and puts its HTML pages behind a bot check (use only the API).
- Data about other creators' games is for your planning; do not copy their names, thumbnails or text (`roblox-design-and-launch` section 6).
