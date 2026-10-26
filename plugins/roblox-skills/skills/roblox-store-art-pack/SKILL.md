---
name: roblox-store-art-pack
description: "Use for any genre when picking and quarantining Creator Store models, checking map composition, or making the game icon and thumbnails. Its world palette (section 1) is for bright daylight simulator/tycoon games only."
when_to_use: "Also when inserting Toolbox/Creator Store models, before publishing or running ads (icon/thumbnail CTR), when building an icon family for UI, or when a bright simulator/tycoon scene looks flat, pastel or greybox. Skip section 1 for horror, realistic or night games; use roblox-lighting instead."
last_reviewed: 2026-10-26
sources:
  - https://github.com/blauwtje/roblox-kit (map-building/reference/daylight-look.md, ui-images; MIT)
  - https://github.com/brain-xiang/grok-studio (skills/thumbnail-and-icon; MIT)
  - https://github.com/S4US/Roqer (references/composition.md, core/assets.md; AGPL, rules re-authored)
  - https://github.com/AshExplained/roblox-skills (roblox-creator-store-security-audit; MIT)
  - https://create.roblox.com/docs/production/publishing/experience-icons
  - https://create.roblox.com/docs/production/publishing/thumbnails
  - original (reference frames of Steal An Egg / Steal a Brainrot, 2026-10-26)
---

# World palette, store assets, icon and thumbnails

Pair with `roblox-building` (geometry), `roblox-lighting`, `roblox-blender-export` (custom meshes), `roblox-ui-genre-studs` (UI) and `roblox-security` (inserted scripts).

## 1. Daylight genre world (simulator/tycoon only)

Skip this section for horror, realistic or night games.


- **Lighting:** ClockTime 14, saturated cyan-blue sky `#6FC3F0` with soft white clouds, no fog, a high-key sun and soft shadows.
- **Palette:**

  | Surface | Color |
  |---|---|
  | Grass | `#58B02A` |
  | Asphalt | `#2E3548` with white stripes |
  | Kerbs | `#C9CDD2` |
  | Beige tile | `#D9C7A3` |
  | Trunks | `#6B3F26` |
  | Interior ambient | warm even `#E8D2A8` |

- The Brainrot / Egg look:
  - Studs on floors (`Enum.Material.Studs` or a stud texture), saturated bright green ground, red carpet paths.
  - Dark grey base frames, brown brick perimeter walls, wooden fences.
  - Avoid pastel SmoothPlastic.
- Saturated color goes on what the player uses (machines, pads, shops); the surroundings are calmer.
- **Floor rules:**
  - One slab per area, butted edge to edge. No coplanar overlap; offset decals and paths by 0.05 stud or more.
  - Nothing exactly at y = 0. No step over 0.5 stud.
  - A perimeter wall, never a void edge.
- **Props:**
  - Every visible prop has a color, a real material and bevelled edges, never default grey.
  - Decor gets `CanCollide`, `CanTouch` and `CanQuery` false.
  - Prefer few large readable props over clutter.

## 2. Composition check (run on every area)

- **Edges:** every edge is finished, with no bare slab sides; add trim, kerb or bevel.
- **Relief:** one real height change per area, with the landmark on the high point.
- **Layout:** break straight outlines and perfect rings and grids.
- **Repetition:** two or more templates with unequal weights, full random yaw, scale 0.8-1.25, clusters and clearings.
- **Player scale:**
  - The player is about 5 studs; a door is 4 wide x 7 high; ceilings are 10-14; a counter is 3.5-4.
  - Paths are 6 studs wide or more. Snap structures to a 4/2 stud grid.
- **Simulator layout:**
  - One connected ground. The hub holds the sell/collect pad, shop, egg/lucky altar and rebirth.
  - Hub to the last zone takes under 1 minute at WalkSpeed 16.
  - The first earn loop closes at the hub, 25-35 studs from the pad.
  - The first upgrade comes in about 20 s or less.

## 3. Creator Store / Toolbox assets

Priority:
1. Our own verified art (Blender kit, uploaded under the group).
2. User-provided ids.
3. Creator Store only for essential content.
4. Otherwise omit the decoration.

Never invent ids.

**Image picks:**
1. `search_asset` with the asset type and subject.
2. Read details for several candidates.
3. Use `asset.textureId`, the usable IMAGE id. If it is 0 or absent, discard the candidate; never fall back to the decal id.
4. Check the thumbnail.
5. Pick for coherence of the SET: reject an individually good image whose style clashes.

Probe every image id before relying on it (`roblox-pitfalls` section 4).

**Model inserts (quarantine first):**
- Insert into a quarantine folder.
- Keep meshes, textures and UI art. Delete every script.
- `script_grep` for `require getfenv setfenv loadstring HttpService GetObjects InsertService MarketplaceService DataStore MessagingService TeleportService RemoteEvent string.char string.reverse`.
- Red-flag names: AntiLag, MainModule, Loader, Handler, Update, Version, HDAdmin, Free, Fix.
- Verdict for each insert: visual-only / reviewed / quarantine / reject. `insert_asset` strips scripts; recreate the behavior yourself.
- Assets owned by someone else need user consent for use. Record the source in the licenses file.

## 4. Icon family (UI images)

- Same canvas (128 px, drawn at 2x), same outline weight, highlight and light direction, flat colors, no text inside.
- 1024 px or less per image. Many icons go on one sprite sheet (8x8 of 128 px).
- 9-slice needs a slice centre; tune `SliceScale`.
- Fixed words (the logo) may be images; translatable words stay TextLabels.

## 5. Game icon and thumbnails

**Icon:**
- 512x512 and still legible at about 150x150; one per locale; moderated.
- One bold subject, a strong silhouette, 2-3 dominant colors, a high-contrast rim light, at most a 1-2 word title, filling the frame, no thin borders.

**Thumbnails:**
- 16:9 at 1920x1080 (jpg, png, gif, tga or bmp), under 3 MB, up to 10 per game. Non-16:9 images get stretched.
- Show an action moment from the core loop, with the character at a rule-of-thirds point and a clear foreground, midground and background.
- Colors saturated but true to the game; an optional short title at top centre.
- Make 2-3 variants for A/B. Genre thumbnails use big stroked text, a "YOU!" arrow, an exaggerated scale moment and a bright sky.

**Truthfulness:** no misleading UI or gameplay, no other games' characters or brand logos, no "FREE ROBUX" or fake "UPDATE" bait.

**Making them:**
- Path 1: a Blender diorama of the game's own assets. 35-50 mm lens for thumbnails, 50-85 mm for the icon, key plus rim light.
- Path 2: Studio `screen_capture` during a playtest with an explicit camera and the HUD hidden (`ScreenGui.Enabled = false`).
- Post-process: crop to the focus point, Lanczos resize, optional outlined title, enforce 3 MB.

**Upload:** manual, in Creator Dashboard (Configurations > Places > Icon / Thumbnails). Open Cloud asset upload does not set the game icon. Never use a .ROBLOSECURITY cookie.
