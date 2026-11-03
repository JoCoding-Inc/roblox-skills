---
name: roblox-pitfalls
description: "Use when publishing a place through Open Cloud, loading Creator Store models at runtime, testing in Studio through MCP, generating meshes with Roblox Cube (Studio MCP generate_mesh), or when something works in Lune tests but not in the engine. Field notes of failures hit while shipping Roblox games with an AI agent."
when_to_use: "Also on a 409 'Server is busy' publish error, models that load live but not in Studio, Creator Store downloads returning 403, empty Output, characters that never get set up, broken non-Latin text on signs, teleports that cannot be tested, a SpotLight that stops reaching, a Cube mesh that comes out the wrong size or as a blob, generate_mesh 'Too Many Requests', MCP screenshots that time out, or a texture that stays grey on a MeshPart, a cutscene camera that snaps back in MCP screenshots, a tooltip drawn under another frame, characters that fall over, or players standing on top of enemies."
last_reviewed: 2026-11-03
sources:
  - original (field notes from three test games, 2026-10)
  - https://create.roblox.com/docs/parts/model-generation
  - https://create.roblox.com/docs/reference/engine/classes/GenerationService
  - https://create.roblox.com/docs/cloud/open-cloud
  - https://create.roblox.com/docs/reference/engine/classes/AssetService
  - https://create.roblox.com/docs/reference/engine/classes/TeleportService
---

# Roblox pitfalls (field notes)

Each entry gives the symptom, the cause and the fix. Pair with `roblox-studio-ai-tools` for the current built-in Studio MCP tool list and `roblox-release-automation` for Open Cloud publishing.

## 1. Publishing

| Symptom | Cause | Fix |
|---|---|---|
| Open Cloud place publish returns 409 "Server is busy" | Field observation (not in the official docs): the place was open in Studio, which holds a collaborative edit session on it. The docs define 409 only as a conflict such as a place that is not part of the universe | First check that the place id belongs to the universe id. Otherwise close that Studio window, wait a few minutes, and retry. Keep a separate **dev place** for Studio work and never open the live place in Studio |
| Publish returns "Invalid Content stream" | Seen when we sent an XML `.rbxlx`. The docs say `.rbxlx` (`Content-Type: application/xml`) is supported, so also check the Content-Type and that the file is not truncated | Upload binary `.rbxl` with `Content-Type: application/octet-stream` (`rojo build -o x.rbxl`, or convert with Lune `@lune/roblox`) |
| The id in a Creator Hub URL publishes to the wrong thing | `/experiences/<id>` shows the **universe** id, not the place id | Resolve the root place from `cloud/v2/universes/<id>` first |

- Publish API facts: `POST /universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved|Published` (Saved stores a version without releasing it; use it for staging). Scope `universe-places:write`. Body limit 10 MiB, 30 requests per minute. The API does **not** update EditableImage, EditableMesh, PartOperation, SurfaceAppearance or BaseWrap instances: publish places that rely on them from Studio.
- API keys: restrict by experience and set minimal scopes. IP allow-lists break keys used from Roblox servers; add an expiry only if you have a rotation process; a key unused for 60 days expires on its own. Keep keys in a secrets store or env file.
- Print one line such as "published version N" from the publish script, so the agent can quote it.
- Publish every playtest build to a private test place, and tell the tester 2-3 things to check plus the known issues.
- An agent never pastes API keys in chat. Keep them in a chmod 600 env file and read them inside the command only.

## 2. Loading Creator Store models

- `InsertService:LoadAsset` refuses models made by other creators. `AssetService:LoadAssetAsync` loads them in live servers only after the place enables **Allow Loading Third Party Assets**.
- In Studio, `LoadAssetAsync` fails. Pre-insert the models into a Studio-only cache folder in the dev place (insert with Studio MCP `insert_asset`), and let runtime code prefer the cache when it exists.
- Always keep a code-built primitive in the prop's place. Make it invisible only after the model is in, so a failed load leaves a usable box (collision and view blocking stay correct).
- Sanitize every model: delete scripts, cap the part count, set decor to `CanCollide`, `CanTouch` and `CanQuery` false, and fit it to the primitive's box.
- Downloading with the Open Cloud asset-delivery API (field notes; the scope name `legacy-asset:manage` is not in the official scope list, so check the current docs): many **recent** Creator Store assets return 403 "User is not authorized" until the account "Gets" them into its inventory. Older ones download fine. Probe ids in a batch and filter.
- Search: the documented endpoint is Open Cloud `toolbox-service/v2/assets:search` (beta, needs an API key with creator-store scope). The unauthenticated `toolbox-service/v1/marketplace/10?keyword=...&num=30` (10 = Models) and `/toolbox-service/v1/items/details?assetIds=` worked in our runs but are undocumented and may change. Studio MCP `search_asset` is the supported way inside Studio.

## 3. Testing in Studio through MCP

