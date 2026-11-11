---
name: roblox-store-art-pack
description: "Use for any genre when picking and quarantining Creator Store models, picking UI icons (button, currency, shop, rebirth) from a Creator Store icon pack, offering popular world-prop packs (trees, rocks, fences) for the user to pick, checking map composition, or making the game icon, thumbnails, logo and loading screen. Its world palette (section 1) is for bright daylight simulator/tycoon games only. Also when inserting Toolbox/Creator Store models, before publishing or running ads (icon/thumbnail CTR), when building an icon family for UI or an agent-made icon looks odd, designing a logo or a custom loading or teleport screen,  or when a bright simulator/tycoon scene looks flat, pastel or greybox. Skip section 1 for horror, realistic or night games; set the mood with Lighting, Atmosphere and post effects instead."
last_reviewed: 2026-11-04
sources:
  - https://github.com/blauwtje/roblox-kit (map-building/reference/daylight-look.md, ui-images; MIT)
  - https://github.com/brain-xiang/grok-studio (skills/thumbnail-and-icon; MIT)
  - https://github.com/S4US/Roqer (references/composition.md, core/assets.md; AGPL, rules re-authored)
  - https://github.com/AshExplained/roblox-skills (roblox-creator-store-security-audit; MIT)
  - https://create.roblox.com/docs/production/publishing/experience-icons
  - https://create.roblox.com/docs/production/publishing/thumbnails
  - https://create.roblox.com/docs/production/promotion/ads-manager
  - https://devforum.roblox.com/t/youtube-videos-will-be-removed-from-game-detail-pages/4879633
  - https://create.roblox.com/docs/players/loading-screens
  - https://create.roblox.com/docs/performance-optimization/improve (load times)
  - https://create.roblox.com/docs/projects/teleport (custom teleport screens)
  - original (76 chart games' icons and first thumbnails, 2026-11-02, hand-tallied from contact sheets)
  - original (reference frames of Steal An Egg / Steal a Brainrot, 2026-10-26)
---

# World palette, store assets, icon, thumbnails, logo and loading screen

Pair with `roblox-blender-export` (custom meshes) and `roblox-ui-genre-studs` (UI). Inserted scripts are code you did not write: quarantine and read them (section 2).

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
  - Studs on floors (a stud texture, or `Enum.SurfaceType.Studs` on parts that use surface types; there is no stud Material), saturated bright green ground, red carpet paths.
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
- **Backdrop:** derive every backdrop radius (skyline rings, far towers) from the layout constants, never from absolute studs. When one lane length grew from 336 to 480, a far tower stood on the road in front of the enemy gate (field note, 2026-11-11). After any layout number change, capture each lane end, not only the spawn view.
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

Store images also texture the world by id with no upload, for example night window photos tiled on far towers for a lit skyline (field note, 2026-11-08). Most such decals have 0 votes and unknown original authorship: record each in the licenses file and list them for the user to keep or replace before release.

**Model inserts (quarantine first):**
- Insert into a quarantine folder.
- Keep meshes, textures and UI art. Delete every script.
- `script_grep` for `require getfenv setfenv loadstring HttpService GetObjects InsertService MarketplaceService DataStore MessagingService TeleportService RemoteEvent string.char string.reverse`.
- Red-flag names: AntiLag, MainModule, Loader, Handler, Update, Version, HDAdmin, Free, Fix, Runtime. Re-uploads of popular simple models are a pattern: four green "Money" models each carried an injected "Runtime" script holding a 35 kB LocalScript (field note, 2026-11-09).
- Color is a filter when choosing. A textured store mesh cannot be recolored to the palette (`MeshPart.Color` does not tint a textured mesh, `roblox-pitfalls` section 4), and a new texture means an upload, so pick a model whose texture already fits (field note, 2026-11-09).
- A theme with no voted pack (none for low-poly war or military props on 2026-11-09): build the family from single meshes by several creators, recolored into one palette, with a triangle cap per family, because voted single models can be heavy (voted sandbag walls had 9k-16k tris). Some store meshes rendered plain white once their `TextureID` was cleared, so check every piece after clearing it, and keep the texture where it already fits (field notes, 2026-11-09).
- Judge store props under the game's own lighting, night included. Realistic tank traps and hedgehogs were unreadable at night under floodlights, while simple chunky silhouettes read (field note, 2026-11-09).
- Verdict for each insert: visual-only / reviewed / quarantine / reject. `insert_asset` keeps scripts and only sets `Sandboxed` on them (observed 2026-11-04), so delete them yourself and recreate the behavior.
- Assets owned by someone else need user consent for use. Record the source in the licenses file.
- A 0-vote model that is the only fit may stay in dev after this quarantine, but list it for the user with its id, creator, votes and the closest voted alternative, and get a keep-or-replace answer before release (judgment). Template MeshPart pieces, not unions (`roblox-pitfalls` section 2).

## 3a. World props from a store pack (the user picks)

Filler world props (trees, rocks, bushes and grass, fences, walls) come from one popular free pack that fits the lane. Pick it with the user from real renders, not from words: `roblox-game-pipeline` section 3, step 4a. Hero props and landmarks stay custom, because a famous pack used for them makes the game look like an asset flip.

1. Rank packs for the lane: `python3 -I <skill dir>/scripts/store_icons.py "<lane word> nature pack" "<lane word> tree" "<lane word> rock" --type model`. Start from the table below. Skip 0-vote re-uploads (most lane keywords return mostly these, many with scripts). A pack with scripts is read before it is kept (section 3).
2. Insert 2-4 candidates under `ServerStorage` with Studio MCP `insert_asset`, in the game's dev place so they are judged under its lighting.
3. Edit `PACKS` in `scripts/pack_lineup.luau` and run it with `execute_luau` (Edit). It does four things:
   - places the largest and a middle-sized tree, rock, plant and wall of each pack side by side, left to right in `PACKS` order, each block next to a red player-size block;
   - anchors the copies and drops their scripts;
   - returns each pack's parts, MeshParts, unique meshes, scripts and unanchored parts;
   - returns camera and look-at positions for `screen_capture`.
4. Capture once overall and once per pack. Save the captures in one folder named after the packs and build a labeled sheet with `python3 -I <roblox-game-pipeline dir>/scripts/style_board.py kit.png --dir <folder>` (3D labels do not show in edit-mode captures).
5. Send the sheet with one line per pack: its look in this game, what it covers, how heavy it is. The user picks one pack per lane. Mix two packs only when the shading matches.
6. Using the pick:
   - keep only the pieces used and delete the rest of the pack;
   - anchor every part (several packs ship unanchored, see the table);
   - set decor collisions (`roblox-blender-export` section 5);
   - record the pack in `assets/LICENSES.md`.
   A class the pack lacks (walls in most lanes) is built from parts or generated to match the pack.

| Lane (tested 2026-11-04; re-rank, votes change) | Pack | Id | Votes | Covers | Parts / scripts / unanchored |
|---|---|---|---|---|---|
| Chunky cartoon | Simulator Pack (qorrium) | 106310348164692 | +29/-1 | bright faceted round trees, blue rocks, grass tufts, fence, chest, coins | 71 / 1 (an ad README) / 0 |
| Chunky cartoon, cozy | Low-Poly Asset Pack (TRG_USER) | 8904182484 | +192/-8 | smooth rounded trees (one snowy), grey rocks, flower, bush, fence | 241 / 0 / 0 |
| Low-poly | Low Poly Nature Pack (Proudism) | 9682467046 | +39/-1 | small faceted trees, palm, rocks, bushes | 51 / 0 / 25 |
| Low-poly, semi-realistic | Synty Nature Pack (Roblox) | 6933438443 | +768/-32 | 200 meshes: trees, rocks, plants, rock walls, fences, ground; the most-voted free nature pack | 200 / 0 / 0 |
| Cozy pastel | Low-Poly Oak Trees Asset Pack (Cliosow) | 8556375773 | +49/-1 | lime puffy oaks | 53 / 0 / 53 |
| Cozy pastel, fantasy | Fantasy Decorations Pack (Z3roTho52) | 8400234126 | +30/-0 | faceted trees, pine, standing stones, plants | 106 / 0 / 0 |
| Anime, stylized | Yasu's Stylized Tree Pack (mvyasu) | 79689531752352 | +400/-0 | 20 painterly trees, bushes; ships texture swatches; no rocks or walls | 396 / 0 / 0 |
| Anime | Sakura Tree With Falling Petals (Biryuvignette) | 8976941336 | +89/-11 | one large cherry tree | 4 / 0 / 0 |
| Dark realistic | Realistic Tree & Bush Pack (luckycowboy44) | 10907214341 | +96/-4 | pines, bushes, grass, small rocks | 110 / 0 / 0 |
| Dark realistic, horror | Dead Trees (Zalensito) | 15113312104 | +90/-10 | 7 black bare trees | 14 / 0 / 14 |
| Dark realistic | PBR foliage and nature pack (moviroon) | 13536410655 | +196/-4 | leafy trees, mossy boulders, rocks, bushes; PBR textures cost phone memory | 227 / 0 / 24 |
| Neon sci-fi | Alien Plants Pack - Beyond the Dark (CurbMandrill) | 10980935233 | +28/-2 | purple and teal alien trees and plants | 119 / 0 / 1 |
| Neon sci-fi | Space Station Architecture Pack - Beyond the Dark (Roblox) | 10980780693 | +188/-12 | modular station walls, floors, railings; take pieces only | 2837 / 93 (image animators) / 594 |
| Any (fence) | Low-Poly Fence (Catherine858) | 4845879207 | +90/-10 | one rail fence | 1 / 0 / 1 |

Gaps found: no voted free wall pack in most lanes (Synty has rock walls, Beyond the Dark has station walls), few true thick-outline props, no pastel flowers.

## 4. Icon family (UI images)

**Store first.** Standard UI icons (cash, coins, gems, shop, rebirth, settings, gifts, arrows, lock, trophy, potions, paw) come from one free Creator Store icon pack, not from generation. This is the exception to the priority in section 3. Generated icons drift between calls and grow odd details. A popular pack is one family that players already read at a glance. Pass and product icons of generic items (potions, luck, boosts) also come from the pack; only an icon showing the game's own character or creature stays custom.

**Never draw icons** (owner rule, 2026-11-08): no icon built from Frames, lines, `Path2D`, parts or emoji, such as a house from a triangle and a box or an arrow from rotated bars. Those came out crude every time. A missing icon is a store search (step 5), not a drawing. Generated icons are an option only when the user asks for them.

1. Rank packs: `python3 -I <skill dir>/scripts/store_icons.py "simulator icon pack" "icon pack" --type model` sorts free packs by up-votes, prints `hasScripts`, and writes a contact sheet; open it and look.
   - Skip 0-vote re-uploads of a popular pack (same thumbnail, another creator). In our run two of them carried scripts: an icon pack never needs one.
2. Insert the pick with Studio MCP `insert_asset` under `ServerStorage`, then audit it (section 3). Edit `ROOT` in `scripts/pack_ids.luau` and run it with `execute_luau` in Edit mode. It lists every icon as `Folder/Name = image id`, checks that each one loads, and lays them out in a ScreenGui named `IconSheet` under StarterGui for one screenshot.
3. Copy the ids you use into one constants module (`Icons.Coin = "rbxassetid://..."`) and delete the pack and the sheet from the place.
4. Record the pack id, the creator and the ids you used in `assets/LICENSES.md`, and name the pack to the user in one line (section 3: someone else's asset).
5. A concept the pack lacks: run `store_icons.py "<thing> icon" --type decal` and pick one that matches the pack's outline weight, shading and light direction. Use the printed `image=` id, never the decal id: a decal id in `ImageLabel.Image` loads nothing (tested 2026-11-04). In Studio, `game:GetObjects("rbxassetid://<decalId>")[1].Texture` gives the same image id.
6. The game's own items that no store icon shows (its pets, tools, products): render the item's own model (a ViewportFrame, or a Blender render, `roblox-blender-export` section 6). Only when the user asks for generated icons, use an image generator the user has (for example gwanggo `generate_game_asset` kind `icon`, `roblox-game-pipeline` section 10). Match the pack's canvas, outline weight and highlight.

| Pack (tested 2026-11-04; re-rank, votes change) | Id | Votes | Contents | Fits |
|---|---|---|---|---|
| Simulator Icon Pack (DevJoob) | 99176447965360 | +392/-8 | 125 chunky full-color icons with a dark outline: arrows and rebirth, coins, cash, gems, potions, gifts, stars, menus (shop, gear, calendar, bag, lock, paw), luck, trails, cursors | Simulator, tycoon, idle, obby |
| Monochrome White UI Icon Pack (SodaBreadle) | 110801640375836 | +29/-1 | 72 white glyphs (gear, cart, lock, weapons, phone, alerts); tint with `ImageColor3`; mixes line and filled glyphs, so use one kind. No arrow or pointer: one game's tutorial pointer used image 12338397670 ("Arrows Down Icon", DesignWithMarko, another creator; loaded in Studio, field note 2026-11-09), so check its line weight against the pack | Dark flat, horror, shooter, realistic |

- Skip icons with the Roblox logo or the Robux mark (both packs have some), except next to a real Robux price: on in-game currency they read as free Robux.
- Skip art from another game (for example a decal named "DOORS Coins Icon").

Rules for any mix of icons:

- Same canvas (128 px, drawn at 2x), same outline weight, highlight and light direction, flat colors, no text inside.
- 1024 px or less per image. Many icons go on one sprite sheet (8x8 of 128 px).
- 9-slice needs a slice centre; tune `SliceScale`.
- Fixed words (the logo) may be images; translatable words stay TextLabels.
- Generated icons for step 6 (for example gwanggo kind `icon`, 1:1 in the project's locked style): downscale to the canvas and check that the outline weight matches the pack.

## 5. Game icon and thumbnails

**Icon:**
- 512x512 and still legible at about 150x150; one per locale; moderated.
- One bold subject, a strong silhouette, 2-3 dominant colors, a high-contrast rim light, at most a 1-2 word title, filling the frame, no thin borders.

**Thumbnails:**
- 16:9 at 1920x1080 (jpg, png, gif, tga or bmp), under 3 MB, up to 10 per game. Non-16:9 images get stretched.
- Show an action moment from the core loop, with the character at a rule-of-thirds point and a clear foreground, midground and background.
- Colors saturated but true to the game; an optional short title at top centre.
- Keep essential text and subjects away from the bottom edge: player count and other metadata can cover it (docs).
- Drafts: edit real gameplay screenshots by hand, or use an AI kit such as gwanggo's Thumbnail & Icon Kit (gwanggo.ai/dashboard/game/thumbnail-kit; 3 thumbnails and 1 icon at these sizes from a real gameplay screenshot); check every letter of AI text and keep the result true to the game (`roblox-game-pipeline` section 10).
- Make 2-3 variants for A/B. No public benchmark for thumbnail A/B results exists (searched 2026-11-03; tracker articles give no method), so measure your own: run the variants as Ads Manager campaign creatives (up to 25 per campaign in the UI as of 2026-11-05, the docs still say 10; shown evenly; setup in `roblox-design-and-launch` section 2) and keep the winners active. Genre thumbnails use big stroked text, a "YOU!" arrow, an exaggerated scale moment and a bright sky.
- **Thumbnail personalization (docs):** it starts only when 2 or more thumbnails are active on the Home Page tab; activate 2-5. Roblox reports +8.5% average qualified play-through rate in its tests (up to +50% for some games). Keep several active instead of crowning one winner, test new thumbnails with each major update, then leave them alone until the next one.
  - Two sets: the Experience details page tab holds the ordered list everyone sees on the game page; the Homepage tab holds the set Roblox picks from per player on the home feed, with impressions and qualified plays per thumbnail. With one active, the tab says personalization is off and everyone sees that one.
  - Its banner recommends 1000+ daily users before testing several; a recommendation, not a gate (Creator Hub UI, 2026-11-11). So a private or tiny game can run one active; keep a second uploaded but inactive and tick 2 or more at public launch, when there is traffic to learn from (judgment).
  - The Homepage upload tooltip said up to 5, jpeg/png/bmp, 10 MB, 16:9 (UI, 2026-11-11); the docs say under 3 MB and 1920x1080, so stay within the docs.
- **Video thumbnails (docs):** 3 uploads a month, reviewed; real gameplay only, no voice-over or lyrics, no "50% off" or "Free UGC" claims; your own logo overlay and in-game UI text are allowed; not shown on Xbox, PlayStation or VR. YouTube video links were removed from game pages on 2026-09-30 (DevForum announcement); upload the video file instead.

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

Read it as: one bold subject, 2 dominant hues, saturated but not neon-flat, centred; a title only when the name is part of the pitch. About 10 of the 76 used the platform's red "The Hollow" event frame (Halloween 2026): it is an event template, not a pattern to copy. The event ended 2026-11-02; do not tally event frames or tags again until after about 2026-11-20. A few top games ship an in-engine screenshot with no art pass, so polish helps but is not required. Re-run with `roblox-launch-benchmarks` scripts data and a fresh contact sheet each quarter.

**Truthfulness:** no misleading UI or gameplay, no other games' characters or brand logos, no "FREE ROBUX" or fake "UPDATE" bait.

**Making them:**
- Path 1: a Blender diorama of the game's own assets. 35-50 mm lens for thumbnails, 50-85 mm for the icon, key plus rim light.
- Path 2: during a playtest, set the camera with the render-step camera and hide the HUD (`ScreenGui.Enabled = false`), then `screen_capture` with no camera arguments (recipe: `roblox-pitfalls` section 3, Screenshots in Play).
- Post-process: crop to the focus point, Lanczos resize, optional outlined title, enforce 3 MB.

**Upload:** the Open Cloud Assets API sets the start place's icon and the detail-page thumbnails, and the Thumbnail Personalization API the homepage set (docs 2026-11, not yet tested here; calls in `roblox-release-automation` section 1). Otherwise use Creator Dashboard (Configurations > Places > Icon / Thumbnails). The `legacy-game-internationalization` game-icon and game-thumbnails endpoints set translated images only and refuse the source language. Never use a .ROBLOSECURITY cookie.

## 6. Logo

- Choosing a logo style: draft the same name in 3-4 treatments (sticker, chrome, chunky 3D letters, hand-drawn) as images and let the user pick (`roblox-game-pipeline` section 10a). AI image text is often misspelled: check every letter, and set final text in an editor when it is wrong.
- Where it appears: the icon (about a third of chart icons carry readable title text, usually 1-3 words), the first thumbnail, the loading screen and the main menu. Make one logo file set and reuse it so the name looks the same in all four.
- Build rules (from the icon docs and the chart sample): square 512x512 icon that still reads at about 150x150; thick outline or bevel plus a drop shadow; 1-3 words; high contrast against the art behind it; keep it inside the icon's safe middle so rounded corners and badges do not clip it; avoid thin strokes and small taglines (they vanish at 150 px).
- Thumbnails: put the logo top or middle, not the bottom edge (metadata overlays the bottom). A logo overlay on a video thumbnail is allowed by the docs.
- In-game: upload the logo as a Decal and use the returned image id, never the decal id (see `roblox-blender-export` section 5). Fixed brand words may be images; translatable words stay TextLabels (section 4). A localized icon can carry a localized logo, one icon per locale.
- Rights: only your own mark. Other games' logos and characters are rejected (see Truthfulness above). Check the name is not already a top game's name.
- Test: render the logo at 150, 96 and 64 px on both a light and a dark background before uploading.

**Tone and manner (make the logo look like the game):**
- Write a 5-line brand brief first and reuse it in every prompt and review: genre and audience, mood in 3 adjectives, 2-3 dominant colors (hex), shape language (round and chunky, sharp and angular, hand-drawn), and the one object or action that sells the game (a bat hitting a ball, an egg hatching).
- Match the logo to the world the player sees. Bright simulators and tycoons take rounded, chunky, glossy letters with a thick dark outline and a white sticker-style edge; horror takes a cracked or dripping condensed face in 1-2 muted colors with red or sickly green accents; anime fighters take sharp italic type with speed lines and a brush texture; cozy roleplay takes soft rounded script on pastels. Do not use a cute bubble face on a horror game or a gritty face on a toddler-friendly one: a mismatch tells players the wrong genre before they play.
- Echo the same palette, outline weight and lighting in the icon, thumbnails, loading screen and UI frames so the brand reads as one set (see `roblox-ui-genre-studs` for the simulator HUD look).
- Sports and themed games can build the pitch into the mark: a user-supplied reference baseball game ("+1 BAT") uses a sticker-style logo (white outer edge) with a smiling avatar swinging a bat, a flaming bat, flying bricks and a yellow "+1" beside bold blue-white "BAT" letters, over a blurred in-game field. The pattern to copy is the structure (avatar action + themed props + outlined numeral/word), not the art or name.

**Making the logo with image-generation AI:**
- Workflow: brief, then 4-8 candidates, pick one, refine, then clean up and typeset. Free first: a text logo typeset in Studio or an image editor with a bold game font, outline and bevel (`roblox-game-pipeline` section 10, Brand row). Then the image tools you already have (for example the `gwanggo-generate` and `higgsfield-generate` skills; models such as GPT Image 2, Nano Banana and Seedream), or Roblox Studio's own generators for in-world assets.
- Prompt pattern: `game logo, text "+1 BAT", chunky 3D bubble letters, thick dark-blue outline, white sticker border, glossy highlights, [subject: avatar swinging a flaming bat], flat solid background, centered, no extra text`. Name the exact words in quotes, ask for one logo on a plain background, and add `no watermark`.
- Image models often misspell or distort text. Proofread every letter at full size. If the words are wrong, generate the art without text and typeset the name yourself (Figma, or a bold game font plus outline and bevel), or fix it by editing the image and re-checking.
- Ask for a transparent or single-color background so the logo can be cut out (generate on pure green or white and remove it, or use a background-removal step). Export a PNG with alpha, 1024 px or more on the long side, and keep the source and the prompt in `assets/` with the model name and date.
- Rights and safety: you answer for what you publish "regardless of whether you use generative AI" (Roblox's rule as quoted in a secondhand article; check the current Creator Terms). Never prompt with other games' names, logos or characters; reject results that resemble an existing logo; the upload still goes through moderation.
- Review: run the 150, 96 and 64 px test, check it on a light and a dark background, and ask a person who has not seen the game what genre it is.

## 7. Loading screen and teleport screen

Choosing the look: show the example in `roblox-game-pipeline/assets/examples/`; if it is not what the user wants, generate 3-4 candidates in the game's style (`roblox-game-pipeline` section 10a) and let the user pick.

**Mechanics (docs, create.roblox.com/docs/players/loading-screens):**
- Put the loading `ScreenGui` in `ReplicatedFirst` (it replicates before anything else) and show it from a `LocalScript` there. Set `IgnoreGuiInset = true`, parent it to `PlayerGui`, then call `ReplicatedFirst:RemoveDefaultLoadingScreen()`. Wait on `game:IsLoaded()` / `game.Loaded`, then fade out and `Destroy()` the gui. Design it in `StarterGui` first, then move it.
- Animate with `TweenService` (fade-in, a rotating ring, a moving bar). The docs example forces a 5 second minimum with `task.wait(5)`; use a minimum only as long as your fade needs, since a forced wait is pure delay.
- Teleports between places: call `TeleportService:SetTeleportGui(screenGui)` on the client with a `ScreenGui` stored in `ReplicatedStorage`. Scripts inside that gui do not run, so it must be static or animated by the sending client beforehand.
- Studio 0.745 check (2026-11-02): `RemoveDefaultLoadingScreen`, `IsFinishedReplicating`, `FinishedReplicating`, `SetTeleportGui`, `PreloadAsync` and `ScreenGui.ScreenInsets` exist. The loading flow itself was not run (`game:IsLoaded()` is not meaningful in Edit mode); verify in a Team Test or a published server.

**Load only what the first screen needs (docs: performance-optimization/improve, "Load times"; the tiers are our synthesis):**

The join waits for `ReplicatedFirst`, then everything in `ReplicatedStorage` and the initial `Workspace`, then anything your scripts preload, then the avatar. The loading screen ends only when all of that is done, so every extra asset lengthens it. Rule: **the loading screen waits for the first screen, nothing more.** Everything else loads after the player can already play.

| Tier | What | When |
|---|---|---|
| 0, blocks the loading screen | The loading screen's own images; the HUD and main-menu images visible on the first screen; the spawn area and the first thing the player does | Before `RemoveDefaultLoadingScreen` ends. Preload with `ContentProvider:PreloadAsync()` only these |
| 1, background | Next zone, other menu tabs, common sound effects, music for the next minute | After the player can move. Start `PreloadAsync` in a separate `task.spawn`, do not wait on it |
| 2, on demand | Shop pages, later worlds, boss assets, rare effects, long audio, cinematics | Load when the player opens or approaches it (stream the area, move the model from `ServerStorage` to the client when needed, load the audio per area) |

Docs-backed rules:
- Do not preload all of `Workspace` (it removes texture pop-in but adds a lot of load time) and do not wait on `ContentProvider.RequestQueueSize` (unreliable and slow).
- Keep `ReplicatedFirst` to the loading screen's basics, not big textures or 3D models.
- Keep `ReplicatedStorage` to what clients need at join, such as shared ModuleScripts. Move large models and audio to `ServerStorage` and send them to the client only when needed.
- Enable instance streaming: only the area near the spawn replicates at join. Test scripts that read `Workspace` at join, since instances may not exist yet.
- Avoid heavy startup `LocalScript` work (large data structures loaded synchronously).
- Check for free-model scripts that spawn thousands of instances; they inflate join size.
- If many assets are unavoidable, show a **Skip Loading** button once the essentials are ready.

Planning use: while planning, list the first-screen assets (stage 4 decision card "first screen") and give each other asset a tier. Put the tiers in `docs/plan.md` as a loading budget, for example "Tier 0: 12 assets, under 3 MB".

Measure instead of guessing (docs): time it with a stopwatch from Play to a visible world, or log `os.clock()` from a `ReplicatedFirst` script to `game.Loaded` (it excludes connection and avatar time), count `#workspace:GetDescendants()`, and turn on **Print Join Size Breakdown** (Studio Settings > Network) to see the 20 largest instances. Re-measure after each content update; a sudden jump usually means something new landed in `ReplicatedStorage`. Test on a throttled network and a low-end phone profile.

**Design (community advice from DevForum threads, opinions not measurements; no public data on loading screens and retention was found):**
- Show the logo, one short tip and a progress indicator tied to real loading. A uniform tween that stalls near the end reads as fake.
- Match the game's art style and the thumbnail the player clicked (inference: the first frame should confirm they entered the game they chose). Plain "Loading..." text with a spinner is the commonly criticised default.
- A theme-matched progress bar beats a plain spinner: the owner's "+1 BAT" loading screen (image: `roblox-game-pipeline/assets/examples/loading-screen-baseball.jpg`) shows a large sticker-style logo over a blurred copy of the game's own field, a green bar with a baseball as the knob that rolls to 100%, and a one-line flavor text ("Play ball!") instead of "Loading". Keep the logo clear of the top-left corner, where Roblox's menu and chat buttons sit over the screen.
- Full-screen key art with `ScaleType.Crop` shows a different part on each screen shape: a wide phone (844x390) shows less height than 16:9. Check both and keep the subject clear of the bar and the logo. In one game a character sat under the bar on phones until the art was regenerated zoomed out (field observation, 2026-11).
- Add a timeout that closes the screen if loading hangs, and keep the screen under a few seconds on a typical phone. Do not put ads or claims on it.
- Test on a throttled network and a low-end phone (Device and Network Simulator) for the worst-case time, and check the screen on phone, tablet and console safe areas.
