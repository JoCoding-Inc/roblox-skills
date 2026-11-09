---
name: roblox-release-automation
description: "Use when shipping a Roblox game or update: splits the release into what an agent can automate through Open Cloud (place publish, server restart, passes, products, place name and description, platform toggles) and what the user must do by hand (create the game, maturity questionnaire, age check, icon and thumbnails, public release), lists the API key scopes each step needs, and what to ask the user when a permission is missing."
when_to_use: "Also before writing a publish script or CI job, when a publish or API call returns 401/403/404/409/429, when asked to 'just release it', when setting up an API key or MCP Permissions, or when deciding what to hand back to the user. Pair with roblox-launch-benchmarks and roblox-pitfalls."
last_reviewed: 2026-11-05
sources:
  - https://github.com/Roblox/creator-docs (commit c8f5276, 2026-10-29): content/en-us/reference/cloud/openapi.json, universes-api/v1.json, game-passes-http-service/v1.json, developer-products-api/v1.json
  - https://create.roblox.com/docs/cloud/guides/usage-place-publishing
  - https://devforum.roblox.com/t/4975849 (Studio MCP Server Updates: Open Cloud access and asset import, posted 2026-11-04, read 2026-11-05)
  - https://create.roblox.com/docs/production/publishing/publish-games-and-places (read 2026-11-02)
  - https://create.roblox.com/docs/production/monetization/immersive-ads (questionnaire resubmission and ads eligibility)
  - https://devforum.roblox.com/t/new-transaction-refunded-webhook-notifies-when-a-purchase-is-cancelled/4890339
  - https://devforum.roblox.com/t/update-on-account-bans-alt-detection-and-appeals/4972565
  - https://devforum.roblox.com/t/unifying-data-stores-open-cloud-and-game-apis-and-increasing-storage-limits/4739240
  - https://devforum.roblox.com/t/4889837 (Luau Execution limits, community report)
  - https://create.roblox.com/docs/cloud (legacy APIs are cookie-based)
  - original (field notes in roblox-pitfalls)
---

# Release automation: what the agent does, what the user does

Facts come from the official OpenAPI specs and publishing docs, not memory. Scope names and limits change: if a call fails with an unknown scope, re-read `reference/cloud/openapi.json` in `Roblox/creator-docs`.

**Two routes to the same APIs.** With Studio open and its MCP connected, the Studio MCP tool `open_cloud_invoke` calls Open Cloud with Studio's token and no API key, within the MCP Permissions the user turned on for this game (`roblox-studio-ai-tools` section 1a). Use it for store setup, settings, publish, restart and analytics in a session. Keep an API key (section 2) for CI with no Studio, for endpoints that refuse the Studio token, and for scopes MCP cannot grant: every `legacy-*` scope (localization, the legacy icon and thumbnail endpoints, activate) and badge scopes. Never switch to a key to get around a permission the user turned off: ask.

## 1. The split

