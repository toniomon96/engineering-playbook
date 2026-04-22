# Design Workflow — Claude Design + Claude Code

*Companion to the Agent-Assisted Engineering handbook. Read before every Claude Design session.*

*Last reviewed: TBD*

# Design Workflow — Claude Design + Claude Code

*Companion to the Agent-Assisted Engineering handbook. Read before every Claude Design session; skim the Quick Reference if that's all you have time for.*

*Last reviewed: 2026-04-22*

---

## Why this exists

Claude Design is fast enough to outrun your taste and token-heavy enough to eat your weekly budget if you're not deliberate. Generation is cheap; direction is where the work is. This is the checklist that keeps the speed useful instead of expensive.

It also sits one layer above your existing Hub orchestration — Claude Design is the generative-design step upstream of code; the Hub handles the deterministic implementation step downstream. Two tools, one pipeline, one head (yours) doing the judgment in the middle.

---

## Quick reference (the 30-second version)

Before starting any session:

- Scope to **one surface**, not the whole app.
- Link the UI **subdirectory**, not the monorepo root.
- For upgrades: upload 2–3 screenshots of current state as context.
- For new apps: no codebase link, no design system.
- Budget one session per sitting. Don't chain.
- Stop iterating in the canvas at ~80%. Finish in Claude Code against real data.
- Commit handoff bundles to `design/<feature>/` in the target repo.
- Run `codebase-audit` on the resulting PR before merging.

If any of those don't make sense right now, read the relevant section below. Don't skip and wing it.

---

## Before your first session (one-time decisions)

### Design system: separate or shared?

Claude Design supports one design system per organization, with multiple systems per team. The default instinct is to build one system shared across all your apps. Don't, yet.

Your apps are genuinely different products with different audiences. The Hub is an operator's tool for you. Whatever comes next is something else. A shared design system locks you into consistency you haven't earned and prevents bold directions on new projects. When you have 4+ shipped apps that clearly share a soul, revisit.

**For now:** skip the published organization design system. Link the target repo at each project's start. More friction per project, more freedom per project.

### Budget reality

Claude Design uses your Pro/Max subscription quota. A single working session — design system setup plus a prototype plus iteration — can burn 50%+ of a weekly Pro allotment. This spend does **not** flow through the Hub's router or cost ceiling. Track it separately; check quota before starting anything substantive.

---

## Playbook A — Upgrading an existing UI

**When:** The app exists, you use it, a specific surface could feel better.
**Don't:** Use this as cover for a full rewrite. If you're tempted, that's a different conversation — have it first.

### The sequence

1. **Scope to one surface.** Not the app. Not the navigation + dashboard + detail views. One screen. Pick the one you look at most and most dislike.

2. **Link the specific subdirectory.** For the Hub PWA: `src/web/`, not the repo root. Large codebases cause lag and degrade Claude Design's ability to extract real patterns.

3. **Upload 2–3 screenshots** of the current state of that surface. Frame the task explicitly: *"This is what exists. The upgrade should evolve this, not replace it. Keep the information architecture; improve clarity, density, and state handling."* Without this framing, Claude Design treats the repo link as raw primitives and invents a new visual identity.

4. **Push on edge cases in the first 20 minutes.** Empty state. Loading state. The list with 4,000 rows. The row with a 10KB transcript. The error state for a failed sync. If you don't surface these in the canvas, you'll surface them in code review, which is slower and more expensive.

5. **Stop iterating in the canvas at ~80%.** Pixel-level spacing, color-token tweaks, animation timing — all of this is faster in Claude Code running against real data. The canvas is expensive and lies to you about data-driven layouts.

6. **Export the handoff bundle.** Commit it to `design/<surface>/bundle.json` (or whatever Claude Design produces) on a new branch `design/<surface>`. One bundle per surface; don't let `design/` become a junk drawer.

7. **Run `codebase-audit` on the resulting PR before merging.** Design-generated code is *exactly* the class of code where "renders correctly" hides "breaks theme tokens" or "bypasses the data layer." Your revised audit prompts exist for this moment — use them.

### Failure modes

- **Scope creep.** You upgrade the captures view; Claude Design suggests also reworking the nav; you accept. Now the PR is 4,000 lines and nothing gets reviewed properly. Catch this at step 4.
- **New visual identity masquerading as an upgrade.** The result is beautiful but doesn't look like your app anymore. Catch this by checking screenshots of the result alongside screenshots of the current state — side by side, not in sequence.
- **Breaking the theme system.** Claude Design uses hardcoded hex values instead of your existing tokens. The audit prompt catches this; don't skip step 7.

---

## Playbook B — Prototyping a new app

**When:** You have an idea; you want to see if it's worth building.
**Don't:** Confuse "I can see it" with "I'll use it."

### The sequence

1. **No codebase link. No published design system.** The whole value of exploration is unfamiliar directions. Constraining with existing patterns defeats the point.

2. **Generate 3–5 divergent directions.** Not variations of the same idea. Different answers to the question "what is this app." One minimal/utilitarian. One warm/opinionated. One spatial or canvas-driven. One deliberately weird. Pick directions you'd be embarrassed to show a stranger — that's where the signal lives.

