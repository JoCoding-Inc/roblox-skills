# UI style cards

Four example screens the agent shows in stage 3 (section 3, step 4) so the user can point at a UI style. Each card is one real screen of a 2025-26 hit, redrawn with gwanggo (`gpt-image-2.5`, quality high, 2026-11-03; prompt under "gwanggo image"): the user interface stays as the original drew it (layout, panel and header shapes, borders, colors, fonts, tags, buttons, HUD positions), so the card shows the real style at the real density; the content is new (item names, prices and currency amounts, item and icon art, the world). Where the frame itself is drawn art (stud chunky), its shape and colors stay and the ornament is new. No game names, logos or Robux icons appear; a few generic numbers (timers, level pills) can match the original. The game's own tone and manner comes after the pick (see "After the pick").

Evidence: the live Explore API charts on 2026-11-03 (top-playing-now, top-trending, up-and-coming, top-earning) and UI frames from 2026 gameplay videos of about 60 games. The 2025-26 risers (egg, pet, "+1", brainrot, dice and evolution games) use dense screens: a heavy outlined frame or a bright header, many small cards with stock, timer and odds labels, labeled side buttons and boost timers on the HUD. A one-day classification of top-50 concurrent players put about 84% in stud chunky, bright cards and dark flat looks plus the illustrated horror look.

| # | Style | File | Look | Fits | Redrawn from (by name, never copied) | Font (`roblox-ui-typography` section 2) |
|---|---|---|---|---|---|---|
| 1 | Soft dark | `soft-dark.jpg` | Dark navy list panel, a bright blue header bar with an icon, the title and a red square close, item rows with a dark icon tile, a name with a colored rarity, a luck line and an info button, blue price, Equip and Equipped buttons; labeled square side buttons and potion timers on the HUD | RNG, dice, gacha, anime collectors, number-heavy idle games | Anime Dice dice shop | Simulator or Anime/battlegrounds row |
| 2 | Stud chunky | `stud-chunky.jpg` | Chunky dark slate frame with a thick black outline, bolted plates and glowing crystal tanks on the corners, big white lettered header, a 3x2 grid of dark item cards with stock or timer labels and green gem price chips; green labeled side buttons on the left, round icon buttons on the right | Simulators, tycoons, steal/collect, "+1" clickers, pets and eggs | Steal An Egg experiment shop | Simulator row |
| 3 | Bright cartoon cards | `bright-cards.jpg` | Navy panel under an orange-to-yellow gradient header bar, a Featured pill, a rainbow gradient featured banner with a LIMITED tag and Buy 1 / Buy 3 buttons, a green gradient boost row with a GIFT button, big rounded type | Pet collecting, kid games, tap games, featured offers and limited eggs | Throw Food For Animals shop | Simulator or Cozy row |
| 4 | Dark flat compact | `dark-flat.jpg` | Near-black flat panel with a thin edge, an evolution tree of small dark tiles in tier rows with connector lines, locked tiles as silhouettes with "???", small pill tags (NEXT blue, UNLOCK! yellow, LV green), a detail card with stat bars and letter grades, one wide green SELECT button, a red square close | Evolution, upgrade and skill trees, collection and index screens with locked silhouettes, stat-heavy screens, survival, shooters, battlegrounds, RPG, tower defense | Bug Evolution bug tree | Anime/battlegrounds or Sci-fi row |

Other looks seen on the 2026-11-03 chart, for words or a live reference: Steal A Pet And Ride It (rarity-colored trail cards), Break and Steal an Egg (dark index with a big claim bar), Tap Simulator REBORN (gradient token cards), Fish It (translucent charcoal with gradient banners), Anime Dice index (navy grid of hidden silhouettes with odds labels and gold frames on rare slots; build it as a UIGridLayout of slots with an odds TextLabel, a gold UIStroke on rare slots and a ScrollingFrame past 12 slots), Tower Defense Simulator (true flat dark).

