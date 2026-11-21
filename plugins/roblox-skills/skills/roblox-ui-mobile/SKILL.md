---
name: roblox-ui-mobile
description: "Use when designing, building or reviewing Roblox UI for phones first, then tablet and desktop: which Device Simulator presets to test, a phone-first build order, HUD placement around the thumbstick and jump button, how a panel opens and closes (size, dim or blur, which HUD slides off, close button, grid, tabs, timing) with a tested PanelStage module, measured HUD motion (counters, coin fly-to-counter, damage numbers, HP and XP bars, button press and cooldown, toasts, badges), the on-screen keyboard, tablet, desktop, a device sweep script. Also when agents test on an old small preset such as iPhone 7 or only on desktop, a panel fills the phone screen, hides the currency or opens over the HUD, a TextBox ends under the keyboard, action buttons hit the jump button on tablets, MCP clicks miss in the Device Simulator, or a counter, cooldown, HP bar, toast or badge animation is slow, jittery or overdone. Zone px and floors stay in roblox-ui-layout; the genre look in roblox-ui-genre-studs and roblox-ui-genre-scifi."
last_reviewed: 2026-11-19
sources:
  - Studio 0.747 Device Simulator, measured 2026-11-12 through Studio MCP execute_luau and user_mouse_input (Play, Client datamodel) on 16 presets (safe frames, touch controls, keyboard, ViewportDisplaySize); runs of scripts/panel_stage.luau and roblox-ui-layout/scripts/ui_device_check.luau; tap pass-through measured by the RoDesigner kit build (Studio 0.747, Play, Galaxy A06 preset touch and desktop mouse, 2026-11-16; result file read by us, not re-run)
  - Roblox client scripts, PlayerModule ControlModule DynamicThumbstick (read from PlayerScripts in Studio 0.747); EmulatedDevices.xml (mirror MaximumADHD/Roblox-Client-Tracker branch roblox at b0b3ae8, Studio 0.746)
  - creator docs performance-optimization/test-on-hardware, studio/device-simulator, input/mobile, reference BlurEffect (read 2026-11-12); Roblox built-in Studio MCP skill rbx-device-simulator-lua
  - StatCounter Global Stats, October 2026 (mobile OS, phone, tablet and desktop screen resolution, vendors; web page views, top 20 rows per chart)
  - Roblox FY2025 Form 10-K and Q3 2026 Form 10-Q (users and revenue by region); Counterpoint Research, best-selling smartphones of 2025; Roblox help article 203625474 (mobile system requirements, updated 2026-11-05)
  - RoDesigner research library, 2026-11-12, 84 phone frames with an open panel from 28 top games, 45 phone HUD frames from 29 top games, 50 tablet frames from 17 games and 24 row-list panels from 16 games (frames private; numbers and method only)
  - original (test set, recipes and thresholds marked judgment)
  - original motion reads, 2026-11-05 and 2026-11-19 (60 fps captures of five live games and 33 more UI clips, measured frame by frame; clips private, numbers and method only)
  - ParticleEmitter2D: DevForum staff post t/4996850 (Studio beta UI Particles, 2026-11-19), creator docs reference ParticleEmitter2D and ui/2D-particle-emitters (read 2026-11-20); property reads in Studio 0.748 with the beta off, and a five-effect HUD build run in Play with the beta on (2026-11-20)
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

Measured in the Studio 0.747 Device Simulator, in Play, landscape (2026-11-12). The safe frame is where a default ScreenGui draws: the screen minus the notch insets and the 58 px top bar. `Camera.ViewportSize` still includes the top bar, so it reads 58 px taller: 705x338 on the Galaxy A06 and 750x381 on iPhone 17 Pro (read 2026-11-13).

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
- A short-lived tap target (a bonus balloon, a pop-up chip) is a button too: spawn it outside the start area and the keep boxes, where it would take the thumb or be tapped by mistake (judgment). The `KitTransient` mark does not excuse it: the sweep and the RoDesigner kit lint still check a marked button against the zones.
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

**A light push on the stick walks.** The thumbstick is analog: a light push moves the character at a fraction of `WalkSpeed`, and the default Animate script blends the walk in. One game measured a stick input of 0.4 giving 8.4 studs/s with walk weight 0.73 and run 0.27. If the game should always run, re-apply the control module's move direction at length 1 each frame, after the control module runs; an emulated 12 px stick drag then moved 21 studs/s instead of 13. Verify with an emulated touch drag in the Device Simulator, not with `Humanoid:Move` (field note, 2026-11-15; a real phone and a gamepad not checked).

