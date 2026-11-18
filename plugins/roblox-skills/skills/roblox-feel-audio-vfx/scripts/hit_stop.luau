--!nonstrict
-- HitStop (client): freeze the attacker's and the victim's animations for a time that grows with the
-- damage, and shake the victim around its frozen pose. Presentation only: the server's hit result and
-- the world never wait for it.
--
-- Measured in Studio (2026-11-19, R15 rigs with AnimationConstraint joints, client): every playing track
-- held its TimePosition during the stop and came back at its own speed (a 1.3x track resumed at 1.3);
-- the shake showed only when written in RunService.PreSimulation, after the Animator and before the
-- solver. Written in PreAnimation, PostSimulation or PreRender it was overwritten or never drawn while a
-- track played. The damage-to-time curve and the amplitude are our starting values, not judged in the
-- hands yet: tune them in Play. Guide: roblox-feel-audio-vfx section 3b.
--
--   HitStop.play(attackerModel, victimModel, damage) -- returns the seconds it froze for

local RunService = game:GetService("RunService")

local HitStop = {}
HitStop.minSeconds = 0.04 -- light hit (fun-effects tier 1: 0.04-0.07 s)
HitStop.maxSeconds = 0.2 -- the feel guide's budget of 0.25 s of freeze per second still applies
HitStop.perDamage = 0.004 -- 10 damage -> 0.08 s, 25 -> 0.14 s, 40 or more -> 0.2 s
HitStop.amplitude = 0.08 -- studs, alternating every frame: sideways on the ground, up and down in the air

local frozen = {} -- AnimationTrack -> { speed = number, count = number }
local shaking = {} -- victim Model -> state

local function animatorOf(model)
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	return hum and hum:FindFirstChildOfClass("Animator")
end

-- Overlapping stops count per track, and the track's own speed comes back once, at the last release.
local function freeze(model)
	local tracks = {}
	local animator = animatorOf(model)
	if not animator then
		return tracks
	end
	for _, track in animator:GetPlayingAnimationTracks() do
		local f = frozen[track]
		if f then
			f.count += 1
		else
			frozen[track] = { speed = track.Speed, count = 1 }
			track:AdjustSpeed(0)
		end
		table.insert(tracks, track)
	end
	return tracks
end

local function release(tracks)
	for _, track in tracks do
		local f = frozen[track]
		if f then
			f.count -= 1
			if f.count <= 0 then
				frozen[track] = nil
				if track.IsPlaying then
					track:AdjustSpeed(f.speed)
				end
			end
		end
	end
end

local function rootJoint(model)
	local lower = model:FindFirstChild("LowerTorso")
	local joint = lower and lower:FindFirstChild("Root") -- R15: AnimationConstraint or Motor6D
	if not joint then
		local hrp = model:FindFirstChild("HumanoidRootPart")
		joint = hrp and hrp:FindFirstChild("RootJoint") -- R6 Motor6D
	end
	return joint
end

-- Ground test by ray: a rig with an anchored root (training dummies, display NPCs) reads
-- Humanoid.FloorMaterial Air while it stands on the floor, on the server and the client (measured; an
-- unanchored NPC read Plastic on both), so FloorMaterial alone would shake every dummy up and down.
local function airborne(victim)
	local hrp = victim:FindFirstChild("HumanoidRootPart")
	local hum = victim:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { victim }
	local reach = hrp.Size.Y / 2 + hum.HipHeight + 1
	return workspace:Raycast(hrp.Position, Vector3.new(0, -reach, 0), params) == nil
end

local function shake(victim, seconds)
	local s = shaking[victim]
	local untilT = os.clock() + seconds
	if s then
		s.untilT = math.max(s.untilT, untilT)
		return
	end
	local joint = rootJoint(victim)
	if not joint then
		return
	end
	local axis = if airborne(victim) then Vector3.yAxis else Vector3.xAxis
	-- Base pose: with the tracks frozen the Animator keeps writing this same pose; with no track playing
	-- nothing resets Transform, so every write is made from the base and the base goes back at the end.
	s = { joint = joint, base = joint.Transform, untilT = untilT, frame = 0 }
	shaking[victim] = s
	-- The side flips once per drawn frame. A count of PreSimulation calls does not do that: at a low frame
	-- rate several simulation steps run per drawn frame, and every drawn frame showed the same side.
	s.frameConn = RunService.PreRender:Connect(function()
		s.frame += 1
	end)
	s.conn = RunService.PreSimulation:Connect(function()
		if os.clock() >= s.untilT or not joint.Parent then
			s.conn:Disconnect()
			s.frameConn:Disconnect()
			joint.Transform = s.base
			shaking[victim] = nil
			return
		end
		local a = if s.frame % 2 == 0 then HitStop.amplitude else -HitStop.amplitude
		joint.Transform = CFrame.new(axis * a) * s.base
	end)
end

function HitStop.seconds(damage: number): number
	return math.clamp(HitStop.minSeconds + HitStop.perDamage * damage, HitStop.minSeconds, HitStop.maxSeconds)
end

function HitStop.play(attacker: Model?, victim: Model, damage: number): number
	local seconds = HitStop.seconds(damage)
	local tracks = freeze(attacker)
	for _, t in freeze(victim) do
		table.insert(tracks, t)
	end
	shake(victim, seconds)
	task.delay(seconds, release, tracks)
	return seconds
end

return HitStop
