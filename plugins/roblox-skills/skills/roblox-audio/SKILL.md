---
name: roblox-audio
description: "Use when adding sound effects, music or ambience to a Roblox game: an event sound map with stable ids and each cue described in words, mix and starting volumes, buses and ducking with the Audio API (AudioPlayer, AudioFader, AudioCompressor sidechain), loops and music changes, Sound vs the Audio API, phone budgets and loading, sourcing from the Creator Store (licensed catalog, privacy and grants, acquire rules, imports, AI audio) and measuring in Studio. Also when a game is silent or every action sounds the same, audio is too loud, clips, stacks or tires the ear, music restarts on respawn or loops with a gap, a Store sound plays in Studio but not in the live game or in a group-owned game, a Toolbox click inserted a Sound object, when picking ids for UI, reward, egg, boss or music cues, before importing or generating audio, and before calling the audio of a release done. Particles, lighting and the feel checklist stay in roblox-feel-audio-vfx; what a reward escalates to stays in roblox-fun-effects."
last_reviewed: 2026-11-09
sources:
  - https://create.roblox.com/docs/audio/assets (updated 2026-11-06; Creator Store audio, import rules, classification)
  - https://create.roblox.com/docs/audio/objects and /audio/effects (Sound, SoundGroup and SoundEffect discouraged; wiring; ListenerLocation)
  - https://create.roblox.com/docs/reference/engine/classes/AudioPlayer, AudioFader, AudioCompressor, AudioAnalyzer (ranges, pins, GetWaveformAsync)
  - https://create.roblox.com/docs/projects/assets/privacy (grants; game grants are permanent)
  - https://create.roblox.com/docs/generative-AI (responsibility for AI-made content)
  - DevForum staff posts t/1701697 (2022 audio privacy change), t/2980704 (2024-05 public SFX distribution), t/3164792 (2024-09 DistroKid music)
  - Studio MCP search_asset tool schema (read 2026-11-09)
  - field notes from live Creator Store searches and loudness measurements (2026-11-09)
  - original (event map, volumes, ducking values and budgets are judgment)
---

# Game audio: sound map, mix, sourcing

Sound is half the feedback of every action (`roblox-feel-audio-vfx` section 1). Write a sound map with stable ids, wire every cue through buses, play only audio the game is allowed to play, and let a person judge the mix on a phone.

## 0. When to load

- Planning: the music and feel cards of `roblox-game-pipeline` stage 4, and the feedback map in `roblox-feel-audio-vfx` section 1. Fill section 1 below for every row that makes a sound.
- Building: before the first sound goes in, so every cue goes through one sound map and the buses of section 3.
- Shipping: the section 8 checklist, and the audio playtest in `roblox-game-pipeline` section 7a.
- Pair with `roblox-fun-effects` (what a reveal or level-up rewards, tier ladder in section 3, reveal beats in section 4) and `roblox-store-art-pack` section 7 (loading tiers).

## 1. Event sound map

One row per game moment. Keep the event id stable (snake_case) so code, settings, tools and notes refer to the same moment. The game sets one asset id per event, or `false` for silence on purpose. Describe each cue in words before searching: length in ms, bright or dark, pitch contour, single or layered. Lengths and characters below are judgment (common genre practice), not measurements.