| Release step | Who | How |
|---|---|---|
| Create the game (universe) and first place | **User** | Studio File > Save to Roblox (or Publish), or Creator Hub. The OpenAPI has no create-universe endpoint |
| Age check (facial age estimation) or ID verification, 2-step verification | **User only** | Needs the user's camera or ID document. No endpoint exists in the OpenAPI; the agent must not try to drive it |
| Create the API key (choose experience, scopes, IP rules, expiry) | **User** | Creator Hub > Credentials. The agent never creates keys and never sees the key in chat |
| Build the place file (`rojo build -o game.rbxl`) and run tests | Agent | Local tools; Luau Execution API for engine tests |
| Publish a place version | Agent | `POST /universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved\|Published`, binary `.rbxl`, scope `universe-places:write` |
| Skip-list: places with EditableImage, EditableMesh, PartOperation, SurfaceAppearance, BaseWrap | **User** | Publish those from Studio; the API does not update these instances |
| Roll live servers to the new version | Agent | `POST /cloud/v2/universes/{id}:restartServers`, scope `universe:write`, 30 requests per minute; default restarts only servers on older versions, `closeAllVersions=true` restarts all, `placeIds` limits places |
| Game name and description, server size | Agent | `PATCH /cloud/v2/universes/{id}/places/{placeId}`, scope `universe.place:write` (the universe name and description follow the root place). A Creator Hub save in a non-English UI replaced the English name and description with that language twice (field note, 2026-11-09): keep both in a repo file and re-read the universe `displayName` on a schedule while ads run |
| Platform toggles (desktop, mobile, tablet, console, VR), voice chat, private server price, social links | Agent | `PATCH /cloud/v2/universes/{id}`, scope `universe:write`. `visibility` and `ageRating` are read-only there |
| Create or update game passes and developer products (name, description, price, for-sale, icon file) | Agent | `POST /game-passes/v1/universes/{id}/game-passes` (5 per second), `POST /developer-products/v2/universes/{id}/developer-products` (3 per second); scopes `game-pass:write`, `developer-product:write` (read: `game-pass:read`, `developer-product:read`). Managed pricing on an existing item: multipart `isManagedPricingEnabled=true` on its PATCH (`isRegionalPricingEnabled` is deprecated; it returned 204 and changed nothing). Until the owner finishes the one-time opt-in in Creator Hub (Monetization > Managed Pricing) the call answers 400 `InvalidManagedPricing` (observation, 2026-11) |
| Grant logic for purchases (`ProcessReceipt`) | Agent | In code; verify with a Studio test and a real test purchase by the user |
| Remote config and A/B experiments | Agent | Configs and experiments APIs, scope `universe:write` (read `universe:read`); configs publish is limited |
| Messaging to live servers (for example a shutdown notice) | Agent | `POST /cloud/v2/universes/{id}:publishMessage`, scope `universe-messaging-service:publish` |
| Upload assets (images, meshes, audio) | Agent, after the user says yes to the batch | Uploads are permanent: Open Cloud cannot delete or archive models or images (Creator Dashboard only), and every upload goes through moderation on the owner's account, so check generated textures first (one creator got a warning for an AI-added fake blood texture, DevForum reply 2026-11-04). Assets API, scopes `asset:read`, `asset:write`; the owner must match the experience owner, or grant the universe use of an asset you have rights over: `PATCH /asset-permissions-api/v1/assets/permissions` (beta, scope `asset-permissions:write`), body `{"subjectType":"Universe","subjectId":"<universeId>","action":"Use","requests":[{"assetId":N,"grantToDependencies":true}]}`, which returns `successAssetIds`. Confirm in a Play client (`roblox-pitfalls` section 4) |
| Maturity & Compliance Questionnaire | **Agent-assisted, user submits** | No API: the OpenAPI has no questionnaire endpoint (only a cookie-based, read-only activation-eligibility check). The agent drafts answers from the design brief (answer for the most mature content a player can meet) and, after asking each time (it is the user's signed-in account), can fill the form in the user's own logged-in Chrome (`claude-in-chrome`) up to the **Questionnaire Preview** page. The user reviews the label and clicks Submit, because the answers are the creator's attestation to Roblox. Resubmit after an update that changes an answer, and only then: while a resubmission is under review the game temporarily loses immersive and rewarded-video ads eligibility |
| Game icon and thumbnails | Agent via experimental API, else browser or user | Homepage thumbnail personalization (`/thumbnail-personalization-api/v1/universes/{id}/...`, scopes `universe.thumbnail:read`/`:write`, EXPERIMENTAL, spec marks them first-party OAuth only, so the Studio MCP route rather than an API key; **not tested here**). Otherwise `POST /legacy-game-internationalization/v1/game-icon/games/{id}/language-codes/{code}` and `.../game-thumbnails/games/{id}/language-codes/{code}/image` (plus `/images/order`, `/alt-text`) accept an API key or OAuth scope `legacy-universe:manage` per the spec, stability EXPERIMENTAL, **not tested here**. Try it first on a throwaway universe; if it fails, upload in Creator Hub > Configurations (the agent can drive the file picker in Chrome after the user says yes). Specs: icon 512x512, thumbnails 16:9 1920x1080 under 3 MB, up to 10 (`roblox-store-art-pack` section 5) |
| Localization: source language, supported languages, auto-translate toggles, source strings | Agent, after the user adds the scope | `legacy-universe:manage`, EXPERIMENTAL, 100 requests per minute per key owner; a key without it answers `{"message":"Scope not authorized."}`. Base `https://apis.roblox.com`. Table id: `POST /legacy-localization-tables/v1/autolocalization/games/{id}/autolocalizationtable` with `{}`. Sources: `PATCH .../localization-table/tables/{tableId}?gameId={id}` with `{"entries":[{"identifier":{"source":"Play","context":"","key":""},"metadata":{"example":"src/Menu.lua:12"}}]}`; read back `.../tables/{tableId}/entry-count?gameId={id}`. Languages: `PATCH /legacy-game-internationalization/v1/source-language/games/{id}?languageCode=en`; `PATCH .../supported-languages/games/{id}` with `[{"languageCodeType":"Language","languageCode":"es"}]`; per language `PATCH .../supported-languages/games/{id}/languages/{code}/automatic-translation-status` with `true` (`.../universe-display-info-automatic-translation-settings` for name and description); verify with `GET .../supported-languages/games/{id}/automatic-translation-status`. Script: `roblox-design-and-launch/scripts/l10n_sync.py` |
| Make the game public, choose audience (16+, all ages, Kids/Select), Recommended For You opt-out | **User decides**; call can be automated | `POST /legacy-develop/v1/universes/{id}/activate` (private to public) accepts an API key or `legacy-universe:manage`, EXPERIMENTAL, **not tested here**. Release requires the age check and a maturity rating, and the eligibility check is cookie-only, so the agent cannot pre-check it. Never call activate without the user's explicit yes for that moment; at most 5 first-time releases per day. Publish flow (docs, 2026-11-02): Studio File > Publish asks one question (No = Content May Vary, 16+; Yes = full questionnaire). Audience: Creator Hub > Publish settings > **Manage Audience**, tabs Playtest and Public ("Playtest" replaced Private and Limited). Recommended For You opt-out: Audience > Advanced Settings |
| Kids/Select extras: facial age estimation or ID, 2-step verification, Plus/Premium for 2 months or 1,000 Robux refundable fee, 50,000 Robux optional expedited review, evaluation of 250 unique plays by highly engaged age-checked users in 60 days (docs; a DevForum post says 100 from Nov 2026) | **User** | Money and identity decisions are never automated. For a group game these fall on the group owner, not an admin (docs `kids-and-select`). The expedited review is the paid alternative to waiting for the evaluation; if the user waits, put "revisit when the evaluation passes (Audience Reach dashboard)" in the hand-off and do not suggest the fee again |
| Transaction Refunded webhook (refund or chargeback of products, passes, private servers, paid access) | **User adds it**, agent writes the handler | Creator Hub Account Settings > Webhooks, up to 5 webhooks; verify the `roblox-signature` header. Roblox revokes passes but not developer products, so the handler revokes granted goods; the payload amount is the original price; events sent while the endpoint is down are lost |
| Early testers (up to 10 friends) | **User** | Studio File > Invite early testers |
| Watch day-1 metrics and errors | Agent reads, user decides | Analytics query API scope `universe.analytics:read`; Creator Hub dashboards |
| Rollback | Agent | Re-publish the previous `.rbxl` (keep it), or revert in Creator Hub version history; note the version number before each release |

**Two kinds of legacy endpoints (checked in the spec's `security` field):** paths starting `/legacy-...` (icon, thumbnails, activate, localization of icons and names, badges) list `roblox-api-key` and OAuth `legacy-*:manage` scopes, stability EXPERIMENTAL; paths starting plain `/v1/...` (activation-eligibility, group policies) list `roblox-legacy-cookie` only. The Open Cloud index warns legacy APIs can change without notice. Use the first kind with an API key after a test on a throwaway universe; never use a `.ROBLOSECURITY` cookie for the second kind, treat those steps as manual. A user added API system `legacy-universe` for the experience to an existing key in Creator Hub (key value unchanged) and the localization calls worked (2026-11-04); if it is not offered, fall back to the browser or manual path.

**Localization API quirks (observations, 2026-11-04):** the table PATCH answered 400 "Maximum entries exceeded" at 100 entries although `.../localization-table/limits` reports `maxEntriesPerUpdate` 300; 50 worked. A good PATCH returns `modifiedEntriesAndTranslations: []`, so confirm with entry-count. Adding many languages in one PATCH returned 504 but they were added, and per-language auto-translate toggles returned 200 yet some read back false: always read back and re-send the stragglers.

## 2. API key for a release pipeline

Create one key per experience, owner = the account or group that owns it, minimal scopes. Give the user this list and nothing broader:

| Need | Scope |
|---|---|
| Publish place versions | `universe-places:write` |
| Restart servers, update universe, configs/experiments | `universe:write` |
| Update place name, description, server size | `universe.place:write` |
| Passes / products | `game-pass:write`, `developer-product:write` |
| Asset upload | `asset:read`, `asset:write`; `asset-permissions:write` to grant a universe use of an asset |
| Engine tests | `universe.place.luau-execution-session:write` (and `:read` for results) |
| Notify live servers | `universe-messaging-service:publish` |
| Read analytics | `universe.analytics:read` |
| Icon, thumbnails, activate (experimental, untested); localization (worked 2026-11) | `legacy-universe:manage` |

Rules: restrict the key to the one experience; leave IP allow-lists empty unless the runner has a fixed IP (a list breaks keys used from Roblox servers); set an expiry only with a rotation owner; a key unused for 60 days expires; keep it in a `chmod 600` env file and read it inside the command. Rate limits apply per key owner across all keys. Data store calls from Open Cloud share one per-experience request budget with the live game servers (unified, live 2026-07-29), so rate-limit operational data store scripts or they can starve live traffic.

**Luau Execution in CI:** creating a task is limited to 5 per minute per key owner (`roblox-studio-ai-tools` section 7). Bundle all engine tests into one task per CI run and serialize runs (one concurrency group); parallel worktrees or jobs on the same key owner collide. A community report (C, 2026-09-23) saw a lockout of about 30 minutes after about 30 creates in 30 minutes, and a first task on a fresh Saved version hanging about 11 minutes before INTERNAL_ERROR; retry once, then report.

## 3. When a permission is missing

| Symptom | Likely cause | Ask the user to |
|---|---|---|
| 401 | Key missing, wrong, expired or revoked | Re-create the key and re-save it in the env file |
| 403 | Scope missing, experience not selected on the key, IP not allowed, or the key owner lacks the role in a group | Open the key in Creator Hub, add the scope above for this experience, check the IP list, confirm the owner has Edit rights on the group experience |
| 404 | Wrong universe or place id (Creator Hub URLs show the universe id under `/experiences/`) | Copy the Universe ID and Place ID from the Creations page; resolve the root place from `cloud/v2/universes/{id}` |
| 409 on publish | Place open in Studio holds an edit session (field note in `roblox-pitfalls`), or the place is not in that universe | Close the place in Studio, retry; confirm ids |
| 429 | Rate limit | Back off using `x-ratelimit-reset`; do not parallelize pass or product creation |
| Publish succeeds but players see the old build | Servers still run the old version | Run `:restartServers` or wait for natural turnover; verify the serving version |
| Asset renders blank in the live game | Asset owned by another account or group | Re-upload under the experience owner |
| Cannot go public | Missing age check, questionnaire, or (Kids/Select) 2-step verification | The user completes it; the agent cannot |
| Game restricted or flagged after release | A moderation violation on the game | Open Game > Safety > Issues & appeals (collaborators with edit rights can see and appeal); Select games get 72 h to fix lower-severity violations |

Before blocking, state exactly what is missing, which scope or account step fixes it, and keep working on the parts that do not depend on it.

## 4. Release runbook

1. Run the release gates in section 4a and the hard gates in `roblox-launch-benchmarks`; record the rollback version.
2. Build `game.rbxl`, run tests, publish to a **private test place** with `versionType=Saved` or `Published`, and let the user test the exact build.
3. User confirms the manual items (questionnaire, icon, thumbnails, audience) are done in Creator Hub.
4. Publish to the live place; print "published version N" and store it.
5. Restart older servers (`:restartServers`), optionally after a `publishMessage` notice.
6. Verify in a live client: assets load, a real purchase grants, save and rejoin work.
7. Watch errors and funnel for the first day; roll back by re-publishing the stored previous build if a blocker appears.

**First public release (once).** Before the user sets Audience to Public, check and report: group join approval off when rewards are group-gated (`roblox-design-and-launch` section 6, item 6b), RTBF templates (`roblox-data-saves` section 7), managed pricing on every item, one real cheap purchase on a live server, and every setting the agent PATCHed read back with a GET (a 2xx is not proof). After the flip, read `visibility` back. To back out, the user sets Audience back to Playtest; one game did this the same day and read back `PRIVATE` (2026-11), and revoking then releasing again does not count toward the daily first-release limit (docs `publish-games-and-places`).

## 4a. Release gates (run before step 2)

1. **Define the release:** list the changed places, scripts, assets, config, DataStore schemas, products and supported devices, plus the rollback path. Mark each gate required, conditional or not applicable.
2. **Block on high-consequence changes.** A failed or unverified gate here means NOT READY; it is never averaged into a percentage, and user approval does not turn it into PASS.
   - Save data changed: load, save, migration, duplicate session, disconnect and shutdown tested (test table in `roblox-data-saves` section 6).
   - Remotes or authority changed: argument types and bounds, ownership, replay, and abusive frequency validated on the server.
   - Purchases changed: `ProcessReceipt` grants are durable and idempotent, and retries are tested.
   - Cloud auth or webhooks changed: secrets, scopes, signatures, retries and deduplication verified.
   - Debug or test hooks (free grants, test purchases, forced rolls, skip-intro): each runs only behind a server-side `RunService:IsStudio()` check (false on live servers, docs); a client-side check does not count.
   - Dev leftovers: `HttpService.HttpEnabled` matches what the game needs (agent helpers turn it on briefly), and no test-only objects remain (`UiDeviceCheck`, `IconSheet`, `PackLineup`, helper ModuleScripts, debug ScreenGuis).
3. **Exercise what ships:** one normal flow plus failure, retry, leave and rejoin, and rapid input; every supported input mode (touch, keyboard, gamepad) and the device sizes in `roblox-ui-layout` section 6; errors, memory, frame and network cost, streaming; touch target size, contrast, readable text.
4. **Evidence:** every PASS cites a test, log, profiler capture, screenshot or dashboard readback. Anything without evidence is UNVERIFIED.
5. **Report:** `READY`, `NOT READY` or `READY WITH ACCEPTED RISK`, with blockers first, then warnings, unverified gates, evidence, rollback plan and skipped gates with reasons. After publishing, confirm the version players actually get.

## 5. Handoff message to the user (template)

"Done by me: <build, tests, publish version N, restart, passes>. Needs you: <list from section 1 marked User>. Missing permission: <scope/role/step> because <call and error>. After you do it I will <next automated step>."
