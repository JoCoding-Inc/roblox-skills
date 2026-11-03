---
name: roblox-game-pipeline
description: "Use FIRST for any new Roblox game, game idea or big feature to run the staged production workflow: tool check, vision, live-market and platform-pattern advice, look and style board, cinematics and small decisions, working-mode choice (auto or staged, solo or subagents), plan, build loop with evidence, verify, release. For Roblox games this replaces generic brainstorming."
when_to_use: "Also when the user says 'make a game', 'I'm making a Roblox game', 'what do you think of this idea', 'is X a good game idea', 'what should I make', 'what is trending', 'plan this game', 'let's start a project', asks how autonomous the agent should be, or whether to use subagents; when small decisions (cinematic, style, intro, music, loading screen) keep coming up late; when work stalls because nobody chose a working mode. Replaces ad-hoc starts: run roblox-project-intake inside stage 0-1 and roblox-market-research in stages 1-2, then continue here."
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
3. **Show, do not describe**, whenever the choice is visual (style board, section 3) or about layout.
4. **Write decisions down** in `docs/brief.md` (what and why) and `docs/ledger.md` (rulings during work, format `Ruling: <what> - <why> - <cost if wrong>`). A decision not written will be lost when the session is compacted.
5. **Evidence before "done":** a task is done when its check ran and the output was read (playtest screenshot, console log, test result). Never claim success from intention.
6. **Look up, do not recall.** At the start call `list_skills` on the Studio MCP and load the matching `rbx-*` skill; read the live API page (`http_get`, see `roblox-dev-workflow` section 0) before using anything new, beta or renamed.
7. **The user owns taste and money.** The agent decides reversible technical details. The user decides look, tone, spending, publishing.

## 1. Stages and gates

| Stage | Output | Gate (user says yes to move on) |
|---|---|---|
| 0 Tool check | Probe, then one table of Required / Recommended / Optional tools with status; setup offered for gaps, skips recorded (`roblox-project-intake` step 1) | Required tools OK before stage 7; optional ones set up or skipped |
| 1 Vision | Pitch, genre, audience, platforms, references (intake Round A); idea check with live data (section 2) | Brief draft confirmed |
| 2 Market and platform fit | Market snapshot for the idea (`roblox-market-research`) and up to 3 pieces of advice from `roblox-design-and-launch` 1a (solo-viable, session, devices, max players) | Accept or reject each |
| 3 Look | Style board result, palette, art sources (section 3) | Style lane picked |
| 4 Moments and small decisions | Cinematics (`roblox-cinematics`), intro, loading screen, logo, music, tutorial, etc. (section 4) | Decision cards answered or defaulted |
| 5 Working mode | Control level and agent mode (section 5) | Both chosen |
| 6 Plan | `docs/plan.md`: small tasks, each with files, done-definition and check | User reads the task list |
| 7 Build | Greybox first, then loop, then art, then polish (`roblox-dev-workflow`) | per working mode |
| 8 Verify | Full playtest on phone-size and PC, cinematic exits, failure paths (`roblox-dev-workflow` 4b) | Evidence list |
| 9 Release | `roblox-release-automation` (gates in 4a); user does the hand steps | User approves publish |

Do not start stage 7 before 3, 4 and 5 are answered or defaulted and every Required tool from stage 0 passes. Changing an answer later is allowed: update the brief and say what rework it causes.

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

