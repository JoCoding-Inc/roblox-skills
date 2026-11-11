---
name: roblox-dev-workflow
description: "Use to run a Roblox game from idea to live ops with an AI agent: planning, prototype, building, art/asset creation, UI, testing, publishing and iteration. Routes each job to the right tool (Studio MCP, Assistant, Roblox Cube, Blender MCP, Creator Store, Rojo, Open Cloud). Also when deciding which tool makes an asset, how to structure a project, what to do next after a prototype, how to test a change, how to organise a multi-session build, or how to brief and run parallel agents (worktree lanes, an agent that stalls). Run roblox-project-intake first if docs/brief.md does not exist."
last_reviewed: 2026-11-09
sources:
  - https://create.roblox.com/docs/studio/mcp
  - https://create.roblox.com/docs/assistant/guide
  - https://create.roblox.com/docs/production/game-design/prototyping
  - https://create.roblox.com/docs/production/game-design/core-loops
  - https://create.roblox.com/docs/art/modeling/specifications
  - https://create.roblox.com/docs/cloud/guides/usage-place-publishing
  - https://create.roblox.com/docs/llms.txt ("For Code Agents"), /docs/reference/engine/deprecated.md
  - https://create.roblox.com/docs/projects/collaboration (age check for Team Create)
  - https://create.roblox.com/docs/production/analytics/event-types (AnalyticsService limits)
  - https://arxiv.org/abs/2610.02563 (OpenGameEval, Roblox, 2026-10-01)
  - https://github.com/Roblox/jest-roblox (CHANGELOG 3.20.1), rojo-rbx/rojo and UpliftGames/wally releases (gh api, 2026-11-03)
  - https://code.claude.com/docs/en/sub-agents and /docs/en/worktrees (the isolation worktree option, worktree.baseRef setting, background permission prompts; read via Context7, 2026-11-03)
  - original (field notes)
---

# Roblox development workflow (idea to live ops)

Run `roblox-game-pipeline` for the staged flow (questions, working mode, plan). Pair with `roblox-engine-2026` (current code, UI and performance rules), `roblox-project-intake` (start), `roblox-studio-ai-tools` (tool details), `roblox-design-and-launch` (planning and policy), `roblox-market-research` (trends, keywords, competitors), `roblox-data-saves`, `roblox-combat-tools`, `roblox-match-flow` (rounds, teams, teleports), `roblox-bots-npcs`, `roblox-feel-audio-vfx`, `roblox-cinematics`, `roblox-blender-export`, `roblox-store-art-pack`, `roblox-ui-genre-studs` and `roblox-pitfalls`.

## 0. Look up before you use (every session)

The model's own API knowledge is older than Studio. At session start call the Studio MCP `list_skills` (Roblox ships `rbx-*` skills for docs search, device and network simulation, profiling, unit tests, debugging, analytics, Configs) and load the matching one before the task. Before writing code with an API that is new, beta, renamed, or listed in `roblox-engine-2026` section 6, read its page with `http_get` (`https://create.roblox.com/docs/reference/engine/classes/<Class>.md`, `query` for the member). If the page does not have it, probe in Studio with `pcall` before relying on it, and say it is unverified. These skills hold workflow, judgment, policy, market data and pitfalls; they do not replace the reference.

Doc map (official, no login; "never guess a URL", a wrong path returns an HTML 404):

| Need | URL |
|---|---|
| Start page for agents, every doc path | `https://create.roblox.com/docs/llms.txt` (section "For Code Agents") |
| Find the page for a question | `https://create.roblox.com/docs/api/search?q=<percent-encoded question>` (JSON; each `url` is fetchable Markdown) |
| Engine API index / Open Cloud index | `/docs/reference/engine/llms.txt`, `/docs/cloud/llms.txt` |
| Was this API removed or replaced? | `/docs/reference/engine/deprecated.md` (600 entries; never suggest a listed member) |

## 1. The phases

