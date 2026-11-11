---
name: roblox-ui-genre-studs
description: "Use only for simulator/tycoon-style games (Steal a Brainrot, Steal An Egg, +1 Strength, Pet Simulator) whose HUD, shop, panels or world labels must match that chunky stud look: black outlines, lips, FredokaOne, quiet HUD zones. Not for horror, realistic or story games."
when_to_use: "Also when a simulator/tycoon UI looks generic, AI-made, too big, too dark or off-genre; when a panel overlaps the HUD; before calling such a UI done; before restyling its HUD, shop, rebirth, store, daily or codes panels; when picking stud/sunburst textures; when world labels clutter the view. For other genres use the UI rules in `roblox-engine-2026`."
last_reviewed: 2026-11-04
sources:
  - https://github.com/S4US/Roqer (apps/desktop/agent/skills/roblox-ui-design, MODERN STUDS theme; AGPL-3.0-or-later; facts re-authored, no text copied)
  - https://github.com/hujhfrgrwg/HatchOrSnatch (.claude/skills/roblox-ui-maker LESSONS/STYLE/ROBLOX_FACTS; no license, facts only)
  - https://github.com/blauwtje/roblox-kit (skills/game-ui; MIT)
  - https://github.com/scenario-labs/skills (scenario-roblox-ui screen-budget; MIT)
  - original (reference-frame comparison of Steal An Egg, Steal a Brainrot, +1 Strength, 2026-10-26)
  - original field notes (2026-10 to 2026-11)
---

# Roblox genre UI: stud style

Pair with `roblox-engine-2026` (flex layouts, input) and `roblox-ui-layout` (placement, reserved zones, phone and console floors; it wins on those). This skill owns the genre LOOK. Numbers below are strong starting values from a few low-star sources. Confirm each one with a Studio screenshot next to a reference frame before treating it as a hard rule.

## 0. Look before you build

- Confirm the UI style was picked from the basic style cards (`roblox-game-pipeline/assets/ui-styles/`); this skill is "stud chunky".
- Show the reference screens in section 9 first. If the user wants a style they do not show (or the game is not a simulator/tycoon), generate the same screen in 2-4 styles and let the user pick before building (`roblox-game-pipeline` section 10a).
- Pull reference frames of 2-3 current top games in the same genre. YouTube storyboards work when clip downloads return 403: `yt-dlp -f sb0 -o sb.mhtml URL`, then extract the JPEGs from the mhtml with Python `email`.
- Store thumbnails come from `thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=...` and are marketing art, not HUD.
- Every UI task ends with the review routine in section 10.

## 1. Identity

- Every surface is one rounded block with:
  - a thick black outline;
  - a darker same-hue lip along the bottom;
  - a saturated face, lighter at the top (vertical UIGradient).

  Square corners or a missing lip is the wrong style.
- Studs are embossed inside the face: a stud tile image on the face, tinted by the gradient at low contrast. Never a loud overlay.
- Fixed color vocabulary:

  | Color | Meaning |
  |---|---|
  | Green | Primary, buy, CTA |
  | Red square with heavy white X | Close |
  | Purple | Gift, premium secondary |
  | Gold | Rare, featured |
  | Grey | Owned, disabled |
  | Slate | Empty, locked |

  Anything for sale is saturated.
- Item art sits on a sunburst image (ImageTransparency about 0.15).
- Text is white and heavy with a black outline. Big world numbers are gradient-filled.

## 2. Surface kit constants

| Kind | Lip (of height) | UICorner | UIStroke | Studs |
|---|---|---|---|---|
| button | 0.12 | scale 0.22 | 3 | 2.5 rows |
| chip | 0.12 | scale 0.3 | 3 | - |
| tile | 0.07 | scale 0.16 | 4 | 4 rows |
| card | 0.05 | 10 px | 3 | 64 px tile |
| band (header) | 0.10 | 10 px | 3 | - |

