---
name: roblox-match-flow
description: "Use when planning or writing a Roblox game with rounds, matches, lobbies or teams: session shape, the round state machine, teams and spawns, lobby and match places, teleports, matchmaking, server shutdown, match results and tests."
when_to_use: "Also when a design says rounds, lobby, queue, 1v1, party, private match or teams; when a match needs more players than are present; when players wait in an empty lobby; when a teleport fails, loses data or cannot be tested; before a release that adds a match place. Pair with roblox-bots-npcs, roblox-data-saves, roblox-combat-tools and roblox-pitfalls."
last_reviewed: 2026-11-03
sources:
  - https://create.roblox.com/docs/projects/teleport (and teleport-private-servers)
  - https://create.roblox.com/docs/reference/engine/classes/TeleportService (and TeleportOptions)
  - https://devforum.roblox.com/t/teleports-to-private-vip-servers-are-now-allowed/4963250 (2026-10-28)
  - https://create.roblox.com/docs/matchmaking (customize-matchmaking, attributes-and-signals)
  - https://create.roblox.com/docs/production/experiments
  - https://create.roblox.com/docs/cloud-services/memory-stores (and the MessagingService class page)
  - https://create.roblox.com/docs/reference/engine/classes/DataModel (BindToClose, ServerRestartScheduled)
  - https://create.roblox.com/docs/projects/update-games
  - https://create.roblox.com/docs/players/leaderboards (devforum 4832224)
  - https://create.roblox.com/docs/studio/testing-modes
  - original (defaults, state machine and test cases are design judgment)
---

# Match flow: rounds, lobbies, teams, teleports

The docs cover the parts (teams, teleports, matchmaking, memory stores). The loop that joins them is our judgment; sections say which is which. Damage and weapon rules live in `roblox-combat-tools`.

## 1. Decide first (ask the developer, one at a time)

| Question | Default (D) |
|---|---|
| Session shape: drop-in world, round-based in one place, or lobby place + match places | Round-based in one place. Add a match place only for fixed-size, private or party matches, or one map per match |
| Players to start a round | 1, bots fill the rest (`roblox-bots-npcs` section 5) |
| Max players per server | From the design (1v1 = 2, squads = 8-16); platform median is 16 (`roblox-design-and-launch` section 1a). Set in place settings on the Creator Dashboard; script cannot change Players.MaxPlayers |
| Round length | 2-4 min. Median session is about 7 min, so two rounds fit |
| Late join | Spectate until the next round. Join in progress only in drop-in modes |
| Team assignment | Server balances, parties stay together, no switching mid-round |
| One player in the server | Wait 15-20 s at most, then bots or a solo mode. Never a dead wait |
| Win, draw, timeout | Write the rule first. Tie = draw, nobody loses rating |

## 2. Round loop (server state machine)

| State | Enter | Leave | Players do |
|---|---|---|---|
| Waiting | server start, or too few players | MIN_PLAYERS present | free roam in the lobby area |
| Intermission | enough players | timer ends (bots fill at the end) | loadout, vote |
| Round | intermission over | win condition, timer, or roster empty | play at spawns |
| Results | round over | timer ends | see winner; server awards and saves |

Results goes back to Intermission, or to Waiting if players dropped below the minimum.

1. One server module owns state, timers and win checks. The client never starts or ends a round.
2. Replicate with attributes (`SetAttribute` on `workspace`) or a RemoteEvent for one-shot events. Send a deadline (`Workspace:GetServerTimeNow()` + seconds), not a counter; the client draws the countdown from it and only displays. Remotes follow `roblox-engine-2026` section 4.
3. Fix the roster when the round starts. A player who leaves is removed on `Players.PlayerRemoving` and the win condition is re-checked at once. Late joiners are not in the roster.
4. AFK: `Player.Idled` fires only in client scripts (about 2 min idle). The client tells the server by remote; the server drops that player from the roster and gives no reward. Roblox disconnects players idle for 20 min.
5. Win condition = one function of roster state. Nobody alive or a tied timer = draw; show "Draw", do not pick a winner by accident.
6. At round end: clear bots, projectiles, connections and temporary instances (`roblox-bots-npcs` section 6).

Skeleton (syntax checked with luau-analyze with the Roblox globals stubbed, not run in a live playtest; adapt and test):

