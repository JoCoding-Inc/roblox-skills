---
name: roblox-ui-mobile
description: "Use when designing, building or reviewing Roblox UI for phones first, then tablet and desktop: which Studio Device Simulator presets to test on and why (player share, the smallest real safe frame), a phone-first build order, HUD placement around the touch controls (when buttons may sit in the thumbstick start area, action buttons placed from the jump button), how a panel opens (size, dim or blur behind it, which HUD stays or slides off, touch controls, close button, grid and tabs, timing) with a tested PanelStage module, the on-screen keyboard, what changes on tablet and desktop, and a device sweep script. Also when agents test on an old small preset such as iPhone 7 or only on desktop, a panel fills the whole phone screen or hides the currency, a shop opens over the HUD, a TextBox ends under the keyboard, action buttons collide with the jump button on tablets, or MCP clicks miss in the Device Simulator. Zone px, size floors and insets stay in roblox-ui-layout; the genre look in roblox-ui-genre-studs and roblox-ui-genre-scifi."
last_reviewed: 2026-11-12
sources:
  - Studio 0.747 Device Simulator, measured 2026-11-12 through Studio MCP execute_luau and user_mouse_input (Play, Client datamodel) on 16 presets (safe frames, touch controls, keyboard, ViewportDisplaySize); runs of scripts/panel_stage.luau and roblox-ui-layout/scripts/ui_device_check.luau
  - Roblox client scripts, PlayerModule ControlModule DynamicThumbstick (read from PlayerScripts in Studio 0.747); EmulatedDevices.xml (mirror MaximumADHD/Roblox-Client-Tracker branch roblox at b0b3ae8, Studio 0.746)
  - creator docs performance-optimization/test-on-hardware, studio/device-simulator, input/mobile, reference BlurEffect (read 2026-11-12); Roblox built-in Studio MCP skill rbx-device-simulator-lua
  - StatCounter Global Stats, October 2026 (mobile OS, phone, tablet and desktop screen resolution, vendors; web page views, top 20 rows per chart)
  - Roblox FY2025 Form 10-K and Q3 2026 Form 10-Q (users and revenue by region); Counterpoint Research, best-selling smartphones of 2025; Roblox help article 203625474 (mobile system requirements, updated 2026-11-05)
  - RoDesigner research library, 2026-11-12, 84 phone frames with an open panel from 28 top games, 45 phone HUD frames from 29 top games, 50 tablet frames from 17 games and 24 row-list panels from 16 games (frames private; numbers and method only)
  - original (test set, recipes and thresholds marked judgment)
---

# Mobile-first UI (phone, tablet, desktop)

Most players hold a phone, so the phone layout is the design and tablet and desktop are adaptations of it. This skill is the how: which devices to test, what order to build in, how the HUD and panels behave on a small screen. `roblox-ui-layout` keeps the numbers (reserved zones in px, size and text floors, insets, HUD budgets); read its sections 1, 2 and 4 with this one. Console is not covered here (`roblox-ui-layout` section 5).

## 0. Who you are building for

- Most sessions and users are on mobile (docs, `roblox-ui-layout` section 0). Android is about 65% of a typical game's players; about 60% of those have 2-4 GB RAM, 35% have 4-8 GB, 5% more (docs `performance-optimization/test-on-hardware`). Your own game's devices are in the Creator Hub Performance dashboard.
- About 82% of daily users are outside the US and Canada (FY2025 10-K), while the US and Canada bring 57% of revenue (Q3 2026 10-Q).
- Phones by market (StatCounter, October 2026; web page views, a proxy and not Roblox players):

  | | Android | iOS |
  |---|---|---|
  | Worldwide | 72.4% | 27.6% |
  | US, UK, Japan | | 52.0%, 50.1%, 53.9% |
  | Brazil, Mexico, Indonesia, Philippines, India | 73.8%, 74.1%, 78.7%, 86.3%, 94.9% | |

