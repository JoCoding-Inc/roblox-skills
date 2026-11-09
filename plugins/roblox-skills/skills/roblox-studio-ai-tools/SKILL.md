---
name: roblox-studio-ai-tools
description: "Use when connecting Claude Code to Roblox Studio (official Roblox Studio plugin or the built-in Studio MCP server), choosing among its tools or built-in rbx-* skills, using Studio Assistant (Planning Mode, /generate_mesh, /generate_procedural_model, skills, bring-your-own-key), generating materials/meshes/procedural models, or running Luau headlessly through Open Cloud."
when_to_use: "Also on 'Roblox_Studio MCP not connected', a tool name that no longer exists (run_code, insert_model, run_script_in_play_mode), a migration from the old studio-rust-mcp-server, multiple Studio windows, an MCP client that should call Open Cloud (open_cloud_invoke, MCP Permissions, import from Blender), MCP key or mouse input that misses its target, writing Assistant skills, or CI that needs to run Luau against a place."
last_reviewed: 2026-11-09
sources:
  - Studio MCP built-in skills rbx-permissions and rbx-open-cloud-usage, and the open_cloud_invoke tool description (Studio build of 2026-11-05)
  - https://devforum.roblox.com/t/4975849 (Studio MCP Server Updates: Open Cloud access and asset import, posted 2026-11-04, read 2026-11-05)
  - https://github.com/Roblox/roblox-studio-agent-plugin (README, read 2026-11-03)
  - Studio MCP list_skills output (Studio build of 2026-11-03)
  - Studio MCP tool schemas for user_keyboard_input, user_mouse_input, screen_capture and start_stop_play (read 2026-11-03)
  - https://create.roblox.com/docs/studio/mcp (GitHub source Roblox/creator-docs, read 2026-11-01)
  - https://create.roblox.com/docs/scripting/sync
  - https://create.roblox.com/docs/studio/device-simulator (read 2026-11-03)
  - https://create.roblox.com/docs/assistant/guide
  - https://create.roblox.com/docs/assistant/mcp
  - https://create.roblox.com/docs/assistant/skills
  - https://create.roblox.com/docs/studio/cli
  - https://create.roblox.com/docs/generative-AI
  - https://create.roblox.com/docs/cloud/reference/features/luau-execution
  - https://github.com/Roblox/studio-rust-mcp-server (archived)
  - original field notes (2026-10 to 2026-11)
---

# Studio MCP, Assistant and AI generation

Facts here come from the official creator-docs repository (docs state as of 2026-10-29). Tool names change; when a call fails with "unknown tool", list the tools the server actually exposes and trust that list over this file.

## 1. Connect Claude Code to Studio

The Studio MCP server is **built into Roblox Studio** (stdio, local process). The older Rust server (`Roblox/studio-rust-mcp-server`, tools `run_code`, `insert_model`, `run_script_in_play_mode`, `get_studio_mode`) is archived on GitHub (checked 2026-11-03). Remove its `Roblox_Studio` entry before adding the built-in one so the names do not clash.

**Easiest path: the official plugin** (`Roblox/roblox-studio-agent-plugin`, README read 2026-11-03). In Claude Code run `/plugin`, search **Roblox Studio**, install, then ask "Get me set up with Roblox Studio": it checks what is missing, installs and opens Studio if needed, and says where the one switch is. "continue Roblox setup" resumes in a new chat. Verify with `/mcp`: it lists `plugin:roblox-studio:macos` and `plugin:roblox-studio:windows`; only the one for your OS connects, so the other failing is expected. Do not also keep a manual `Roblox_Studio` entry, or every tool appears twice.

Manual path:

