--!nonstrict
-- fx_capture: freeze-frame capture for effects built on fx_clock (roblox-feel-audio-vfx section 3d, "Verify").
-- The effect's clock stops exactly on each beat time (FxClock.breakpoints): every emitter's TimeScale and beam
-- TextureSpeed go to 0 and the clock's curves stop, so a late screenshot still shows that beat. A line
-- "FXCAP|tag|index|t|epochMs" is printed at each freeze and "FXDONE|tag|peak ..." with the peak live counts
-- when the effect has cleaned up. Client only: run it from a LocalScript or Studio MCP execute_luau in the
-- Play Client DataModel. Ran in Studio 0.747 Play on 2026-11-17 for fire_slash, hit_impact and level_up_aura.
--
-- Stepping for an agent that captures with Studio MCP screen_capture (it renders on demand, so it works while
-- the window is in the background):
--   local cap = require(folder.fx_capture)
--   cap.begin("FireSlash", function() return FireSlash.play(hero) end, FireSlash.CAPTURE_TIMES,
--     cap.cameraAt(focus, Vector3.new(20, 6.5, 5)))      -- freezes on the first beat, returns "t=..."
--   -- screen_capture, then:
--   cap.step()                                            -- runs on to the next beat; repeat per beat
-- Lay the frames in one row in beat order (one strip per cast) and read it against the checks in section 3d.
-- Effect play() functions must build their clock inside the call: the breakpoints are read when a clock is made.
--
-- Background capture (section 3e, 2026-11-18): run(tag, play, times, { hold = s, scale = 0.25, marker = true })
-- holds each beat for `hold` real seconds and draws a 9-square binary frame marker at the bottom left (mark(i)),
-- so an OS-level capture loop of the Studio window can tell which beat a snapshot shows (a background window can
-- redraw late and show an older frame). Without opt.marker no marker is drawn (the stepping above).
-- count() also counts Highlights and the visible GuiObjects of the cutscene ScreenGui "CineScreen"; the mouse
-- icon is hidden during a run (it drew into the viewport crop).

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local FxClock = require(script.Parent.fx_clock)
local FxTextures = require(script.Parent.fx_textures)

local FxCapture = {}

-- Frame marker for background capture: 9 squares of 8 px on a black bar at the bottom-left of the screen,
-- square 0 always white, squares 1-8 the bits of idx (white = 1); idx 0 means "running, not a beat".
-- mark(nil) hides it. Drawn above every other ScreenGui. A capture loop saves a snapshot only when two snaps in a
-- row show the wanted index.
local markerGui = nil
local markerCells = {}
function FxCapture.mark(idx: number?)
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not markerGui or not markerGui.Parent then
		markerGui = Instance.new("ScreenGui")
		markerGui.Name = "CapMarker"
		markerGui.IgnoreGuiInset = true
		markerGui.ScreenInsets = Enum.ScreenInsets.None
		markerGui.DisplayOrder = 1000000
		markerGui.ResetOnSpawn = false
		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.BorderSizePixel = 0
		bar.Size = UDim2.fromOffset(9 * 10 + 4, 14)
		bar.Position = UDim2.new(0, 0, 1, -14)
		bar.Parent = markerGui
		for k = 0, 8 do
			local c = Instance.new("Frame")
			c.BorderSizePixel = 0
			c.Size = UDim2.fromOffset(8, 8)
			c.Position = UDim2.fromOffset(3 + k * 10, 3)
			c.Parent = bar
			markerCells[k] = c
		end
		markerGui.Parent = pg
	end
	markerGui.Enabled = idx ~= nil
	if idx then
		markerCells[0].BackgroundColor3 = Color3.new(1, 1, 1)
		for k = 1, 8 do
			local on = bit32.band(idx, bit32.lshift(1, k - 1)) ~= 0
			markerCells[k].BackgroundColor3 = if on then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
		end
	end
end

-- Fixed camera from a focus point and an offset (about 22 studs away was used for the strips).
function FxCapture.cameraAt(focus: Vector3, offset: Vector3): CFrame
	return CFrame.lookAt(focus + offset, focus)
end

