---
name: roblox-superpowers
description: "Use FIRST for any new Roblox game or big feature to run the staged production workflow: probe, vision, platform-pattern advice, look and style board, cinematics and small decisions, working-mode choice (auto or staged, solo or subagents), plan, build loop with evidence, verify, release. Roblox version of the superpowers workflow."
when_to_use: "Also when the user says 'make a game', 'plan this game', 'let's start a project', asks how autonomous the agent should be, or whether to use subagents; when small decisions (cinematic, style, intro, music, loading screen) keep coming up late; when work stalls because nobody chose a working mode. Replaces ad-hoc starts: run roblox-project-intake inside stage 0-1, then continue here."
last_reviewed: 2026-11-03
sources:
  - superpowers plugin 7.0.0 skills: brainstorming, writing-plans, executing-plans, subagent-driven-development, verification-before-completion, finishing-a-development-branch (read 2026-11-03; rules adapted, not copied)
  - roblox-project-intake, roblox-design-and-launch (section 1a), roblox-dev-workflow, roblox-cinematics, roblox-store-art-pack
  - Studio MCP `subagent` tool: this build (0.745) listed explore, screen_capture, unit_test
  - original (Roblox-specific constraints from shipping test games with an AI agent)
---

# Roblox superpowers: the staged game-development workflow

The superpowers plugin (if installed) gives generic habits: ask before building, plan before coding, execute with evidence, review before finishing. This skill adds what is specific to Roblox: one live Studio place, MCP tools, platform play patterns, art and cinematic choices, and publish limits. Use the plugin skills for the generic parts when they exist, and follow the stages below either way.

## 0. Rules for every stage

1. **Ask in small steps.** One topic per message, at most 4 questions in a round, each with a recommended default marked (D). Open question first ("tell me about the moment a player loves your game"), menus only when the user is stuck.
2. **Offer the skip.** The first message says: "Say 'just decide' and I will pick defaults and write them down." Then record every default in `docs/brief.md` as assumed, so it can be corrected.
3. **Show, do not describe**, whenever the choice is visual (style board, section 3) or about layout.
4. **Write decisions down** in `docs/brief.md` (what and why) and `docs/ledger.md` (rulings during work, format `Ruling: <what> - <why> - <cost if wrong>`). A decision not written will be lost when the session is compacted.
5. **Evidence before "done":** a task is done when its check ran and the output was read (playtest screenshot, console log, test result). Never claim success from intention (`roblox-collaboration-mode`).
6. **The user owns taste and money.** The agent decides reversible technical details. The user decides look, tone, spending, publishing.

## 1. Stages and gates

| Stage | Output | Gate (user says yes to move on) |
|---|---|---|
| 0 Probe | Toolchain, MCP, Open Cloud findings (`roblox-project-intake` step 1) | none, no questions |
| 1 Vision | Pitch, genre, audience, platforms, references (intake Round A) | Brief draft confirmed |
| 2 Platform fit | Up to 3 pieces of advice from `roblox-design-and-launch` 1a (solo-viable, session, devices, max players) | Accept or reject each |
| 3 Look | Style board result, palette, art sources (section 3) | Style lane picked |
| 4 Moments and small decisions | Cinematics (`roblox-cinematics`), intro, loading screen, logo, music, tutorial, etc. (section 4) | Decision cards answered or defaulted |
| 5 Working mode | Control level and agent mode (section 5) | Both chosen |
| 6 Plan | `docs/plan.md`: small tasks, each with files, done-definition and check | User reads the task list |
| 7 Build | Greybox first, then loop, then art, then polish (`roblox-dev-workflow`) | per working mode |
| 8 Verify | Full playtest on phone-size and PC, cinematic exits, failure paths (`roblox-dev-workflow` 4b) | Evidence list |
| 9 Release | `roblox-publish-checklist` + `roblox-release-automation`; user does the hand steps | User approves publish |

Do not start stage 7 before 3, 4 and 5 are answered or defaulted. Changing an answer later is allowed: update the brief and say what rework it causes.

## 2. Platform fit (stage 2)

Run the checks in `roblox-design-and-launch` section 1a and give the developer at most 3 pieces of advice, each as "pattern -> your plan -> suggested change" with the evidence grade. Typical ones: playable alone, a complete mini-loop in 5-10 minutes, first reward in 2 minutes, friend hooks as a bonus, phone and PC from day one, max players chosen from the design.