1. Update Studio to the latest version.
2. Studio: **Assistant** > **...** > **Settings** > **MCP Servers** (**Manage MCP Servers** in older versions) > turn on **Enable Studio as MCP server**.
3. Connect the client, either:
   - Quick connect: **Assistant Settings** > **MCP Servers** > **Quick connect**, toggle Claude Code (also lists Claude Desktop, Cursor, Codex CLI, Gemini CLI, Antigravity, VS Code). Install the client first and restart Studio if it is missing.
   - CLI command (macOS): `claude mcp add Roblox_Studio -s user -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
   - CLI command (Windows): `claude mcp add Roblox_Studio -s user -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"`
   - JSON: macOS `{"mcpServers":{"Roblox_Studio":{"command":"/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"}}}`; Windows `{"mcpServers":{"Roblox_Studio":{"command":"cmd.exe","args":["/c","%LOCALAPPDATA%\\Roblox\\mcp.bat"]}}}`
4. Restart Claude Code. Verify: `claude mcp list` shows Connected, and Studio's Manage MCP Servers panel shows a green client count. In the session, ask for the tool by name ("call `list_roblox_studios`, no shell commands"): a vague "list my Studio windows" can look like a pass with nothing connected. A new project folder needs the add command again (project-scoped config).
5. Troubleshoot: restart both apps, check the binary path exists, check JSON commas.

Security: any connected client can read and modify the open places. Connect only clients you trust, and keep execute tools on prompt in Claude Code's permissions.

### 1a. Open Cloud through Studio and MCP Permissions (2026-11-04)

Announced on the DevForum on 2026-11-04. Details below come from Roblox's own built-in skills `rbx-permissions` and `rbx-open-cloud-usage` and the `open_cloud_invoke` tool description (Studio build of 2026-11-05); the docs page `studio/mcp-open-cloud` covers it since (read 2026-11-09). Check that the server lists `open_cloud_invoke` before relying on it, and load those two skills with `skill` before the first call. No MCP Permissions tab in Assistant > ... > Settings means Studio is older than this update: ask the user to update Roblox Studio and restart it.

- `open_cloud_invoke(method, endpoint, body?, scopes?, files?)` calls Open Cloud from an external MCP client (not the Assistant inside Studio). For each call Studio fetches a short-lived OAuth token limited to the scopes the user switched on; never pass API keys or auth headers. `endpoint` is the path under `https://apis.roblox.com`. Find endpoints from `https://create.roblox.com/docs/cloud/llms.txt` with `http_get` (each page lists `**Scopes:**`).
- **Where:** Assistant > ... > Settings > MCP Permissions tab, or click MCP in Studio's bottom-right corner. Saved per user and per game; collaborators set their own; only the user can change them. A local `.rbxl` shows "Save to Roblox to manage MCP permissions": a scratch place opened from a file has none, so test Open Cloud and data stores in a place saved to Roblox (File > Save to Roblox makes a private game; Publish is not needed). Tested 2026-11-05 on Studio 0.746 with a local `.rbxl` (no MCP permissions possible): `execute_luau` can build and edit parts, read and write `Script.Source` and destroy instances, but cannot parent a Script, LocalScript or ModuleScript into the place ("cannot reparent ... additional value for the Capabilities property: Network"), cannot `require` a ModuleScript, cannot read `HttpService.HttpEnabled` or call `GetAsync` ("lacking capability Network"), and data stores answer "You must publish this place to the web". `multi_edit` still creates scripts, and copies whose scripts are removed before parenting go in fine. The Access level dropdown offers presets and Custom (preset names not checked).
- **Sections and scopes** (the dialog shows each scope as a "capability"):

  | Section | Scopes | Unlocks |
  |---|---|---|
  | Look at your game | `universe:read`, `universe.place:read`, `universe.analytics:read`, `universe.place.instance:read` | Settings, configs, version history, analytics |
  | Edit your game | `universe:write`, `universe.place:write`, `universe.place.instance:write` | Settings, configs, experiments, **publishing and server restarts** |
  | Players & social (the skill calls it Users, groups & events) | `user.*`, `group:*`, `group-forum:read`, `universe.event:*`, `creator-store-save:*` | Profiles, inventory, notifications, groups, game events |
  | Save & load data | `universe-datastores.*`, `universe.ordered-data-store.*`, `memory-store.*` | `DataStoreService` and `MemoryStoreService` from `execute_luau` (never through Open Cloud) |
  | Connect to the internet | the `Network` script capability plus an HTTP domain allowlist; `universe-messaging-service:publish` | HTTP from Luau; cross-server messages |
  | Publish & manage assets | `asset:*`, `asset-permissions:write`, `creator-store-product:*`, `universe-places:write`, `universe.thumbnail:*` | Uploads, sharing, Creator Store, place publishing, homepage thumbnails |
  | Money & monetization | `developer-product:*`, `game-pass:*`, `ad.campaign:*`, `ad.billing:read`, `universe.subscription-product.subscription:read` | Products and passes with prices, ads |
  | Player consequences | `universe.user-restriction:*` | Bans |
  | Security & credentials | `universe.secret:*`, `universe.place.luau-execution-session:*` | Secrets, cloud Luau |