0. **Show the lane cards first.** `assets/lanes/` holds seven original concept images, one per lane (see `assets/lanes/README.md`). Build a labeled sheet with `python3 -I <skill dir>/scripts/style_board.py out.png` (add `--only a b c` to show a subset that fits the genre), send it to the user, and propose 3-4 lanes with a one-line reason each. The user can also pick two and ask for a mix.
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
3. Show it to the user: send the PNG (`SendUserFile`) or publish a private Artifact page. Ask: "Which lane is closest? Which one is the opposite of what you want?" Offer to generate mood images for a mix of lanes with an image-generation tool (for example gwanggo; the lane cards cost 3 credits each), and ask before spending credits. Examples of finished screens: `assets/examples/` (loading screen) and `roblox-ui-genre-studs/references/` (stud-style HUD, shop, quests, rewards).
4. Record in the brief: chosen lane, 3 palette colors, line weight, 2-3 reference file paths in `assets/refs/` (private notes, never shipped or uploaded), and the "avoid" lane.
5. Rules: live-game references are other creators' work: they steer direction and are never copied, traced or uploaded. The lane cards and the example images in this plugin are ours or the owner's own. Logo and icon follow `roblox-store-art-pack` section 6.

## 4. Moments and small decisions (stage 4)

Ask these as **decision cards**: one line, a default, one more question only if the answer is yes. Ask them in 2-3 rounds of up to 4, grouped as below. If the user says "all defaults", write the defaults.

| Group | Cards (default in brackets) |
|---|---|
| Moments | Cinematic at all? [none until the loop is fun; if yes, `roblox-cinematics` section 1] ; first-join intro [short, skippable] ; boss or unlock moment [4-6 s, skippable] ; ending [none yet] ; one clip-worthy moment [name the 5-second moment a player would record and share: a huge reveal, a steal, a jump scare] |
| Feel | Camera [third person, shoulder only if shooter] ; hit feedback and screen shake [on, with a setting] ; haptics on phone [off] ; music [one looping track + SFX set] ; SFX style [matches lane] |
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
- **Four stop conditions** (any mode): an irreversible or destructive operation; a security-sensitive action; a side effect outside the dev place (publish, merge, push to shared branch, spend credits); a plan so broken that every path forward is a guess. Everything else is decided, written as a `Ruling:` line, and the work continues.

Record both choices in the brief ("Working mode") and repeat them back in one line.

## 6. Plan (stage 6)

`docs/plan.md` is a list of small tasks (about 15-60 minutes each). Each task has:

```
T07 Boss reveal cinematic
Files/places: ReplicatedStorage/Cinematics/BossReveal, StarterPlayerScripts/CinePlayer
Depends on: T04
Done when: shot list played, Skip works on touch, camera restored after skip and death
Check: playtest screenshot per shot + console clean
Mode: solo (live Studio)
```

Add a loading budget (tier 0 assets and size) to the plan. Order: greybox of the core loop, then the progression engine, then onboarding, then art, then moments, then polish, then economy and monetization, then store art. Tag tasks `solo` or `delegate` so the working mode is already applied. Put the riskiest or least understood task first when it can change the design (spike it).

## 7. Build loop (stage 7)

Per task: read the task and brief, do it, run its check, read the output, commit, write the ledger line, tick the task. Use `roblox-dev-workflow` for tools and `roblox-pitfalls` when MCP or publishing misbehaves. Saves: `roblox-data-saves`. Enemies, allies, bot fill: `roblox-bots-npcs`. Weapons, hit detection, Server Authority: `roblox-combat-tools`. Rounds, lobbies, teleports, leaderboards: `roblox-match-flow`. Sound, effects, lighting: `roblox-feel-audio-vfx`. Camera moments: `roblox-cinematics`. On a failure, find the cause before changing code (`superpowers:systematic-debugging`). Spikes (throwaway builds to feel something out) are allowed and labeled as spikes; their lessons go back to the brief.

## 8. Verify and release (stages 8-9)

- Evidence list in `docs/verification.md`: client and build, phone-size and PC screenshots, console clean, failure paths, cinematic exits, save and rejoin.
- Review the whole branch once with a fresh-context reviewer.
- Release follows the gates in `roblox-release-automation` section 4a. The agent never publishes or merges without the user's explicit yes, and hands back the manual steps (maturity questionnaire, age check, icon and thumbnail upload).

## 9. When the user changes their mind

Update the brief, list the tasks affected, and say the rework cost in one line before continuing. Do not silently keep building on an old decision.
