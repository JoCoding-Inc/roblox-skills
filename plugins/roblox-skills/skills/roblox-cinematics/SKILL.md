---
name: roblox-cinematics
description: "Use when deciding whether and how a Roblox game gets cinematics: intro, boss reveal, tutorial beats, level-up or unlock moments, ending. Covers the planning questions, a shot list, the three production methods, skip and safety rules, budgets and testing. Also in the planning interview (roblox-game-pipeline stage 4) before any camera code, when a user asks for a cutscene, intro or trailer-style moment, when a cutscene feels too long or blocks play, or when a cutscene breaks on phone, in a server with several players, or in an MCP screenshot. Pair with roblox-pitfalls and roblox-store-art-pack (loading budget)."
last_reviewed: 2026-11-03
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

## 3. Three ways to make one

| Method | Use when | Notes |
|---|---|---|
| Script: `Camera.CameraType = Scriptable`, tween `CFrame` and `FieldOfView` between shot points (Parts as camera marks) | Most cases; easy to skip, restore and localize | Recipe in section 3a. Put marks in a Workspace folder called `CineMarks`, named `Shot01_A`, `Shot01_B` |
| Animation Editor on a camera rig, played through an Animator | Complex timing with actors and camera together | More setup; plugins exist (community) but check they are maintained |
| Pre-rendered image sequence or video frame | Trailer-like title cards | Heavy; not recommended for a first game |

### 3a. Script recipe (client; syntax checked with luau-analyze, not run in a live playtest, so adapt and test)

```luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local running = 0 -- newest cinematic wins
local activeTween: Tween? = nil
-- state from before the first cinematic; one that interrupts another keeps it
local saved: {type: Enum.CameraType, subject: Instance?, fov: number}? = nil

local function restore(withSubject: boolean)
	if activeTween then -- or it keeps writing CFrame and FOV after the restore
		activeTween:Cancel()
		activeTween = nil
	end
	if not saved then return end
	camera.CameraType = saved.type
	if withSubject and saved.subject and saved.subject.Parent then camera.CameraSubject = saved.subject end
	camera.FieldOfView = saved.fov
	controls:Enable() -- only play() below disabled it
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
		saved = {type = camera.CameraType, subject = camera.CameraSubject, fov = camera.FieldOfView}
		controls:Disable() -- the movement lock lives here, never in the caller
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

Movement is locked inside `play` with the camera: the first cinematic saves and disables the controls, `restore` enables them once on every exit, death included. Never lock or save movement in the caller: a second cinematic would save the locked state and restore it. Do not restore hard-coded defaults.

## 4. Shot list (write it before code)

One line per shot in `docs/cinematics.md`:

```
Shot 01 | 3.0 s | marks Shot01_A -> Shot01_B | slow push-in | FOV 70 -> 55 | text "Welcome" | music cue
```

Keep 3-6 shots per cinematic. Name every mark. Include what the player's character does (frozen, hidden, or acting).

## 5. Rules (checklist)

1. **Skip:** a visible Skip button (touch size, 44 px or more), gamepad and keyboard binding. Skip restores everything exactly as the end of the cutscene would.
2. **Restore:** save camera type, subject and FOV before; restore after, also on skip, error and player death.
3. **Input:** lock movement controls during the cutscene inside the cinematic module (section 3a), never in the caller; unlock on every exit, death included.
4. **Safety:** make the player invulnerable or anchored while the camera is away from the character; unanchor after, on every exit, and save the old state once in one place like the camera (first save wins). Anchored roots ignore `Humanoid:MoveTo` (`roblox-pitfalls`).
5. **Streaming:** with `StreamingEnabled`, call `Player:RequestStreamAroundAsync(position)` for the cutscene area before the first shot, or shots show unloaded geometry.
6. **Client authority:** the server sends one event ("play cinematic X to player P") and tracks "seen X" in the save; the client plays it. Do not let the client decide that a reward was earned.
7. **Overlap:** one cinematic owner at a time; a new one cancels the old one cleanly.
8. **Mobile:** test on a phone-size emulator; letterbox bars must not cover the Roblox top-left buttons or the Skip button.
9. **Performance:** no new heavy effects only for the cutscene; check frame time on a low-end phone profile.
10. **Accessibility:** short text lines, readable size, no flashing, shake can be turned off.
11. **Localization:** captions go through the localization table.

## 6. Testing through Studio MCP

- `execute_luau` returning resets a Scriptable camera to Custom, so screenshots show the default camera. Re-arm the camera inside the same call or play the cinematic from a real LocalScript in a play session (`roblox-pitfalls` section 3, 'Screenshots in Play', gives a binding that survives between calls).
- Record evidence per shot: one screenshot at the middle of each shot, plus one after the cutscene ends (camera and controls restored).
- Test the three exits: complete, skip, player dies or leaves mid-cutscene.

## 7. Done when

Shot list exists; skip works with touch, keyboard and gamepad; camera and controls restore after complete, skip and death; first-time-only flag is saved; evidence screenshots are in the PR or notes.
