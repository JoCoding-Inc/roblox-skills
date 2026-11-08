--!strict
-- hud_shapes.luau: image-free sci-fi HUD shapes. Put it in a ModuleScript and require it from client UI code.
--   chamfer(frame, cut, corners, color, transparency, edgeColor?, edgeWidth?) -> fill Frame
--       cut corners on an existing Frame of any size: one rotated Frame clipped by an axis-aligned one,
--       plus a closed Path2D outline. corners: "all", "tlbr" (top-left, bottom-right) or "trbl".
--   stripes(frame, c1, c2, period, angle)   hazard or diagonal stripes from one UIGradient (Repeat tile)
--   segments(bar, n, filled, gap)           a wave or health bar cut into n segments with transparent gaps
--   brackets(frame, len, thickness, color)  four L-shaped corner brackets
-- Needs rotated children clipped by ClipsDescendants (default since 2026-09-24, permanent in Studio 0.746)
-- and UIGradient Scale and TileMode (full release 2026-10-29). Tested in Studio 0.746 on 2026-11-08,
-- also under a UIScale and on a Scale-sized frame.

local M = {}

local function uiScale(g: Instance): number
	local k = 1
	local p: Instance? = g
	while p do
		local s = p:FindFirstChildOfClass("UIScale")
		if s then k *= s.Scale end
		p = p.Parent
	end
	return k
end

function M.chamfer(root: Frame, cut: number, corners: string, color: Color3, transparency: number, edgeColor: Color3?, edgeWidth: number?): Frame
	root.BackgroundTransparency = 1
	local clip = Instance.new("Frame")
	clip.Name = "ChamferClip"
	clip.Size = UDim2.fromScale(1, 1)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.ZIndex = 0
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0.5, 0.5)
	fill.Position = UDim2.fromScale(0.5, 0.5)
	fill.BackgroundColor3 = color
	fill.BackgroundTransparency = transparency
	fill.BorderSizePixel = 0
	fill.Rotation = if corners == "trbl" then -45 else 45
	fill.Parent = clip
	clip.Parent = root

	local function layout()
		local w, h = root.AbsoluteSize.X, root.AbsoluteSize.Y
		if w < 1 or h < 1 then return end
		local c = cut * uiScale(root) -- cut is in design px, AbsoluteSize already includes UIScale
		local cutting = ((w + h) / 2 - c) / math.sqrt(2) -- half extent whose edge cuts two corners by c
		local open = (w + h) / math.sqrt(2) + 2 -- half extent that cuts nothing
		local ax = if corners == "all" or corners == "tlbr" or corners == "trbl" then cutting else open
		local by = if corners == "all" then cutting else open
		fill.Size = UDim2.fromScale(2 * ax / w, 2 * by / h) -- scale of the clip, so UIScale is not applied twice
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()

	if edgeColor then
		local tl = corners == "all" or corners == "tlbr"
		local tr = corners == "all" or corners == "trbl"
		local pts = {}
		local function p(sx: number, ox: number, sy: number, oy: number)
			table.insert(pts, Path2DControlPoint.new(UDim2.new(sx, ox, sy, oy)))
		end
		if tl then p(0, 0, 0, cut); p(0, cut, 0, 0) else p(0, 0, 0, 0) end
		if tr then p(1, -cut, 0, 0); p(1, 0, 0, cut) else p(1, 0, 0, 0) end
		if tl then p(1, 0, 1, -cut); p(1, -cut, 1, 0) else p(1, 0, 1, 0) end
		if tr then p(0, cut, 1, 0); p(0, 0, 1, -cut) else p(0, 0, 1, 0) end
		local edge = Instance.new("Path2D")
		edge.Name = "Edge"
		edge.Closed = true
		edge.Color3 = edgeColor
		edge.Thickness = edgeWidth or 2
		edge.ZIndex = 0
		edge:SetControlPoints(pts)
		edge.Parent = root
	end
	return fill
end

function M.stripes(frame: GuiObject, c1: Color3, c2: Color3, period: number, angle: number): UIGradient
	frame.BackgroundColor3 = Color3.new(1, 1, 1) -- a UIGradient multiplies the frame color
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(0.5, c1),
		ColorSequenceKeypoint.new(0.5, c2), ColorSequenceKeypoint.new(1, c2),
	})
	g.Scale = period -- share of the frame one stripe pair covers, for example 0.12
	g.TileMode = Enum.GradientTileMode.Repeat
	g.Rotation = angle
	g.Parent = frame
	return g
end

function M.segments(bar: GuiObject, n: number, filled: number, gap: number)
	-- bar: a Frame inside a track Frame. Sets its width to filled / n of the track and cuts it into
	-- segments with a transparent gap (share of a segment, for example 0.14). Call again when filled changes.
	bar.Visible = filled > 0
	if filled <= 0 then return end
	bar.Size = UDim2.new(filled / n, 0, bar.Size.Y.Scale, bar.Size.Y.Offset)
	local g = bar:FindFirstChild("Segments") :: UIGradient?
	if not g then
		local ng = Instance.new("UIGradient")
		ng.Name = "Segments"
		ng.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1 - gap, 0),
			NumberSequenceKeypoint.new(1 - gap, 1), NumberSequenceKeypoint.new(1, 1),
		})
		ng.TileMode = Enum.GradientTileMode.Repeat
		ng.Parent = bar
		g = ng
	end
	local seg = g :: UIGradient
	seg.Scale = 1 / filled -- one tile per segment
end

function M.brackets(frame: GuiObject, len: number, thickness: number, color: Color3)
	for _, c in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		for _, size in { UDim2.fromOffset(len, thickness), UDim2.fromOffset(thickness, len) } do
			local f = Instance.new("Frame")
			f.AnchorPoint = c
			f.Position = UDim2.fromScale(c.X, c.Y)
			f.Size = size
			f.BackgroundColor3 = color
			f.BorderSizePixel = 0
			f.Parent = frame
		end
	end
end

return M
