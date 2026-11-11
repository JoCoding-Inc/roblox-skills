---
name: roblox-combat-tools
description: "Use when planning, writing or reviewing combat in a Roblox game: melee, guns, projectiles, abilities, Tools and combat input, hit detection, lag tolerance, damage and kill credit, knockback, anti-exploit checks, Server Authority and combat testing. Also when a design adds weapons, enemies that fight back, PvP or PvE damage; when hits feel laggy or miss on phones; when exploiters one-shot players or spam a fire remote; when choosing between Tools, custom input, the Weapons Kit and Server Authority. Pair with roblox-engine-2026, roblox-bots-npcs, roblox-feel-audio-vfx, roblox-match-flow."
last_reviewed: 2026-11-03
sources:
  - https://create.roblox.com/docs/projects/server-authority
  - https://devforum.roblox.com/t/4727993 (Server Authority full release, 2026-07-09, incl. known issues and FAQ)
  - https://create.roblox.com/docs/players/tools and https://create.roblox.com/docs/workspace/raycasting
  - https://create.roblox.com/docs/reference/engine/classes/WorldRoot, datatypes/RaycastParams, datatypes/OverlapParams
  - https://create.roblox.com/docs/reference/engine/classes/Humanoid (TakeDamage, ForceField), Animator, AnimationTrack
  - https://create.roblox.com/docs/resources/weapons-kit and https://create.roblox.com/docs/studio/network-simulator
  - original (judgment: every number marked judgment, the flow, the checklists and tests)
---

# Combat and weapons

Combat is where lag and exploiters show up first. One rule: the client shows, the server decides. The docs we checked (2026-11-03) have no lag-compensation guide for classic (non Server Authority) combat, so the numbers in sections 4, 8 and 11 are judgment. Tune them with the tests in section 11.

## 1. Decide first (ask the developer, one at a time)

| Question | Default (D) |
|---|---|
| Weapon type, per weapon: melee, hitscan, projectile, ability | Guns hitscan, rockets and arrows projectile, swords melee arc, spells ability. Two types in the prototype |
| PvE, PvP or both | PvE or co-op first. PvP needs all of section 8 and bot fill (`roblox-bots-npcs`). Rounds, teams, respawn: `roblox-match-flow` |
| Casual or ranked | Casual: client claims + server checks (sections 2, 4). Ranked or physics-heavy: Server Authority (section 6) |
| Team damage | Off. On only when the design wants friendly fire, and then only inside the damage module (section 7) |
| Latency target | Playable at 150 ms round trip on a phone (judgment): standing targets always hit, moving targets 90 percent or better at the 4G preset |

## 2. Architecture

```
Client                                   Server
press / tap  -> predict swing, muzzle, tracer, sound
             -> FireServer(weaponId, aim or target)  -->  validate (section 8)
                                                          hit test (section 4)
                                                          Damage.apply (section 7)
hit marker, numbers  <--  HitConfirmed(victim, amount)    health, death, credit
other clients  <--  replicated Humanoid + VFX event
```

- Client sends intent only: weapon id, aim direction or claimed target. Never damage, health, ammo, cooldown state or "I killed X".
- Server owns hit result, damage, cooldown, ammo, death and credit. Damage numbers come from a server config table keyed by weapon id.
- The shooter predicts cosmetics at once. Show the hit marker only on the server's confirm; drop predicted effects that never confirm.

## 3. Tools and input

| Piece | Rule (docs: In-game tools) |
|---|---|
| `Tool` with one child part named `Handle` | Only one Handle, direct child, not anchored (an anchored tool pins the character). Weld other parts to it |
| `Tool.RequiresHandle` | `true` for held weapons; `false` for ability tools with no model |
| `Tool.CanBeDropped`, `Tool.Enabled` | Backspace drops a tool unless `CanBeDropped` is `false` (set it for weapons). Server sets `Enabled` false during reload or lockout |
| `Tool.Activated` / `Deactivated` / `Equipped` / `Unequipped` | The docs say they fire in LocalScripts. LocalScript reads input, a RemoteEvent tells a server Script |
| Grants | `StarterPack` copies to everyone at spawn; `StarterGear` for one player; earned weapons live in storage and the server clones them into the `Backpack`. Re-grant on every spawn (character reload clears the Backpack) |

`Tool.Activated` covers click, tap and gamepad trigger. Use the Input Action System (`roblox-engine-2026`) when you need aim hold, charge, combos, remapping, or Server Authority. Under Server Authority gameplay input must be an InputAction (section 6).

## 4. Hit detection

