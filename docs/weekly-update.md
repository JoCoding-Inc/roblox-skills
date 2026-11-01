# Weekly skill update runbook

Run once a week. Goal: keep the skills in `plugins/roblox-skills/skills/` current with Roblox releases and trends, and verify claims in Studio.

1. Sync: `git checkout main && git pull`; branch `docs/weekly-YYYY-MM-DD`.
2. Research (primary sources first):
   - DevForum weekly recaps (search "Weekly Recap" for the last 7 days, extract each; follow links to betas, deprecations, policy posts).
   - Studio release notes (`devforum.roblox.com/c/updates/release-notes/62`) and `github.com/Roblox/creator-docs` commits.
   - Trends: top and trending charts, notable new genres, Roblox policy or discovery changes.
2b. Re-run `scripts/benchmark` (see its README) and compare with `roblox-launch-benchmarks`; update the table if a value moved by more than a quarter.
3. Triage against the skills: grep each item; skip what is already covered. Record only facts you read, with the date and source.
4. Test in Studio through MCP on a scratch place only (never a user's game): API exists, signature, behavior, removed or renamed names. Play-test physics or runtime APIs; stop play afterwards. Note what could not be tested.
5. Edit the matching SKILL.md (smallest diff), mark unverified items as such, update `last_reviewed`.
6. Commit (English, conventional commits), push, open a PR. Merge only after the user agrees.