| Event id | Cue in words | Bus | Notes |
|---|---|---|---|
| `ui_click` | 30-80 ms, bright, flat, single tick or pop | UI | Every button, the same for every tier |
| `ui_hover` | 20-50 ms, soft, flat, single, about half the click level | UI | PC and console only; touch has no hover |
| `tab_switch` | 50-120 ms, neutral, flat, single soft tick or short swish | UI | |
| `panel_open` | 150-300 ms, bright, rising, whoosh plus pop | UI | |
| `panel_close` | 100-250 ms, neutral, falling, single, softer than open | UI | The mirror of open |
| `toast` | 200-400 ms, bright, rising 2-note chime, single | UI | |
| `error` | 150-300 ms, dark, falling or flat, low buzz or 2 low notes | UI | Must differ from every success cue in pitch direction and tone |
| `not_enough` | 150-300 ms, dark, falling 2-note, softer than `error` | UI | Plays with the price shake, never a purchase sound |
| `purchase` | 300-700 ms, bright, rising, layered (coin or register plus chime) | UI | |
| `equip` | 100-250 ms, neutral, flat, single click (cloth or metal) | SFX | |
| `coin_pickup` | 60-150 ms, bright, high, single ping | SFX | Pitch steps up per pickup in a combo; 2-3 pooled players |
| `count_tick` | 20-50 ms, bright, flat, single tick, very quiet | UI | At most about 15 per second, or leave it off |
| `reward_pop` | 200-500 ms, bright, rising, layered (pop plus sparkle) | SFX | |
| `chest_open` | 400-900 ms, dark into bright, layered (creak or latch, then sparkle) | SFX | Then `reward_pop` |
| `level_up` | 0.8-2 s, bright, rising 3-5 note arpeggio into a held chord, layered | SFX | Duck the music |
| `egg_shake` | 80-200 ms per shake, neutral, wobble or rattle, single | SFX | Repeats faster or higher toward the reveal |
| `egg_reveal` | 300-800 ms, bright, rising, pop plus chime | SFX | Grows with the tier |
| `rare_reveal` | 1.5-4 s, bright, rising build then a hit, layered (riser, impact, sparkle or choir) | SFX | The loudest cue in the game; duck the music |
| `boss_warning` | 1-3 s, dark, low horn or alarm, falling or pulsing, layered | SFX | Duck the music, then switch to `music_combat` |
| `hit` | 50-200 ms, punchy, impact plus body, single or layered | SFX | Positional; random pitch of +-3-5 % |
| `round_start` | 0.5-1.5 s, bright, rising; short beeps, then a higher "go" | SFX | |
| `victory` | 2-5 s, bright, rising, major jingle, layered | Music | Stops or ducks the round music |
| `defeat` | 1.5-4 s, dark, falling, minor, shorter than `victory` | Music | |
| `music_lobby` | 60-180 s loop, calm and bright, mid tempo | Music | Seamless loop (section 4) |
| `music_combat` | 60-180 s loop, tense or driving, faster than the lobby | Music | Seamless loop |
| `ambience_loop` | 20-60 s loop, wind, crowd or machines, quiet | SFX | Per area; positional or global |

Rules (judgment):
- One cue per event. Only very frequent cues (hits, footsteps, coins) get 2-3 takes or random pitch; never ten variants.
- Rare beats common: the rarer the moment, the longer and louder the cue. Common cues stay short and quiet so they do not tire the ear.
- Never play two tier sounds at once, or a tier jingle over music that is not ducked (`roblox-fun-effects` section 4).
- Silence is a valid value: write `false` in the map so nobody adds a sound there later by accident.

## 2. Mix and volumes (judgment)

- Starting fader volumes: Master 1, SFX 0.7, UI 0.5, Music 0.35. Tune by ear from there.
- Loudness order: rare reveal > rewards and level-up > hits and pickups > UI > music > ambience.
- `AudioPlayer.Volume` and `AudioFader.Volume` both range from 0 to 10 (docs); values over 1 amplify. Keep them at 1 or below, and fix a quiet asset with its own player volume, not with the bus.
- Store assets differ in level: a Roblox UI click peaked at -5.9 dBFS and a ProSoundEffects cue at -14.3 dBFS (field note, 2026-11-09). Set a volume per cue after listening; never expect two assets to match.
- Random pitch of +-3 % (`PlaybackSpeed` 0.97-1.03) on repeated cues hides the repeat. `PlaybackSpeed` changes length and pitch together (docs: range 0 to 20).
- Settings: a mute toggle plus Music and SFX sliders that set the bus faders; save them per player.
- Judge on phone speakers with the device volume low, and over 5+ minutes for fatigue (`roblox-game-pipeline` section 7a).

