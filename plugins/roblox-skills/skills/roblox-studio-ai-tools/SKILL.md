---
name: roblox-studio-ai-tools
description: "Use when connecting Claude Code to Roblox Studio (built-in Studio MCP server), choosing among its tools, using Studio Assistant (Planning Mode, /generate_mesh, /generate_procedural_model, skills, bring-your-own-key), generating materials/meshes/procedural models, or running Luau headlessly through Open Cloud."
when_to_use: "Also on 'Roblox_Studio MCP not connected', a tool name that no longer exists (run_code, insert_model, run_script_in_play_mode), a migration from the old studio-rust-mcp-server, multiple Studio windows, writing Assistant skills, or CI that needs to run Luau against a place."
last_reviewed: 2026-11-01
sources:
  - https://create.roblox.com/docs/studio/mcp (GitHub source Roblox/creator-docs, read 2026-11-01)
  - https://create.roblox.com/docs/assistant/guide
  - https://create.roblox.com/docs/assistant/mcp
  - https://create.roblox.com/docs/assistant/skills
  - https://create.roblox.com/docs/studio/cli
  - https://create.roblox.com/docs/generative-AI
  - https://create.roblox.com/docs/cloud/reference/features/luau-execution
  - https://github.com/Roblox/studio-rust-mcp-server (archived)
---

# Studio MCP, Assistant and AI generation

Facts here come from the official creator-docs repository (docs state as of 2026-10-29). Tool names change; when a call fails with "unknown tool", list the tools the server actually exposes and trust that list over this file.

## 1. Connect Claude Code to Studio

The Studio MCP server is **built into Roblox Studio** (stdio, local process). The older Rust server (`Roblox/studio-rust-mcp-server`, tools `run_code`, `insert_model`, `run_script_in_play_mode`, `get_studio_mode`) is superseded (a third-party summary says the repo is archived; the official docs only call the built-in server the way to connect, so treat the archive claim as unverified). Remove its `Roblox_Studio` entry before adding the built-in one so the names do not clash.

1. Update Studio to the latest version.
2. Studio: **Assistant** > **...** > **Manage MCP Servers** > turn on **Enable Studio as MCP server**.
3. Connect the client, either:
   - Quick connect: **Assistant Settings** > **MCP Servers** > **Quick connect**, toggle Claude Code (also lists Claude Desktop, Cursor, Codex CLI, Gemini CLI, Antigravity, VS Code). Install the client first and restart Studio if it is missing.
   - CLI command (macOS): `claude mcp add Roblox_Studio -s user -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
   - CLI command (Windows): `claude mcp add Roblox_Studio -s user -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"`
   - JSON: macOS `{"mcpServers":{"Roblox_Studio":{"command":"/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"}}}`; Windows `{"mcpServers":{"Roblox_Studio":{"command":"cmd.exe","args":["/c","%LOCALAPPDATA%\\Roblox\\mcp.bat"]}}}`
4. Restart Claude Code. Verify: `claude mcp list` shows Connected, and Studio's Manage MCP Servers panel shows a green client count. In the session, ask for the tool by name ("call `list_roblox_studios`, no shell commands"): a vague "list my Studio windows" can look like a pass with nothing connected. A new project folder needs the add command again (project-scoped config).
5. Troubleshoot: restart both apps, check the binary path exists, check JSON commas.

Security: any connected client can read and modify the open places. Connect only clients you trust, and keep execute tools on prompt in Claude Code's permissions.

## 2. Tool map (built-in server)

Every call takes a `studio_id`. Call `list_roblox_studios` first (name, instance id, place id) and pass the id of your dev place, especially with several windows or agents.

| Group | Tools | Notes |
|---|---|---|
| Scripts | `script_read`, `multi_edit`, `script_search`, `script_grep` | Dot-notation paths; `multi_edit` creates a script if the path is new and needs `datamodel_type` Edit. `script_search` returns 10 fuzzy matches, `script_grep` 50 |
| Generate | `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished` | See section 4 |
| Assets | `search_asset`, `insert_asset`, `upload_image`, `store_image` | `search_asset` covers Creator Store and your inventory (user, group, universe) with type, price, tag filters. `store_image` turns a local file into a URI for reference images |
| Explore | `search_game_tree`, `inspect_instance`, `subagent` | `subagent` types: `explore` (investigate game state) and `playtest` (run gameplay scenarios and verify outcomes; the Playtest Agent is a beta under File > Beta Features and has a daily cap, and can report false passes). The `subagent` tool in the Studio build of 2026-11-02 listed only `explore`, `screen_capture` and `unit_test`, so `playtest` needs the beta on. A secondhand report says it could not jump in one run; recheck any climb it fails |
| Run | `execute_luau` | `datamodel_type` Edit, Client or Server |
| Playtest | `get_studio_state`, `start_stop_play`, `get_console_output`, `screen_capture` | `screen_capture` accepts a camera position and look-at |
| Input | `character_navigation`, `user_keyboard_input`, `user_mouse_input` | Sequences of actions; can target UI instances |
| Docs | `http_get`, `skill` | `http_get` reads allowed Roblox docs URLs (Engine API, Creator docs, Cloud API). Use it before guessing an API |
| Sessions | `list_roblox_studios` | |

