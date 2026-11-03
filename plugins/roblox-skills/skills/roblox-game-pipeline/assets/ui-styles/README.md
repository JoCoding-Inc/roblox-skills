# UI style cards

Four basic example screens the agent shows in stage 3 (section 3, step 4) so the user can point at a UI style. Every card shows the same screen (left menu column, currency bottom-left, settings top-right, an open shop with four items), so only the style changes. AI-generated with gwanggo (`gpt-image-2.5`, quality high, 2026-11-03): mood images, not Studio renders, not copies of any game. The cards stay basic on purpose; the game's own tone and manner comes after the pick (see "After the pick").

Evidence: the live top-50 chart on 2026-11-03 (Explore API `top-playing-now`) and HUD frames from 2026 gameplay videos of about 27 games. Stud chunky, bright cards and dark flat, plus the illustrated horror look in the themed table, covered about 84% of top-50 concurrent players (our own classification of a one-day snapshot). Soft dark was added later from a simulator screen the repository owner supplied and was not part of that count. Dark flat is mostly older hits; the 2025-26 breakouts (egg, "+1", brainrot games) use stud chunky and bright cards.

| # | Style | File | Look | Fits | Seen in (by name, never copied) | Font (`roblox-ui-typography` section 2) |
|---|---|---|---|---|---|---|
| 1 | Soft dark | `soft-dark.jpg` | Dark slate panel at about 85% opacity, 10-12 px corners, faint light border, no outline or header band; red close, green price chips, white digits with a thin dark stroke | Simulators, tycoons, clickers, any genre that wants a quiet neutral UI | a simulator screen supplied by the repository owner (not yet counted on the chart) | Simulator row |
| 2 | Stud chunky | `stud-chunky.jpg` | Rounded blocks, thick black outline, darker lip, gradient faces, faint studs; dark panel with one colored header band | Simulators, tycoons, steal/collect, "+1" clickers, pets and eggs | Steal a Brainrot, Steal An Egg, Throw Food For Animals | Simulator row |
| 3 | Bright cartoon cards | `bright-cards.jpg` | White or cream cards, colored tab header, pastel item cards, glossy green buy buttons | Pet collecting, kid games, tap games | Adopt Me, Pet Simulator 99, Tap Simulator | Simulator or Cozy row |
| 4 | Dark flat compact | `dark-flat.jpg` | Near-black slate, 1 px stroke, one accent color, small line icons, no gloss | Shooters, battlegrounds, sports, survival, RPG, fishing | Rivals, Blox Fruits, Forsaken, Volleyball Legends, Fisch | Anime/battlegrounds or Sci-fi row |

`studio-mock.jpg`: the same four styles built as a real ScreenGui in Studio by `scripts/ui_style_mock.luau` (the bright-cards one shows a game model in its first card). Show it next to the cards when offering the Studio mockup.

Themed looks (words only, no card; build them on the closest basic style when the game asks for it):

| Look | Words | Fits | Seen in | Base style |
|---|---|---|---|---|
| Anime neon and gold | navy-violet panel, gold header, rarity-colored glowing frames | Anime tower defense, gacha, anime fighters | Anime Adventures | Dark flat |
| Glam gloss | pink-violet gradients, white outline, glow, ribbon header | Fashion, dress-up, social | Dress To Impress | Bright cards |
| Dark ornate | pure black, thin bright frame with corner brackets, one glow color per item | RNG, aura collection, number-heavy idle | Sol's RNG | Dark flat |
| Cozy wood | wood planks, cream parchment cards, amber price pills | Farming, garden, cooking, shop sims | Grow a Garden | Bright cards |
| Illustrated | torn paper, hand-drawn ink outline, desaturated with one accent | Horror, survival, co-op | Dandy's World, DOORS, 99 Nights in the Forest | Dark flat (needs hand-drawn 9-slice art) |

Not carded: glass (frosted translucent panels), a designer trend with no confirmed top game; a native per-element UI blur is on the roadmap for early 2027, so today it needs a screen-wide `BlurEffect` or fake glass.

## Build notes per style

