# Part look examples

Two Studio renders (our own, scratch place, 2026-11-03) the agent shows when part-built art is in the plan (section 6a) and the user has not chosen a part look. They are real engine output, not AI images.

## `stud-surfaces.jpg`: how games get (or avoid) the stud look

| Option | Set this | Looks like | Use for |
|---|---|---|---|
| A. Studs on every face | `Material = Plastic` and all six `TopSurface`, `BottomSurface`, `FrontSurface`, `BackSurface`, `LeftSurface`, `RightSurface` = `Enum.SurfaceType.Studs` | The classic brick look on every side | Classic blocky lane, nostalgia builds, obbies, toy-like props |
| B. New part default | Nothing: `Instance.new("Part")` is Plastic with Top = Studs, Bottom = Inlet, sides Smooth | Studs on top only, plain sides | Rarely chosen on purpose; set the faces explicitly instead |
| C. Smooth | `Material = SmoothPlastic` (surfaces do not draw studs on SmoothPlastic) | Clean flat color, modern | Chunky cartoon, cozy, low-poly lanes; UI-like props |
| D. Stud texture | `SmoothPlastic` plus a `Texture` per face with a stud tile image, `StudsPerTileU/V` for size, `Transparency` 0.5-0.7 for strength (tested with `rbxassetid://6927295847`, 4 studs per tile, 0.6) | Faint, adjustable studs | Floors and big surfaces in chunky cartoon games; a hint of studs without the noise |

Rules:
- Studs only render on `Plastic`. A part set to Studs but SmoothPlastic shows nothing.
- Set the look once in the build script's part helper so every part matches. Mixed defaults (option B next to A) look like a bug.
- Six textures per part add instances; on hundreds of parts prefer A or C, or put the stud texture only on the faces players see (usually Top).
- Thick cartoon outlines do not come from parts. `Highlight` has a cap on how many draw at once and costs GPU; outlines come from meshes or not at all.
- Not tested yet: a `MaterialVariant` with a stud color map (`MaterialService`, `StudsPerTile`) to set the stud look game-wide.

```lua
local FACES = { "Top", "Bottom", "Front", "Back", "Left", "Right" }
local function brick(size: Vector3, cf: CFrame, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored, p.Size, p.CFrame, p.Color = true, size, cf, color
	p.Material = Enum.Material.Plastic
	for _, f in FACES do
		p[f .. "Surface"] = Enum.SurfaceType.Studs -- option A; use SmoothPlastic + Smooth for option C
	end
	p.Parent = parent
	return p
end
```

## `materials.jpg`: built-in materials on the same cube

Plastic (with studs), SmoothPlastic, Neon, Glass (Transparency 0.4), Wood, WoodPlanks, Brick, Cobblestone, Concrete, Metal, DiamondPlate, Grass. Rendered with the default 2022 materials. Use it to pick 2-4 materials per lane, for example classic blocky: Plastic with studs plus Neon accents; cozy: SmoothPlastic, WoodPlanks, Grass; sci-fi: Metal, DiamondPlate, Neon, Glass. Materials stay readable only at their scale: WoodPlanks and Brick tile per stud, so tiny parts show one smear.

## How to use

Send `stud-surfaces.jpg` (and `materials.jpg` when the lane is not chunky cartoon), say in one line per option what it would look like in this game ("A: the whole gym in toy bricks; C: smooth candy-color machines"), and record `Part look: <A-D>, materials <list>` in the brief. For the look of the user's own scene, build one sample prop each way in Studio and screenshot them side by side (section 6a bake-off) rather than generating an image: parts cost nothing to try.
