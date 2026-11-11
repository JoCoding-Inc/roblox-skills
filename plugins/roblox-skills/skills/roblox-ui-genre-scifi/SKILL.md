---
name: roblox-ui-genre-scifi
description: "Use for sci-fi, military, mech, space, tower defense and shooter HUDs and menus in Roblox built without uploading images: cut-corner panels, thin accent edges, hazard stripes, translucent dark glass, segmented wave and health bars, corner brackets, palette and fonts, Creator Store 9-slice frame art vs primitives, and a review against the mockup. Also when a non-stud UI looks flat, grey, boxy or cheap; when a dark HUD needs angled panels or hazard details; when the user asks for a futuristic, tech, cyber or military look; before calling such a UI done. Stud chunky (simulator, tycoon) is roblox-ui-genre-studs; placement and sizes are roblox-ui-layout; fonts are roblox-ui-typography."
last_reviewed: 2026-11-08
sources:
  - https://create.roblox.com/docs/reference/engine/classes/UIGradient (Scale, TileMode, performance notes)
  - https://create.roblox.com/docs/reference/engine/classes/Path2D (closed stroked paths, at most 100 control points)
  - https://create.roblox.com/docs/reference/engine/classes/GuiObject (ClipsDescendants and rotation)
  - DevForum 4846594 "[Full Release] Upgraded UI Gradients" (update of 2026-10-29) and 4737864 (clipping of rotated elements and Path2D)
  - Studio 0.746 tests, 2026-11-08 (scripts/hud_shapes.luau, references/hud-shapes-demo.jpg)
  - Creator Store search with roblox-store-art-pack scripts/store_icons.py (2026-11-08)
  - original field notes (a tower defense game, 2026-11-08)
---

# Sci-fi and military UI without uploads

`references/hud-shapes-demo.jpg` is our own Studio render of the recipes below (wave strip, build panel, boss banner, resource readout). Icon slots are left empty on purpose: icons come from a store pack.

## 0. Look before you build

- Pick the UI style with the user first: `roblox-game-pipeline` section 3, step 4 (style cards in `assets/ui-styles/` and the free Studio mockup `scripts/ui_style_mock.luau`). This look builds on the dark flat card. Skipping that step led one agent straight to paid image mockups (field note, 2026-11-08).
- Before any UI code, write a look table from the chosen mockup or reference frame: panel shape (which corners are cut), fill (opaque or glass, how transparent), edge (width and color), accent colors and where they go, fonts, icon style, density (labels, timers, tags per card).
- Icons come from the Creator Store by default (`roblox-store-art-pack` section 4; the monochrome white glyph pack fits this look, tinted with `ImageColor3`); generated icons only when the user asks. Never build icons from Frames, lines, Path2D, parts or emoji (a house from a triangle and a box, an arrow from rotated bars), and never let a UI agent improvise them (owner rule, 2026-11-08: "don't make icons, use the store ones").

## 1. The look in numbers

Starting points from our demo (judgment); replace them with the chosen mockup's values. The `sci-fi` preset of `roblox-game-pipeline/scripts/ui_style_mock.luau` holds the same colors and font for a quick mockup (square corners only).

| Element | Start with |
|---|---|
| Panel fill | near-black blue (12, 20, 32) at `BackgroundTransparency` 0.15-0.3, times `GuiService.PreferredTransparency` (`roblox-engine-2026` section 2) |
| Edge | a 1-2 px line in the accent color (Path2D), never a thick black outline |
| Accents | one main (cyan 80, 220, 255), one warning (amber 255, 176, 32), red only for damage and lives |
| Corner cut | 8-16 px; top bars cut top-left and bottom-right, panels all four, cards the other diagonal |
| Text | the sci-fi pair in `roblox-ui-typography` section 2 (Michroma, Jura or Sarpanch for display; TitilliumWeb or Roboto for body), light on dark; a stroke only for text over the world |
| Detail | one or two per panel: a header tab, a 3-4 px role-color bar on each card, corner brackets; stripes only on warnings |

## 2. Shapes from primitives (`scripts/hud_shapes.luau`)

Put the module in a ModuleScript and require it from client UI code. Tested in Studio 0.746 (2026-11-08), also under a `UIScale` of 1.3 and on a Scale-sized frame.