**Context hints need a hold.** A hint that follows a raw condition (Jump, Hide, nothing) flickered as it switched every 0.1-0.4 s while the runner left the ground or the line of sight moved. Once shown, keep each hint for a minimum time (0.4 s and 1.5 s by hint in one game), and let a hint that depends on standing wait out a jump (field note, 2026-11-16).

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
stage:open(buyPanel, { kind = "purchase" }) -- confirm or purchase: only its own buttons close it
```

- A modal `open` dims the game (0.5 black; `"blur"` is a `BlurEffect` of 16 plus a 0.25 dim), slides off the HUD layers whose elements come within 8 px of the panel, sets `GuiService.TouchControlsEnabled` to false, and pops the panel. `close` reverses all of it. A tap on the scrim closes, except for `kind` `"confirm"` or `"purchase"`: a stray tap must not cancel a money decision (an explicit `dismissOnScrim` still wins).
- **Your own panel bodies and dims are `Active`.** A Frame, label or image with `Active` false passes a tap to a button drawn behind it, inside one ScreenGui and across ScreenGuis with different `DisplayOrder`, on touch and with the mouse (measured, sources above). Before the fix every tap on an empty spot of an open panel reached the scrim and closed it (16 of 16 on touch over three layouts, 4 of 4 with the mouse); with `Active = true` on the panel, 0 of 16 and 0 of 4. A dim that was not `Active` let the button under it fire (2 of 2; 0 of 2 once `Active`). `InputSink = All` on a non-Active Frame did not stop the tap (2 of 2, mouse), though the docs describe it as sinking all input: set `Active`. `open` sets it on the panel; set it on any dim or backdrop of your own.
- `stage:destroy()` closes at once and removes what `new` made: the scrim ScreenGui, the `BlurEffect` in Lighting and the keyboard connection.
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

**Open and close, frame by frame.** One live simulator measured at 60 fps (three panels; frame-by-frame reads of 2026-11-05 and 2026-11-19), added to the survey above; basis per row as in section 4a. Where it differs from the Timing row: the 0.2 s there is the median of three tagged clips and `PanelStage`'s default, the 250 ms here is one game read frame by frame; both sit inside the measured 133-300 ms.

| Part | Value | Basis |
|---|---|---|
| Panel open | `UIScale` 0.90 -> 1.00 in 250 ms Back Out, growing from the panel's centre (AnchorPoint 0.5, 0.5; the `UIScale` on a plain Frame wrapper). Back Out alone peaks about +1% of the panel's size at 0.58 of the time: add no more. Other measured forms run from 133 ms Quad Out (snappy) to 300 ms Back Out (chunky) | measured, one game |
| Slide up while scaling (optional) | Start 8% of the panel's height lower, same 250 ms Back Out | measured, one game |
| Fade | None: no tagged clip fades the panel | measured |
| Never | Slower than 400 ms; a hero panel that pops with no tween | measured |
| Full-screen page (upgrades, skills) | No scale pop. The dark backdrop fades in over 200 ms Quad Out, then the plate (67 ms) and the rows, 130 ms each at 50 ms steps, at most 12 animated rows; the whole entrance within 600 ms | measured |
| Dim | Black to 0.5 in 200 ms Quad Out from the panel's first frame (`PanelStage`); keep it at 40% or darker. Measured dims are in place within 100-180 ms | judgment (200 ms, 40%); measured (100-180 ms) |
| Blur (optional) | `BlurEffect.Size` 0 -> 16 in 100-120 ms Quad Out with a 0.25 dim; skip it on low graphics quality. `PanelStage` blends it in over 200 ms | measured (117 ms in one clip); judgment (the rest) |
| HUD that leaves | Cut or faded out 67-150 ms after the panel's first frame; none slid (table above) | measured, one game |
| Which groups leave | A window panel: only the groups it covers, each off its nearest edge (menu column left, action buttons right, bars down, a top tracker up). A full-screen page: every group. Counters stay on both, or the balance goes in the panel header (measured, table above). The jump button and thumbstick are the engine's and cannot slide: hide them with `GuiService.TouchControlsEnabled` | judgment |
| Slide out | Until the whole group is off screen: its far edge plus a margin (`PanelStage` adds 80 px for a notch margin), from `AbsolutePosition` and `AbsoluteSize`, divided by the `UIScale` above it. 180 ms Quad In, starting on the panel's first frame, so the HUD is gone before the panel settles | judgment (`PanelStage`, tested on 7 presets); measured, one game (the start) |
| Order | Bottom first, then the sides, the top last: 0, 20 and 40 ms apart, all within 150 ms. `PanelStage` moves every covered layer at once | measured, one game (groups gone at 67, 83, 100 and 150 ms) |
| A group that cannot leave | Behind a notch or on a wide tablet: fade it to 0 in 100 ms instead of sliding. No fade on a full slide | judgment |
| Taps while moving | A group that is moving or off screen takes no taps: set its buttons' `Interactable` to false from the first frame of the slide until it is home | judgment |
| Close | `UIScale` 1.00 -> 0.90 in 120 ms Quad In, then hide; no overshoot, no wind-up. Measured closes take 100-300 ms, 0.35-0.6 of their open | measured |
| HUD back | 250 ms Quad Out to home, starting with the close, in the reverse order (top first); touch controls back on when the close starts | judgment (`PanelStage`, which moves all layers at once) |
| Dim after close | Released over 400-500 ms Quad Out once the panel is gone. `PanelStage` releases it over 200 ms from the start of the close, so it still ends after the panel | measured; judgment (`PanelStage`) |
| Close during the open | Stop the running tweens and tween from the current values to the close targets; never snap to the open end state first. The same for an open during a close. Keep the full 120 and 250 ms | judgment |
| Reduced motion | Listen for changes of `GuiService.ReducedMotionEnabled`: every scale and slide is instant or a Linear fade of 100 ms or less, with no overshoot and no stagger. The dim stays: it is state, not motion | judgment (the setting: docs) |

Check it on a 60 fps capture: count the frames of the open (at 0.2 s the panel settles at frame 12, at 250-300 ms at frames 15-18; the covered HUD is gone by frame 11); tap close at frame 5 of the open and the panel turns back from where it is; open one panel from another and the dim does not flicker; on the Galaxy A06 and a tablet preset every slid group leaves the screen completely; with Reduce Motion on nothing moves and every end state is the same.

**A window that looks designed, opens in order and answers a press.** The rows above make a panel that is the right size and moves at the right speed; a build that followed them and nothing else still read as "a generic kit" to two blind judges, who scored it 66 against 75 (sums of two, out of 100) for a designer's posted quest window (2026-11-21; the designer's window read frame by frame at 30 fps; one comparison, so read the numbers as a lead). Its text and its routine claim scored level or better; it lost on the look of the window (6 against 9 of 10) and on how the window opens. What both judges asked for, as rules (basis: these two judges unless a row says measured):

| Part | Do | Not |
|---|---|---|
| Finish of the window and every card | Four things together: a dark outer `UIStroke` (3-4 px on the window, 2 on cards), a vertical `UIGradient` (the top about 10% lighter than the bottom), a 2 px light line inside the top edge, and a soft shadow under it (a darker rounded Frame 4-6 px lower, 60-70% transparent). One diagonal sheen band at about 10% white across the header or the main card (a white overlay Frame with a rotated `UIGradient` whose `Transparency` is clear, 0.9, clear) | Flat single-colour fills; a stroke as the only depth |
| A hero in the window | One element that breaks the frame: the header emblem or the selected item's art at about 100 px, sitting 16-20 px over the top edge, tilted 6-8 degrees. In a detail pane the selected item's art is the largest thing in it | Every icon the same 40-60 px inside its box |
| Decoration, a little | A plate or ribbon behind the title, 2-3 sparkle accents near it, a 4 px colour stripe on each row for its category, labels under HUD buttons (12 px or more, stroked) | Bare text on the header; unlabeled HUD icons |
| Selected is not ready | Selected: a bright 3 px outline and a row fill about 10% lighter. Ready to claim: its own mark (a green chip or a small bouncing gift on the row). Never the same outline for both | One gold outline for "selected" and for "claimable" |
| Empty space | A short list ends with a card that says why and when (all done, new in 05:11:50), or the pane shrinks to its rows. Blocks in a detail pane sit under each other with one gap; no hole between description and progress | Three rows over a blank pane |
| Open: shell first, then content in order | Measured on the designer's window, about 0.95 s in all: the empty panes fade in and settle in 0.17 s (they come tilted in perspective; a `UIScale` 0.92 -> 1 does the job in 2D) while the scene dims; then the header emblem pops; the tabs one by one (30 ms apart); the list rows slide in with a fade from one side, top to bottom (40 ms apart, each row whole, with its content); the detail text; its progress slots one by one; the main button; the close button pops last, rotated, with overshoot; reward tiles pop and progress marks fill last. The window itself is usable from about 0.3 s | The whole window as one block popping in; empty row frames that fill in later (named as a defect); anything still arriving after 1 s |
| Close | Measured: the close button goes first (2 frames), then the window fades out while it shrinks or tilts back, 0.2-0.25 s, and the dim goes with it. To fade a window make its root a `CanvasGroup` and tween `GroupTransparency` (one per window, never one per row) | An opaque shrink that ends in a one-frame cut |
| A press is seen before the state changes | The pressed button squashes to 0.92 in 60-80 ms, rebounds to 1.05-1.08 and settles in about 150 ms (Back Out), with a white flash of 100-120 ms; the label and colour change after the squash, not on the press frame | A button that is already "Claimed" on the frame it is pressed |
| Claim | Measured, about 1.1 s in all: by 70 ms the button has changed; each reward tile lifts off its slot, grows and tilts, flies on an arc to its counter and shrinks into it (0.4 s each, 70 ms apart) while the slot keeps a faded copy in its own colour; the counter counts up for 0.5 s with a "+N" label that rises about 24 px and fades, and bumps to about 1.15 on arrival; then the list re-sorts | A claim over 2 s; a slot that turns near-black |
| Re-sort | Rows are keyed by item and tween to their new places over 0.25-0.3 s Quad Out; the outline, badge and selection are children of their row and travel with it; the detail pane changes on the same frame the selection does | Removing and re-inserting rows; rows overlapping mid-move; an outline left behind over the wrong row |
| Bigger moments for bigger rewards | A routine claim is the flight above. A weekly or special one adds, behind the reward: rays that turn about 30 degrees over 0.8 s, 20-30 star pieces over the window, a stamped title that scales 1.4 -> 1.0 in 0.25 s and stays about 0.6-1.5 s (measured: the designer's special claim ran a hue-cycling ray burst behind the emblem and a full-width title for about 1.5 s) | One sequence for every tier |
| Tab change | The old rows leave and the new ones arrive in about 0.5 s in all; the list is never blank for a visible moment (the designer's 0.8 s change with an empty list for 0.2 s was marked down by both judges) | A slow change through an empty list |
| Text floors still win | Secondary text of 7-9 px on a phone was marked down in the designer's window. Keep the floors of section 0 and `roblox-ui-typography` while adding all of the above | Shrinking text to make room for decoration |

`scripts/window_kit.luau` is a client ModuleScript that does the rows above with Frames only (no images, no uploads); `scripts/window_kit_demo.luau` builds a small missions window with it and plays every motion in a loop. Copy both as ModuleScripts into one folder (`ReplicatedStorage.Ui.WindowKit`, `WindowKitDemo`) and read the demo for the calls, not for its palette. The ScreenGui must use `ZIndexBehavior` Sibling (`Instance.new("ScreenGui")` defaults to Global; the kit warns once).

| Call | Does |
|---|---|
| `Kit.card(parent, { size, position, anchor, fill, radius, strokeWidth, depth, sheen, padding, button })` -> `outer, content` | A surface with the whole finish: dark outline, lighter top, light line inside the top edge, shadow `depth` px lower. Place, size and animate `outer`; parent your children to `content`. Use it for the window, panes, rows, tiles and chips, so they share one depth |
| `Kit.button(parent, { text, textSize, font, fill, ... })` -> `button, label` | The same finish on a TextButton with a stroked label |
| `Kit.recolor(card, fill, stroke?)` | A state change (in progress, claim, claimed, locked; selected) in 0.12 s |
| `Kit.finish(frame, { radius, stroke, lift })` | Corner, outline and lighter top on a Frame you already have (no shadow, no extra children) |
| `Kit.press(button, fn)` | Squash to 0.92 in 70 ms, rebound with overshoot, a light flash; `fn` runs after the squash. `Kit.squash(button)` is the motion alone |
| `Kit.open(window, groups, { shell, budget, delay })` | The shell fades in and settles in 0.17 s, then each group arrives in order: `{ item or { items }, "pop" | "slide" | "fade" | "spin" | "fill", gap = seconds, from = side }`. Every item arrives whole, with its content. `shell = false` for a pane inside an open window, or when PanelStage pops the window |
| `Kit.close(window, { first = closeButton, done })` | The close button pops out, the window fades while it shrinks, 0.22 s, then everything is put back for the next open |
| `Kit.list(scroll, { gap, pad })` -> `list:add(key, row)`, `list:show(keys)`, `list:order(keys)`, `list:reveal(key)`, `list:shown()` | Keyed rows without a `UIListLayout`: the kit sets each row's Y. `show` makes rows leave, arrive and move in one go (a tab change with no blank list); a row that would cross others (a claimed row going down) fades out here and in there, so rows never overlap mid-move |
| `Kit.fly(fromGui, toGui, { count, onArrive })` | Copies of a reward lift, grow, tilt, fly on an arc and shrink into the counter, 0.4 s each, 70 ms apart; the counter bumps as each lands |
| `Kit.count(label, from, to)` | Counts in 0.5 s with a bump and a "+N" that rises 24 px and fades. `Kit.comma(n)` formats |
| `Kit.burst(anchor, { tier = 1..3, color })`, `Kit.stamp(gui, hold)` | The bigger moment: rays that turn behind the reward and four-point glints thrown outward; a title that lands at 1.4 -> 1 and holds |
| `Kit.steps(parent, total, done, { color })` -> `steps:set(n)` | Progress as step slots; a newly done step pops |
| `Kit.pulse(gui)`, `Kit.bob(gui, px, period, tilt)`, `Kit.sheen(card, { period })`, `Kit.still(gui)` | Idle motion: the breath of something ready, the float of a hero emblem, a light band across a card; `still` stops them |
| `Kit.slideTo(marker, tab)`, `Kit.fade(gui, to)`, `Kit.glint(parent, size, color)`, `Kit.settle(root)`, `Kit.run(...)` | A tab marker; fade a whole item to 0, 0.4 or 1; a sparkle; end every motion under a root now; your own motion on the kit's clock |

Read frame by frame on a 30 fps capture of the demo (Studio Play, a 1309 x 707 view, 2026-11-21): on open the empty panes show first, then title plate and emblem, the tabs, the rows one by one from the left, the pane's content, the close button last, all in by about 0.75 s; on a claim the button reads CLAIMED about 0.1 s after the press, five coins land between 0.4 and 0.75 s while the counter counts up, and at 1.0 s the claimed row fades out, the others close the gap and it fades in at the bottom, with no two rows overlapping in any frame; the close took 6 frames. Limits: not judged blind yet; not run on the phone presets (the demo scales one desktop layout, which drops text under the floors on a phone); not tried together with `panel_stage.luau`, with a gamepad, or across two ScreenGuis with different insets (`Kit.fly` measures both ends by `AbsolutePosition`). The fade of a closing window is per object, so stacked cards show through each other for those 6 frames; a `CanvasGroup` root fades as one image at the cost of its memory. Found while building it: a weak-keyed table lost Instance keys that no Luau variable held although the instances were still on screen, so a record of "what to restore" must be a strong table that is cleared by hand.

## 4a. HUD motion

How each HUD element moves, measured frame by frame on 60 fps captures of five live games and on 33 more UI clips (two sets of reads, 2026-11-05 and 2026-11-19). Times are in ms; easing names are `Enum.EasingStyle` and `Enum.EasingDirection` (Quad Out is style Quad, direction Out).

| Basis | Means |
|---|---|
| measured | read frame by frame on several clips or games |
| measured, one game | one live game, or a read of medium confidence |
| judgment | no clip shows it; set from the measured rows around it |
| not measured yet | no clip covered this case; a starting value. Capture your build at 60 fps and tune it |

Panels and the HUD that leaves for them: section 4. A stud-style game may keep its house pop, button squash and count-up (`roblox-ui-genre-studs` section 5, judgment); the rows here are what live games were measured doing.

**Rules for every element**

| Rule | Value | Basis |
|---|---|---|
| Entrances are fast | Routine UI 133-270 ms, Quad or Exponential Out. Over 400 ms only for a hero moment | measured |
| Exits are shorter | 0.35-0.6 of the entrance; a hard cut is fine for routine UI | measured |
| Overshoot only on pops | Back Out on pops: live games overshoot 1-5% of the element's size, Roblox's Back Out about 10% of the travel. None on toasts, fills, counters or closes | measured |
| Counts are short | 330-850 ms for any size of change, never over 1 s | measured |
| Flash | On for 1 frame, then a 330-530 ms decay, Quad or Exponential Out; at most 3 a second (`roblox-feel-audio-vfx` section 3b) | measured |
| Stagger | 50-83 ms between the items of a dense grid, 117-150 ms between cards; the whole group within 600 ms, at most 12 animated items | measured |
| Idle motion is tiny | A glow breathes +7% brightness over a 2.1 s period; a featured item moves under 1 px. No large bob, no spin on HUD icons | measured |
| Never tween | `TextSize`, `UIStroke.Thickness` or the `Size` of text: scale a `UIScale` instead (`roblox-ui-typography` section 4) | docs |
| Reduced motion | With `GuiService.ReducedMotionEnabled`, scales and slides are instant or a Linear fade of 100 ms or less; no flashes, loops or shakes; counts take 300 ms or less | judgment (the setting: docs) |

**Counters (currency, power, any stat readout)**

| Event | Build to | Basis |
|---|---|---|
| Value goes up (reward, sell, claim) | Count from the old value to the new one in 650 ms Quart Out (fast start, short tail). Linear over 330-830 ms is the other measured form: Linear when the count is the show (a results screen), Quart or Cubic Out on the HUD | measured (HUD cash 650 ms Quart Out, a popup amount 850 ms Cubic Out, results rows Linear 330-830 ms) |
| Small pickup (a coin, +1) | No count: swap the number in the same frame. Never hold the readout until a flight lands (`roblox-feel-audio-vfx` section 3b) | measured |
| Bump on change | Most measured counters do not bump. Two games do, in two sizes: a small punch, `UIScale` 1.00 -> 1.05 and back in 65 ms in all; or a spring punch on the icon and the number together, +12% in one frame, then -8% at 50 ms, +2% at 120 ms, -3% at 200 ms and at rest by 270 ms, with a brightness flash of about +9% on the row that decays over the same 270 ms. Either only on a discrete arrival, never during a count | measured (no bump); measured, one game (each punch; the spring at 60 fps, high confidence) |
| Suffix change (K, M, B) | Switch the suffix during the count as the value crosses it, with no extra effect | measured |
| Digits | Equal-width digits, or right-aligned in a fixed box, so the number does not jitter while counting (fonts: `roblox-ui-typography` section 6) | measured |
| Timer digits | Swap once a second, no tween | measured, one game |

**Currency flying to the counter**

| Part | Build to | Basis |
|---|---|---|
| Burst | 9-12 icons leave the source in 150-180 ms, Exponential Out, scattered 40-90 px | measured, one game (12 bills in about 150 ms); judgment (the scatter) |
| Flight | Each icon flies to the counter's icon in 680 ms Quad In (slow start, fast arrival), over about 0.43 of the screen width. For other distances: clamp(250 + 0.6 x distance, 380, 700) ms, with the distance in px on a 1080 px tall screen | measured, one game (the flight); judgment (the formula) |
| Launch stagger | 15-50 ms between icons; the measured game launched one a frame, about 30 icons | measured, one game |
| Counter | Counts in parallel (counters above), not in step with the arrivals; the last icon lands about 1.1 s after the burst | measured, one game |
| Phones | At most 12 live icons, from one reused pool; no trail on low graphics quality | judgment |

**Numbers over the world (+N, damage, stat gain)**

| Event | Build to | Basis |
|---|---|---|
| Damage number | Appears at full size in 1 frame, holds 230 ms while drifting 8 px, then breaks up or fades over 310 ms Quad In. No slow float upward | measured, one game |
| Stat or multiplier text | Pops 0.80 -> 1.00 in 100 ms with no overshoot; each later change punches +5% and returns in 65 ms | measured, one game |
| High fire rate | Do not scale a number in on every hit; show it at full size | measured, one game |
| Combo or streak text | Wipes in over 230 ms Exponential Out and settles 1.15 -> 1.00 over 340 ms Back Out, all within 500 ms; holds about 3 s, with no bounce while it holds | measured, one game |

**Bars (HP, XP, level, progress)**

| Event | Build to | Basis |
|---|---|---|
| Stat or XP bar fills to its value | Linear, about 1.0-1.1 s per bar; several bars fill one after another, 1.2 s apart, the active row scaled to about 1.4x while it fills | measured, one game |
| Hold-to-confirm bar | Speeds up: 0 -> 100% over 2.3 s Quad In, then holds full for 280 ms before the result | measured |
| Timing or power marker | Appears in 100 ms; moves faster and faster (Quad In) | measured, one game |
| XP bar gains | The label number swaps in the same frame as the gain; the fill follows. Form A: Linear at a constant 1.5 bar widths a second (a gain of 38% of the bar takes 250 ms), and the bar's plate squashes wider and flatter, +1.3 to +2.6% in width and -4% in height, for about 200 ms on each gain. Form B: the fill eases out to its target over about 200 ms, no squash | measured, two games (60 fps, high confidence) |
| XP bar on a level up | Form A: the bar empties and the label changes to the new level in one frame; it does not wait for the fill to reach the end, and there is no flash. Form B: the label changes, the plate punches +3% in one frame and springs back (-4.5% at 50 ms, +1.4% at 130 ms, at rest by 270 ms), and the fill runs down from full to the new value over about 270 ms, easing out | measured, two games |
| Resource bar that empties (stamina) | The fill turns red while it recovers from empty and goes back to its normal colour when it is usable again; the bar hides while empty | measured, one game (read from frames, no curve fitted) |
| HP bar loses health | The front bar snaps to the new value in 1 frame; a lighter bar behind it waits 250 ms, then shrinks over 300 ms Quad Out (the late "ghost" bar of `roblox-feel-audio-vfx` section 3b) | not measured yet |

**Skill and action buttons**

| Event | Build to | Basis |
|---|---|---|
| Press | Three measured forms: no scale, a hard step to 0.67 of the brightness while held and an 83 ms white flash (+27%) on release; a squash, `UIScale` 1.00 -> 0.875 in 50 ms (decelerating), held about 33 ms, back to 1.00 in 50-67 ms with a +1% overshoot, about 150 ms in all; or nothing at all | measured (no scale, nothing); measured, one game (the squash, 60 fps, high confidence) |
| After a press that starts something | A 320 ms dark "pending" state, then the new state (disabled or cooling down) | measured, one game |
| Cooldown sweep | A dark overlay cleared clockwise from 12 o'clock at constant speed (Linear, so the time left reads true); whole seconds as a number while more than 1 s is left, ticking once a second with no tween. One game showed a segmented ring gauge that drains clockwise at a constant rate (not timed) | not measured yet |
| Ready again | `UIScale` 1.00 -> 1.10 -> 1.00 in 200 ms Back Out, plus a 1-frame flash with a 330 ms decay | not measured yet |
| Hover (desktop only) | Scale 1.02-1.15 in 100-170 ms, or +16% brightness in 110 ms with no scale; out in 60-160 ms. Touch has no hover: the press gives the feedback | measured |
| Selected slot ring | Jumps to the new slot and grows 0.93 -> 1.00 in 133 ms Quad Out; the old ring goes at once | measured, one game |

**Toasts, banners and prompts**

| Kind | Build to | Basis |
|---|---|---|
| Plain text toast (no plate) | Fades in over 400 ms, holds 2 s, fades out over 170 ms; no slide | measured, one game (low confidence) |
| Stat or level toast on a band | Slides in from the left edge in 358 ms Quart Out, no overshoot; holds over 2 s | measured, one game |
| Call-to-action popup from the top | Drops in over 200 ms, overshoots by 24% of its travel and comes back in 200 ms; stays until tapped. The only toast that overshoots | measured, one game |
| Win or result banner | Grows from 8% of its width to full in 400 ms Quad Out while rising 34 px | measured |
| Level-up banner | Unfolds in 600 ms Back Out (2.5% overshoot) after a 60 ms lead flash, or hard-pops in 70 ms with a 130 ms gold flash; its particles outlive it by about 1 s | measured (unfold); measured, one game (hard pop) |
| Subtitle or dialogue line | The box appears in 1 frame; the text fades in over 90 ms or types at 45-90 characters a second; out with a 100 ms Linear fade | measured, one game |
| Tooltip or hint card | The card appears in 1 frame and its text fades in over 80 ms, or the card drops 82 px in 500 ms Quad Out; it leaves with a hard cut | measured (appear, cut); measured, one game (drop) |
| Tutorial focus | The world dims to about 10% brightness in 400 ms Exponential Out, with a highlight on the target; back in 300 ms Quad Out | measured, one game |
| Quest tracker update | Hard swaps: a new objective replaces the old one in one frame at full size; the progress number and its bar follow the value with no tween; at completion the bar and the number vanish and a one-word praise line takes their place in the same frame, then holds until the next hint replaces it. A softer option: a 1-frame flash with a 330 ms decay on the completed row | measured, one game (50 ms steps); judgment (the flash) |

**Badges and idle attention**

| Event | Build to | Basis |
|---|---|---|
| Alert badge ("!" or a red dot) | Appears at full size in one frame, no scale-in. Of three badges seen, two stay still and one pulses: a continuous loop between 0.89 and 1.11 of its mean size (+25% from smallest to largest), about 600 ms each way with a short rest at both ends, a 1.23 s period, Sine InOut, on a `UIScale`. At most 2 badges pulsing at once. A wobble or a colour pulse also fits. Never tween the badge's `Size`; a pulse is continuous scaling, so a "!" drawn as text steps between font sizes (`roblox-ui-genre-studs` section 5): draw the mark as an image, or wobble or pulse colour | measured, one game (the pulse at 60 fps, high confidence; the appear); judgment (at most 2, wobble or colour) |
| Card or button glint | A diagonal highlight crosses in 330-500 ms, once every 4 s, on hero items only | measured |
| Glow breathing | +7% brightness, 1050 ms each way Sine InOut | measured |
| Sparkle | Lives 250 ms (brightest at 100 ms); a new one every 150-250 ms | measured, one game |

**The HUD as a whole**

| Event | Build to | Basis |
|---|---|---|
| HUD appears after loading or a cutscene | Every group in one frame after a 630 ms beat with no UI, or a 560 ms cross-fade | measured, two games |
| HUD leaves for a panel | Section 4 | |
| Phone budget | About 40 live tweens at once; pause loops while their group is hidden; at most 24 pooled particle images | judgment (working limits, not from Roblox docs) |

**UI particles: a native emitter in Studio beta**

`ParticleEmitter2D` emits 2D particles from any `GuiObject` (Studio beta since 2026-11-19, DevForum t/4996850; status in `roblox-engine-2026` section 6). Places that use it cannot be published until Roblox ships it to the client, so pooled ImageLabels under the budget above stay the shipping method until then.

| Point | Value | Basis |
|---|---|---|
| What it replaces once live | The burst and sparkle layers: ring and spray bursts, confetti, button sparkle, hit sparks, the particles a level-up banner leaves behind. The flight to the counter stays scripted: particles move by speed, acceleration and drag and cannot home on a target | judgment |
| Units | `Size` is a half size in offset px (32 draws 64 px across); `Speed` in px a second; `Acceleration` in px a second squared on the parent's X and Y; `EmissionOffset` and `EmissionSpread` are fractions of the parent's size | docs |
| Direction | Emits up by default; `EmissionAngle` in degrees adds to the parent's rotation; `SpreadAngle` 360 sends particles every way; `EmissionMode` Point (centre) or BoundingBox (the whole parent) | docs |
| Look | `Color`, `Transparency` and `Size` follow the particle's age; `Squash` stretches it; `Blend` 0 is normal, 1 additive; `Brightness` above 1 glows; `TimeScale` 0-1 slows or freezes; `Emit()` sends 16 (it drew nothing in our test: see Bursts below); flipbooks 2x2, 4x4, 8x8 or Custom at up to 30 frames a second; `FlipbookStartRandom` with a framerate of 0 gives each particle one random frame | docs |
| Layering | Particles draw above the parent's strokes and inset shadows; `ZIndex` orders only emitters on the same parent | docs |
| Known limits | Not clipped in a SurfaceGui or BillboardGui; styling (`StyleSheet`) does not apply; particles vanish at once when the parent is culled | docs (release notes) |
| Defaults of a new emitter | Enabled, `Rate` 20, `Lifetime` 5-10 s, `Speed` 64, `Size` 32, BoundingBox, the built-in sparkle texture: it streams until you turn it off, so set `Enabled` false for a burst-only emitter. Writes clamp `Blend` and `TimeScale` to 0-1, `Brightness` to 0 or more and the flipbook grid to 1-64 | measured (property reads, Studio 0.748, beta off) |
| Beta off or on | With the beta off the class exists and takes every property but draws nothing. With it on, emitters draw in Play | measured (Studio 0.748, 2026-11-20) |
| Bursts | `Emit(n)` drew nothing: with `Rate` 0, 0.01 or set to 0 later, with and without a flipbook. A short `Rate` pulse works: set `Rate = n / 0.12`, set it back to 0 after 0.12 s, and about n particles come out (give or take a frame). For a burst-only emitter keep `Enabled` true and `Rate` 0 between bursts | measured (Studio 0.748, beta on, Play, 2026-11-20) |
| Spawn and direction | Particles start at a random point inside the parent (the default BoundingBox), so the size of the parent frame is the spawn area. `EmissionAngle` 0 sends them up and 90 to the right; `Acceleration` +Y pulls them down the screen; `Blend` 1 adds light | measured (same build) |
| Scale | A `UIScale` above the emitter scales particle size and travel alike. Build the effect at one design size (for example a 1280x720 stage), fit the stage to the screen with one `UIScale`, and it keeps its look on every screen | measured (same build) |
| Cost on a phone, clipping by `ClipsDescendants` or a `CanvasGroup` | Not measured yet. Before relying on it, compare live particle counts against a pooled-ImageLabel baseline in the Device Simulator | not measured yet |

The rows marked not measured yet (HP bar loss, cooldown sweep, ready pop) have no measured clip behind them: the captured games are simulators and show neither, so they need 60 fps captures of combat or RPG games. Build them from the starting values, capture your build at 60 fps and count frames against the rules above.

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
2. Tap for real. In the simulator `user_mouse_input` is emulated touch, and it takes x in screen px and y in screen px minus the 58 px top bar: a click by `instance_path` lands the left inset to the left of the target (47 px on the Galaxy A06, 62 px on iPhone 17 Pro) and the top inset above it (0 on the A06, 20 px on iPhone 17 Pro). With `n` = the `AbsolutePosition` of a `ScreenInsets.None` ScreenGui (-47, -58 on the A06; -62, -78 on iPhone 17 Pro), pass `x = AbsolutePosition.X - n.X` and `y = AbsolutePosition.Y - n.Y - 58`. Tested 2026-11-12 on the A06 and 2026-11-13 on iPhone 17 Pro: taps sent at y 102 and 202 landed at 82 and 182, and a tap sent with the formula hit a 5 px row. A game session saw Studio MCP mouse and key input in Play flip `UserInputService.PreferredInput` to KeyboardAndMouse, after which a touch HUD on a simulated phone re-laid out as desktop: capture and sweep before any MCP input, read `PreferredInput` after one, and restart Play if it changed (field note, 2026-11-12; not reproduced here; the RoDesigner kit lint warns INPUT_NOT_TOUCH for this case from 0.1.16).
3. `screen_capture` each device at idle and with each panel open, and look: nothing under the controls, the balance visible, the close button inside the frame.
4. Simulator traps:
   - The simulated device can carry over between Studio windows on one machine. Seen: a new window opened on the device another session had set, and listed that session's custom devices (2026-11-12); another time a new window read Default right after another window set a phone preset (one report, 2026-11-13). Whether a change reaches a window that is already open was not measured. So read `GetDeviceAsync()` before a capture, and put the device back when done.
   - Edit draws no top bar, so the frame is 58 px taller than in Play. Final numbers come from Play.
   - Set the device before `SetOrientationAsync`; it errors while a desktop device is active (field note, 2026-11-12).
5. A real phone last: thumb reach, the keyboard, and the notch side.
