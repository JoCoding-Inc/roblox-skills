---
name: roblox-data-saves
description: "Use when planning, writing or reviewing Roblox player saves: what to store, DataStore layout, session locking, ProfileStore, retries, periodic and shutdown saves, schema versions, migrations, trading, leaderboards, badges, test cases, storage limits and deletion rules."
when_to_use: "Also when a design adds currency, inventory, progression, trading, a leaderboard, badges or settings; when data is lost, rolled back or duplicated; before a release that changes the save shape, reorders items, zones or tiers that saves refer to, or recomputes a stored value; when choosing between DataStore, MemoryStore and a module such as ProfileStore."
last_reviewed: 2026-11-03
sources:
  - https://create.roblox.com/docs/cloud-services/data-stores/best-practices
  - https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing (session locking)
  - https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits
  - https://madstudioroblox.github.io/ProfileStore/api/ (and ProfileStore.luau source, read 2026-11-03)
  - https://create.roblox.com/docs/players/leaderboards
  - https://create.roblox.com/docs/production/publishing/badges
  - https://devforum.roblox.com/t/4739240 (unified Data Stores budget and 500 MB storage, live 2026-07-29)
  - original (checklists and test cases from our release gates)
---

# Player saves

Saves are the highest-consequence part of a release: a bug here loses real players' progress and purchases. A failed or unverified save gate means NOT READY (`roblox-release-automation` section 4a).

## 1. Plan the data (planning stage)

1. List what must persist: currencies, inventory, progression, settings, purchase records, "seen" flags (cinematics, tutorial). Everything else is session-only.
2. Give the save a **version number** from day one: `{version = 1, ...}`.
3. Decide who may change each field: only the server writes economy fields; the client never sends values to save.
4. Decide the loss budget: how much progress may be lost on a crash (usually the last periodic save interval). Write it in the brief.

## 2. Layout (docs: best practices)

- Few data stores, many keys. One `PlayerData` store, one key per player such as `User_{UserId}`. Never key by display name.
- One key per player when the record fits the 4 MB object limit, so related values update atomically and rollbacks are simple. Split into a few deterministic keys only when access patterns differ or size/throughput limits approach. Keep data that must change together in the same key.
- Prefixes (`User_123/Profile/Warrior`) group keys and make them listable. Static key patterns also let Roblox's automated right-to-be-forgotten processing find player data.
- Third-party modules (for example ProfileStore) are fine; check ownership, maintenance and how to read your data without the module. DataStore2 is legacy and ProfileService's README says it is no longer supported: do not use either for new games.
- Temporary, fast-changing data (matchmaking, cross-server state, cooldown tables) goes in MemoryStores, not DataStores.

### 2a. ProfileStore cheat sheet (default module; API from its docs and source, 2026-11-03)

Wally `lm-loleris/profilestore` 1.0.3 (no GitHub releases; last commit 2025-07-31). Its API differs from ProfileService: do not mix the two.

| Call | Use |
|---|---|
| `ProfileStore.New(name, template)` | One store per save type; `template` is the default `Data` for new profiles |
| `store:StartSessionAsync(tostring(userId), {Cancel = fn})` | Session-locked load. Returns **nil** on a conflict or timeout: kick the player, never play on defaults. `Cancel` returns true once the player has left |
| `profile:AddUserId(userId)` then `profile:Reconcile()` | Right-to-erasure link, then fill missing fields from the template |
| `profile.OnSessionEnd:Connect(...)` | Session lost (other server, shutdown): kick the player |
| `profile:Save()` | Extra save at critical moments (after a developer product grant). Costs one `UpdateAsync` |
| `profile:EndSession()` | On `PlayerRemoving`; skipping it keeps making DataStore requests |
| `store:MessageAsync(key, msg)` + `profile:MessageHandler(fn)` | Guaranteed delivery to an offline or other-server profile (gifts, trade payouts); 2 `UpdateAsync` per message |
| `store:GetAsync(key)` / `store:VersionQuery(...)` / `store:RemoveAsync(key)` | Read without a session, roll back a version, erase |
| `store.Mock` | Same API, isolated in-memory store for Studio and tests |

- Autosave is every **300 s** (`AUTO_SAVE_PERIOD` in the source). That is the crash-loss budget unless you call `Save()`; write it in the brief.
- Change `profile.Data` only while `profile:IsActive()` is true and without yielding in between.
- `{Steal = true}` bypasses the session lock: debugging only.

## 3. Runtime pattern

1. **Load once** when the player joins; keep a server-local copy and change that during play. Do not write on every change.
2. **Session lock:** write a lock to the key atomically on first read so only one server owns the data. Without it, a player who hops servers can have an old copy saved over a new one. A module such as ProfileStore does this for you.
3. **Save** periodically (staggered with a random start offset so servers do not hit the limits together, and shorter than any lock expiry), on leave, on server shutdown (`game:BindToClose`), and at critical points such as completing a purchase.
4. **Prefer `UpdateAsync`** when a write depends on the current value or several servers may write the key; use `SetAsync` for new keys or values that ignore the old one.
5. **Retry** transient failures inside `pcall` with capped exponential backoff plus jitter. Retry in order per key (an old retry must not overwrite newer data). A failed call may still have written: design writes so repeating them is safe.
6. **If the load fails, do not play on an empty profile.** Kick the player with a message, or run read-only; never save a default record over their real data.
7. Hot shared keys that many servers read can be sharded into copies (`Weather_1..3`) with random start delays; this fixes read throttling only.