```luau
--!strict
local Players = game:GetService("Players")
local MIN_PLAYERS = 1 -- 1 = solo viable; bots fill the rest (roblox-bots-npcs)
local TIMES = {Intermission = 15, Round = 180, Results = 8}
local roster: {[Player]: boolean} = {} -- who is in this round
local startCount = 0
Players.CharacterAutoLoads = false
Players.PlayerRemoving:Connect(function(player) roster[player] = nil end)
local function setState(name: string, seconds: number)
	workspace:SetAttribute("MatchState", name)
	workspace:SetAttribute("StateEndsAt", workspace:GetServerTimeNow() + seconds)
end
local function roundOver(): boolean
	local alive = 0
	for player in roster do
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then alive += 1 end
	end
	return alive < math.min(startCount, 2) -- solo ends on death, else last one standing
end
while true do
	setState("Waiting", 0)
	while #Players:GetPlayers() < MIN_PLAYERS do task.wait(1) end
	setState("Intermission", TIMES.Intermission)
	task.wait(TIMES.Intermission)
	table.clear(roster)
	for _, player in Players:GetPlayers() do
		roster[player] = true
		pcall(player.LoadCharacterAsync, player) -- yields until spawned; may fail if they left
	end
	startCount = #roster
	setState("Round", TIMES.Round)
	local stop = workspace:GetServerTimeNow() + TIMES.Round
	while workspace:GetServerTimeNow() < stop and not roundOver() do task.wait(0.25) end
	setState("Results", TIMES.Results) -- award on the server, then display
	task.wait(TIMES.Results)
end
```

Left out: bot fill, awards, teams, spectators. With `CharacterAutoLoads` off nobody spawns until `LoadCharacterAsync`, so also load players on join for Waiting and Intermission.

## 3. Teams and spawns (each property confirmed on the live class pages)

| Item | Behavior |
|---|---|
| `Teams` service | Parent every `Team` directly to it; `Teams:GetTeams` returns only direct children |
| `Team.TeamColor` | Give each team a unique color; spawn matching works by color |
| `Team.AutoAssignable` | A joining player goes to the auto-assignable team with the fewest players; if none, `Player.Neutral` is true. It does not rebalance when players leave. The built-in rebalance method is deprecated; write your own |
| `Player.Team` | Set this, not `Player.TeamColor`. `Team:GetPlayers` lists players on the team who are not neutral |
| `SpawnLocation.TeamColor`, `SpawnLocation.Neutral` | Neutral false: only players with the same team color spawn there. Neutral true: anyone |
| `SpawnLocation.AllowTeamChangeOnTouch` | Turn off in team games, or touching a spawn changes the team |
| `SpawnLocation.Enabled`, `SpawnLocation.Duration` | Disable lobby spawns during a round. Duration = spawn ForceField seconds, default 10, 0 = none; set per mode |
| `Player.RespawnLocation` | Per-player spawn; must be in Workspace and match the team or be neutral |
| `Players.RespawnTime` | Default 5 s; applies only while `Players.CharacterAutoLoads` is true |
| `Players.CharacterAutoLoads` | False = no spawn until `Player:LoadCharacterAsync` (the older `LoadCharacter` is deprecated). Do not call it again for a player before `Player.CharacterAppearanceLoaded` |

Team split (judgment): put party members on one team first, then add each remaining player to the smaller team.

## 4. Multi-place flow (lobby place + match place)

Both places live in one universe. On the match place set Access Control for Places to "Secure within universe only" (`roblox-engine-2026` section 4). Default flow:

1. Lobby collects a group (queue, party or private code) and saves their data (section 5).
2. The lobby server makes a GUID with `HttpService:GenerateGUID(false)`, sets `TeleportOptions.ReservedServerId` and `TeleportOptions:SetTeleportData` (ids and settings only), and calls `TeleportService:TeleportAsync(matchPlaceId, players, options)` inside `pcall`.
3. The match server checks `game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0` (reserved) and reads `Player:GetJoinData()`. It waits a join timeout, then starts with bots for missing players.
4. After Results it saves, then teleports everyone back to the lobby place with no private routing field.

`TeleportOptions` (live docs 2026-11-03; devforum 4963250 announced the change 2026-10-28):

