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
| Game pass | One-time purchase, benefit forever | Good for access and permanent perks. Icon up to 512x512. Cross-game pass and product sales ended 2026-05-30 |
| Developer product | Repeatable purchase | Currency packs, consumables; grant on the server after `ProcessReceipt` succeeds |
| Subscription | Recurring monthly benefit | Auto-renewing; Robux price at least 49 or local-currency tiers (2.99/4.99/7.99/9.99/14.99 USD); payout always in Robux (Robux subscriptions pay 70 percent monthly; local-currency ones 70 percent in month 1, then 100 percent); max 50 per game; Robux regional pricing cannot be turned off; Robux price changes allowed once per 60 days with 30 days' notice |
| Paid access / private servers | Pay to enter, pay for a private server | Roblox Plus subscribers get paid private servers free and you are still paid for their time |
| Immersive ads | Roblox serves ads in your 3D space | Billboards (video up to 30 s, or image) and portal ads; AdGui between 8x4.5 and 32x18 studs. Needs 13+, ID-verified, 2FA, approved questionnaire and 2,000 monthly unique visitors; paid on the 25th of the next month. Hide ads where `PolicyService` says ads are not allowed |
| Rewarded video | Player watches a 6-30 s ad for a reward | Needs 13+, ID-verified, 2,000 monthly unique visitors. The reward must be a developer product, never Robux (suggested value 3-10 Robux). Use `AdService` and check `GetAdAvailabilityNowAsync`; keep it optional |
| Avatar items / Marketplace | UGC items sold to players | Separate creator requirements |
| Creator Rewards | Robux for Daily Engagement and Audience Expansion | Replaced Engagement-Based Payouts on 2025-07-24. Daily Engagement: 5 Robux per Active Spender per day who plays 10+ minutes in one of your first 3 experiences that day (Active Spender = at least 9.99 USD of qualifying purchases in 60 days). Audience Expansion: 35 percent of the first 100 USD a new or returning user spends in 60 days; needs 100+ average DAU. Earned Robux with a 60-day hold |
| Roblox Plus | Subscribers get 10-20 percent discounts (Roblox covers it, your earnings are not reduced) | You can earn for driving Plus sign-ups (up to 750 Robux each) and paid private server time (up to 100 Robux per subscriber per month) |

Other rules: paid random items must show numeric odds that sum to 100 percent and check `PolicyService`; fake urgency timers and always-on "sales" are banned; paid access costs 25-1000 Robux (or local-currency tiers) and excludes private servers; developer product price 1 to 1 billion Robux; managed regional pricing runs 30-100 percent of the default and is on by default for new passes and products.

Design rules: never block the core loop behind a purchase; do not give Premium or paying players an unfair tactical edge; describe offers honestly in the description; do not promise Robux or out-of-game rewards. Add monetization after the core loop is fun, with funnel and economy events logged from the first build.

**DevEx (cashing out):** only Earned Robux counts. Standard rate 0.0038 USD per Earned Robux (30,000 Robux = 114 USD); balances earned before 2025-09-05 10:00 PT cash out at 0.0035. A higher 0.0054 rate (effective 2026-06-08) applies to developer product, pass, subscription and private-server purchases by U.S. players who are age-verified 18+, in eligible games. Eligibility requires that player characters stay R15 (or a qualifying human-form or custom rig) for 100 percent of active playtime with no R6 option; set Studio Avatar Settings to R15 Only. Minimum cash-out 30,000 Earned Robux (114 USD), age 13+, W-8/W-9 on file. DevEx payouts become royalties from 2026-11-01 (tax information was due 2026-10-31). Direct purchases, monthly Premium/Plus grants, resale and Robux transfers do not count. Re-read `developer-exchange` before quoting rates to a user.

## 3. Analytics and live ops