-- The player camera scripts put CameraType back, so the fixed camera is re-applied every frame after them.
-- camera(nil) gives the camera back to the player.
local camBound = false
function FxCapture.camera(cf: CFrame?)
	local cam = workspace.CurrentCamera
	if camBound then
		RunService:UnbindFromRenderStep("FxCapture_Camera")
		camBound = false
	end
	if not cf then
		cam.CameraType = Enum.CameraType.Custom
		return
	end
	RunService:BindToRenderStep("FxCapture_Camera", Enum.RenderPriority.Camera.Value + 1, function()
		cam.CameraType = Enum.CameraType.Scriptable
		cam.FieldOfView = 70
		cam.CFrame = cf
	end)
	camBound = true
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = cf
end

-- Live counts per frame while effects run (peak is kept).
FxCapture.peak = { emitters = 0, beams = 0, lights = 0, parts = 0, highlights = 0, guis = 0 }
function FxCapture.count()
	local c = { emitters = 0, beams = 0, lights = 0, parts = 0, highlights = 0, guis = 0 }
	local rt = workspace:FindFirstChild("FxRuntime")
	if rt then
		for _, d in rt:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				c.emitters += 1
			elseif d:IsA("Beam") and d.Enabled then
				c.beams += 1
			elseif d:IsA("Light") then
				c.lights += 1
			elseif d:IsA("BasePart") and d.Name ~= "Host" then
				c.parts += 1
			elseif d:IsA("Highlight") then
				c.highlights += 1
			end
		end
	end
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local sg = pg and pg:FindFirstChild("CineScreen")
	if sg then
		for _, d in sg:GetDescendants() do
			if d:IsA("GuiObject") and d.Visible then
				c.guis += 1
			end
		end
	end
	for k, v in c do
		FxCapture.peak[k] = math.max(FxCapture.peak[k], v)
	end
	return c
end

