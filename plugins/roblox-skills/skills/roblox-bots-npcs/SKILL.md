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
