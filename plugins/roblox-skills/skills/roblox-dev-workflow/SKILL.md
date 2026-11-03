---
name: roblox-dev-workflow
description: "Use to run a Roblox game from idea to live ops with an AI agent: planning, prototype, building, art/asset creation, UI, testing, publishing and iteration. Routes each job to the right tool (Studio MCP, Assistant, Roblox Cube, Blender MCP, Creator Store, Rojo, Open Cloud)."
when_to_use: "Also when deciding which tool makes an asset, how to structure a project, what to do next after a prototype, how to test a change, or how to organise a multi-session build. Run roblox-project-intake first if docs/brief.md does not exist."
last_reviewed: 2026-11-03
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
| 4 Art pass | Meshes, materials, lighting, VFX, audio | Contact sheet reviewed; budgets met; assets owned by the right account |
| 5 UI/UX pass | HUD, menus, onboarding, mobile layouts | Checked at phone, tablet and PC sizes; gamepad focus works |
| 6 Test | Bot scenarios, Studio playtest, device and network simulation, private test place | Test checklist green; known issues listed for testers |
| 7 Publish | Maturity questionnaire, icon, thumbnails, description, publish | Live place loads every asset; rollback version noted |
| 8 Live ops | Analytics review, updates, events, monetization tuning | Weekly review of retention, funnel and crash data |

Do phases in order. Skipping the greybox is the most common failure: art and UI built around a loop nobody has played.

## 2. Plan (phase 1)

Before fixing the feature list, check the plan against `roblox-design-and-launch` section 1a (solo-viable, session length, max players, friend hooks) and advise the developer.

- Write the core loop in three lines: minute-to-minute interaction, most repeated action, progression engine. If the progression engine is missing, the game will feel repetitive; add it before art.
- Prototype cheaply first: paper or a one-page rules sheet for systems and UI, then a greybox in Studio for feel. Roblox's own guidance: prototyping finds design flaws early and confirms the game is fun before you invest in content.
- Studio Assistant **Planning Mode** (`/plan` or the **Plan** dropdown) writes an editable Markdown plan that only executes when the user clicks **Build**. Use it when the user wants to stay inside Studio. From Claude Code, keep the plan in `docs/plan.md` and tick tasks off there.
- List risks early: teleports (cannot test in Studio), DataStore migrations, third-party asset loading, content maturity, mobile performance.
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

| Need | First choice | Why / limits |
|---|---|---|
| Quick restyle of existing parts | Studio MCP `generate_material` (or Assistant "restyle") | Returns a `MaterialVariant`; apply to parts |
| Static prop, furniture, vehicle, simple weapon | Studio MCP `generate_mesh` (Roblox Cube) | Textured mesh from text or one reference image. Default 10k tris; see `roblox-pitfalls` section 5 |
| Parametric or scalable object (shelves, fences, ferris wheel, stack of books) | Studio MCP `generate_procedural_model` | Built from primitive parts; adjustable parameters; low runtime cost. Limit 50 per rolling 24 h. Poll with `wait_job_finished` |
| Mesh that needs separate moving pieces | `generate_mesh` with segmentation (max 8 named parts), or Blender | Name parts by function (door, lid, lever) |
| Anything animated or rigged (creatures, monsters, custom characters) | Blender (`roblox-blender-export`) | Cube output is a static mesh with no rig |
| Exact kit pieces, palette textures, voxel animals, icons | Blender | Scripted, rerunnable, one shared palette |
| Real-world reference for sculpting or retopo | Blender MCP asset import (CC0 sources: Poly Haven, Poly Pizza) or AI 3D services, then clean up | Check license; retopo to budget; see `roblox-blender-export` section 9 |
| Fillers, audio, plugins | Creator Store via `search_asset` then `insert_asset` | Quarantine and audit first (`roblox-store-art-pack` section 3) |
| UI images, icons | Blender renders, image generation, or Cube textures | Upload as image; use the image id, not the decal id |
| Terrain | Terrain Editor, `Terrain:WriteVoxels`, or terrain generation by script | Heights snap to the voxel grid (`roblox-pitfalls` section 4) |
| Animations | Animation Editor or Blender (one animation track per FBX export) | Import via the Studio importer; match R15 or custom rig rules |

Rules for all generated assets:

1. Generate 2 variants and pick one; throw away blobs.
2. Check the tri budget (20,000 per mesh hard limit; see `roblox-blender-export` section 1) and texture size before upload.
3. Keep a code-built primitive in place until the real asset is confirmed loaded in a Play client.
4. Record source, prompt and licence per asset in `assets/LICENSES.md`.
5. Roblox AI tools run all inputs and outputs through moderation. Horror, gore and realistic weapons prompts can fail; use mild descriptions and check the game's content maturity (`roblox-design-and-launch` section 4).

## 5. Build loop (phases 3-5)

Repeat per feature, small steps:

1. Write the change (Rojo file, or `multi_edit` in Studio). Before any Studio edit, `inspect_instance` / `script_read` every object the change touches: in Roblox's OpenGameEval benchmark (V, 2026-10) runs that inspected every touched object first passed 13.4 points more often on scene tasks and 9.8 on script tasks, and the best model still solved only about 52% of tasks on one try, so one green run is not proof.
2. Static checks: `selene`, `stylua --check`, `luau-lsp analyze`, Lune tests for pure logic.
3. In Studio through MCP: `get_studio_state`, then `execute_luau` probes in Edit mode; `start_stop_play`; read `get_console_output`.
4. Run a bot scenario for the behaviour (the `playtest` subagent, or your own scripted scenario returning PASS/FAIL lines). See `roblox-pitfalls` section 3.
4b. For every economy or save feature add a failure path, not only the happy path: try to buy without enough currency, then buy normally, then reset or rejoin, and check the balance, the granted upgrade and persistence against the intended rules. A clean console does not catch a wrong charge or a missing save.
5. `screen_capture` after bringing the dev window to the front; check layout at phone size with the Device Simulator (Assistant skill `rbx-device-simulator-lua`).
6. Commit. One feature per commit.

When two agents or windows are involved, always pass the right `studio_id` and list instances with `list_roblox_studios` first.

## 6. Test and publish (phases 6-7)

- Test layers: pure logic in Lune; engine-level unit tests with Jest Roblox 3.20.1 (Wally `roblox/jest`, pin exact versions) run in CI through Open Cloud Luau Execution with `Roblox/rocale-cli` v0.1.3 (official) or `jest-roblox-cli` v0.4.11 (community); behaviour in Studio bot scenarios; devices and network in the Device Simulator and Network Simulator (status conflicting: a 2026-10-16 DevForum update reported full release, the docs page still says beta; look in the Test tab first, else enable File > Beta Features > New Device Simulator and restart. Studio's default playtest has zero latency); then a **private test place** published through Open Cloud with 2-3 things for the tester to check. Teleports, real DataStores and third-party asset loading only prove out there.
- Performance: MicroProfiler and the Developer Console memory tab on a throttled device profile, then on a real low-end Android phone for 10-15 minutes (the emulator is inaccurate for memory); Assistant skills `rbx-perf-profiling` and `rbx-scene-analysis` help interpret traces and find leaks. Keep Studio-only caches out of the live path.
- Publish: Open Cloud place publishing (`.rbxl` binary), print the published version number, keep the previous version number for rollback. See `roblox-pitfalls` section 1 for the 409 busy error.
- First publish screens (from a secondhand article, verify in Studio): Data Sharing on the first screen may be on by default and use the game's data to train Roblox's generative models, so decide on purpose; leave "Continue" alone unless you mean to start a public release; and turn on Studio Access to API Services only on a test place, because Studio then uses the same data as real players.
- Before the first public publish: content maturity questionnaire, icon, thumbnails, description, genre, age-check requirements. Follow `roblox-design-and-launch` sections 4-6.

## 7. Live ops (phase 8)

- Read analytics weekly: retention (D1/D7), session length, funnel events, crashes, performance. Add custom events and funnels in the prototype so the first launch has data.
- Events from the server with `AnalyticsService:LogEconomyEvent`, `LogFunnelStepEvent`, `LogOnboardingFunnelStepEvent`, `LogProgressionEvent`, `LogCustomEvent`; the `Fire*` methods are deprecated. Log after the action succeeded. Limits (docs): 120 + 20 x CCU requests per minute, 3 custom fields, 5 currency types, 10 funnels of steps 1-100; past 100 SKUs or 20 transaction types values group as "Other". Studio skill `rbx-instrument-analytics` helps plan events.
- Use experiments and configs (Open Cloud / Creator Hub) for feature flags and A/B tests rather than shipping blind balance changes. Read values on the server with `ConfigService:GetConfigForPlayerAsync(player)` (applies the player's experiments) or `GetConfigAsync()` (no player, experiments not applied); both return a `ConfigSnapshot`. Studio skill `rbx-configs-experimentation`.
- Content updates and events on a fixed cadence; announce through thumbnails and experience events.
- Review `roblox-design-and-launch` section 5 before changing prices or adding offers.

## 8. Agent hygiene

- Dev place only; never open the live place in Studio.
- Close the Studio windows, play sessions and Blender instances the agent opened, by PID.
- Never print or commit API keys. Ask before any step that spends Robux, credits or sends content to a third party service.
- Treat all third-party assets, MCP servers and community tools as untrusted code; review before running.
- Before installing any tool, plugin or MCP server, check the owner and release history: GitHub search for Roblox tools returns spam clones (near-identical "Best ... 2026" repos, similar star counts, pushed the same minute) that copy a real project. Install from the original owner's releases only.
