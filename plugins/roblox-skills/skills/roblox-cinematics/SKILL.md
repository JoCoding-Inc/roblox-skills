---
name: roblox-cinematics
description: "Use when deciding whether and how a Roblox game gets cinematics: intro, boss reveal, tutorial beats, level-up or unlock moments, ending. Covers the planning questions, a shot list, the three production methods, skip and safety rules, budgets and testing. Also in the planning interview (roblox-game-pipeline stage 4) before any camera code, when a user asks for a cutscene, intro or trailer-style moment, when a cutscene feels too long or blocks play, or when a cutscene breaks on phone, in a server with several players, or in an MCP screenshot. Pair with roblox-pitfalls and roblox-store-art-pack (loading budget)."
last_reviewed: 2026-11-12
sources:
  - roblox-pitfalls (execute_luau resets Scriptable camera; anchored NPC poses)
  - DevForum community threads on Scriptable camera cutscenes (opinion, not Roblox docs)
  - original (planning notes; the budgets below are design judgment, not measured)
---

# Cinematics for Roblox games

Roblox has no official cutscene guide in the creator docs we checked (2026-11-03). Camera and Tween mechanics come from the engine API and community practice; the budgets here are judgment. Say so when advising.

## 1. Decide first (ask the developer, one at a time)

| Question | Default (D) |
|---|---|
| Does this game need any cinematic? Simulators and obbies often do not; story, horror, boss and RPG games often do | None in the prototype; add after the core loop is fun |
| Which moments: first-join intro, tutorial beat, boss reveal, unlock or rebirth, ending, trailer | Pick at most 2 |
| Play for everyone or only the first time? | First time only, replay from a menu |
| Skippable? | Always yes |
| Who sees it: one player (client) or everyone in the server | One player |
| Style: letterbox bars + slow pans, handheld shake, or a fast-cut montage | Slow pan + bars |
| Voice, music or text captions | Music + short text lines |

If the developer cannot picture a style, show it: storyboard stills per style, or a 4-5 s clip per style when they want to see the motion (`roblox-game-pipeline` section 10a; clips cost more, quote first).

If the genre is a simulator or tycoon and the developer is unsure, recommend a 5-8 s "unlock moment" instead of an intro: players there come to play, not watch (see `roblox-design-and-launch` section 1a on short sessions).

## 2. Budgets (judgment)

| Cinematic | Length | Rule |
|---|---|---|
| First-join intro | 10-20 s | Show the title and the core promise; control returns fast |
| Boss reveal | 4-8 s | The fight starts right after, no second wait |
| Unlock, level-up, rebirth | 3-6 s | Skippable, never blocks the shop or the next action |
| Roll or hatch reveal | 0.3-8 s by rarity tier | Short for common results, a "skip below tier N" setting; beats in `roblox-fun-effects` section 4 |
| Story or ending | up to 60 s | Chapters, skip per chapter |

Keep the first minute interactive: a long intro before the first action costs the early retention that the platform data points to (median session about 7 min).

Measured in one game: a 48 s first-join intro was finished by everyone who watched it, yet 77 percent of first sessions on phones and 66 percent on computers skipped it, at 7-9 s; on tablets 19 percent skipped, at 13-20 s (field note, 2026-11-16). Log a cutscene-end event with how it ended (finished or skipped) and when, per device. What the first 7-9 s show is all most players see (judgment).

## 3. Three ways to make one

| Method | Use when | Notes |
|---|---|---|
| Script: `Camera.CameraType = Scriptable`, tween `CFrame` and `FieldOfView` between shot points (Parts as camera marks) | Most cases; easy to skip, restore and localize | Recipe in section 3a. Put marks in a Workspace folder called `CineMarks`, named `Shot01_A`, `Shot01_B` |
| Animation Editor on a camera rig, played through an Animator | Complex timing with actors and camera together | More setup; plugins exist (community) but check they are maintained |
| Pre-rendered image sequence or video frame | Trailer-like title cards | Heavy; not recommended for a first game |

A worked skill cutscene (shot table, impact frames, dark beat, flash cap counted in code, element scripts and capture strips): `roblox-feel-audio-vfx` section 3e; its 3-per-second flash cap is how a skill cutscene meets rule 10.

### 3a. Script recipe (client; run once in Studio Play in the Device Simulator on 2026-11-22: a two-shot film skipped at 1 s, then played to the end, put back the camera, the touch controls and the speeds both times; the death and respawn paths were not run, so adapt and test)

