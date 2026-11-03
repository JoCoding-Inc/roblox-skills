# roblox-skills

Claude Code skills for building Roblox games with an AI agent, from JoCoding. They add to [roblox-brain](https://github.com/TabooHarmony/roblox-brain), the general 29-skill Roblox pack, with what we learned shipping test games.

| Skill | Use it for |
|---|---|
| `roblox-game-pipeline` | Run first: staged game-development workflow (probe, vision, platform-fit advice, style board with reference images, cinematics and small decisions as decision cards, choice of auto/staged and solo/subagents, plan, build loop with evidence, release) |
| `roblox-cinematics` | Whether and how to add intros, boss reveals and unlock moments: questions, budgets, shot list, skip and restore rules, testing through Studio MCP |
| `roblox-project-intake` | Run first: probes the machine (Studio MCP, Blender, Rojo, Open Cloud), interviews the user about the game, audience and art sources, writes `docs/brief.md` |
| `roblox-engine-2026` | Current engine rules: task scheduler, deferred events, Parallel Luau, types, flex layouts and UI styling, Input Action System, streaming, memory budgets, remote security checklist, platform chat change |
| `roblox-dev-workflow` | Idea to live ops in 9 phases, project layout, and which tool makes each asset (Cube, procedural models, Blender, Creator Store) |
| `roblox-studio-ai-tools` | Built-in Studio MCP server (setup, full tool map), Assistant (Planning Mode, skills, BYOK), generation commands, headless Luau |
| `roblox-design-and-launch` | Core loops, prototyping, onboarding, monetization and DevEx, content maturity and age rules, AI rules, icon/thumbnail and publish checklist |
| `roblox-launch-benchmarks` | Pre-launch checklist with values measured from live top-chart games: thumbnails, description length, players per server, game pass count and prices, like ratio. Refresh script in `scripts/benchmark` |
| `roblox-release-automation` | What an agent can automate in a release (Open Cloud publish, server restart, passes, products, config) vs what the user must do (create game, maturity questionnaire, icon, thumbnails, public release), API key scopes per step, and what to ask when a permission is missing |
| `roblox-pitfalls` | Field notes: Open Cloud publish 409, Studio vs live asset loading, Creator Store 403, testing through Studio MCP with bot scenarios, Roblox Cube mesh generation, teleport/DataStore/light/texture/terrain limits |
| `roblox-blender-export` | Blender meshes into Studio: scale, pivot, axis, FBX export call, palette textures, triangle budgets, upload |
| `roblox-store-art-pack` | Any genre: Creator Store picks and quarantine, map composition check, game icon and thumbnails. Bright world palette for simulator/tycoon games |
| `roblox-ui-genre-studs` | Simulator/tycoon games only: stud-style UI with outlines, lips, gradients, HUD zones, motion |

## Install

Install all of roblox-brain (29 skills) first, then this plugin. Skills only load their full text when a task needs them, so keeping every skill installed costs little and covers every genre.

```bash
npx -y skills add TabooHarmony/roblox-brain -g -a claude-code -s '*' -y
```

Keep `-g -a claude-code`: run from inside Claude Code without flags, the skills CLI installs into the current project folder (`./.claude/skills`, `./.agents/skills`) without asking.

In Claude Code:

```
/plugin marketplace add JoCoding-Inc/roblox-skills
/plugin install roblox-skills@roblox-skills
```

Without the plugin system, copy `plugins/roblox-skills/skills/*` into `~/.claude/skills/`. Use one way, not both: a manual copy plus the plugin gives every skill twice (`roblox-pitfalls` and `roblox-skills:roblox-pitfalls`).

Check the install with files, then restart Claude Code so new skills show up:

```bash
ls ~/.claude/skills | grep -c '^roblox-'   # 29 from roblox-brain
claude plugin list                          # roblox-skills@roblox-skills enabled
```

Skills load on their own when the task matches their description. To update, run `/plugin marketplace update roblox-skills`.

## Works best with

- Roblox Studio MCP (built into Studio): Assistant > ... > Manage MCP Servers > Enable Studio as MCP server, then Quick connect > Claude Code, or register it by hand. macOS: `claude mcp add Roblox_Studio -s user -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`; Windows: `claude mcp add Roblox_Studio -s user -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"`. Check with `claude mcp list` (Connected). The old Rust server is archived
- Rojo, Lune, selene, StyLua, luau-lsp, Wally; install them with Rokit
- Blender MCP (`claude mcp add blender uvx mcp-for-blender`) for custom meshes and rigs; read the safety notes in `roblox-blender-export` section 9

## License

MIT. Credits for sources are in [NOTICE.md](NOTICE.md).
