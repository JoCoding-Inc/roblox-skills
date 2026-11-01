---
name: roblox-release-automation
description: "Use when shipping a Roblox game or update: splits the release into what an agent can automate through Open Cloud (place publish, server restart, passes, products, place name and description, platform toggles) and what the user must do by hand (create the game, maturity questionnaire, age check, icon and thumbnails, public release), lists the API key scopes each step needs, and what to ask the user when a permission is missing."
when_to_use: "Also before writing a publish script or CI job, when a publish or API call returns 401/403/404/409/429, when asked to 'just release it', when setting up an API key, or when deciding what to hand back to the user. Pair with roblox-publish-checklist, roblox-cloud and roblox-launch-benchmarks."
last_reviewed: 2026-11-01
sources:
  - https://github.com/Roblox/creator-docs (commit c8f5276, 2026-10-29): content/en-us/reference/cloud/openapi.json, universes-api/v1.json, game-passes-http-service/v1.json, developer-products-api/v1.json
  - https://create.roblox.com/docs/cloud/guides/usage-place-publishing
  - https://create.roblox.com/docs/production/publishing/publish-games-and-places
  - https://create.roblox.com/docs/cloud (legacy APIs are cookie-based)
  - original (field notes in roblox-pitfalls)
---

# Release automation: what the agent does, what the user does

Facts come from the official OpenAPI specs and publishing docs, not memory. Scope names and limits change: if a call fails with an unknown scope, re-read `reference/cloud/openapi.json` in `Roblox/creator-docs`.

## 1. The split

| Release step | Who | How |
|---|---|---|
| Create the game (universe) and first place | **User** | Studio File > Publish to Roblox, or Creator Hub. The OpenAPI has no create-universe endpoint |
| Account, group and 2-step verification, age check or ID verification | **User** | Roblox account settings; needed for any release |
| Create the API key (choose experience, scopes, IP rules, expiry) | **User** | Creator Hub > Credentials. The agent never creates keys and never sees the key in chat |
| Build the place file (`rojo build -o game.rbxl`) and run tests | Agent | Local tools; Luau Execution API for engine tests |
| Publish a place version | Agent | `POST /universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved\|Published`, binary `.rbxl`, scope `universe-places:write` |
| Skip-list: places with EditableImage, EditableMesh, PartOperation, SurfaceAppearance, BaseWrap | **User** | Publish those from Studio; the API does not update these instances |
| Roll live servers to the new version | Agent | `POST /cloud/v2/universes/{id}:restartServers`, scope `universe:write`, 30 requests per minute; default restarts only servers on older versions, `closeAllVersions=true` restarts all, `placeIds` limits places |
| Game name and description, server size | Agent | `PATCH /cloud/v2/universes/{id}/places/{placeId}`, scope `universe.place:write` (the universe name and description follow the root place) |
| Platform toggles (desktop, mobile, tablet, console, VR), voice chat, private server price, social links | Agent | `PATCH /cloud/v2/universes/{id}`, scope `universe:write`. `visibility` and `ageRating` are read-only there |
| Create or update game passes and developer products (name, description, price, for-sale, icon file) | Agent | `POST /game-passes/v1/universes/{id}/game-passes` (5 per second), `POST /developer-products/v2/universes/{id}/developer-products` (3 per second); scopes `game-pass:write`, `developer-product:write` (read: `game-pass:read`, `developer-product:read`) |
| Grant logic for purchases (`ProcessReceipt`) | Agent | In code; verify with a Studio test and a real test purchase by the user |
| Remote config and A/B experiments | Agent | Configs and experiments APIs, scope `universe:write` (read `universe:read`); configs publish is limited |
| Messaging to live servers (for example a shutdown notice) | Agent | `POST /cloud/v2/universes/{id}:publishMessage`, scope `universe-messaging-service:publish` |
| Upload assets (images, meshes, audio) | Agent | Assets API, scopes `asset:read`, `asset:write`; the owner must match the experience owner |
| Maturity & Compliance Questionnaire | **User** | Creator Hub or Studio publish flow. One question for 16+ without restricted content; the full questionnaire for restricted content or Kids/Select. The agent can prepare honest answers from the design, the user submits |
| Game icon and thumbnails | **User** | Creator Hub > Configurations. Specs: icon 512x512, thumbnails 16:9 1920x1080 under 3 MB, up to 10 (`roblox-store-art-pack` section 5). The agent makes the files and checks them |
| Make the game public, choose audience (16+, all ages, Kids/Select), Recommended For You opt-out | **User** | Release dialog; at most 5 first-time releases per day |
| Kids/Select extras: facial age estimation or ID, 2-step verification, Plus/Premium for 2 months or 1,000 Robux refundable fee, 50,000 Robux optional expedited review | **User** | Money and identity decisions are never automated |
| Early testers (up to 10 friends) | **User** | Studio File > Invite early testers |
| Watch day-1 metrics and errors | Agent reads, user decides | Analytics query API scope `universe.analytics:read`; Creator Hub dashboards |
| Rollback | Agent | Re-publish the previous `.rbxl` (keep it), or revert in Creator Hub version history; note the version number before each release |

**Not safe to rely on:** endpoints named `legacy-*` (game icon, thumbnails, universe activate/deactivate, localization of icons). The Open Cloud index says legacy APIs use cookie-based authentication and may change without notice. Never use a `.ROBLOSECURITY` cookie; treat these steps as manual. Whether an API key can be granted those scopes was not verified.

## 2. API key for a release pipeline

Create one key per experience, owner = the account or group that owns it, minimal scopes. Give the user this list and nothing broader:

| Need | Scope |
|---|---|
| Publish place versions | `universe-places:write` |
| Restart servers, update universe, configs/experiments | `universe:write` |
| Update place name, description, server size | `universe.place:write` |
| Passes / products | `game-pass:write`, `developer-product:write` |
| Asset upload | `asset:read`, `asset:write` |
| Engine tests | `universe.place.luau-execution-session:write` (and `:read` for results) |
| Notify live servers | `universe-messaging-service:publish` |
| Read analytics | `universe.analytics:read` |

Rules: restrict the key to the one experience; leave IP allow-lists empty unless the runner has a fixed IP (a list breaks keys used from Roblox servers); set an expiry only with a rotation owner; a key unused for 60 days expires; keep it in a `chmod 600` env file and read it inside the command. Rate limits apply per key owner across all keys.

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

Before blocking, state exactly what is missing, which scope or account step fixes it, and keep working on the parts that do not depend on it.

## 4. Release runbook

1. Run `roblox-publish-checklist` and the hard gates in `roblox-launch-benchmarks`; record the rollback version.
2. Build `game.rbxl`, run tests, publish to a **private test place** with `versionType=Saved` or `Published`, and let the user test the exact build.
3. User confirms the manual items (questionnaire, icon, thumbnails, audience) are done in Creator Hub.
4. Publish to the live place; print "published version N" and store it.
5. Restart older servers (`:restartServers`), optionally after a `publishMessage` notice.
6. Verify in a live client: assets load, a real purchase grants, save and rejoin work.
7. Watch errors and funnel for the first day; roll back by re-publishing the stored previous build if a blocker appears.

## 5. Handoff message to the user (template)

"Done by me: <build, tests, publish version N, restart, passes>. Needs you: <list from section 1 marked User>. Missing permission: <scope/role/step> because <call and error>. After you do it I will <next automated step>."
