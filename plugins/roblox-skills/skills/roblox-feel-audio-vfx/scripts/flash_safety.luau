--!nonstrict
-- flash_safety: reduced motion and the screen-flash cap shared by every screen-wide layer of the cutscene
-- elements (roblox-feel-audio-vfx section 3e). Client only. Ran in Studio 0.747 and 0.748 Play, 2026-11-18.
--
-- Reduced motion: Safety.reduced() is GuiService.ReducedMotionEnabled (the player's Reduce Motion setting,
-- read-only) unless Safety.override is set (true or false; a test switch). With it on: no camera shake, the
-- impact block, dark beat and white-out become one soft dim, lettering does not jitter, speed lines are drawn
-- once and not re-shaped.
--
-- Flash cap (WCAG 2.1 SC 2.3.1, "no more than three flashes in any one-second period"): every screen-wide state
-- change goes through Safety.request(root, t, L, label) with the mean screen value it will show (L 0..1,
-- estimated per state: white 1, black 0.03, the grey stage 0.5). A change of at least THRESH (0.2) from the last
-- accepted value counts as a transition; a flash is a pair of opposing transitions (up then down or down then
-- up), counted at the second one. A state that would make a 4th flash inside any 1.0 s of clock time is refused:
-- the caller keeps the previous state instead; a block or white-out first tests its whole sequence
-- (Safety.fits, return to the scene included) and drops states from its end until it fits. Time is the root
-- clock's time, so a slowed capture counts the same as a 1x play. Every accepted transition prints
-- "FLASH|t|L|dir|flashesInLastSecond|label" and every refused one "FLASHCUT|t|label"; Safety.report(root) gives
-- the whole log and the largest count in any second.
-- Local flashes (a glow on one part, lettering, ink shapes under about 35 % of the frame) are not counted. Hard
-- cuts between a dark and a bright shot are not counted either: keep the shots of one stretch at one level.
-- Limits: the L values are estimates per state, not measured screen luminance; the 0.2 step is coarser than the
-- WCAG 10 % change, so a dim pulse below it is not counted.

local GuiService = game:GetService("GuiService")

local Safety = {}

Safety.override = nil :: boolean?
Safety.MAX_PER_SECOND = 3
Safety.THRESH = 0.2
Safety.SCENE_L = 0.5

function Safety.reduced(): boolean
	if Safety.override ~= nil then
		return Safety.override
	end
	local ok, v = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	return ok and v == true
end

local function state(root)
	if not root.flashState then
		root.flashState = { anchor = Safety.SCENE_L, dir = 0, flashes = {}, log = {} }
	end
	return root.flashState
end

local function countIn(st, t: number): number
	local n = 0
	for _, ft in st.flashes do
		if ft > t - 1.0 + 1e-6 and ft <= t + 1e-6 then
			n += 1
		end
	end
	return n
end

-- Decide one screen value change at clock time t. Returns true if it may be shown. dry = true tests on a copy.
function Safety.request(root, t: number, L: number, label: string?, st0): boolean
	local st = st0 or state(root)
	local d = L - st.anchor
	if math.abs(d) < Safety.THRESH then
		return true
	end
	local dir = if d > 0 then 1 else -1
	local completes = st.dir ~= 0 and dir ~= st.dir
	if completes then
		if countIn(st, t) + 1 > Safety.MAX_PER_SECOND then
			if not st0 then
				print(string.format("FLASHCUT|%.3f|%s", t, label or "?"))
				table.insert(st.log, { t = t, L = L, cut = true, label = label })
			end
			return false
		end
		table.insert(st.flashes, t)
	end
	st.anchor = L
	st.dir = dir
	if not st0 then
		table.insert(st.log, { t = t, L = L, dir = dir, label = label })
		print(string.format("FLASH|%.3f|%.2f|%d|%d|%s", t, L, dir, countIn(st, t), label or "?"))
	end
	return true
end

-- Would the whole sequence (items = { { t, L } } in time order) pass without a refusal? Tests on a copy.
function Safety.fits(root, items): boolean
	local st = state(root)
	local copy = { anchor = st.anchor, dir = st.dir, flashes = table.clone(st.flashes), log = {} }
	for _, it in items do
		if not Safety.request(root, it.t, it.L, it.label, copy) then
			return false
		end
	end
	return true
end

-- The largest number of flashes inside any 1.0 s window so far on this root clock.
function Safety.maxPerSecond(root): number
	local st = state(root)
	local best = 0
	for _, ft in st.flashes do
		best = math.max(best, countIn(st, ft))
	end
	return best
end

function Safety.report(root): string
	local st = state(root)
	local lines = {}
	for _, e in st.log do
		table.insert(lines, string.format("%.3f %s L=%.2f %s", e.t, e.cut and "CUT" or (e.dir > 0 and "up" or "down"), e.L, e.label or ""))
	end
	return string.format("flashes=%d maxPerSecond=%d\n%s", #st.flashes, Safety.maxPerSecond(root), table.concat(lines, "\n"))
end

return Safety