- **Never grantable over MCP:** badge scopes, `legacy-*` scopes, `universe-datastores.control:*`, `universe-datastores.objects:create`, analytics alerts. Use an API key (`roblox-release-automation` section 2) or Creator Dashboard.
- **Probe before acting:** `open_cloud_invoke(method: "GET", endpoint: "/cloud/v2/universes/<GameId>", scopes: [...])`. A missing scope fails at the token step before anything is sent, so it is safe for write scopes; it stops at the first missing one, and a misspelled scope fails the same way. Upload folders, the HTTP allowlist and the Studio API access setting cannot be probed: ask up front.
- **Ask** in one message for the exact section and toggle, what it unlocks and why. Sensitive toggles get their own clear yes: money (`developer-product:write`, `game-pass:write`, `ad.campaign:write`, `ad.billing:read`), players (`universe.user-restriction:write`, `user.user-notification:write`), security (`universe.secret:write`, `universe.place.luau-execution-session:write`), publishing and sharing (`universe:write`, `universe-places:write`, `asset-permissions:write`, `creator-store-product:write`).
- **Errors:**

  | Result | Meaning | Do |
  |---|---|---|
  | "Scope '<scope>' has not been granted" | Toggle off or name misspelled | Ask for that toggle |
  | 403 or 401 from the endpoint, probe passes | The endpoint does not accept the MCP token | Do not ask again; use a Studio tool or Creator Dashboard (or an API key if the user has one for this). 401: retry once first, each call gets a fresh token |
  | Business reason (for example no ad account) | The permission worked | Explain what is missing |
  | Data store `502 ... Access forbidden` | Save & load data scope off (reads `universe-datastores.objects:read`, writes `:update`) | Ask for it |
  | Data store 403 "API access is not enabled" | Game setting, not MCP | Game Settings > Security > Enable Studio Access to API Services |
  | MemoryStore `InternalError` | Usually `memory-store.*` off | Probe it |
  | "HttpService request denied: domain ... is not in the Assistant HTTP allowlist" | Domain not allowed | User adds it under Connect to the internet |
  | "lacking capability <capability>" | Only `Network` can be granted | Say so |
  | "MessagingService can only be executed by game server" | No Studio route | Tell the user |

- **Uploads:** `files` takes up to 5 asset files of 20 MB each (bmp, fbx, glb, gltf, jpg, png, rbxm, rbxmx, tga, mp3, ogg, wav, flac, mov, mp4) from a folder the user approved; never copy or move a file to get around that. Uploads are permanent (Open Cloud cannot delete or archive models or images; Creator Dashboard only), go to the game's owner (the group for a group game) and through moderation. Ask before uploading; asset uploads return an operation to poll.
- **Never work around a block:** no playtest or game code to run a blocked operation, no other endpoint, domain or context for the same effect, no API key to get past a toggle the user turned off. Using a Studio tool after an endpoint refused a granted scope is fine.
- Built-in skills from the same update: `rbx-open-cloud-usage`, `rbx-permissions`, `rbx-import-asset` (GLB or FBX from Blender or another tool, then fixes scale, rotation, textures and anchoring; `roblox-blender-export` section 5).
- Same update: a playtest started from an MCP client no longer brings Studio to the front; each place gets a new Studio ID when you switch places; Studio shows the MCP status in its bottom-right corner.

## 2. Tool map (built-in server)