3. **Kill four. Keep one.** Commit to a direction explicitly, out loud, in writing. "I'll refine all three in parallel" is the trap. You won't. You'll get distracted and ship none.

4. **Prototype 4–6 core screens, not 40.** The useful prototype answers "would I use this daily." Beyond six screens and you've committed to decisions the idea hasn't earned.

5. **Use it for a week before handoff.** Share the prototype URL to your phone. Actually try to use it. Note where your finger hesitates, where you tap the wrong thing twice, where you wish a button was somewhere else. One week of real use beats any amount of canvas iteration.

6. **Hand off to a fresh repo.** Not a branch on something existing. New repo, scratch-branch mentality. Ninety percent gets deleted. The ten percent that survives comes back into your real work having earned its place.

### Failure modes

- **Frictionless commitment.** The prototype looks so real you start treating it as a product before deciding whether it should be one. Step 5 is the circuit breaker — a week of boredom with your own idea is the cheapest product-killing test you have.
- **Stack lock-in.** The handoff bundle includes component library choices. If you're not sure about Next vs. Remix vs. vanilla Vite, decide *before* handoff — don't let Claude Design decide for you.

---

## Handoff to Claude Code (in VS Code)

The mechanical flow, because this is where it's easy to drift:

1. In Claude Design: **Export → Send to Claude Code.** Copy the command.
2. In VS Code: open the target repo. Checkout the right branch — `design/<feature>` for an upgrade, `main` of a fresh repo for a prototype.
3. Open the Claude panel. Paste the command. Let Claude fetch the bundle.
4. **Verify Claude actually sees the bundle before proceeding.** Ask it to summarize the component tree back in one paragraph. If it can't, stop and debug — do not proceed on vibes.
5. State the implementation target explicitly. Example: *"Implement this in `src/web/app/captures`, matching existing patterns in `src/web/app/runs`. Do not add new dependencies. Open a PR against `design/captures-v2` when done."*
6. Read every file in the diff. If you can't explain a block in plain language, ask Claude to walk you through it. Then decide whether you actually want it. "I don't understand this but the tests pass" is the debt you can't service later.
7. **Commit the handoff bundle alongside the code.** Future-you will want to know what spec the implementation came from. The bundle is cheap to store and priceless six months later when you're wondering why a component was built a certain way.

---

## Integration with the Hub orchestration system

**Don't build this until you've done the manual handoff at least twice.** You need to know what "implement against existing patterns" actually requires as a prompt, and you can't know that before you've done it by hand.

When you do build it, it's one new prompt in `hub-prompts`:

```yaml
id: design-implement
trigger: "push"
when: "files_changed.some(f => f.startsWith('design/'))"
```

The prompt takes a bundle path and a target directory, drives Claude Code headless, and opens a PR. Keep it narrow. It does not:
- Invoke Claude Design (no public API; and even if there were, this step needs taste)
- Handle multi-surface bundles (one surface per prompt run)
- Update design systems (pure taste work, stays manual)

One thing to add to the registry once this exists: auto-run `codebase-audit` on any PR opened by `design-implement`. This is what your audit prompts are for — design-sourced code is exactly the class they catch best.

---

## Budget discipline

- **Check your quota before starting.** Know what you have before you commit to a session.
- **One session per sitting.** Walk away between them. Chaining sessions is how you burn Tuesday's work on Monday.
- **If you're tweaking spacing or color, you're in the wrong tool.** Close the canvas, go to Claude Code, iterate against real data. The canvas is expensive; the running app is free.
- **Set up the design system in a separate session from real prototyping.** Combining them is how people run out of quota.

---

## What earns automation, what doesn't

**Automate eventually:**
- Claude Code's consumption of committed handoff bundles (the `design-implement` prompt).
- Running `codebase-audit` on design-sourced PRs.
- Archiving old bundles with links to their implementation PRs.

**Do not automate:**
- Claude Design invocation (the whole point is human taste at the wheel).
- Design system refinement (pure judgment work).
- Choosing which surface to upgrade next (pure judgment work).
- Deciding when a prototype has earned productization.

The pattern: automate the *deterministic* side of the pipeline. Keep the *generative* and *judgment* sides human.

---

## Self-check after each session

Five questions, honest answers:

1. Did I scope to one surface, or did I scope-creep?
2. Did I stop at 80% in the canvas, or did I burn tokens polishing pixels?
3. If a fresh collaborator opened the generated code tomorrow, would they recognize the project's patterns?
4. For prototypes: did I actually use it, or just admire it?
5. What's the one thing I'd do differently next session?

If question 1 is "scope-creep" twice in a row, shrink the next session deliberately. If question 3 is "no," run `codebase-audit` now, not later.

---

## Per-repo stub

Each app's repo should include a short `docs/PLAYBOOK.md` pointing to the canonical playbook, so Claude and Copilot inside that repo know the playbook exists. That stub lives in the `engineering-playbook` repo at `stubs/PLAYBOOK.md` — copy it into each project's `docs/` directory.
