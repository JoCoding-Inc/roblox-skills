---
name: roblox-fun-effects
description: "Use when adding or reviewing any animation, particle effect, aura, trail, title, roll or egg-hatch reveal, rarity look, mutation or variant, level-up or rebirth celebration, emote, finisher or kill effect, or rare-drop announcement in a Roblox game. Decides what the effect rewards, who sees it, how it escalates and how it pays off in a clip, so it adds fun instead of only working. Also when an effect 'works but feels like nothing', a roll or reveal is boring or too long, when planning rarity tiers, cosmetics or auras, when players should be able to show off, when asked for 'more juice' or 'make it satisfying', or in roblox-game-pipeline stage 4 (Feel cards). Pair with roblox-feel-audio-vfx (how to build it and phone budgets), roblox-cinematics (long scenes), roblox-design-and-launch section 2 (paid random odds)."
last_reviewed: 2026-11-12
sources:
  - https://create.roblox.com/docs/en-us/production/game-design/design-for-roblox.md (fun first; players want their avatars seen)
  - https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design.md (feedback)
  - https://create.roblox.com/docs/en-us/production/monetization/paid-random-items.md (updated 2026-11-02)
  - https://create.roblox.com/docs/en-us/reference/engine/classes/CaptureService.md, SocialService.md, MessagingService.md, ParticleEmitter.md, enums/HapticEffectType.md
  - https://create.roblox.com/docs/en-us/effects/particle-emitters.md (flipbooks switch off on low memory)
  - https://create.roblox.com/docs/en-us/resources/modules/emote-bar.md (mega emotes)
  - community patterns read 2026-11-03 (RNG aura games, mutation games, DevForum feedback threads t/2880624 and t/3424276)
  - talks Juice it or lose it (Jonasson and Purho) and The art of screenshake (Nijman); Sakurai hitstop column (fan translation)
  - https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html
  - original (tiers, timings and budgets are judgment, not measured)
---

# Fun effects: reasons, tiers, reveals, showing off

An effect that only works is decoration. Spend effect budget where it rewards something, grows with rarity or effort, can be seen by other players and makes a short clip. Roblox's own design guide puts fun first and notes that players want their avatars to be seen. If the core loop is flat, effects will not save it: prove the loop first (`roblox-game-pipeline` section 6b A). All numbers below are judgment: tune them in a user playtest (`roblox-game-pipeline` section 7a).

## 1. Fun card (before building any effect longer than a 0.3 s tick)

```
Effect / trigger : <name> / <one game event>
Rewards          : <the action, luck, effort or milestone it celebrates>
Escalates by     : <tier, combo or repeat count> -> <what grows: size, color, count, sound, time>
Seen by          : self | nearby | whole server | other servers | clip
Payoff           : <what the player gets beyond pixels: index entry, title, multiplier, display slot, clip>
Clip test        : does a 5 s muted phone clip make sense with no explanation? y/n
Cost             : emitters and lights per player; 20 players at once OK on a low-end phone? y/n
Fair             : paid random? odds shown; free path; reduced-effects setting
```

No "Rewards" or no "Payoff" line: cut it or shrink it to a tick. Effects on every repeated action get the smallest budget; big ones are for rare moments. Write the cards in `docs/brief.md` under "Moments and feel".

## 2. Principles (from game-feel talks; opinion, widely used)

- **Anticipate, hit, settle:** a short wind-up, a sharp peak, a follow-through. Squash and stretch on the peak.
- **Hold the peak:** a few frames of freeze or silence before the burst makes it land.
- **Escalate:** combos, streaks and rarer results get bigger, louder and longer, but slower than the odds (about 1.5x per tier, not 10x).
- **Permanence:** something stays for a moment (debris, a mark, a trophy on a shelf).
- **Read through 3 channels:** color + shape or size + sound. Never color alone.
- **A reason not to spam:** cooldowns and recoil make each press mean something.

## 3. Tier ladder (one table drives rolls, odds UI, labels and effects)