- Phone screens worldwide (same source, portrait px): 414x896 12.7%, 360x800 8.6%, 384x832 7.2%, 390x844 5.3%. 360x800 is first in the Philippines (16.6%), Indonesia (8.7%) and India (15.7%). 375x667 (the iPhone 6 to 8 size) is 1.4% worldwide and 2.6% in the US. Nothing in the worldwide top 20 is narrower than 360.
- The two best-selling Android phones of 2025 were the Galaxy A16 5G and the Galaxy A06 (Counterpoint, 5th and 6th overall). Both are Studio presets.
- Tablets: Apple 47.7%, Samsung 26.8%, Amazon 9.0% worldwide; Amazon is 21.8% in the US. Desktop screens: 1920x1080 27.8%, 1536x864 9.2%, 1366x768 7.5%.
- One game's own mix (field note relayed from its Open Cloud analytics, 2026-11-05 to 11-10, 929 daily-user days, ad-driven traffic; not re-read here): Android phone 31%, iPhone 26%, iPad 21%, Android tablet 6%, Windows 14%, Mac 2% of daily users (phone 57%, tablet 27%, computer 16%); playtime phone 59%, tablet 11%, computer 30%. Tablets were over a quarter of its players and outnumbered computers, which web traffic shares do not show. Its iPad players stayed 3.8 minutes a day against 13.9 on Android phones, and its tablet UI was the phone layout scaled up and had never been captured at a tablet size (a correlation, not a proven cause).
- Reading (judgment): the typical player holds an entry Android phone, which gives Roblox its smallest frame (section 1), most spend comes from iPhone-heavy markets, and tablets are a large third group. Test all three on every change.

## 1. Test devices

Measured in the Studio 0.747 Device Simulator, in Play, landscape (2026-11-12). The safe frame is where a default ScreenGui draws: the screen minus the notch insets and the 58 px top bar.

| Studio preset | Screen | Safe frame | Touch controls | `ViewportDisplaySize` | Keyboard height | Frame left above the keyboard |
|---|---|---|---|---|---|---|
| Samsung Galaxy A06 | 800x360 | 705x280 | small, jump button 70 px | Small | 162 px | top 140 px |
| iPhone 17 Pro | 874x402 | 750x323 | small | Small | 181 px | top 143 px |
| iPhone 16 Pro Max | 956x440 | 830x381 | small | Small | 198 px (preset value) | not run |
| Amazon Fire HD 10 (2023) | 960x600 | 959x541 | large, jump button 120 px | Small | 302 px | top 240 px |
| iPad 10th Generation | 1180x820 | 1179x761 | large | Medium | 413 px | top 349 px |
| Average Windows | 1366x768 | 1365x710 | none | Medium | | |
| HD 1080 | 1920x1080 | 1919x1021 | none | Medium | | |

When to use which (judgment, from section 0):

