# UI style cards

Eight original example screens the agent shows in stage 3 (section 3, step 4) so the user can point at a UI style. Every card shows the same screen (left menu column, currency bottom-left, settings top-right, an open shop with four items), so only the style changes. AI-generated with gwanggo (`gpt-image-2.5`, quality high, 2026-11-03): mood images, not Studio renders, not copies of any game.

Evidence: the live top-50 chart on 2026-11-03 (Explore API `top-playing-now`) and HUD frames from 2026 gameplay videos of about 27 games. Styles 1, 3, 2 and 8 together covered about 84% of top-50 concurrent players (our own classification of a one-day snapshot). Style 3 is mostly older hits; the 2025-26 breakouts (egg, "+1", brainrot games) use styles 1 and 2.

| # | Style | File | Look | Fits | Seen in (by name, never copied) | Font (`roblox-ui-typography` section 2) |
|---|---|---|---|---|---|---|
| 1 | Stud chunky | `stud-chunky.jpg` | Rounded blocks, thick black outline, darker lip, gradient faces, faint studs; dark panel with one colored header band | Simulators, tycoons, steal/collect, "+1" clickers, pets and eggs | Steal a Brainrot, Steal An Egg, Throw Food For Animals | Simulator row |
| 2 | Bright cartoon cards | `bright-cards.jpg` | White or cream cards, colored tab header, pastel item cards, glossy green buy buttons | Pet collecting, kid games, tap games | Adopt Me, Pet Simulator 99, Tap Simulator | Simulator or Cozy row |
| 3 | Dark flat compact | `dark-flat.jpg` | Near-black slate, 1 px stroke, one accent color, small line icons, no gloss | Shooters, battlegrounds, sports, survival, RPG, fishing | Rivals, Blox Fruits, Forsaken, Volleyball Legends, Fisch | Anime/battlegrounds or Sci-fi row |
| 4 | Anime neon and gold | `anime-neon-gold.jpg` | Navy-violet panel, gold header, rarity-colored glowing frames, neon bokeh | Anime tower defense, gacha, anime fighters | Anime Adventures | Anime row |
| 5 | Glam gloss | `glam-gloss.jpg` | Pink-violet gradients, white outline, glow, ribbon header, sparkles | Fashion, dress-up, social | Dress To Impress | none yet: a rounded sans such as Nunito |
| 6 | Dark ornate | `dark-ornate.jpg` | Pure black, thin bright frame with corner brackets, one glow color per item | RNG, aura collection, number-heavy idle | Sol's RNG | RNG row |
| 7 | Cozy wood | `cozy-wood.jpg` | Wood planks, cream parchment cards, amber price pills, leaf-green buttons | Farming, garden, cooking, shop sims | Grow a Garden | Cozy row |
| 8 | Illustrated thematic | `illustrated.jpg` | Torn paper, hand-drawn ink outline, desaturated with one accent, grain and vignette | Horror, survival, co-op | Dandy's World, DOORS, 99 Nights in the Forest | Horror row |

Weak evidence: styles 5, 6 and 7 rest on one observed game each. Not carded: glass (frosted translucent panels), a designer trend with no confirmed top game; a native per-element UI blur is on the roadmap for early 2027, so today it needs a screen-wide `BlurEffect` or fake glass.

## Build notes per style

| # | Build with | Phone risks |
|---|---|---|
| 1 | `roblox-ui-genre-studs` (UICorner, Border UIStroke, vertical UIGradient, lip Frame or 9-slice, tiled stud image, UIScale pop) | Text under 26 design px, too many UIStrokes, HUD over 15% of screen height |
| 2 | UICorner, colored UIStroke, UIGradient header, UIShadow on cards, UIGridLayout | White text on pastel needs a stroke; a white panel glares over a bright world |
| 3 | Frame with BackgroundTransparency 0.1-0.4, UICorner 6, UIStroke 1, small UIShadow; scale transparency by `GuiService.PreferredTransparency` | Tiny text, low contrast over bright maps, 1 px strokes jag on low-DPI screens |
| 4 | UIGradient (radial and conical), colored UIShadow as glow, 9-slice rarity frames, ViewportFrame portraits | Busy screens, gradient and stroke count |
| 5 | UIGradient, white UIStroke, pink UIShadow glow, UICorner (1, 0) pills, sparkle images | Pastel text contrast, glow cost |
| 6 | Black Frame, UIStroke 1-2, corner brackets as 4 small Frames or a 9-slice, glow via colored UIShadow | Thin light text, tiny gray-on-black text |
| 7 | Brown Frame, dark UIStroke, tiled wood image, header UIGradient | Brown on brown contrast |
| 8 | 9-slice textured images (needs hand-drawn art), UIStroke on text, vignette, ColorCorrection | Small text on dark, 9-slice stretch, high art cost |

Keep UIShadow instances to about 100 on screen. Check every style on a phone-size viewport (`roblox-engine-2026` UI rules).

## How to use

Pick the 3-4 styles whose "Fits" column matches the genre and the chosen lane, build a sheet of only those with `python3 -I <skill dir>/scripts/style_board.py ui.png --dir <skill dir>/assets/ui-styles --only stud-chunky bright-cards dark-flat`, and send it. Describe each in one line set in the user's game ("stud chunky gym: lime buy buttons, dumbbell icons, orange header"). Then offer images of the user's own HUD and shop in the 2-3 closest styles (gwanggo, section 10a). Record the pick in the brief as `UI style: <name>` with the font pair.

Making a new card or an image of the user's own screen: keep the layout block identical and change only the style words.

```
A 16:9 landscape screenshot of a mobile game interface, UI only over a softly blurred <the game's world> background. Layout: bottom-left currency readout with a coin icon and digits only; left edge a column of 3 square menu buttons with icons (shop bag, backpack, gift) and no text; top-right one round settings button; center an open shop panel about 55% of the width with a header bar holding a shop-bag icon, a close button with an X, and a 2x2 grid of item cards (<4 items from the game>) with price chips (coin icon and digits). No readable words, digits only. No logos, no watermarks, no real game names, no characters. Large tap targets, high contrast. Style: <style words>.
```

Use 16:9, quality high (3 credits each on `gpt-image-2.5`), and compress to JPEG at or under 200 KB and 1024 px wide.
