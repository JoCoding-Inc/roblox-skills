# roblox-skills

Claude Code skills for building Roblox games with an AI agent, from JoCoding. They add to [roblox-brain](https://github.com/TabooHarmony/roblox-brain), the general 29-skill Roblox pack, with what we learned shipping test games.

| Skill | Use it for |
|---|---|
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

- Roblox Studio MCP: enable "Studio as MCP server" in Studio, then register it in Claude Code. On macOS: `claude mcp add Roblox_Studio -s user -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`. Check with `claude mcp list` (Connected)
- Rojo, Lune, selene, StyLua, luau-lsp
- Blender MCP for custom meshes

## License

MIT. Credits for sources are in [NOTICE.md](NOTICE.md).