| Method | Use for | Notes |
|---|---|---|
| `WorldRoot:Raycast` | Hitscan, line of sight, melee reach | Max length 15,000 studs. Parts with `BasePart.CanQuery = false` are skipped. Filter with `RaycastParams.ExcludeInstances` / `IncludeInstances` (they replace FilterDescendantsInstances and FilterType for new work), `CollisionGroup`, `RespectCanCollide` |
| `WorldRoot:Blockcast`, `Spherecast`, `Shapecast` | Fat bullets, sweeping melee, forgiving aim | Do NOT detect parts already overlapping the start shape. `RaycastParams.Margin` and `SizeGradient` widen or taper the cast. Shapecast got a new implementation on 2026-10-28 (`roblox-engine-2026` status board) |
| `WorldRoot:GetPartBoundsInBox`, `GetPartBoundsInRadius`, `GetPartsInPart` | Melee arcs, point-blank, area damage | `OverlapParams` (Exclude/IncludeInstances, `MaxParts`, `CollisionGroup`). Bounds queries use bounding boxes (cheap); `GetPartsInPart` uses exact geometry. Run once per swing and dedupe victims per swing |
| `BasePart.Touched` | Pickups, triggers. Not damage | Fires only from physical movement, needs one unanchored part, misses CFrame moves, and can fire many times per swing |

With StreamingEnabled a client cast can miss unstreamed parts; the server sees everything, so the server cast decides.

Lag tolerance rules (numbers are judgment):

1. Take the shot origin from the server character (root plus 1.5 studs up), not from the client. If you accept a client origin, require it within 10 studs of the server root.
2. Range check: weapon range + 4 to 8 studs + target speed x ping. Read ping with `Player:GetNetworkPing()` (round trip, seconds) and cap the credited ping at 0.3 s so a laggy or spoofed ping does not widen the window forever.
3. Line of sight: the server casts shooter to target and rejects if a `CanQuery` part is in between.
4. Fire rate: server clock, cooldown minus 15 percent slack.
5. Rewind (ranked PvP only, otherwise skip): record each character's root CFrame every Heartbeat for 0.5 s. On a shot, test the target at `now - ping/2 - ~0.1 s` (measure the interpolation delay), cap the rewind at 0.25 s, accept within 3 to 4 studs. Rewind positions only, never health or cooldowns. Server Authority does this natively, so prefer it for ranked.

### 4a. Server validation snippet (hitscan claim)

Syntax checked with luau-analyze against stubbed Roblox globals, not run in a live playtest. Equipped, ammo, alive and team checks are not shown (section 8, `Damage.apply`).

```luau
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local fire = ReplicatedStorage:WaitForChild("FireWeapon") :: RemoteEvent
local Damage = require(script.Parent:WaitForChild("Damage")) :: {apply: (Model, number, Player) -> ()}

local RANGE, MARGIN, COOLDOWN, DAMAGE = 120, 6, 0.15, 20 -- studs, studs, s, hp (judgment)
local lastShot: {[Player]: number} = {}

fire.OnServerEvent:Connect(function(player: Player, target: unknown)
	if typeof(target) ~= "Instance" or not target:IsA("Model") then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local aim = target:FindFirstChild("HumanoidRootPart")
	if not (char and root and root:IsA("BasePart") and aim and aim:IsA("BasePart")) then return end

	local now = os.clock()
	if now - (lastShot[player] or 0) < COOLDOWN * 0.85 then return end -- 15% slack
	lastShot[player] = now

	local offset = aim.Position - root.Position
	local ping = math.min(player:GetNetworkPing(), 0.3)
	if offset.Magnitude > RANGE + MARGIN + aim.AssemblyLinearVelocity.Magnitude * ping then return end

	local params = RaycastParams.new()
	params.ExcludeInstances = {char}
	local hit = workspace:Raycast(root.Position, offset, params) -- line of sight
	local part = hit and hit.Instance
	if part and part:IsDescendantOf(target) then
		Damage.apply(target, DAMAGE, player)
	end
end)

Players.PlayerRemoving:Connect(function(player) lastShot[player] = nil end)
```

## 5. Projectiles

| Speed | Approach |
|---|---|
| Fast (bullets, lasers) | Hitscan on the server. The client draws a tracer from the muzzle to the confirmed hit point. The Weapons Kit does the same by setting `BulletSpeed` very high (its doc suggests 20000) |
| Slow (rockets, grenades, arrows, spells) | Server simulates each step in `RunService.Heartbeat`: cast from last position to next (Raycast, or Spherecast for width) so it cannot tunnel through thin walls. Clients get a "spawned" event and animate a visual copy. The shooter's own copy appears at once and the server copy is hidden for them |