Use them in this order for a change: `get_studio_state` > `search_game_tree` / `inspect_instance` > `script_read` > `multi_edit` > `execute_luau` probe > `start_stop_play` > `get_console_output` > `screen_capture`. Pitfalls with these tools (camera type reset, fresh module copies, hover not firing, window must be frontmost) are in `roblox-pitfalls` section 3.

When the docs and a tool disagree, ask `http_get` for the page, or the Studio `skill` tool for the topic, instead of relying on memory.

## 3. Assistant in Studio (what it adds)

Use Assistant for things that live best inside Studio; use Claude Code for repo-wide code work. Both can run at once on different tasks.

- **Planning Mode:** pick **Plan** in the input dropdown or type `/plan`. It writes an editable Markdown plan, stored in the cloud per experience and creator, private to you. Execution starts only when you click **Build**; edits to the plan sync back to Assistant.
- **Slash commands:** `/plan`, `/generate_mesh <text or image>` (not both), `/generate_procedural_model <text or image>` (Assistant limit: 50 per rolling 24 hours), `/generate_material`, `/generate_texture`, `/segment_mesh` (select the MeshPart itself; up to 5 part names per run), `/insert_asset <id>`. A selected Part is used as a bounding box. Optional max triangle count (default 10,000).
- **Prompting Assistant:** use exact instance names; it biases to edit-time, so ask for a script when you want runtime behaviour; name the object first and leave out background, camera, lighting and quality words; for procedural models state which properties must be editable and how it scales; reference images should be .png at a 3/4 angle and not low-poly. Official loop: Plan > Build and Playtest > Refine and Polish, playtesting after every round.
- **Screen capture subagent** and chat history exist; plans and chats are not visible to collaborators.
- **Skills:** a skill is one Markdown file with frontmatter `name` (lowercase, no `rbx-` prefix), `description`, `enabled`, loaded automatically when a request matches the description or by typing `/` in the composer. Skills belong to the Roblox account, so they apply to every place. Built-in Roblox skills: `rbx-create-skill`, `rbx-debug` (breakpoints, call stacks), `rbx-device-simulator-lua` (device presets and UI screenshots), `rbx-docs-search`, `rbx-perf-profiling` (MicroProfiler analysis), `rbx-scene-analysis` (rendering cost, memory, leaks, asset inventory), `rbx-unit-test` (Jest-Lua/TestEZ). Duplicate one to customise it; the original is then disabled automatically.
- **Bring your own key:** **Assistant > ... > Manage API Keys**, choose Anthropic, OpenAI or Google Gemini, paste the key, choose the model. The key is typed in Studio, never into chat.
- **External MCP servers** can also be connected into Assistant (Manage MCP Servers).

## 4. Generating content

| Tool | Use | Notes |
|---|---|---|
| `generate_mesh` | One static textured mesh | Prompt rules and failure modes in `roblox-pitfalls` section 5. Reference image allowed instead of text. Segmentation: none for static props; named parts (max 8) for pieces that must move, with function names such as `door`, `lid`, `lever` |
| `generate_material` | Restyle parts | Returns the base material plus a variant name to apply; lightweight form of the Material Generator |
| `generate_procedural_model` | Primitive-part objects with parameters (give sizes in studs, a theme, and "add no other objects"; a character is about 5 studs tall, so jump gaps and doorways need real numbers) | Lands in a `GeneratedFolder`; behaves like normal parts; works with undo, Team Create, replication. The docs state **50 per rolling 24 hours** for Assistant; assume the MCP tool shares it. Generator is a ModuleScript returning `Attributes` and `OnGenerate(params, container)`; scaling uses `ScaleTo`, resizing regenerates; not supported in Actors and cannot become packages |
| Texture Generator (Model tab > Texture, or `/generate_texture`) | Texture a selected mesh from text or an image | Preview in about 10 s (3 images). **Fast** = 1K diffuse in under 30 s; **Quality** = 4K PBR via `SurfaceAppearance` in a couple of minutes. Do not edit the asset while it runs; do not describe reflectivity or transparency in the prompt |
| Material Generator (Window > 3D > Material Generator) | Tileable materials | 4 tiles per Generate; Studs Per Tile, Organic toggle, base material; Save & Apply Variant creates a `MaterialVariant`. Tip: ask for grayscale to tint with `Color` later |
| `GenerationService` (in-experience API) | Generate models at runtime | `GenerateModelAsync(inputs, schema)` returns a Model; inputs `TextPrompt` or `Image`, `Size`, `MaxTriangles`, `GenerateTextures`; schema `Car5`, `Body1` or `{Groups={...}}`; wrap in `pcall`; needs moderation-safe prompts. `GenerateMeshAsync` is deprecated. `SegmentMeshAsync` is Studio/plugin only |

