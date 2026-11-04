-- Lay out the same kinds of props (trees, rocks, plants, walls) from each inserted Creator Store
-- pack, one block per pack side by side, left to right in PACKS order, each starting with a red 2x5x1 player-size
-- block, and report each pack's weight. Run it in the game's own dev place so every pack is judged under its lighting.
-- 1. Insert each pack with Studio MCP insert_asset under ServerStorage (name them in PACKS).
-- 2. Run this with execute_luau (Edit). It returns stats plus camera and look-at positions.
-- 3. screen_capture once with the overall positions (all packs side by side), then once per pack.
-- Delete workspace.PackLineup and the packs afterwards.
local PACKS = { "PackA", "PackB" } -- children of ServerStorage, one per pack
local PER_CLASS = 2 -- props shown per class per pack
local MAX_SIZE = 150 -- skip props larger than this many studs (terrain chunks, whole maps)
local CLASSES = { -- matched against the lowercased full path, in this order
	{ "tree", { "tree", "pine", "palm", "oak", "willow", "birch", "spruce", "maple", "sakura", "blossom" } },
	{ "rock", { "rock", "stone", "boulder", "cliff" } },
	{ "plant", { "bush", "shrub", "fern", "grass", "flower", "plant" } },
	{ "wall", { "wall", "fence", "hedge", "pillar", "arch", "gate" } },
}
local SKIP = { "texture", "material", "organization", "thumbnail", "decal", "swatch", "preview" }

local function isContainer(inst)
	if inst:IsA("Folder") then
		return true
	end
	if not inst:IsA("Model") then
		return false
	end
	local groups, parts = 0, 0
	for _, c in inst:GetChildren() do
		if c:IsA("BasePart") then
			parts += 1
		elseif c:IsA("Model") or c:IsA("Folder") then
			groups += 1
		end
	end
	-- a model of sub-models, or a pack laid out as many loose parts (one mesh per prop)
	return (groups > 0 and parts == 0) or groups + parts > 20
end

local function collect(node, out)
	for _, c in node:GetChildren() do
		if isContainer(c) then
			collect(c, out)
		elseif c:IsA("Model") or c:IsA("BasePart") then
			table.insert(out, c)
		end
	end
end

local function has(s, words)
	for _, w in words do
		if string.find(s, w, 1, true) then
			return true
		end
	end
	return false
end

local function bounds(inst)
	if inst:IsA("BasePart") then
		return inst.CFrame, inst.Size
	end
	return inst:GetBoundingBox()
end

local function stats(root)
	local s = { parts = 0, meshParts = 0, scripts = 0, unanchored = 0, meshes = {} }
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			s.parts += 1
			if not d.Anchored then
				s.unanchored += 1
			end
		end
		if d:IsA("MeshPart") then
			s.meshParts += 1
			s.meshes[d.MeshId] = true
		elseif d:IsA("SpecialMesh") then
			s.meshes[d.MeshId] = true
		end
		if d:IsA("LuaSourceContainer") then
			s.scripts += 1
		end
	end
	local n = 0
	for _ in s.meshes do
		n += 1
	end
	s.uniqueMeshes = n
	return s
end

local old = workspace:FindFirstChild("PackLineup")
if old then
	old:Destroy()
end
local lineup = Instance.new("Model")
lineup.Name = "PackLineup"