```luau
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local running = 0 -- newest cinematic wins
local activeTween: Tween? = nil
-- state from before the first cinematic; one that interrupts another keeps it
type Saved = {type: Enum.CameraType, subject: Instance?, fov: number, touch: boolean, hum: Humanoid?, walk: number, jumpPower: number, jumpHeight: number}
local saved: Saved? = nil

local function restore(withSubject: boolean)
	if activeTween then -- or it keeps writing CFrame and FOV after the restore
		activeTween:Cancel()
		activeTween = nil
	end
	if not saved then return end
	camera.CameraType = saved.type
	if withSubject and saved.subject and saved.subject.Parent then camera.CameraSubject = saved.subject end
	camera.FieldOfView = saved.fov
	GuiService.TouchControlsEnabled = saved.touch -- only play() below changed these
	local hum = saved.hum
	if hum and hum.Parent then
		hum.WalkSpeed, hum.JumpPower, hum.JumpHeight = saved.walk, saved.jumpPower, saved.jumpHeight
	end
	saved = nil
end

-- death ends the cinematic at once (the character is removed only after Players.RespawnTime)
local function watch(char: Model)
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	hum.Died:Connect(function()
		running += 1
		restore(true)
	end)
end
if player.Character then task.spawn(watch, player.Character) end
player.CharacterAdded:Connect(watch)
-- so does a respawn without death (LoadCharacter); the new character sets the camera subject itself
player.CharacterRemoving:Connect(function()
	running += 1
	restore(false)
end)

-- shots: { {marks = {CFrame, CFrame}, time = number, fov = number?} }
local function play(shots, skipSignal: RBXScriptSignal)
	running += 1
	local me = running
	if not saved then
		local char = player.Character
		local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		saved = {type = camera.CameraType, subject = camera.CameraSubject, fov = camera.FieldOfView, touch = GuiService.TouchControlsEnabled,
			hum = hum, walk = if hum then hum.WalkSpeed else 0, jumpPower = if hum then hum.JumpPower else 0, jumpHeight = if hum then hum.JumpHeight else 0}
		-- the movement lock lives here, never in the caller: no thumbstick or jump button, no walking or jumping
		GuiService.TouchControlsEnabled = false
		if hum then hum.WalkSpeed, hum.JumpPower, hum.JumpHeight = 0, 0, 0 end
	end
	local skipped = false
	local skipConn = skipSignal:Connect(function() skipped = true end)
	camera.CameraType = Enum.CameraType.Scriptable
	local ok, err = pcall(function()
		for _, shot in shots do
			camera.CFrame = shot.marks[1]
			local goal = {CFrame = shot.marks[2]}
			if shot.fov then goal.FieldOfView = shot.fov end
			local tween = TweenService:Create(camera, TweenInfo.new(shot.time, Enum.EasingStyle.Sine), goal)
			activeTween = tween
			tween:Play()
			local done = false
			tween.Completed:Once(function() done = true end)
			while not done and not skipped and running == me do task.wait() end
			tween:Cancel()
			if skipped or running ~= me then break end
		end
	end)
	skipConn:Disconnect()
	if running == me then -- restore in every exit: complete, skip, error (death restores above)
		restore(true)
	end
	if not ok then warn(err) end
end
```