Every call takes a `studio_id`. Call `list_roblox_studios` first (name, instance id, place id) and pass the id of your dev place, especially with several windows or agents. Window rules: `roblox-game-pipeline` section 0, rule 8.

| Group | Tools | Notes |
|---|---|---|
| Scripts | `script_read`, `multi_edit`, `script_search`, `script_grep` | Dot-notation paths; `multi_edit` creates a script if the path is new and needs `datamodel_type` Edit. `script_search` returns 10 fuzzy matches, `script_grep` 50 |
| Generate | `generate_mesh`, `generate_material`, `generate_procedural_model`, `generate_texture`, `segment_mesh`, `generate_scene`, `generate_animation`, `wait_job_finished` | See section 4. `segment_mesh` splits a MeshPart into named parts (up to 5 per run). `wait_job_finished` takes `jobId` (and `timeout`, default 600 s) |
| Avatars | `generate_avatar`, `auto_setup_avatar` | Prompt-to-avatar is a Studio beta (section "Recent additions"); check the tool's own description before use |
| Skills | `list_skills`, `skill`, `create_skill`, `edit_skill` | Call `list_skills` at the start of a task and load the matching `rbx-*` skill with `skill` |
| Assets | `search_asset`, `insert_asset`, `upload_image`, `store_image` | `search_asset` covers Creator Store and your inventory (user, group, universe) with type, price, tag filters. `store_image` turns a local file into a URI for reference images. If every asset fails with "User is not authorized" or "Authentication required", Studio lost its login (`roblox-pitfalls` section 3) |
| Explore | `search_game_tree`, `inspect_instance`, `subagent` | `subagent` types: `explore` (investigate game state) and `playtest` (run gameplay scenarios and verify outcomes; the Playtest Agent is a beta under File > Beta Features and has a daily cap, and can report false passes). The `subagent` tool in the Studio build of 2026-11-02 listed only `explore`, `screen_capture` and `unit_test`, so `playtest` needs the beta on. A secondhand report says it could not jump in one run; recheck any climb it fails |
| Run | `execute_luau` | `datamodel_type` Edit, Client or Server (Client and Server exist only during Play). Without the `Network` capability (Connect to the internet; never on a local `.rbxl`) it cannot parent scripts, `require` or use HTTP: create scripts with `multi_edit` (section 1a). It runs with plugin capability (field observation), so a write that works here can fail in a real script (`roblox-pitfalls` section 3) |
| Playtest | `get_studio_state`, `start_stop_play`, `get_console_output`, `screen_capture` | `start_stop_play` takes `is_start` (bool). `screen_capture` needs a `capture_id`; `camera_position` and `look_at_position` are 3-number arrays, given together. The tool calls itself an edit-time capture, and in Play the game's camera script overrides them (field observation; `roblox-pitfalls` section 3). `get_studio_state` reports the play state and the datamodel types available now |
| Input | `character_navigation`, `user_keyboard_input`, `user_mouse_input` | Sequences of actions; can target UI instances. Keyboard, mouse and navigation take `datamodel_type` `Client` only, so Play must be running. Keyboard example: `{action: 'keyPress', key_code: 'E'}` (`key_code`, not `key`). Mouse example: `{action: 'moveTo', instance_path: 'LocalPlayer.PlayerGui.Frame'}` then `{action: 'mouseButtonClick', mouse_button: 'left'}`; `instance_path` wins over `x` and `y`, and later steps reuse the last position. Other actions: the tool schema. Misses and wrong clicks: `roblox-pitfalls` section 3 |
| Docs | `http_get`, `skill` | `http_get` reads allowed Roblox docs URLs (Engine API, Creator docs, Cloud API). Use it before guessing an API |
| Sessions | `list_roblox_studios` | |
| Open Cloud | `open_cloud_invoke` | Any Open Cloud API with Studio's token, within MCP Permissions (section 1a) |

