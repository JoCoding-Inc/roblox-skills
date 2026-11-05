# roblox-skills

Claude Code skills for building Roblox games with an AI agent, from JoCoding. They cover the whole path from planning interview to release, with what we learned shipping test games.

| Skill | Use it for |
|---|---|
| `roblox-game-pipeline` | Run first: staged game-development workflow (tool check, vision, live-market and platform-fit advice, style board with eight reference lane cards, four basic UI style cards and a Studio UI mockup script, cinematics and small decisions as decision cards, choice of auto/staged and solo/subagents, plan, build loop with evidence, release) |
| `roblox-market-research` | Judge an idea against the live market: trending and rising charts, keyword competition, competitor teardown, hit decay curves, and a catalog of sites and public APIs for Roblox charts and keywords. `scripts/market.py` needs only Python 3 |
| `roblox-combat-tools` | Weapons and Tools, hit detection, server validation, lag compensation and Server Authority caveats |
| `roblox-match-flow` | Rounds, lobbies, matchmaking and teleports, reserved servers, leaderboards, AFK and shutdown handling |
| `roblox-cinematics` | Whether and how to add intros, boss reveals and unlock moments: questions, budgets, shot list, skip and restore rules, testing through Studio MCP |
| `roblox-data-saves` | Player saves: what to store, DataStore layout, session lock, retries, schema versions and migrations, test cases, limits, deletion rules |
| `roblox-bots-npcs` | NPCs, enemies, allies and bot fill so a solo player never waits in an empty server: pathfinding, state machines, server cost, tests |
| `roblox-feel-audio-vfx` | Game feel: feedback map, audio objects and mix, particle and effect budgets, lighting and atmosphere, mobile checklist |
| `roblox-fun-effects` | Make effects fun, not only working: fun card, rarity tier ladder, roll and hatch reveal beats, auras and status others see, announcements and clip sharing, mutations, hit stop and finishers, odds and flashing guard rails |
| `roblox-character-motion` | Custom character motions (exercise loops, sitting, interactions, emotes): which authoring path, contact-first solve and bake (tested push-up baker), runtime IK, upload for live servers, measuring contacts |
| `roblox-project-intake` | Run first: tool check (Studio, Studio MCP and git required; Script Sync or Rojo, Blender MCP, Open Cloud key optional) with step-by-step setup from the live docs, interview about the game, audience and art sources, writes `docs/brief.md` and a project `CLAUDE.md` |
| `roblox-engine-2026` | Current engine rules: task scheduler, deferred events, Parallel Luau, types, flex layouts and UI styling, Input Action System, streaming, memory budgets, remote security and server-side exploit detection, Server Authority, platform chat change, status board of betas and rollouts |
| `roblox-dev-workflow` | Idea to live ops in 9 phases, project layout, and which tool makes each asset (Cube, procedural models, Blender, Creator Store) |
| `roblox-studio-ai-tools` | Built-in Studio MCP server (setup, full tool map), Assistant (Planning Mode, skills, BYOK), generation commands, headless Luau |
| `roblox-design-and-launch` | Core loops, prototyping, onboarding, monetization and DevEx, content maturity and age rules, AI rules, icon/thumbnail and publish checklist, localization setup. `scripts/l10n_sync.py` pushes UI text to the translation table |
| `roblox-launch-benchmarks` | Pre-launch checklist with values measured from live top-chart games: thumbnails, description length, players per server, game pass count and prices, like ratio. Refresh scripts in the skill's `scripts/` |
| `roblox-release-automation` | What an agent can automate in a release (Open Cloud publish, server restart, passes, products, config) vs what the user must do (create game, maturity questionnaire, icon, thumbnails, public release), API key scopes per step, and what to ask when a permission is missing |
| `roblox-pitfalls` | Field notes: Open Cloud publish 409, Studio vs live asset loading, Creator Store 403, testing through Studio MCP with bot scenarios, Roblox Cube mesh generation, teleport/DataStore/light/texture/terrain limits |
| `roblox-blender-export` | Blender meshes into Studio: scale, pivot, axis, FBX export call, palette textures, triangle budgets, upload |
| `roblox-store-art-pack` | Any genre: Creator Store picks and quarantine, map composition check, game icon and thumbnails. Bright world palette for simulator/tycoon games |
| `roblox-ui-typography` | Fonts and text for any genre: built-in and Creator Store fonts (no uploads), display and body pair per genre, phone readability, stroke and text performance, numbers, fonts for Korean and other languages |
| `roblox-ui-layout` | Any genre: one placement and size standard for phone, tablet, desktop and console, with Roblox's reserved zones in px (top bar, thumbstick, jump, hotbar, chat), insets, scaling, touch and text floors, TV-safe area and a device check script |
| `roblox-ui-genre-studs` | Simulator/tycoon games only: stud-style UI with outlines, lips, gradients, HUD zones, motion |