- On a TextButton, set the UIStroke `ApplyStrokeMode = Border`. Contextual would stroke the text instead.
- Color ramps (top / bottom / lip RGB):

  | Color | Top | Bottom | Lip |
  |---|---|---|---|
  | green | 190,255,90 | 40,215,30 | 10,140,20 |
  | red | 255,120,120 | 225,20,30 | 130,0,10 |
  | purple | 215,125,250 | 150,20,230 | 95,5,160 |
  | gold | 255,240,130 | 240,170,20 | 150,95,0 |
  | blue | 120,215,255 | 20,125,240 | 10,65,160 |

- Build a face as a white `BackgroundColor3` plus a vertical `UIGradient` from the top to the bottom color: the gradient multiplies the base color, so a colored base comes out darker (`roblox-engine-2026` section 2).
- Panels:
  - Body: dark navy `23,25,40` (sampled from the section 9 screens). Over a bright 3D world, 60% opacity reads see-through, so big bodies go 90% or more opaque.
  - Outline: black UIStroke 5-7.
  - Corners: UICorner 14-30.
  - One colored header band per panel (orange, blue or purple).
  - Optional faint 2 px white inner rim.
- Opening a panel: world BlurEffect plus a UIScale pop.

## 3. Text

- Fonts for every genre, readability rules and non-Latin coverage: `roblox-ui-typography`. This section only adds the stud-style specifics.
- Font: `Font.fromEnum(Enum.Font.FredokaOne)`, with another current display font as the alternative (`GothamBlack` is removed and renders as Montserrat). Never mix the two on one screen. At most 2 fonts in the whole game.
- UIStroke on text:

  | Text | Stroke |
  |---|---|
  | Small | 2-2.5 |
  | Buttons, headers | 3 |
  | Panel titles | 3.5 |

  Color near-black (`#121212`). An optional 3 px hard drop shadow.
- Display-number gradients:

  | Currency | From | To |
  |---|---|---|
  | Cash | 180,255,135 | 90,215,55 |
  | Gold | 255,245,140 | 255,170,0 |
  | Gem | 150,235,255 | 40,150,255 |
  | Candy | 255,170,240 | 175,80,255 |

  Warning text: 255,92,92.
- Robux price goes in ONE label: `utf8.char(0xE002) .. " 249"`.
- Phone minimums: body text 26 design px or more, titles 40 or more (design px at 1920x1080). On a phone those shrink to about a third, so the phone sizes in `roblox-ui-layout` section 4 win (14 px panel body text; bold, stroked HUD text 12 px or more).
- One number formatter: truncate and never round up into the next suffix (250K, not 0.3M).

## 4. HUD zones (1080p measurements, all in Scale)

- These are desktop proportions. On phones the safe frame is about 667x317 px: apply the keep boxes and floors of `roblox-ui-layout` (sections 1, 2 and 4) and run its `scripts/ui_device_check.luau` per device.
- Treat the screen as a 3x3 grid. The centre 50% x 50% stays empty. Zones inset 2% or more.
- Roblox's controls fill the left of a 58 px top strip (`roblox-ui-layout` section 1). With the default `ScreenInsets = CoreUISafeInsets` the safe frame starts below it; with `None` or `DeviceSafeInsets`, push top-corner groups below `GuiService.TopbarInset`.
- **Left:** menu tiles in 1-2 columns, vertically centred.
  - Tile `UDim2.new(0.049,0,0.09,0)` plus `UIAspectRatioConstraint` 0.97 (about 97 px at 1080p). 0.09 of the screen height is the median visible menu button of top games on phones (measured 2026-11-09, `roblox-ui-layout` section 4); the old 0.115 sat above their p75. Desktop top games run smaller, about 0.07 (median 0.073 of 39 desktop HUD frames, a quick pass not deduplicated per game, measured 2026-11-11), so 0.09 is the upper end on desktop.
  - Icon at 0.8 of the face, with the label over the icon foot.
  - At most 6 tiles per side. Badges on at most 2 tiles; badges wobble or pulse color, never size.
