# UI style cards

Four basic example screens the agent shows in stage 3 (section 3, step 4) so the user can point at a UI style. Every card shows the same screen (left menu column, currency bottom-left, settings top-right, an open shop with four items), so only the style changes. Each card was redrawn with gwanggo (`gpt-image-2.5`, quality high, 2026-11-03) from a collage of real shop and inventory panels of current chart games, used as a style reference only: layout, items, text and world are ours, and no game's art, names or logos are copied. The cards stay basic on purpose; the game's own tone and manner comes after the pick (see "After the pick").

Evidence: the live Explore API charts on 2026-11-03 (top-playing-now, top-trending, up-and-coming, top-earning) and UI frames from 2026 gameplay videos of about 55 games. Stud chunky, bright cards and dark flat, plus the illustrated horror look in the themed table, covered about 84% of top-50 concurrent players (our own classification of a one-day snapshot; soft dark was not part of that count). The 2025-26 risers on the chart (egg, pet, "+1" and brainrot games) nearly all use stud chunky; dark flat is mostly older hits and competitive games.

| # | Style | File | Look | Fits | Seen in (by name, never copied) | Font (`roblox-ui-typography` section 2) |
|---|---|---|---|---|---|---|
| 1 | Soft dark | `soft-dark.jpg` | Charcoal panel at about 85% opacity, small corners, thin light border, plain title with no header band, item cards on bright diagonal gradients, small dark price chips, small square red close | Simulators, fishing, tycoons, clickers: a quiet frame with loud items | Fish It | Simulator row |
| 2 | Stud chunky | `stud-chunky.jpg` | Dark navy panel, thick near-black outline, glossy colored header band with a stripe sheen, item cards in saturated rarity colors (green, blue, purple, red), chunky lime buttons with a darker lip, white text with a thick dark stroke | Simulators, tycoons, steal/collect, "+1" clickers, pets and eggs | Break and Steal an Egg, Steal A Pet And Ride It, +1 Spider Arm, +1 Venom Evolution, Steal An Egg, Steal a Brainrot | Simulator row |
| 3 | Bright cartoon cards | `bright-cards.jpg` | White panel with a light blue outline, a colored tab label on the top-left corner, pill tab chips, light blue item cards with rarity pill tags, glossy green buy buttons | Pet collecting, kid games, tap games, unit shops | Arm Wrestle Simulator, Toilet Tower Defense, Pet Simulator 99, Tap Simulator | Simulator or Cozy row |
| 4 | Dark flat compact | `dark-flat.jpg` | Near-black slate, 8 px corners, 1 px gray border, small uppercase title, dark tiles with a thin rarity line, one accent color for buttons, no gloss | Shooters, battlegrounds, survival, evolution, RPG, tower defense | Bug Evolution, Tower Defense Simulator, Sniper Arena, Rivals, Blox Fruits | Anime/battlegrounds or Sci-fi row |

`studio-mock.jpg`: the four styles built as a real ScreenGui in Studio by `scripts/ui_style_mock.luau` with the bundled icons, over a part-built world. Its `PRESETS` follow the first version of the cards (one card color, no rarity colors); match `override` to the card the user picked.

Live references: `python3 -I <skill dir>/scripts/ui_refs.py <scratch dir> "Game A" "Game B" --query "shop inventory"` grabs frames from each game's newest gameplay video (last 90 days) and tiles them into `sheet.jpg`. Use it when the user names a game whose UI they like, or to refresh the "Seen in" column. The frames are other games' art: show them, never commit them.

`icons/`: nine 192 px PNG icons with alpha (gem, sword, egg, star, coin, bag, pack, gift, gear) for mockups until the game has its own. Made as one gwanggo sheet (`gpt-image-2.5` high, 3 credits, 2026-11-03) on a flat magenta background, keyed and sliced with Pillow. Make a game's own set the same way: one 3x3 sheet in its locked style, "flat solid pure magenta (#FF00FF) background, wide margins, no magenta inside the icons", then key out the magenta and cut each icon by its largest connected shape.

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
| Soft dark | Frame BackgroundTransparency 0.1-0.2, UICorner 8-10, UIStroke 1-2 white at Transparency 0.8+, item cards with a rotated UIGradient, text UIStroke 2; scale transparency by `GuiService.PreferredTransparency` | Panel too clear over a busy world, thin gray text |
| Stud chunky | `roblox-ui-genre-studs` (UICorner, Border UIStroke, vertical UIGradient, lip Frame or 9-slice, a rarity color per card, UIScale pop) | Text under 26 design px, too many UIStrokes, HUD over 15% of screen height |
| Bright cards | UICorner, colored UIStroke, UIGradient header, UIShadow on cards, UIGridLayout | White text on pastel needs a stroke; a white panel glares over a bright world |
| Dark flat | Frame with BackgroundTransparency 0.1-0.4, UICorner 6, UIStroke 1, small UIShadow | Tiny text, low contrast over bright maps, 1 px strokes jag on low-DPI screens |

