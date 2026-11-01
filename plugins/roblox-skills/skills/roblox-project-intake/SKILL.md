---
name: roblox-project-intake
description: "Use FIRST when a user starts a new Roblox game, prototype, or big feature, or opens a Roblox project the agent has not worked in before. The agent interviews the user, probes the local setup, and writes a project brief before any design, code or asset work."
when_to_use: "Also when the request is vague ('make me a Roblox game', 'add a shop'), when no CLAUDE.md or docs/brief.md exists in the project, when the user switches genre or target audience, or before choosing between Blender, Roblox Cube, Creator Store and Assistant for art."
last_reviewed: 2026-11-01
sources:
  - https://create.roblox.com/docs/production/game-design/prototyping
  - https://create.roblox.com/docs/production/game-design/core-loops
  - https://create.roblox.com/docs/production/promotion/content-maturity
  - https://create.roblox.com/docs/production/publishing/kids-and-select
  - https://create.roblox.com/docs/studio/mcp
  - original (workflow notes from shipping test games with an AI agent)
---

# Project intake (do this before building)

The agent works much better with five minutes of questions than with an hour of guessing. Run this once per project, store the answers in `docs/brief.md`, and re-open it when scope changes. Never ask what a probe can answer, and never ask more than 6 questions at a time. If the user says "just decide", pick the defaults marked (D) and write them into the brief so they can be corrected.

## Step 1. Probe the machine first (no questions)

Run these and record the results in the brief:

| Probe | Command / tool | Why |
|---|---|---|
| Existing project | `ls`, look for `default.project.json`, `wally.toml`, `rokit.toml`, `CLAUDE.md`, `docs/` | Rojo project vs. Studio-only place |
| Toolchain | `rokit --version`, `rojo --version`, `selene --version`, `stylua --version`, `lune --version`, `luau-lsp --version` | Which checks can run locally |
| Studio MCP | `claude mcp list` (look for `Roblox_Studio`, Connected) and the MCP tool `list_roblox_studios` | Live engine access, which place is open |
| Blender | `blender --version`, `claude mcp list` (look for `blender`) | Custom meshes and rigs |
| Open Cloud | env vars named like `ROBLOX_API_KEY`, `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID` (check that they exist, never print values) | Publish, asset upload, Luau Execution |
| OS | `uname`, Windows vs. macOS paths | Studio MCP command differs per OS |

If the Studio MCP is missing, point the user to `roblox-studio-ai-tools` section 1. Do not install anything global without telling the user.

## Step 2. Interview (ask in rounds)

**Round A: the game (always ask)**

1. One sentence: what is the game, and what does the player do every minute? Name 1-3 reference games.
2. Genre and camera: simulator/tycoon, obby, horror, RPG/adventure, shooter/PvP, social/roleplay, racing, tower defense, other. First person, third person, top-down?
3. Target audience and age: all ages, 9-12, 13+, 17+? (This sets the content maturity label, chat and monetization limits. See `roblox-design-and-launch` section 4.)
4. Platforms: phone, PC, console, VR? Mobile-first changes UI size, part count and texture budgets.
5. Solo or multiplayer? Co-op, PvP, or single-player with leaderboards? Expected players per server?
6. Scope for this session: a playable vertical slice in one sitting, or a full game plan? (D: vertical slice with one complete core loop.)

**Round B: look and assets (ask when art is in scope)**

7. Art style: chunky cartoon / low-poly / stylised realistic / blocky Roblox / user's own references (ask for 2-3 images or links).
8. Where should art come from? Offer the routing in `roblox-dev-workflow` section 4: Roblox Cube and Assistant generation (fast, static props), Blender (anything that must animate, exact shapes, kits), Creator Store (fillers, audio), or user-supplied files.
9. Is the user willing to approve anything that spends money or Robux (ads, paid uploads, Hyper3D/Meshy credits)? (D: no spend without asking.)

**Round C: accounts and publishing (ask before the first publish)**

10. Who owns the game: personal account or group? (Assets must be owned by the account/group that owns the place, or they can render blank.)
11. Is there an existing experience/universe, or should a new private test place be made? Is there a separate dev place? (D: separate dev place plus a private test place; never open the live place in Studio.)
12. Is the creator account age-verified or 2-step enabled? Needed to publish for Roblox Kids/Select audiences, see `roblox-design-and-launch` section 4.
13. API key available? Tell the user which scopes are needed and that the key goes into an env file, never into chat.

**Round D: monetization and live ops (ask when the user says "launch" or "earn")**

14. Planned monetization: none yet / passes / developer products / subscriptions / paid access / ads. (D: none in the prototype; add after the core loop is fun.)
15. Update cadence and events planned?

## Step 3. Write the brief

Create `docs/brief.md` (and a short `CLAUDE.md` pointing to it) with:

```
# <Game name> brief
Pitch: one sentence
Core loop: minute-to-minute / most-repeated action / progression engine
Genre + camera + platforms + audience (content maturity target)
Art direction: style, palette, references, source per asset class (Cube / Blender / Store)
Environment: OS, toolchain versions, MCP servers connected, dev place id, test place id
Scope of this session: milestone + done-definition + out of scope
Open questions and defaults assumed (D)
```

Show the brief to the user and ask for one confirmation. Then hand over to `roblox-dev-workflow`.

## Rules

- Prefer multiple-choice questions with a recommended default over open-ended ones.
- Ask about audience age before designing monetization or chat features; it changes what is allowed.
- Record decisions as they are made. A decision not in `docs/brief.md` will be forgotten after the session is compacted.
- Do not start Blender, generate meshes or write gameplay code until the pitch, genre, audience and art source are known.