| Field | Use |
|---|---|
| `ReservedServerId` | Developer GUID. First teleport with a new id creates the server; reusing the id returns to the same one |
| `VipServerId` | `DataModel.PrivateServerId` of a player-bought VIP server. Works for any place in the same experience, not another experience |
| `ServerInstanceId` | `DataModel.JobId` of one public server |
| `SetTeleportData` / `GetTeleportData` | Value types only; Instances, functions and engine objects are stripped |

- Set at most one of `ReservedServerId`, `VipServerId`, `ServerInstanceId` (also the old fields): two raise an error.
- Deprecated, still working: the TeleportOptions fields `ShouldReserveServer` and `ReservedServerAccessCode`; the TeleportService methods `ReserveServerAsync`, `ReserveServer`, `TeleportToPrivateServer`, `TeleportPartyAsync`; the client `Teleport`. Reserving first does nothing; it only returns a random GUID. Old access codes stay valid.
- Generate GUIDs on the server only. Store the GUID (DataStore) if players must return to the same private match. `DataModel.PrivateServerId` stays the same across restarts of that server; `DataModel.JobId` does not. `TeleportAsyncResult.PrivateServerId` returns it after a private teleport.
- Party teleport: one `TeleportAsync` call, up to 50 players, one experience. `Player.PartyId` (hidden) with `SocialService:GetPlayersByPartyId` lists a party. The arrivals see `Members` in `Player:GetJoinData`. Test party code with Studio's Party Simulator.
- VIP: access can be removed at any moment, so handle `TeleportService.TeleportInitFailed`. A plain teleport with no routing field can land a player on the VIP server they recently used. An opt-out field was announced but is not in the docs yet: verify before relying on either.

## 5. Teleport safety and failure

1. Teleport data is visible to the client and unencrypted. Treat it as a hint. `Player:GetJoinData` only returns data that a Roblox server sent in the last 48 h with this player, and gives `SourcePlaceId` and `SourceGameId`, so check they match your lobby. Never carry currency or rewards in it; send an id and read the truth from a DataStore or MemoryStore.
2. Save before you teleport: save the profile and release the session lock (`roblox-data-saves` section 3), then call `TeleportAsync`. If the teleport fails, the player is still here; keep or re-take the lock. No teleport while a save is in flight.
3. Call `TeleportAsync` from the server only (a client button fires a remote; the server checks the player is allowed). Wrap it in `pcall` and retry with a capped backoff (the docs example: 5 tries, 1 s). Also connect `TeleportService.TeleportInitFailed`: it fires when the call succeeded but the player stays, once per player in a group, and hands you a `TeleportOptions` that repeats the same destination.
4. By `Enum.TeleportResult`: `Flooded` wait long (docs example 15 s); `Failure` retry soon; `IsTeleporting` do not send another; `GameFull`, `GameEnded`, `GameNotFound`, `Unauthorized` do not blind-retry, tell the player.
5. Rate: the docs give no per-player number, only `Flooded` ("too many requests recently"). Judgment: one teleport module, one in-flight teleport per player, a short cooldown, group players into one call.
6. Teleports cannot run in Studio. The module logs and simulates in Studio; verify the real hop on a published private test place (`roblox-pitfalls` section 4).

## 6. Matchmaking options

| Option | Fits | Facts and limits (docs) |
|---|---|---|
| Roblox default matchmaking | drop-in public servers, round-based in one place | Skips full, private, reserved and closing servers; scores servers by latency, friends, language, age, device, play history, voice and text chat, occupancy. `Players.PreferredPlayers` is the fill target below the max |
| Custom matchmaking config | public servers that should group by skill, language, device or mode | Creator Dashboard > Configurations > Custom matchmaking. Change signal weights; up to 2 custom signals, 5 player and 5 server attributes per game. Player attributes read a DataStore key; server attributes use `MatchmakingService:SetServerAttribute` (name and value max 50 characters). Preview with mock servers, apply per place |
| Experiments | prove a config helps | Type "Matchmaking": one at a time, up to 3 variants, 100% rollout advised, no code change |
| `MemoryStoreQueue` | fixed-size matches, skill brackets | `AddAsync` with expiration and priority; `ReadAsync` (max 100 items) then `RemoveAsync` before the invisibility timeout (default 30 s). Per queue: 1,000,000 items, 100 MB; value 32 KB; expiration max 45 days. Game request budget: 1000 + 120 x players per minute |
| `MemoryStoreSortedMap` | rating-ordered pools, open-lobby lists | Same size and expiration limits; one map sits on one partition (throttling near 30,000 units per minute, an estimate). Shard hot maps |
| `MessagingService` | wake-ups only ("match ready") | Best effort, typically 1-2 s, may drop. Message 1 kB, topic 1-80 characters. Send 600 + 240 x players per minute per server |