Generative AI rules (official): Roblox AI services (`GenerationService`, `TextGenerator`) moderate inputs and outputs and aim for All Ages content. If a game lets players have extended conversation with a chatbot-like AI, or the AI remembers earlier sessions, answer **Yes** to the Extended AI question; the game then needs a Restricted label (18+). Third-party model output is the creator's responsibility and chat text must still go through `TextChatService`. Details: `roblox-design-and-launch` section 4.

## 5. Studio from the command line

Studio accepts documented flags (others are internal): `--task EditPlace --placeId <id> --universeId <id>` opens the latest published place; `--task EditPlaceRevision ... --placeVersion <n>` an older version; `--task EditFile` a local file; `--task RunScript --runScriptFile <file.luau> [--outputFile <f>] [--quitAfterExecution]` runs a script at command-bar permission (a default Baseplate opens if no place is given), which is a local alternative to Open Cloud Luau Execution; `--task TryAsset --assetId <id>`; `--openScriptPath` / `--openScriptFromId` with line/character flags; `--api`, `--fullApi`, `--apiV2 <path>` dump the API. Launched this way Studio streams verbose logs to stdout. Windows exe: `%localappdata%\Roblox\Versions\<version>\RobloxStudioBeta.exe`.

## 6. Script Sync (code between Studio and your editor)

Built into Studio (beta). Enable: **File > Beta Features > Script Sync**, Save, restart Studio. Then in Explorer right-click a service or folder > **Script Sync > Sync to** and pick the project folder; select the top-level folder and subfolders named like services (`ServerScriptService`, `ReplicatedStorage`, `StarterPlayerScripts`) match automatically. Stop with **Script Sync > Stop Sync**.

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
- Typical CI: `rojo build -o game.rbxl` > publish to a test place (`versionType=Saved` or `Published`) > Luau Execution test run > fail the job on FAIL lines. Wrappers such as `rbxcloud luau execute` exist.

## 8. Simulators and test modes (agents drive these through MCP)

- Test modes: Test (F5), Test Here, Run (F8, no avatar), stop with Shift+F5; solo Test can toggle Client/Server view; **Server & Clients** starts up to 8 clients (F7). Studio's default playtest has **zero network latency**, so also test with the Network Simulator or `NetworkSettings.InboundNetworkMinDelayMs` / `OutboundNetworkMinDelayMs`, `...JitterMs`, `...LossPercent` (docs advise 50-150 ms each way).
- **Device Simulator and Network Simulator are beta:** File > Beta Features > New Device Simulator, restart. Device presets: Phone, Desktop, Console, Headset, each in Flagship, Mid-range and Entry-level groups. Network presets (latency/jitter/loss): Ideal Fiber 8 ms; Wired Broadband 25/3/0; Home Wi-Fi 30/12/0.2; 4G 45/20/0.4; 3G 150/70/0.5. Controller Emulator covers Xbox, PS4, PS5, generic gamepad, handheld, TV remote and Quest.
- Plugin-side test API: `StudioTestService:ExecuteMultiplayerTestAsync(numPlayers 1-8, args)`, `ExecutePlayModeAsync`, `ExecuteRunModeAsync`; one session at a time. Teleports cannot be tested in Studio.
- Place file limit: 100 MB. Save versions with notes (Ctrl+Alt+S); keep Drafts mode off unless the team wants it.

## 9. Choosing Studio MCP vs Assistant vs Open Cloud

| Task | Use |
|---|---|
| Edit many files, refactor, git, tests | Claude Code with Rojo |
| Inspect or change the open place, playtest, screenshots | Studio MCP |
| Generate a mesh/material/procedural model from inside Studio with human review | Assistant (or the MCP generate tools) |
| Plan with approval gate inside Studio | Assistant Planning Mode |
| Publish, upload assets, run tests with no Studio window | Open Cloud |

## Recent additions (DevForum recaps, Oct 2026)

- `/generate_texture` has a Quality mode (Studio Beta, Oct 12-18): slower, better textures; use it for hero assets, the default mode for bulk props.
- Prompt-to-avatar character generation and live-server inspection during Team Test are Studio Betas (Oct 26-30 listing, not re-read).
- Server-log stack traces deep-link into Studio (Oct 19-23).
