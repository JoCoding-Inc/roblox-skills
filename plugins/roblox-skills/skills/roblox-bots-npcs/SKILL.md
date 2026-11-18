---
name: roblox-bots-npcs
description: "Use when a Roblox game needs NPCs, enemies, allies or bots: pathfinding, state machines, spawns, talking NPCs and ProximityPrompt interactions, bot fill so a solo player never plays an empty server, server cost and testing. Also when the planning advice says a mode must be solo-viable, when a match needs more players than are present, when NPCs get stuck, walk through walls, lag the server or ignore MoveTo, and before putting more than a handful of agents in a server."
last_reviewed: 2026-11-03
sources:
  - https://create.roblox.com/docs/characters/pathfinding (navigation mesh, agent parameters, modifiers, visualization)
  - https://create.roblox.com/docs/ui/proximity-prompts and /resources/npc-kit
  - roblox-pitfalls (anchored NPC poses ignore MoveTo)
  - roblox-design-and-launch section 1a (solo-viable checklist)
  - original (design judgment; budgets not measured)
---

# NPCs, enemies and bots

## 1. Decide the role (planning)

| Role | Examples | Notes |
|---|---|---|
| Enemy | mobs, bosses | Server-run; keep the count low per area |
| Ally or companion | pets that fight, guides | Follow the owner; cheap states |
| Bot fill | match players when the server is empty | Makes a mode playable alone (`roblox-design-and-launch` 1a): start the match after a short timeout with bots |
| Ambient | crowds, shopkeepers | Often animation only; no pathfinding |

Ask: how many agents per server at once, what must they do, can they be simpler (a tween on a path, a scripted lane)? Fewer smarter agents beat many busy ones.

## 2. Pathfinding (docs)

- `PathfindingService:CreatePath(params)` computes a route over the navigation mesh. Agent parameters (radius, height, can jump, can climb) and `Costs` per material or region steer it, for example higher cost for water. `PathfindingModifier` and `PathfindingLink` mark regions to avoid or jump gaps.
- In Studio, turn on **Navigation mesh** and **Pathfinding modifiers** in Visualization Options to see where agents can walk and what the engine thinks of your map.
- Recompute when the path is blocked or the target moves far. Follow waypoints with `Humanoid:MoveTo`, and treat a jump waypoint as a jump.
- Straight-line move (`MoveTo`, a tween) is enough when nothing is in the way. Use pathfinding only where the map needs it.

## 3. State machine, not a pile of ifs

Keep states few: Idle, Patrol or Follow, Chase, Attack, Return, Dead. One update loop per agent group (not one `while true` per agent), a state-change function that cleans up the previous state, and a single place that releases poses. Anchored roots ignore `MoveTo` (`roblox-pitfalls`): release the pose in one helper that every move path calls.

NPC animations play from the server (`roblox-feel-audio-vfx` section 3a). Code that reads or writes NPC joints as `Motor6D` breaks under the Avatar Joint Upgrade (`roblox-engine-2026` section 3).

Chasers that hunt players (horror, tag, escape) need pacing and fair senses. Field notes from one chase game, tested in Studio and by its owner on a phone (2026-11-15 to 2026-11-17):
- **Ramp the chaser with chase length.** A chaser that only matches the runner's sprint keeps a steady gap, and a player who never hides finishes; the playtester called it too easy twice. Raise its speed while one chase lasts (from the runner's 22 studs/s sprint to 27 between 5 s and 13 s there) and reset the ramp when contact is lost, so a hide or a real break is needed about every 15 s. A trap resets the ramp; a stumble must not, or players trip on purpose.
- **Only contact catches.** A noise sends the hearer to search the spot for a few seconds; a catch needs contact (5 studs with a clear line there). Being restarted for a sound read as unfair. Give hearing an error that grows with distance and let a thrown object count as the runner when unseen, so a decoy works. Give searchers roles at a decoy (one checks it, one covers facing away, one looks from where it stands), or they stack up where it fell and stare.
- **Hiding shrinks sight, not to zero.** Crouched with the light off, sight fell from 30 to 16 studs there, with a 10-stud always-seen radius so a searcher cannot stand beside a hider for long. Check every range against measured gaps: failed hides had the chaser 36-54 studs away with a clear line, inside the old 50-stud range.