Use them in this order for a change: `get_studio_state` > `search_game_tree` / `inspect_instance` > `script_read` > `multi_edit` > `execute_luau` probe > `start_stop_play` > `get_console_output` > `screen_capture`; for a change that Play must see, follow the Edit and Play order below. Pitfalls with these tools (camera type reset, fresh module copies, hover not firing, fast moments, captures from a background window) are in `roblox-pitfalls` section 3.

Edit and Play do not overlap. Order: stop Play > apply in the Edit context (`multi_edit`, `execute_luau` with `datamodel_type` Edit) > `start_stop_play` with `is_start` true > check `get_studio_state` > read back in Client and Server. Send these one call at a time: overlapping calls fail with "Edit datamodel is not available in Play mode" or "Start play hasn't finished yet" (field observation). Make a bulk apply return the number of entries it wrote and check that number before you start Play.

When the docs and a tool disagree, ask `http_get` for the page, or the Studio `skill` tool for the topic, instead of relying on memory. Keep an unconfirmed engine claim marked unverified until a docs page or a probe confirms it (`roblox-dev-workflow` section 0).

## 3. Assistant in Studio (what it adds)

Use Assistant for things that live best inside Studio; use Claude Code for repo-wide code work. Both can run at once on different tasks.

- **Planning Mode:** pick **Plan** in the input dropdown or type `/plan`. It writes an editable Markdown plan, stored in the cloud per experience and creator, private to you. Execution starts only when you click **Build**; edits to the plan sync back to Assistant.
- **Slash commands:** `/plan`, `/generate_mesh <text or image>` (not both), `/generate_procedural_model <text or image>` (Assistant limit: 50 per rolling 24 hours), `/generate_material`, `/generate_texture`, `/segment_mesh` (select the MeshPart itself; up to 5 part names per run), `/insert_asset <id>`. A selected Part is used as a bounding box. Optional max triangle count (default 10,000).
- **Prompting Assistant:** use exact instance names; it biases to edit-time, so ask for a script when you want runtime behaviour; name the object first and leave out background, camera, lighting and quality words; for procedural models state which properties must be editable and how it scales; reference images should be .png at a 3/4 angle and not low-poly. Official loop: Plan > Build and Playtest > Refine and Polish, playtesting after every round.
- **Screen capture subagent** and chat history exist; plans and chats are not visible to collaborators.
- **Skills:** a skill is one Markdown file with frontmatter `name` (lowercase, no `rbx-` prefix), `description`, `enabled`, loaded automatically when a request matches the description or by typing `/` in the composer. Skills belong to the Roblox account, so they apply to every place. Built-in Roblox skills (10 in `list_skills`, Studio build of 2026-11-03): `rbx-configs-experimentation` (ConfigService live values and A/B experiments), `rbx-create-skill`, `rbx-debug` (breakpoints, call stacks), `rbx-device-simulator-lua` (device presets and UI screenshots), `rbx-docs-search`, `rbx-instrument-analytics` (AnalyticsService economy, funnel and custom events), `rbx-network-simulator` (latency, jitter, loss presets via `settings().Network`), `rbx-perf-profiling` (MicroProfiler analysis), `rbx-scene-analysis` (rendering cost, memory, leaks, asset inventory), `rbx-unit-test` (module unit tests). Duplicate one to customise it; the original is then disabled automatically.
- **Bring your own key:** **Assistant > ... > Manage API Keys**, choose Anthropic, OpenAI or Google Gemini, paste the key, choose the model. The key is typed in Studio, never into chat.
- **External MCP servers** can also be connected into Assistant (Manage MCP Servers).

## 4. Generating content

