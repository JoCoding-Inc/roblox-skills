---
name: roblox-ui-typography
description: "Use when choosing or fixing fonts and text style in any Roblox game: which fonts exist (built-in and Creator Store, no uploads), a display and body pair per genre, Font API, readability on phones, stroke and shadow, text performance, numbers and damage numbers, and fonts for Korean, Japanese, Chinese, Arabic and Thai."
when_to_use: "Also when UI text looks generic, blurry, jagged, too small or unreadable over the 3D world; when text flickers on phones; when numbers jitter while counting; when Korean or other non-Latin text renders broken or in the wrong font; when a font name from an old tutorial (Gotham, Arial) no longer works; in roblox-game-pipeline stage 3 (style board) to pick the font pair. Simulator/tycoon stud-style text specifics stay in roblox-ui-genre-studs section 3."
last_reviewed: 2026-11-03
sources:
  - https://create.roblox.com/docs/en-us/reference/engine/datatypes/Font.md and enums/Font.md (families, removed fonts)
  - https://create.roblox.com/docs/en-us/projects/assets.md (fonts cannot be imported; updated 2026-11-02)
  - Creator Store fonts category via apis.roblox.com/toolbox-service/v1/marketplace/73 (91 fonts, all by Roblox, read 2026-11-03)
  - https://create.roblox.com/docs/en-us/reference/engine/classes/TextLabel.md, TextService.md, UIStroke.md, enums/StrokeSizingMode.md, ui/rich-text.md
  - https://create.roblox.com/docs/en-us/production/publishing/accessibility.md (PreferredTextSize)
  - https://create.roblox.com/docs/en-us/resources/builder-font-license.md
  - DevForum staff posts on the font atlas (t/1515743) and UIStroke update (t/3958036, 2025-09-25); Release 731 FreeType thread (t/4757666)
  - DevForum community threads on overused fonts (t/4128957, t/3435304) and CJK fallback (t/4566304, t/674438)
  - original (genre pairs and sizes are judgment; test on a phone)
---

# UI typography for Roblox games

Fonts are part of the look: pick them in the style board (stage 3 of `roblox-game-pipeline`), next to the palette, not at the end.

## 1. What you can use

- **No uploads.** Roblox does not import font files (docs, 2026-11-02). Choose from:
  - built-in families: `Font.fromName("FredokaOne")` or `Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold)`;
  - Creator Store fonts (91, all published by Roblox, read 2026-11-03): `Font.fromId(id)` or `Font.new("rbxassetid://<id>")`. In the Studio font picker, click Install first.
- `Enum.Font` is legacy; set `FontFace` with the `Font` datatype. Removed fonts map silently: Gotham family to Montserrat, Arial and ArialBold to Arimo.
- Check which weights and italics a family really has with `TextService:GetFamilyInfoAsync(familyId)` before relying on Bold or Heavy.
- Lettering that no font gives you (a logo, a title with effects) is an image. Use it only for fixed brand words: images do not localize (`roblox-store-art-pack` section 6).
- The Builder fonts (Builder Sans, Extended, Mono) are licensed for Roblox experiences and their digital promotion, not for merchandise.

## 2. Pick a pair

- At most 2 fonts in the whole game: one **display** (titles, buttons, big numbers) and one **body** (descriptions, settings, dialog). One font with two weights is also fine.
- Show, do not describe: in Studio, make a temporary ScreenGui with the game name, a button label, a big number and one body line in each candidate pair, `screen_capture` it at phone size, let the user pick, then delete it. AI images misspell text, so do not use generated images to choose fonts.
- FredokaOne and Poppins are on many front-page games (community opinion), so they read as default. If the game uses them, stand out with stroke color, gradients and layout, or pick a less common display face.

| Genre | Display (try first) | Body |
|---|---|---|
| Simulator, tycoon, obby | FredokaOne, LuckiestGuy, DenkOne, Londrina Solid* | Nunito, BuilderSans |
| Horror | SpecialElite, Jolly Lodger*; Creepster, Nosifer*, Eater* for titles only | SourceSansPro |
| Anime, battlegrounds, fighting | Bangers, Teko*, Antonio*, Oswald | RobotoCondensed, Barlow* |
| RNG, idle, number-heavy | Goldman*, Rubik*, DenkOne; Bungee Inline* for titles | BuilderSans |
| Sci-fi | Michroma, Jura, Sarpanch, Audiowide*, Rajdhani* | TitilliumWeb, Roboto |
| Fantasy, RPG | Fondamento, GrenzeGotisch, RomanAntique | Merriweather |
| Cozy, story | PatrickHand, Kalam | Nunito |
| Retro, pixel | PressStart2P, Silkscreen* | Silkscreen* |