## 3a. Talking NPCs, shops, interactions

- Interaction: a `ProximityPrompt` on the NPC (`ActionText` "Talk", `ObjectText` the name, `HoldDuration` 0 for talk, longer for risky actions; `MaxActivationDistance`, `RequiresLineOfSight`). Handle `Triggered` (or `ProximityPromptService.PromptTriggered`) on the server; phones can always tap the prompt.
- Dialog: drive lines from a data table (id, text, choices, next id) and show them in your own UI; captions go through localization. Server checks anything a choice grants (shop purchase, quest start), with the same rules as remotes (`roblox-engine-2026` section 4).
- Prefab option: the official NPC Kit (`/docs/resources/npc-kit`) has ready NPCs; audit it like any inserted model.
- Combat NPCs reuse the hit and damage rules of `roblox-combat-tools`; round-based enemies spawn from `roblox-match-flow`.

## 4. Server cost (judgment, measure on your map)

- Update agents on a staggered tick (for example every 0.2-0.5 s for far agents, faster when close), not every frame.
- Only simulate agents near a player; freeze or despawn the rest. Cap agents per server and per area, and test the cap on a low-end phone profile because the client animates and renders them.
- Give players network ownership of nothing that decides gameplay; keep combat, health and rewards on the server. Set NPC network ownership deliberately (`SetNetworkOwner(nil)` for server-controlled agents) so they do not jitter when a player is near.

## 5. Bot fill for solo play

1. Define the minimum players to start (1 for the main mode).
2. If real players are fewer than the match needs after a timeout (for example 15-20 s), add bots up to the minimum.
3. Bots follow the same rules as players (same damage, same speed), are labeled, and never take rewards or leaderboard places that real players lose.
4. Replace a bot with a real player who joins in progress when the mode allows it.
5. Do not use bots to fake player counts or hide an empty game; tell the player.

## 6. Tests

- One player alone finishes the mode with bots.
- A bot stuck on geometry recovers (path recompute, teleport to last good point after a timeout).
- 2x the planned agent count does not push server frame time or the player's FPS past your budget.
- Agents are cleaned up when the round ends or the player leaves (no leaked loops or connections).
- Hide spots pass a ray test in the course validator, not a look: from points 35-90 studs back along the approach (every 5 studs, eye height 4.5) cast to each spot with the same filters the chaser's sight uses (skip `CanQuery` off and `Transparency` 0.9 or more). A spot passes when at least 80 percent of the rays are blocked. In one course all 19 hide spots failed (16 at 0 percent) until they moved and 36 slim cover trunks were added (all 20 then at 92-100 percent). Re-run it after every edit of the route or the props (field note, 2026-11-16).
- Tune a chase with a fixed-step runner sim before tuning by feel: runner policies (sprint only, sprint plus hides, one stumble or trap anywhere, jog only) and the goals as assertions (a never-hide runner is caught, a hider finishes, one mistake is survivable). In one game it found the smallest survivable trap gap (30 studs) and showed that a stamina recovery delay of 0.6 s let burst sprinters finish where 1.5 s caught them. Do not use a walker that moves leg by leg (the Studio MCP `character_navigation` tool) as the runner: it stopped at each leg's end and averaged 13-15 studs/s against a held run of 20, so it was caught where a person was not. Use an in-game autopilot that holds input (field note, 2026-11-16).
- A chaser that stands still is geometry or a bad goal: log its state, speed, anchored flag and `MoveTo` target, and keep a watchdog. Causes found in one game: it ran at an invisible boundary wall (fix: a chaser collision group that ignores the wall; 4 of 4 runs stalled before, 0 of 8 after), it wedged between a post and an opened door, a lane goal sat 2 studs away on the inside of a corner (it ran on the spot for 16 s), and lane goals sat on cover trunks (field note, 2026-11-15).