## 4. Schema changes and migrations

- Each release that renames, retypes, reorders or recomputes existing saved data bumps `version` and adds a migration step in `migrate(data)` that upgrades older records on load, one step at a time. Guard each step with the version it fixes (`if data.version < N then ... data.version = N end`). A step that recomputes a derived field (for example a level from total XP) without that guard rewrites every live save on any version bump.
- Missing fields get defaults on load (`reconcile`), never on save. A purely additive field with a constant default needs no version bump and no step: add it to the template.
- Table keys inside a saved record are stable ids, never array positions. A table key that is a list index or tier number breaks when entries are reordered or inserted: append only, or key by stable string id and migrate old records once. Content tables use the same ids (`roblox-engine-2026` section 1).
- Test a migration against a saved sample of the old shape before release; keep the old data in versions (do not create a new key per revision; only the latest version counts toward storage).
- Never rename a DataStore key pattern in the same release as a migration.

## 5. Purchases and saves

- Grant the purchase, save it, then return `PurchaseGranted` from `ProcessReceipt` only after the save succeeded; store the receipt id so a retry does not grant twice (`roblox-design-and-launch` section 2).

## 5a. Trading (two players)

- Server only. Both players must be in the same server with active sessions. Re-check both inventories at commit time, not at offer time.
- Commit both sides in one step with no yield: check `IsActive()` on both profiles, then move items and currency in both `Data` tables in the same code block (the ProfileStore docs name this the trading pattern). Then `Save()` both.
- Cross-server or offline gifts: `MessageAsync`, not MessagingService (which can drop messages).
- Log every trade (ids, items, time) for support and rollback; add a cooldown and value-ratio limits against scam and dupe abuse.
- Raw DataStores cannot update two keys atomically; without ProfileStore, use a session-locked layout and an escrow record that is resolved on next load.

## 5b. Leaderboards and badges

| Need | Use | Notes |
|---|---|---|
| In-server ranking | `leaderstats` Folder (exact lowercase name) with `IntValue`/`NumberValue` children under the Player | Session only; values come from the save |
| Persistent ranking (Friends, Global tabs of the PlayerList) | `DataStoreService:GetOrderedDataStore(name)`, one numeric score per player keyed by user id, registered in Creator Hub | **Beta** (since 2026-08-26): one active persistent leaderboard per experience. Your server writes the scores; Roblox only reads them. Validate scores server-side |
| Custom top-N board | `OrderedDataStore:GetSortedAsync(false, pageSize)` | Cache the result and refresh every few minutes; never per player join |
| Badges | `BadgeService:AwardBadgeAsync(userId, badgeId)` in `pcall`, server only; check `UserHasBadgeAsync` / `CheckUserBadgesAsync` first and `GetBadgeInfoAsync().IsEnabled` | Rate limit 50 + 35 x players per minute. 5 free badges per game per 24 h, then 100 Robux each. A badge is a progress funnel signal (`roblox-market-research` reads others' award counts) |

Keep the save as the source of truth: a leaderboard or badge is a view of saved progress, never the other way round. Round-based scoring lives in `roblox-match-flow`.

## 6. Tests (evidence for the release gate)

| Case | Expected |
|---|---|
| Join, change values, leave, rejoin | Values kept |
| Kill the server mid-session (shutdown) | Last save point kept, no corruption |
| Join twice quickly from two clients or servers | One session owns the data, no duplication |
| Simulate DataStore failure (wrap calls to error) | Player is told, nothing overwritten |
| Old-version record | Migrates, no field lost; a current-version record passes through `migrate` unchanged |
| Purchase then leave before the periodic save | Purchase still present after rejoin |
| Studio: enable Studio Access to API Services on test places only | Use a test place, never the live data; never point a scratch place at the live game with `DataModel:SetPlaceId` / `DataModel:SetUniverseId` (`roblox-pitfalls` section 4) |
| ProfileStore game: run the cases above against `store.Mock` in Studio, then once on a test place | Same results; no live keys touched by Mock |
| Trade: one side leaves or the server shuts down mid-trade | Both sides whole or both sides done, never one |

## 7. Limits, operations, privacy

- Read `error-codes-and-limits` before quoting numbers; limits change. Budget requests per server and per game. Since 2026-07-29 in-game and Open Cloud requests share **one per-experience budget** per request type (base 300 + CCU multiplier per minute), so an Open Cloud script can throttle live servers: rate-limit it, and use `DataStoreService:SetRateLimitForRequestType` / `GetRequestBudgetForRequestType` in game.
- Storage limit: 500 MB + 1 MB x lifetime users, measured on the compressed latest version of each key.
- Watch the Data Stores observability dashboard and set alerts for sustained failures and storage growth. Delete test data when testing ends; a deleted store has a 30-day restore window.
- Player data must be deletable: use static key patterns and configure automated right-to-be-forgotten processing, or the right-to-erasure webhook for custom schemas.
