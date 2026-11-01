---
name: roblox-engine-2026
description: "Use when writing or reviewing Roblox game code and UI in 2026: task scheduler, deferred events, Parallel Luau, native codegen, strict types, StreamingEnabled settings, flex layouts and UI styling, Input Action System, mobile/console rules, performance budgets, remote security, platform-integrated chat."
when_to_use: "Also when code uses wait/spawn/delay or PhysicsService collision groups, when a UI breaks on phone or console, when memory or crash rates are high, when adding remotes, ProximityPrompts or purchases, or when an old tutorial's pattern might be outdated."
last_reviewed: 2026-11-01
sources:
  - https://create.roblox.com/docs/scripting (scheduler, events/deferred, multithreading, locations, security, transparent-batching)
  - https://create.roblox.com/docs/luau (type-checking, native-code-gen)
  - https://create.roblox.com/docs/ui (list-flex-layouts, styling, size-modifiers, in-experience-containers)
  - https://create.roblox.com/docs/input (input-action-system, mobile, gamepad)
  - https://create.roblox.com/docs/workspace/streaming
  - https://create.roblox.com/docs/performance-optimization
  - https://create.roblox.com/docs/chat/platform-integrated-chat
  - https://create.roblox.com/docs/projects/teleport
---

# Modern engine practices (docs state 2026-10-29, Studio 0.745)

Complements roblox-brain (`roblox-luau`, `roblox-gui`, `roblox-performance`, `roblox-security` style skills). Where this file and an older tutorial disagree, this file follows the current docs.

## 1. Code

- **Scheduler:** use `task.spawn` (runs now), `task.defer` (end of this resume point), `task.delay`, `task.wait` (about one Heartbeat). `wait`, `spawn`, `delay` are legacy and slower.
- **Deferred events:** `Workspace.SignalBehavior = Deferred` is recommended and used by template places. Handlers run later, so code like `fire(); return flag` breaks. Re-entrancy limit 10. `Disconnect()` drops pending handlers, `Destroy()` does not. Prefer `signal:Once()`.
- **Script layout:** one `RunContext=Client` Script in ReplicatedStorage, one `RunContext=Server` Script in ServerScriptService, everything else ModuleScripts with a `start()`. Do not put scripts in Workspace; use CollectionService tags. A new Script defaults to `Legacy` RunContext, so set it.
- **Types:** use `--!strict` (modes: `--!nocheck`, `--!nonstrict`, `--!strict`; default is `Workspace.LuauTypeCheckMode`). Generics and `typeof()` are supported.
- **Parallel Luau:** put code under `Actor`; `task.desynchronize()` / `task.synchronize()` or `Signal:ConnectParallel`; messaging with `Actor:SendMessage` / `BindToMessage`; shared data in `SharedTable`. No `require()` while desynchronized; instance writes need a serial phase; `Terrain:WriteVoxels` is serial-only. Many small actors (64+ is fine); scripts in one actor run serially.
- **Native codegen:** `--!native` or `@native` for numeric and `buffer` loops on the server. Annotate `Vector3` params; avoid `getfenv/setfenv`; breakpoints disable it. Check size with `debug.dumpcodesize()`.
- **Batching:** start `GetProductInfoAsync`, `UserOwnsGamePassAsync`, `GetItemDetailsAsync` calls concurrently with `task.spawn` and they batch.
- **Collision groups:** `PhysicsService` is deprecated and forwards to Workspace. Use `workspace:RegisterCollisionGroup(name)`, `workspace:CollisionGroupSetCollidable(a, b, false)` and `BasePart.CollisionGroup`.
- **Physics:** adaptive timestepping runs at 60/120/240 Hz; use Fixed 240 Hz for racing or tanks. `CollisionFidelity` Precise is the most expensive; use Box or Hull. Raycast max length 15,000 studs.
- **Experimental/beta (do not ship without a fallback):** Server Authority (`Workspace.AuthorityMode=Server`, needs NextGenerationReplication, Input Action System, Deferred signals, fixed simulation, streaming), script capabilities (`Sandboxed`), Input Action Manager, `InputActionLabel`, persistent leaderboards, video upload.
- `Player.UserId` is still the global id; `Player.User` exists but scoped ids have not rolled out.

## 2. UI

