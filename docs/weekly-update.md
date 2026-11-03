# Skill update runbook

Goal: keep `plugins/roblox-skills/skills/` right about what the live docs and Studio MCP do NOT carry. API signatures are not copied into the skills: they are looked up live (`roblox-dev-workflow` section 0).

## Weekly (about 30 minutes)

1. Sync: `git checkout main && git pull`; branch `docs/weekly-YYYY-MM-DD`.
2. Drift check: `python3 -I scripts/check_apis.py`. Also parse every SKILL.md front matter with a YAML parser: a plain-scalar line with ": " in `sources` breaks the whole header and the skill loses its description and triggers. Fix names that vanished or were deprecated; add intentional mentions to `scripts/check_apis.ignore` with a reason.
3. Research only what the reference lacks (primary sources first):
   - DevForum weekly recaps (search "Weekly Recap", last 7 days) and Studio release notes (`devforum.roblox.com/c/updates/release-notes/62`): betas and their flags, rollout dates, deprecations, policy and discovery changes, known bugs.
   - Roblox policy, creator-program or payout changes (see `roblox-design-and-launch` section 8 pages).
4. Triage: grep each item against the skills; skip what is covered or is only an API signature. Record facts you read, with date and source.
5. Test in Studio through MCP on a scratch place only (never a user's game): does it exist, is a beta flag needed, any known bug. Stop play afterwards. Note what could not be tested. Scratch place on macOS: build a blank place with `rojo build -o scratch.rbxl` (a project with a Baseplate part), start `/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio -localPlaceFile <abs path>` in the background (`open -n -a RobloxStudio --args ...` did not start it on 2026-11-03), wait for it in `list_roblox_studios`, and close it by PID at the end (`roblox-game-pipeline` rule 8).
6. Edit the matching SKILL.md (smallest diff; status board in `roblox-engine-2026` section 6), mark unverified items, update `last_reviewed`.
7. Commit (English, conventional commits), push, open a PR. Merge only after the user agrees.

## Monthly

- Re-run the `roblox-launch-benchmarks` scripts (see `scripts/README.md` there) and compare with `roblox-launch-benchmarks`; update the table if a value moved by more than a quarter. Also re-check the platform play-pattern numbers in `roblox-design-and-launch` section 1a.
- Check the Studio MCP tool list (`list_skills`, tool names) against `roblox-studio-ai-tools`.
- Refresh the snapshot in `roblox-market-research` section 7 (`market.py charts`, `history` for the top 5) and move its expiry date; re-check that each site in the section 3 catalog still loads and still allows automated reads.
- Re-read the setup pages in `roblox-project-intake` step 1c (Studio MCP, official Roblox Studio plugin README, rokit README) and fix changed menu paths or commands.
