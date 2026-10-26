---
name: roblox-pitfalls
description: "Use when publishing a place through Open Cloud, loading Creator Store models at runtime, testing in Studio through MCP, or when something works in Lune tests but not in the engine. Field notes of failures hit while shipping Roblox games with an AI agent."
when_to_use: "Also on a 409 'Server is busy' publish error, models that load live but not in Studio, Creator Store downloads returning 403, empty Output, characters that never get set up, broken non-Latin text on signs, teleports that cannot be tested, or a SpotLight that stops reaching."
last_reviewed: 2026-10-26
sources:
  - original (field notes from two shipped test games, 2026-10)
  - https://create.roblox.com/docs/cloud/open-cloud
  - https://create.roblox.com/docs/reference/engine/classes/AssetService
  - https://create.roblox.com/docs/reference/engine/classes/TeleportService
---

# Roblox pitfalls (field notes)

Each entry gives the symptom, the cause and the fix. Pair with `roblox-studio-mcp`, `roblox-cloud`, `roblox-tooling` and `roblox-data` from roblox-brain.

## 1. Publishing

| Symptom | Cause | Fix |
|---|---|---|
| Open Cloud place publish returns 409 "Server is busy" | The place is open in Studio, which holds a collaborative edit session on it | Close that Studio window, wait a few minutes, and retry. Keep a separate **dev place** for Studio work and never open the live place in Studio |
| Publish returns "Invalid Content stream" | You uploaded an XML `.rbxlx` | Upload binary `.rbxl` (`rojo build -o x.rbxl`, or convert with Lune `@lune/roblox`) |
| The id in a Creator Hub URL publishes to the wrong thing | `/experiences/<id>` shows the **universe** id, not the place id | Resolve the root place from `cloud/v2/universes/<id>` first |

- Print one line such as "published version N" from the publish script, so the agent can quote it.
- Publish every playtest build to a private test place, and tell the tester 2-3 things to check plus the known issues.
- An agent never pastes API keys in chat. Keep them in a chmod 600 env file and read them inside the command only.

## 2. Loading Creator Store models

- `InsertService:LoadAsset` refuses models made by other creators. `AssetService:LoadAssetAsync` loads them in live servers only after the place enables **Allow Loading Third Party Assets**.
- In Studio, `LoadAssetAsync` fails. Pre-insert the models into a Studio-only cache folder in the dev place (insert with Studio MCP `insert_asset`), and let runtime code prefer the cache when it exists.
- Always keep a code-built primitive in the prop's place. Make it invisible only after the model is in, so a failed load leaves a usable box (collision and view blocking stay correct).
- Sanitize every model: delete scripts, cap the part count, set decor to `CanCollide`, `CanTouch` and `CanQuery` false, and fit it to the primitive's box.
- Downloading with the Open Cloud asset-delivery API (`legacy-asset:manage` scope): many **recent** Creator Store assets return 403 "User is not authorized" until the account "Gets" them into its inventory. Older ones download fine. Probe ids in a batch and filter.
- Search without auth: `apis.roblox.com/toolbox-service/v1/marketplace/10?keyword=...&num=30` (10 = Models), with details from `/toolbox-service/v1/items/details?assetIds=`.

## 3. Testing in Studio through MCP

- Studio's Output can show no server logs at all, not even `warn()`. Read logs through MCP `get_console_output`, or run one-line `execute_luau` probes that return facts (positions, attributes, states) instead of printing.
- Several Studio windows may be open. List them first and target only your dev place. Never act on another project's window.
- Lune unit tests with mocks miss engine ordering bugs. Example: `CharacterAdded` can fire **before** the character is parented to `workspace`, so code that needs `char.Parent` silently skips. Back pure-logic tests with in-engine **bot scenarios**:
  - server-side bots run a scripted case (walk into the guard's view, freeze, carry an object together);
  - the scenario returns PASS or FAIL lines that the agent reads through MCP.
- A Studio attribute override per feature (skip intro, force a guard type, force a server mode) keeps scenarios deterministic. Every override is a no-op unless it is set.
- A scenario that fails on the base commit too is pre-existing. Prove that in a throwaway worktree before you blame your change.

## 4. Engine limits that bite

- **Teleports cannot run in Studio.** Route every teleport through one module that logs and simulates in Studio, and verify the real hop on a published private build.
- One place can serve as both lobby and match. Detect a reserved server with `game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0`; a VIP server has an owner id. Treat teleport data as a client-visible hint and trust only who actually arrives.
- **DataStores:** use a separate store name in Studio (for example `PlayerData_Studio`) so Studio never writes live data.
- **SpotLight / PointLight `Range` caps at 60 studs.** A "longer" flashlight past that needs a second light or a fake glow, not a bigger number.
- **Non-Latin text on SurfaceGui signs:** some fonts (seen with GothamBold) render Hangul broken in 3D. Use English sign text, or test a font that has the script before relying on it. Screen GUIs were fine.
- **Image ids:** a Decal id renders nothing in `ImageLabel.Image`; use the image (texture) id. Probe it with `AssetService:CreateEditableImageAsync(Content.fromAssetId(id))`. "No permission" means it will be blank in your place.