`*` = Creator Store font. Ids (read 2026-11-03): Londrina Solid 113086061264643, Jolly Lodger 77368255811694, Nosifer 12187377325, Eater 12187372382, Teko 12187376174, Antonio 122516982241677, Barlow 12187372847, Goldman 115884882777577, Rubik 12187365977, Bungee Inline 12187370000, Audiowide 12187360881, Rajdhani 12187375422, Silkscreen 12187371840. The table is judgment: test each pick on a phone before locking it.

## 3. Readable on a phone

- Sizes (judgment, at 1080p design scale): body 14 or more, key labels and buttons 20 or more; never below the docs floor of `MinTextSize` 9. Stud-style games use their own larger minimums (`roblox-ui-genre-studs` section 3).
- Text over the 3D world needs a stroke (`UIStroke` on the label) or a `UIShadow`; check contrast against the brightest and darkest spot the label can sit on.
- Avoid Thin, ExtraLight and Light weights below about size 24: since the July 2026 FreeType update (Release 731), thin text and BillboardGui text look jagged on low-DPI screens (staff and community reports).
- Prefer `AutomaticSize` plus `TextWrapped` over `TextScaled` (the docs recommend it). The player's Text Size setting (`GuiService.PreferredTextSize`) does not scale `TextScaled` text, and `TextScaled` stops at 100. If you use it, add a `UITextSizeConstraint`.
- Long strings: `TextTruncate` (AtEnd) and check `TextFits` after localization.

## 4. Stroke, shadow, rich text

- `UIStroke.StrokeSizingMode = ScaledSize` makes stroke thickness follow the font size on text, so it scales with the screen without code. Several strokes on one label stack by `UIStroke.ZIndex`; a stroke can take a `UIGradient` child.
- Never tween `UIStroke.Thickness` or `TextSize`: every in-between size renders new glyphs. Pulse color, transparency or a parent `UIScale` instead.
- Keep visible strokes under about 300 for low-end devices (staff guidance, 2025-09-25).
- `RichText = true` gives `<b>`, `<i>`, `<stroke>`, `<font color size face family weight>`, `<uc>`, `<sc>`, `<mark>`, `<br/>`. Localization strips the tags, so put them back in each translation.

## 5. Performance

- Each font + size + DPI combination is a separate glyph set in a shared atlas; a full atlas flickers on phones (staff). Keep few font and size combinations, and reuse them.
- BillboardGui: set `MaxDistance`. SurfaceGui: lower `PixelsPerStud` instead of huge `TextSize`.
- Typewriter text: animate `MaxVisibleGraphemes`, not the string.
- Fonts load asynchronously: put the first screen's fonts in loading tier 0 (`ContentProvider:PreloadAsync`, `roblox-store-art-pack` section 7). Wrap `TextService:GetTextBoundsAsync` in `pcall`.

## 6. Numbers and damage numbers

- One number formatter for the whole game (K, M, B; truncate, never round up into the next suffix).
- Counters that jitter while counting: try `OpenTypeFeatures = "tnum"` (tabular digits) and read `OpenTypeFeaturesError`; not tested yet. If it errors, use a mono font for the counter only (RobotoMono, BuilderMono).
- Damage numbers: pooled BillboardGui labels with `MaxDistance`, stroke or shadow, rise and fade over about 0.6 s. A crit changes color and jumps to one larger size; never scale text continuously.

## 7. Other languages

- Pick fonts that cover the target languages: Korean Nanum Gothic (12187361718); Japanese M PLUS Rounded 1c (12188570269), IBM Plex Sans JP (12187364147); Chinese Noto Serif SC (12187376739), Noto Serif TC (12187368093); Arabic Cairo (12187377099), Tajawal (12187377588); Thai Kanit (12187373592), Prompt (12187607287). Coverage is from the font names, not tested.
- Characters missing from the chosen font fall back to a default font, so a Latin display face shows Hangul in a different style (community reports; the docs do not describe fallback). A Hangul sign on a SurfaceGui has rendered broken (`roblox-pitfalls`). Test one sentence per language on a ScreenGui, a SurfaceGui and a BillboardGui before shipping.
- Leave 30-40 percent spare width for translations (judgment). Turn `AutoLocalize` off on player names, codes and numbers. Arabic needs right-to-left layout (`StarterGui.RtlTextSupport`, on by default).

## 8. Checklist

| Check | Pass |
|---|---|
| 2 fonts or fewer, chosen with the user from a specimen screenshot | yes |
| No `Enum.Font` Gotham or Arial left in code | yes |
| Phone-size screenshot: every label readable, none under the size floor | yes |
| No tweened `TextSize` or stroke `Thickness` | yes |
| Counters do not jitter; one number formatter | yes |
| One sentence per shipped language tested on screen, sign and billboard | yes |
