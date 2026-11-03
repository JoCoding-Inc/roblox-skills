--!strict
-- ContactBake: bake a looping push-up KeyframeSequence whose toes and palms stay on the floor.
-- Method: rotate the body about the toe line, solve each arm (shoulder + elbow) so the palm stays on a
-- fixed floor spot, keep the wrist flat, pick the elbow-back solution, sample keys on an eased curve.
-- Works on R15 rigs with Motor6D joints (not yet on AnimationConstraint joints).
-- Use in Studio (Edit or a plugin/command context). The result is a KeyframeSequence: preview it with
-- KeyframeSequenceProvider:RegisterKeyframeSequence (Studio only), then upload it for live games.
local ContactBake = {}

local TREE: { [string]: { string } } = {
	HumanoidRootPart = { "LowerTorso" },
	LowerTorso = { "UpperTorso", "LeftUpperLeg", "RightUpperLeg" },
	UpperTorso = { "Head", "LeftUpperArm", "RightUpperArm" },
	LeftUpperArm = { "LeftLowerArm" },
	LeftLowerArm = { "LeftHand" },
	RightUpperArm = { "RightLowerArm" },
	RightLowerArm = { "RightHand" },
	LeftUpperLeg = { "LeftLowerLeg" },
	LeftLowerLeg = { "LeftFoot" },
	RightUpperLeg = { "RightLowerLeg" },
	RightLowerLeg = { "RightFoot" },
}

local function motor(rig: Model, part: string, name: string): Motor6D
	return (rig:FindFirstChild(part) :: BasePart):FindFirstChild(name) :: Motor6D
end

local function rest(parent: CFrame, j: Motor6D): CFrame
	return parent * j.C0 * j.C1:Inverse()
end

-- Every joint gets a pose with Weight 1 (identity when not animated) so lower-priority tracks
-- (Animate idle or fall) cannot leak into the legs or head.
local function addPose(parent: Instance, name: string, poses: { [string]: CFrame })
	local pose = Instance.new("Pose")
	pose.Name = name
	pose.CFrame = poses[name] or CFrame.new()
	pose.Weight = if name == "HumanoidRootPart" then 0 else 1
	pose.Parent = parent
	for _, child in TREE[name] or {} do
		addPose(pose, child, poses)
	end
end

local function ease(x: number): number
	return if x < 0.5 then 4 * x * x * x else 1 - (-2 * x + 2) ^ 3 / 2
end

export type Options = {
	period: number?, -- seconds per rep (default 1.2)
	keysPerHalf: number?, -- keys from top to bottom (default 6)
	chestGap: number?, -- chest clearance at the bottom in studs (default 0.35)
	straight: number?, -- arm extension at the top, 0-1 of full reach (default 0.97)
}

