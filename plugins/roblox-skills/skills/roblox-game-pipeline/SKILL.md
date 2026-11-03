---
name: roblox-game-pipeline
description: "Use FIRST for any new Roblox game, game idea or big feature to run the staged production workflow: tool check, vision, live-market and platform-pattern advice, look and style board, cinematics and small decisions, working-mode choice (auto or staged, solo or subagents), plan, first proof (core-fun prototype, concept images or concept trailer with gwanggo), build loop with evidence, verify, release. For Roblox games this replaces generic brainstorming."
when_to_use: "Also when the user says 'make a game', 'I'm making a Roblox game', 'what do you think of this idea', 'is X a good game idea', 'what should I make', 'what is trending', 'plan this game', 'let's start a project', asks how autonomous the agent should be, or whether to use subagents; asks for a prototype, a playable test of the core loop, concept art or a trailer before building; when a step is judged by feel (controls, combat, difficulty, scares, audio) and the user should play it and give feedback; when small decisions (cinematic, style, intro, music, loading screen) keep coming up late; when work stalls because nobody chose a working mode. Replaces ad-hoc starts: run roblox-project-intake inside stage 0-1 and roblox-market-research in stages 1-2, then continue here."
last_reviewed: 2026-11-03
sources:
  - superpowers plugin 7.0.0 skills: brainstorming, writing-plans, executing-plans, subagent-driven-development, verification-before-completion, finishing-a-development-branch (read 2026-11-03; rules adapted, not copied)
  - roblox-project-intake, roblox-market-research, roblox-design-and-launch (section 1a), roblox-dev-workflow, roblox-cinematics, roblox-store-art-pack
  - Studio MCP `subagent` tool: this build (0.745) listed explore, screen_capture, unit_test
  - original (Roblox-specific constraints from shipping test games with an AI agent)
---

# Roblox game pipeline: the staged game-development workflow

The superpowers plugin (if installed) gives generic habits: ask before building, plan before coding, execute with evidence, review before finishing. This skill adds what is specific to Roblox: one live Studio place, MCP tools, platform play patterns, art and cinematic choices, and publish limits. Use the plugin skills for the generic parts when they exist, and follow the stages below either way.

## 0. Rules for every stage

1. **Ask in small steps.** One topic per message, at most 4 questions in a round, each with a recommended default marked (D). Open question first ("tell me about the moment a player loves your game"), menus only when the user is stuck.
2. **Offer the skip.** The first message says: "Say 'just decide' and I will pick defaults and write them down." Then record every default in `docs/brief.md` as assumed, so it can be corrected.
3. **Show, tell, then offer**, whenever the choice is visual (look, UI style, characters, logo, loading screen, lighting) or about layout or motion:
   1. Show only the bundled examples that fit the idea's genre, audience and tone (at most 3-4). Skip cards that clash with the pitch, such as horror for a kids' gym tycoon, unless the user asks for them.
   2. Give 2-4 options in words, written for this game ("chunky cartoon gym: lime dumbbells, sunburst sky, thick black outlines").
   3. Ask: "Do you want example images of your own game in these options? I can make them with gwanggo, about N credits." Bundled images are generic, so recommend this for the look and the UI style. With gwanggo connected, make them on a yes (section 10a). Without it, offer the setup once (`roblox-project-intake` step 1c), else use the fallback in section 10a.
   4. Record the pick.
4. **Write decisions down** in `docs/brief.md` (what and why) and `docs/ledger.md` (rulings during work, format `Ruling: <what> - <why> - <cost if wrong>`). A decision not written will be lost when the session is compacted.
5. **Evidence before "done":** a task is done when its check ran and the output was read (playtest screenshot, console log, test result). Never claim success from intention.
6. **Look up, do not recall.** At the start call `list_skills` on the Studio MCP and load the matching `rbx-*` skill; read the live API page (`http_get`, see `roblox-dev-workflow` section 0) before using anything new, beta or renamed.
7. **The user owns taste and money.** The agent decides reversible technical details. The user decides look, tone, spending, publishing.
8. **Close Studio when done.** Each Studio window holds about 0.3-1 GB (measured 2026-11-03), and many open windows slow or crash the machine.
   - Before opening a place, list the open windows (`list_roblox_studios`) and their memory (`ps -axo pid,rss,command | grep -i "[R]obloxStudio"`; Windows `tasklist /fi "imagename eq RobloxStudioBeta.exe"`). With 3 or more open, tell the user and ask which to close. Never close another project's window yourself.
   - One window per project: reuse it instead of opening the same place twice. Note the PID of each window you open (process list before and after) in `docs/ledger.md`.
   - When a task, a gate or the session ends, or the window is no longer needed: stop play (`start_stop_play`), make sure the work is saved (code on disk through Rojo or Script Sync; parts and settings saved with Ctrl+S or published; no MCP tool saves the place, so ask the user to press Ctrl+S when Studio-only edits exist), close it by PID (`kill <pid>`; Windows `taskkill /pid <pid>`), never by name, and confirm with `list_roblox_studios`. A window with unsaved changes shows a save dialog and ignores `kill`: for a scratch place the agent opened, check the PID's command line names that file, then `kill -9`; for the user's place, ask the user to save and close it.