## 3. Buses and ducking (Audio API)

Graph (docs, audio/objects): `AudioPlayer` -> `Wire` -> bus `AudioFader` -> `Wire` -> Master `AudioFader` -> `Wire` -> `AudioDeviceOutput`. A `Wire` joins its `SourceInstance` to its `TargetInstance`; `TargetName` picks the target pin. World sounds go `AudioPlayer` -> `AudioEmitter` on a part, and an `AudioListener` hears them. With SoundService **ListenerLocation** set to Character or Camera, the engine creates the listener and an `AudioDeviceOutput` under `SoundService` at runtime (docs).

Sketch of the 2D buses (untested; written from the docs on 2026-11-09, run it once in Studio before relying on it). It goes in a LocalScript under `StarterPlayerScripts`, which runs once per join, so music survives respawn:

```lua
local SoundService = game:GetService("SoundService")

local function wire(source, target, pin)
	local w = Instance.new("Wire")
	w.SourceInstance = source
	w.TargetInstance = target
	if pin then w.TargetName = pin end
	w.Parent = target
end

local function fader(name, volume, target)
	local f = Instance.new("AudioFader")
	f.Name = name
	f.Volume = volume
	f.Parent = SoundService
	wire(f, target)
	return f
end

local output = Instance.new("AudioDeviceOutput")
output.Parent = SoundService
local master = fader("Master", 1, output)
local buses = { SFX = fader("SFX", 0.7, master), UI = fader("UI", 0.5, master), Music = fader("Music", 0.35, master) }

local cues = {}
local function addCue(event, assetId, bus, volume)
	local p = Instance.new("AudioPlayer")
	p.Name = event
	p.Asset = "rbxassetid://" .. assetId
	p.Volume = volume or 1
	p.Parent = SoundService
	wire(p, buses[bus])
	cues[event] = p
end

local function play(event)
	local p = cues[event]
	if not p then return end -- false or missing in the map: silent on purpose
	p.TimePosition = 0
	p:Play()
end
```

Ducking, two ways:
1. **Tween the Music fader** for scripted moments (`level_up`, `rare_reveal`, `boss_warning`): down to about 40 % of its value over 0.1 s, hold for the cue, back over 0.4-0.6 s (judgment). Simple and predictable.
2. **Sidechain compressor** for loud cues that are not scripted (explosions, hit bursts): wire the music into an `AudioCompressor` on its `Input` pin and the loud bus to its `Sidechain` pin as well, then the compressor output to the Music fader. The compressor lowers the music while the sidechain is loud (docs: `Input` and `Sidechain` pins; `Threshold` -60 to 0 dB, `Ratio` 1 to 50, `Attack` 0.0001 to 0.5 s, `Release` 0.01 to 5 s). Starting values (judgment): Threshold -30, Ratio 4, Attack 0.01, Release 0.4.

## 4. Loops and music

- `AudioPlayer.Looping` loops the whole asset. `LoopRegion` (seconds, inside `PlaybackRegion`) loops part of it, for a track with an intro (docs). `Looped` fires on every loop and `Ended` when playback completes (docs).
- One track per mood (lobby, combat, shop, boss). Change it on a state change (area, round, boss), never per click.
- Crossfade with two players: tween one down and the other up over 0.5-1.5 s, then stop the silent one (judgment).
- Keep music in a client script that does not reset on respawn (the section 3 sketch). Never restart the track when the character dies.
- Seam check: listen to 3 loops, or compare the first and last 50 ms with `GetWaveformAsync` (section 8). A click or gap at the seam means trimming with `LoopRegion` or picking another track.
- Beat sync: `AudioPlayer:Play` takes an optional time scheduled against `SoundService:GetMixerTime()` for sample-accurate starts (docs); useful for rhythm games.

