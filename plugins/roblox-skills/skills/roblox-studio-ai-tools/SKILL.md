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

The Studio MCP server is **built into Roblox Studio** (stdio, local process). The older Rust server (`Roblox/studio-rust-mcp-server`, tools `run_code`, `insert_model`, `run_script_in_play_mode`, `get_studio_mode`) is archived; migrate off it and remove its `Roblox_Studio` entry first so the names do not clash.

1. Update Studio to the latest version.
2. Studio: **Assistant** > **...** > **Manage MCP Servers** > turn on **Enable Studio as MCP server**.
3. Connect the client, either:
   - Quick connect: **Assistant Settings** > **MCP Servers** > **Quick connect**, toggle Claude Code (also lists Claude Desktop, Cursor, Codex CLI, Gemini CLI, Antigravity, VS Code). Install the client first and restart Studio if it is missing.
   - CLI command (macOS): `claude mcp add Roblox_Studio -s user -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
   - CLI command (Windows): `claude mcp add Roblox_Studio -s user -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"`
   - JSON: macOS `{"mcpServers":{"Roblox_Studio":{"command":"/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"}}}`; Windows `{"mcpServers":{"Roblox_Studio":{"command":"cmd.exe","args":["/c","%LOCALAPPDATA%\\Roblox\\mcp.bat"]}}}`
4. Restart Claude Code. Verify: `claude mcp list` shows Connected, and Studio's Manage MCP Servers panel shows a green client count.
5. Troubleshoot: restart both apps, check the binary path exists, check JSON commas.

Security: any connected client can read and modify the open places. Connect only clients you trust, and keep execute tools on prompt in Claude Code's permissions.

## 2. Tool map (built-in server)

Every call takes a `studio_id`. Call `list_roblox_studios` first (name, instance id, place id) and pass the id of your dev place, especially with several windows or agents.

| Group | Tools | Notes |
|---|---|---|
| Scripts | `script_read`, `multi_edit`, `script_search`, `script_grep` | Dot-notation paths; `multi_edit` creates a script if the path is new and needs `datamodel_type` Edit. `script_search` returns 10 fuzzy matches, `script_grep` 50 |
| Generate | `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished` | See section 4 |
| Assets | `search_asset`, `insert_asset`, `upload_image`, `store_image` | `search_asset` covers Creator Store and your inventory (user, group, universe) with type, price, tag filters. `store_image` turns a local file into a URI for reference images |
| Explore | `search_game_tree`, `inspect_instance`, `subagent` | `subagent` types: `explore` (investigate game state) and `playtest` (run gameplay scenarios and verify outcomes) |
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
- **Slash commands:** `/generate_mesh <text or image>` (not both), `/generate_procedural_model <text or image>`. A selected Part is used as a bounding box. Optional max triangle count (default 10,000).
- **Screen capture subagent** and chat history exist; plans and chats are not visible to collaborators.
- **Skills:** a skill is one Markdown file with frontmatter `name` (lowercase, no `rbx-` prefix), `description`, `enabled`, loaded automatically when a request matches the description or by typing `/` in the composer. Skills belong to the Roblox account, so they apply to every place. Built-in Roblox skills: `rbx-create-skill`, `rbx-debug` (breakpoints, call stacks), `rbx-device-simulator-lua` (device presets and UI screenshots), `rbx-docs-search`, `rbx-perf-profiling` (MicroProfiler analysis), `rbx-scene-analysis` (rendering cost, memory, leaks, asset inventory), `rbx-unit-test` (Jest-Lua/TestEZ). Duplicate one to customise it; the original is then disabled automatically.
- **Bring your own key:** **Assistant > ... > Manage API Keys**, choose Anthropic, OpenAI or Google Gemini, paste the key, choose the model. The key is typed in Studio, never into chat.
- **External MCP servers** can also be connected into Assistant (Manage MCP Servers).

## 4. Generating content

| Tool | Use | Notes |
|---|---|---|
| `generate_mesh` | One static textured mesh | Prompt rules and failure modes in `roblox-pitfalls` section 5. Reference image allowed instead of text. Segmentation: none for static props; named parts (max 8) for pieces that must move, with function names such as `door`, `lid`, `lever` |
| `generate_material` | Restyle parts | Returns the base material plus a variant name to apply; lightweight form of the Material Generator |
| `generate_procedural_model` | Primitive-part objects with parameters | Lands in a `GeneratedFolder`; behaves like normal parts; works with undo, Team Create, replication. **50 per rolling 24 hours** |
| Texture Generator / Material Generator (Studio tools) | Textures for meshes, tileable materials | Prefer these for surface looks on custom meshes |

Generative AI rules (official): Roblox AI services (`GenerationService`, `TextGenerator`) moderate inputs and outputs and aim for All Ages content. If a game lets players have extended conversation with a chatbot-like AI, or the AI remembers earlier sessions, answer **Yes** to the Extended AI question; the game then needs a Restricted label (18+). Third-party model output is the creator's responsibility and chat text must still go through `TextChatService`. Details: `roblox-design-and-launch` section 4.

## 5. Studio from the command line

Studio accepts documented flags (others are internal): `--task EditPlace --placeId <id> --universeId <id>` opens the latest published place; `--task EditPlaceRevision ... --placeVersion <n>` opens an older version; `--task EditFile` opens a local file. Launched this way Studio streams verbose logs to stdout. Use it to open the right dev place before MCP work.

## 6. Run Luau headlessly (Open Cloud Luau Execution)

For CI, mass edits and automated checks without Studio. `POST` a task under the place (optionally a place version), poll its state, read logs. Auth: API key in `x-api-key` with `universe.place.luau-execution-session:write` (and `:read` to poll). The docs list a rate limit of 45 calls per minute per key owner or IP; the docs warn that a missing scope can make a call look successful without applying changes, so read the result back. Wrappers such as `rbxcloud luau execute` exist. Typical CI: `rojo build -o game.rbxl` > publish to a test place > Luau Execution test run > fail the job on FAIL lines.

## 7. Choosing Studio MCP vs Assistant vs Open Cloud

| Task | Use |
|---|---|
| Edit many files, refactor, git, tests | Claude Code with Rojo |
| Inspect or change the open place, playtest, screenshots | Studio MCP |
| Generate a mesh/material/procedural model from inside Studio with human review | Assistant (or the MCP generate tools) |
| Plan with approval gate inside Studio | Assistant Planning Mode |
| Publish, upload assets, run tests with no Studio window | Open Cloud |