- A client never reports "my projectile hit X"; it can only request a launch. Cap active projectiles per player (10 to 20, judgment) and per server (measure), give each a lifetime, clean up on hit, timeout and owner leaving.

## 6. Server Authority (competitive or physics-heavy games)

Full release 2026-07-09, opt-in. Docs list FPS, racing, sports and combat as its target. The server runs the simulation; clients predict ahead, then roll back and resimulate when the server disagrees. Opt in for ranked or exploit-prone movement games; skip it for casual PvE (extra server CPU, extra rewrite).

What changes (all from the docs page unless marked):

- Set `Workspace.AuthorityMode` to `Enum.AuthorityMode.Server`; this also sets NextGenerationReplication, PlayerScriptsUseInputActionSystem, SignalBehavior (Deferred), UseFixedSimulation and StreamingEnabled.
- Core logic goes in functions bound with `RunService:BindToSimulation()` inside a ModuleScript that both server and client initialize.
- Gameplay input uses `InputAction` (the `InputContext` must sit under the `Player`), not `UserInputService.InputBegan`. Use `time()` for time logic; `tick()`, `os.time()` and `os.clock()` are not synchronized and do not roll back.
- Synced custom state (health, ammo) goes in attributes on predicted instances; write them only inside bound functions.
- Create instances in the simulation; do not `Destroy()` there (mark intent with an attribute, destroy in `RunService.PostSimulation`). Sounds and VFX run in a render connection that reads simulation results and can undo mispredicted effects.
- Camera aim: the camera InputAction no longer replicates; `Player:GetCameraState()` returns CFrame, FieldOfView and ViewportSize synced from client to server (release post).

Caveats (each confirmed on the docs page or the release post):

| Caveat | Source |
|---|---|
| Release post: Backpacks and Tools are fully supported. Known issue: changing Tools during a misprediction may delete the Tool's Weld on the client (equip another tool or unequip to fix). Docs page (updated 2026-11-02) still says Tools are not fully supported, and `Humanoid:EquipTool()` and `UnequipTools()` have no simulation access, so call them outside bound functions. Run a two-client equip and swap test before you commit to Tools | post, docs |
| Attributes replicate only for the first 64 per instance, name up to 50 chars, string value up to 50 chars | docs |
| At most 8 actively playing animation tracks per Animator | post |
| RemoteEvents are not ordered with property/attribute updates and not on the shared timeline: use them for discrete events (score, pickup), InputActions for inputs | docs, post |
| Higher server utilization; small unless the server is already near its limit | post |

## 7. Damage pipeline (one server module, `Damage.apply(victim, amount, attacker, weaponId)`)

1. Validate: victim has a `Humanoid` with `Health` above 0; amount finite and clamped to the weapon's max.
2. Team: compare `Player.Team` of attacker and `Players:GetPlayerFromCharacter(victim)`; same team and friendly fire off means return. `Player.Neutral` players have no team.
3. Apply with `Humanoid:TakeDamage(amount)`. It does nothing while a `ForceField` protects the humanoid (spawn protection works). Setting `Humanoid.Health` ignores ForceFields; use it only for deliberate bypass (void, execute). Default regeneration is 1 percent of MaxHealth per second; an empty Script named `Health` in StarterCharacterScripts turns it off.
4. Kill credit: keep `lastHit[humanoid] = {attacker, os.clock()}` and credit the last attacker within 10 s (judgment). The older "creator" ObjectValue tag in the Humanoid is a community convention, not documented; use it only if other scripts need it.
5. Death: connect `Humanoid.Died` once per character. Pay out the kill once (guard against double fire), then hand off to match flow. For custom respawn set `Players.CharacterAutoLoads` false and call `Player:LoadCharacterAsync()` (`LoadCharacter` is deprecated). Rewards go through the economy module, server only.
6. Knockback: scale by mass: `ApplyImpulse(dir * strength * part.AssemblyMass)` (setting `AssemblyLinearVelocity` is allowed but the docs prefer forces or impulses). A player's character is simulated by its own client, so a server-side impulse may be ignored or overwritten (verify in the two-client test); the usual fix is a RemoteEvent telling the victim's client to apply a server-capped impulse. NPCs and loose parts: apply on the server with `SetNetworkOwner(nil)` (`roblox-bots-npcs`). Under Server Authority the server owns the character; apply it inside the simulation.

## 8. Anti-exploit checklist (every combat remote)