| Phase | Output | Done when |
|---|---|---|
| 0 Intake | `docs/brief.md` | User confirmed pitch, genre, audience, art sources |
| 1 Plan | Core loop doc, feature list ordered by value, risks | Core loop has the 3 parts (minute-to-minute action, most repeated action, progression engine) |
| 2 Greybox prototype | Playable loop with primitives and placeholder UI | A tester can finish one loop in under 5 minutes and say if it is fun |
| 3 Systems | Data, economy, progression, saving, remotes | Bot scenarios pass; server owns all state |
| 4 Art pass | Meshes, materials, lighting, VFX, audio | Contact sheet reviewed; budgets met; assets owned by the right account; no primitive stand-in left |
| 5 UI/UX pass | HUD, menus, onboarding, mobile layouts | `roblox-ui-layout` `ui_device_check.luau` has no errors on phone, tablet, desktop (and console if shipped); gamepad focus works |
| 6 Test | Bot scenarios, Studio playtest, device and network simulation, private test place | Test checklist green; known issues listed for testers |
| 7 Publish | Maturity questionnaire, icon, thumbnails, description, publish | Live place loads every asset; rollback version noted |
| 8 Live ops | Analytics review, updates, events, monetization tuning | Weekly review of retention, funnel and crash data |

Do phases in order. Skipping the greybox is the most common failure: art and UI built around a loop nobody has played.

**The agent never builds final art from parts** (owner rule, 2026-11-05, tightened 2026-11-09: agent-made art looked too low quality).

The only exception is a prototype or playtest build: a greybox before the art pass, with every capture labelled greybox. Anything shown to the user or a player as a result is a deliverable and follows these rules:
- **Sources.** Every prop, piece of furniture, unit, creature, set piece and piece of scenery comes from one of these, matched to the game's style:
  - Roblox Cube.
  - A Blender mesh. Hand, script, MCP or headless modelling are all fine, as long as it follows `roblox-blender-export` sections 1-4 and passes a side-by-side check at the same camera against a reference anchor: a store model, a Cube result or a concept image of the same class.
  - A vetted Creator Store model (`roblox-store-art-pack`).
- **Banned as final art.** Roblox Parts and primitives assembled into objects, such as ball-blob plants, box sofas and block units. `generate_procedural_model` results count as part builds, so they are for prototypes only.
- **Characters.** Players keep their own avatar. Humanoid NPCs are Roblox avatars or `generate_avatar` (`roblox-character-design`). Never part-built figures.
- **Structure.** Floors, walls, lanes and terrain may be parts or Terrain. Give them real materials or MaterialVariants chosen for the style, not default flat SmoothPlastic. Everything placed on them is sourced.
- **Lanes where parts are the look** (classic blocky, stud): only when the user picked that lane. Even then, part builds must match a reference anchor's detail.
- **UI.**
  - Layout and code-drawn shapes are construction: panels, strokes, gradients and the chamfers of `roblox-ui-genre-scifi`.
  - Icons come from a store icon pack or an image generator the user has connected.
  - Illustrated or ornate frame art comes from the store, a generator or Blender renders.
- **VFX.**
  - Beams and particles are composed in the engine. Built-in textures are fine when chosen on purpose, such as the soft beams in `roblox-feel-audio-vfx` section 4.
  - Hero and skill effects use Blender meshes plus gradient or flipbook textures (`roblox-feel-audio-vfx` section 3).
  - Default sparkles as the whole look stay rejected.
- **Logos and wordmarks.** Use an image from a generator, the user's file or an editor (`roblox-store-art-pack` section 6). A code-built text wordmark is a placeholder.

## 2. Plan (phase 1)

Before fixing the feature list, check the plan against `roblox-design-and-launch` section 1a (solo-viable, session length, max players, friend hooks) and advise the developer.

- Write the core loop in three lines: minute-to-minute interaction, most repeated action, progression engine. If the progression engine is missing, the game will feel repetitive; add it before art.
- Prototype cheaply first: paper or a one-page rules sheet for systems and UI, then a greybox in Studio for feel. Roblox's own guidance: prototyping finds design flaws early and confirms the game is fun before you invest in content.
- Studio Assistant **Planning Mode** (`/plan` or the **Plan** dropdown) writes an editable Markdown plan that only executes when the user clicks **Build**. Use it when the user wants to stay inside Studio. From Claude Code, keep the plan in `docs/plan.md` and tick tasks off there.
- List risks early: teleports (Studio tests only `TeleportAsync` within one experience), DataStore migrations, third-party asset loading, content maturity, mobile performance.
- Keep scope honest: one complete loop beats five half-built systems.

