# Style lane cards

Eight original concept images the agent shows the user in stage 3 of `roblox-game-pipeline` so the user can point at a look instead of describing it. Seven are AI-generated mood images (RoDesigner, model `gpt-image-2.5`, 2026-11-03); `voxel.jpg` is a free headless Blender render (2026-11-04, recipe in `roblox-blender-export` section 4). None are Studio renders or copies of any game or brand. Use them to choose a direction; the real look is built in Studio.

| Card | File | Look | Palette to start from | Fits | UI feel |
|---|---|---|---|---|---|
| Chunky cartoon | `chunky-cartoon.jpg` | Thick outlines, candy colors, rounded oversized shapes, sunburst sky, stud floor | saturated green, sky blue, yellow, hot pink, black outlines | Simulators, tycoons, pet and collect games | Glossy outlined buttons with highlight lips (`roblox-ui-genre-studs`) |
| Classic blocky | `classic-blocky.jpg` | Plain primary-color parts on a green baseplate, flat sky | red, blue, yellow, green | Obbies, classic builds, nostalgia | Dark flat compact bars, small square icons (`../ui-styles/dark-flat.jpg`); parts with studs on every face (`../part-looks/`) |
| Low-poly stylized | `low-poly.jpg` | Flat-shaded facets, few colors per object, warm sunset | teal, orange, olive, warm gray | Adventure, exploration, RPG | Thin rounded panels, pictogram icons |
| Anime cel | `anime-cel.jpg` | Ink outlines, flat fills, hard shadows, dramatic sky | electric blue, magenta, white, deep navy | Action RPG, fighting, gacha-like | Angled sleek HUD, skill icons |
| Cozy pastel | `cozy-pastel.jpg` | Soft light, rounded props, muted colors | peach, mint, lavender, cream | Farming, decorating, social, roleplay | Cream rounded cards, pastel buttons |
| Dark horror | `dark-horror.jpg` | Low light, fog, desaturated, one warm light | gray-green, black, one warm yellow | Horror, survival, escape | Minimal thin bars |
| Neon sci-fi | `neon-scifi.jpg` | Dark base, glowing cyan and magenta edges, bloom | navy, cyan, magenta | Racing, arena, sci-fi shooters | Holographic thin frames, gauges |
| Voxel | `voxel.jpg` | Everything built from cubes. Left half low-res (about 15 blocks tall, flat color per part, reads well on a phone); right half high-res (about 30 blocks tall, each block a slightly different shade). Pick one density per game | 3-4 colors per creature plus one accent (eyes) | Creature and pet collecting, monster evolution, survival and building | Chunky outlined buttons (`roblox-ui-genre-studs`) or dark flat bars |

How to use: pick the 3-4 cards whose "Fits" column matches the idea and build a sheet of only those with `python3 -I <skill dir>/scripts/style_board.py out.png --only chunky-cartoon cozy-pastel` (no `--only` shows all eight). These cards are generic: a card that clashes with the pitch confuses more than it helps. Send the sheet with a one-line description of each lane set in the user's game, ask "closest / opposite", then offer the user's own game in the closest looks: a Studio greybox per look (free, first), or images from an image generator the user has connected, cost quoted first (`roblox-game-pipeline` section 10a). Record the pick in the brief. Mix lanes if the user wants ("cozy but with thick outlines"). Add live-chart references of the same genre on top (stage 3, step 2).

More real examples live in `../examples/` (a loading screen) and in `roblox-ui-genre-studs/references/` (a stud-style HUD and shop). Those are the owner's own screens, included with permission.

Making a new card: prompt pattern `Game concept art for <genre> game, <lane look words>, <palette>, <scene>, in-game HUD with <UI feel>, icons only, no readable text. No logos, no real brand names.` Use 16:9, check it is not close to any toy or game brand, compress to JPEG at or under 200 KB and 1024 px wide.
