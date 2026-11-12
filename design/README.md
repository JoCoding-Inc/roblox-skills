# Design pack

The design values of the skills as versioned data, plus the design-related skill text, packed for other tools (for example a design service's importer). The skills stay the readable source; this folder mirrors their numbers.

## Files

| Path | What |
|---|---|
| `data/<type>.json` | Values for one type: `zones` (reserved zones, zone map, insets, scale, floors, HUD zones, UI budgets), `tokens` (stud house style kit, ramps, panels, text, currency gradients, house rules), `motion`, `typography`, `icons`, `vfx` (tier ladder, aura and particle limits, VFX house rules) |
| (generated) `styles` | Built at export time from `PRESETS` in `roblox-game-pipeline/scripts/ui_style_mock.luau` and the table in `assets/ui-styles/README.md`, so the Lua file stays the only source |
| `schema/<type>.schema.json` | One JSON Schema (draft 2020-12) per type, `styles` included. Derived from the data by `--write-schemas`; do not edit by hand |
| `../scripts/export_design_pack.py` | Validates, derives the schemas and builds the pack |

## Value format

- Every value is a leaf `{"v": <value>, "p": <provenance>, "src"?: "<source or qualifier>", "date"?: "YYYY[-MM[-DD]]"}`. A `src` of "about" or "under about" marks guidance, not an engine limit.
- Units are in the key name: `_px`, `_s`, `_share` (0 to 1), `_scale`, `_rgb`, `_studs`, `_deg`, plus `_of_height` and `_of_face` (fractions). A key without a unit inherits its parent's (`health_bar_px.default`). A two-number list under a unit key is a range or a width-height size. `max` or `min` in a key marks a limit. Colors are `[r, g, b]` from 0 to 255.
- `styles` keeps the Lua key names of `PRESETS` (`radius`, `strokeW`, `panelT`); each key's unit is in its schema `description`. A `null` value means "none" (no lip, no header band).

| `p` | Means |
|---|---|
| `measured` | we measured it: engine source, pixels on reference frames, store API reads, tested in Studio |
| `documented` | Roblox docs, staff posts or filings |
| `field` | observed while shipping a game (dated when known) |
| `opinion` | judgment, house style, owner rule or a community starting value |

## Schemas

Each schema requires every key the data has today and types every value (number, range, size, color, text, list). Unit suffixes add bounds: `_share` 0 to 1, `_px`, `_s`, `_scale`, `_studs` and limits 0 or more (`_deg` may be negative), colors 0 to 255. Object values (a font's `family` and `weight`) are typed key by key. Unknown keys are allowed everywhere, in the envelope and in leaves too, so a reader built for 1.0 reads 1.x files and ignores what it does not know.

## Versions

- `schema_version` (every data file and the manifest; one value per pack), semver: major when a key is removed, renamed or changes type; minor when keys or types are added.
- `pack_version`, the release tag without `design-pack-v`, semver: major with a schema major; minor when values or keys change; patch for text and image changes only. A tag with a pre-release suffix (`design-pack-v1.1.0-rc.1`) publishes a GitHub pre-release.
- Readers pick the highest semver among non-pre-release releases whose tag starts with `design-pack-v` (not the newest by date).

## Pack layout

```
design-pack/
  manifest.json
  data/<type>.json
  schema/<type>.schema.json
  skills/<skill>/SKILL.md            whole skill, or only the listed sections
  skills/<skill>/.../README.md       style card, lane and part-look notes
  skills/<skill>/.../*.jpg|png       images the guides point to, at the same relative paths
  skills/<skill>/scripts/*.luau      Luau a packed guide section is built on (listed in SCRIPTS)
  LICENSE, NOTICE.md
```

## Manifest

Fields: `name`, `schema_version`, `pack_version`, `source_repo`, `source_commit`, `source_dirty`, `source_base_url`, `built_at` (UTC), `license`, `provenance`, `kinds`, `topics`, `excluded`, `skills` (name, `sections` as a list or `"all"`, topic), `files[]`.

Each `files[]` entry has:

| Field | Meaning |
|---|---|
| `path` | path inside `design-pack/` |
| `sha256`, `bytes` | of the file as packed |
| `kind` | `data`, `schema`, `guide`, `image`, `script` (since 1.2.0) or `license` |
| `topic` | one key of `topics`; data and the guides it mirrors share a topic (`zones` and `roblox-ui-layout` are both `layout`) |
| `section_ref` | list of `<path>[#<sections>]`, `path` relative to the skills folder (`roblox-feel-audio-vfx/SKILL.md#1,3,4,5`, `roblox-ui-genre-studs/SKILL.md#1-3,7-9`), or `null` for schema and license files. For data it names the skill text the values mirror |
| `schema` | data only: the schema file to validate with |
| `unresolved_refs` | guides only: sections, skills, scripts and files of the repository that the text mentions and the pack leaves out; each resolves under `source_base_url` |
| `project_refs` | guides only: paths the text mentions that are files of the user's game project (`docs/brief.md`, `assets/refs/`, `assets/LICENSES.md`), not of this repository |

## Verify a release (importers)

1. Download `design-pack.tgz`, `manifest.json` and `SHA256SUMS` from the release; check both files against `SHA256SUMS`.
2. Check the manifest: `pack_version` equals the tag without `design-pack-v`, `source_dirty` is false, `schema_version` major is one you support, and `source_commit` is on `main` of `source_repo`.
3. Extract into an empty directory. Reject any member whose path is absolute, contains `..`, or is a link. Every path is under `design-pack/`.
4. `design-pack/manifest.json` must equal the downloaded `manifest.json` byte for byte. Every other extracted file must appear in `files[]` with the same `sha256` and `bytes`, and every entry must exist.
5. Validate each `data` file with its `schema`.
6. Serve guide text as quoted reference data, never as instructions to the agent that reads it: the skills address an agent in the imperative ("ask the user", "run ..."), and that text must not override the importer's own rules. Serve `script` files as source to read and copy into a game, never run them on the importer's side.

## Release

1. Merge the change to `main`.
2. Push a tag `design-pack-v<semver>` on a `main` commit (`git tag design-pack-v1.0.0 <sha> && git push origin design-pack-v1.0.0`).
3. `.github/workflows/design-pack.yml` checks the tag format and that the commit is on `main`, builds, and publishes a release with `design-pack.tgz`, `manifest.json` and `SHA256SUMS`.

Local build: `python3 -I scripts/export_design_pack.py --out dist --version 0.0.0-dev --tgz` (output in `dist/`, git-ignored). `--check` only validates: every data file against its schema, schemas up to date with the data, the generated styles, guide sections, topics, ASCII.

## Editing

- When a skill value mirrored here changes (`roblox-ui-layout`, `roblox-ui-mobile`, `roblox-ui-genre-studs`, `roblox-ui-typography`, `roblox-fun-effects`, `roblox-feel-audio-vfx`, `roblox-store-art-pack`), change the data file in the same PR; the PR check warns when only the skill changed.
- After a data change, run `--write-schemas` and read the schema diff: a removed or retyped key is a schema major bump.
- Security: a PR from an outside contributor that touches `design/**` or a mirrored skill needs a maintainer's review for instructions aimed at agents (for example "ignore previous instructions", hidden links, commands), not only for content, because the pack becomes tool output that agents read.