## 3. Project setup (phase 2)

Two valid setups. Pick one and record it in the brief:

| Setup | Use when | Notes |
|---|---|---|
| **Rojo project** (code in git) | Anything beyond a throwaway prototype | `rokit` installs Rojo, Lune, selene, StyLua; Wally for packages; `rojo build -o game.rbxl`; `rojo serve` for live sync (never bind it to the network). Pin Rojo 7.7.1 (2026-10-02) and Wally 0.3.2 (0.4.0 is alpha and changes the lockfile). Converting an existing place: `rojo syncback` (one-shot place to files, Rojo 7.7.0+), not live two-way sync. Studio holds only the place data |
| **Script Sync + Studio MCP** (official Roblox path, full release 2026-06-17) | Existing places, Team Create, a Studio-first project that still wants git | Script Sync keeps scripts as `.luau` files in git; Studio MCP handles everything Script Sync cannot (StarterGui, StarterPack, parts, properties). Details in `roblox-studio-ai-tools` section 6 |
| **Studio-only** (Studio MCP edits) | A throwaway prototype | `multi_edit` and `script_read` edit scripts in the open place. Export the scripts into git regularly or turn on Script Sync |

Do not scaffold these (archived or unsupported; model memory still suggests them): Knit (archived, last push 2024-07-31; use plain ModuleScripts), Roact (archived 2023-12; use React Luau or built-in UI), Aftman (archived 2025-07; use Rokit), TestEZ (archived 2024-03; use Jest Roblox), `run-in-roblox` (no push since 2024-03), ProfileService and DataStore2 (use ProfileStore, `roblox-data-saves`).

Team Create with other people: the owner (user, or group owner) and each collaborator must complete an age check (ID or facial estimation); collaboration is limited to compatible age groups unless trusted friends or parental permission apply. Solo Team Create needs no check (docs, projects/collaboration).

Suggested Rojo layout:

```
default.project.json  rokit.toml  wally.toml  selene.toml  stylua.toml  .luaurc
src/server  -> ServerScriptService      src/client -> StarterPlayerScripts
src/shared  -> ReplicatedStorage        Packages/ (Wally, gitignored)
assets/ (Blender sources, exports, LICENSES.md)    tests/    docs/brief.md
```

`CLAUDE.md` must list: the exact build/lint/test commands, `--!strict` and type conventions, the client/server rule (server owns state; validate every remote argument by context, type, value and rate: full checklist in `roblox-engine-2026` section 4), "never hand-edit `.rbxl` or `Packages/`", asset import steps, which Studio window is the dev place, and that Open Cloud keys come from env vars only.

## 4. Which tool makes this? (phase 4)

Several rows often fit the same asset. When the choice decides many assets (all machines, all pets), do not pick silently: compare one sample per available tool with the user (`roblox-game-pipeline` section 6a). Cube and procedural models cost no credits.

