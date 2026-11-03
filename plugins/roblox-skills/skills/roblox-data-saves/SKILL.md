---
name: roblox-data-saves
description: "Use when planning, writing or reviewing Roblox player saves: what to store, DataStore layout, session locking, retries, periodic and shutdown saves, schema versions, migrations, test cases, storage limits and deletion rules."
when_to_use: "Also when a design adds currency, inventory, progression or settings; when data is lost, rolled back or duplicated; before a release that changes the save shape; when choosing between DataStore, MemoryStore and a module such as ProfileStore."
last_reviewed: 2026-11-03
sources:
  - https://create.roblox.com/docs/cloud-services/data-stores/best-practices
  - https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing (session locking)
  - https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits
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
- Third-party modules (for example ProfileStore) are fine; check ownership, maintenance and how to read your data without the module. DataStore2 is legacy: do not use it for new games.
- Temporary, fast-changing data (matchmaking, cross-server state, cooldown tables) goes in MemoryStores, not DataStores.

## 3. Runtime pattern

1. **Load once** when the player joins; keep a server-local copy and change that during play. Do not write on every change.
2. **Session lock:** write a lock to the key atomically on first read so only one server owns the data. Without it, a player who hops servers can have an old copy saved over a new one. A module such as ProfileStore does this for you.
3. **Save** periodically (staggered with a random start offset so servers do not hit the limits together, and shorter than any lock expiry), on leave, on server shutdown (`game:BindToClose`), and at critical points such as completing a purchase.
4. **Prefer `UpdateAsync`** when a write depends on the current value or several servers may write the key; use `SetAsync` for new keys or values that ignore the old one.
5. **Retry** transient failures inside `pcall` with capped exponential backoff plus jitter. Retry in order per key (an old retry must not overwrite newer data). A failed call may still have written: design writes so repeating them is safe.
6. **If the load fails, do not play on an empty profile.** Kick the player with a message, or run read-only; never save a default record over their real data.
7. Hot shared keys that many servers read can be sharded into copies (`Weather_1..3`) with random start delays; this fixes read throttling only.

## 4. Schema changes and migrations

- Each release that changes the save shape bumps `version` and adds a migration function `migrate(data)` that upgrades older records on load, one step at a time.
- Missing fields get defaults on load (`reconcile`), never on save.
- Test a migration against a saved sample of the old shape before release; keep the old data in versions (do not create a new key per revision; only the latest version counts toward storage).
- Never rename a key pattern in the same release as a migration.

## 5. Purchases and saves

- Grant the purchase, save it, then return `PurchaseGranted` from `ProcessReceipt` only after the save succeeded; store the receipt id so a retry does not grant twice (`roblox-design-and-launch` section 2).

## 6. Tests (evidence for the release gate)

| Case | Expected |
|---|---|
| Join, change values, leave, rejoin | Values kept |
| Kill the server mid-session (shutdown) | Last save point kept, no corruption |
| Join twice quickly from two clients or servers | One session owns the data, no duplication |
| Simulate DataStore failure (wrap calls to error) | Player is told, nothing overwritten |
| Old-version record | Migrates, no field lost |
| Purchase then leave before the periodic save | Purchase still present after rejoin |
| Studio: enable Studio Access to API Services on test places only | Use a test place, never the live data |

## 7. Limits, operations, privacy

- Read `error-codes-and-limits` before quoting numbers; limits change. Budget requests per server and per game; Open Cloud scripts share the game's request budget, so rate-limit them.
- Watch the Data Stores observability dashboard and set alerts for sustained failures and storage growth. Delete test data when testing ends; a deleted store has a 30-day restore window.
- Player data must be deletable: use static key patterns and configure automated right-to-be-forgotten processing, or the right-to-erasure webhook for custom schemas.