Movement is locked inside `play` with the camera: the first cinematic saves the touch controls and the humanoid's `WalkSpeed`, `JumpPower` and `JumpHeight`, hides the controls and sets the three to 0; `restore` puts the saved values back once on every exit, death included. Never lock or save movement in the caller: a second cinematic would save the locked state and restore it. Do not restore hard-coded defaults. A game whose server rewrites `WalkSpeed` while the film plays (a sprint or stats system) pauses that too. Not `PlayerModule:GetControls():Disable()`: in Studio's Device Simulator (Samsung Galaxy A06, 2026-11-22; seen by a builder, then again with the test place's only script switched off) it left the thumbstick and the jump button on screen through the lock and added a second `TouchGui` that stayed after `Enable()`; `GuiService.TouchControlsEnabled = false` hid both and kept one.

Lens fights: a camera or zoom module that writes `Camera.FieldOfView` every frame overrides the cinematic's lens. One game measured 70 on every frame of a shot that asked for 42, and its start screen had the same fault. Route the film's lens through that module (a setter it applies each frame, cleared with nil on every exit) or bind the film's step after it, and log `FieldOfView` per frame in the first Studio check before judging any framing (field note, 2026-11-17).

## 4. Shot list (write it before code)

One line per shot in `docs/cinematics.md`:

```
Shot 01 | 3.0 s | marks Shot01_A -> Shot01_B | slow push-in | FOV 70 -> 55 | text "Welcome" | music cue
```

Keep 3-6 shots per cinematic. Name every mark. Include what the player's character does (frozen, hidden, or acting).

Framing rules from built boss reveals and world tours:
- **Keep the player's character out of shots by geometry, not luck.** Build the camera keys in a frame made at the film's start from the subject's ground point and the character (forward = the flat direction from the character to the ground). Put low cameras between the character and the boss, then turn the whole low run about the ground by the first angle of 0, +-25 ... +-125 degrees that keeps the character's box (about 4 x 4 studs and 9.5 tall with a weapon on the back) out of every low picture between the bars, on a 16:9 screen and an 800 x 360 phone, with 6 degrees of lens and 1 stud of box to spare for shake. When no turn works (the character stands close to the subject), hide the character's own parts on that client with `LocalTransparencyModifier` until the camera has passed it, and restore them on every exit. Test the rule as code with the box, not by eye: by eye, the character's back and weapon filled a third of the first low shot (field note, 2026-11-18).
- **Fit key for a big subject:** give the landing and roar shots no aim or lens of their own and compute both from where the camera stands, so the whole body sits between the bars (feet at about -0.45 of the half-height, top at +0.85) with ground under it. For a 27-stud boss that gave FOV 67 from 38 studs and 75 from 32; hand-framed shots had cut the boss at the waist and showed no ground. Keep every camera 1 stud short of walls (a ray from 6 studs up) and at least 15 studs from the subject's centre (field note, 2026-11-18).
- **A fly-through flies low:** 8-11 studs up, under gate beams, past each creature group from its side. A first version at 20-44 studs read the creatures as dots. Write the path as data and test it by sampling every 0.01 s: near the road, always moving on, clear of every gate, never under 6 studs, 12-16 s long. Move creature groups that a raised weapon would sweep across the lens (field note, 2026-11-17).
- **Title inside the bars:** lay the title out at the 800 x 360 phone picture and scale it by the picture height with a `UIScale`, because `TextSize` stops at 100 px; keep capitals about 10 percent of the picture height on every screen (field note, 2026-11-18).

## 5. Rules (checklist)

1. **Skip:** a visible Skip button (touch size, 44 px or more), gamepad and keyboard binding. Skip restores everything exactly as the end of the cutscene would.
2. **Restore:** save camera type, subject and FOV before; restore after, also on skip, error and player death. Restore only what the cinematic changed, and remove only what it created (`roblox-feel-audio-vfx` section 3b, ownership rule). Hide the game's overlays too and give them back on every exit: touch controls, open panels, guide arrows, pending notices and world `BillboardGui`s. Hide world labels by setting `MaxDistance` to about 0.01 and restoring it, not by `Enabled`: other scripts toggle `Enabled` with their own state and switch a label back on mid-film. One game found a reward notice and NPC name tags over its intro only in captures (field note, 2026-11-17).
3. **Input:** lock movement controls during the cutscene inside the cinematic module (section 3a), never in the caller; unlock on every exit, death included.
4. **Safety:** make the player invulnerable or anchored while the camera is away from the character; unanchor after, on every exit, and save the old state once in one place like the camera (first save wins). Anchored roots ignore `Humanoid:MoveTo` (`roblox-pitfalls`).
5. **Streaming:** with `StreamingEnabled`, call `Player:RequestStreamAroundAsync(position)` for the cutscene area before the first shot, or shots show unloaded geometry.
6. **Client authority:** the server sends one event ("play cinematic X to player P") and tracks "seen X" in the save; the client plays it. Do not let the client decide that a reward was earned. When a film covers a server-run activity (a boss entrance, a run), the server owns the wait: it sets and saves "seen" at the trigger (a skip, death or leave never replays it), names the one player who gets the film (everyone else gets the normal entrance) and holds the activity for max(normal wait, film length - lead-in + 0.3 s), so no attack lands during the film. Cap any hold that waits for the client's "ended" report: with a 10 s cap, a client that never reported was released at 10.03 s. Skip is one remote the server accepts once, only from that player, only while the activity is held, rate-limited, and it shortens the hold to the normal wait, never below it (field notes, 2026-11-15 and 2026-11-18). Mark "seen" only when the full version played: a short fallback must not use up a once-per-save film (judgment).
7. **Overlap:** one cinematic owner at a time; a new one cancels the old one cleanly.
8. **Mobile:** test on a phone in the Studio Device Simulator (`roblox-ui-layout` section 6); letterbox bars must not cover the Roblox top-left buttons or the Skip button.
9. **Performance:** no new heavy effects only for the cutscene; check frame time on a low-end phone profile.
10. **Accessibility:** short text lines, readable size, no flashing, shake can be turned off.
11. **Localization:** captions go through the localization table.

## 6. Testing through Studio MCP

- `execute_luau` returning resets a Scriptable camera to Custom, so screenshots show the default camera. Re-arm the camera inside the same call or play the cinematic from a real LocalScript in a play session (`roblox-pitfalls` section 3, 'Screenshots in Play', gives a binding that survives between calls).
- Record evidence per shot: one screenshot at the middle of each shot, plus one after the cutscene ends (camera and controls restored).
- Captures land seconds after the call, so a 4 s intro at real speed was never caught; at 0.25x it was. Give the cutscene timeline a Studio-only time-scale attribute and slow it together with the sim's debug speed for shots (field note, 2026-11-11). Judge real-speed timing by watching it in Play (`roblox-game-pipeline` section 7a).
- Test the three exits: complete, skip, player dies or leaves mid-cutscene.

## 7. Done when

Shot list exists; skip works with touch, keyboard and gamepad; camera and controls restore after complete, skip and death; first-time-only flag is saved; evidence screenshots are in the PR or notes.