When each fits (judgment): casual drop-in = default; skill spread = custom config, then a matchmaking experiment; fixed N-player matches = queue + lobby + reserved server; parties = party teleport.

Queue pattern (judgment): a lobby server adds each local player as a ticket (user id, rating, expiry). One reader forms a group, makes the GUID and writes it to a sorted map or publishes it with `MessagingService`. A server can only teleport its own `Player` instances, so each server teleports its players with the same `ReservedServerId`. Tickets expire; a missing player means bots, not a stuck match. Studio and live memory stores are separate.

## 7. Server lifecycle

- `game:BindToClose(function(closeReason) ... end)`: bound functions run in parallel and the server shuts down after 30 s even if they have not finished. Teleports are disabled during moderation shutdowns. Skip slow work when `RunService:IsStudio()`. On close: end the round as a no-contest, save every roster player in parallel, start nothing new.
- Published updates: Dashboard > Configurations > Server management > Restart Servers. "Restart only servers with outdated versions" avoids needless kicks; "Delay server restart" gives 1-60 min of bleed-off. Roblox then moves players of an old server together to a server on the new version. `DataModel.ServerRestartScheduled(restartTime, source, attributes)` fires on a delayed restart: stop starting rounds, show a countdown, let the current round finish.
- Own soft shutdown (optional pattern): teleport players to a reserved server and back. Roblox already moves players on a developer update; build this only for extra control, and verify it on a published test place.
- Server size: more players cost more replication and bandwidth. The docs give no per-player figure. Fill the cap with bots, read the MicroProfiler Network view on a phone, and size the cap to the mode (`roblox-engine-2026` performance budgets).

## 8. Leaderboards and match results

| Need | Use |
|---|---|
| This server's ranking | A `leaderstats` folder (lowercase) on each `Player` with value objects; the server writes them. Shows in the "Here" view |
| Friends and Global over time | An `OrderedDataStore` registered in Creator Hub. Documented as beta (devforum 4832224): one active persistent leaderboard per experience, one numeric score per player, user id in the key. Your game writes scores; the platform only reads them |
| Results and rating | The server computes at Results and writes once, with the match GUID as an idempotent record id, so a retry cannot award twice. Ratings go to a DataStore, never only to MemoryStore (`roblox-data-saves`). Write scores at match end, not on every point; limits in `roblox-data-saves` section 7 |

## 9. Testing

- Studio: choose Server & Clients, set up to 8 clients, press F7 to run the loop with real players. Party Simulator fakes parties. `StudioTestService` scripts multi-client runs, joins and disconnects (Studio only). Network Simulator adds latency.
- Teleports: publish a private test place (separate universe or restricted access) and use separate DataStore names in Studio (`roblox-pitfalls`).
- Failure paths to run:

| Case | Expected |
|---|---|
| Leave during Waiting, Intermission, Round, Results | Roster updates, win re-checked, no error, no stuck timer |
| Last or only opponent leaves mid-round | Round ends (cancelled or win, per the brief), no rating loss, back to Waiting |
| Join mid-round | Spectates; not in the roster |
| All die together | Draw |
| One player alone | Bots fill after the wait; loop completes |
| Server restart mid-round | `BindToClose` saves all within 30 s; no double award |
| Teleport fails (bad place id, forced error) | Retry with backoff, player told, still in lobby, data intact |
| One of 4 never arrives | Match starts after the join timeout with a bot |
| Spoofed teleport data | Ignored; truth read from storage |

## 10. Done when

Decision table filled; state machine runs Waiting to Results and back with one player and with a full server; leave, draw and shutdown cases pass; teams and spawns match the brief; teleports (if any) work on a published test place with retry and saved-before-teleport data; results are written once; evidence is in the PR or notes.
