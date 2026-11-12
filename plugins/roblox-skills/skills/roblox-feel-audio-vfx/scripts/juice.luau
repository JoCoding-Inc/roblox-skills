--!strict
-- juice.luau: client-side feedback behind one settings table (roblox-feel-audio-vfx section 3b).
-- ModuleScript, required from LocalScripts only. Every effect is local to this player.
--
--   local Juice = require(ReplicatedStorage:WaitForChild("Juice"))
--   Juice.impact("heavy")                      -- shake + FOV punch + flash + vibration by tier
--   Juice.shake(0.5)  Juice.kick(2)            -- camera shake (trauma 0..1), one-sided roll kick
--   Juice.fovPunch(4)  Juice.fovBias(12)       -- short punch; held offset for a state (0 releases)
--   Juice.hitStop(0.08, { swingTrack }, onResume)
--   Juice.flash(color, 0.3)  Juice.edge(color, 0.6)  Juice.grade(-0.5, tint)  Juice.bloom(1)  Juice.blur(10)
--   Juice.haptic("hit")                        -- "tap" | "notify" | "hit" | "big" | a hapticWave name
--   Juice.pop(button)  Juice.countUp(label, 120, 480)  Juice.flyTo({ ... })
--
-- Juice.settings turns channels off; Juice.motionOn() also honours the Roblox Reduce Motion setting.
-- Numbers are starting points (judgment, tuned by eye in Studio on 2026-11-12, not on a phone).

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Juice = {}

Juice.settings = {
	shake = 1, -- 0..1.5 multiplier, 0 turns camera shake off
	flash = 1, -- 0..1 multiplier on flash and edge opacity
	fov = true,
	hitStop = true,
	haptics = true,
	reducedMotion = false, -- the game's own switch; the Roblox Reduce Motion setting also counts
}

-- Camera shake (trauma model: shake = trauma^2, linear decay, smooth noise, rotation only in 3D)
local SHAKE_DECAY = 1.5 -- trauma lost per second
local SHAKE_FREQ = 16 -- noise speed
local MAX_PITCH = math.rad(3)
local MAX_YAW = math.rad(3)
local MAX_ROLL = math.rad(3)
-- FOV punch
local FOV_MAX = 10 -- degrees, total offset clamp
local FOV_ATTACK = 0.05
-- Hit stop: at most this many seconds of freeze inside any second
local STOP_BUDGET = 0.25
-- Full-screen brightness changes: stay under three per second (WCAG 2.3.1)
local FLASH_MAX = 0.5 -- highest opacity of a full-screen flash
local FLASH_PER_SECOND = 2

local TIERS = {
	light = { trauma = 0.3, fov = 0, flash = 0, haptic = "tap" },
	medium = { trauma = 0.45, fov = 2, flash = 0, haptic = "hit" },
	heavy = { trauma = 0.6, fov = 4, flash = 0.16, haptic = "hit" },
	huge = { trauma = 0.9, fov = 7, flash = 0.35, haptic = "big" },
}
Juice.tiers = TIERS

local HAPTIC_TYPES = {
	tap = Enum.HapticEffectType.UIClick,
	notify = Enum.HapticEffectType.UINotification,
	hit = Enum.HapticEffectType.GameplayCollision,
	big = Enum.HapticEffectType.GameplayExplosion,
}

local player = Players.LocalPlayer

function Juice.motionOn(): boolean
	return not (Juice.settings.reducedMotion or GuiService.ReducedMotionEnabled)
end

-- ---------------------------------------------------------------- camera

local trauma = 0
type Punch = { t0: number, deg: number, release: number }
local punches: { Punch } = {}
local baseFov: number? = nil
local bias, biasTarget = 0, 0 -- held FOV offset (dash, boost, aim)
local roll = 0 -- camera roll kick in degrees

-- Shakes combine by max, never by sum, so many small hits cannot pile up into a big one.
function Juice.shake(amount: number)
	trauma = math.clamp(amount, trauma, 1)
end

-- deg > 0 widens (impact, kill), deg < 0 narrows (wind-up). The base is read only
-- when no punch is running, so a punch can never become the new base.
function Juice.fovPunch(deg: number, release: number?)
	if not Juice.settings.fov or not Juice.motionOn() then
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	if not baseFov then
		baseFov = cam.FieldOfView
	end
	table.insert(punches, { t0 = os.clock(), deg = deg, release = release or 0.35 })
end

