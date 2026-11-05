# Design pack

The design values of the skills as versioned data, plus the design-related skill text, packed for other tools (for example a design service's importer). The skills stay the readable source; this folder mirrors their numbers.

## Files

| Path | What |
|---|---|
| `data/<type>.json` | Values for one type: `zones` (reserved zones, zone map, insets, scale, floors, HUD zones, UI budgets), `tokens` (stud house style kit, ramps, panels, text, currency gradients, house rules), `motion`, `typography`, `icons`, `vfx` (tier ladder, aura and particle limits, VFX house rules) |
| `schema/<type>.schema.json` | One JSON Schema (draft 2020-12) per type, `styles` included |
| (generated) `styles` | Built at export time from `PRESETS` in `roblox-game-pipeline/scripts/ui_style_mock.luau` and the table in `assets/ui-styles/README.md`, so the Lua file stays the only source |
| `../scripts/export_design_pack.py` | Validates and builds the pack |

## Value format

Every value is a leaf `{"v": <value>, "p": <provenance>, "src"?: "<source or qualifier>", "date"?: "YYYY-MM[-DD]"}`. Units are in the key name (`_px`, `_s`, `_share`, `_scale`, `_rgb`, `_studs`, `_deg`); a two-number list under a unit key is a range or a width-height size. Colors are `[r, g, b]` from 0 to 255.

| `p` | Means |
|---|---|
| `measured` | we measured it: engine source, pixels on reference frames, store API reads, tested in Studio |
| `documented` | Roblox docs, staff posts or filings |
| `field` | observed while shipping a game (dated when known) |
| `opinion` | judgment, house style, owner rule or a community starting value |

`schema_version` (in every data file and the manifest) is semver: a major bump breaks readers, a minor bump only adds keys or types. Unknown keys are allowed in most groups so minor versions stay readable.

## Pack layout

```
design-pack/
  manifest.json
  data/<type>.json
  schema/<type>.schema.json
  skills/<skill>/SKILL.md            whole skill, or only the listed sections
  skills/<skill>/.../README.md       style card, lane and part-look notes
  skills/<skill>/.../*.jpg|png       images the guides point to (relative paths still work)
  LICENSE, NOTICE.md
```

`manifest.json`: `name`, `schema_version`, `pack_version`, `source_repo`, `source_commit`, `source_dirty`, `built_at` (UTC), `license`, `provenance` (the tag vocabulary), `kinds`, `skills` (name, `sections` as a list or `"all"`, topic) and `files[]` with `path`, `sha256`, `bytes`, `kind` (`data`, `schema`, `guide`, `image`, `license`), `topic`, `section_ref` (for example `roblox-feel-audio-vfx/SKILL.md#1,3,4,5`) and, for data, `schema`.

## Release

1. Merge the change to `main`.
2. Push a tag `design-pack-v<version>` on a `main` commit (`git tag design-pack-v1.0.0 <sha> && git push origin design-pack-v1.0.0`).
3. `.github/workflows/design-pack.yml` checks that the commit is on `main`, builds, and publishes a GitHub release with `design-pack.tgz` and `manifest.json`. Readers take the newest release whose tag starts with `design-pack-v`.

Local build: `python3 -I scripts/export_design_pack.py --out dist --version 0.0.0-dev --tgz` (output in `dist/`, git-ignored). `--check` only validates: schemas, every data file, the generated styles, guide sections, ASCII.

## Editing

When a skill value mirrored here changes (`roblox-ui-layout`, `roblox-ui-genre-studs`, `roblox-ui-typography`, `roblox-fun-effects`, `roblox-feel-audio-vfx`, `roblox-store-art-pack`), change the data file in the same PR; the PR check warns when only the skill changed. Pack text becomes tool output that agents read: review outside PRs that touch design sections for injected instructions as well as for content.
