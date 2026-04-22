# Agent-Assisted Engineering Handbook

*Last reviewed: TBD*

# Agent-Assisted Engineering: An Operator's Handbook

*For experienced engineers building ambitiously with coding agents*

*Last reviewed: 2026-04-22*

---

## The premise

You already know how to build software. The question isn't how to code — it's how to direct a fleet of capable-but-brittle agents without losing the thread, the quality, or the learning. This handbook is a working doc, not a manifesto. Adopt what earns its keep. Discard the rest.

Three ideas sit underneath everything:

1. **You are a technical director, not a typist.** Your leverage is judgment — what to build, what "good" means, when to stop.
2. **Agents are powerful and wrong.** They produce plausible code at a rate that outstrips your ability to catch subtle mistakes unless you have systems for it.
3. **Ambition and rigor are not opposites.** The engineers shipping the most interesting work are also the ones with the tightest verification loops. Speed comes from trust, and trust comes from being able to check.

---

## How to decide what to delegate

Before starting anything, ask two questions: *How reversible is this?* and *How well can I verify the result?*

**Hand it off** when both answers are "easy." Scaffolding, CRUD, migrations with tests, refactors with green suites, codemod-style changes, one-shot scripts, most documentation, exploratory spikes you'll throw away.

**Pair with it** when one answer is "easy" and the other is "hard." New features with clear specs, unfamiliar-code bug fixes, library integrations, perf work with a benchmark. You drive the spec and review; the agent drafts.

**Drive it yourself** when both answers are "hard." Architecture that's expensive to change, anything touching auth/money/PII, concurrency primitives, public APIs, data migrations against production, novel algorithms where correctness isn't obvious from reading.

The triage is not about ego — it's about where agents currently fail. They fail silently on subtle correctness, security boundaries, and decisions whose consequences surface months later. Those are the places you stay hands-on.

---

## Context: enough, not maximal

More context isn't better. Relevant context is better. A bloated context file is worse than none because it dilutes attention and ages poorly.