- **Bottom-left:** currency readouts with no plate behind them.
  - Each row is about 6% of screen height (top-game phone median, measured 2026-11-09; desktop about 5%), a small icon on the left and a gradient number on the right.
  - A small "+N/s" line goes under the main currency. A bare number with no icon is a defect.
  - On touch, keep this above the joystick zone.
- **Right:** small square icon buttons (store, daily, codes), plus up to 2 unframed offers. An offer is art on a sunburst at 0.17 of screen height with a green `0,255,8` price; on a phone it collapses to an icon button with a price badge (`roblox-ui-layout` section 2).
- **Top-centre:** one timer or objective, or at most 3 nav chips (13.6% x 7.5% each). Otherwise empty. Event banners are short ("RUN!!").
- **Quiet HUD:** show only per-second info (main currency, one goal, 4-5 buttons). Reveal secondary currencies and timers when they start to matter.
- Hit areas: 44 px or more on a phone, through a transparent button larger than the visible tile when needed (`roblox-ui-layout` section 4). Primary buttons 150-190 at 1080p. Keep the thumbstick and jump keep boxes clear on touch (`roblox-ui-layout` section 1).
- Under a canvas scale k (screen px = design px x k) a floor is floor / k design px. When shrinking a HUD, clamp each hit area, not the visible size: `math.max(math.ceil(v * factor), math.ceil(44 / k))`. On small phones the floor wins; say so instead of claiming the full shrink.
- Never auto-claim rewards. Hide zero rewards. An unaffordable item is a grey plate, and tapping it says how much is missing.

## 5. Motion and polish

- **Panel open:** UIScale 0.85 -> 1 with a Back/Out ease, about 0.25-0.38 s. Close in about 0.18 s.
- **Buttons:** hover 1.06, press 0.92-0.94, about 0.12 s, through a UIScale child. Set `AutoButtonColor = false`.
- **Numbers:** count up over about 0.45 s.
- Never continuously scale anything that contains text, because text steps between whole font sizes. Pulse color, or rotate +-8 degrees (never inside a ScrollingFrame).
- Float images only: 10 px or more each way over 0.9-1.2 s.
- Scale every UIStroke by viewport height / 1080 (minimum 1), or on text set `UIStroke.StrokeSizingMode` to `ScaledSize` so the stroke follows the font size. Never tween stroke `Thickness`. Add `UITextSizeConstraint` to TextScaled labels.
- Animate UIScale, not Size. Honor `GuiService.ReducedMotionEnabled`.

## 6. World labels (BillboardGui)

- No frame. Stacked stroked text over each pedestal or animal:
  - name (white);
  - rarity (rarity color, rainbow gradient for the top tier; colors from the one tier table in `roblox-fun-effects` section 3);
  - "$X/s" (yellow-green);
  - value or price.
- A green "Collect" pad in front of each pedestal, with its amount in stroked text.
- Floating income: large green "+$1.5M" with a black stroke that rises and fades. It is the main juice.
- Owner sign over the base: "<DisplayName>'s Base".
- Set `BillboardGui.MaxDistance` on every world label (`roblox-ui-typography` section 5), high enough that a label is already small when it vanishes (docs: avoids pop-out). Add a declutter pass near the camera: shrink close labels, hide one that would cover a nearer one (field observation).
- Guide arrows (trail to the next goal): raycast down per arrow (`roblox-combat-tools` section 4) and sit each just above the floor; interpolating between player and target makes the arrows climb toward a tall trigger. Clamp each arrow's width by its camera distance so a near arrow does not fill the screen (field observation). Lay the trail along a `PathfindingService` path (straight line as fallback) with a pooled set of arrows, CanCollide, CanTouch and CanQuery off. Recompute on a timer (about 0.75 s) or after a few studs of movement, not every frame (`ComputeAsync` yields), and hide the arrows near the target. Judge their size from the default camera: in one game the first size read too small and 1.5x read right (field observation, 2026-11).