| Tool | Use | Notes |
|---|---|---|
| `generate_mesh` | One static textured mesh | Prompt rules and failure modes in `roblox-pitfalls` section 5. Reference image allowed instead of text. Segmentation: `none` for static props; `explicit` with `partNames` (max 8) for pieces that must move, with function names such as `door`, `lid`, `lever` |
| `generate_material` | Restyle parts | Returns the base material plus a variant name to apply; lightweight form of the Material Generator |
| `generate_procedural_model` | Primitive-part objects with parameters (give sizes in studs, a theme, and "add no other objects"; a character is about 5 studs tall, so jump gaps and doorways need real numbers) | Lands in a `GeneratedFolder`; behaves like normal parts; works with undo, Team Create, replication. The docs state **50 per rolling 24 hours** for Assistant; assume the MCP tool shares it. Generator is a ModuleScript returning `Attributes` and `OnGenerate(params, container)`; scaling uses `ScaleTo`, resizing regenerates; not supported in Actors and cannot become packages |
| Texture Generator (Model tab > Texture, or `/generate_texture`) | Texture a selected mesh from text or an image | Preview in about 10 s (3 images). **Fast** = 1K diffuse in under 30 s; **Quality** = 4K PBR via `SurfaceAppearance` in a couple of minutes. Do not edit the asset while it runs; do not describe reflectivity or transparency in the prompt |
| Material Generator (Window > 3D > Material Generator) | Tileable materials | 4 tiles per Generate; Studs Per Tile, Organic toggle, base material; Save & Apply Variant creates a `MaterialVariant`. Tip: ask for grayscale to tint with `Color` later |
| `generate_scene` (Scene Generation, Studio Beta 2026-10-30) | Prototype scenes: an editable set of procedural models (optionally also generated meshes), textures and terrain inside a bounding box, from a prompt and/or images | 2-3 min per run; Assistant takes one image, Generate > Scene in the viewport menu several. Say what to leave out ("don't generate any terrain") and reuse one style text across runs. Roblox frames it as prototyping. One test (field note, 2026-11-09, 9 generations): about 100-108 s per MCP run; the MCP schema has only `textPrompt`, `images`, `boundingBoxPosition` and `boundingBoxSize`, and "procedural models only" in the prompt was followed 2 of 2 times; a gym interior had the right layout and palette but benches of 2 boxes, a dumbbell rack of 1,920 wedges and a roof on (6,129 parts); a tycoon plot got a terrain base it was not asked for, poking through the floor; each run leaves a disabled generator script (376 KB). Blockout only |
| `generate_animation` (Studio Beta 2026-11-05) | An R15 clip from a prompt, or an R6 animation id converted to R15 | Needs File > Beta Features > Animation Generation in Assistant; untested by us. Details: `roblox-character-motion` section 1 |
| `GenerationService` (in-experience API) | Generate models at runtime | `GenerateModelAsync(inputs, schema)` returns a Model; inputs `TextPrompt` or `Image`, `Size`, `MaxTriangles`, `GenerateTextures`; schema `Car5`, `Body1` or `{Groups={...}}`; wrap in `pcall`; needs moderation-safe prompts. `GenerateMeshAsync` is deprecated. `SegmentMeshAsync` is Studio/plugin only |

One gym-prop test (field notes, 2026-11-09, scratch place): a Cube bench took about 45 s for 4,276-4,940 tris, ignored the size hint (it fits the height) and rendered chrome as flat grey; it created published asset ids, and the log showed no texture-pack uploads. `generate_texture` Fast took under a minute, came closest to the brief and swapped in a new mesh. `segment_mesh` split the bench cleanly into backrest, seat, frame and pin. A `generate_procedural_model` dumbbell rack had 104 parts with tier, pair and colour attributes and rebuilt in 1.5 s on a Size change, but the dumbbells floated and overlapped. `generate_material` gave a rubber floor bright seams and maze-like tiles; built-in Rubber with a Color looked better.

Generative AI rules (official): Roblox AI services (`GenerationService`, `TextGenerator`) moderate inputs and outputs and aim for All Ages content. If a game lets players have extended conversation with a chatbot-like AI, or the AI remembers earlier sessions, answer **Yes** to the Extended AI question; the game then needs a Restricted label (18+). Third-party model output is the creator's responsibility and chat text must still go through `TextChatService`. Details: `roblox-design-and-launch` section 4.

## 5. Studio from the command line