`studio-mock.jpg`: four simple presets built as a real ScreenGui in Studio by `scripts/ui_style_mock.luau` with the bundled icons, over a part-built world: a 2x2 shop with a color per item card (`rarity`, drawn as fill, line or tag), a tab header (`headerTab`), pill chips (`pills`), wide price buttons (`chipWide`). It is far plainer than the cards; build the picked card's real density (labels, timers, banners, side buttons, tags, stat bars) on top of it.

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
| Soft dark | Navy Frame at BackgroundTransparency 0.1, UICorner 8, header bar Frame with a blue UIGradient, an icon and a red close button, rows in a UIListLayout with a rarity TextLabel and a small stat line, text UIStroke 2 | Rows too tall for phone (keep 3 visible and scroll), thin stat text |
| Stud chunky | `roblox-ui-genre-studs` (UICorner, Border UIStroke, vertical UIGradient, lip Frame or 9-slice frame art with bolts and trim, UIGridLayout of cards with stock and timer labels, UIScale pop) | Text under 26 design px, too many UIStrokes, HUD over 15% of screen height |
| Bright cards | Header bar Frame with an orange-to-yellow UIGradient and a Featured pill, banner Frames with a rotated rainbow UIGradient, LIMITED tag, stacked Buy 1 / Buy 3 buttons, UIShadow on banners | White text on a rainbow needs a thick stroke; two banners fill a phone screen, so scroll the rest |
| Dark flat | Near-black Frame, UICorner 6, UIStroke 1; tiles placed per tier row with thin Frames as connector lines; a silhouette ImageLabel per locked tile (ImageColor3 black) with a "???" label; pill tags as small Frames with UICorner; a detail panel with stat bars (fill Frame sized by scale) and grade letters; one accent color for the main button | Tiny tag and stat text; a tree wider than a phone screen needs a ScrollingFrame; black silhouettes vanish without a lighter tile behind them |

Keep UIShadow instances to about 100 on screen. Check every style on a phone-size viewport (`roblox-engine-2026` UI rules). HUD text over the world (currency, timers) stays light with a dark stroke in every style.

## How to use

1. Pick the 2-4 styles whose "Fits" column matches the genre and the chosen lane, build a sheet of only those with `python3 -I <skill dir>/scripts/style_board.py ui.png --dir <skill dir>/assets/ui-styles --only soft-dark stud-chunky bright-cards`, and send it. Describe each in one line set in the user's game ("soft dark gym: slate panels, lime buy chips, dumbbell icons").
2. After the pick, ask: "Shall I make a design that matches your game's tone and manner?" Offer both ways in one line each and recommend the free Studio mockup unless the user wants a painted mood image:

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

To match a real hit's density (how the four cards were made), redraw one of its screens:

1. Grab frames with `scripts/ui_refs.py` and pick one frame with a whole open panel. A facecam, captions or a mouse cursor are fine; the prompt removes them.
2. Prompt: "Redraw this game screenshot as the screen of a different, original Roblox game. Keep the user interface exactly as it is: the same layout, number of cards and rows, panel shape, size and position, header bar, borders and outline thickness, corner radius, colors and gradients, font and text style, tabs, tags, buttons, icon style and size, spacing, and the same HUD buttons in the same places. Do not add ornaments, glow, crests or decorations that the screenshot does not have. Change only the content: new item names, new numbers, new item and creature art, redrawn icons in the same style, and a new background world. Use only coin or gem currency icons (no Robux icon). No real game names, no logos, no watermarks. Remove video captions, any streamer webcam or avatar overlay, and the Roblox client icons in the top corners. Keep all text crisp and readable." Then map each item in place ("Brood Mother becomes Void Jellyfish"), say what each item's art shows when it must match its label, give the new numbers, and name the new world. When the frame itself is drawn art (machine tubes, ornate borders), add: "keep its shape, thickness, outline and colors, but replace the decorative motifs with your own", or the card copies that art.
3. Send the frame as a data URL with the gwanggo CLI (no upload step): `gwanggo generate image "<prompt>" --model gpt-image-2.5 --quality high --aspect-ratio 16:9 --image-url "data:image/jpeg;base64,$(base64 -i frame.jpg)"`. Keep the file under about 700 KB so the command line fits. Tested 2026-11-03: 3 credits, 1088x608 output.
4. Put the result next to the original and check it: the UI must match (an added crest or glow, or a new header shape, means the style drifted), the content must not (item art, names or drawn frame ornament that are still the original's). Also check the top corners for leftover Roblox client icons, garbled labels, labels whose art shows another object, and numbers carried over from the frame. A garbled label on a flat tile can be repainted with Pillow (sample the tile color, redraw the name in a bold sans at the neighbors' cap height). An earlier prompt that asked to redesign every graphic changed the UI itself (new headers, crests and ornaments), so the cards stopped showing the real style.