## 5. Sound vs the Audio API

- `Sound`, `SoundGroup` and `SoundEffect` are "now discouraged in favor of" the audio objects (docs, audio/objects). On 2026-11-09 the API reference still lists them with no deprecation message, so old code keeps working.
- New work uses `AudioPlayer` and the graph of section 3. Set `AudioPlayer.Asset`; `AssetId` is deprecated in favor of `Asset` (docs).
- Clicking an audio asset in the Toolbox inserts a `Sound` object (docs). Right-click it and choose Copy Asset ID, then put the id in the sound map instead.
- Use one system per game, so one mute toggle and one set of buses covers every sound (judgment). Search the place for `Sound` objects (Store models can carry them) and convert or remove them.

## 6. Phone budgets and loading

- Under about 20 unique sounds for the first release (judgment; also the `roblox-feel-audio-vfx` section 5 checklist).
- Load in tiers (`roblox-store-art-pack` section 7): UI and core-loop cues at join, the next area's music in the background, boss and rare cues on demand. With `AutoLoad` on, setting `Asset` loads it at once; with it off, the asset loads on the first play (docs).
- `IsReady` can turn false again under extreme memory pressure (docs). Check it before counting on a long track being loaded.
- Rapid events: pool 2-3 players per cue and add a 40-80 ms cooldown, so a burst of pickups does not stack 30 voices (judgment).
- No official limit on simultaneous sounds was found in the docs (searched 2026-11-09). Treat the number of playing voices as a budget and test it on a low-end phone.
- Music tracks are the longest assets: one per mood, and on demand for later areas (judgment).

## 7. Sourcing and rights

Docs: https://create.roblox.com/docs/audio/assets and https://create.roblox.com/docs/projects/assets/privacy.

The Creator Store holds "more than 100,000 professionally-produced sound effects and music tracks from top audio and music partners", free to use (docs, audio/assets). Since the privacy change of 2022-03-22, new uploads are private and existing audio over 6 s became private (DevForum staff post t/1701697). What a game may play without owning the asset:

| Source | Plays without owning it? | Label |
|---|---|---|
| Roblox licensed catalog (music and SFX) | Yes: "All of the Roblox official licensed catalog of Music and SFX will remain Public and usable by developers in any of their experiences." | DevForum staff post t/1701697 (2022) |
| Someone else's private audio | Only with the owner's grant: to a friend or group as a collaborator, or to the game itself. A game grant cannot be revoked. | docs, projects/assets/privacy |
| Public distributed audio: DistroKid music (since 2024-09), community SFX (since 2024-05) | Only after it is acquired: Get in the Creator Store, or insert it in Studio, which adds it to that user's inventory. "Currently, groups cannot acquire audio assets from the Creator Store", so a group-owned game may stay silent. Test in a group-owned place. | DevForum staff posts t/3164792 and t/2980704 (2024); not re-checked on 2026-11-09 |
| Your own uploads | Yes when the uploader owns the game too. Upload under the user or group that owns the game, or grant the game. | docs, projects/assets/privacy |

- Accounts seen carrying licensed audio in Store search (field note, 2026-11-09): Roblox (user 1), ProSoundEffects (user 7462895450) and APMOfficial (user 7462718749), all verified creators. DistrokidOfficial (user 7135127272) carries DistroKid music, which needs acquiring. The docs do not list which partner accounts count as the licensed catalog, so test every id in the real game (section 8).
- Search with Studio MCP `search_asset`: `assetType: "Audio"`, `scope: "creator_store"`, `audioMinDuration` / `audioMaxDuration` in seconds, `verifiedCreatorsOnly: true` (tool schema, 2026-11-09). In the Toolbox: Creator Store tab, category Audio (docs).
- Store durations are whole seconds, and sub-second SFX show 0 (field note, 2026-11-09). Read `TimeLength` instead (section 8).
- Open keyword searches return ripped commercial audio (game soundtracks, chart songs) mixed in with licensed audio (field note, 2026-11-09). Never use a rip, even if it plays today: audio that is moderated later is removed from every game that uses it (DevForum staff post t/2980704, 2024).