9. **Ask for keys and permissions at the moment of need**, with what, why, the exact clicks and how to confirm (`roblox-project-intake` step 1d). Never ask for key values in chat.
10. **Let a person judge the feel.** When the result is judged in the hands (core action, movement, combat, difficulty, scares, audio, phone controls), stop and ask the user to play it (section 7a) instead of judging from screenshots and building on a guess.

## 1. Stages and gates

| Stage | Output | Gate (user says yes to move on) |
|---|---|---|
| 0 Tool check | Probe, then one table of Required / Recommended / Optional tools with status; setup offered for gaps, skips recorded (`roblox-project-intake` step 1) | Required tools OK before stage 7; optional ones set up or skipped |
| 1 Vision | Pitch, genre, audience, platforms, references (intake Round A); idea check with live data (section 2) | Brief draft confirmed |
| 2 Market and platform fit | Market snapshot for the idea (`roblox-market-research`) and up to 3 pieces of advice from `roblox-design-and-launch` 1a (solo-viable, session, devices, max players) | Accept or reject each |
| 3 Look | Style board result, palette, art sources (section 3) | Style lane picked |
| 4 Moments and small decisions | Cinematics (`roblox-cinematics`), intro, loading screen, logo, music, tutorial, etc. (section 4) | Decision cards answered or defaulted |
| 5 Working mode | Control level and agent mode (section 5) | Both chosen |
| 6 Plan | `docs/plan.md`: small tasks, each with files, done-definition and check; art source per asset class chosen with the user (section 6a) | User reads the task list |
| 6b First proof | User picks: core-fun prototype, concept images, concept trailer, or straight to the build (section 6b) | Prototype verdict written, or concept assets reviewed |
| 7 Build | Greybox first, then loop, then art, then polish (`roblox-dev-workflow`); the user plays at feel checkpoints (section 7a) | per working mode; checkpoint notes in `docs/playtests.md` |
| 8 Verify | Full playtest on phone-size and PC, cinematic exits, failure paths (`roblox-dev-workflow` 4b); a final user session on PC and a real phone | Evidence list |
| 9 Release | `roblox-release-automation` (gates in 4a); user does the hand steps | User approves publish |

Do not start stage 7 before 3, 4, 5 and 6b are answered or defaulted and every Required tool from stage 0 passes. Changing an answer later is allowed: update the brief and say what rework it causes.

Stage 0 runs before the first question, also when the user opens with an idea. Show its table in the same message as the first answer, so the user can set tools up while planning goes on.

## 2. Market and platform fit (stages 1-2)

**Idea check first.** When the user asks "what do you think of X" or names a genre, answer from live data, not memory: run `roblox-market-research` (`market.py charts`, `keyword` for 2-4 terms of the idea, `game` and `history` for the top 1-2 competitors) and cite the numbers with the date. Then give:
- Crowding: rank-1 and top-10 CCU for the keywords, share of results under 90 days old.
- Twist test: one thing the idea does that the top clone does not. No twist, no green light.
- Size for week 8, not launch week: the competitor's half-life from `history`.
- Live-ops load: what the first 4 weeks of updates would be (section 4, Live ops card).

Then the platform checks: run the checks in `roblox-design-and-launch` section 1a and give the developer at most 3 pieces of advice, each as "pattern -> your plan -> suggested change" with the evidence grade. Typical ones: playable alone, a complete mini-loop in 5-10 minutes, first reward in 2 minutes, friend hooks as a bonus, phone and PC from day one, max players chosen from the design.

## 3. Look and style board (stage 3)

Ask for taste with pictures, not adjectives.

