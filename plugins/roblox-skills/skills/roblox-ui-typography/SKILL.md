---
name: roblox-ui-typography
description: "Use when choosing or fixing fonts and text style in any Roblox game: which fonts exist (built-in and Creator Store, no uploads), a display and body pair per genre, Font API, readability on phones, stroke and shadow, text performance, numbers and damage numbers, and fonts for Korean, Japanese, Chinese, Arabic and Thai. Also when UI text looks generic, blurry, jagged, too small or unreadable over the 3D world; when text flickers on phones; when numbers jitter while counting; when Korean or other non-Latin text renders broken or in the wrong font; when a font name from an old tutorial (Gotham, Arial) no longer works; in roblox-game-pipeline stage 3 (style board) to pick the font pair. Simulator/tycoon stud-style text specifics stay in roblox-ui-genre-studs section 3."
last_reviewed: 2026-11-20
sources:
  - https://create.roblox.com/docs/en-us/reference/engine/datatypes/Font.md and enums/Font.md (families, removed fonts)
  - https://create.roblox.com/docs/en-us/projects/assets.md (fonts cannot be imported; updated 2026-11-02)
  - Creator Store fonts category via apis.roblox.com/toolbox-service/v1/marketplace/73 (91 fonts, all by Roblox, read 2026-11-03)
  - https://devforum.roblox.com/t/4934553 (upgraded UIShadow full release, staff update 2026-11-05, read 2026-11-20)
  - https://create.roblox.com/docs/en-us/reference/engine/classes/TextLabel.md, TextService.md, UIStroke.md, enums/StrokeSizingMode.md, ui/rich-text.md
  - https://create.roblox.com/docs/en-us/production/publishing/accessibility.md (PreferredTextSize)
  - https://create.roblox.com/docs/en-us/resources/builder-font-license.md
  - DevForum staff posts on the font atlas (t/1515743) and UIStroke update (t/3958036, 2025-09-25); Release 731 FreeType thread (t/4757666)
  - DevForum community threads on overused fonts (t/4128957, t/3435304) and CJK fallback (t/4566304, t/674438)
  - original (genre pairs and sizes are judgment; test on a phone)
---

# UI typography for Roblox games

Fonts are part of the look: pick them in the style board (stage 3 of `roblox-game-pipeline`), next to the palette and the UI style card (section 3, step 4, with a free Studio mockup), not at the end.

## 1. What you can use

- **No uploads.** Roblox does not import font files (docs, 2026-11-02). Choose from:
  - built-in families: `Font.fromName("FredokaOne")` or `Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold)`;
  - Creator Store fonts (91, all published by Roblox, read 2026-11-03): `Font.fromId(id)` or `Font.new("rbxassetid://<id>")`. Set from a script, they load without the picker's Install step (tested 2026-11-03 in a fresh place: Nanum Gothic, Londrina Solid, Goldman).
