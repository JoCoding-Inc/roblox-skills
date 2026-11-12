---
name: roblox-ui-layout
description: "Use when placing or sizing any HUD, button, panel or menu in a Roblox game for phone, tablet, desktop and console: our one layout standard with Roblox's reserved zones in pixels (top bar, thumbstick, jump button, hotbar, chat, player list), safe insets, Scale vs Offset vs UIScale, touch and text floors, orientation, console TV-safe area and a device check script. Also when a button sits under the thumbstick, jump button or top bar; UI is cramped on phones, lost on PC or huge on a TV; a notch cuts a panel; choosing ScreenInsets or IgnoreGuiInset; enabling portrait; adding gamepad support; when judging phone UI from a desktop capture or driving Studio's Device Simulator (`StudioDeviceSimulatorService`); when a TextBox meets the on-screen keyboard; before calling any UI done. The genre look (stud chunky) stays in roblox-ui-genre-studs and fonts in roblox-ui-typography; on placement, sizes and floors this skill wins."
last_reviewed: 2026-11-12
sources:
  - Roblox client scripts, mirror MaximumADHD/Roblox-Client-Tracker branch roblox at b0b3ae8 (Studio 0.746, 2026-11-03): PlayerModule ControlModule TouchJump.lua, DynamicThumbstick.lua, ClassicThumbstick.lua; CoreScripts BackpackScript, PlayerList, EmotesMenu, TopBar Constants.lua (Studio 0.745 install)
  - https://create.roblox.com/docs (creator-docs main 76167c1, 2026-11-03): ScreenGui, ScreenInsets, SafeAreaCompatibility, GuiService (GetGuiInset, TopbarInset, GetInsetArea, ViewportDisplaySize), UIScale, UISizeConstraint, UITextSizeConstraint, TextLabel.TextScaled, input/mobile, production/publishing/cross-platform, console guidelines, ui/adaptive-design, studio/testing-modes (Device Emulator)
  - DevForum staff posts on experience controls (t/2567355, 2023-08-28; 2024-09-17 and 2024-10-15 live), notched screen support (t/2074324), GuiInset timing (t/2973508), platform-integrated chat (2026-10-21)
  - creator docs input/mobile, production/game-design/design-for-roblox, performance-optimization/test-on-hardware (mobile majority, read 2026-11-12); PocketGamer.biz 2024 platform split (press); GameAnalytics 2026 Roblox Benchmark Report (device combinations)
  - Roblox built-in Studio MCP skill rbx-device-simulator-lua (StudioDeviceSimulatorService, read 2026-11-12); RoDesigner phone UI spec (same 23 frames, 2026-11-12)
  - phone HUD sizes measured on 23 in-play phone HUD frames from 20 top games (2026-11-09; frames private, numbers and method only)
  - original (zone map, sizes marked judgment, ui_device_check.luau tested 2026-11-04 in Studio; its text rule changed 2026-11-11, checked with luau-analyze only)
---

# UI layout standard (phone, tablet, desktop, console)

One standard for every genre. The genre skills set the look (pick it first: `roblox-game-pipeline` section 3, step 4, style cards and a free Studio mockup; then `roblox-ui-genre-studs`, `roblox-ui-genre-scifi` or the UI rules in `roblox-engine-2026`); this one sets where things go and how big they are. Coordinates below are Roblox UI px inside the CoreUI-safe frame (below the top bar, inside notches), which is where a default ScreenGui draws.

## 0. Facts behind the standard