| Need | First choice | Why / limits |
|---|---|---|
| Quick restyle of existing parts | Studio MCP `generate_material` (or Assistant "restyle") | Returns a `MaterialVariant`; apply to parts |
| Blocky or chunky prop, machine, furniture, building, map structure | Parts built by script (`execute_luau` in Edit mode, or Rojo model files) | No credits, instant, collisions are simple, the user can edit it in Studio. Group as a Model with a PrimaryPart, keep part counts low on repeated props and clone one model. Set the stud or smooth look on purpose, never the new-part default (`roblox-game-pipeline/assets/part-looks/README.md`, with example renders). Weak for organic shapes |
| Static prop, furniture, vehicle, simple weapon | Studio MCP `generate_mesh` (Roblox Cube) | Textured mesh from text or one reference image. Default 10k tris; see `roblox-pitfalls` section 5 |
| Parametric or scalable object (shelves, fences, ferris wheel, stack of books) | Studio MCP `generate_procedural_model` | Built from primitive parts; adjustable parameters; low runtime cost. Limit 50 per rolling 24 h. Poll with `wait_job_finished`. A part build, so prototype and greybox only (section 1) |
| Static props, pets and pickups in one locked style | Roblox Cube (`generate_mesh`) with one reference image for the style, or Blender for exact shapes and kits. Optional, only if connected: gwanggo MCP `generate_game_asset` kind `image`, then kind `3d` from that image (textured GLB, Roblox limits; `roblox-game-pipeline` section 10) | Static, no rig; import with the 3D Importer; gwanggo costs credits, `dry_run` and ask first |
| Standard UI icons (cash, coins, gems, shop, rebirth, settings, gifts, arrows) | Free Creator Store icon pack, ranked by votes (`roblox-store-art-pack` section 4) | One family players already know; use image ids, never decal ids; delete the pack from the place |
| Icons for the game's own items (no store icon fits); seamless textures | Icons: a render of the item's own model (ViewportFrame, or Blender, `roblox-blender-export` section 6). Textures: Studio MCP `generate_material`. Optional, only if connected: gwanggo MCP `generate_game_asset` kind `texture` in the project style, or kind `icon` when the user asks for generated icons. Never draw icons from frames or lines (`roblox-store-art-pack` section 4) | Upload as image; textures go into a `MaterialVariant`; match icons to the store pack |
| Mesh that needs separate moving pieces | `generate_mesh` with segmentation (max 8 named parts), or Blender | Name parts by function (door, lid, lever); rigid parts suit turrets, robots and mechs (`roblox-character-design` section 6) |
| Anything animated or rigged (creatures, monsters, custom characters) | Blender (`roblox-blender-export`) | Cube output is a static mesh with no rig. Design the look and size first: `roblox-character-design` |
| Modular kit pieces with exact sizes (walls, floors, trims, rails), palette textures, voxel animals, icons | Blender | Scripted, rerunnable, one shared palette. Distinct props (machines, furniture) are the Cube or gwanggo rows |
| Real-world reference for sculpting or retopo | Blender MCP asset import (CC0 sources: Poly Haven, Poly Pizza) or AI 3D services, then clean up | Check license; retopo to budget; see `roblox-blender-export` section 9 |
| Fillers, audio, plugins | Creator Store via `search_asset` then `insert_asset` | Quarantine and audit first (`roblox-store-art-pack` section 3) |
| UI images other than standard icons (item renders, banners) | Blender renders, image generation, or Cube textures | Upload as image; use the image id, not the decal id |
| Terrain | Terrain Editor, `Terrain:WriteVoxels`, or terrain generation by script | Heights snap to the voxel grid (`roblox-pitfalls` section 4) |
| Animations | Contact loops (exercise, sitting, machines): solve and bake by script; expressive clips: Animation Editor or Blender (FBX or glTF, several clips per file) | `roblox-character-motion`. Script-registered ids work only in Studio: upload before release |

Rules for all generated assets:

1. Generate 2 variants and pick one; throw away blobs.
2. Check the tri budget (20,000 per mesh hard limit; see `roblox-blender-export` section 1) and texture size before upload.
3. Keep a code-built primitive in place until the real asset is confirmed loaded in a Play client.
4. Record source, prompt and licence per asset in `assets/LICENSES.md`.
5. Roblox AI tools run all inputs and outputs through moderation. Horror, gore and realistic weapons prompts can fail; use mild descriptions and check the game's content maturity (`roblox-design-and-launch` section 4).

## 5. Build loop (phases 3-5)

Repeat per feature, small steps:

1. Write the change (Rojo file, or `multi_edit` in Studio). Before any Studio edit, `inspect_instance` / `script_read` every object the change touches: in Roblox's OpenGameEval benchmark (V, 2026-10) runs that inspected every touched object first passed 13.4 points more often on scene tasks and 9.8 on script tasks, and the best model still solved only about 52% of tasks on one try, so one green run is not proof. After a scripted bulk edit (sed, a Python replace, a generator), check `git diff --stat`.
2. Static checks: `selene`, `stylua --check`, `luau-lsp analyze`, Lune tests for pure logic. Read the whole output and the exit code; a pipe into `tail` returns tail's exit code, not the check's.
3. In Studio through MCP: `get_studio_state`, then `execute_luau` probes in Edit mode; `start_stop_play`; read `get_console_output`. Lint does not catch runtime-only errors in UI code (for example a renamed theme key): Play after UI changes and read the console.
4. Run a bot scenario for the behaviour (the `playtest` subagent, or your own scripted scenario returning PASS/FAIL lines). See `roblox-pitfalls` section 3. For a layout or loop task a passing scenario does not replace walking the player path with real input (`roblox-game-pipeline` section 7).
4b. For every economy or save feature add a failure path, not only the happy path: try to buy without enough currency, then buy normally, then reset or rejoin, and check the balance, the granted upgrade and persistence against the intended rules. A clean console does not catch a wrong charge or a missing save.
5. `screen_capture` from the dev window left in the background (never bring Studio to the front: `roblox-pitfalls` section 3); check layout per device with `roblox-ui-layout` section 6, then the Device Simulator (Assistant skill `rbx-device-simulator-lua`).
6. Commit. One feature per commit.

