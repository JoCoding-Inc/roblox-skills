---
name: roblox-store-art-pack
description: "Use for any genre when picking and quarantining Creator Store models, checking map composition, or making the game icon, thumbnails, logo and loading screen. Its world palette (section 1) is for bright daylight simulator/tycoon games only."
when_to_use: "Also when inserting Toolbox/Creator Store models, before publishing or running ads (icon/thumbnail CTR), when building an icon family for UI, designing a logo or a custom loading or teleport screen,  or when a bright simulator/tycoon scene looks flat, pastel or greybox. Skip section 1 for horror, realistic or night games; use roblox-lighting instead."
last_reviewed: 2026-11-02
sources:
  - https://github.com/blauwtje/roblox-kit (map-building/reference/daylight-look.md, ui-images; MIT)
  - https://github.com/brain-xiang/grok-studio (skills/thumbnail-and-icon; MIT)
  - https://github.com/S4US/Roqer (references/composition.md, core/assets.md; AGPL, rules re-authored)
  - https://github.com/AshExplained/roblox-skills (roblox-creator-store-security-audit; MIT)
  - https://create.roblox.com/docs/production/publishing/experience-icons
  - https://create.roblox.com/docs/production/publishing/thumbnails
  - https://create.roblox.com/docs/players/loading-screens
  - https://create.roblox.com/docs/performance-optimization/improve (load times)
  - https://create.roblox.com/docs/projects/teleport (custom teleport screens)
  - original (76 chart games' icons and first thumbnails, 2026-11-02, hand-tallied from contact sheets)
  - original (reference frames of Steal An Egg / Steal a Brainrot, 2026-10-26)
---

# World palette, store assets, icon, thumbnails, logo and loading screen

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
- Keep essential text and subjects away from the bottom edge: player count and other metadata can cover it (docs).
- Make 2-3 variants for A/B. Genre thumbnails use big stroked text, a "YOU!" arrow, an exaggerated scale moment and a bright sky.
- **Thumbnail personalization (docs):** it starts only when 2 or more thumbnails are active on the Home Page tab; activate 2-5. Roblox reports +8.5% average qualified play-through rate in its tests (up to +50% for some games). Keep several active instead of crowning one winner, test new thumbnails with each major update, then leave them alone until the next one.
- **Video thumbnails (docs):** 3 uploads a month, reviewed; real gameplay only, no voice-over or lyrics, no "50% off" or "Free UGC" claims; your own logo overlay and in-game UI text are allowed; not shown on Xbox, PlayStation or VR.

**What chart games do (n=76 from the Oct-Nov 2026 charts, first thumbnail and icon of each, measured by script plus hand-tallied from contact sheets, so counts are approximate, survivorship bias applies, and Halloween skews the mix):**

| Measure | Icons | First thumbnails |
|---|---|---|
| Saturation (0-1) | median 0.59, p10 0.24, p90 0.76 | median 0.51, p10 0.28, p90 0.74 |
| Brightness (0-1) | median 0.66, p10 0.36, p90 0.83 | median 0.62, p10 0.35, p90 0.82 |
| Luminance contrast (std, 0-1) | median 0.26, p10 0.20 | median 0.22, p10 0.16 |
| Distinct strong hues (share 8% or more) | median 2, p90 4 | median 2, p90 4 |
| Readable title or logo text | about a third | about a third (title, or a short feature line such as "Piercing Projectiles") |
| A Roblox avatar as the subject | about a third | about half |
| Number or reward hook ("1.2x", "+1", "$/s", "1 in 9,342,584", "YOU!" arrow) | a few | about one in ten |
| First-person hands or POV | rare | about one in ten |

Read it as: one bold subject, 2 dominant hues, saturated but not neon-flat, centred; a title only when the name is part of the pitch. About 10 of the 76 used the platform's red "The Hollow" event frame (Halloween 2026): it is an event template, not a pattern to copy. A few top games ship an in-engine screenshot with no art pass, so polish helps but is not required. Re-run with `scripts/benchmark` data and a fresh contact sheet each quarter.

**Truthfulness:** no misleading UI or gameplay, no other games' characters or brand logos, no "FREE ROBUX" or fake "UPDATE" bait.

**Making them:**
- Path 1: a Blender diorama of the game's own assets. 35-50 mm lens for thumbnails, 50-85 mm for the icon, key plus rim light.
- Path 2: Studio `screen_capture` during a playtest with an explicit camera and the HUD hidden (`ScreenGui.Enabled = false`).
- Post-process: crop to the focus point, Lanczos resize, optional outlined title, enforce 3 MB.

**Upload:** in Creator Dashboard (Configurations > Places > Icon / Thumbnails), or the experimental `legacy-game-internationalization` game-icon and game-thumbnails endpoints with an API key (see `roblox-release-automation`, not yet tested). The Open Cloud Assets API does not set the game icon. Never use a .ROBLOSECURITY cookie.

## 6. Logo

- Where it appears: the icon (about a third of chart icons carry readable title text, usually 1-3 words), the first thumbnail, the loading screen and the main menu. Make one logo file set and reuse it so the name looks the same in all four.
- Build rules (from the icon docs and the chart sample): square 512x512 icon that still reads at about 150x150; thick outline or bevel plus a drop shadow; 1-3 words; high contrast against the art behind it; keep it inside the icon's safe middle so rounded corners and badges do not clip it; avoid thin strokes and small taglines (they vanish at 150 px).
- Thumbnails: put the logo top or middle, not the bottom edge (metadata overlays the bottom). A logo overlay on a video thumbnail is allowed by the docs.
- In-game: upload the logo as a Decal and use the returned image id, never the decal id (see `roblox-blender-export` section 5). Fixed brand words may be images; translatable words stay TextLabels (section 4). A localized icon can carry a localized logo, one icon per locale.
- Rights: only your own mark. Other games' logos and characters are rejected (see Truthfulness above). Check the name is not already a top game's name.
- Test: render the logo at 150, 96 and 64 px on both a light and a dark background before uploading.

## 7. Loading screen and teleport screen

**Mechanics (docs, create.roblox.com/docs/players/loading-screens):**
- Put the loading `ScreenGui` in `ReplicatedFirst` (it replicates before anything else) and show it from a `LocalScript` there. Set `IgnoreGuiInset = true`, parent it to `PlayerGui`, then call `ReplicatedFirst:RemoveDefaultLoadingScreen()`. Wait on `game:IsLoaded()` / `game.Loaded`, then fade out and `Destroy()` the gui. Design it in `StarterGui` first, then move it.
- Animate with `TweenService` (fade-in, a rotating ring, a moving bar). The docs example forces a 5 second minimum with `task.wait(5)`; use a minimum only as long as your fade needs, since a forced wait is pure delay.
- Teleports between places: call `TeleportService:SetTeleportGui(screenGui)` on the client with a `ScreenGui` stored in `ReplicatedStorage`. Scripts inside that gui do not run, so it must be static or animated by the sending client beforehand.
- Studio 0.745 check (2026-11-02): `RemoveDefaultLoadingScreen`, `IsFinishedReplicating`, `FinishedReplicating`, `SetTeleportGui`, `PreloadAsync` and `ScreenGui.ScreenInsets` exist. The loading flow itself was not run (`game:IsLoaded()` is not meaningful in Edit mode); verify in a Team Test or a published server.

**Load time is the real design problem (docs, performance-optimization/improve):**
- Keep `ReplicatedFirst` to what the loading screen needs: a few UI elements, not big textures or 3D models.
- Preload only the loading screen's images, key menu images and the spawn area with `ContentProvider:PreloadAsync()`. Do not preload all of `Workspace`, and do not wait on `ContentProvider.RequestQueueSize` (it fluctuates and adds time).
- Keep `ReplicatedStorage` small and enable instance streaming; both cut the time the screen is visible.
- If you must load many assets, add a **Skip Loading** button once the essentials are ready.

**Design (community advice from DevForum threads, opinions not measurements; no public data on loading screens and retention was found):**
- Show the logo, one short tip and a progress indicator tied to real loading. A uniform tween that stalls near the end reads as fake.
- Match the game's art style and the thumbnail the player clicked (inference: the first frame should confirm they entered the game they chose). Plain "Loading..." text with a spinner is the commonly criticised default.
- Add a timeout that closes the screen if loading hangs, and keep the screen under a few seconds on a typical phone. Do not put ads or claims on it.
- Test on a throttled network and a low-end phone (Device and Network Simulator) for the worst-case time, and check the screen on phone, tablet and console safe areas.
