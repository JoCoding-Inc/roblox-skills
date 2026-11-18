-- fx_own_textures: the asset ids of the textures you uploaded for ground_blast (roblox-feel-audio-vfx section 3g)
-- and ground_slam (section 3h). Each effect reads only its own names.
-- Make the files with ground_blast_textures.py and ground_slam_textures.py, upload each PNG as an Image to your own account or the group that
-- owns the game, and write the ids here. While a name is left at 0, ground_blast refuses to play and lists it.
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
	-- ground_slam (ground_slam_textures.py): while one is 0, ground_slam refuses to draw its smoke and haze layers
	slam_puff_a = 0, -- 4x4 flipbook: a dark puff that erodes into curls
	slam_puff_b = 0, -- 4x4 flipbook: a second puff
	slam_plume = 0, -- 4x4 flipbook: the taller plume
	slam_wisp_a = 0, -- 4x4 flipbook: pale haze
	slam_wisp_b = 0, -- 4x4 flipbook: pale haze
}
