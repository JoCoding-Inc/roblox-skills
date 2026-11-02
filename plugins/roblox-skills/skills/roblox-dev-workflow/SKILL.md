---
name: roblox-dev-workflow
description: "Use to run a Roblox game from idea to live ops with an AI agent: planning, prototype, building, art/asset creation, UI, testing, publishing and iteration. Routes each job to the right tool (Studio MCP, Assistant, Roblox Cube, Blender MCP, Creator Store, Rojo, Open Cloud)."
when_to_use: "Also when deciding which tool makes an asset, how to structure a project, what to do next after a prototype, how to test a change, or how to organise a multi-session build. Run roblox-project-intake first if docs/brief.md does not exist."
last_reviewed: 2026-11-01
sources:
  - https://create.roblox.com/docs/studio/mcp
  - https://create.roblox.com/docs/assistant/guide
  - https://create.roblox.com/docs/production/game-design/prototyping
  - https://create.roblox.com/docs/production/game-design/core-loops
  - https://create.roblox.com/docs/art/modeling/specifications
  - https://create.roblox.com/docs/cloud/guides/usage-place-publishing
  - original (field notes)
---

# Roblox development workflow (idea to live ops)

Pair with `roblox-engine-2026` (current code, UI and performance rules), `roblox-project-intake` (start), `roblox-studio-ai-tools` (tool details), `roblox-design-and-launch` (planning and policy), `roblox-blender-export`, `roblox-store-art-pack`, `roblox-ui-genre-studs` and `roblox-pitfalls`. Pair with roblox-brain skills for engine API detail (`roblox-building`, `roblox-gui`, `roblox-data`, `roblox-cloud`, `roblox-lighting`).

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

- Write the core loop in three lines: minute-to-minute interaction, most repeated action, progression engine. If the progression engine is missing, the game will feel repetitive; add it before art.
- Prototype cheaply first: paper or a one-page rules sheet for systems and UI, then a greybox in Studio for feel. Roblox's own guidance: prototyping finds design flaws early and confirms the game is fun before you invest in content.
- Studio Assistant **Planning Mode** (`/plan` or the **Plan** dropdown) writes an editable Markdown plan that only executes when the user clicks **Build**. Use it when the user wants to stay inside Studio. From Claude Code, keep the plan in `docs/plan.md` and tick tasks off there.
- List risks early: teleports (cannot test in Studio), DataStore migrations, third-party asset loading, content maturity, mobile performance.
- Keep scope honest: one complete loop beats five half-built systems.

## 3. Project setup (phase 2)

Two valid setups. Pick one and record it in the brief:

| Setup | Use when | Notes |
|---|---|---|
| **Rojo project** (code in git) | Anything beyond a throwaway prototype | `rokit` installs Rojo, Lune, selene, StyLua; Wally for packages; `rojo build -o game.rbxl`; `rojo serve` for live sync. Studio holds only the place data |
| **Script Sync + Studio MCP** (official Roblox path, beta) | Existing places, Team Create, a Studio-first project that still wants git | Script Sync keeps scripts as `.luau` files in git; Studio MCP handles everything Script Sync cannot (StarterGui, StarterPack, parts, properties). Details in `roblox-studio-ai-tools` section 6 |
| **Studio-only** (Studio MCP edits) | A throwaway prototype | `multi_edit` and `script_read` edit scripts in the open place. Export the scripts into git regularly or turn on Script Sync |

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
| Terrain | Terrain Editor, `Terrain:Write*`, or terrain generation by script | Heights snap to the voxel grid (`roblox-pitfalls` section 4) |
| Animations | Animation Editor or Blender (one animation track per FBX export) | Import via the Studio importer; match R15 or custom rig rules |

Rules for all generated assets:

1. Generate 2 variants and pick one; throw away blobs.
2. Check the tri budget (20,000 per mesh hard limit; see `roblox-blender-export` section 1) and texture size before upload.
3. Keep a code-built primitive in place until the real asset is confirmed loaded in a Play client.
4. Record source, prompt and licence per asset in `assets/LICENSES.md`.
5. Roblox AI tools run all inputs and outputs through moderation. Horror, gore and realistic weapons prompts can fail; use mild descriptions and check the game's content maturity (`roblox-design-and-launch` section 4).

## 5. Build loop (phases 3-5)

Repeat per feature, small steps:

1. Write the change (Rojo file, or `multi_edit` in Studio).
2. Static checks: `selene`, `stylua --check`, `luau-lsp analyze`, Lune tests for pure logic.
3. In Studio through MCP: `get_studio_state`, then `execute_luau` probes in Edit mode; `start_stop_play`; read `get_console_output`.
4. Run a bot scenario for the behaviour (the `playtest` subagent, or your own scripted scenario returning PASS/FAIL lines). See `roblox-pitfalls` section 3.
4b. For every economy or save feature add a failure path, not only the happy path: try to buy without enough currency, then buy normally, then reset or rejoin, and check the balance, the granted upgrade and persistence against the intended rules. A clean console does not catch a wrong charge or a missing save.
5. `screen_capture` after bringing the dev window to the front; check layout at phone size with the Device Simulator (Assistant skill `rbx-device-simulator-lua`).
6. Commit. One feature per commit.

When two agents or windows are involved, always pass the right `studio_id` and list instances with `list_roblox_studios` first.

## 6. Test and publish (phases 6-7)

- Test layers: pure logic in Lune, behaviour in Studio bot scenarios, devices and network in Studio simulators (both beta; Studio's default playtest has zero latency), then a **private test place** published through Open Cloud with 2-3 things for the tester to check. Teleports, real DataStores and third-party asset loading only prove out there.
- Performance: MicroProfiler and the Developer Console memory tab on a throttled device profile, then on a real low-end Android phone for 10-15 minutes (the emulator is inaccurate for memory); Assistant skills `rbx-perf-profiling` and `rbx-scene-analysis` help interpret traces and find leaks. Keep Studio-only caches out of the live path.
- Publish: Open Cloud place publishing (`.rbxl` binary), print the published version number, keep the previous version number for rollback. See `roblox-pitfalls` section 1 for the 409 busy error.
- First publish screens (from a secondhand article, verify in Studio): Data Sharing on the first screen may be on by default and use the game's data to train Roblox's generative models, so decide on purpose; leave "Continue" alone unless you mean to start a public release; and turn on Studio Access to API Services only on a test place, because Studio then uses the same data as real players.
- Before the first public publish: content maturity questionnaire, icon, thumbnails, description, genre, age-check requirements. Follow `roblox-design-and-launch` sections 4-6.

## 7. Live ops (phase 8)

- Read analytics weekly: retention (D1/D7), session length, funnel events, crashes, performance. Add custom events and funnels in the prototype so the first launch has data.
- Use experiments and configs (Open Cloud / Creator Hub) for feature flags and A/B tests rather than shipping blind balance changes.
- Content updates and events on a fixed cadence; announce through thumbnails and experience events.
- Review `roblox-design-and-launch` section 5 before changing prices or adding offers.

## 8. Agent hygiene

- Dev place only; never open the live place in Studio.
- Close the Studio windows, play sessions and Blender instances the agent opened, by PID.
- Never print or commit API keys. Ask before any step that spends Robux, credits or sends content to a third party service.
- Treat all third-party assets, MCP servers and community tools as untrusted code; review before running.