| Tier | Example odds | Look | Effect | Reveal | Seen by |
|---|---|---|---|---|---|
| 1 Common | 1 in 1-10 | grey, white | none | 0.3-0.6 s | self |
| 2 Uncommon | 1 in 10-100 | green | small pop (5-10 particles) | 0.6-1 s | self |
| 3 Rare | 1 in 100-1k | blue | burst + rim glow | 1-1.5 s | self, nearby |
| 4 Epic | 1 in 1k-10k | purple | burst + 1 aura emitter | 1.5-2.5 s | small toast |
| 5 Legendary | 1 in 10k-1M | gold | burst + aura + trail + camera kick | 2.5-4 s | server toast |
| 6 Mythic | 1 in 1M+ | animated gradient, unique shape | full sequence + unique sound | 4-6 s | server banner |
| 7 Top | above a set line | unique per item | short scene (`roblox-cinematics` rules) | up to 8 s | all servers (optional) |

- Store the ladder in one ModuleScript; the roll, the odds UI, rarity labels (`roblox-ui-genre-studs` section 6) and the effects all read it.
- For characters, towers and units, a tier also changes shape and size, not only color (`roblox-character-design` section 4).
- Low tiers are seen thousands of times: keep them short.
- Settings: "skip reveal below tier N" (default 3) and "hide announcements below tier N". Popular RNG aura games ship both (community wikis).
- Show a roll counter and a collection index; never auto-equip a worse item.

## 4. Reveal sequence (roll, hatch, crate, spin)

| Beat | Time | What |
|---|---|---|
| 0 Press | under 0.1 s | click sound, button squash; same for every tier |
| 1 Anticipate | 0.3-3 s by tier | container shakes or charges, pitch rises, light grows; tier color may leak in the last 0.3 s |
| 2 Hold | 0.1-0.25 s (tier 4+) | brief freeze or silence (`ParticleEmitter.TimeScale` to 0, duck the music) |
| 3 Burst | 0.2-0.6 s | one `ParticleEmitter:Emit(n)`, small FOV kick (+4 to +8 for 0.15 s), a white flash of 0.15-0.25 s whose opacity grows with the tier (0.14 at the lowest to 0.5 at the top in our test place, judgment), rings, rays and a spray behind the result |
| 4 Show | 1-2.5 s | name, tier color, "1 in N", model spin, NEW badge, what it does; one primary button |
| 5 Settle | 0.3-0.5 s | stats count up, index fills, equip offered only if better |
| 6 Share | tier 5+ | clip and share buttons, server toast (section 6); never blocks the next roll |

- Timing in top games, read from tagged clips (RoDesigner motion library, 2026-11-12; clips at 4 to 15 fps, so 0.07-0.25 s of error): egg hatch build-up before the flash median 0.77 s, range 0.37-1.3 (5 clips, 2 games); full-screen flash 0.15-0.25 s (4 clips, 2 games), white in 6 of the 7 hatch and roll clips that flash; hold on the result median 1.1 s, range 0.5-1.4 (5 clips, 2 games); a whole ordinary hatch 2.5-4.3 s until the HUD is back (3 clips, 1 game); a top-rarity title held 3 to 4.5 s (2 clips, 1 game). The HUD is hidden during the hatch in both phone clips that show it. Shake, hit stop, flash opacity and sound are not recorded in the tags.
- A worked build of the beats (test place of `roblox-feel-audio-vfx` section 3b; judgment, accepted by the owner in Studio, 2026-11-12): the container wobbles harder and drifts, ticks speed up and rise in pitch, thin rings close inward, the stage zooms from 1 to 1.16, and the tier colour leaks only in the last third; the top two tiers darken the screen and hold 0.45 s with a blur; the burst is a flash, two rings, a spray, rays and a card that pops with a shine; from the third tier a title stamps in, and the top tier's title runs a colour gradient. After the UI closes the world reacts where other players can see it: a ground ring from the second tier, a light pillar and an aura (3 s plus 1 s per tier rank) from the third, a toast for the top two tiers, fireworks for the top one. A spinning reel of tier names during the build is a tease by nature: free rolls only (section 10).
- The server rolls and saves before beat 0; leaving mid-reveal never loses the item. The client plays the presentation from the result id, driven by the tier table, not one script per tier. The server refuses the next roll until the minimum reveal time has passed, or a script skips the reveal and farms (`roblox-engine-2026` section 4, item 13).
- When the client must not learn the result early (a timed or shared reveal), the server rolls and saves at the open, sends a `revealAt` time on `workspace:GetServerTimeNow()`, refuses the next action until then, and sends the result at that time. The client schedules the roulette against `GetServerTimeNow()` and lands when the result event arrives; teasers in the wait never fake a near miss (section 10) (field note, 2026-11-11).
- Show the result at a showcase size, not its gameplay size. At its in-world slot size a result was about 100 px tall from a 50-stud default camera and got lost under its own name plate; one game used a fixed showcase height that grows with the tier, 6.5 to 10 studs (field note, 2026-11-11). On a 667 x 375 phone a world plate above the floating result ran under the top bar from the usual camera, so put the plate beside the result on phones (field note, 2026-11-11; reserved zones in `roblox-ui-layout` section 1).
- **Color ladder** (honest anticipation): in beat 1 the container steps up one tier color per pulse (white, blue, purple, gold, ...) with rising pitch and stops at the result's tier. It never passes the real tier and drops back (a near-miss tease, section 10), so the ladder's length tells the tier and long anticipation comes only with rare results.
- Effect caps (pools, a maximum of live rigs) apply to other players' effects. The local player's own reveal always gets one (reserve or force a slot), or a busy server shows them nothing (field observation, 2026-11-04).
- Review the top tiers first: they are the clip moments and the least seen in testing. Force the result with a Studio-only hook (`roblox-pitfalls` section 3). An effect that only pulls inward (a vortex) read as an empty frame at reveal distance; end it with an outward burst (field observation).
- Tap skips to beat 4, never past the grant. Auto-roll plays the short version below the skip tier.
- Never stack two tier sounds or a tier jingle over the music; duck the music.
- Cosmetic bursts may go over `UnreliableRemoteEvent`; the result itself goes over a `RemoteEvent`.