- `Enum.Font` is legacy; set `FontFace` with the `Font` datatype. Removed fonts map silently: Gotham family to Montserrat, Arial and ArialBold to Arimo.
- Check which weights and italics a family really has with `TextService:GetFamilyInfoAsync(familyId)` before relying on Bold or Heavy.
- Italic (speed and sports type): `Font.new(family, weight, Enum.FontStyle.Italic)`. Built-in families with real italic faces (`GetFamilyInfoAsync`, Studio, 2026-11-22; weights in brackets): TitilliumWeb (200-700), Nunito (200-900), SourceSansPro (200-900), Fondamento (400), RobotoMono (100-700), Montserrat (100-900), Merriweather (300-900), Arimo (400-700), Ubuntu (300-700), Roboto (100-900), RobotoCondensed (300-700), JosefinSans (100-700). The other built-in families have none, and Studio slants them when Italic is asked for (FredokaOne, LuckiestGuy and Oswald read on a capture: the upright letters, leaned). A real italic also changes the letterforms (Montserrat's on the same capture).
- Lettering that no font gives you (a logo, a title with effects) is an image. Use it only for fixed brand words: images do not localize (`roblox-store-art-pack` section 6).
- The Builder fonts (Builder Sans, Extended, Mono) are licensed for Roblox experiences and their digital promotion, not for merchandise.

## 2. Pick a pair

- Start from the row that matches the chosen UI style (`roblox-game-pipeline/assets/ui-styles/README.md` names it).
- At most 2 fonts in the whole game: one **display** (titles, buttons, big numbers) and one **body** (descriptions, settings, dialog). One font with two weights is also fine.
- Show, do not describe: in Studio, make a temporary ScreenGui with the game name, a button label, a big number and one body line in each candidate pair, `screen_capture` it at phone size, let the user pick, then delete it. AI images misspell text, so do not use generated images to choose fonts.
- FredokaOne and Poppins are on many front-page games (community opinion), so they read as default. If the game uses them, stand out with stroke color, gradients and layout, or pick a less common display face.

| Genre | Display (try first) | Body |
|---|---|---|
| Simulator, tycoon, obby | FredokaOne, LuckiestGuy, DenkOne, Londrina Solid* | Nunito, BuilderSans |
| Horror | SpecialElite, Jolly Lodger*; Creepster, Nosifer*, Eater* for titles only | SourceSansPro |
| Anime, battlegrounds, fighting | Bangers, Teko*, Antonio*, Oswald | RobotoCondensed, Barlow* |
| RNG, idle, number-heavy | Rubik* (equal-width digits), Goldman*, DenkOne; Bungee Inline* for titles | Nunito (equal-width digits) |
| Sci-fi | Michroma, Jura, Sarpanch, Audiowide*, Rajdhani* | TitilliumWeb, Roboto (Sarpanch, Rajdhani and TitilliumWeb draw small: section 3) |
| Fantasy, RPG | Fondamento, GrenzeGotisch, RomanAntique | Merriweather |
| Cozy, story | PatrickHand, Kalam | Nunito |
| Retro, pixel | PressStart2P, Silkscreen* | Silkscreen* |

`*` = Creator Store font. Ids (read 2026-11-03): Londrina Solid 113086061264643, Jolly Lodger 77368255811694, Nosifer 12187377325, Eater 12187372382, Teko 12187376174, Antonio 122516982241677, Barlow 12187372847, Goldman 115884882777577, Rubik 12187365977, Bungee Inline 12187370000, Audiowide 12187360881, Rajdhani 12187375422, Silkscreen 12187371840. The table is judgment: test each pick on a phone before locking it.

## 3. Readable on a phone

- Sizes (judgment, at 1080p design scale): body 14 or more, key labels and buttons 20 or more; never below the docs floor of `MinTextSize` 9. Phone sizes at `UIScale` 1 (14 px panel body text; bold HUD labels and numbers with a stroke or on an opaque plate 12 px or more): `roblox-ui-layout` section 4. Stud-style games use their own larger minimums (`roblox-ui-genre-studs` section 3). These are UI px at `UIScale` 1, the same on phone and desktop (`roblox-ui-layout` section 0). A layout that scales everything by viewport height / 1080 shrinks them to about a third on a 375 px tall phone (14 becomes about 4.9 px), so such a layout must still clamp text to the device px floors (12 bold stroked HUD, 14 body); found in RoDesigner's audit, 2026-11-12. These are floors, not comfortable sizes: Roblox staff call TextSize 20 or more readable on any device (DevForum t/1515743, 2021), so give text players read at length (panel body, dialog, shop descriptions) 18-20 where space allows (judgment).
- **TextSize is the line box, not the letters, and faces fill it differently.** Measured 2026-11-21 on a Studio capture ("H" and "x" at TextSize 100, bold, 48 faces): a capital is 0.43 to 0.75 of TextSize. The sizes above and the 14 px floor were set with faces near 0.52 (Nunito, SourceSansPro). For a face that draws smaller, raise TextSize by 0.52 / its share (the window kit does it: `Kit.textSize(px, face)`); do not shrink a face that draws larger. Field case: a sci-fi screen in Sarpanch and TitilliumWeb, every label TextSize 14 or more and lint clean, was marked down by two blind judges for "8-9 px labels" and a title read as "Flore Pock": its capitals were 6 px tall.

  | Capital / TextSize | Faces (capital / lowercase x, as shares of TextSize) |
  |---|---|
  | Small, 0.43-0.50: TextSize x1.05 to x1.2 | GrenzeGotisch 0.43 / 0.32, Sarpanch 0.45 / 0.35, Teko* 0.45 / 0.35, TitilliumWeb 0.45 / 0.33, Kalam 0.46 / 0.32, Goldman* 0.49 / 0.37, Silkscreen* 0.49 / 0.49, IndieFlower 0.50 / 0.33, Rajdhani* 0.50 / 0.40 |
  | Middle, 0.51-0.61 | PressStart2P 0.51 / 0.37, PatrickHand 0.52 / 0.37, Nunito 0.52 / 0.37, SourceSansPro 0.52 / 0.40, Fondamento 0.54 / 0.40, RobotoMono 0.55 / 0.41, Guru 0.55 / 0.40, Oswald 0.55 / 0.40, PermanentMarker 0.55 / 0.46, BuilderExtended 0.56 / 0.42, BuilderMono 0.56 / 0.42, BuilderSans 0.56 / 0.42, Michroma 0.56 / 0.42, Jura 0.57 / 0.43, Montserrat 0.57 / 0.44, Audiowide* 0.58 / 0.44, RomanAntique 0.58 / 0.35, Barlow* 0.59 / 0.44, Merriweather 0.59 / 0.44, Arimo 0.60 / 0.46, Inconsolata 0.60 / 0.44, Rubik* 0.60 / 0.44, Ubuntu 0.61 / 0.46, AmaticSC 0.61 / 0.52, Roboto 0.61 / 0.46, RobotoCondensed 0.61 / 0.46 |
  | Large, 0.63-0.75 | Balthazar 0.63 / 0.43, FredokaOne 0.63 / 0.48, LondrinaSolid* 0.63 / 0.46, BungeeInline* 0.64 / 0.64, Zekton 0.65 / 0.47, Antonio* 0.66 / 0.57, JollyLodger* 0.66 / 0.44, Creepster 0.69 / 0.67, DenkOne 0.70 / 0.50, Bangers 0.74 / 0.74, JosefinSans 0.74 / 0.44, SpecialElite 0.74 / 0.55, LuckiestGuy 0.75 / 0.73 |

  A face whose lowercase x is 0.35 or less (Sarpanch, Teko, GrenzeGotisch, RomanAntique, TitilliumWeb, Kalam, IndieFlower) loses its a, e and o under about 20 px: as a display face set it in capitals and digits, and put names in mixed case in the body face. A face not in the table: put "H" at TextSize 100 on a capture and measure it.
- World text sized in studs (SurfaceGui signs, BillboardGuis with a Scale size) shrinks with distance. On-screen height in px is about text height in studs x screen height in px / (2 x distance x tan(FOV / 2)): with the default 70 degree FOV on a 375 px tall phone screen that is about 268 / distance px per stud, so a 14 px floor needs letters about distance / 19 studs tall (2 studs at 40 studs away). Check boards from where players stand with the default camera (derivation, judgment).
- Text over the 3D world needs a stroke (`UIStroke` on the label) or a drop shadow (an offset copy of the label, or `UIShadow` text mode, fully released on 2026-11-05 but not re-tested by us since: `roblox-engine-2026` section 2); check contrast against the brightest and darkest spot the label can sit on: at least 4.5:1 for body text and 3:1 for large text (WCAG 2.x AA). `Color3:GetContrastRatio` returns the WCAG ratio (1 to 21) and `Color3:GetContrastingColor` picks readable text for a background (tested 2026-11-09: white against black gives 21, a near-black navy gets white, a yellow gets black).
- Avoid Thin, ExtraLight and Light weights below about size 24: since the July 2026 FreeType update (Release 731), thin text and BillboardGui text look jagged on low-DPI screens (staff and community reports).
- Prefer `AutomaticSize` plus `TextWrapped` over `TextScaled` (the docs recommend it). The player's Text Size setting (`GuiService.PreferredTextSize`) does not scale `TextScaled` text, and `TextScaled` stops at 100. If you use it, add a `UITextSizeConstraint`.
- Long strings: `TextTruncate` (AtEnd) and check `TextFits` after localization.
- `TextBounds` height is the line box, ascender and descender space included, so it is taller than the visible letters (field note, 2026-11-09). Judge whether text touches a stripe or an edge on a capture, not from `TextBounds`.

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

- One number formatter for the whole game (K, M, B; truncate, never round up into the next suffix), world-space numbers included: a floating refund that rounded ("+$7.3T") next to a card and toast that truncated ("$7.2T") read as a wrong refund to the owner (field note, 2026-11-09).
- Counters that jitter while counting: `OpenTypeFeatures = "tnum"` does not help (tested 2026-11-03: "Unsupported feature: tnum" on BuilderSans, FredokaOne, Montserrat, Roboto). Use a font whose digits are already equal width for counters and timers. Measured equal: Roboto, RobotoCondensed, RobotoMono, BuilderMono, Nunito, SourceSansPro, Teko, Rubik. Proportional (they jitter): BuilderSans, FredokaOne, LuckiestGuy, DenkOne, Montserrat, Oswald, Bangers, Goldman, Arimo. With a proportional display font, right-align the counter in a fixed-width box.
- Damage numbers: pooled BillboardGui labels with `MaxDistance`, stroke or shadow, rise and fade over about 0.6 s. A crit changes color and jumps to one larger size; never scale text continuously.

## 7. Other languages

- Pick fonts that cover the target languages: Korean Nanum Gothic (12187361718; Regular, Bold, ExtraBold); Japanese M PLUS Rounded 1c (12188570269), IBM Plex Sans JP (12187364147); Chinese Noto Serif SC (12187376739), Noto Serif TC (12187368093); Arabic Cairo (12187377099), Tajawal (12187377588); Thai Kanit (12187373592), Prompt (12187607287). Only Nanum Gothic was tested; the rest is from the font names.
- Tested 2026-11-03 in a Studio play session: Hangul rendered on a ScreenGui, a SurfaceGui and a BillboardGui in Montserrat (the old GothamBold), FredokaOne, LuckiestGuy, BuilderSans and Nanum Gothic. Fonts without Hangul fall back to a default Korean face in a regular weight, so bold Latin sits next to thin Hangul. For Korean-first text, use Nanum Gothic Bold or ExtraBold (or keep display words in Latin). Test one sentence per shipped language on screen, sign and billboard.
- Leave 30-40 percent spare width for translations (judgment). Turn `AutoLocalize` off on player names, codes and numbers. Text built at run time ("+120 Gems", "Stage " .. n) matches no table entry and stays untranslated: use one keyed entry with parameters ("Stage {n}") read with `Translator:FormatByKey(key, args)` (docs `translate-dynamic-content`), or translate free text on the server with `POST /cloud/v2/universes/{id}:translateText` (scope `universe:write`, beta, rate limited; docs `auto-translate-dynamic-content`). Proofread machine-translated proper names. Arabic needs right-to-left layout (`StarterGui.RtlTextSupport`, on by default).
- Hand-translated runtime text (field notes, 2026-11-09, one game in 15 languages with auto translation off):
  - A template source ("STAGE {1}") read with `Translator:Translate(game, source)`, with the arguments filled in code, also worked. Translate arguments that are words (hero or mutation names); paste numbers and player names as they are.
  - Server-built world labels (BillboardGui, SurfaceGui): the server stores the template and its arguments as attributes with a CollectionService tag; each client renders its own language and re-renders on `AttributeChanged`. Set `AutoLocalize` false on those labels so the two systems do not fight, and cache translations per player with a size cap.
  - Measure the translated string. With `AutoLocalize`, `Text` and `ContentText` keep the source language while the screen shows the translation, so `TextService:GetTextSize(label.Text)` sized boxes for English, and German, Russian, Thai and Arabic overflowed. Measure `Translator:Translate(...)`, refit when the translator arrives, and give wrapped labels a shrink-to-fit loop (from the design size down to a minimum until the longest word fits the width and the wrapped height fits).
  - Translator timing: `GetTranslatorForPlayerAsync` errored in an unpublished place (a local file, GameId 0), while `GetTranslatorForLocaleAsync(player.LocaleId)` worked there after about 10 s in Studio. Both can fail (docs `localize-with-scripting`), so use the player call with the locale call as a fallback, fire a "translator ready" signal that re-renders text built before it, and wait briefly on the client (up to 3 s in that game) before building text that is set once.
  - Glossary first (judgment): per language, fix the game's terms (rarity names, currencies, UI verbs) before translating the strings, so a term reads the same on every screen. Flag the names that stay in the source language.

## 8. Checklist

| Check | Pass |
|---|---|
| 2 fonts or fewer, chosen with the user from a specimen screenshot | yes |
| No `Enum.Font` Gotham or Arial left in code | yes |
| Phone-size screenshot: every label readable, none under the size floor | yes |
| No tweened `TextSize` or stroke `Thickness` | yes |
| Counters do not jitter; one number formatter | yes |
| One sentence per shipped language tested on screen, sign and billboard | yes |