| Shape | How | Note |
|---|---|---|
| Cut-corner panel (`chamfer`) | An axis-aligned Frame with `ClipsDescendants` holds one Frame rotated 45 degrees. A half extent of ((w + h) / 2 - cut) / sqrt(2) cuts two opposite corners by `cut`; set it on both axes to cut all four | One piece, so glass has no seams or darker overlaps. It recomputes on `AbsoluteSize` changes and counts ancestor `UIScale` |
| Edge line | A closed `Path2D` through the cut corners, points as `UDim2` scale plus offset so it follows resizes | A `UIStroke` on the rotated fill does not work: the clip cuts it off along the straight edges |
| Glass sheen | `UIGradient` on the fill, `Rotation` = 90 minus the fill's rotation (45 for a 45-degree fill), `Transparency` 0.45 to 0 | Lighter at the top |
| Hazard or diagonal stripes (`stripes`) | A white Frame, `UIGradient` with hard stops (two keypoints at 0.5 are allowed), `Scale` 0.1-0.15, `TileMode` Repeat, `Rotation` 45 | `Scale` and `TileMode` are fully released since 2026-10-29 |
| Segmented bar (`segments`) | The fill Frame is `filled / n` of the track; a `UIGradient` `Transparency` hard step makes the gap, `Scale` = 1 / filled, `TileMode` Repeat | One Frame for any n: waves, health, shields, charge |
| Corner brackets (`brackets`) | Two thin Frames per corner of a frame a few px larger than the panel | |

- Clipping rules (docs): a non-rotated parent clips rotated children and Path2D (default since 2026-09-24; the opt-out `StarterGui.ClipsDescendantsSupportsRotation` no longer exists in Studio 0.746). A rotated parent does not clip, and a `UICorner` on the clipping frame does not round the clip: both need a `CanvasGroup`.
- Cost (docs): at most 6 color stops per `UIGradient`; animate `Offset` or `Rotation`, not `Color` or `Transparency`; no `UIGradient` on text with `TextStrokeColor3`. Dark gradients showed a banding regression at full release (staff post, 2026-10-29); check dark sheens on a phone.
- Glass from several pieces: translucent frames go darker where they overlap. Make the pieces opaque inside one `CanvasGroup` per plate and set its `GroupTransparency` instead (tested 2026-11-08; CanvasGroup rules in `roblox-engine-2026` section 2). A glass plate in a world `BillboardGui` needs `GroupTransparency` 0 there (field note, 2026-11-11).
- A chamfered panel is 3 Frames plus a Path2D. Build cards from it, not every small chip; small chips can stay rectangles. Size a plate from its content, not with `AutomaticSize` (`roblox-ui-layout` section 4).

## 3. Creator Store frame art vs primitives

| | Primitives (`hud_shapes.luau`) | Creator Store frame images (9-slice) |
|---|---|---|
| Cost | Free, nothing uploaded | Free, nothing uploaded; use the printed image id, never the decal id |
| Look | Clean vector edges; recolor by property or `StyleSheet` token | Painted bevels, glow and greebles that primitives cannot draw |
| One family | By construction | Single images from many creators, no votes on decals, uneven quality; some are other games' art (a "Star Citizen Hud" upload in our search) |
| Scaling | Exact at every size and `UIScale` | `ScaleType` Slice with `SliceCenter` on the art's border and a tuned `SliceScale`; corners blur when the frame is smaller than the art's corner |
| Theming | Any color, `PreferredTransparency` | `ImageColor3` tint only; baked colors stay |
| Risk | None | The image can be removed or moderated; quarantine and record the license (`roblox-store-art-pack` section 3) |

Our search on 2026-11-08 found no voted free sci-fi UI kit among store models (results were settings GUIs with scripts and another game's UI kit), and decal searches ("sci fi frame", "hud frame") returned single unvoted frames. So build the system from primitives. Take store frame art for one hero element (a boss banner, a title frame) only when one creator's set matches the look, and show it to the user next to the primitive version. Search with `store_icons.py "sci fi frame" "hud frame" --type decal` (`roblox-store-art-pack` section 4).

## 4. What got rejected

- A UI that copied the reference game's layout exactly but shipped flat opaque grey plates, heavy black outlines and crude hand-drawn icons: "is this the improved UI?" (owner, 2026-11-08). The layout matched; the look did not.
- One Frame, one color and a default font per element (`roblox-engine-2026` section 2, layers).
- Stripes, brackets and glows on everything. Detail marks what matters: warnings, the selected card, the boss.
- Stud-style thick black outlines and bubbly fonts: that is `roblox-ui-genre-studs`.
- Emoji or letters as icons.

## 5. Review before done

1. Works: `roblox-ui-layout` section 6 and the UI review in `roblox-engine-2026` section 2.
2. Looks: put the chosen mockup or reference frame and our screen side by side at the same viewport size. List every element with its gap (shape, fill, edge, color, font, icon, spacing, density) and fix it or record why it stays.
3. Show the side-by-side to the user and get a look verdict. Passing checks says the UI works, not that it looks right (`roblox-game-pipeline` section 0, rule 5).