-- Held offset for a state (dash +10, aim -15); eases in and out. 0 releases it.
function Juice.fovBias(deg: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	if not Juice.settings.fov or not Juice.motionOn() then
		deg = 0
	end
	if not baseFov and deg ~= 0 then
		baseFov = cam.FieldOfView
	end
	biasTarget = deg
end

-- One-sided camera roll that springs back: sells the direction of a heavy hit.
function Juice.kick(degrees: number)
	roll += degrees
end

-- Other camera code changes the resting FOV through this while punches may be running.
function Juice.setBaseFov(fov: number)
	if baseFov then
		baseFov = fov
	elseif workspace.CurrentCamera then
		workspace.CurrentCamera.FieldOfView = fov
	end
end

local function noise(t: number, seed: number): number
	return math.clamp(math.noise(t, seed) * 2, -1, 1)
end

RunService:BindToRenderStep("JuiceCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	if trauma > 0 or math.abs(roll) > 0.01 then
		local s = trauma * trauma * Juice.settings.shake
		if Juice.settings.shake > 0 and Juice.motionOn() then
			local t = os.clock() * SHAKE_FREQ
			cam.CFrame *= CFrame.Angles(
				MAX_PITCH * s * noise(t, 11.3),
				MAX_YAW * s * noise(t, 47.9),
				MAX_ROLL * s * noise(t, 83.1) + math.rad(roll) * Juice.settings.shake
			)
		end
		trauma = math.max(0, trauma - SHAKE_DECAY * dt)
		roll *= math.exp(-10 * dt)
	end
	bias += (biasTarget - bias) * math.min(1, 9 * dt)
	if baseFov then
		local now = os.clock()
		local offset = 0
		for i = #punches, 1, -1 do
			local p = punches[i]
			local e = now - p.t0
			if e < FOV_ATTACK then
				offset += p.deg * (e / FOV_ATTACK)
			elseif e < FOV_ATTACK + p.release then
				local r = 1 - (e - FOV_ATTACK) / p.release
				offset += p.deg * r * r
			else
				table.remove(punches, i)
			end
		end
		cam.FieldOfView = baseFov + math.clamp(offset, -FOV_MAX, FOV_MAX) + bias
		if #punches == 0 and biasTarget == 0 and math.abs(bias) < 0.05 then
			cam.FieldOfView = baseFov
			bias = 0
			baseFov = nil
		end
	end
end)

-- ---------------------------------------------------------------- hit stop

-- Roblox has no time scale. A hit stop freezes the animation tracks you pass and
-- delays the reaction (knockback, death, numbers) until `resume` runs.
local frozen: { [AnimationTrack]: { speed: number, holds: number } } = {}
local stopUsed = 0
local stopClock = os.clock()

function Juice.hitStop(seconds: number, tracks: { AnimationTrack }?, resume: (() -> ())?)
	local now = os.clock()
	stopUsed = math.max(0, stopUsed - (now - stopClock) * STOP_BUDGET)
	stopClock = now
	local t = if Juice.settings.hitStop then math.min(seconds, STOP_BUDGET - stopUsed) else 0
	if t < 0.02 then
		if resume then
			resume()
		end
		return
	end
	stopUsed += t
	for _, track in tracks or {} do
		local f = frozen[track]
		if f then
			f.holds += 1
		else
			frozen[track] = { speed = track.Speed, holds = 1 }
			track:AdjustSpeed(0)
		end
	end
	task.delay(t, function()
		for _, track in tracks or {} do
			local f = frozen[track]
			if f then
				f.holds -= 1
				if f.holds <= 0 then
					frozen[track] = nil
					track:AdjustSpeed(f.speed)
				end
			end
		end
		if resume then
			resume()
		end
	end)
end

-- ---------------------------------------------------------------- screen flash and edge tint

local fxGui: ScreenGui? = nil
local flashFrame: Frame
local edges: { Frame } = {}
local brightStarts: { number } = {}

local function gui(): ScreenGui
	if fxGui then
		return fxGui
	end
	local g = Instance.new("ScreenGui")
	g.Name = "JuiceFx"
	g.ResetOnSpawn = false
	g.ScreenInsets = Enum.ScreenInsets.None -- cover the notch and the top bar too
	g.DisplayOrder = 90
	flashFrame = Instance.new("Frame")
	flashFrame.Name = "Flash"
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.Parent = g
	-- four gradient strips make the edge tint without an image
	local specs = {
		{ UDim2.fromScale(1, 0.24), UDim2.fromScale(0, 0), 90 },
		{ UDim2.fromScale(1, 0.24), UDim2.fromScale(0, 0.76), 270 },
		{ UDim2.fromScale(0.16, 1), UDim2.fromScale(0, 0), 0 },
		{ UDim2.fromScale(0.16, 1), UDim2.fromScale(0.84, 0), 180 },
	}
	for _, s in specs do
		local f = Instance.new("Frame")
		f.Name = "Edge"
		f.Size = s[1] :: UDim2
		f.Position = s[2] :: UDim2
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		local grad = Instance.new("UIGradient")
		grad.Rotation = s[3] :: number
		grad.Transparency = NumberSequence.new(0, 1)
		grad.Parent = f
		f.Parent = g
		table.insert(edges, f)
	end
	g.Parent = player:WaitForChild("PlayerGui")
	fxGui = g
	return g
end

local function brightAllowed(): boolean
	local now = os.clock()
	for i = #brightStarts, 1, -1 do
		if now - brightStarts[i] > 1 then
			table.remove(brightStarts, i)
		end
	end
	if #brightStarts >= FLASH_PER_SECOND then
		return false
	end
	table.insert(brightStarts, now)
	return true
end

-- One full-screen flash. Returns false when it was dropped by the rate limit or the setting.
function Juice.flash(color: Color3, alpha: number, seconds: number?): boolean
	local a = math.min(alpha, FLASH_MAX) * Juice.settings.flash
	if a < 0.02 or not brightAllowed() then
		return false
	end
	gui()
	flashFrame.BackgroundColor3 = color
	flashFrame.BackgroundTransparency = 1 - a
	TweenService:Create(flashFrame, TweenInfo.new(seconds or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	return true
end

-- Edge tint (damage, low health, fail, rarity colour) that leaves the centre clear.
function Juice.edge(color: Color3, alpha: number, seconds: number?): boolean
	local a = math.min(alpha, 0.8) * Juice.settings.flash
	if a < 0.02 or not brightAllowed() then
		return false
	end
	gui()
	for _, f in edges do
		f.BackgroundColor3 = color
		f.BackgroundTransparency = 1 - a
		TweenService:Create(f, TweenInfo.new(seconds or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
	end
	return true
end

-- Short colour grade on the camera: saturation -1..1 and a tint, easing back to neutral.
local gradeFx: ColorCorrectionEffect? = nil

function Juice.grade(saturation: number, tint: Color3?, seconds: number?)
	local cam = workspace.CurrentCamera
	if not cam or Juice.settings.flash <= 0 then
		return
	end
	local fx = gradeFx
	if not fx or fx.Parent ~= cam then
		fx = Instance.new("ColorCorrectionEffect")
		fx.Name = "JuiceGrade"
		fx.Parent = cam
		gradeFx = fx
	end
	local f = fx :: ColorCorrectionEffect
	f.Saturation = saturation * Juice.settings.flash
	f.TintColor = tint or Color3.new(1, 1, 1)
	TweenService:Create(f, TweenInfo.new(seconds or 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Saturation = 0,
		TintColor = Color3.new(1, 1, 1),
	}):Play()
end

local function cameraEffect(class: string, name: string): any
	local cam = workspace.CurrentCamera
	local fx = cam and cam:FindFirstChild(name)
	if cam and not fx then
		fx = Instance.new(class)
		fx.Name = name
		fx.Parent = cam
	end
	return fx
end

-- Bloom pulse: bright things glow for a moment on a big hit or reveal.
function Juice.bloom(intensity: number, seconds: number?)
	local fx = cameraEffect("BloomEffect", "JuiceBloom") :: BloomEffect?
	if not fx or Juice.settings.flash <= 0 then
		return
	end
	fx.Threshold, fx.Size = 0.9, 36
	fx.Intensity = intensity * Juice.settings.flash
	TweenService:Create(fx, TweenInfo.new(seconds or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Intensity = 0 }):Play()
end

-- Blur pulse: a hard hit, a stun, the hold before a big reveal.
function Juice.blur(size: number, seconds: number?)
	local fx = cameraEffect("BlurEffect", "JuiceBlur") :: BlurEffect?
	if not fx or not Juice.motionOn() then
		return
	end
	fx.Size = size
	TweenService:Create(fx, TweenInfo.new(seconds or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 0 }):Play()
end

-- ---------------------------------------------------------------- vibration

local haptics: { [string]: HapticEffect } = {}

local function hapticFor(kind: string): HapticEffect
	local h = haptics[kind]
	if not h then
		h = Instance.new("HapticEffect")
		h.Name = "Juice_" .. kind
		h.Type = HAPTIC_TYPES[kind] or Enum.HapticEffectType.Custom
		h.Parent = workspace
		haptics[kind] = h
	end
	return h
end

-- kind: "tap" | "notify" | "hit" | "big", or a name registered with hapticWave.
function Juice.haptic(kind: string)
	if Juice.settings.haptics then
		hapticFor(kind):Play()
	end
end

-- Custom waveform: keys are { timeMs, strength 0..1 } pairs, for example a rising roll.
function Juice.hapticWave(name: string, keys: { { number } })
	local h = hapticFor(name)
	local curve = {}
	for _, k in keys do
		table.insert(curve, FloatCurveKey.new(k[1], k[2], Enum.KeyInterpolationMode.Linear))
	end
	h.Type = Enum.HapticEffectType.Custom
	h:SetWaveformKeys(curve)
end

-- ---------------------------------------------------------------- tiers

-- One call per event: the tier sets how many channels fire and how hard.
function Juice.impact(tier: string, flashColor: Color3?)
	local t = TIERS[tier]
	Juice.shake(t.trauma)
	if t.fov ~= 0 then
		Juice.fovPunch(t.fov)
	end
	if t.flash > 0 then
		Juice.flash(flashColor or Color3.new(1, 1, 1), t.flash, 0.25)
	end
	Juice.haptic(t.haptic)
end

-- ---------------------------------------------------------------- UI feedback

-- Scale punch. Uses its own UIScale so it never fights layout or another tween.
function Juice.pop(target: GuiObject, peak: number?, seconds: number?)
	if not Juice.motionOn() then
		return
	end
	local scale = target:FindFirstChild("JuicePop") :: UIScale?
	if not scale then
		local s = Instance.new("UIScale")
		s.Name = "JuicePop"
		s.Parent = target
		scale = s
	end
	local s = scale :: UIScale
	s.Scale = peak or 1.25
	TweenService:Create(s, TweenInfo.new(seconds or 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
end

local counts: { [TextLabel]: number } = {}

-- Rolls a number label from `from` to `to`. A newer call on the same label wins.
function Juice.countUp(label: TextLabel, from: number, to: number, seconds: number?, format: ((number) -> string)?)
	local fmt = format or function(n: number): string
		return tostring(n)
	end
	local token = (counts[label] or 0) + 1
	counts[label] = token
	local dur = seconds or 0.45
	local t0 = os.clock()
	task.spawn(function()
		while counts[label] == token do
			local k = math.min(1, (os.clock() - t0) / dur)
			local eased = 1 - (1 - k) * (1 - k)
			label.Text = fmt(math.floor(from + (to - from) * eased + 0.5))
			if k >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
	end)
end

export type FlyOptions = {
	from: Vector2, -- start, in the same px space as AbsolutePosition
	target: GuiObject, -- the counter icon the pieces land on
	count: number,
	make: () -> GuiObject, -- returns one piece (AnchorPoint 0.5, 0.5), not parented
	parent: GuiBase2d, -- a ScreenGui above the HUD
	onArrive: ((index: number) -> ())?, -- per piece: add to the counter, play the tick
	scatter: number?, -- px
}

-- Pieces burst out, hang, then fly into the counter one after another.
function Juice.flyTo(o: FlyOptions)
	if not Juice.motionOn() then
		for i = 1, o.count do
			if o.onArrive then
				o.onArrive(i)
			end
		end
		return
	end
	local scatter = o.scatter or 46
	for i = 1, o.count do
		local piece = o.make()
		piece.Position = UDim2.fromOffset(o.from.X, o.from.Y)
		piece.Parent = o.parent
		local angle = math.random() * math.pi * 2
		local reach = scatter * (0.5 + math.random() * 0.5)
		local mid = o.from + Vector2.new(math.cos(angle), math.sin(angle)) * reach
		local out = TweenService:Create(piece, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(mid.X, mid.Y),
		})
		out:Play()
		task.delay(0.2 + (i - 1) * 0.04, function()
			local goal = o.target.AbsolutePosition + o.target.AbsoluteSize / 2
			local fly = TweenService:Create(piece, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(goal.X, goal.Y),
			})
			fly.Completed:Once(function()
				piece:Destroy()
				if o.onArrive then
					o.onArrive(i)
				end
			end)
			fly:Play()
		end)
	end
end

return Juice