1. Payload: `typeof`, `math.isfinite`, Instance is the expected kind and descendant of the expected container (`roblox-engine-2026` section 4).
2. Shooter alive, character loaded, the weapon Tool is a child of the character and `Enabled`.
3. Cooldown and fire rate from the server clock; ammo and reload are server counters (the client only displays them).
4. Range with margin, origin near the server root, line of sight (section 4).
5. Target valid: a living character, not the shooter, not protected, not a teammate unless allowed.
6. Rate-limit each remote per player (token bucket; refill about 1.5 x max fire rate, judgment). Over limit: drop silently.
7. Client timestamps never decide anything. For diagnostics, compare with `Workspace:GetServerTimeNow()` and discard claims more than about 1 s apart (judgment).
8. Log, then soft-flag, then act. Count violations per player per rule. First hits are dropped and logged without telling the sender. Kick or exclude from ranked only after a sustained pattern (for example 10 or more in 30 s, judgment); lag causes honest false positives.

## 9. Animation hookup

- Load once per equip with `Animator:LoadAnimation()` and keep the track; it creates a new track every call. Retrieve an existing one with `Animator:GetTrackByAnimationId()`. Loading from the owning client also loads it for the server (docs).
- Set `AnimationTrack.Priority` to `Enum.AnimationPriority.Action` so a swing overrides idle and walk; use Action2 to Action4 only for layering.
- Hit frame: add a marker in the animation and listen with `AnimationTrack:GetMarkerReachedSignal("Hit")` for VFX, sound and opening the client's hit window.
- The server never trusts the marker. It starts its own timer at the swing request: accept hits only after the windup and before windup + active time, once per swing.
  Under Server Authority drive combat animations inside bound functions and do not cache tracks across frames.

## 10. Official Weapons Kit

Prefab Tools (Pistol, Shotgun, Auto Rifle, Submachine Gun, Sniper Rifle, Crossbow, Grenade Launcher, Rocket Launcher, Railgun) with an over-the-shoulder camera and projectile system. Get the model from the asset library, move its `WeaponsSystem` folder to `ServerScriptService`. Per weapon `Configuration`: `AmmoCapacity`, `BulletSpeed`, `HitDamage`, `FullDamageDistance`, `ZeroDamageDistance`, hit marks and a damage billboard. Limited Use License.

Use the kit for a prototype, a game jam or casual third-person shooter feel in an afternoon. Build custom for first-person or your own camera, melee or ability combat, ranked PvP, Server Authority (kit compatibility: verify) and your own team and kill-credit rules. Read the kit's server scripts before shipping PvP; whether they meet section 8 is not documented (verify). Route its damage through your `Damage` module if you add team rules.

## 11. Testing

- Two clients: Studio Test, Server & Clients setting with 2 or more players. Shooter and target each see the hit, health, death and kill credit.
- Latency: Test > Device Simulator, **Network** pill, **Apply** a preset. Presets (in/out): Home Wi-Fi 30/30 ms, Standard Mobile 45/55 ms, Bad Connection 150/180 ms; round trip is the sum plus real ping. Scriptable with `NetworkSettings.InboundNetworkMinDelayMs` and `OutboundNetworkMinDelayMs`. The docs page still labels it beta (enable New Device Simulator in Beta Features); `roblox-engine-2026` lists it as full release.
- Bot scenarios (`roblox-bots-npcs`), one PASS/FAIL line each: standing target in range = hit with config damage; target at range + 50 studs, behind a wall, dead or respawning, or a teammate (friendly fire off) = no damage and no second kill credit; run-speed target at the 4G preset = 90 percent or better hits (judgment); fire at 3 x max rate for 2 s = accepted shots at or below max rate.
- Exploit tests from a test LocalScript: spam the remote at 100 per second; send NaN, inf, huge vectors, wrong types, a destroyed Instance; claim a target 500 studs away; fire while dead; fire an unequipped weapon. Expected: no damage, no server errors, flags logged.
- Hit feedback checks belong to `roblox-feel-audio-vfx`; hit stop, combo escalation and finisher effects to `roblox-fun-effects` section 8; save data for loadouts to `roblox-data-saves`; Studio MCP quirks to `roblox-pitfalls`.

## 12. Done when

Weapon types, PvP/PvE, ranked or casual and team damage are decided and written down; one `Damage` module is the only path to health; every combat remote passes section 8; server cooldown, ammo, range and line of sight verified by the bot table; exploit tests pass; hits tested at Home Wi-Fi, 4G and 3G presets; kill credit and respawn hand-off tested; Server Authority decision recorded with its caveats if used.