| Style | Build with | Phone risks |
|---|---|---|
| Soft dark | Frame BackgroundTransparency 0.1-0.2, UICorner 10-12, UIStroke 1-2 white at Transparency 0.8+, text UIStroke 2; scale transparency by `GuiService.PreferredTransparency` | Panel too clear over a busy world, thin gray text |
| Stud chunky | `roblox-ui-genre-studs` (UICorner, Border UIStroke, vertical UIGradient, lip Frame or 9-slice, tiled stud image, UIScale pop) | Text under 26 design px, too many UIStrokes, HUD over 15% of screen height |
| Bright cards | UICorner, colored UIStroke, UIGradient header, UIShadow on cards, UIGridLayout | White text on pastel needs a stroke; a white panel glares over a bright world |
| Dark flat | Frame with BackgroundTransparency 0.1-0.4, UICorner 6, UIStroke 1, small UIShadow | Tiny text, low contrast over bright maps, 1 px strokes jag on low-DPI screens |

Keep UIShadow instances to about 100 on screen. Check every style on a phone-size viewport (`roblox-engine-2026` UI rules). HUD text over the world (currency, timers) stays light with a dark stroke in every style.

## How to use

1. Pick the 2-4 styles whose "Fits" column matches the genre and the chosen lane, build a sheet of only those with `python3 -I <skill dir>/scripts/style_board.py ui.png --dir <skill dir>/assets/ui-styles --only soft-dark stud-chunky bright-cards`, and send it. Describe each in one line set in the user's game ("soft dark gym: slate panels, lime buy chips, dumbbell icons").
2. After the pick, ask: "Shall I make a design that matches your game's tone and manner?" Offer both ways in one line each and recommend one:

   | Way | Cost | Gives | Best when |
   |---|---|---|---|
   | Studio mockup (`scripts/ui_style_mock.luau`) | Free | A real ScreenGui in the game's own place: real Roblox fonts, strokes and corners, the game's own item models in the cards, the game's world behind it. Close to buildable | Studio MCP is connected and the place has a world or items (default) |
   | gwanggo image (prompt below) | about 3 credits each on `gpt-image-2.5` high; quote and ask first | A mood image with the game's world and themed ornament (wood, gold, glam) that parts and frames cannot draw yet | No place yet, or the user wants a themed look explored before building |

3. Show 2-3 variants, let the user pick or mix, and record the pick in the brief as `UI style: <name>` with the font pair and the palette.

### Studio mockup

1. Read `scripts/ui_style_mock.luau` and edit only `CONFIG`: `preset` (closest basic style), `override` (palette, font, corners from the brief; keys are those of `PRESETS`, for example `{ font = Font.fromName("LuckiestGuy"), chip = Color3.fromRGB(150, 230, 40) }`), `title`, `currency`, and `items` with `model = <a Model or Part in the game>` where the game has items.
2. Run it with Studio MCP `execute_luau` in Edit mode on the user's game place (never another project's window), then `screen_capture` with `camera_position` and `look_at_position` on a typical spot of the world.
3. Send the image. For each variant change `override` and run again (it replaces the previous mock).
4. Afterwards delete `StarterGui.UiStyleMock` and `Lighting.UiStyleMockBlur`; the script adds nothing else.

Icons are drawn with frames (bag, backpack, gift, gear); real icons come later from `roblox-store-art-pack` section 6. Tested 2026-11-03 in Studio at 1309x747: all four presets and the model path.

### gwanggo image

Keep the layout block identical and change only the style words (themed table words, the game's palette and props).

```
A 16:9 landscape screenshot of a mobile game interface, UI only over a softly blurred <the game's world> background. Layout: bottom-left currency readout with a coin icon and digits only; left edge a column of 3 square menu buttons with icons (shop bag, backpack, gift) and no text; top-right one round settings button; center an open shop panel about 55% of the width with a header bar holding a shop-bag icon, a close button with an X, and a 2x2 grid of item cards (<4 items from the game>) with price chips (coin icon and digits). No readable words, digits only. No logos, no watermarks, no real game names, no characters. Large tap targets, high contrast. Style: <style words>.
```

Use 16:9, quality high, and compress to JPEG at or under 200 KB and 1024 px wide.