local report, rows = {}, {}
local x0, top = 0, 5
for _, packName in PACKS do
	local root = game.ServerStorage:FindFirstChild(packName)
	if not root then
		table.insert(report, packName .. ": not found in ServerStorage")
		continue
	end
	local list = {}
	if isContainer(root) then
		collect(root, list)
	else
		list = { root }
	end
	local row = Instance.new("Model")
	row.Name = packName
	row.Parent = lineup
	local marker = Instance.new("Part")
	marker.Name = "PlayerSize"
	marker.Size = Vector3.new(2, 5, 1)
	marker.Color = Color3.fromRGB(220, 40, 40)
	marker.Anchored = true
	marker.Position = Vector3.new(x0 + 1, 2.5, 0)
	marker.Parent = row

	local x, height, counts = x0 + 6, 5, {}
	for _, class in CLASSES do
		local matches = {}
		for _, item in list do
			-- path inside the pack (the item's own name for a single-model pack)
			local path = item == root and string.lower(root.Name)
				or string.lower(string.sub(item:GetFullName(), #root:GetFullName() + 2))
			if has(path, class[2]) and not has(path, SKIP) then
				local _, size = bounds(item)
				if math.max(size.X, size.Y, size.Z) <= MAX_SIZE and math.min(size.X, size.Y, size.Z) > 0.3 then
					table.insert(matches, { item = item, v = size.X * size.Y * size.Z })
				end
			end
		end
		table.sort(matches, function(a, b)
			return a.v > b.v
		end)
		-- the largest prop and one from the middle of the size range
		local picks = { matches[1], matches[math.max(2, math.floor(#matches / 2))] }
		local shown = 0
		for _, pick in picks do
			if not pick or shown >= PER_CLASS then
				continue
			end
			local m = pick.item:Clone()
			if m:IsA("BasePart") then
				local wrap = Instance.new("Model")
				m.Parent = wrap
				m = wrap
			end
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
				elseif d:IsA("LuaSourceContainer") then
					d:Destroy()
				end
			end
			local cf, size = m:GetBoundingBox()
			m:PivotTo(m:GetPivot() + (Vector3.new(x + size.X / 2, size.Y / 2, 0) - cf.Position))
			m.Parent = row
			x += size.X + 4
			height = math.max(height, size.Y)
			shown += 1
		end
		table.insert(counts, class[1] .. " " .. #matches)
	end
	if x == x0 + 6 then
		-- no class matched (names in another language, or a single odd prop): show the first items
		for i = 1, math.min(3, #list) do
			local m = list[i]:Clone()
			if m:IsA("BasePart") then
				local wrap = Instance.new("Model")
				m.Parent = wrap
				m = wrap
			end
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
				elseif d:IsA("LuaSourceContainer") then
					d:Destroy()
				end
			end
			local cf, size = m:GetBoundingBox()
			m:PivotTo(m:GetPivot() + (Vector3.new(x + size.X / 2, size.Y / 2, 0) - cf.Position))
			m.Parent = row
			x += size.X + 4
			height = math.max(height, size.Y)
		end
		table.insert(counts, "no class match, first items shown")
	end
	local s = stats(root)
	local w = x - x0
	local center = Vector3.new(x0 + w / 2, height / 2, 0)
	local dist = math.max(w, height * 1.6) * 0.6 + 10
	table.insert(rows, {
		name = packName,
		camera = { center.X, center.Y + dist * 0.35, center.Z + dist },
		lookAt = { center.X, center.Y, center.Z },
	})
	table.insert(report, string.format(
		"%s: %s | parts %d meshParts %d uniqueMeshes %d scripts %d unanchored %d | row %dx%d studs",
		packName, table.concat(counts, ", "), s.parts, s.meshParts, s.uniqueMeshes, s.scripts, s.unanchored, w, height))
	top = math.max(top, height)
	x0 = x + 30
end

local ground = Instance.new("Part")
ground.Name = "Ground"
ground.Anchored = true
ground.Size = Vector3.new(x0 + 30, 1, 120)
ground.Position = Vector3.new(x0 / 2 - 15, -0.5, 0)
ground.Color = Color3.fromRGB(120, 130, 110)
ground.Parent = lineup
lineup.Parent = workspace

local mid = Vector3.new((x0 - 30) / 2, top / 2, 0)
local span = math.max(x0 - 30, top * 1.6)
local out = { table.concat(report, "\n") }
for _, r in rows do
	table.insert(out, string.format("camera %s: {%.0f, %.0f, %.0f} look {%.0f, %.0f, %.0f}", r.name,
		r.camera[1], r.camera[2], r.camera[3], r.lookAt[1], r.lookAt[2], r.lookAt[3]))
end
table.insert(out, string.format("camera overall: {%.0f, %.0f, %.0f} look {%.0f, %.0f, %.0f}",
	mid.X, mid.Y + span * 0.15, span * 0.55 + 10, mid.X, mid.Y, 0))
return table.concat(out, "\n")
