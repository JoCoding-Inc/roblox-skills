---
name: roblox-ui-genre-studs
description: "Use only for simulator/tycoon-style games (Steal a Brainrot, Steal An Egg, +1 Strength, Pet Simulator) whose HUD, shop, panels or world labels must match that chunky stud look: black outlines, lips, FredokaOne, quiet HUD zones. Not for horror, realistic or story games."
when_to_use: "Also when a simulator/tycoon UI looks generic, AI-made, too big, too dark or off-genre; before restyling its HUD, shop, rebirth, store, daily or codes panels; when picking stud/sunburst textures. For other genres use roblox-gui."
last_reviewed: 2026-10-26
sources:
  - https://github.com/S4US/Roqer (apps/desktop/agent/skills/roblox-ui-design, MODERN STUDS theme; AGPL-3.0-or-later; facts re-authored, no text copied)
  - https://github.com/hujhfrgrwg/HatchOrSnatch (.claude/skills/roblox-ui-maker LESSONS/STYLE/ROBLOX_FACTS; no license, facts only)
  - https://github.com/blauwtje/roblox-kit (skills/game-ui; MIT)
  - https://github.com/scenario-labs/skills (scenario-roblox-ui screen-budget; MIT)
  - original (reference-frame comparison of Steal An Egg, Steal a Brainrot, +1 Strength, 2026-10-26)
---

# Roblox genre UI: stud style

Pair with `roblox-gui` (layout, insets, input, lifecycle). This skill owns the genre LOOK. Numbers below are strong starting values from a few low-star sources. Confirm each one with a Studio screenshot next to a reference frame before treating it as a hard rule.

## 0. Look before you build

- Pull reference frames of 2-3 current top games in the same genre. YouTube storyboards work when clip downloads return 403: `yt-dlp -f sb0 -o sb.mhtml URL`, then extract the JPEGs from the mhtml with Python `email`.
- Store thumbnails come from `thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=...` and are marketing art, not HUD.
- Every UI task ends with our screenshot and a reference frame side by side at the same viewport, desktop and phone.

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

- Panels:
  - Body: dark `13,17,23`. Over a bright 3D world, 60% opacity reads see-through, so big bodies go 90% or more opaque.
  - Outline: black UIStroke 5-7.
  - Corners: UICorner 14-30.
  - One colored header band per panel (orange, blue or purple).
  - Optional faint 2 px white inner rim.
- Opening a panel: world BlurEffect plus a UIScale pop.

## 3. Text

- Font: `Font.fromEnum(Enum.Font.FredokaOne)`, with `GothamBlack` as the alternative. Never mix the two on one screen. At most 2 fonts in the whole game.
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
- Phone minimums: body text 26 design px or more, titles 40 or more (design px at 1920x1080).
- One number formatter: truncate and never round up into the next suffix (250K, not 0.3M).

## 4. HUD zones (1080p measurements, all in Scale)

- Treat the screen as a 3x3 grid. The centre 50% x 50% stays empty. Zones inset 2% or more.
- Nothing inside the top-left 350x70 px (Roblox core UI). Push top-corner groups below `GuiService.TopbarInset` at runtime.
- **Left:** menu tiles in 1-2 columns, vertically centred.
  - Tile `UDim2.new(0.065,0,0.115,0)` plus `UIAspectRatioConstraint` 0.97 (about 124 px at 1080p).
  - Icon at 0.8 of the face, with the label over the icon foot.
  - At most 6 tiles per side. Badges on at most 2 tiles; badges wobble or pulse color, never size.
- **Bottom-left:** currency readouts with no plate behind them.
  - Each row is about 7.5% of screen height, a small icon on the left and a gradient number on the right.
  - A small "+N/s" line goes under the main currency. A bare number with no icon is a defect.
  - On touch, keep this above the joystick zone.
- **Right:** small square icon buttons (store, daily, codes), plus up to 2 unframed offers. An offer is art on a sunburst at 0.17 of screen height with a green `0,255,8` price.
- **Top-centre:** one timer or objective, or at most 3 nav chips (13.6% x 7.5% each). Otherwise empty. Event banners are short ("RUN!!").
- **Quiet HUD:** show only per-second info (main currency, one goal, 4-5 buttons). Reveal secondary currencies and timers when they start to matter.
- Tap targets: 124 design px or more (about 48 screen px). Primary buttons 150-190. Keep the bottom-left joystick and bottom-right jump zones clear on touch.
- Never auto-claim rewards. Hide zero rewards. An unaffordable item is a grey plate, and tapping it says how much is missing.

## 5. Motion and polish

- **Panel open:** UIScale 0.85 -> 1 with a Back/Out ease, about 0.25-0.38 s. Close in about 0.18 s.
- **Buttons:** hover 1.06, press 0.92-0.94, about 0.12 s, through a UIScale child. Set `AutoButtonColor = false`.
- **Numbers:** count up over about 0.45 s.
- Never continuously scale anything that contains text, because text steps between whole font sizes. Pulse color, or rotate +-8 degrees (never inside a ScrollingFrame).
- Float images only: 10 px or more each way over 0.9-1.2 s.
- Scale every UIStroke by viewport height / 1080 (minimum 1). Add `UITextSizeConstraint` to TextScaled labels.
- Animate UIScale, not Size. Honor `GuiService.ReducedMotionEnabled`.

## 6. World labels (BillboardGui)

- No frame. Stacked stroked text over each pedestal or animal:
  - name (white);
  - rarity (rarity color, rainbow gradient for the top tier);
  - "$X/s" (yellow-green);
  - value or price.
- A green "Collect" pad in front of each pedestal, with its amount in stroked text.
- Floating income: large green "+$1.5M" with a black stroke that rises and fades. It is the main juice.
- Owner sign over the base: "<DisplayName>'s Base".

## 7. Anti-slop list

Each of these is a defect:
- emoji or letters as icons;
- more than 2 fonts or more than one corner-radius scale;
- stat text with a panel behind it;
- HUD elements over 15% of screen height (except panels);
- near-black navy giant panels;
- pills everywhere;
- one size of button for every importance;
- permanent upsell buttons;
- timer nag tips;
- a desaturate filter over a price.

## 8. Textures and icons

- Probe every image id before relying on it (`roblox-pitfalls` section 4).
- Public stud tiles: `rbxassetid://6927295847` (4x4 chunky, TileSize 50-70 px, ImageTransparency 0.7), `12055407192` (2x2), `10509831729`. Roqer's 92521981645530 and 91084849147872 belong to another group. Safest: make our own stud and sunburst tiles and upload them under the game's group.
- Icons:
  - one family: same canvas, outline weight, light direction, flat colors, no text inside;
  - `ScaleType.Fit` with the aspect locked;
  - never tint full-color art with ImageColor3; white art tinted by ImageColor3 is fine;
  - many small icons go on one 1024 px sprite sheet with ImageRectOffset/ImageRectSize.
- Free community textures: ui-resources.com (stud textures, sunbursts, halftones). Some ".png" files are really WebP, so convert them with `sips -s format png`. Credit the creators.