Importing (docs, audio/assets):
- You must hold the legal rights. One track in `.mp3`, `.ogg`, `.wav` or `.flac`, under 20 MB and under 7 minutes, 48 kHz or less, mono, stereo, 3.0 or 5.1.
- 2,000 free imports per 30 days if ID verified, 100 if not. Imports go through moderation and are classified automatically as sound effect or song.
- Through the Asset Manager, the Creator Dashboard or Open Cloud (`POST https://apis.roblox.com/assets/v1/assets`, `assetType` Audio). New uploads are private; grant other games as in the table.
- Distributing your own SFX on the Creator Store: under 10 s, no music or speech, uploader 13+ and ID verified, plus copyright and moderation checks (DevForum staff post t/2980704, 2024; check the current rules before relying on them).

AI-made audio: no audio-specific rule was found in the docs (searched 2026-11-09). The generative-AI page says "You are responsible for the content delivered to users, even if it is AI-generated." Treat it like any import: confirm the AI vendor's licence gives you the rights, and expect the same moderation and copyright checks (judgment).

Records: one line per cue in `assets/LICENSES.md` with the event id, asset id, creator account and source (licensed catalog, acquired, own upload, or AI vendor and licence). Never rip audio from videos, other games or charts, and never re-upload Store audio.

## 8. Measuring and review

In Studio (docs):
- Set `Asset`, wait for `IsReady`, then read `TimeLength` (seconds): the real length.
- `AudioPlayer:GetWaveformAsync(NumberRange.new(0, length), samples)` returns `samples` numbers from -1 to 1 without playing the asset. It yields, and returns an empty table if the waveform cannot be read. Peak dBFS = 20 * log10(max |value|).
- `AudioAnalyzer.PeakLevel` and `RmsLevel` measure a live stream (`GetSpectrum` with `SpectrumEnabled`). On the server they are always 0, so read them on the client.
- Short SFX: integrated LUFS is meaningless (a short UI click measured -70 LUFS because of the 400 ms gate). Compare peak and the loudest 50 ms RMS instead; compare music by integrated LUFS (field note, 2026-11-09).

Measuring sketch (untested; written from the docs on 2026-11-09):

```lua
local p = Instance.new("AudioPlayer")
p.Asset = "rbxassetid://0" -- the id to check
p.Parent = workspace
for _ = 1, 50 do
	if p.IsReady then break end
	task.wait(0.1)
end
if not p.IsReady then
	warn("not ready: no permission, moderated or wrong id")
else
	local wave = p:GetWaveformAsync(NumberRange.new(0, p.TimeLength), 2000)
	local peak = 0
	for _, v in wave do peak = math.max(peak, math.abs(v)) end
	print(p.TimeLength, peak > 0 and 20 * math.log10(peak) or "no waveform")
end
p:Destroy()
```

Review checklist:

| Check | Pass |
|---|---|
| Every event in the map has an asset id or `false` on purpose | yes |
| `error` and `not_enough` sound unlike every success cue | yes |
| Music sits below SFX; the rare reveal is the loudest cue | yes |
| No two tier sounds at once; music ducks under level-up, rare reveal and boss warning | yes |
| Music loops without a click or gap and does not restart on respawn | yes |
| Mute and volume sliders work and persist | yes |
| Each id plays in the published game under its real owner (user or group) | yes |
| Under about 20 unique sounds at first release; nothing heavy loads at join | yes |
| `assets/LICENSES.md` lists every id with its source | yes |
| A person listened on phone speakers at low volume for 5+ minutes (`roblox-game-pipeline` section 7a) | yes |
