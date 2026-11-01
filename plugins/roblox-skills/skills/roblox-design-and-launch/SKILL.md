---
name: roblox-design-and-launch
description: "Use for Roblox game design and release decisions: core loops, prototyping, onboarding and UX, economy balance, monetization (passes, developer products, subscriptions, ads, Creator Rewards, DevEx), content maturity and age rules, generative-AI rules, icon/thumbnail/description, analytics and experiments, localization."
when_to_use: "Also before adding any purchase or chat/AI feature, before the first public publish, when choosing the target audience or maturity label, when a game needs a retention or funnel review, or when asked what Roblox pays creators."
last_reviewed: 2026-11-01
sources:
  - https://create.roblox.com/docs/production/game-design (core-loops, prototyping, onboarding, ui-ux-design, monetization-foundations)
  - https://create.roblox.com/docs/production/monetization (developer-exchange, 18-plus-devex-rate, subscriptions, immersive-ads, roblox-plus)
  - https://create.roblox.com/docs/creator-rewards
  - https://create.roblox.com/docs/production/promotion/content-maturity
  - https://create.roblox.com/docs/production/publishing/kids-and-select
  - https://create.roblox.com/docs/production/publishing/experience-icons
  - https://create.roblox.com/docs/production/publishing/thumbnails
  - https://create.roblox.com/docs/generative-AI
  - https://create.roblox.com/docs/production/analytics
---

# Design, policy and launch

Read from the official creator-docs repository (state 2026-10-29). Numbers and policies change; the checks in section 8 say when to re-read the live page. Pair with `roblox-dev-workflow` and `roblox-store-art-pack` (icon and thumbnail craft).

## 1. Design

- **Core loop** = minute-to-minute interaction + most repeated action + progression engine. Write all three before building. A game without a progression engine feels shallow.
- **Prototype** with paper first (systems, UI flows, economy), then a greybox in Studio (feel, camera, controls). Paper gives speed and finds design flaws early, but cannot test feel and can give false positives; a greybox does.
- **Onboarding (first-time user experience):** teach the essentials, reach fun quickly, leave players wanting more. Measure the player funnel step by step and fix the biggest drop-off with an experiment.
- **UI/UX:** prioritise information (what is the player doing right now?), keep visual language consistent, follow platform conventions. Design for phone first, then scale up. Test layouts with Experiments, toggle platform or seasonal UI with Configs.
- **Economy:** every currency needs sources, sinks and a pacing target. Simulate the economy in a spreadsheet or Lune script before shipping prices. Avoid power that only paying players can reach if the game is for younger audiences.
- **Genre craft:** for chunky simulator/tycoon looks use `roblox-ui-genre-studs`; for other genres use roblox-brain `roblox-gui`.

## 2. Monetization options (Robux)

| Option | What it is | Notes |
|---|---|---|
| Game pass | One-time purchase, benefit forever | Good for access and permanent perks |
| Developer product | Repeatable purchase | Currency packs, consumables; grant on the server after `ProcessReceipt` succeeds |
| Subscription | Recurring monthly benefit | Auto-renewing; priced in local currency or Robux; payout always in Robux; all subscriptions in a game can be owned together; regional pricing on Robux subscriptions cannot be turned off |
| Paid access / private servers | Pay to enter, pay for a private server | Roblox Plus subscribers get paid private servers free and you are still paid for their time |
| Immersive ads | Roblox serves ads in your 3D space | Billboards (video up to 30 s, or image) and portal ads. Opt in; keep placement fair |
| Rewarded video | Player watches an ad for a reward | Needs eligibility; keep rewards optional |
| Avatar items / Marketplace | UGC items sold to players | Separate creator requirements |
| Creator Rewards | Robux for Daily Engagement and Audience Expansion | Replaced Engagement-Based Payouts on 2025-07-24 |
| Roblox Plus | Subscribers get 10-20 percent discounts (Roblox covers it, your earnings are not reduced) | You can earn for driving Plus sign-ups (up to 750 Robux each) and paid private server time (up to 100 Robux per subscriber per month) |

Design rules: never block the core loop behind a purchase; do not give Premium or paying players an unfair tactical edge; describe offers honestly in the description; do not promise Robux or out-of-game rewards. Add monetization after the core loop is fun, with funnel and economy events logged from the first build.