Keep UIShadow instances to about 100 on screen. Check every style on a phone-size viewport (`roblox-engine-2026` UI rules). HUD text over the world (currency, timers) stays light with a dark stroke in every style.

## How to use

1. Pick the 2-4 styles whose "Fits" column matches the genre and the chosen lane, build a sheet of only those with `python3 -I <skill dir>/scripts/style_board.py ui.png --dir <skill dir>/assets/ui-styles --only soft-dark stud-chunky bright-cards`, and send it. Describe each in one line set in the user's game ("soft dark gym: slate panels, lime buy chips, dumbbell icons").
2. After the pick, ask: "Shall I make a design that matches your game's tone and manner?" Offer both ways in one line each and recommend one:

   | Way | Cost | Gives | Best when |
   |---|---|---|---|
   | Studio mockup (`scripts/ui_style_mock.luau`) | Free | A real ScreenGui in the game's own place: real Roblox fonts, strokes and corners, the bundled icons or the game's own, its item models in the cards, its world behind it. Close to buildable | Studio MCP is connected (default). It looks only as good as its icons and world: never draw icons with frames |
   | gwanggo image (prompt below) | about 3 credits each on `gpt-image-2.5` high; quote and ask first | A mood image with the game's world and themed ornament (wood, gold, glam) that parts and frames cannot draw yet | No place yet, or the user wants a themed look explored before building |

3. Show 2-3 variants, let the user pick or mix, and record the pick in the brief as `UI style: <name>` with the font pair and the palette.

### Studio mockup

1. Start the icon server in the background: `python3 -I <skill dir>/scripts/serve_icons.py <skill dir>/assets/ui-styles/icons [<game icon dir>]` (later folders override by name). Icons stay local: Studio loads them over 127.0.0.1 into EditableImages, nothing is uploaded.
2. Read `scripts/ui_style_mock.luau` and edit only `CONFIG`: `preset` (closest basic style), `override` (palette, font, corners from the brief; keys are those of `PRESETS`, for example `{ font = Font.fromName("LuckiestGuy"), chip = Color3.fromRGB(150, 230, 40) }`), `title`, `currency`, `icons` (menu, settings, coin, title), and `items`, each with `icon = <served name or "rbxassetid://">` or `model = <a Model or Part in the game>`.
3. Run it with Studio MCP `execute_luau` in Edit mode on the user's game place (never another project's window), then `screen_capture` with `camera_position` and `look_at_position` on a busy, typical spot of the world (trees or buildings on both sides of the panel).
4. Send the image. For each variant change `override` and run again (it replaces the previous mock).
5. Afterwards delete `StarterGui.UiStyleMock` and `Lighting.UiStyleMockBlur` and stop the server. The script turns `HttpService.HttpEnabled` on only while it loads icons and restores it.

Tested 2026-11-03 in Studio at 1309x747: all four presets with the bundled icons, a 3D model in a card, `HttpEnabled` restored to off.

### gwanggo image

Keep the layout block identical and change only the style words (themed table words, the game's palette and props).

```
A 16:9 landscape screenshot of a mobile game interface, UI only over a softly blurred <the game's world> background. Layout: bottom-left currency readout with a coin icon and digits only; left edge a column of 3 square menu buttons with icons (shop bag, backpack, gift) and no text; top-right one round settings button; center an open shop panel about 55% of the width with a header bar holding a shop-bag icon, a close button with an X, and a 2x2 grid of item cards (<4 items from the game>) with price chips (coin icon and digits). No readable words, digits only. No logos, no watermarks, no real game names, no characters. Large tap targets, high contrast. Style: <style words>.
```

Use 16:9, quality high, and compress to JPEG at or under 200 KB and 1024 px wide.

To match a real game's look (how the four cards were made), add a reference image:

1. Grab frames with `scripts/ui_refs.py`, crop 2-4 clean panels (no facecam, no subtitles) and paste them into one collage.
2. Start the prompt with: "Redraw as an original mobile game UI screenshot. The attached image is a collage of UI panels from other games: use it ONLY as a style reference (panel shape and color, outline weight, header bar, card and button style, text style). Do not copy its layout, text, item art, characters or logos."
3. Send the collage as a data URL with the gwanggo CLI (no upload step): `gwanggo generate image "<prompt>" --model gpt-image-2.5 --quality high --aspect-ratio 16:9 --image-url "data:image/jpeg;base64,$(base64 -i collage.jpg)"`. Keep the collage under about 700 KB so the command line fits. Tested 2026-11-03: 3 credits, 1088x608 output.
4. Check the result for copied names, logos or item art before showing it.