Studio accepts documented flags (others are internal): `--task EditPlace --placeId <id> --universeId <id>` opens the latest published place; `--task EditPlaceRevision ... --placeVersion <n>` an older version; `--task EditFile` a local file; `--task RunScript --runScriptFile <file.luau> [--outputFile <f>] [--quitAfterExecution]` runs a script at command-bar permission (a default Baseplate opens if no place is given), which is a local alternative to Open Cloud Luau Execution; `--task TryAsset --assetId <id>`; `--openScriptPath` / `--openScriptFromId` with line/character flags; `--api`, `--fullApi`, `--apiV2 <path>` dump the API. Launched this way Studio streams verbose logs to stdout. Windows exe: `%localappdata%\Roblox\Versions\<version>\RobloxStudioBeta.exe`.

Opening a local place on macOS: `open -a RobloxStudio file.rbxl` (also with `-g -n`) showed the start page instead of the file (field observation, 2026-11-03). Pass the file as Studio flags to a new background instance instead: `open -g -n -a /Applications/RobloxStudio.app --args -localPlaceFile <absolute path> -task EditFile` (every launch of an overnight run, 2026-11-04), or run the binary `/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio` with the same flags. Studio still activates itself at launch and later; to keep the user's app in front, a small Swift helper started with the new pid can watch `NSWorkspace.didActivateApplicationNotification` and re-activate the user's last app when that pid comes forward. Screenshots work from the background window; FPS checks do not (`roblox-pitfalls` section 3).

## 6. Script Sync (code between Studio and your editor)

Built into Studio, full release 2026-06-17 (docs: create.roblox.com/docs/scripting/sync). Older Studio builds needed **File > Beta Features > Script Sync**. In Explorer right-click a service or folder > **Script Sync > Sync to** and pick the project folder; select the top-level folder and subfolders named like services (`ServerScriptService`, `ReplicatedStorage`, `StarterPlayerScripts`) match automatically. Stop with **Script Sync > Stop Sync**.

- File names: `name.luau` ModuleScript; `name.server.luau` server Script; `name.client.luau` client Script; `name.local.luau` LocalScript; `name.legacy.luau` legacy Script; `name.plugin.luau` plugin Script; a directory is a Folder; `init.*.luau` inside a directory makes that directory a script with children. Extension (`.lua` or `.luau`) is a Studio setting.
- Syncs only Script, LocalScript, ModuleScript and Folder (up to 10,000 scripts per synced root, 128 roots). Attributes and tags on scripts are not synced; `StarterGui` and `StarterPack` content, parts and everything else must go through Studio MCP. Names must be unique and file-system safe.
- Conflicts show a dialog (Keep Studio / Keep Disk). Works with Team Create; two people must not sync the same script.
- Verify from the agent: `game:GetService("InstanceFileSyncService"):GetStatus(instance)` returns `Enum.InstanceFileSyncStatus` (NotSynced, Errored, SyncedAsRoot, SyncedAsDescendant, AncestorErrored).
- Official starter flow (`ai/coding-harness`): project folder with the three service folders, save the place as `.rbxlx` next to it (git-ignored), enable Script Sync, enable MCP, verify with a test script, commit.
- **Script Sync vs Rojo:** Script Sync = code only, no extra tools, works on existing places and Team Create. Rojo = the whole project file-first (instances, models, `rojo build`, Wally packages, CI). Do not sync the same tree with both.

## 7. Run Luau headlessly (Open Cloud Luau Execution)

For CI and automated checks without Studio (stable API, official reference is the OpenAPI spec). Endpoints under `/cloud/v2/universes/{u}/`: `POST places/{p}/luau-execution-session-tasks` (latest version) or `.../versions/{v}/luau-execution-session-tasks` (pinned version); `GET` the task for `state` (QUEUED, PROCESSING, COMPLETE, FAILED, CANCELLED; create does not wait, so poll); `GET .../logs` (FLAT or STRUCTURED).