## Install

Skills only load their full text when a task needs them, so keeping every skill installed costs little.

In Claude Code:

```
/plugin marketplace add JoCoding-Inc/roblox-skills
/plugin install roblox-skills@roblox-skills
```

Without the plugin system, copy `plugins/roblox-skills/skills/*` into `~/.claude/skills/`. Use one way, not both: a manual copy plus the plugin gives every skill twice (`roblox-pitfalls` and `roblox-skills:roblox-pitfalls`).

Check the install with files, then restart Claude Code so new skills show up:

```bash
claude plugin list                          # roblox-skills@roblox-skills enabled
```

Skills load on their own when the task matches their description. To update, run `/plugin marketplace update roblox-skills`.

## Starting a game

- Mention Roblox in the first message: "I'm making a Roblox game, what do you think of a gym tycoon?" loads `roblox-game-pipeline` and `roblox-market-research`. Without the word Roblox, a generic brainstorming skill may answer instead.
- `/roblox-game-pipeline` always works.
- After the first session, intake writes a project `CLAUDE.md` whose first line marks the folder as a Roblox project, so "I'm making a game" alone is enough there.
- The first step is a tool check: the agent shows which tools are connected, says what each one unlocks, sets up the required ones with you, and lets you skip optional ones.
- When the plan is done, the agent asks what to see first: a core-fun prototype to playtest, concept images, a concept trailer, or straight to the full build.

## Works best with

- Roblox Studio MCP: easiest is the official plugin (`/plugin`, search **Roblox Studio**, then ask "Get me set up with Roblox Studio"). Manual: Studio Assistant > ... > Settings > MCP Servers > Enable Studio as MCP server, then Quick connect > Claude Code, or register it by hand. macOS: `claude mcp add Roblox_Studio -s user -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`; Windows: `claude mcp add Roblox_Studio -s user -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"`. Check with `claude mcp list` (Connected). The old Rust server is archived
- Rojo, Lune, selene, StyLua, luau-lsp, Wally; install them with Rokit
- Blender MCP (`claude mcp add blender uvx mcp-for-blender`) for custom meshes and rigs. In Blender, turn the add-on on first: Edit > Preferences > Add-ons > MCP for Blender (tick it), then press Connect to MCP server in the viewport `N` panel. Read the safety notes in `roblox-blender-export` section 9
- Optional: RoDesigner MCP, a Roblox design MCP for images, video, icons, textures and 3D with the project's style pack applied automatically (paid; every step has a free route, and an image generator the user has connected works too): a game project with a locked art style, concept images and a concept trailer, props and pets as textured GLB, icons, textures, logo and loading art. Every paid call is quoted (`dry_run`) and asked first. Setup: TODO(RoDesigner launch): setup page and the `claude mcp add` command. Without it the agent uses written storyboards, Studio screenshots, Roblox Cube and Blender

RoDesigner is not affiliated with or endorsed by Roblox Corporation.

## Keeping it current

The skills do not copy API signatures; the agent looks them up live through the Studio MCP (`list_skills`, `http_get`). The skills hold workflow, judgment, policy, market data, beta status and pitfalls. Market numbers come live from `roblox-market-research/scripts/market.py`; the snapshot in that skill expires about 2026-12-15. `python3 -I scripts/check_apis.py` checks that every API name used in the skills still exists in the live reference. The update routine is in `docs/weekly-update.md`.

## License

MIT. Credits for sources are in [NOTICE.md](NOTICE.md).