| When | Devices | Why |
|---|---|---|
| Every UI change | Samsung Galaxy A06, iPhone 17 Pro, iPad 10th Generation | The smallest common frame and the largest Android class; the notched iPhone frame where the spend is; a tablet with large touch controls (tablets were 27% of one game's daily users, section 0) |
| Before calling a UI done | plus Amazon Fire HD 10 (2023), Average Windows, HD 1080 | Large touch controls on a small tablet frame, a small laptop, the most common desktop. With the three above this is the default list of the sweep script (section 7) |
| Before a release | plus iPhone 16 Pro Max and one real phone | The largest phone frame; thumb reach and the real keyboard |

- Every Android phone preset is 360 px tall (Galaxy A06 800 px wide, A16 and S25 Ultra 780, S22 Ultra 772), so the Android frame is 280 px high at any price. The A16 and S25 Ultra frame is 685x280: leave 20 px of slack in any row that just fits 705.
- The Android presets model iPhone-like side insets (47 px each side and about 21 px at the bottom on the A06). That was not checked on a real Android phone, where the frame may be wider. Building for 705 px is the safe side.
- iPhone 7 (667x375, frame 666x316) is not a default: it has no notch, its frame is 36 px taller than the Android one, and its screen size is about 1% of traffic. A layout that fits it can still overflow on the phones most players hold. Do not pick an old preset because it is first in the list.
- `ViewportDisplaySize` does not tell a phone from a tablet: it is Small on every phone and on the 960x600 tablets, Medium on the iPad and on desktop. The touch controls switch to large when the frame's short side is over 500 px. Branch on `UserInputService.PreferredInput` for touch and on the frame size for space.

## 2. Build order

1. Build each screen on the Galaxy A06 preset first (705x280). If it works there, larger frames only add room.
2. Fix the HUD budget before placing anything: 5 menu buttons (8 in a simulator), HUD coverage near 11% of the screen, nothing in the centre box (`roblox-ui-layout` section 2).
3. Size content (buttons, icons, text) in Offset px from `roblox-ui-layout` section 4. Size containers in Scale with a `UISizeConstraint` maximum, so they stop growing on tablet and desktop (section 6).
4. Switch to iPhone 17 Pro: the frame is 45 px wider and 43 px taller, with 62 px of notch margin on each side. Nothing should depend on reaching the screen edge.
5. Switch to a tablet: the touch controls grow by 1.7x, and the HUD and panels follow with the tablet scale (section 6). Anything placed at a fixed px distance from the corner now sits under the jump button (section 3).
6. Switch to desktop: touch-only buttons hide, the chat window and the player list take the top corners, panels keep their px size.
7. Run the device sweep (section 7), then look at a capture of every state on every device.

## 3. HUD around the touch controls

Placement follows the zone map in `roblox-ui-layout` section 2. Three things decide whether it works on a phone.

**The thumbstick start area.** The default dynamic thumbstick starts wherever a touch begins inside `DynamicThumbstickFrame`: the left 40% of the safe frame's width and the lower 2/3 of its height (measured on four devices; its rect also extends 100 px left of the safe frame, into the notch margin).

- A passive `Frame`, `TextLabel` or `ImageLabel` (`Active` false) does not block it: a touch that begins on a readout still starts the stick (tested, Galaxy A06 preset, emulated touch).
- A `GuiButton` or an `Active` frame does block it: the touch never starts the stick, and a tap fires the button. A stick drag that ends on a button does not fire it.
- A button with `Active` or `Interactable` false is dead (no tap) and lets the stick through, so that is not a way around it.
- So a button in the start area costs exactly its hit area of stick room, plus the taps players make by mistake when they put the thumb down to move.

Top phone games use the area anyway (45 HUD frames, 29 games; frames / games): game UI sits in it in 42 / 28, tappable buttons in 32 / 22, and menu-type buttons in 13 / 11 of 16 / 13 simulator and tycoon frames. Where there are buttons, the median is 2 (4 in simulators and tycoons) at about 0.10 of the screen height. They sit as a left-edge column (17 / 13) or in the upper band of the area (14 / 14). All game UI together covers a median 8% of the area (p75 17%, max 33%). In the 16 frames that show the stick, a button touches its resting ring in 1.

Rule (judgment from those numbers and the test above):

- Readouts (currency, stats, income rows) may sit in the start area freely. Keep them passive.
- Buttons go there when the right side and the top band are full: as a left-edge column or in the upper band, with at most about a quarter of the area under buttons. Simulators and tycoons, where the player stands still to tap, tolerate more than obbies or combat games, where a failed stick start costs a life.
- Keep the resting ring clear (the ring keep box in `roblox-ui-layout` section 1). The ring is only a first-touch hint, but the corner is where the thumb lands. A button there is a last resort.
- A button in the start area must be safe to hit by mistake: it opens a menu or a prompt and never spends, consumes or confirms on one tap.
- The sweep script reports the share of the start area under buttons: a note under 17%, a warning over 17%, an error over 33%.

**Action buttons come from the jump button, not from the corner.** The jump button is 70 px at 25 px from the right and 20 px from the bottom on phones, and 120 px at 50 px and 90 px on tablets. Read its rect and place attack, sprint or ability buttons beside it. Tested on Galaxy A06, iPhone 17 Pro, iPhone 16 Pro Max, Fire HD 10 and iPad 10th, the tablets at scale 1 and 1.7 (no overlap on any):

```luau
-- layer: the full-size HUD frame that holds the buttons. attack sits left of the jump button, dash above it.
-- rootScale: the UIScale at the root of this ScreenGui (section 6); 1 on phones, 1.7 on tablets
local touchGui = playerGui:WaitForChild("TouchGui", 10) -- exists on touch devices only
local jump = touchGui and touchGui:FindFirstChild("JumpButton", true)
local function place()
	local touch = UserInputService.PreferredInput == Enum.PreferredInput.Touch
	attack.Visible, dash.Visible = touch, touch
	if not (touch and jump) then
		return
	end
	local k = rootScale.Scale -- an Offset unit inside the scaled HUD is k px
	local p, s = (jump.AbsolutePosition - layer.AbsolutePosition) / k, jump.AbsoluteSize / k
	local size, gap = math.floor(s.X * 0.9), math.floor(s.X * 0.12)
	attack.Size, dash.Size = UDim2.fromOffset(size, size), UDim2.fromOffset(size, size)
	attack.Position = UDim2.fromOffset(p.X - size - gap, p.Y + s.Y - size)
	dash.Position = UDim2.fromOffset(p.X + s.X - size, p.Y - size - gap)
end
if jump then
	jump:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
	jump:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
end
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(place)
layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
rootScale:GetPropertyChangedSignal("Scale"):Connect(place)
place()
```

**Pass-through buttons (drag moves, tap fires).** When a column has to run into the start area or over the ring, a button can let the stick through instead of blocking it. Tested on the Galaxy A06 preset (emulated touch) and Average Windows (mouse), 2026-11-12: a tap fired once, a drag that began on the button moved the character and did not fire, a hidden button and a button under a modal scrim did not fire, a mouse click fired once.

```luau
-- drag = thumbstick, tap = button. Mark it so ui_device_check.luau does not count it as a stick blocker.
local TAP_TIME, TAP_MOVE = 0.3, 10 -- seconds and px (judgment)
local function shown(o: Instance?): boolean
	while o and not o:IsA("ScreenGui") do
		if o:IsA("GuiObject") and not o.Visible then
			return false
		end
		o = o.Parent
	end
	return o ~= nil and (o :: ScreenGui).Enabled
end
local function passThrough(button: GuiButton, onTap: () -> ())
	button:SetAttribute("PassThrough", true)
	local function sync() -- on touch the button stops taking input, so the stick gets the touch
		button.Active = UserInputService.PreferredInput ~= Enum.PreferredInput.Touch
	end
	sync()
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(sync)
	button.Activated:Connect(onTap) -- mouse and gamepad; never fires while Active is false
	local began: InputObject?, at: Vector3, t0: number
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Touch or button.Active then
			return -- processed: an active GUI above (a panel, a scrim) took the touch
		end
		local p, s, pos = button.AbsolutePosition, button.AbsoluteSize, input.Position
		if shown(button) and pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y then
			began, at, t0 = input, pos, os.clock()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input == began then
			began = nil
			if os.clock() - t0 <= TAP_TIME and (input.Position - at).Magnitude <= TAP_MOVE then
				onTap()
			end
		end
	end)
end
```

- Why this shape: a button with `Active` false gets no `Activated` and no `InputBegan` of its own, so the tap is found in `UserInputService.InputBegan` by its rect. `GetGuiObjectsAtPosition` also returns hidden objects, so check visibility yourself. `InputObject.Position` is in the same px as `AbsolutePosition` in a default ScreenGui.
- Cost: the stick's dead zone is 2 px, so a tap that slides 3 to 10 px also nudges the character for the length of the tap. Use it for menu openers, not for a button the player taps while standing on a narrow ledge. The 0.3 s limit was not timed: the MCP tap itself takes about 0.4 s.
- A column that cannot fit above the ring keep box (five 48 px rows need 240 px; a 280 px frame has 180 px above the box): show 3 rows and put the rest behind one "more" button, or split into two columns, or make the rows that reach the start area pass-through. Pass-through buttons do not count toward the start-area share and may sit over the ring.

**One layer per side.** Parent each side's HUD into one invisible full-size frame (Left, Right, Top). Layout code keeps owning each element; a panel moves a whole side by moving its layer (section 4).

## 4. Opening a panel

What top phone games do (84 frames with an open panel, 28 games, 2026-11-12; sizes from 58 framed panels in 22 games; frames / games). The sample is mostly simulator, tower defense, horror, survival and tycoon; frames from one video are near duplicates, so weigh by games.

| Topic | Measured | Use |
|---|---|---|
| Size | Median 0.45 of the screen width x 0.72 of its height; shop and inventory grids 0.45 x 0.72 (0.20-0.78 x 0.44-0.86). No framed panel covers 90% of both axes | A grid panel about 0.6 of the safe frame wide and nearly its full height; a small modal 0.45 wide and as tall as its content. On a phone 0.72 of the screen height is about 0.9 of the safe frame |
| Row lists (quests, daily rewards, codes) | 24 / 16 panels with a row list, but phone only 6 / 3 (weak): 3 rows in the first view (phone 3 to 4, a cut last row included); row height 14% of the screen height on phones (51 px at 360), 12% on PC; the panel 0.38 x 0.80 of the screen on phones, 0.41 x 0.65 on PC; rows fill about 90% of the panel width | A list panel is narrower and taller than a grid panel: about 0.5 of the safe frame wide, nearly its full height, 52 px rows, 3 to 4 visible |
| On tablets | 20 / 8 framed panels: 0.59 x 0.46 of the screen (0.20-0.98 x 0.19-0.62), centred 16 of 20; close button 5.5% of the screen height | Wider and shorter in share than on phones: cap the height (table below) |
| Position | Centred 43 / 16 of 58 / 22. Side sheets (unit or tool cards): left 4 / 3, right 5 / 4, 0.18-0.23 of the screen wide. Full-screen menus without a frame 10 / 4 | Centre it. A card the player uses while playing is a side sheet |
| Behind it | Untouched 30 / 17, blur 26 / 9, opaque full screen 8 / 4, dim 5 / 5, dim plus blur 2 / 2, unclear 11 / 8. A 24% dim was not visible by eye, so some untouched frames may hide a light dim; no typical dim strength could be measured | Dim or blur, your choice (judgment: it separates a panel from a busy world; one owner's review asked for it). `BlurEffect` blurs the 3D world only and "may render differently on low-end devices" (docs), so pair a blur with a light dim |
| HUD | Stays whole 52 / 26, partly 27 / 9, all hidden 3 / 2. The currency stays visible in all 19 shop frames (8 games). In every blur frame the HUD is sharp, above the blur | Keep the HUD the panel does not cover. Move away only what it covers. Keep the balance on screen: in the panel header when the top row is covered |
| HUD buttons sliding off when a panel opens | Not seen in any of 26 tagged panel clips | A design choice, not a norm. It is cheap and reads well (judgment); `PanelStage` does it for covered layers only |
| Touch controls | The jump button stays visible in 50 of 67 frames whose video shows one | Hide them under a modal panel whose scrim takes every touch (they would be dead); keep them beside a sheet |
| Close | X icon 53 / 21 of 74 / 27; none visible 17 / 10 (info cards, results). The X is inside the top-right corner in 20 and straddles it in 22 of 44; never top-left. Visible height median 0.077 of the screen height (29 px at 375) | X at the top-right corner, about 30 px visible inside a 44 px hit area. A tap outside the panel also closes it (judgment; stills cannot show it) |
| Tabs | None 48 / 19; top tabs inside the frame 8 / 6, floating above it 10 / 5, left rail 9 / 4. Tab bar height median 0.058 of the screen height (22 px at 375) | Top tabs or a left rail; give each tab a 44 px hit area |
| Grid | 4 columns, 2 rows visible (18 / 12 with 2+ rows; 2 to 9 columns); cell 0.20 x 0.18 of the screen height. A cut last row as a scroll hint 21 / 7 | 4 columns on a phone; let the last visible row be cut by the panel edge |
| Timing | Open: 200 ms median where tagged (3 clips, 120-250 ms); 10 clips open within one frame. Scale pop 3, slide from an edge 2, fade 0 | Scale pop from 0.9 in 0.2 s; close in 0.12 s. A chunky genre may keep its own pop (`roblox-ui-genre-studs` section 5) |

`scripts/panel_stage.luau` is a client ModuleScript that does this. Tested on Galaxy A06, iPhone 17 Pro, iPhone 16 Pro Max, Fire HD 10, iPad 10th, Average Windows and HD 1080 presets, with real taps on the A06:

```luau
local stage = PanelStage.new(playerGui, 5) -- scrim DisplayOrder: under the HUD (10), panels above (60)
stage:addLayer(hud.Left, "left")
stage:addLayer(hud.Right, "right")
stage:addLayer(hud.Top, "top")
shopButton.Activated:Connect(function()
	stage:open(shopPanel) -- or { backdrop = "blur" }, { hide = "all", keep = { hud.Top } }
end)
closeButton.Activated:Connect(function()
	stage:close()
end)
stage:open(unitCard, { modal = false }) -- a sheet: no backdrop, touch controls stay
```

- A modal `open` dims the game (0.5 black; `"blur"` is a `BlurEffect` of 16 plus a 0.25 dim), slides off the HUD layers whose elements come within 8 px of the panel, sets `GuiService.TouchControlsEnabled` to false, and pops the panel. `close` reverses all of it. A tap on the scrim closes.
- Opening another panel while one is open swaps them: layers the new panel does not cover come back, the backdrop does not flicker.
- Put the scrim's `DisplayOrder` under the HUD's, as above, and the HUD that stays is bright and tappable, so a menu button switches panels in one tap. With the scrim above the HUD (the default, 50) the remaining HUD dims with the game and takes no taps.
- `GuiService.ReducedMotionEnabled` makes every change instant.

Sizes that reproduce the measured shares (tested in the simulator; the caps are judgment). Tablet columns are with the tablet scale of section 6, where the cap is in scaled units: 300 units is 510 px.

| Panel | Size | Galaxy A06 | iPhone 17 Pro | iPad 10th (scale 1.7) | Fire HD 10 (scale 1.7) | Average Windows |
|---|---|---|---|---|---|---|
| Grid (shop, inventory) | `UDim2.new(0.6, 0, 1, -16)`, `UISizeConstraint.MaxSize` 560x400, 560x300 on tablets | 423x264: 0.53 x 0.73 of the screen, 4 columns of 84 px cells, 2.1 rows | 450x307: 0.51 x 0.76, 4 columns, 2.5 rows | 707x510: 0.60 x 0.62, 4 columns, 2.5 rows | 575x510: 0.60 x 0.85, 3 columns | 560x400: 0.41 x 0.52, 5 columns |
| List (quests, daily) | `UDim2.new(0.5, 0, 1, -16)`, max 480x400, 480x300 on tablets; rows 52 units tall, 6 apart | 352x264: 0.44 x 0.73, 3.7 rows, a row is 14% of the screen height | 375x307: 0.43 x 0.76, 4.4 rows | 589x510: 0.50 x 0.62, 4.3 rows of 88 px | 479x510: 0.50 x 0.85, 4.3 rows | 480x400: 0.35 x 0.52, 6 rows |
| Small modal (settings, confirm) | `UDim2.new(0.45, 0, 0, 190)`, min width 300, max 420 | 317x190 | 337x190 | 530x323 | 510x323 | 420x190 |
| Side sheet | 150 units wide, 0.7 of the frame height, 8 from the edge | 150x196 | 150x226 | not run at scale | not run at scale | 150x497 |

With the grid panel open on a phone the left menu column stays, and the top currency row and the right action buttons slide off, so the balance goes in the panel header.

The tablet and list numbers rest on few frames (tablet panels 20 frames from 8 games, phone row lists 6 from 3), so treat these caps as a starting point: a panel that reads well outside them is not a violation.

## 5. Text entry and the keyboard

- On a phone the keyboard leaves only the top half of the frame: 140 of 280 px on the Galaxy A06, 143 of 323 on iPhone 17 Pro (section 1). A centred 190 px modal kept its TextBox 1 px above the keyboard and its Save button under it (tested).
- Put the TextBox in the top half of its panel and nothing the player needs while typing below it. `PanelStage` lifts the open panel until the focused TextBox is 8 px above the keyboard and puts it back on hide (tested on four devices).
- `UserInputService.OnScreenKeyboardPosition` is in viewport px: subtract `GuiService:GetGuiInset().Y` (58) to compare it with an `AbsolutePosition`. Its X is negative on a notched device, because the keyboard spans the screen.
- The simulator does not move the UI by itself; a real phone may (`roblox-ui-layout` section 6, keyboard notes). Type on a real phone once.

## 6. Tablet and desktop

Same layout on every device; positions follow Scale and anchors, panels are capped with `UISizeConstraint` (section 4). What changes is one scale factor on tablets.

**Tablets keep the phone's share of the screen, not its px.** Top games, tablet against phone (tablet HUD 10 frames from 9 games, mostly arena and shooter, 1 simulator: weak; phone 45 / 29; shares are plus or minus half a point):

| | Tablet | Phone |
|---|---|---|
| Menu button height, share of the screen height | 8.0% (3.6-11.5) | 9.5% |
| Touch action button | 11.2% (8 / 7) | 16.1% (24 / 15) |
| HUD text height | 2.2% | 2.5% |
| Bottom margin, share of the height | 1.4% | 1.2% |
| Side margins, share of the width | 0.7% and 0.5% (flush to the edge) | 5.2% and 4.9% (the notch inset) |
| Framed panel | 0.59 x 0.46 of the screen (20 / 8) | 0.45 x 0.71 (58 / 22) |

- In px that is about 1.7 to 1.9 times the phone size for menu buttons and 1.4 to 1.6 for action buttons (derived from the shares and an 820 px tall screen, never measured in px). The engine steps its own touch controls by 1.7: the jump button goes from 70 to 120 px, the stick ring from 74 to 148.
- An unscaled HUD is physically phone-sized on a tablet (both presets are about 131 px per inch) and reads as small: a 34 px menu button beside the 120 px jump button (one game's field note, 2026-11-12).
- Rule (judgment, from the weak sample and the engine's step): on a touch device whose safe frame's short side is over 500 px, scale the HUD and the panels by 1.7 (1.4 to 1.9 is inside what top games show). `ViewportDisplaySize` cannot pick this: it is Small on a Fire HD 10 and Medium on an iPad.

```luau
-- one UIScale parented to each ScreenGui (HUD, panels); the ScreenGui's own AbsoluteSize does not change
local function deviceScale(): number
	local frame = hud.AbsoluteSize
	local largeTouch = UserInputService.PreferredInput == Enum.PreferredInput.Touch and math.min(frame.X, frame.Y) > 500
	return if largeTouch then 1.7 else 1
end
local function apply()
	local k = deviceScale()
	hudScale.Scale, panelScale.Scale = k, k
	shop.UISizeConstraint.MaxSize = Vector2.new(560, if k > 1 then 300 else 400) -- tablet panels are shorter in share
end
hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply)
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(apply)
apply()
```

- Tested on Fire HD 10 and iPad 10th presets (2026-11-12): full-size layers still fill the frame, a 44 unit hit area is 74 px (its 34 unit icon 58 px: 7% of the iPad's height, 10% of the Fire's), action buttons sit beside the jump button with no overlap, `PanelStage` slides, swaps and follows the keyboard correctly.
- Inside a scaled ScreenGui one Offset unit is 1.7 px. Any px you compute from `AbsolutePosition` or `AbsoluteSize` must be divided by the scale before you write it back as an Offset (the action-button code in section 3 does; `PanelStage` does it for its slides and keyboard lift).
- Tablet facts: the jump button is 120 px at 50 px from the right and 90 px from the bottom, the keyboard takes 302-413 px. Tablet HUD in top games sits flush to the side edges. A button 40% down the left edge is easy on a phone and a stretch on a tablet (docs, `roblox-ui-layout` section 2).
- Desktop: no touch controls. Hide touch-only buttons through `UserInputService.PreferredInput`; show the key on the button instead. The chat window and the player list take the top-left and top-right corners (the sweep warns). A 560x400 panel is 0.29 x 0.37 of a 1080p screen: raise it with the root `UIScale` rule in `roblox-ui-layout` section 4 if the style wants it bigger (judgment).

## 7. Verify

1. Play, then run `roblox-ui-layout/scripts/ui_device_check.luau` through `execute_luau` with datamodel Client. It switches the simulator through the six devices of section 1 and reads the live `PlayerGui`: frame sizes, HUD coverage, the centre box, buttons in the jump keep box (error), on the resting stick ring (warning) or in the start area (share), buttons under 44 px, small text, elements off the frame, backdrops that stop short of the screen edge, buttons under a notch and overlaps between ScreenGuis (the `KitTransient` attribute and the ModuleScript shortcut: `roblox-ui-layout` section 6). Run it at idle, then once with each panel open. Fix every error.
2. Tap for real. In the simulator `user_mouse_input` is emulated touch, and it takes x in screen px and y in safe-frame px: a click by `instance_path` lands the left inset (47 px on the Galaxy A06, 62 px on iPhone 17 Pro) to the left of the target. Pass `x = AbsolutePosition.X + left inset` and `y = AbsolutePosition.Y`; the left inset is minus the `AbsolutePosition.X` of a `ScreenInsets.None` ScreenGui (tested 2026-11-12). A game session saw Studio MCP mouse and key input in Play flip `UserInputService.PreferredInput` to KeyboardAndMouse, after which a touch HUD on a simulated phone re-laid out as desktop: capture and sweep before any MCP input, read `PreferredInput` after one, and restart Play if it changed (field note, 2026-11-12; not reproduced here).
3. `screen_capture` each device at idle and with each panel open, and look: nothing under the controls, the balance visible, the close button inside the frame.
4. Simulator traps:
   - The simulated device is one setting for every Studio window on the machine. Read `GetDeviceAsync()` before a capture, and put the device back when done; another session may have changed it.
   - Edit draws no top bar, so the frame is 58 px taller than in Play. Final numbers come from Play.
   - Set the device before `SetOrientationAsync`; it errors while a desktop device is active (field note, 2026-11-12).
5. A real phone last: thumb reach, the keyboard, and the notch side.
