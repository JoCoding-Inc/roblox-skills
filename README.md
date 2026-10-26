# roblox-skills

Claude Code skills for building Roblox games with an AI agent, from JoCoding. They add to [roblox-brain](https://github.com/TabooHarmony/roblox-brain), the general 29-skill Roblox pack, with what we learned shipping test games.

| Skill | Use it for |
|---|---|
| `roblox-pitfalls` | Field notes: Open Cloud publish 409, Studio vs live asset loading, Creator Store 403, testing through Studio MCP with bot scenarios, teleport/DataStore/light limits |
| `roblox-blender-export` | Blender meshes into Studio: scale, pivot, axis, FBX export call, palette textures, triangle budgets, upload |
| `roblox-store-art-pack` | World palette and composition, Creator Store picks and quarantine, game icon and thumbnails |
| `roblox-ui-genre-studs` | Simulator/tycoon stud-style UI: outlines, lips, gradients, HUD zones, motion |

## Install

Recommended: install roblox-brain first, then this plugin.

```bash
npx skills add TabooHarmony/roblox-brain
```

In Claude Code:

```
/plugin marketplace add JoCoding-Inc/roblox-skills
/plugin install roblox-skills@roblox-skills
```

Without the plugin system, copy `plugins/roblox-skills/skills/*` into `~/.claude/skills/`.

Skills load on their own when the task matches their description. To update, run `/plugin marketplace update roblox-skills`.

## Works best with

- Roblox Studio MCP (Studio: enable "Studio as MCP server")
- Rojo, Lune, selene, StyLua, luau-lsp
- Blender MCP for custom meshes

## License

MIT. Credits for sources are in [NOTICE.md](NOTICE.md).