**DevEx (cashing out):** only Earned Robux counts. Standard rate 0.0038 USD per Earned Robux (30,000 Robux = 114 USD); balances earned before 2025-09-05 10:00 PT cash out at 0.0035. A higher 0.0054 rate applies to certain Earned Robux from eligible games, from purchases by U.S. players who are age-verified 18+ (developer products, passes, subscriptions, private servers). The 18+ rate rewards high-quality character articulation and creative direction. Direct purchases, monthly Premium/Plus grants, resale and Robux transfers do not count. Re-read `developer-exchange` before quoting rates to a user.

## 3. Analytics and live ops

- Creator Dashboard analytics: engagement, retention (D1/D7 and beyond), monetization, acquisition, performance, crashes, demographics; custom events, funnel events, economy events, custom dashboards and alerts.
- Instrument before launch: onboarding funnel steps, first purchase, session length, quit points, economy sources and sinks.
- **Experiments** (A/B tests) and **Configs** (remote values) ship balance and UI changes safely. Open Cloud exposes both for automation.
- `RecommendationService` lets you build in-game recommendation carousels (register items, log one impression per item per session, log quality actions, fetch).
- Live ops plan: a content cadence, events (Experience Events), and a weekly review of retention, funnel and error reports.

## 4. Age, safety and content maturity (check before design is final)

- **Content maturity** is required: without it Roblox restricts playability for everyone. Fill the Maturity & Compliance questionnaire (Creator Dashboard > experience > Publish settings or Audience > Maturity & Compliance); answer for the most mature content a player can meet. Misrepresenting it risks moderation.
- Labels and who can play: **Minimal / Mild** reaches Roblox Kids (5-8) and Select (9-15); **Moderate** reaches Select (9-15) and standard (16+); **Content May Vary** needs age-checked 16+; **Restricted** needs age-verified 18+ (servers run restricted). Realistic or excessive violence, blood, crude humour or romance in uploaded assets can be moderated whatever the label.
- Reaching Kids/Select audiences adds publishing requirements (age-checked, verified, or 2-step verification on the creator account). Confirm with the user which audience is intended in `roblox-project-intake`.
- Age checks (facial age estimation) gate chat and other features; do not build features that bypass `TextChatService` filtering.
- **Generative AI in games:** Roblox-served AI (`GenerationService`, `TextGenerator`) is moderated and aims at All Ages; third-party AI output is your responsibility and must follow Community Standards. A game whose main purpose is continuous chat with an AI character, or whose AI remembers prior sessions, has "extended AI interactions": answer Yes in the questionnaire and expect a Restricted (18+) label.
- Disclosures, IP and rights: follow the IP guidelines and Rights Manager; keep `assets/LICENSES.md`; do not publish copied art or music.

## 5. Pricing and balance changes

- Change one thing at a time and measure with an experiment, not a feeling.
- Regional pricing is on by default for Robux subscriptions; plan prices accordingly.
- Never raise prices on existing owners of a pass without a clear value add.

## 6. Publish checklist

1. Dev place tested; a private test place built from the exact publish build; tester told what to check and the known issues.
2. Content maturity done; genre chosen; description honest (include controls, update notes; do not stuff keywords).
3. **Icon** 512x512 (previews scale down to about 150 px; check it small). **Thumbnails** 16:9, 1920x1080, under 3 MB; up to 10 images/videos; uploaded video has a monthly quota (3 uploads). Craft rules in `roblox-store-art-pack` section 5.
4. Localization: add source text, auto-translate or manual translations; check long strings in the UI.
5. Accessibility, console and VR guidelines if those platforms are targeted; device and network simulator checks.
6. Assets owned by the publishing account/group and verified loadable in a live client.
7. Publish through Open Cloud; record the version number; keep the rollback version.
8. Day-1 watch: crashes, error reports, funnel drop-off, DataStore errors.

## 7. Account and rights hygiene

- Use a group-owned experience for teams; assets uploaded to the wrong owner render blank.
- Turn on 2-step verification; use API keys with the minimum scopes, an IP allow-list and an expiry date; keep keys in env files.
- Create the game and its dev place separately; never edit the live place in Studio.

## 8. Re-check these live pages before relying on numbers

Pages that change: `production/monetization/developer-exchange`, `creator-rewards`, `roblox-plus`, `promotion/content-maturity`, `publishing/kids-and-select`, `generative-AI`. The Studio MCP tool `http_get` or the Assistant skill `rbx-docs-search` reads current docs; the documentation source repository is `github.com/Roblox/creator-docs` (path `content/en-us`).