When two agents or windows are involved, always pass the right `studio_id` and list instances with `list_roblox_studios` first. Within one project only one agent at a time drives the shared Studio place or Blender scene; the others do file-only work or headless Blender, or work in their own Blender instance (`roblox-game-pipeline` section 5, `roblox-blender-export` section 8).

Parallel work lanes (several agents building at once; whether to delegate at all: `roblox-game-pipeline` section 5):

- Before spawning more than two agents, post the plan (one row per agent: task, files, model; open decisions with defaults; credit quotes) and wait for an explicit go. A user stopped 8 agents that were launched before the plan was shown (field observation).
- Write a lane contract before spawning (for example `docs/prototype-contract.md`): instance tree names, remote names and payloads, module APIs, and which lane owns which files. Three lanes (server, client flow, effects) built against one contract merged cleanly overnight (field observation, 2026-11-04).
- A lane that needs Studio opens its own dev place file, built from its worktree and named after the lane (`<Game>-dev-<lane>.rbxl`), and drives only the window with that name, never another lane's or another project's. Cap open windows by memory (`roblox-game-pipeline` section 0, rule 8). Generation calls share one limit across lanes: at most 2 `generate_mesh` jobs at a time on the machine (`roblox-pitfalls` section 5).
- Claude Code's Agent tool option `isolation: "worktree"` covers only the session's own repo (branched from the remote default branch unless `worktree.baseRef` is `"head"`); lane agents could not use git in a target repo outside the session directory (field observation). Create the worktrees by hand, `git worktree add -b feat/<lane> ../<repo>-<lane> <base>`, start each agent without `isolation`, and give it the absolute path, the files it may edit and the files it must not touch.
- One owner lane per shared module (HUD module, asset-id manifest, the ScreenGui `DisplayOrder` table); the other lanes do not edit it, or only a region the contract names (layout constants for one lane, goal logic for another), with new code in a new module. Two lanes split one big HUD file this way, each in its own worktree, and the merge conflicted only in a shared docs file (field observation, 2026-11-04). Regenerate generated manifests with their generator after a merge; never hand-merge them.
- After every merge run lint and tests and grep for symbols the merge dropped.

## 6. Test and publish (phases 6-7)