0. **Show the lane cards that fit, and tell.** `assets/lanes/` holds seven original concept images, one per lane (see `assets/lanes/README.md`, column "Fits"). Pick the 3-4 lanes that fit the genre, audience and tone, build a sheet of only those with `python3 -I <skill dir>/scripts/style_board.py out.png --only a b c`, and send it. Mention in one line that other lanes exist. Next to the sheet, describe each lane in one line set in this game ("cozy pastel gym: mint mats, peach walls, soft morning light"). The user can also pick two and ask for a mix.
1. The **style lanes**:

   | Lane | Look |
   |---|---|
   | Chunky cartoon | thick outlines, saturated colors, rounded forms, sticker-like UI (see `roblox-ui-genre-studs`) |
   | Classic blocky | Roblox bricks and studs, primary colors |
   | Low-poly stylized | flat shading, few colors per object, soft light |
   | Painterly or cel anime | outlines on characters, flat color fills |
   | Cozy pastel | soft light, rounded props, muted palette |
   | Dark realistic or horror | low light, fog, desaturated palette; mascot horror (bright cartoon characters in dark spaces) is a common sub-lane |
   | Neon or sci-fi | dark base, glow accents |

2. After the user leans toward a lane, add real references from live games of the same genre for that lane (not for all seven): run `roblox-launch-benchmarks` `scripts/collect.py` then `scripts/art_fetch.py` (thumbnails land in `thumbs/`), or search the genre on the charts. Make one labeled contact sheet (Pillow) with the lane names.
3. Show it to the user: send the PNG (`SendUserFile`) or publish a private Artifact page. Ask: "Which lane is closest? Which one is the opposite of what you want?" Then offer: "Want to see your game itself in the 2-3 closest looks? I can make one image each with gwanggo, about N credits." Recommend it, and always when no lane fits, the user wants a mix, or describes a look the cards do not show. Each image shows the game's own scene (its setting and core action, for example a member lifting in a small gym), only the look changes (section 10a). Examples of finished screens: `assets/examples/` (loading screen) and `roblox-ui-genre-studs/references/` (stud-style HUD, shop, quests, rewards).
4. **UI style**, right after the lane: `assets/ui-styles/` holds four basic example screens (soft dark, stud chunky, bright cards, dark flat), all showing the same HUD and shop (see its README, column "Fits"; themed looks such as cozy wood or anime gold are words only). Show the 2-4 that fit the genre and lane (`style_board.py ui.png --dir <skill dir>/assets/ui-styles --only ...`) and describe each in one line set in this game. After the pick, ask "Shall I make a design that matches your game's tone and manner?" and offer a Studio mockup (free: `scripts/ui_style_mock.luau` builds a real ScreenGui in the game's place with its own items) or gwanggo images (about 3 credits each, quote first); the README has both. The pick decides the UI skill: stud chunky goes to `roblox-ui-genre-studs`, the others to the UI rules in `roblox-engine-2026` with the README's build notes.
5. Record in the brief: chosen lane, UI style, 3 palette colors, line weight, the font pair (picked from a specimen screenshot, `roblox-ui-typography` section 2), 2-3 reference file paths in `assets/refs/` (private notes, never shipped or uploaded), and the "avoid" lane.
6. Rules: live-game references are other creators' work: they steer direction and are never copied, traced or uploaded. The lane cards and the example images in this plugin are ours or the owner's own. Logo and icon follow `roblox-store-art-pack` section 6.

## 4. Moments and small decisions (stage 4)

Ask these as **decision cards**: one line, a default, one more question only if the answer is yes. Ask them in 2-3 rounds of up to 4, grouped as below. If the user says "all defaults", write the defaults. Visual cards (loading screen, logo, hit effects, lighting mood, UI style, cinematic style) get example images when the user hesitates or asks "what would that look like" (section 10a).

| Group | Cards (default in brackets) |
|---|---|
| Moments | Cinematic at all? [none until the loop is fun; if yes, `roblox-cinematics` section 1] ; first-join intro [short, skippable] ; boss or unlock moment [4-6 s, skippable] ; ending [none yet] ; one clip-worthy moment [name the 5-second moment a player would record and share: a huge reveal, a steal, a jump scare] |
| Feel | Camera [third person, shoulder only if shooter] ; hit feedback and screen shake [on, with a setting] ; haptics on phone [off] ; music [one looping track + SFX set] ; SFX style [matches lane] ; signature reveal or celebration [one, tiered by rarity or effort, skippable; `roblox-fun-effects`] ; status other players see [aura, trail or title with a free path, if the game has rarity] |
| Onboarding | Tutorial [learn by doing in the first 2 minutes] ; loading screen [custom, themed, skippable] ; first reward time [under 2 min] ; first screen assets [only what the first screen shows load before play; the rest loads in the background or on demand, `roblox-store-art-pack` section 7] |
| Brand | Game name and logo [after core loop is fun] ; icon and thumbnails [late, `roblox-store-art-pack`] ; trailer [no] |
| Social | Friend bonus [on] ; private servers [free] ; leaderboard [yes if score-based] ; chat [platform default] |
| Systems | Daily reward [after the loop works] ; shop and passes [after the loop works, `roblox-design-and-launch` section 2] ; localization [English first, strings in a table] ; accessibility options [text size, shake toggle] |
| Live ops | First 4 weeks after launch [one content drop per week, planned before launch] ; seasonal hook [next platform season or holiday] ; codes and events [codes at launch, one event in weeks 2-4] |
| Combat and rounds | Combat in the game? [if yes, `roblox-combat-tools`] ; rounds, lobby or teleports? [if yes, `roblox-match-flow`] |

Write the answers into the brief under "Moments and feel". Put open items in "Open questions".

## 5. Working mode (stage 5)

Ask two questions, with a recommended default for each.

**A. Control level (how often the agent stops)**

| Mode | Behavior | Use when |
|---|---|---|
| Auto (D after the plan is approved) | Runs every task; stops only for the four stop conditions below; posts a ledger and evidence at the end | Mechanical work, user wants a finished slice |
| Stage gates (D for new games) | Stops after greybox, after art pass, after polish: shows screenshots and asks go or change | New game, taste matters |
| Task by task | Stops after every task | User learning, risky systems (saves, purchases) |

**B. Agent mode (who does the work)**

| Mode | Behavior | Use when |
|---|---|---|
| Solo inline | One context does all tasks, one fresh-context review at the end | Small slice, tightly coupled edits, lowest cost |
| Subagents | Fresh agent per task, review after each (superpowers `subagent-driven-development`) | Long plan of independent tasks, file-only work |
| Hybrid (D) | Solo for live Studio edits; subagents for read-only and file-only jobs | Most Roblox work |

Roblox constraints that decide this:
- **One live place.** Studio edits through MCP change one shared state. Two agents editing the same place collide, so Studio edits stay with one agent at a time.
- **Safe to delegate:** research, reading code, reviewing a diff, screenshot QA (the Studio MCP `subagent` tool listed `explore`, `screen_capture`, `unit_test` in build 0.745; `playtest` needs the Playtest Agent beta), Luau modules and Lune tests in a Rojo project, Blender assets in the agent's own collection or own Blender instance (`roblox-blender-export` section 8).
- **Never delegate:** taste decisions, spending Robux or credits, API keys, publishing, DataStore schema decisions.
- **Four stop conditions** (any mode): an irreversible or destructive operation; a security-sensitive action; a side effect outside the dev place (publish, merge, push to shared branch, spend credits); a plan so broken that every path forward is a guess. Everything else is decided, written as a `Ruling:` line, and the work continues. Planned playtest checkpoints (section 7a) are not extra stops in Auto mode unless later tasks build on that feel; otherwise they wait for the end.

Record both choices in the brief ("Working mode") and repeat them back in one line.

## 6. Plan (stage 6)

`docs/plan.md` is a list of small tasks (about 15-60 minutes each). Each task has:

```
T07 Boss reveal cinematic
Files/places: ReplicatedStorage/Cinematics/BossReveal, StarterPlayerScripts/CinePlayer
Depends on: T04
Done when: shot list played, Skip works on touch, camera restored after skip and death
Check: playtest screenshot per shot + console clean
Playtest: user - watch it once, skip it once: too long? (section 7a)
Mode: solo (live Studio)
```

Add a loading budget (tier 0 assets and size) to the plan. Order: greybox of the core loop, then the progression engine, then onboarding, then art, then moments, then polish, then economy and monetization, then store art. Tag tasks `solo` or `delegate` so the working mode is already applied. Add a `Needs user:` line to every task that needs a permission, key or hand step (`roblox-project-intake` step 1d, for example Studio access to data stores before the first save test), so the agent asks right before that task, not at the start. Add a `Playtest: user` line to every task whose result is judged by feel (section 7a). Put the riskiest or least understood task first when it can change the design (spike it).

## 6a. Art source per asset class (before writing art tasks)

List the asset classes (for example machines and furniture, building kit, characters and creatures, pets and pickups, icons) and, for each, the tools this session can really use (probe again: Studio MCP, gwanggo `get_credits`, Blender `get_addon_status`):

| Tool | Cost | Good at | Not for |
|---|---|---|---|
| Parts built by script (agent writes `execute_luau` or Rojo model files) | No credits; instant; edit in Studio | Blocky props, machines, furniture, buildings, map structure; the classic blocky lane fully, chunky cartoon only for shapes (no thick outlines) | Organic or detailed shapes; many parts per repeated prop (keep counts low, reuse one model) |
| Roblox Cube (Studio MCP `generate_mesh`) | No credits; rate limited (1-2 jobs at a time) | Static props, furniture, machines, vehicles; a reference image keeps the look | Rigs; exact modular sizes |
| gwanggo `generate_game_asset` kind `image` then `3d` | Credits, `dry_run` first | Many props in one locked style (the project's selected concept and palette); GLB within Roblox limits | Rigs |
| `generate_procedural_model` | No credits; 50 per 24 h | Scalable part-built objects (shelves, fences, stairs) | Organic shapes |
| Blender (scripted) | Free, slowest | Rigs and animation, modular kit pieces with exact sizes (walls, floors, trims), voxel animals | Many detailed props fast |
| Creator Store | Free | Fillers, audio | Hero assets (quarantine first) |

- When a class covers many assets and the user has not seen the options, run a **bake-off**: make the same object (one machine, one pet) with each available tool, screenshot them side by side in Studio (or a sheet with `scripts/style_board.py`), and let the user pick. Quote gwanggo credits first. Never mark one option (D) and skip the others unseen.
- Judge from the samples, not from memory: "AI output has inconsistent style" is not true of a style-locked gwanggo project or Cube with a reference image; the raw-mesh warning in `roblox-blender-export` section 9 is about the Blender MCP generators.
- When parts are in the mix, settle the part look before building: send `assets/part-looks/stud-surfaces.jpg` (studs on every face, new-part default, smooth, faint stud texture; real Studio renders) and `materials.jpg`, describe each option in one line set in this game, and record `Part look:` in the brief. The README there has the property settings and a helper.
- Record the result in the brief as `Art source: <class> -> <tool> (<reason>)` lines and tag the art tasks with it.

## 6b. First proof (after the plan, before the full build)

When the plan is approved, ask once, several picks allowed: "Before the full build, what do you want to see first?"

| Option | You get | Needs | Cost |
|---|---|---|---|
| A. Core-fun prototype (D) | A playable greybox of the most-repeated action, its feedback, the first reward and one upgrade | Studio MCP | 1-3 plan tasks, no credits |
| B. Concept images | 3-6 stills: key art, one gameplay screen, the clip-worthy moment, the hero character or creature | gwanggo MCP | Credits per image, quoted first |
| C. Concept trailer | 15-30 s video made from B's stills: 3-5 shots, captions, title card | gwanggo MCP | More credits than B, quoted first |
| D. Straight to the full build | Stage 7 as planned | - | - |

Pick A first when the core action is the risk; B or C first when the pitch or the look is the open question (the user wants to show friends or a team). B then C, and A plus B, are common.

**A. Core-fun prototype**
- Build it in the real project as the first greybox tasks, not in a throwaway place, so stage 7 continues from it. Tag those tasks `Prototype` in the plan.
- In: the minute-to-minute action, one sound and one number pop as feedback, the first reward, one upgrade, the twist if it is mechanical. Placeholder parts and default UI.
- Out: saves, shop, monetization, art pass, cinematics, loading screen, settings.
- Test: the agent playtests through Studio MCP (screenshots, console), then the user plays it in Studio or on a phone through a private test place (`roblox-release-automation`), following section 7a steps 3-5. If multiplayer is the point, use Server & Clients with 2 clients.
- Verdict from three questions: does the action feel good within 30 s? Does the player want the next upgrade? Does the twist show in the first 2 minutes? Write keep / change / drop to `docs/ledger.md` and update the plan before stage 7.

**B. Concept images (gwanggo Game Studio, section 10)**
- If the project has no gwanggo project yet: `create_game_project` (platform `roblox`) and `plan_game` with our brief passed as `brief`, so gwanggo uses `docs/brief.md` instead of writing its own (both free).
- `generate_concepts` with `dry_run: true` first, show the credits, wait for yes, then run it (count 3; key art, gameplay scene, world overview, character lineup). Put the style lane, palette and "Roblox game, blocky avatar proportions" in `extra_direction`. Never name other live games or their characters.
- Poll each task with `get_task`, show the images, and call `select_concept` with the one the user picks: this locks the style for every later asset and video.
- Save copies to `assets/concept/` with `assets/concept/README.md` (prompt, model, credits, date). They steer direction; they are not shipped art.

**C. Concept trailer (gwanggo)**
- Shot list first (format in `roblox-cinematics` section 4): hook = the clip-worthy moment, then the core action, the progression payoff, the twist or friends, title card; 3-6 s per shot.
- `generate_gameplay_video` makes one clip from the selected concept (needs `select_concept`; credits per second, `dry_run` first; default 5 s, 16:9). Pass each shot's motion as `prompt`. For shots that start from another concept image, use `generate_video` with that image as the start frame. 9:16 for Shorts or TikTok tests (the `gwanggo-social-video` skill plans these if installed).
- Join the clips with `ffmpeg -f concat -safe 0 -i shots.txt -c copy trailer.mp4` when ffmpeg exists (re-encode if the clips differ); otherwise hand over the clips in order.
- Concept images and trailers do not show the real game. Never use them as store thumbnails, the store video or Roblox ads; those show real gameplay (`roblox-store-art-pack`, truthfulness). gwanggo's own tool description says the same.

**Without gwanggo:** offer setup once (`roblox-project-intake` step 1c), then fall back: a written storyboard (one line per shot, format above), greybox screenshots with Studio MCP `screen_capture`, Blender renders (`look`), or another image or video tool the user has connected. Say which fallback was used.

## 7. Build loop (stage 7)

Per task: read the task and brief, do it, run its check, read the output, commit, write the ledger line, tick the task. Use `roblox-dev-workflow` for tools and `roblox-pitfalls` when MCP or publishing misbehaves. Saves: `roblox-data-saves`. Enemies, allies, bot fill: `roblox-bots-npcs`. Weapons, hit detection, Server Authority: `roblox-combat-tools`. Rounds, lobbies, teleports, leaderboards: `roblox-match-flow`. Sound, effects, lighting: `roblox-feel-audio-vfx`. Reveals, auras, rarity and celebrations: `roblox-fun-effects`. Character motions (exercise loops, sitting, interactions): `roblox-character-motion`. Fonts and text: `roblox-ui-typography`. Camera moments: `roblox-cinematics`. On a failure, find the cause before changing code (`superpowers:systematic-debugging`). Spikes (throwaway builds to feel something out) are allowed and labeled as spikes; their lessons go back to the brief.

## 7a. Feel checkpoints: the user plays

The agent checks what a machine can measure: errors, console, layout, screenshots, saves, PASS/FAIL scenarios. It cannot feel input delay, fun, fear, boredom or a sore thumb. At those points it stops, hands the game to the user and asks, instead of guessing and building on top.

| Checkpoint | Why the agent cannot judge it | Ask (1-5 plus one line) |
|---|---|---|
| Core action and its feedback (6b A, first greybox) | Timing between input, sound and number pop is felt, not seen in a screenshot | Fun within 30 s? Want to press it again? |
| Movement and camera (walk speed, jump, camera distance, shake) | Floaty, heavy or dizzy only shows in the hands | Too slow, right or too fast? Any dizziness? |
| Combat and hit feel (hit timing, knockback, cooldowns, enemy damage) | Fairness and impact depend on reaction time and latency | Did hits land when you expected? Were deaths fair? |
| Difficulty and pacing (first 10 minutes, jumps, upgrade costs) | Frustration and boredom are personal; the agent knows every answer | Where did you get stuck or bored? |
| Onboarding (first 2 minutes) | A first-time player does not know what the agent knows; best tested by someone who has never seen the game | Did you know what to do without reading? |
| Scares, tension, cinematics | Timing works on people, not on logs | Surprised or scared? Too long? |
| Character motions (exercise loops, interactions, emotes) | Contacts are measured first (`roblox-character-motion` section 7); weight and timing are felt | Looks like the real move? Too fast or slow for the reward? |
| Rolls, reveals, rare drops, celebrations | Excitement and "too long" are felt; tier timings are judgment (`roblox-fun-effects`) | Did you want to show someone? Skip anything? |
| Audio mix and music | Loudness and annoyance on real speakers over 5+ minutes | Anything too loud or tiring? |
| Phone controls | Thumb reach and button size on a real phone, not the emulator | Anything hard to tap or under your thumb? |
| Social and multiplayer fun | Needs real people together | More fun with a friend? |
| Before release (stage 8) | Overall | Would you play again tomorrow? |

Do not ask the user to find what a test can find (errors, overlaps, saves, purchase failure paths).

1. **Plan it.** Feel tasks carry a `Playtest: user - <what to try>` line (section 6). Batch them: one 5-10 minute session after a group of feel tasks, not one per number. In Stage gates mode the session joins the gate.
2. **Make changes cheap.** Keep feel values (speeds, cooldowns, costs, shake) in one `Tuning` ModuleScript or as attributes. For a close call, build 2-3 variants the user can switch during play with a key (dev builds only, removed before release) and ask which is best.
3. **Hand over.** Stop any MCP play session and save, then give: where to play (Studio Play, F5; Server & Clients with 2 clients for multiplayer; a phone through the private test place or the Playtest audience, `roblox-design-and-launch` section 4), 2-4 things to try and how long. The agent does not edit the place or start play while the user plays.
4. **Measure while they play.** Print key moments to the Output (first reward time, deaths, upgrades bought, where the player stopped) and read them afterwards with `get_console_output`, so the answers come with numbers.
5. **Ask and record.** At most 4 questions, 1-5 plus one free line. Write the session to `docs/playtests.md`, then turn each answer into keep, change or drop with a task:

   ```
   PT03 2026-11-03 | build a1b2c3d | user, PC Studio, 8 min
   Tried: jump A/B/C, first upgrade
   Said: core action 4/5, jump B best, first upgrade too slow
   Data: first reward 1:40, deaths 3
   Next: JumpPower 50 -> 46 (keep B); upgrade cost 100 -> 60 (T13)
   ```

6. **Skipped?** Write `Ruling: playtest PT03 skipped - feel assumed - rework if it feels wrong later` in the ledger and go on.

## 8. Verify and release (stages 8-9)

- Evidence list in `docs/verification.md`: client and build, phone-size and PC screenshots, console clean, failure paths, cinematic exits, save and rejoin.
- A final user session (section 7a, last row) on PC and on a real phone, recorded in `docs/playtests.md`.
- Review the whole branch once with a fresh-context reviewer.
- Release follows the gates in `roblox-release-automation` section 4a. The agent never publishes or merges without the user's explicit yes, and hands back the manual steps (maturity questionnaire, age check, icon and thumbnail upload).

## 9. When the user changes their mind

Update the brief, list the tasks affected, and say the rework cost in one line before continuing. Do not silently keep building on an old decision.

## 10. gwanggo along the way (images, icons, textures, 3D, video)

gwanggo Game Studio (gwanggo.ai/game, agent setup at gwanggo.ai/game/connect) keeps one project per game: the brief, a locked style (palette, reference images, chosen concept) and every generated asset. The MCP tools below were listed from the live server on 2026-11-03; when a call fails, list the server's tools and trust that list.

| Tool | Cost | Use |
|---|---|---|
| `create_game_project`, `plan_game`, `update_game_project`, `select_concept`, `list_game_projects`, `get_game_project`, `get_project_assets` | Free | Project, brief (pass ours as `brief`), style lock, asset list with download URLs (GLB for 3D) |
| `generate_concepts` | Credits per image | 1-4 concept images from the brief |
| `generate_game_asset` | Credits | One asset in the locked style: `kind` `image` (object on plain background), `icon` (1:1), `texture` (1:1 seamless tile), `3d` (textured GLB, Roblox limits when the project platform is `roblox`) |
| `generate_3d` | 4-47 credits by model and texture | Text or image to GLB outside the style lock; `style` `roblox`, `face_limit` up to `15000` (Roblox-safe) |
| `generate_gameplay_video` | Credits per second | Concept or promo clip from the selected concept; AI video, not real footage |
| `generate_image`, `generate_video`, `list_models`, `get_credits`, `get_task` | Credits for generation | General images and video, model list with costs, balance, polling |

Rules:
- Offer generation at the moment it helps, in one line with what it adds and the cost; never a batch up front. Every paid call runs with `dry_run: true` first (or `list_models` costs), and the user says yes to the exact credits.
- Write the gwanggo project id into `docs/brief.md` (Environment) so later sessions reuse the same project and style lock. Check `list_game_projects` first and reuse a matching project instead of making duplicates.
- Order matters (checked 2026-11-03): `generate_concepts` fails until `plan_game` has saved a brief; `generate_gameplay_video` fails until `select_concept`; assets made before a palette and a selected concept come back with "not color-locked" and "not style-locked" warnings. So: brief with `art_direction.palette` (or `update_game_project` style palette) -> concepts -> select -> assets and video.
- Cost scale from `list_models` and `dry_run` on 2026-11-03 (quote the live number, not these): image 1-8 credits, icon 3, 3D 4-47 (tripo-h31 text 8, image 12), video 1-25 credits per second (a 5 s 720p clip is often 10-45).
- Consistent 3D: `generate_game_asset` kind `image` first, poll until done, then kind `3d` with `image_url` set to that result (image-to-3D). Prefer the Roblox-friendly models (tripo-h31, rodin-25-fast, meshy-v71, trellis-2-image); Hunyuan 3D Pro is always 40K+ faces, over the 20,000-triangle mesh limit. 3D results are static meshes with no rig.
- Import: `get_project_assets` gives the GLB URL; download it, import with Studio's 3D Importer, set collision and anchoring as in `roblox-blender-export` section 5, and log it in `assets/LICENSES.md` (source gwanggo, model, date).

| Moment | gwanggo | Fallback without it |
|---|---|---|
| Stage 1-2 brief | `create_game_project` + `plan_game` (our brief); its `asset_list` seeds the art tasks in the plan | Asset list written by hand |
| Stage 3 look | `generate_concepts` 3, user picks, `select_concept` locks the style | Lane cards, live-game contact sheet |
| Stage 6b first proof | Concept images, concept trailer (`generate_gameplay_video`) | Written storyboard, greybox screenshots |
| Stage 7 props and pets | `generate_game_asset` image then 3d; packs of themed props (one call per item) | Studio MCP `generate_mesh` (Roblox Cube), Blender, Creator Store |
| Stage 7 UI | `generate_game_asset` kind `icon` for inventory, shop and currency icons (`roblox-store-art-pack` section 4) | Blender renders, Studio screenshots |
| Stage 7 surfaces | `generate_game_asset` kind `texture` for seamless tiles, used as `MaterialVariant` color maps | Studio Material Generator, `generate_material` |
| Brand | Logo candidates and loading-screen art with `generate_image` (`roblox-store-art-pack` sections 6-7) | Text logo built in Studio |
| Stage 9 launch | Game icon and thumbnails: web Thumbnail & Icon Kit (gwanggo.ai/dashboard/game/thumbnail-kit; 3 thumbnails 1920x1080 under 3 MB and a 512x512 icon from a real gameplay screenshot, checked against Roblox sizes; not an MCP tool). Ads Manager creative variants from real screenshots | Studio screenshots edited by hand |

AI text in images can be misspelled: check every letter, or leave titles off and typeset them. Video thumbnails and ads must be real gameplay.

### 10a. Example images for any design choice

Use this for every choice of how something looks or moves, after the bundled examples that fit (lane cards, `assets/ui-styles/`, `assets/part-looks/`, `assets/examples/`, `roblox-ui-genre-studs/references/`) and the word options (rule 3). The bundled images are generic; examples of the user's own game decide faster. Ask before making them, and recommend it.

| Choice | Example to generate |
|---|---|
| Overall look, lane mix, palette | Same scene in each candidate look |
| Characters, pets, enemies, NPCs | 3-4 designs of the same character |
| UI style (HUD, shop, buttons) | Same screen layout in each style (phone landscape); with Studio MCP prefer a free Studio mockup (`scripts/ui_style_mock.luau`, `assets/ui-styles/README.md`) |
| Loading screen, logo | 3-4 candidates (`roblox-store-art-pack` sections 6-7) |
| Lighting and mood (day, night, horror, neon) | Same spot of the map in each mood |
| Hit effects, particles, rewards | A still of the effect at its peak per option |
| Map layout or a zone | Top-down or overview per option |
| Camera, cinematic style, motion (only if the user wants motion) | A 4-5 s clip per option; otherwise storyboard stills |

How:
1. One image per option, same scene, same camera and framing; only the choice changes, so the comparison is fair. The scene comes from this game (its setting, core action, characters from the brief), not a generic one. Label each option A, B, C.
2. Before the style lock use `generate_image`; after it use `generate_game_asset` kind `image` so examples match the locked style. Explore with a cheap model (1-3 credits per image in `list_models`); use high quality only for the final pick.
3. Quote the total first (count x cost) and wait for yes. Clips cost much more than stills: offer them only for motion choices.
4. Show them on one labeled sheet: save the files as `A-<name>.png` and so on in a scratch folder and run `python3 -I <skill dir>/scripts/style_board.py sheet.png --dir <folder>`, then send the sheet.
5. Record the pick in the brief or ledger, copy the chosen image to `assets/refs/`, and log prompt, model and credits. A pick can feed the next step: a chosen character image goes to `generate_game_asset` kind `3d`.

Without gwanggo: a quick greybox mock in Studio captured with `screen_capture` per option, live-game thumbnails of the same genre as references (`roblox-launch-benchmarks` `scripts/art_fetch.py`; references only, never copied), or a short written description per option.

If gwanggo is not connected when a moment comes, say what it would add, offer the setup in `roblox-project-intake` step 1c once, and use the fallback if the user declines. If it is connected but `create_game_project` is missing, the session holds an old tool list: reconnect it in `/mcp` or restart Claude Code. If `list_models` rejects `type: "3d"`, its schema is stale: call it with no filter, which also returns the 3D models.
