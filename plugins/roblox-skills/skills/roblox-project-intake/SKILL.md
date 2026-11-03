---
name: roblox-project-intake
description: "Use FIRST when a user starts a new Roblox game, prototype, or big feature, or opens a Roblox project the agent has not worked in before. The agent checks the tools (Studio, Studio MCP, git required; Script Sync or Rojo, Blender MCP, Open Cloud key optional), guides setup, interviews the user, and writes a project brief before any design, code or asset work."
when_to_use: "Also when the request is vague ('make me a Roblox game', 'add a shop'), when Studio MCP or Blender MCP is not connected or the user asks how to set them up, when no CLAUDE.md or docs/brief.md exists in the project, when the user switches genre or target audience, or before choosing between Blender, Roblox Cube, Creator Store and Assistant for art."
last_reviewed: 2026-11-03
sources:
  - https://create.roblox.com/docs/production/game-design/prototyping
  - https://create.roblox.com/docs/production/game-design/core-loops
  - https://create.roblox.com/docs/production/promotion/content-maturity
  - https://create.roblox.com/docs/production/publishing/kids-and-select
  - https://create.roblox.com/docs/studio/mcp
  - https://create.roblox.com/docs/studio/setup
  - https://create.roblox.com/docs/scripting/sync
  - https://create.roblox.com/docs/cloud/auth/api-keys
  - https://github.com/rojo-rbx/rokit (README, read 2026-11-03)
  - original (workflow notes from shipping test games with an AI agent)
---

# Project intake (do this before building)

The agent works much better with five minutes of questions than with an hour of guessing. Run this once per project, store the answers in `docs/brief.md`, and re-open it when scope changes. Never ask what a probe can answer, and never ask more than 6 questions at a time. If the user says "just decide", pick the defaults marked (D) and write them into the brief so they can be corrected.

## Step 1. Tool check (probe first, then ask only about the gaps)

Run this at the start of every new project and when a project is opened on a new machine. Planning (`roblox-game-pipeline` stages 1-6) may continue while the user sets tools up; building (stage 7) does not start until every **Required** tool passes.

### 1a. Probe (no questions)