- Who plays where: "The majority of Roblox sessions are played on mobile devices", and "The majority of Roblox users play on a mobile device, so it's wise to design your user interfaces (UI) and user experience (UX) around mobile devices first" (docs `input/mobile`, `production/game-design/design-for-roblox`). Most of them are on lower-spec phones; Android is about 65% (docs `performance-optimization/test-on-hardware`). Roblox's 2025-26 filings and letters give no platform split; a press figure for 2024 is 80% mobile, 17% PC, 3% console (PocketGamer.biz, C). Yet 44% of players use both phone and PC and about 85% touch PC at least once (GameAnalytics 2026). So: design for the phone first, check desktop on every change, treat console as a checked extra.
- Phone px are device-independent: phones report about 160 dpi px (an iPhone X 2436x1125 screen reports 812x375, staff 2018). A px looks about the same size on a phone at 30 cm and a 1080p monitor at 60 cm (our arithmetic). That is why Roblox's own UI uses the same px on both and x1.5 only on console (source: UIBlox tokens). A TV at 3 m needs that x1.5.
- A phone's safe frame is small: 667x317 on a 667x375 phone, 733x313 on the docs' notched phone (851x392 minus 59 px each side, 58 px top bar, 21 px bottom). A HUD drawn on a 1080p desktop covers about 3x more of the phone screen. On a real iPhone with a Dynamic Island, in landscape, the home indicator overlapped a bottom-centre line that sat 4 px from the screen bottom inside the `CoreUISafeInsets` frame (field note, 2026-11-09, unlike the docs' 21 px): read the safe frame's `AbsoluteSize` on the target device, and keep bottom-centre touch UI clear of the bottom edge (that game chose 14 px in Studio's device emulation, not yet checked on the phone).
- Roblox's small-screen breakpoints: touch controls switch from small to large when the safe frame's short side is over 500 px. Core UI (chat, player list, emotes) treats a touch screen as small when the viewport is under 500 px tall or 700 px wide.

## 1. Reserved zones (no buttons inside)

| Zone | Phone (short side 500 px or less) | Tablet, large touch | Desktop | Console |
|---|---|---|---|---|
| Top bar (outside the safe frame) | 58 px strip. All Roblox controls are left-aligned: menu button plus unibar, 44 px cells, up to about 350 px wide on phone landscape and possibly the full width in portrait. With the default controls, Studio measured 164 px plus a 16 px gap (RoDesigner, 2026-11-11): read the real width from `GuiService.TopbarInset` (section 3) instead of a constant | same | 58 px | 87 px (58 x 1.5) when the new controls are on |
| Thumbstick ring (default dynamic stick) | centre 66 px from the left and 56 px from the bottom, 74 px wide. Keep box: 110 x 100 px bottom-left | centre (132, bottom - 112), 148 px wide. Keep box: 215 x 195 px | none (keyboard) | none |
| Thumbstick start area | any touch in the left 40% x bottom 2/3 starts the stick (portrait: full width x bottom 40%). Information may sit there; frequent buttons should not | same | none | none |
| Jump button | 70 x 70 px, 25 px from the right, 20 px from the bottom. Keep box: 95 x 90 px bottom-right | 120 x 120 px, 50 px from the right, 90 px from the bottom. Keep box: 170 x 210 px | none | none |
| Backpack hotbar (only when the player has Tools) | bottom centre, 200 x 70 px (3 slots, touch and width under 1024) | 655 x 70 px (10 slots); open arrow up to 110 px above the bottom | 655 x 70 px | 1055 x 110 px |
| Chat window | hidden at start on small touch screens; opens top-left under the bar | top-left under the bar | top-left under the bar, scale-based size (about 30% x 25% of the screen, unconfirmed) | disable chat (docs) |
| Player list | hidden; a centred modal from the menu | top-right under the bar | top-right, about 166-210 px wide, half the screen tall (legacy values) | centred modal |
| Emote wheel | centred, 150-300 px | centred, 200-400 px | centred | centred, 320-640 px |
| Health bar | top-right of the top strip, 125 x 20 px (80 x 20 when the width is 393 px or less), only after damage | same | same | 220 x 16 px |

- Touch controls appear only when `UserInputService.PreferredInput` is Touch, not when `TouchEnabled` is true (a touch laptop with a mouse gets none). Branch UI on `PreferredInput`, never on device guesses.
- The jump button moves between 70 and 120 px layouts and disappears when jumping is disabled. Place buttons relative to it, not at fixed px near it.
- Platform-integrated chat (opt-in since 2026-10, automatic from February 2027) renders chat itself; a custom chat goes in a `TextChannelWindow` whose size and place you set.

## 2. Zone map for game UI (landscape)

| Where (safe frame) | Put | Rule |
|---|---|---|
| Left column, from about 20% to 60% of the height | menu buttons (shop, inventory, pets), 3-4 at most | Stop above the thumbstick keep box. On a 317 px phone, two 60 px buttons from 35% already reach it (tested) |
| Bottom-left, above the keep box | currency and stat readouts (not tappable) | Stack upward from 110 px above the bottom on phones, 200 px on large touch |
| Bottom-right, around the jump button | action buttons (attack, ability, interact) | On an arc left of and above the jump button, sized 0.8-1x of it (docs sample places buttons relative to the jump button) |
| Right column, above the jump keep box | offers, secondary buttons | Out of the player list's column on desktop, or disable the player list |
| Top centre, under the bar | one objective or timer line, toasts | One line, short text |
| Top strip right (`TopbarSafeInsets` ScreenGui) | small status chips | Only through that ScreenGui; it can be zero wide (portrait) |
| Bottom centre | hotbar if the game gives Tools, else the main prompt | Never both. A game bar sits between about x 0.35 and 0.70 of the width and is at most 0.15 vh tall (13 phone frames, measured 2026-11-09) |
| Centre | panels and modals, closed by default | A modal is a centred card about 0.45 of the screen width (top games 0.36-0.67, only 5 frames; RoDesigner warns over 0.67 and fails over 0.80), with the game dimmed behind it (one owner's review, 2026-11-11). Full screen only for shop grids. A panel fits the phone safe frame with a scroll; close button 44 px or more inside the safe frame. If it still covers the thumbstick or jump keep box, set `GuiService.TouchControlsEnabled = false` while it is open and restore it on close (field, 667 x 375 phone) |

Reach: a button 40% below the top is easy on a phone and almost unreachable on a tablet (docs). Frequent buttons go near the bottom corners above the keep boxes; rare ones go into a menu on small screens (docs adaptive design).

See the game: on a phone, measure the share of the centre 50% x 50% box that visible HUD covers at idle (the union of their rects), not only overlaps between elements. A desktop-style bottom cluster plus 2x2 offer cards covered about 40% of it and the owner rejected the HUD; moving groups to the edges and shrinking them got it near 1% (field observation, 2026-11).

Measure the whole HUD too: the union of the visible HUD rects at idle as a share of the full screen, top bar included (count plate-less text by its `TextBounds`, glass plates as solid). One owner rejected a HUD covering 22% of a 1920x1080 screen as "covers too much" and accepted about 7%; the same HUD covered 16.5% of a 667x375 phone because of the phone floors this skill set then (field note, 2026-11-08).

Phone HUD budgets. The top-game numbers are measured on 23 in-play phone HUD frames from 20 top games (2026-11-09); the thresholds are judgment set from them:

| Budget (phone, in-play HUD at idle) | Target | Warn | Fail | Top games |
|---|---|---|---|---|
| HUD coverage: union of game UI rects, without Roblox core UI, touch controls, toasts and world labels | 11% | over 16% | over 20% | median 10.6%, p25-p75 7.3-15.9%, max 20.3% |
| Centre 50% x 50% box covered | 0% | over 2% | over 10% | median 0%, p75 1.4% |
| Largest clear rectangle around the centre, share of the screen | 38% or more | | under 38% | median 53.8%, p25 38.4% (same frames, RoDesigner lint PH-8) |
| Visible menu buttons | 5 (8 in simulators) | over 9 | over 12 | median 5, p75 8.5 |

Horror and RPG HUDs that show vitals or a party list may sit in the warn band (their frames ran 18-20%). Menu buttons beyond 8 go into one "more" drawer button. On a phone, an offer card becomes an icon button of about 0.09 vh with a price badge, and boost or timer chips merge into one stacked chip in the top band (judgment).

A card that opens when the player walks near something (an action or build card) goes beside the play area, never over the spot where the action happens. On phone and tablet, let it take a HUD column's slot and hide that column while the card shows; on desktop it fits under the column. In one game that cut the centre box covered while the card shows from 56% to 9.3% on a phone (field note, 2026-11-08).

Hiding a HUD side while such a card shows (one tested recipe, field note 2026-11-09):
- Give each ScreenGui root one invisible full-size layer frame per side and parent that side's elements into it, so the layout code keeps owning their `Position` and `Size`. Slide only the layer.
- Timing used: hide 0.22 s Quad In, show 0.3 s Back Out, with a small stagger between layers.
- Set the layer's `Visible` to false when the hide ends, so nothing hidden takes input and a re-layout while hidden cannot pop an element back.
- Measure the slide distance again on every show.
- Call show from every close path: the close button, walking away, death, losing the target. With `GuiService.ReducedMotionEnabled`, hide and show at once.

Portrait only when the game sets `StarterGui.ScreenOrientation` to `Sensor` or `Portrait` (default `LandscapeSensor`). In portrait the stick takes the bottom 40% and the top strip may be full: menu buttons go in a bottom row above the stick zone or behind one menu button.

Phone details from the docs (read 2026-11-12):
- "Show only the most vital information during active gameplay" (`ui/position-and-size`). A situational action is a `ProximityPrompt`, not a permanent button; touch players can always tap a prompt, whatever `ClickablePrompt` says. A menu button can expand into its sub-buttons only when selected, and action buttons can swap by context (`production/game-design/ui-ux-design` examples).
- Long press is `GuiButton.SecondaryActivated` (right-click on desktop).
- A `ScrollingFrame` bounces on touch by default; set `ElasticBehavior` to `Never` where that fights a tight list.
- Never rely on color alone: add a symbol or text (`projects/cross-platform`).
- Pinch and swipe gestures must not fight the gameplay controls (`performance-optimization/test-on-hardware`).

## 3. Insets

- Interactive UI: keep the default `ScreenInsets = CoreUISafeInsets`. Do not set `IgnoreGuiInset = true`: it switches to `DeviceSafeInsets` (under the top bar).
- Full-screen backgrounds and fades: `ScreenInsets = None` in their own ScreenGui with no buttons. Set `SafeAreaCompatibility = None` on new ScreenGuis (docs discourage the legacy fullscreen extension).
- Never hard-code 36 or 58: `GetGuiInset()` returns 0 for about 0.2 s after join and can change without a signal (staff). For the top strip, use a `TopbarSafeInsets` ScreenGui and react to its `AbsoluteSize`, or the property-changed signal of `GuiService.TopbarInset`.
- Slide-in panels: `ClipToDeviceSafeArea` (default true) clips them at the notch; set it false on that ScreenGui and add an offset, or tween to a placeholder.
- iOS landscape insets are symmetric (59 pt on Dynamic Island phones) although the cutout is on one side only, at mid-height and about 48 pt deep, so the side without it shows a wide empty margin (field note, 2026-11-09, simulated viewport in Studio, not checked on a phone). Measure the spare as the width of a `ScreenInsets.None` probe minus a `CoreUISafeInsets` probe, divided by 2. Turning the phone moves the cutout to the other side, so let only corner HUD reach into the spare, on both sides, keep the mid-height band clear, and set `ClipToDeviceSafeArea` false on that ScreenGui (judgment). Mid-height HUD that must use the spare stays at least the island's offset plus depth plus a few pt from the edge on both sides: about 52 pt on an iPhone 15 Pro Max (11 pt + 37.33 pt from published sizes, not tested on a phone).

## 4. Size and scale

- Position with Scale plus `AnchorPoint` into the zone (docs). Size content (buttons, icons, text) in Offset px, because phone px are physically stable; size containers (panels, lists) in Scale with a `UISizeConstraint` min and max. The docs' cross-platform page recommends Scale for sizing and a 2024 staff designer post does too; staff engineers explain why content stays in Offset (device-independent px, about 160 dpi; Scale-only text comes out a few px high on phones; DevForum t/122825, 2018, and t/4009681, 2025). This standard follows the engineers for content and the docs for containers. Offset takes whole px only, so a slow pixel tween steps visibly on high-density phones; move by Scale or a `UIScale` for smooth motion (staff, t/4009681).
- One `UIScale` at the root of each ScreenGui, from `GuiService.ViewportDisplaySize`: Small 1, Medium 1, Large 1.5 (Roblox's own scale). Listen to its change signal.
- Offer a player "UI size" setting (x1, x1.15, x1.3). Grow a Garden ships one; the factors are community values.
- A chunky genre may raise Medium (desktop) to 1.25 for its look (judgment, compare screenshots first). Do not enlarge phone HUDs past the sizes below: a 1080p design scaled with a phone floor (k = max(viewport height / 1080, 0.55)) came out 1.4-1.7x the top-game sizes, covered 23-38% of a 667 x 375 phone, and one owner rejected it as too big to see the game (field note, 2026-11-09).
- Phone sizes, landscape. Measured on 23 in-play phone HUD frames from 20 top games (2026-11-09). vh = share of the viewport height; px are for a 667 x 375 phone. Offset px taken from this column stay inside the ranges on phones up to 430 px tall.

  | Role | Target | Range | Source |
  |---|---|---|---|
  | Menu or HUD button, visible size | 0.09 vh (34 px) | 0.06-0.105 vh | measured: median 0.088, p25-p75 0.058-0.103 |
  | Its hit area | 44 x 44 px or more | | Roblox top bar cells are 44 px (client source); WCAG 2.1 target size (AAA) and Apple's HIG default are 44; Android asks 48 dp with 8 dp between targets; the docs' UI tutorial cites 9 x 9 mm (about 57 px) for frequent buttons |
  | Touch action button (attack, sprint, ability, use) | 0.17 vh (64 px) | 0.12-0.20 vh, never under 44 px | measured median 0.168; the Roblox jump button measured 0.172 vh; docs: frequent buttons 9 x 9 mm, about 57 px |
  | HUD label or timer | TextSize 12, bold with a stroke | cap height 0.017-0.028 vh | measured cap height (median 0.022 vh, 8 px); TextSize assumes cap = 0.7 x TextSize, not measured |
  | Currency number | TextSize about 14, bold with a stroke | cap height 0.022-0.038 vh | same (median cap 0.027 vh, 10 px) |
  | Currency row height | 0.06 vh (22 px) | 0.04-0.086 vh, tycoon up to 0.12 | measured: median 0.059 |
  | Gap between buttons | 0.02 vh (8 px) | 0.012-0.046 vh | measured: median 0.021 |
  | Edge margin | sides 0.035 vh (13 px), bottom 0.01 vh (4 px) | | measured medians (same frames, RoDesigner) |
  | Panel body text | 14 px | | Roblox chat default `TextSize` 14 |
  | Hard floor | `MinTextSize` 9 | | docs |

- Split the look from the hit area: make the tappable `GuiButton` transparent and 44 px or more, with the visible icon inside it at the size above. In a packed column, grow the hit areas into the gaps and margins until they meet: there the pitch (centre to centre) sets the hit size along the column, so keep it at 40 px or more (judgment: top games pack 33 px buttons with 8 px gaps, a 41 px pitch). Small status chips with a tooltip work the same way: a 44 px hit area larger than the chip, and the tooltip opens on tap on touch and on hover on desktop (field note, 2026-11-11).
- A menu button goes over 0.12 vh only when the HUD shows 2 or fewer (obby HUDs ran 0.147 vh with 1-2 buttons).
- How far to trust these numbers: tower defense, +1/clicker, arena and RPG had 2 frames each (examples, not norms); boxes were hand-measured to about 0.01 of the viewport (about +-10% on a button); nothing was checked on a real phone.
- Prefer `AutomaticSize` with `TextWrapped` over `TextScaled` (docs): TextScaled ignores the player's text-size setting.
- Never let wrapped text take its width from a container that takes its size from that text: in one game both collapsed to one letter per line, and `AutomaticSize` on a plate holding rotated skin pieces grew without end (field note, 2026-11-08). Measure the content at its natural width (in an invisible frame with a large Offset size) and set the plate's `Size` from that measurement, divided by the plate's `UIScale` factor. The same growth hit small chips inside a `UIListLayout` row (field note, 2026-11-11).

## 5. Console

- TV-safe area: keep UI inside the middle 90% (96 px left and right, 54 px top and bottom at 1920x1080, docs illustration). Xbox reports 1080p px with no dpi scaling, so `UIScale` 1.5 on Large.
- Every control is reachable with the d-pad plus select and back (`Selectable`, `NextSelection*`); set `GuiService.SelectedObject` when a menu opens. Disable the chat window. Hide touch-only and mouse-only buttons and show gamepad glyphs (`InputActionLabel` or `UserInputService:GetImageForKeyCode`).

## 6. Check every UI change at these sizes

| Device | Screen (UI px) | Why |
|---|---|---|
| `phone` | 667 x 375 | smallest common landscape, small controls |
| `phone_notch` | 851 x 392 (59 px sides, 21 px bottom) | the docs' notched phone |
| `phone_portrait` | 375 x 667 | only if portrait is allowed |
| `tablet` | 1024 x 768 | large controls, reach |
| `desktop` | 1920 x 1080 | player list, chat, wide layout |
| `console` | 1920 x 1080, 87 px bar | TV-safe, x1.5 |

**Hard rule: phone and tablet layout is judged only in a Studio Device Simulator viewport**, either a preset device or a custom device of the exact size. Never draw a device outline, safe-area lines or zone boxes over the desktop viewport or a desktop capture to estimate a phone or tablet's proportions, sizes, coverage or placement, and never report such a picture as a phone or tablet check. Desktop captures judge desktop only. Every phone or tablet number in a review (HUD coverage, centre box, button size, overlap) comes from a simulator capture or from `AbsolutePosition`/`AbsoluteSize` read while the simulator holds that device.

1. Switch Studio's viewport to the device in the Device Simulator. It gives the real viewport, insets and keyboard height, and scripts that read `ViewportSize` re-run.
   - By hand: the device picker in Studio's toolbar (a device name such as "iPhone 17 Pro", plus laptop, gamepad and headset buttons).
   - From an agent: `StudioDeviceSimulatorService` through `execute_luau` in Edit (plugin context). Source: Roblox's built-in Studio MCP skill `rbx-device-simulator-lua` (load it with the MCP `skill` tool for the full API and its test, compare, orientation and playtest workflows; read 2026-11-12, not yet run here). Wrap every call in `pcall`:

     ```luau
     local svc = game:GetService("StudioDeviceSimulatorService")
     local function use(name: string): Vector2
     	for _, id in svc:GetDeviceListAsync() do -- ids such as "iphone_17_pro": match the display name, never hard-code
     		if svc:GetDeviceInfoAsync(id).Name == name then
     			svc:SetDeviceAsync(id)
     			task.wait(0.2) -- the viewport updates async
     			return workspace.CurrentCamera.ViewportSize
     		end
     	end
     	error("no device " .. name)
     end
     local ok, vp = pcall(use, "Samsung Galaxy A06")
     return if ok then tostring(vp) else vp
     ```

   - Then `screen_capture`. Cover the lowest-resolution phone in the list (the skill's example: Samsung Galaxy A06, 800 x 360, viewport about 705 x 338), the newest iPhone (iPhone 17 Pro, 874 x 402, Dynamic Island side), a tablet, and Xbox. Sizes no preset matches, such as 667 x 375 from the table above or a 932 x 430 large phone (the top of the section 4 range), come from `CreateDeviceAsync({Name = ..., Width = ..., Height = ..., PixelDensity = ...})`.
   - Exact overflow: after the switch, the `AbsolutePosition` and `AbsoluteSize` of StarterGui elements are in the device viewport's px (Edit only), so read numbers instead of eyeballing.
   - UI that scripts build: set the device first, then `start_stop_play`, because every setter errors on the Play server. In Play, `execute_luau` cannot read `PlayerGui`, so judge from `screen_capture`.
   - Portrait only if the game allows it: `SetOrientationAsync(Enum.ScreenOrientation.Portrait)`.
   - Taps and keyboard: `ScaleToPhysicalSize` scaling shows the physical size. Open the on-screen keyboard on every TextBox; the device info gives `LandscapeKeyboardHeight` (181 on iPhone 17 Pro). Move or shrink a panel while the player types with `UserInputService.OnScreenKeyboardVisible`, `OnScreenKeyboardSize` and `OnScreenKeyboardPosition` (px; zero when hidden); `TextBox.ReturnPressedFromOnScreenKeyboard` fires on mobile; set `ClearTextOnFocus` false on fields players edit (docs). Players report that a real phone shifts the view to centre a focused TextBox, which can clip one anchored top-left, and that the simulator never shifts; Android's action-button row is missing from `OnScreenKeyboardSize` (DevForum bug reports, 2023-2024, C). So keep TextBoxes centred or in the upper half, never use `TextScaled` on a TextBox, and type on a real phone once.
   - End with `StopSimulationAsync()`. A changed scaling mode is never reset by switching or stopping, so set it back yourself.
2. Zone lint: run `scripts/ui_device_check.luau` with `execute_luau` (Edit) once per size in the table (set `DEVICE`). It computes, for that device's safe area, buttons inside Roblox's reserved zones, buttons under 44 px on touch, text under 14 px (12 px for bold, stroked text) and elements crossing the safe edge. Fix every `error`, then check the phone HUD against the section 2 budgets with the numbers from step 1.
   - Use only its returned list. The frame and red zones it draws are a debug overlay inside the current window, not a phone view: never review placement, measure proportions or capture it as evidence for a phone or tablet. Delete the `UiDeviceCheck` copy it adds to StarterGui after the run.
   - It does not apply your runtime `UIScale` or scripts, so UI that scripts build needs a Play-mode copy. Take that copy with every transient state up (contextual cards with their buttons, tutorial bar, prompts, toasts): one phone overlap showed only with a contextual card and the tutorial bar open (field note, 2026-11-09). Judge the look of those states in step 1's Play run.
3. Last, a real phone for thumb reach (`roblox-game-pipeline` verification).
4. These steps check placement and size, not the look: also run the look check in `roblox-engine-2026` section 2 (UI review, step 4).