-- Freeze-frame run. play: a function that starts the effect and returns its clock. times: beat times in clock
-- seconds. opt.hold: real seconds per frozen frame (default 1). opt.scale: clock speed between beats (0..1,
-- default 0.25). opt.camera: a CFrame for the fixed camera. opt.marker: draw the frame marker (mark).
function FxCapture.run(tag: string, play: () -> any, times: { number }, opt)
	opt = opt or {}
	local mark = if opt.marker then FxCapture.mark else function(_: number?) end
	local hold = opt.hold or 1.0
	local scale = opt.scale or 0.25
	FxCapture.peak = { emitters = 0, beams = 0, lights = 0, parts = 0, highlights = 0, guis = 0 }
	game:GetService("UserInputService").MouseIconEnabled = false -- the cursor drew into the viewport crop
	if opt.camera then
		FxCapture.camera(opt.camera)
	end
	FxClock.defaultScale = scale
	FxClock.breakpoints = times
	FxClock.onBreak = function(clock, t, i)
		FxCapture.count()
		mark((opt.first or 1) + i - 1)
		print(string.format("FXCAP|%s|%d|%.3f|%d", tag, i, t, DateTime.now().UnixTimestampMillis))
		task.delay(hold, function()
			mark(0) -- "running": a background snap taken now is not a beat frame
			clock:setScale(if i >= #times then 1 else scale)
		end)
	end
	mark(0)
	local ok, clock = pcall(play)
	FxClock.defaultScale = 1
	FxClock.breakpoints = nil
	FxClock.onBreak = nil
	if not ok then
		error(clock)
	end
	clock:every(function()
		FxCapture.count()
	end)
	clock:onCleanup(function()
		mark(nil)
		game:GetService("UserInputService").MouseIconEnabled = true
		local pk = FxCapture.peak
		print(string.format("FXDONE|%s|peak emitters=%d beams=%d lights=%d parts=%d highlights=%d guis=%d", tag, pk.emitters, pk.beams, pk.lights, pk.parts, pk.highlights, pk.guis))
	end)
	return clock
end

-- Evenly spaced times for a dense capture.
function FxCapture.dense(t0: number, t1: number, step: number)
	local out = {}
	local t = t0
	while t <= t1 + 1e-6 do
		table.insert(out, math.floor(t * 1000 + 0.5) / 1000)
		t += step
	end
	return out
end

-- Manual stepping: begin() freezes on the first beat, step() runs on to the next one. Both wait until the clock
-- is frozen (or stopped) before returning. opt.park = true moves the local character far away and anchors it,
-- so it is not in the frame.
function FxCapture.begin(tag: string, play: () -> any, times: { number }, cameraCF: CFrame?, opt)
	opt = opt or {}
	if opt.park then
		local plr = Players.LocalPlayer
		if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			plr.Character:PivotTo(CFrame.new(0, 4, 400))
			plr.Character.HumanoidRootPart.Anchored = true
		end
	end
	if FxCapture.current and not FxCapture.current.stopped then
		FxCapture.current:stop()
	end
	FxCapture.current = FxCapture.run(tag, play, times, { hold = 1e9, scale = opt.scale or 0.25, camera = cameraCF })
	return FxCapture.step(nil)
end

function FxCapture.step(scale: number?)
	local c = FxCapture.current
	if c.scale == 0 and not c.stopped then
		c:setScale(scale or 0.25)
	end
	local s = os.clock()
	while os.clock() - s < 20 do
		task.wait()
		if c.scale == 0 or c.stopped then
			break
		end
	end
	return string.format("t=%.3f%s", c.t, if c.stopped then " (done)" else "")
end

-- Texture board: one big particle per slot candidate in a grid 30 studs in front of the camera, over a backdrop
-- (dark by default), labelled with its index. Prints "TEXBOARD|index|id|slot: note". Use it to see whether a
-- texture renders at all and whether it is on black (needs LightEmission 1) or on alpha.
function FxCapture.textureBoard(lightEmission: number?, backdrop: Color3?)
	local old = workspace:FindFirstChild("TexBoard")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "TexBoard"
	folder.Parent = workspace
	local ids, notes, seen = {}, {}, {}
	for slot, list in FxTextures.slots do
		for _, c in list do
			if c.id ~= "" and not seen[c.id] then
				seen[c.id] = true
				table.insert(ids, c.id)
				notes[c.id] = slot .. ": " .. c.note
			end
		end
	end
	table.sort(ids)
	local cam = workspace.CurrentCamera
	local base = cam.CFrame * CFrame.new(0, 0, -30)
	local cols = 6
	local rows = math.ceil(#ids / cols)
	local back = Instance.new("Part")
	back.Anchored, back.CanCollide, back.CanQuery = true, false, false
	back.Size = Vector3.new(cols * 4.5 + 1, rows * 4.5 + 1, 0.2)
	back.Color = backdrop or Color3.fromRGB(20, 20, 24)
	back.Material = Enum.Material.SmoothPlastic
	back.CFrame = base * CFrame.new(0, 2 - (rows - 1) * 4.5 / 2, -3)
	back.Parent = folder
	for i, id in ids do
		local col = (i - 1) % cols
		local row = (i - 1) // cols
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.Transparency = true, false, false, 1
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		p.CFrame = base * CFrame.new((col - (cols - 1) / 2) * 4.5, 2 - row * 4.5, 0)
		p.Parent = folder
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		e.Texture = id
		e.Lifetime = NumberRange.new(20) -- capture within 20 s
		e.Speed = NumberRange.new(0)
		e.Rotation = NumberRange.new(0)
		e.RotSpeed = NumberRange.new(0)
		e.Size = NumberSequence.new(3.6)
		e.Transparency = NumberSequence.new(0)
		e.LightEmission = lightEmission or 0
		e.LightInfluence = 0
		e.ZOffset = 1
		e.Parent = p
		e:Emit(1)
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(40, 18)
		gui.StudsOffset = Vector3.new(-1.6, 1.9, 0)
		gui.AlwaysOnTop = true
		gui.Parent = p
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundColor3 = Color3.new(0, 0, 0)
		t.TextColor3 = Color3.new(1, 1, 0)
		t.TextScaled = true
		t.Text = tostring(i)
		t.Parent = gui
		print(string.format("TEXBOARD|%d|%s|%s", i, id, notes[id]))
	end
	return ids
end

return FxCapture