- **Layouts:** `UIListLayout` has flex (`HorizontalFlex`/`VerticalFlex`, `ItemLineAlignment`, `UIFlexItem.FlexMode` Fill/Grow/Shrink/Custom; slightly more expensive). Also `UIGridLayout`, `UITableLayout`, `UIPageLayout`. A `UIAspectRatioConstraint` or `UISizeConstraint` overrides layout sizing. `AutomaticSize` turns `Size` into a minimum. To reverse order negate `LayoutOrder`.
- **Styling system:** `StyleSheet` (tokens as `$Token` attributes, themes), `StyleRule` selectors (class, `.tag`, name, GuiState, `@query`), `StyleLink` on a ScreenGui (one sheet per tree), `StyleDerive`. Built-in queries `@ViewportDisplaySizeSmall/Medium/Large` (phone and tablet = Small, laptop = Medium, console = Large) and `@PreferredInputTouch`. Use it for per-device scale instead of hand-written branching.
- **Effects:** `UIShadow`, `UIGradient` (Radial/Elliptical/Conical are beta), 9-slice via `ScaleType=Slice` + `SliceCenter`. `RichText=true` for markup (localisation strips tags).
- **Safe area:** `ScreenGui.ScreenInsets` defaults to `CoreUISafeInsets`, which already clears the top bar and cutouts. Add manual insets only with `None`/`DeviceSafeInsets` or `IgnoreGuiInset`.
- **SurfaceGui/BillboardGui buttons** work only when parented under `PlayerGui` (use StarterGui); a SurfaceGui button also needs the part's `CanQuery=true`.
- **Input:** prefer the Input Action System (`InputContext`, `InputAction`, `InputBinding`; set `Workspace.PlayerScriptsUseInputActionSystem`) with one binding each for gamepad, keyboard/mouse and touch. Use `UserInputService.PreferredInput`, not `TouchEnabled` (true on touch laptops). Show per-device hints with `InputActionLabel` or `GetImageForKeyCode`.
- **Mobile:** landscape by default (`ScreenOrientation`); keep UI out of the default thumb zones and relative to the jump button; `UITextSizeConstraint.MinTextSize` not below 9. 75 percent scale looks huge on a 4K TV, so adapt with display-size queries. Test with the Device Simulator and the Controller Emulator, but check memory on real devices.
- **Fonts:** `Arial`, `ArialBold`, `Gotham`, `GothamMedium`, `GothamBold` and `GothamBlack` are removed and map to Montserrat. Pick a current font; check glyph coverage for Korean text before use.

## 3. World, streaming, memory

- `StreamingEnabled` is on for new places. Recommended: `ModelStreamingBehavior=Improved`, `StreamingIntegrityMode=PauseOutsideLoadedArea`, `StreamOutBehavior=Opportunistic`, `PredictiveStreamingMode=Enabled`, `EnableSLIMAvatars`. `StreamingMinRadius` 64 and `StreamingTargetRadius` 1024 are defaults. Set `Model.LevelOfDetail=SLIM` on static models (keep each under about 64 cubic studs). Persistent models are rare; wait for `Workspace.PersistentLoaded`.
- Budgets: frame 16.67 ms at 60 FPS. Server memory is 6.25 GiB + 100 MiB per peak player; stay under 50 percent. Client crash rate above 2-3 percent needs investigation. About 65 percent of a typical game's players are on Android, mostly 2-8 GB RAM; test on a low-end device (Infinix Smart 9, Moto G05, Oppo A18, Fire HD 10) for 10-15 minutes. Example target from the docs: under 1,000 draw calls and 1,000,000 triangles (measure your own baseline).
- Textures: memory grows with resolution (1024 is 4x a 512). Most images at most 512; minor ones under 256. File size does not change memory.
- Same MeshId + same texture = one draw call. Never import a whole map as one file; use packages; tint with `SurfaceAppearance.Color`.
- Keep ReplicatedStorage lean; large content in ServerStorage. Tween on the client, never the server. NPCs: disable unneeded Humanoid states, use `AnimationController` for static NPCs, pool them, update `Motor6D.Transform`.
- Particles: 400 per second (100 on mobile), lifetime max 20 s. Highlights: cap 255, first costs up to 1 ms on mobile. Shadows are off below quality level 4.
- Tools: MicroProfiler (Ctrl+Alt+F6 on device), Developer Console (F9), Shift+F2/F3/F5 stats, `debug.profilebegin/profileend`, Assistant skills `rbx-perf-profiling` and `rbx-scene-analysis`. Enable `Workspace.PlayerCharacterDestroyBehavior` to avoid leaking Player/Character objects.

## 4. Security checklist for every remote and prompt

1. Context: is the player alive, close enough, allowed?
2. Type: `typeof(x) == "Instance"` and `IsDescendantOf` the expected container (tables can pose as Instances).
3. Value: `math.isfinite` (reject NaN/inf), range-check numbers, cap string length and table size, `utf8.len`.
4. Rate-limit with a token bucket or cooldown per player.
5. `ProximityPrompt`, `ClickDetector` and `DragDetector` events can be fired by exploiters from any distance; only `Triggered` has a server distance check, so verify distance yourself.
6. Purchases: grant in `ProcessReceipt`; never trust `PromptProductPurchaseFinished`.
7. Unanchored parts are exploitable through network ownership; anchor them or set the owner.
8. Remotes cannot pass functions; metatables are stripped; `UnreliableRemoteEvent` drops payloads over 1,000 bytes.
9. Teleports: use server `TeleportAsync` (client `Teleport` is deprecated), set Access Control for Places to "Secure within universe only", treat teleport data as client-visible.
10. `Player.DeviceTrustLevel` (Pending/Unknown/None/Standard/Full) is a server-side signal and always Pending in Studio.

## 5. Chat, voice, platform

- Platform-integrated chat (`TextChatService.PlatformIntegratedChat`, Studio-only toggle) becomes **required for all games in May 2027**. When on, `TextChatMessage.Text`/`Translation` return empty, and `PrefixText`, `OnIncomingMessage` and `Player.Chatted` are unsupported. Move to `TextChannelWindow` and `TextChatCommand` now.
- Voice chat: experiences up to 100 players, ID-verified 13+ users in supported countries. Cross-server chat about 200 users per channel.
- Matchmaking: up to 5 server attributes and 5 player attributes per game.
- Audio import: under 20 MB, under 7 minutes, 48 kHz or less; free imports per 30 days 2,000 (ID verified) or 100 (unverified).
- Data/Memory/HTTP limits: see `roblox-studio-ai-tools` and the Open Cloud numbers in `roblox-pitfalls` section 1; DataStore value 4 MB, keys 50 characters, 25 MB/min read and 4 MB/min write per key.
