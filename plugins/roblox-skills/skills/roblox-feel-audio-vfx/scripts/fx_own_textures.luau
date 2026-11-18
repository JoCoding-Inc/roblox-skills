-- fx_own_textures: the asset ids of the textures you uploaded for ground_blast (roblox-feel-audio-vfx section 3g).
-- Make the files with ground_blast_textures.py, upload each PNG as an Image to your own account or the group that
-- owns the game, and write the ids here. A name left at 0 keeps a public stand-in texture (rough look).
-- Copy this file as a ModuleScript named fx_own_textures next to ground_blast.
-- swirl_streaks is not in this table: it goes into the swirl mesh template's SurfaceAppearance in Studio.
return {
	hot_fire_a = 0, -- 4x4 flipbook: fire lump
	hot_fire_b = 0, -- 4x4 flipbook: fire lump, torn more
	sim_smoke = 0, -- 4x4 flipbook: smoke puff
	lick = 0, -- 4x4 pieces: single flame tongues
	crackle = 0, -- 2x2 pieces: webs of thin hot lines
	flecks = 0, -- 2x2 pieces: scatters of chips
	blades = 0, -- the flash fan
	cracks = 0, -- floor cracks
	streaks = 0, -- streak sheet
	swirl_disc = 0, -- spinning floor disc
	trail = 0, -- ejecta trail
	scorch = 0,
	shock_ring = 0,
	spark = 0,
}