-- at: position on the floor (any height) and facing; the head points along at.LookVector.
-- Returns the sequence and the CFrame to anchor HumanoidRootPart at while it plays.
function ContactBake.pushup(rig: Model, at: CFrame, floorY: number, opts: Options?): (KeyframeSequence, CFrame, number)
	local o = opts or {}
	local period = o.period or 1.2
	local N = o.keysPerHalf or 6
	local hrp = rig:FindFirstChild("HumanoidRootPart") :: BasePart
	local root, waist = motor(rig, "LowerTorso", "Root"), motor(rig, "UpperTorso", "Waist")

	-- rest geometry in HRP space, from the joints only (the current pose does not matter)
	local lt0 = rest(CFrame.new(), root)
	local ul = rest(lt0, motor(rig, "LowerTorso", "LeftHip") or motor(rig, "LeftUpperLeg", "LeftHip"))
	local ll = rest(ul, motor(rig, "LeftLowerLeg", "LeftKnee"))
	local ft = rest(ll, motor(rig, "LeftFoot", "LeftAnkle"))
	local foot = rig:FindFirstChild("LeftFoot") :: BasePart
	local toe = ft:PointToWorldSpace(Vector3.new(0, -foot.Size.Y / 2, -foot.Size.Z / 2))
	local P = Vector3.new(0, toe.Y, toe.Z)

	-- face down, head along at.LookVector, toes on the floor
	local face = CFrame.new(at.Position) * (at - at.Position) * CFrame.Angles(math.rad(-90), 0, 0)
	local H = face + Vector3.new(0, floorY - face:PointToWorldSpace(P).Y, 0)
	local headDir = at.LookVector

	local function rootT(th: number): CFrame
		local rp = CFrame.new(P) * CFrame.Angles(math.rad(th), 0, 0) * CFrame.new(-P)
		return root.C0:Inverse() * rp * root.C0
	end
	local function ut(th: number): CFrame
		return H * root.C0 * rootT(th) * root.C1:Inverse() * waist.C0 * waist.C1:Inverse()
	end

	type Side = { sh: Motor6D, el: Motor6D, wr: Motor6D, hy: number, aTop: number, flat: number, target: Vector3 }
	local sides: { [string]: Side } = {}
	for _, s in { "Left", "Right" } do
		sides[s] = {
			sh = motor(rig, s .. "UpperArm", s .. "Shoulder"),
			el = motor(rig, s .. "LowerArm", s .. "Elbow"),
			wr = motor(rig, s .. "Hand", s .. "Wrist"),
			hy = (rig:FindFirstChild(s .. "Hand") :: BasePart).Size.Y,
			aTop = 0,
			flat = 0,
			target = Vector3.zero,
		}
	end

	local thTop = 0
	local function wrist(d: Side, th: number, a: number, b: number): number
		-- keeps the hand at one world pitch: flat on the floor
		return math.rad(thTop) + d.aTop - math.rad(th) - a - b + d.flat
	end
	local function fk(d: Side, th: number, a: number, b: number, flat: boolean): (Vector3, Vector3, Vector3)
		local ua = ut(th) * d.sh.C0 * CFrame.Angles(a, 0, 0) * d.sh.C1:Inverse()
		local la = ua * d.el.C0 * CFrame.Angles(b, 0, 0) * d.el.C1:Inverse()
		local w = if flat then wrist(d, th, a, b) else 0
		local hd = la * d.wr.C0 * CFrame.Angles(w, 0, 0) * d.wr.C1:Inverse()
		return hd:PointToWorldSpace(Vector3.new(0, -d.hy / 2, 0)), (la * d.el.C1).Position, (ua * d.sh.C1).Position
	end

	-- top angle: shoulder height = straight * reach; bottom angle: chest just above the floor
	local R = sides.Right
	local palm0, _, sh0 = fk(R, 0, 0, 0, false)
	local reach = (palm0 - sh0).Magnitude
	local function shoulderH(th: number): number
		local _, _, sh = fk(R, th, 0, 0, false)
		return sh.Y - floorY
	end
	local function solveTh(h: number): number
		local lo, hi = 0, 60
		for _ = 1, 40 do
			local mid = (lo + hi) / 2
			if shoulderH(mid) < h then lo = mid else hi = mid end
		end
		return (lo + hi) / 2
	end
	local torsoHalf = (rig:FindFirstChild("UpperTorso") :: BasePart).Size.Z / 2
	thTop = solveTh(reach * (o.straight or 0.97))
	local thBot = solveTh(torsoHalf + (o.chestGap or 0.35))

	-- palm spots: straight arm reaching the floor at the top pose
	for _, d in sides do
		local best = math.huge
		for i = 0, 1800 do
			local a = math.rad(i / 10)
			local p = fk(d, thTop, a, 0, false)
			local e = math.abs(p.Y - floorY)
			if e < best then
				best, d.aTop = e, a
			end
		end
		-- wrist angle that turns the palm flat to the floor at the top pose
		local ua = ut(thTop) * d.sh.C0 * CFrame.Angles(d.aTop, 0, 0) * d.sh.C1:Inverse()
		local hd = ua * d.el.C0 * d.el.C1:Inverse() * d.wr.C0 * d.wr.C1:Inverse()
		local up = hd:VectorToObjectSpace(Vector3.yAxis)
		d.flat = math.atan2(up.Z, up.Y)
		local p = fk(d, thTop, d.aTop, 0, true)
		d.target = Vector3.new(p.X, floorY, p.Z)
	end

	-- two-bone solve with the elbow pointing back toward the feet (the pole choice)
	local function cost(d: Side, th: number, ai: number, bi: number): (number, number)
		local p, e, sh = fk(d, th, math.rad(ai), math.rad(bi), true)
		local err = (p - d.target).Magnitude
		local c = err
		if bi > 1 and (e - sh):Dot(headDir) > 0 then
			c += 10
		end
		return c, err
	end
	local function solve(d: Side, th: number): (number, number, number)
		local best, ba, bb = math.huge, 0, 0
		for ai = -150, 200, 2 do
			for bi = 0, 170, 2 do
				local c = cost(d, th, ai, bi)
				if c < best then
					best, ba, bb = c, ai, bi
				end
			end
		end
		for _, step in { 0.25, 0.05 } do
			local ca, cb = ba, bb
			for ai = ca - 8 * step, ca + 8 * step, step do
				for bi = math.max(0, cb - 8 * step), cb + 8 * step, step do
					local c = cost(d, th, ai, bi)
					if c < best then
						best, ba, bb = c, ai, bi
					end
				end
			end
		end
		local _, err = cost(d, th, ba, bb)
		return math.rad(ba), math.rad(bb), err
	end

	local seq = Instance.new("KeyframeSequence")
	seq.Name = "PushUp"
	seq.Loop = true
	seq.Priority = Enum.AnimationPriority.Action
	local maxErr = 0
	for i = 0, 2 * N do
		local x = if i <= N then i / N else (2 * N - i) / N
		local th = thTop + (thBot - thTop) * ease(x)
		local poses: { [string]: CFrame } = { LowerTorso = rootT(th) }
		for s, d in sides do
			local a, b, err = solve(d, th)
			poses[s .. "UpperArm"] = CFrame.Angles(a, 0, 0)
			poses[s .. "LowerArm"] = CFrame.Angles(b, 0, 0)
			poses[s .. "Hand"] = CFrame.Angles(wrist(d, th, a, b), 0, 0)
			maxErr = math.max(maxErr, err)
		end
		local key = Instance.new("Keyframe")
		key.Time = i * (period / 2) / N
		addPose(key, "HumanoidRootPart", poses)
		key.Parent = seq
		task.wait()
	end
	return seq, H, maxErr
end

-- Lowest corner of each contact part above floorY (negative = inside the floor).
function ContactBake.measure(rig: Model, floorY: number): { [string]: number }
	local out = {}
	for _, n in { "LeftHand", "RightHand", "LeftFoot", "RightFoot", "Head", "UpperTorso" } do
		local p = rig:FindFirstChild(n) :: BasePart
		local h = p.Size / 2
		local m = math.huge
		for _, x in { -h.X, h.X } do
			for _, y in { -h.Y, h.Y } do
				for _, z in { -h.Z, h.Z } do
					m = math.min(m, p.CFrame:PointToWorldSpace(Vector3.new(x, y, z)).Y)
				end
			end
		end
		out[n] = m - floorY
	end
	return out
end

return ContactBake