## 5. Status other players can see

| Type | Rule |
|---|---|
| Aura | Built on each client from a character attribute (tier or item id). At most 2 emitters + 1 trail per player, about 40 live particles per emitter (`Rate` x `Lifetime`), no Highlights, lights only at tier 5+. Distance LOD: full near, 1 emitter mid, off far. It must still read when flipbooks switch off on low-memory phones (docs) |
| Trail | Short `Lifetime`, tier color; doubles as movement feedback |
| Title | BillboardGui text in the tier color over the head; cheapest status; readable at 30 studs |
| Size or shape | Bigger or unique models at higher tiers (pet-size ladders) |
| Display | A pedestal, shelf or base where others can walk up and see what you own and what it is worth |
| Emotes | The Emote Bar module supports mega emotes that grow when several nearby players do the same emote |

- Status is cosmetic and has a free path. It never hides hitboxes, enemies or other players' UI.
- Add a "reduce other players' effects" setting. Test 20 players with the top aura on the low-end phone profile.

## 6. Announcements and clips

- **Server toast:** the server sends `{userId, itemId}` to every client; each client builds the line from its own localized strings and the DisplayName in a ScreenGui. Queue them (about 1 per 5 s, keep 3). `TextChannel:DisplaySystemMessage` only shows to the local player and is not localized, so it is not the main channel.
- **Other servers** (top tier only): `MessagingService` (1 kB per message; 600 + 240 x players sends per minute per server; best effort).
- **Clip:** for tier 5+, the client can call `CaptureService:StartVideoCaptureAsync` at beat 1 (the result is known), `CaptureService:StopVideoCapture` about 3 s after beat 4, then offer `CaptureService:PromptSaveCapturesToGallery` or `CaptureService:PromptShareCapture` (with launch data for the invite link). Recordings stop at 30 s and mute all voices while recording, so make auto-capture a setting, off by default in voice-chat games. Check the class page for beta status before shipping.
- **Link:** the server calls `SocialService:PromptLinkSharingAsync` (server only) with launch data that drops friends next to the sharer.
- Frame the clip: big tier name, one sound, 5-8 s total. Roblox's Moments tab (16+, rolling out by region since 2026-07-28) has no developer API: design for clips, do not depend on it.

## 7. Mutations and variants

- A mutation is a modifier on an item with 3 parts: a look, a number (multiplier or income) and a source (roll, world event or weather, craft or merge).
- It reads in the icon, the world model and the label at once. One mutation per item; extra traits add at most 2 visible layers.
- Tie event mutations to scheduled world events, so players log in for them.
- Set multipliers from your own economy sheet; numbers from guides of other games differ by game and patch.
- Reward a completed set (every item in one mutation) with something visible.
- A paid merge or reroll is a paid random item (section 10).

## 8. Combat flair