- Test layers: pure logic in Lune; engine-level unit tests with Jest Roblox 3.20.1 (Wally `roblox/jest`, pin exact versions) run in CI through Open Cloud Luau Execution with `Roblox/rocale-cli` v0.1.3 (official) or `jest-roblox-cli` v0.4.11 (community); behaviour in Studio bot scenarios; devices and network in the Device Simulator and Network Simulator (status conflicting: a 2026-10-16 DevForum update reported full release, the docs page still says beta; look in the Test tab first, else enable File > Beta Features > New Device Simulator and restart. Studio's default playtest has zero latency); then a **private test place** published through Open Cloud with 2-3 things for the tester to check. Teleports, real DataStores and third-party asset loading only prove out there.
- Feel: speeds, combat, difficulty, scares, audio and phone controls are judged by a person playing, not by screenshots; plan user play sessions with `roblox-game-pipeline` section 7a.
- Performance: MicroProfiler and the Developer Console memory tab on a throttled device profile, then on a real low-end Android phone for 10-15 minutes (the emulator is inaccurate for memory); Assistant skills `rbx-perf-profiling` and `rbx-scene-analysis` help interpret traces and find leaks. Keep Studio-only caches out of the live path.
- Publish: Open Cloud place publishing (`.rbxl` binary; with Studio open, through the Studio MCP `open_cloud_invoke` and MCP Permissions, no key, `roblox-release-automation` section 1), print the published version number, keep the previous version number for rollback. See `roblox-pitfalls` section 1 for the 409 busy error.
- Handing over a place file (for example on the Desktop after an unattended run): prove it matches the commit. `rojo build` HEAD to a scratch file and `cmp` it with the handed-over `.rbxl`; the two were byte-identical in our run (2026-11-04).
- First publish screens (from a secondhand article, verify in Studio): Data Sharing on the first screen may be on by default and use the game's data to train Roblox's generative models, so decide on purpose; leave "Continue" alone unless you mean to start a public release; and turn on Studio Access to API Services only on a test place, because Studio then uses the same data as real players.
- Before the first public publish: content maturity questionnaire, icon, thumbnails, description, genre, age-check requirements. Follow `roblox-design-and-launch` sections 4-6.

## 7. Live ops (phase 8)

- Read analytics weekly: retention (D1/D7), session length, funnel events, crashes, performance. Add custom events and funnels in the prototype so the first launch has data.
- Events go from the server with `AnalyticsService` (economy, funnel, journey, custom); the `Fire*` methods are deprecated. Log after the action succeeded. Events from Studio or the client never arrive, so test in a published test place. Calls, rules, limits and the minimum event set: `roblox-design-and-launch` section 3a. Studio skill `rbx-instrument-analytics` helps plan events.
- Use experiments and configs (Open Cloud / Creator Hub) for feature flags and A/B tests rather than shipping blind balance changes. Read values on the server with `ConfigService:GetConfigForPlayerAsync(player)` (applies the player's experiments) or `GetConfigAsync()` (no player, experiments not applied); both return a `ConfigSnapshot`. Studio skill `rbx-configs-experimentation`.
- Content updates and events on a fixed cadence; announce through thumbnails and experience events.
- Review `roblox-design-and-launch` section 5 before changing prices or adding offers.

## 8. Agent hygiene

- Dev place only; never open the live place in Studio.
- Close the Studio windows, play sessions and Blender instances the agent opened, by PID.
- One owner per scheduled job (a 3-hourly ads check, a nightly build): two sessions ran the same check and wrote duplicate log entries (field note, 2026-11-09). Check the log or git history for that slot before running it.
- For one asset, the brief decides the quality more than the maker: a lead session and a subagent given the same brief (hard requirements plus forced self-review passes on renders) made comparable results, and the agent took longer but added checks the lead skipped (field note, 2026-11-11). Put the requirements and review passes in the brief; spawn agents for batches, where they buy parallel time.
- Every subagent brief says: no commands that need approval (`rm` and other deletes), no watch mode or foreground servers (`rojo serve`, `python3 -I -m http.server`), one command per Bash call (never edit, delete, rebuild and upload chained in one call), no call that waits more than 4 min (an agent's prompt cache lasts 5 min, so a longer wait rewrites its whole context on the next call: poll with sleeps of 240 s or less, or end the agent and let the parent wait in the background), and report `BLOCKED` instead of waiting (also for a Studio window stuck at the login screen, `roblox-pitfalls` section 3). Every brief also forbids uploads and credit spend unless the user approved that exact batch: a lane whose brief left the rule out re-uploaded 90 resized textures (field note, 2026-11-08). Opening a Rojo-built place with `SurfaceAppearance` maps uploads too (`roblox-pitfalls` section 4). A brief that builds scenery or unit art also carries the primitive stand-in rule (section 1). A permission prompt waits for the user, so an unattended agent sits on it (field observation).
- Agents commit after each logical step, not only at the end. Keep the ledger (`docs/ledger.md`, `roblox-game-pipeline` section 0 rule 4), briefs and agent reports in the repo (git-ignored is fine), not in a temp or scratch directory that can be wiped.
- Never print or commit API keys. Ask before any step that spends Robux, credits or sends content to a third party service.
- Treat all third-party assets, MCP servers and community tools as untrusted code; review before running.
- Before installing any tool, plugin or MCP server, check the owner and release history: GitHub search for Roblox tools returns spam clones (near-identical "Best ... 2026" repos, similar star counts, pushed the same minute) that copy a real project. Install from the original owner's releases only.