- Creator Dashboard analytics: engagement, retention (D1/D7 and beyond), monetization, acquisition, performance, crashes, demographics; custom events, funnel events, economy events, custom dashboards and alerts.
- Economy events use Source/Sink with transaction types IAP, TimedReward, Onboarding, Shop, Gameplay, ContextualPurchase; funnels up to 10 x 100 steps. Configs: up to 1,000 active configs, 100 conditions; read with `ConfigService:GetConfigAsync`/`GetConfigForPlayerAsync`; publish takes 15-60 s. Experiments run 14-60 days, 2 variants plus control, metrics D1, D7, playtime, ARPU, ARPPU, payer conversion.
- Instrument before launch: onboarding funnel steps, first purchase, session length, quit points, economy sources and sinks.
- **Experiments** (A/B tests) and **Configs** (remote values) ship balance and UI changes safely. Open Cloud exposes both for automation (configs API is beta, experiments API experimental, so expect changes; configs publish is limited to 10 per minute).
- `RecommendationService` lets you build in-game recommendation carousels (register items, log one impression per item per session, log quality actions, fetch).
- Live ops plan: a content cadence, events (Experience Events), and a weekly review of retention, funnel and error reports.

## 4. Age, safety and content maturity (check before design is final)

- **Content maturity** is required: without it Roblox restricts playability for everyone. Fill the Maturity & Compliance questionnaire (Creator Dashboard > experience > Publish settings or Audience > Maturity & Compliance); answer for the most mature content a player can meet. Misrepresenting it risks moderation.
- Labels and who can play: **Minimal / Mild** reaches Roblox Kids (5-8) and Select (9-15); **Moderate** reaches Select (9-15) and standard (16+); **Content May Vary** needs age-checked 16+; **Restricted** needs age-verified 18+ (servers run restricted). Realistic or excessive violence, blood, crude humour or romance in uploaded assets can be moderated whatever the label.
- **16+ release path:** account in good standing and at least 2 days old, age check, and answer the first questionnaire question (answering No gives Content May Vary, 16+ only). A maximum of 5 first-time releases per day.
- **Simpler publish flow (rolling out from Oct 2026):** a guided flow synced between Creator Hub and Studio. A game with no age-restricted content answers one confirmation question instead of the full questionnaire (up to 30 questions) to reach players 16+ in most regions. The full questionnaire is still needed for restricted content or Kids / Select reach. **Early testers:** invite up to 10 friends to preview an unpublished game in the Roblox app. Highly Engaged Player counts in Creator Hub update hourly.
- **Roblox Kids / Select (all ages):** age check plus facial age estimation or ID verification, 2-step verification, Plus/Premium for 2 consecutive months or a 1,000 Robux refundable fee (50,000 for expedited review), the full questionnaire with a Minimal/Mild/Moderate result, and an evaluation of 250 unique highly engaged plays within 60 days. Select-only publishing drops the fee/subscription requirement. Confirm the intended audience in `roblox-project-intake`.
- Free text between players (signs, boards, pet names, trading notes) outside `TextChatService` is enforced against now; see `roblox-engine-2026` section 5.
- Age checks (facial age estimation) gate chat and other features; do not build features that bypass `TextChatService` filtering. Platform-integrated chat becomes mandatory for all games in May 2027 (see `roblox-engine-2026` section 5), and voice chat is limited to experiences of 100 players or fewer.
- **Generative AI in games:** Roblox-served AI (`GenerationService`, `TextGenerator`) is moderated and aims at All Ages; third-party AI output is your responsibility and must follow Community Standards. A game whose main purpose is continuous chat with an AI character, or whose AI remembers prior sessions, has "extended AI interactions": answer Yes in the questionnaire and expect a Restricted (18+) label.
- Disclosures, IP and rights: follow the IP guidelines and Rights Manager; keep `assets/LICENSES.md`; do not publish copied art or music.

## 5. Pricing and balance changes