## 3. Look and style board (stage 3)

Ask for taste with pictures, not adjectives.

1. Pick 4-6 **style lanes** that fit the genre and audience:

   | Lane | Look |
   |---|---|
   | Chunky cartoon | thick outlines, saturated colors, rounded forms, sticker-like UI (see `roblox-ui-genre-studs`) |
   | Classic blocky | Roblox bricks and studs, primary colors |
   | Low-poly stylized | flat shading, few colors per object, soft light |
   | Painterly or cel anime | outlines on characters, flat color fills |
   | Cozy pastel | soft light, rounded props, muted palette |
   | Dark realistic or horror | low light, fog, desaturated palette |
   | Neon or sci-fi | dark base, glow accents |

2. Gather one reference image per lane from live games of the same genre: run `scripts/benchmark` `collect.py` then `art_fetch.py` (thumbnails land in `thumbs/`), or search the genre on the charts. Make one labeled contact sheet (Pillow) with the lane names.
3. Show it to the user: send the PNG (`SendUserFile`) or publish a private Artifact page. Ask: "Which lane is closest? Which one is the opposite of what you want?" Offer to generate mood images with an image-generation tool, and ask before spending credits.
4. Record in the brief: chosen lane, 3 palette colors, line weight, 2-3 reference file paths in `assets/refs/` (private notes, never shipped or uploaded), and the "avoid" lane.
5. Rules: references steer direction; they are other creators' work and are never copied, traced or uploaded. Logo and icon follow `roblox-store-art-pack` section 6.

## 4. Moments and small decisions (stage 4)

Ask these as **decision cards**: one line, a default, one more question only if the answer is yes. Ask them in 2-3 rounds of up to 4, grouped as below. If the user says "all defaults", write the defaults.

| Group | Cards (default in brackets) |
|---|---|
| Moments | Cinematic at all? [none until the loop is fun; if yes, `roblox-cinematics` section 1] ; first-join intro [short, skippable] ; boss or unlock moment [4-6 s, skippable] ; ending [none yet] |
| Feel | Camera [third person, shoulder only if shooter] ; hit feedback and screen shake [on, with a setting] ; haptics on phone [off] ; music [one looping track + SFX set] ; SFX style [matches lane] |
| Onboarding | Tutorial [learn by doing in the first 2 minutes] ; loading screen [custom, themed, skippable] ; first reward time [under 2 min] |
| Brand | Game name and logo [after core loop is fun] ; icon and thumbnails [late, `roblox-store-art-pack`] ; trailer [no] |
| Social | Friend bonus [on] ; private servers [free] ; leaderboard [yes if score-based] ; chat [platform default] |
| Systems | Daily reward [after the loop works] ; shop and passes [after the loop works, `roblox-monetization`] ; localization [English first, strings in a table] ; accessibility options [text size, shake toggle] |

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

Order: greybox of the core loop, then the progression engine, then onboarding, then art, then moments, then polish, then economy and monetization, then store art. Tag tasks `solo` or `delegate` so the working mode is already applied. Put the riskiest or least understood task first when it can change the design (spike it).

## 7. Build loop (stage 7)

Per task: read the task and brief, do it, run its check, read the output, commit, write the ledger line, tick the task. Use `roblox-dev-workflow` for tools and `roblox-pitfalls` when MCP or publishing misbehaves. On a failure, find the cause before changing code (`superpowers:systematic-debugging`). Spikes (throwaway builds to feel something out) are allowed and labeled as spikes; their lessons go back to the brief.

## 8. Verify and release (stages 8-9)

- Evidence list in `docs/verification.md`: client and build, phone-size and PC screenshots, console clean, failure paths, cinematic exits, save and rejoin.
- Review the whole branch once with a fresh-context reviewer.
- Release follows `roblox-publish-checklist` and `roblox-release-automation`. The agent never publishes or merges without the user's explicit yes, and hands back the manual steps (maturity questionnaire, age check, icon and thumbnail upload).

## 9. When the user changes their mind

Update the brief, list the tasks affected, and say the rework cost in one line before continuing. Do not silently keep building on an old decision.