- Studio's Output can show no server logs at all, not even `warn()`. Read logs through MCP `get_console_output`, or run one-line `execute_luau` probes that return facts (positions, attributes, states) instead of printing.
- Several Studio windows may be open. Call `list_roblox_studios` first and pass your dev place's `studio_id` on every call (the built-in server requires it). Never act on another project's window.
- Old tool names from the archived Rust server (`run_code`, `insert_model`, `run_script_in_play_mode`, `get_studio_mode`) do not exist in the built-in server. Use `execute_luau`, `search_asset` + `insert_asset`, `start_stop_play`, `get_studio_state`. For scenario testing the docs list a `subagent` type `playtest`, but the Studio build of 2026-11-02 exposed only `explore`, `screen_capture` and `unit_test`: `playtest` needs the Playtest Agent beta (File > Beta Features). Without it, drive the playtest with `start_stop_play` and the input tools.
- **Wrong window.** Every Studio window shares one MCP connection, and calls queue through it. A call without the right `studio_id`, or after the user switched windows, lands in another place (community reports, C). Re-check `list_roblox_studios` when a result names an unexpected place.
- `multi_edit` matches the old text exactly, whitespace and tabs included; a failed match means re-read with `script_read` and copy the text, not retype it. `script_grep` and `script_search` can return stale results right after an edit (community reports, C): confirm with `script_read`.
- Duplicate tools: the official Roblox Studio plugin and a manual `Roblox_Studio` entry both connect, so every tool appears twice. Keep one (`roblox-studio-ai-tools` section 1).
- Lune unit tests with mocks miss engine ordering bugs. Example: `CharacterAdded` can fire **before** the character is parented to `workspace`, so code that needs `char.Parent` silently skips. Back pure-logic tests with in-engine **bot scenarios**:
  - server-side bots run a scripted case (walk into the guard's view, freeze, carry an object together);
  - the scenario returns PASS or FAIL lines that the agent reads through MCP.
- A Studio attribute override per feature (skip intro, force a guard type, force a server mode) keeps scenarios deterministic. Every override is a no-op unless it is set.
- A scenario that fails on the base commit too is pre-existing. Prove that in a throwaway worktree before you blame your change.
- **Screenshots** (`screen_capture`) time out when the Studio window sits on another macOS Space, and Studio throttles hard (15 fps and below) when it is not the frontmost app. Bring only your dev-place window forward before shots and FPS checks; FPS read from a background Studio is not a measurement.
- Some properties are out of reach of `execute_luau` (RobloxScript capability), for example reading `Lighting.Technology` or authoring `MaterialVariant` maps in our runs. Put those in the Rojo project (`*.model.json` under `MaterialService`) so `rojo build` ships them, and set them by hand in the dev place.
- `execute_luau` resets `Camera.CameraType` from Scriptable to Custom when the call returns (Output: "The execute_luau changed camera type"). A cutscene then shows the default camera in every screenshot. Re-arm it inside the call with `task.delay(0.2, function() camera.CameraType = Enum.CameraType.Scriptable end)` and capture right after.
- A `require` from `execute_luau` gets a fresh copy of a ModuleScript, so module state (sessions, caches) is empty there. Drive the running game through its own remotes or debug actions instead of calling module functions.
- `user_mouse_input` moves do not fire `MouseEnter`, so hover tooltips never open. Toggle the tooltip's `Visible` in a probe to check its placement.
- Lune mock tests that run the whole client are slow, about 3-4 s of real time per simulated second; a long `Sched.advance(60)` looks hung, and parallel runs make it worse. Print a timestamp per section before calling it a hang. macOS has no `timeout` command.
- **Close what you opened.** Each Studio window holds about 1 GB. When a task ends, close the windows and play sessions the agent opened, by PID, never by pattern, and never another project's window.

## 4. Engine limits that bite

- **Teleports cannot run in Studio.** Route every teleport through one module that logs and simulates in Studio, and verify the real hop on a published private build.
- One place can serve as both lobby and match. Detect a reserved server with `game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0`; a VIP server has an owner id. Treat teleport data as a client-visible hint and trust only who actually arrives.
- **DataStores:** use a separate store name in Studio (for example `PlayerData_Studio`) so Studio never writes live data.
- **SpotLight / PointLight `Range` caps at 60 studs** (field observation; the docs do not state a cap). A "longer" flashlight past that needs a second light or a fake glow, not a bigger number.
- **Non-Latin text on SurfaceGui signs:** some fonts render Hangul broken in 3D (seen with GothamBold; the docs say Gotham fonts are removed and map to Montserrat, so the cause is probably Montserrat's glyph coverage). Use English sign text, or test a font that has the script before relying on it. Screen GUIs were fine.
- **Image ids:** a Decal id renders nothing in `ImageLabel.Image`; use the image (texture) id. Probe it with `AssetService:CreateEditableImageAsync(Content.fromAssetId(id))`. "No permission" means it will be blank in your place.
- **Mesh colour textures: upload at 1024.** A 2048 colour map (3.5 MB, approved) showed on an ImageLabel but stayed grey as `MeshPart.TextureID` in the client; the same art at 1024 rendered. 2048 roughness/metal maps were fine. `ContentProvider:PreloadAsync` reports Failure even for working ids, so test a texture on a MeshPart in a Play client instead.
- **Anchored roots ignore `Humanoid:MoveTo`.** An NPC posed by anchoring its root (sitting, cutscene) silently stays put when an AI later tells it to walk. Release the pose (unanchor, stop the clip) in one helper that every move path calls.
- **GUI draw order with `ZIndexBehavior.Sibling`:** a child's ZIndex only sorts among its siblings. A tooltip at ZIndex 60 inside a button still draws under a menu frame that is a later sibling of that button. Raise the button's own ZIndex (or move the tooltip to a top-level layer).
- **Big characters tip over.** Scaled or custom humanoids sometimes enter `FallingDown`/`Ragdoll` and lie on the floor. Call `Humanoid:SetStateEnabled` false for both on the client that owns the character (each client owns its own).
- **Players climb onto NPCs.** Walking into a collidable enemy model lets the character step up onto it. Put enemy parts in their own collision group and `workspace:RegisterCollisionGroup` + `workspace:CollisionGroupSetCollidable(enemies, characters, false)` (`PhysicsService` is deprecated and only forwards); hit detection by distance or query still works.
- **Terrain heights snap.** `FillCylinder`/`FillBall` plus an Air carve leave the surface at `4*floor(y/4) + 2`, and Air fills clear every cell they touch. For an exact floor height, write the cell layer with `WriteVoxels` occupancy, then check it with a raycast through MCP. Lune voxel mocks usually miss this.

## 5. Generating meshes with Roblox Cube (Studio MCP)

Related generators: `generate_procedural_model` builds parameterised objects from primitive parts (50 per rolling 24 h; poll with `wait_job_finished`), better than a mesh for shelves, fences, stairs or anything that must scale; `generate_material` returns a `MaterialVariant` for restyling parts. Roblox's own generators aim at All Ages content, so weapon and horror prompts may be softened or fail.

Studio MCP `generate_mesh` (Roblox Cube, `GenerationService`) makes a textured mesh from text. In our runs the result was published to the generating account's inventory with an asset id; the official docs describe the in-experience API (`GenerateModelAsync` returns a Model) and do not document that inventory step, so verify it on your build.

| What | Rule |
|---|---|
| Prompt | One object, shape first: "long low waist-high chest freezer with glass sliding lids". A list of sub-items ("counter with belt, register, card reader") gives only one of them. No scene words ("furniture store display") |
| Size | A hint only. The long axis often comes out along Z: rotate the long side to your prop axis, `ScaleTo` the long side, put the base on the floor. Uniform scale keeps the AI proportions; set `MeshPart.Size` non-uniformly when the footprint must match |
| Triangles | Default 10,000. Lower budgets turn props blocky; use 8,000-10,000 for anything seen up close |
| Parts | `segmentation` "none" for static props; named parts (max 8) only for pieces that must move, such as wardrobe doors |
| Variants | Generate 2 per object and pick one. Vague shapes ("island", "bunker", "box" freezer) come back as blobs |
| Rate | 1-2 jobs at a time. Eight at once failed on publish with "Too Many Requests" |
| Mode | Runs in Edit mode only, not during a playtest |
| Errors | "Failed to fetch image" and MeshGen outages are transient: retry later with a shorter prompt |
| Moderation | Horror words ("sharp teeth", "wet skin") fail. Describe shapes in mild words |

- Good for static props, furniture, vehicles and simple weapons (pistol, bat, pipe, forklift, lantern). It missed a crowbar twice, so check every weapon against a reference.
- Not for creatures: the result is one static mesh with no rig, and `auto_setup_avatar` only rigs R15 humanoids. Quadrupeds, spiders and other monsters need a Blender rig (`roblox-blender-export`).
- `generate_avatar` and `auto_setup_avatar` appeared in our MCP tool list but are not in the current official tool table (`studio/mcp.md`): list the server's tools before relying on them. `generate_avatar` returned a rigged R15 with a realistic human look, not the blocky Roblox style. The MCP call can time out on the client while the model still lands in `workspace` minutes later, so check the tree before you retry.
- Cube assets live in the generating account's inventory. Before publishing, check that the live place can load every one of them (a group-owned place may not).

## Studio-tested API notes (2026-11-01, Studio 0.745, scratch place via Studio MCP)

- `TextChatService.PlatformIntegratedChat` cannot be read from `execute_luau` (property read errors): set it in the Properties panel and playtest by hand.
- `BasePart:BindToCollisionSummaries` works from a Server `execute_luau` call during play: a part dropped from 30 studs reported the landing at relative speed about 108 with Normal (0,1,0) toward the part above the baseplate, then rebound contacts a few frames later. Use the dot product of `RelativeVelocity` and `Normal` for impact strength.
- `AssetService:PromptCreateAssetAsync` no longer exists; use `PromptCreatePlatformContentAsync`. Old tutorials and cached code that call it fail with a nil method.
- A beta API can exist as a class but not as a property: `UIShadow` and `AudioTextToSpeech` instantiate, `Camera.ProjectionType` (orthographic beta) does not until the Studio beta is on. Probe with `pcall(function() return obj.Prop end)` before scripting against a beta.