- Auth: API key in `x-api-key`. Create needs `universe.place.luau-execution-session:write`; get task and logs accept `:read` or `:write`.
- Body: `script` (up to 4 MB), `timeout` (default and max 5 minutes), optional binary input (presigned upload, up to 100 MiB) and binary output (up to 256 MiB, fetch within 15 minutes).
- Limits: return value is JSON, up to 4 MB (Instances come back as null); only the last 450 KB of logs are kept; task info lives 24 h; at most 10 unfinished tasks per place (429 after that). Error codes: SCRIPT_ERROR, DEADLINE_EXCEEDED, OUTPUT_SIZE_LIMIT_EXCEEDED.
- Rate limits per key owner: create task **5 per minute**, binary input 5 per minute, get task 200 per minute, list logs 45 per minute. Batch work into few tasks.
- **Changes to the DataModel inside a task are local and are never saved.** The task has no physics and scripts do not auto-run. APIs that write cloud data (DataStores) do persist, so never run destructive DataStore code against a live universe without asking. To save place content, publish a built `.rbxl`, or use the Instance API (scripts only).
- Typical CI: `rojo build -o game.rbxl` > publish to a test place (`versionType=Saved` or `Published`) > Luau Execution test run > fail the job on FAIL lines. Wrappers such as `rbxcloud luau execute` exist, but rbxcloud's last release is v0.17.0 (2025-03-23); check it against the current OpenAPI spec or call the endpoints directly.

## 8. Simulators and test modes (agents drive these through MCP)

- Test modes: Test (F5), Test Here, Run (F8, no avatar), stop with Shift+F5; solo Test can toggle Client/Server view; **Server & Clients** starts up to 8 clients (F7). Studio's default playtest has **zero network latency**, so also test with the Network Simulator or `NetworkSettings.InboundNetworkMinDelayMs` / `OutboundNetworkMinDelayMs`, `...JitterMs`, `...LossPercent` (docs advise 50-150 ms each way).
- **Device Simulator and Network Simulator:** in the Test tab (Test > Device Simulator, per the 2026-11-06 Performance Simulator post; the docs page read 2026-11-03 still said beta: File > Beta Features > New Device Simulator, restart). Its **Performance** button simulates a device's graphics quality and RAM tier with a background load, not CPU or GPU speed; Studio Settings follow the simulated level, so restore your own setting afterwards (`roblox-engine-2026` section 6). Average Windows and Average MacBook replace Average Laptop. The `rbx-network-simulator` skill applies network presets through `settings().Network` with or without the beta. Device presets: Phone, Desktop, Console, Headset, each in Flagship, Mid-range and Entry-level groups. Network presets (latency/jitter/loss): Ideal Fiber 8 ms; Wired Broadband 25/3/0; Home Wi-Fi 30/12/0.2; 4G 45/20/0.4; 3G 150/70/0.5. Controller Emulator covers Xbox, PS4, PS5, generic gamepad, handheld, TV remote and Quest.
- Plugin-side test API: `StudioTestService:ExecuteMultiplayerTestAsync(numPlayers 1-8, args)`, `ExecutePlayModeAsync`, `ExecuteRunModeAsync`; one session at a time. `TeleportAsync` can be tested in Test and Team Test since 2026-11-05 (limits: `roblox-pitfalls` section 4).
- Place file limit: 100 MB. Save versions with notes (Ctrl+Alt+S); keep Drafts mode off unless the team wants it.

## 9. Choosing Studio MCP vs Assistant vs Open Cloud

| Task | Use |
|---|---|
| Edit many files, refactor, git, tests | Claude Code with Rojo |
| Inspect or change the open place, playtest, screenshots | Studio MCP |
| Generate a mesh/material/procedural model from inside Studio with human review | Assistant (or the MCP generate tools) |
| Plan with approval gate inside Studio | Assistant Planning Mode |
| Store setup, game and place settings, publish, restart, analytics while Studio is open | Studio MCP `open_cloud_invoke` (section 1a), no API key |
| Publish, upload assets, run tests with no Studio window (CI), or an endpoint that refuses the Studio token | Open Cloud with an API key |

## Recent additions (DevForum recaps, Oct 2026)

- `/generate_texture` has a Quality mode (Studio Beta, Oct 12-18): slower, better textures; use it for hero assets, the default mode for bulk props.
- Prompt-to-avatar character generation and live-server inspection during Team Test are Studio Betas (Oct 26-30 listing, not re-read).
- Server-log stack traces deep-link into Studio (Oct 19-23).