Start with **one** living doc in the repo root — call it whatever your tooling reads by default (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules`, etc.). Keep it under two pages. It should answer:

- What is this project and who uses it?
- What stack, and what are the non-obvious constraints?
- What conventions actually matter here? (Not style — your formatter handles that. The *decisions* that would surprise an outsider.)
- What's in scope right now, and what's explicitly off-limits?
- How do I run, test, and deploy?

Split the doc only when it genuinely outgrows itself — usually around the point where the project has multiple subsystems with different contributors or conventions. Resist ceremony. A stale `DECISIONS.md` is a liability; a short, fresh doc is an asset.

One specific habit worth the effort: when you make a non-obvious architectural call, write a three-sentence note about *why* and stash it somewhere the agent can see. You'll forget your own reasoning within a month. The agent will propose undoing your decision for the third time, and you'll be grateful you wrote it down.

---

## The verification loop (this is where most vibe coding dies)

The single biggest difference between engineers who ship solid work with agents and those who ship landmines is how seriously they take verification. If you skip this section, skip the whole doc.

**Tests are the contract, not a chore.** Before asking an agent to implement anything non-trivial, either write the test yourself or have the agent write tests *first* and review them before it writes the implementation. Tests the agent wrote after the fact tend to test what the code does rather than what it should do.

**Types, linting, and compilers are free labor.** Turn on strict mode. Let the toolchain catch what it can before your eyes have to.

**Read every diff.** Not skim — read. If you can't explain a block in plain language, that's your signal to slow down, ask the agent to walk you through it, and then decide whether you actually want it. "I don't understand this but the tests pass" is how you accumulate debt you can't service.

**Run it, don't just read it.** Agents hallucinate APIs that don't exist, imports that don't resolve, and behaviors that pass review but fail at runtime. Execute the code, exercise the path, watch it work.

**For anything touching user trust:** threat-model it yourself. Auth, payments, PII, file uploads, anything user-submitted that gets rendered or executed. Agents are especially prone to confident-sounding mistakes in security-adjacent code because the surface pattern looks right.

This is not bureaucracy. This is what lets you delegate aggressively without getting burned.

---

## Pushing ambition without losing control

The original doc you shared had the right instinct here — defaults drift toward safe — but some of its forcing functions were expensive habits dressed up as principles. Here's a tighter version:

**Prototype separately from production.** Keep a scratch branch or a separate throwaway repo. When you want to explore something wild — a different architecture, a new framework, an AI-first feature — do it there with the brakes off. Ninety percent gets deleted. The ten percent that survives comes back into the real codebase having earned its place.

**Use parallel generation selectively.** Not for every decision — that's a tax. Use it at genuine forks: the choice of data model, the shape of a core abstraction, the user flow for a critical feature. For those, "give me three approaches with tradeoffs" is worth its cost. For everything else, just pick something reasonable and move.

**Steal from outside your domain.** When you're stuck, the most useful prompt is rarely "how do I do X better" — it's "how do fields unlike mine solve the analogous problem?" Game engines for UI responsiveness. Compilers for DSL design. Biology for resilience patterns. The cross-pollination instinct in the original doc was right; keep it.

**Raise the quality bar past "working."** Once something works, ask the agent: what would this look like if we cared about it three levels deeper? Better error messages. Handling the weird edge case you shortcut. The animation that makes it feel alive. The empty state that teaches. Immaculate apps are made in this pass, not the first one.

**Define "immaculate" for your project.** Different products have different quality vectors — latency, correctness, delight, accessibility, offline behavior, graceful degradation. Pick the two or three that matter most and measure them. Otherwise "quality" becomes a feeling, and feelings drift.

---

## When *not* to use the agent

This is the section the original doc was missing, and it matters.

- When writing it yourself would take less time than specifying it clearly.
- When you're learning something new and the point is to internalize it.
- When the problem is small but the stakes are high — a five-line change to an auth check is faster to write and reason about than to delegate and review.
- When you're debugging and the bug is in your mental model, not the code. An agent will happily patch symptoms.
- When you're tired. Agents amplify judgment; poor judgment at 1 a.m. ships worse code at 10x speed.

Reaching for the agent reflexively is its own failure mode. The best operators I've seen are *selective*, not maximal.

---

## Secrets, keys, and the stuff that hurts if it leaks

Low-glamour, high-consequence:

- Never paste secrets into a chat with any agent. Assume everything in context may be logged somewhere.
- `.env` in `.gitignore`, always. Verify before first push.
- If an agent proposes committing a config file, read it byte-by-byte before accepting.
- Rotate anything that might have leaked. It's five minutes; the alternative is days.
- For agents that can execute code or touch the filesystem: understand what permissions you've granted. "It seemed to work" is not a security posture.

---

## Version control discipline

An agent can rewrite two hundred files in a minute. Your undo button is git.

- Small, frequent commits with honest messages. "Agent refactored auth module" is a real message and a useful one.
- A branch per feature, always. Even for solo work. Especially for solo work.
- Before a big agent-driven change, commit the clean state. Before a risky one, tag it.
- If a session goes sideways, throw away the branch. Don't try to salvage bad agent output by patching it — start fresh with better context.

---

## Keeping your edge

The real risk of agent-assisted work isn't bad code. It's skill atrophy you don't notice until you need it.

- **Explain-back rule.** After any significant feature, write three sentences in your own words about how it works. If you can't, you don't understand it yet.
- **One deep dive a week.** Pick one thing an agent introduced you to — a library, a pattern, a technique — and actually study it. Read the source, not just the docs.
- **Occasional cold-start days.** Build something small without the agent. Muscle memory matters. You don't want to discover you've lost it during an incident.
- **Read code you didn't ship.** Great open-source projects, your dependencies, the framework you use every day. Taste is pattern recognition; pattern recognition needs input.

---

## A useful agent kickoff template

Not a ritual. A checklist you can skip when it's obvious.

Project context: see [file].
Task: [what, specifically]
Out of scope: [what not to touch]
Verification: [how I'll know it's right — tests, manual steps, a command]
Mode: [propose-first | just-do-it | explain-as-you-go]
Flags I want raised:

Anything that changes [a specific thing you care about]
Any dependency additions
Anything that touches [sensitive area]

The "Mode" line is the most underused. Telling an agent *how* to collaborate — propose before doing, or just execute, or teach you as it goes — is a small prompt change with a big effect on the output.

---

## Weekly self-check

Five minutes, honest answers:

1. Is there code I merged this week I couldn't reconstruct from memory?
2. Did I verify or did I vibe?
3. What's the most ambitious thing I attempted, and did I learn something from it?
4. What felt like friction, and is there a one-time fix?
5. What am I going to try next week that I haven't tried before?

If #1 is "yes" more than once, slow down. If #3 is empty more than two weeks running, you've drifted into maintenance mode — force an exploration day.

---

## The posture

You are not trying to automate yourself out of the loop. You are compressing the distance between idea and working system, while keeping your hands on the wheel in the places that matter. The goal isn't to type less. It's to ship work you're proud of, at a pace that would have been impossible five years ago, without losing the craft that makes the output good in the first place.

Build deliberately. Verify ruthlessly. Explore without apology. Understand what you ship.

Everything else is just tooling.
