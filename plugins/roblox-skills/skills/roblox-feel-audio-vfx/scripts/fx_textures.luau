--!nonstrict
-- fx_textures: texture slots with ranked candidates, used by fire_slash, hit_impact and level_up_aura
-- (roblox-feel-audio-vfx section 3d). No uploads: public ids from the Roblox docs VFX tutorials, plus one free
-- explosion flipbook shared on the DevForum (https://devforum.roblox.com/t/2-free-realistic-flipbook-particle-explosions/3035597);
-- Studio built-ins last. Every public id below rendered in Studio 0.747 Play on 2026-11-17; none was checked in a
-- published game. A game moves to its own textures before release: put them first in each slot (or in force).
-- Built-ins (rbxasset://) are prototype only (section 3 house rule); set allowBuiltins = false to keep them out.
-- resolve() preloads every candidate and records the status per id; PreloadAsync reported Failure for ids that
-- did render (measured), so the status is recorded only and a slot is never skipped on it. fx_capture.textureBoard
-- shows whether each id actually renders.
--
-- local FxTextures = require(folder.fx_textures)
-- task.spawn(FxTextures.resolve)          -- optional, once at start
-- FxTextures.apply(emitterOrBeam, "glow") -- sets Texture (and the flipbook layout for a flipbook candidate)
-- FxTextures.use("streak", "rbxassetid://<your sheet>", "Grid4x4") -- the game's own texture for a slot (or a new slot
--   name); the third argument is for a sheet of variants (2x2 or 4x4 different pieces, one random cell per particle)

local ContentProvider = game:GetService("ContentProvider")

local FxTextures = {}

-- flipbook: an animation played once over the particle's life. pieces: a sheet of different static pieces.
-- lead: the share of each particle's life spent on the sheet's opening frames that must not show (hideLead).
export type Candidate = { id: string, note: string, flipbook: string?, pieces: string?, builtin: boolean?, lead: number? }

FxTextures.slots = {
	glow = {
		{ id = "rbxassetid://3845808160", note = "docs soft circle (volcano smoke): white soft ball on alpha" },
		{ id = "rbxassetid://8983307836", note = "docs flare: ring + rays on black, additive only" },
	},
	flare = {
		{ id = "rbxassetid://8983307836", note = "docs flare: ring + rays on black, additive only" },
		{ id = "rbxassetid://3845808160", note = "docs soft circle" },
	},
	smoke = {
		{ id = "rbxassetid://16830673704", note = "docs thick smoke (volcano)" },
		{ id = "rbxassetid://3845808160", note = "docs soft circle" },
		{ id = "rbxassetid://16830667309", note = "docs thick mist (waterfall)" },
	},
	star = {
		{ id = "rbxassetid://5833323391", note = "docs curriculum spark" },
		{ id = "rbxasset://textures/particles/sparkles_main.dds", note = "built-in 4-point star", builtin = true },
	},
	streak = {
		{ id = "rbxassetid://17581858560", note = "docs elongated ember (on black, additive only)" },
		{ id = "rbxasset://textures/particles/fire_sparks_main.dds", note = "built-in", builtin = true },
	},
	fire = {
		-- its first three frames are a smooth pink-red ball: shown, every flame was born as a pink dot (Studio, 2026-11-21)
		{ id = "rbxassetid://17040521870", note = "DevForum free explosion flipbook 8x8", flipbook = "Grid8x8", lead = 0.05 },
		{ id = "rbxassetid://3845808160", note = "docs soft circle tinted by a fire ramp" },
	},
	band = {
		{ id = "rbxassetid://3845808160", note = "docs soft circle, wrapped finely along a beam = soft-edged band" },
		{ id = "", note = "untextured beam (solid band)" },
	},
	electric = {
		{ id = "rbxassetid://6101261905", note = "docs electric spark (lightning bolt)" },
	},
}

FxTextures.allowBuiltins = true
FxTextures.status = {} :: { [string]: string }
FxTextures.chosen = {} :: { [string]: Candidate }
FxTextures.force = {} :: { [string]: Candidate } -- pin a slot to one candidate
FxTextures.resolved = false

function FxTextures.resolve()
	local ids = {}
	local seen = {}
	local function add(c)
		if c.id ~= "" and not seen[c.id] then
			seen[c.id] = true
			table.insert(ids, c.id)
		end
	end
	for _, list in FxTextures.slots do
		for _, c in list do
			add(c)
		end
	end
	pcall(function()
		ContentProvider:PreloadAsync(ids, function(contentId, status)
			FxTextures.status[contentId] = status.Name
		end)
	end)
	for slot, list in FxTextures.slots do
		local pick = FxTextures.force[slot]
		if not pick then
			for _, c in list do
				local ok = true -- PreloadAsync status is recorded only: it said Failure for ids that rendered (measured)
				if ok and (FxTextures.allowBuiltins or not c.builtin) then
					pick = c
					break
				end
			end
		end
		FxTextures.chosen[slot] = pick or list[#list]
	end
	FxTextures.resolved = true
	return FxTextures.chosen
end

-- Pins a slot to the game's own texture, before or after resolve(). `pieces` names the grid of a variant sheet
-- ("Grid2x2", "Grid4x4"): every particle then shows one random cell for its whole life. A new slot name is allowed,
-- so a recipe layer can ask for it (slot = "shard").
function FxTextures.use(slot: string, id: string, pieces: string?): Candidate
	local c: Candidate = { id = id, note = "own texture", pieces = pieces }
	FxTextures.force[slot] = c
	FxTextures.slots[slot] = FxTextures.slots[slot] or { c }
	FxTextures.chosen[slot] = c
	return c
end

function FxTextures.get(slot: string): Candidate
	if not FxTextures.resolved then
		-- Not resolved yet: take the first candidate (or the forced one).
		return FxTextures.force[slot] or FxTextures.slots[slot][1]
	end
	return FxTextures.chosen[slot]
end

-- Sets Texture (and flipbook settings for a flipbook candidate) on an emitter or beam.
function FxTextures.apply(inst: Instance, slot: string)
	local c = FxTextures.get(slot)
	if inst:IsA("ParticleEmitter") then
		inst.Texture = c.id
		if c.flipbook then
			inst.FlipbookLayout = Enum.ParticleFlipbookLayout[c.flipbook]
			inst.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		elseif c.pieces then
			-- variants, not frames: Loop at framerate 0 holds the random start cell (OneShot would play the cells)
			inst.FlipbookLayout = Enum.ParticleFlipbookLayout[c.pieces]
			inst.FlipbookMode = Enum.ParticleFlipbookMode.Loop
			inst.FlipbookStartRandom = true
			inst.FlipbookFramerate = NumberRange.new(0)
		else
			inst.FlipbookLayout = Enum.ParticleFlipbookLayout.None
		end
	elseif inst:IsA("Beam") then
		inst.Texture = c.id
	end
	return c
end

-- A transparency sequence that hides the first `lead` of each particle's life and keeps the rest.
function FxTextures.hideLead(seq: NumberSequence, lead: number): NumberSequence
	local kps = seq.Keypoints
	local t1 = lead + 0.002
	local v, env = kps[#kps].Value, kps[#kps].Envelope
	for i = 2, #kps do
		local a, b = kps[i - 1], kps[i]
		if t1 <= b.Time then
			local u = (t1 - a.Time) / math.max(b.Time - a.Time, 1e-6)
			v, env = a.Value + (b.Value - a.Value) * u, a.Envelope + (b.Envelope - a.Envelope) * u
			break
		end
	end
	local out = { NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(lead, 1), NumberSequenceKeypoint.new(t1, v, env) }
	for _, k in kps do
		if k.Time > t1 then
			table.insert(out, k)
		end
	end
	return NumberSequence.new(out)
end

function FxTextures.report(): string
	local lines = {}
	for slot, c in FxTextures.chosen do
		table.insert(lines, string.format("%s=%s (%s)", slot, c.id == "" and "none" or c.id, c.note))
	end
	for id, st in FxTextures.status do
		table.insert(lines, string.format("preload %s %s", id, st))
	end
	table.sort(lines)
	return table.concat(lines, "\n")
end

return FxTextures