- Change one thing at a time and measure with an experiment, not a feeling.
- Regional pricing is on by default for Robux subscriptions; plan prices accordingly.
- Never raise prices on existing owners of a pass without a clear value add.

## 5b. Discovery (what the recommender rewards)

- Recommended for You retrieves then ranks; ranking counts only users who arrived through it. Strongest signals: play-through rate, first-play bounce rate (negative; 61-180 s window), play days per user (D1, D2-7, D8-28), playtime per user (capped at 60 min per user per game per day). Also: co-play days, qualified sessions, spend days, Robux spent per user. Signals are per-user averages, so small games are not penalised and new games need no 28-day wait.
- A custom thumbnail is required for home recommendations (in force since 2026-10-19: a default thumbnail gets no Home impressions). Metadata that does not match the content, giveaway-led titles and near-duplicate games hurt exposure.
- Description: the first about 160 characters matter most (about 1,000 total); hashtags and tags are not used.
- Other surfaces: Standout Games, Sponsored, semantic Search, Discover, notifications, experience events (max 10 events; update posts up to 60 characters, once every 3 days). Programs worth knowing: Creator Rewards, Developer Awards, Standout Games, Learn & Explore, Jumpstart (18+ novel games), Incubator.

## 6. Publish checklist

Who does what (agent vs user), API key scopes and missing-permission handling: `roblox-release-automation`. Benchmark gates: `roblox-launch-benchmarks`.

1. Dev place tested; a private test place built from the exact publish build; tester told what to check and the known issues.
2. Content maturity done; genre chosen; description honest (include controls, update notes; do not stuff keywords).
3. **Icon** 512x512 (previews scale down to about 150 px; check it small). **Thumbnails** 16:9, 1920x1080, under 3 MB; up to 10 images/videos; uploaded video has a monthly quota (3 uploads). Craft rules in `roblox-store-art-pack` section 5.
4. Localization: add source text, auto-translate or manual translations; check long strings in the UI.
5. Accessibility (readable text, contrast, never colour or sound alone, honour `GuiService.PreferredTransparency`, `PreferredTextSize` and reduced motion); console (10-foot UI, TV-safe area, full controller navigation, no chat window); VR (OpenXR, default camera scripts, instance streaming, Quest aims for 72 fps); device and network simulator checks.
5b. Localization: source and supported languages, `AutoLocalize`; auto-translate covers 18 languages (Arabic, Chinese simplified/traditional, English, French, German, Hindi, Indonesian, Italian, Japanese, Korean, Polish, Portuguese, Russian, Spanish, Thai, Turkish, Vietnamese). Analytics: log events after success, not on attempt; custom events max 100 names; data rolls off after 90 days.
6. Assets owned by the publishing account/group and verified loadable in a live client.
7. Publish through Open Cloud (`versionType=Published`; `Saved` stages a version without releasing it); record the version number; keep the rollback version. The API skips EditableImage, EditableMesh, PartOperation, SurfaceAppearance and BaseWrap instances, so publish those places from Studio.
8. Day-1 watch: crashes, error reports, funnel drop-off, DataStore errors.

## 7. Account and rights hygiene

- Use a group-owned experience for teams; assets uploaded to the wrong owner render blank.
- Turn on 2-step verification; use API keys restricted to the one experience with the minimum scopes; keep keys in env files. IP allow-lists break keys used from Roblox servers, expiry dates need a rotation process, and keys unused for 60 days expire. Asset scopes follow the creator (user or group), so a user key cannot manage group assets without the group role.
- Create the game and its dev place separately; never edit the live place in Studio.

## 8. Re-check these live pages before relying on numbers

Pages that change: `production/monetization/developer-exchange`, `creator-rewards`, `roblox-plus`, `promotion/content-maturity`, `publishing/kids-and-select`, `generative-AI`. The Studio MCP tool `http_get` or the Assistant skill `rbx-docs-search` reads current docs; the documentation source repository is `github.com/Roblox/creator-docs` (path `content/en-us`).