- **Hit stop** is presentation on the client: freeze the attacker's and victim's animations (`AnimationTrack:AdjustSpeed(0)`, then restore) and the hit effect (`TimeScale` 0), not the world. Stronger hit, longer stop, with a cap: light 0.04-0.07 s, heavy 0.08-0.14 s, kill 0.15-0.25 s, never over 0.3 s. Use little in fast group fights.
- Pair it with a 0.1 s flash, a 1-2 degree camera kick, a number pop and slight pitch variation; raise pitch and size on combos.
- Layer by importance: a hit, a crit, a kill and a boss kill each add channels, not just size. The per-moment table is in `roblox-feel-audio-vfx` section 3b. Frequent kills use the heavy range above (0.08 s in the test place) and keep the kill range for bosses.
- Budget hit feedback per target per second, not per hit. A white `Highlight` flash tuned for towers with short range (0.09 s, at most every 0.12 s, fill 0.15) left enemies white most of the time once every tower could hit them along the whole path; a soft blink at most 3 times per second per enemy fixed it (field note, 2026-11-11).
- **Finisher or kill effect:** plays only after the server confirms the kill, 2.5 s or less, the killer keeps control (or loses it for 0.5 s at most), cosmetic only. Sell it directly (a pass or bundle) or by crate with odds. Damage and timing rules stay in `roblox-combat-tools`.
- Taunt emotes after a kill: optional and mutable.

## 9. Celebrations (level-up, rebirth, unlock)

- 3-6 s, skippable, never blocks the shop or the next action, no camera takeover (`roblox-cinematics` section 2).
- Show what changed (count-up about 0.45 s), one burst, one sound. Rebirth shows what is kept and the new multiplier; nearby players get a small toast.
- At most one big celebration per about 30 s; otherwise a small tick.
- A level-up that reads as an event (test place, judgment): light pillar and ground ring at the player, an aura for about 2.5 s, a cheer emote, the level stamped in under the top bar, then the stat lines one by one about 0.3 s apart, confetti and one fanfare.
- Reward popup: the chest or source reacts in the world first, then the screen dims, a title stamps in, cards drop in face down about 0.12 s apart, flip one by one about 0.55 s apart with a ring, a spray and a rising note each, and the claim button appears last and breathes; on claim the cards shrink and coins fly to the counter. Top games space reward rows or cards 0.25-0.8 s apart and hold a one-off result title 2-3 s (RoDesigner motion library, 3 and 4 clips, 2026-11-12).
- Small rewards all the time carry the feel between the big ones: pickups that bob, spin and sparkle before they are taken; a note that climbs with each pickup or coin in a run; one merged "+N" at the counter every 0.25 s instead of one per coin; a combo count that grows and warms, with a named streak on quick kills and a short "fever" state at a threshold (judgment).
- Phones: `HapticEffect` with `Enum.HapticEffectType.UIClick` for taps and `Enum.HapticEffectType.GameplayCollision` for impacts, subtle and behind a setting.

## 10. Guard rails

- **Paid random** (eggs, crates, wheels, spin tickets bought with Robux or paid currency, luck boosts, paid rerolls): odds before the spend, built from the roll table, updated while a boost runs; restricted players get a compliant alternative (`roblox-design-and-launch` section 2). Free random rewards need no odds.
- No near-miss teases on paid rolls (showing a rare item, then swapping to a common one) and no fake urgency (judgment: players and parents notice, and the platform bans fake timers). Free rolls can have the richest show.
- **Flashing:** at most 3 flashes per second (WCAG 2.3.1); no full-screen white strobes. A "Reduce effects" setting removes flashes, camera kicks and other players' auras; honor `GuiService.ReducedMotionEnabled` for UI motion.

## 11. Defects players complain about (DevForum feedback on RNG games)

Each is a bug: a reveal that plays long but does not say what you got; rare-item music stacked over the background music; walk animation while standing; no roll counter; auto-equipping a worse item; inventory full after a few rolls; FPS drop during the reveal.

## 12. Done when

| Check | Pass |
|---|---|
| Fun card filled for every effect longer than a tick | yes |
| Tier table drives roll, odds UI, labels and effects | yes |
| Each tier's reveal timed against section 4; skip works and never loses the grant | yes |
| Every tier's reveal captured in Studio through a forced-result hook, top tiers first | yes |
| 20 players with the top aura: FPS stable on the low-end phone profile | yes |
| A 5 s muted clip of a tier 5 result makes sense | yes |
| User playtest (`roblox-game-pipeline` section 7a): "Did you want to show someone?" | yes, notes in `docs/playtests.md` |