## 7. Anti-slop list

Each of these is a defect:
- emoji or letters as icons;
- generated or hand-made icons for standard things (cash, coins, gems, shop, rebirth, settings, gifts) that a store icon pack already has;
- more than 2 fonts, or corner radii outside section 2 (one value per kind from the table; panels 14-30 px, the same on every panel);
- stat text with a panel behind it;
- HUD elements over 15% of screen height on desktop; on a phone, menu buttons over 0.12 of the viewport height (unless the HUD shows 2 or fewer) or an idle HUD covering more than 20% of the screen (except panels and offers);
- a giant dark panel, or one with no colored header band, black outline and lighter inner cards (the section 9 panels are dark navy, but framed, banded and full of saturated parts);
- flat 1990s-style UI in a simulator (plain flat boxes, thin or no outline, no lip, no gradient): use the stud house style of the section 9 screens (owner rule);
- pills everywhere;
- one size of button for every importance;
- permanent upsell buttons;
- timer nag tips;
- a desaturate filter over a price.

## 8. Textures and icons

- Probe every image id before relying on it (`roblox-pitfalls` section 4).
- Public stud tiles: `rbxassetid://6927295847` (4x4 chunky, TileSize 50-70 px, ImageTransparency 0.7), `12055407192` (2x2), `10509831729`. Roqer's 92521981645530 and 91084849147872 belong to another group. Safest: make our own stud and sunburst tiles and upload them under the game's group.
- Icons:
  - source: DevJoob's Simulator Icon Pack (Creator Store 99176447965360, +392/-8 votes, 125 icons in this look) for every standard icon; ranking, ids and the steps are in `roblox-store-art-pack` section 4. for the game's own items render their models, and generate only when the user asks, matched to the pack; never draw icons from frames or lines;
  - one family: same canvas, outline weight, light direction, flat colors, no text inside;
  - `ScaleType.Fit` with the aspect locked;
  - never tint full-color art with ImageColor3; white art tinted by ImageColor3 is fine;
  - many small icons go on one 1024 px sprite sheet with ImageRectOffset/ImageRectSize.
- Free community textures: ui-resources.com (stud textures, sunbursts, halftones). Some ".png" files are really WebP, so convert them with `sips -s format png`. Credit the creators.

## 9. Reference screens (owner's own prototype)

Six screenshots in `references/` show the look at work: a simulator HUD with a left menu column, right-side offer buttons and a bottom action bar, over a blurred 3D world. Open them when restyling; match the structure and weights, not the exact art.

| File | Shows |
|---|---|
| `house-ui-hud.jpg` | Full HUD: currency top left, menu column left, offer tiles right, auto-action bar and damage meter bottom |
| `house-ui-shop.jpg` | Shop panel: title tab with icon, four product cards, small price pills, red close button |
| `house-ui-rewards.jpg` | Daily rewards: day grid with a highlighted current day, claim buttons, group reward row |
| `house-ui-quests.jpg` | Quest list: icon, progress bar, reward chip, green claim button |
| `house-ui-playtime.jpg` | Playtime rewards: 4x3 grid of timed rewards with countdowns |
| `house-egg-panel-robux.jpg` | World-space egg station label with hatch buttons and a paid hatch option |

## 10. Review routine (after every UI change)

Run the UI review in `roblox-engine-2026` section 2 ("UI review before done"), then put our screenshot beside a reference frame at the same viewport, desktop and phone. World labels (section 6) do not appear in `screen_capture`: check them by properties (`Enabled`, `Adornee`, `Size`, `MaxDistance`, text) and by eye in a play session (`roblox-pitfalls` section 3, 'Screenshots in Play').