| Probe | Command / tool | Why |
|---|---|---|
| Existing project | `ls`, look for `default.project.json`, `wally.toml`, `rokit.toml`, `CLAUDE.md`, `docs/` | Rojo project vs. Studio-only place |
| Studio installed | macOS `ls /Applications/RobloxStudio.app`; Windows `%LOCALAPPDATA%\Roblox\Versions` | The MCP server ships inside Studio |
| Studio MCP | `claude mcp list` (look for `Roblox_Studio` or the official plugin's `plugin:roblox-studio:<os>`, Connected), then call the MCP tool `list_roblox_studios` by name | Live engine access, which place is open. A server listed but not callable means it was added after this session started |
| git | `git --version`; `git rev-parse --is-inside-work-tree` in the project folder | History and rollback |
| Toolchain | `rokit --version`, `rojo --version`, `selene --version`, `stylua --version`, `lune --version`, `luau-lsp --version` | Which checks can run locally |
| Blender | `blender --version`, `claude mcp list` (look for `blender`), then the MCP tool `get_addon_status` | Custom meshes and rigs |
| Open Cloud | env vars or a `chmod 600` env file with names like `ROBLOX_API_KEY`, `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID` (check that they exist, never print values) | Publish, asset upload, Luau Execution |
| Other MCP | `claude mcp list` (image generation such as gwanggo) | Mood images, icon drafts |
| OS | `uname`, Windows vs. macOS paths | Setup commands differ per OS |

Do not install anything global, and do not touch Studio windows of other projects (say which ones are open and leave them alone).

### 1b. Report and ask

Show one table with a Status column (OK / missing / not checked), then ask only about the gaps.

| Tool | Tier | What it unlocks | If skipped |
|---|---|---|---|
| Roblox Studio, latest version, signed in | **Required** | Everything; Studio MCP needs the latest Studio | Nothing can be built |
| Studio MCP (`Roblox_Studio` connected to Claude Code) | **Required** | Agent reads and edits the open place, playtests, screenshots, console logs, Cube mesh/material/procedural generation, `rbx-*` skills, live docs (`http_get`) | The agent can only write files, the user pastes code and reports results by hand, and "evidence before done" cannot be met. Do not build without it |
| git, project folder is a repo | **Required** | Per-task commits, review, rollback | One bad edit cannot be undone |
| Code on disk: Script Sync (built into Studio) or Rojo | Recommended, pick one (D: Script Sync for a Studio-first game, Rojo for a code-heavy one; `roblox-dev-workflow` section 3) | Scripts as files: diffs, lint, subagents on files | Code lives only in the place; export scripts to git regularly |
| Lint and test tools (selene, StyLua, luau-lsp, Lune via rokit) | Optional | Local checks before Studio | Checks run only in Studio playtests |
| Blender + MCP for Blender | Optional | Animated creatures and rigs, exact-shape kits, icon renders | Roblox Cube for static props, Creator Store, user files |
| Open Cloud API key in an env file | Optional until release | Automated publish, asset upload, passes and products, headless Luau tests | User publishes and uploads by hand in Studio and Creator Hub |
| Image-generation MCP (for example gwanggo) | Optional, spends credits | Mood images, icon and thumbnail drafts | Studio Texture and Material Generator, user art |
| Playtest Agent beta (Studio File > Beta Features) | Optional | Studio MCP `subagent` type `playtest` | The agent drives playtests with the input tools |

How to ask:
- **Required and missing:** say what it is needed for in one line and offer to walk the user through it now. Re-probe after each fix. If the user refuses, record it and stop before stage 7.
- **Optional and missing:** one message, one line each: "set up now / later / skip". On skip, write `Skipped: <tool> - unavailable: <features> - fallback: <fallback>` under Environment in the brief and do not ask again. When a later task needs a skipped tool, say so at that moment and offer setup or the fallback.
- Every question ends with: "If you are not sure how to do this, say so and I will guide you step by step."

### 1c. Setup guides (re-read the live page first)

Menus and commands change between Studio releases. Before guiding, fetch the live page in the table (WebFetch, or Studio MCP `http_get` when connected) and follow it over this file. Guide one step per message; ask the user to confirm or paste the exact error. Keys and passwords are typed by the user into Creator Hub, an env file or an addon panel, never into chat.

| Tool | Short path (details in the linked skill) | Live page | Verify |
|---|---|---|---|
| Studio | Install from the Creator Hub, sign in, accept the update prompt | create.roblox.com/docs/studio/setup | Studio opens a place while signed in |
| Studio MCP | Easiest: Claude Code `/plugin` > install **Roblox Studio** (official), then say "Get me set up with Roblox Studio". Manual: Studio Assistant > ... > Settings > MCP Servers > Enable Studio as MCP server, then Quick connect > Claude Code or `claude mcp add` (`roblox-studio-ai-tools` section 1) | github.com/Roblox/roblox-studio-agent-plugin, create.roblox.com/docs/studio/mcp | Restart Claude Code (servers load at session start; `claude --continue` resumes this conversation), then call `list_roblox_studios` |
| git | macOS `xcode-select --install`; Windows installer from git-scm.com; `git init` in the project folder | git-scm.com | `git --version` |
| Script Sync | Explorer > right-click a service > Script Sync > Sync to (`roblox-studio-ai-tools` section 6) | create.roblox.com/docs/scripting/sync | `InstanceFileSyncService:GetStatus` returns SyncedAsRoot |
| Rojo and tools | Rokit: install script from the rokit README, `rokit self-install`, then `rokit init` and `rokit add rojo-rbx/rojo` (same for selene, StyLua, Lune); `rojo plugin install` adds the Studio plugin | github.com/rojo-rbx/rokit, rojo.space | `rojo --version`; the Rojo plugin in Studio shows Connected after `rojo serve` |
| Blender MCP | `uvx mcp-for-blender install-addon`, enable the add-on, N panel > Connect, `claude mcp add blender uvx mcp-for-blender`, restart Claude Code (`roblox-blender-export` sections 8-9) | github.com/ahujasid/blender-mcp | `get_addon_status` answers |
| Open Cloud key | User creates it in Creator Hub > Credentials with the scopes in `roblox-release-automation` section 2 and saves it to a `chmod 600` env file | create.roblox.com/docs/cloud/auth/api-keys | Variable exists (never print it); one read-only call returns 200 |

Record the final state (tool, version, OK or skipped) in the brief's Environment line.

## Step 2. Interview (ask in rounds)

**Round A: the game (always ask)**

1. One sentence: what is the game, and what does the player do every minute? Name 1-3 reference games.
2. Genre and camera: simulator/tycoon, obby, horror, RPG/adventure, shooter/PvP, social/roleplay, racing, tower defense, other. First person, third person, top-down?
3. Target audience and age: Roblox Kids (5-8), Roblox Select (9-15), 16+, or 18+ Restricted? (This sets the content maturity label, the publishing bar, chat and monetization limits. See `roblox-design-and-launch` section 4.)
4. Platforms: phone, PC, console, VR? Mobile-first changes UI size, part count and texture budgets.
5. Solo or multiplayer? Co-op, PvP, or single-player with leaderboards? Expected players per server? (D: playable alone, better with friends. See `roblox-design-and-launch` section 1a.)
6. Scope for this session: a playable vertical slice in one sitting, or a full game plan? (D: vertical slice with one complete core loop.)

**Round B: look and assets (ask when art is in scope)**

7. Art style: chunky cartoon / low-poly / stylised realistic / blocky Roblox / user's own references (ask for 2-3 images or links).
8. Where should art come from? Offer the routing in `roblox-dev-workflow` section 4: Roblox Cube and Assistant generation (fast, static props), Blender (anything that must animate, exact shapes, kits), Creator Store (fillers, audio), or user-supplied files.
9. Is the user willing to approve anything that spends money or Robux (ads, paid uploads, Hyper3D/Meshy credits)? (D: no spend without asking.)

**Round A2: look, moments and working mode (ask after Round A; the full flow is `roblox-game-pipeline` stages 3-5)**

A1. Style: show a labeled contact sheet of reference games (one per style lane) and ask which is closest and which is the opposite. (D: chunky cartoon for simulator/tycoon.)
A2. Cinematics: none, intro, boss or unlock moment, ending? (D: none until the core loop is fun; see `roblox-cinematics`.)
A3. Small decisions as decision cards with defaults: loading screen, music, tutorial style, hit feedback, friend bonus, localization (`roblox-game-pipeline` section 4).
A4. Control level: auto, stage gates, or task by task? (D: stage gates for a new game.)
A5. Agent mode: solo, subagents, or hybrid? (D: hybrid, Studio edits solo.)

**Round C: accounts and publishing (ask before the first publish)**

10. Who owns the game: personal account or group? (Assets must be owned by the account/group that owns the place, or they can render blank.)
11. Is there an existing experience/universe, or should a new private test place be made? Is there a separate dev place? (D: separate dev place plus a private test place; never open the live place in Studio.)
12. Is the creator account age-checked and 2-step enabled? Reaching players under 16 (Kids, Select) needs both, plus a refundable per-game fee or a 2+ month old Plus/Premium subscription, plus the evaluation; 16+ has a lower bar. See `roblox-design-and-launch` section 4.
13. API key available? Tell the user which scopes are needed and that the key goes into an env file, never into chat.

**Round D: monetization and live ops (ask when the user says "launch" or "earn")**

14. Planned monetization: none yet / passes / developer products / subscriptions / paid access / ads. (D: none in the prototype; add after the core loop is fun.)
15. Update cadence and events planned?

## Step 2b. Advise from platform play patterns

After Round A, read `roblox-design-and-launch` section 1a and check the answers against it (solo-viable checklist, session length for the genre, max players, phone and PC, friend hooks). Tell the developer at most 3 findings, each as "pattern -> your plan -> suggested change", and say the evidence grade (Roblox docs, our chart sample, vendor report, or judgment). The developer decides; record accepted and rejected advice in the brief. Example: "Players hop between games and a median session is about 7 min -> your match needs 8 players to start -> allow a bot fill after 20 s so a solo player can play."

## Step 3. Write the brief

Create `docs/brief.md` and a short `CLAUDE.md` pointing to it. The first line of that `CLAUDE.md` is the Roblox marker, so later sessions load these skills from a plain "I'm making a game" or "what about this idea":

```
Roblox game project (Luau, Roblox Studio). Use the roblox-skills plugin: roblox-game-pipeline for planning and building, roblox-market-research for idea and trend questions. Brief: docs/brief.md
```

The brief contains:

```
# <Game name> brief
Pitch: one sentence
Core loop: minute-to-minute / most-repeated action / progression engine
Genre + camera + platforms + audience (content maturity target)
Style lane + references (assets/refs/), cinematics decision, working mode (control level + agent mode)
Play mode: solo-viable? min players to start, max players and why, target session length, friend hooks, advice accepted/rejected (design-and-launch 1a)
Art direction: style, palette, references, source per asset class (Cube / Blender / Store)
Environment: OS, toolchain versions, MCP servers connected, dev place id, test place id, skipped tools with fallback (step 1b)
Scope of this session: milestone + done-definition + out of scope
Open questions and defaults assumed (D)
```

Show the brief to the user and ask for one confirmation. Then hand over to `roblox-dev-workflow`.

## Rules

- Prefer multiple-choice questions with a recommended default over open-ended ones.
- Ask about audience age before designing monetization or chat features; it changes what is allowed.
- Record decisions as they are made. A decision not in `docs/brief.md` will be forgotten after the session is compacted.
- Do not start Blender, generate meshes or write gameplay code until the pitch, genre, audience and art source are known.
