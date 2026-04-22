# Architecture Doc Generation Prompt

*The prompt used to generate and maintain `ARCHITECTURE.md` files in project repos. Invoke via Claude Code in any target repo.*

*Last reviewed: TBD*

# Architecture Doc Generation Prompt

*The prompt used to generate and maintain `ARCHITECTURE.md` files in project repos. Invoke via Claude Code in any target repo. Every project gets its own ARCHITECTURE.md produced by this prompt.*

*Last reviewed: 2026-04-22*

---

## When to use this

- **First time in a repo:** to generate an initial `ARCHITECTURE.md` at the repo root.
- **After a significant change:** to refresh the existing doc against the current state of the code.
- **Before handing a repo to a fresh agent session:** to make sure the doc is current so the agent onboards from truth, not drift.

## How to invoke

In Claude Code, in the target repo's root, paste the **Prompt** section below. Claude Code reads the repo, produces or updates `ARCHITECTURE.md`, and opens a PR (or commits directly, depending on your preference — state that in the invocation).

If `ARCHITECTURE.md` already exists, Claude Code updates it in place, preserving any human-added sections and the Decision Log in full.

---

## Prompt

> You are generating or updating the canonical `ARCHITECTURE.md` for this repository. This file lives at the repo root and is the single context document a fresh Claude or Copilot session reads to understand the project. It is committed to git and referenced via raw URL from other sessions, so it must be accurate, concise, and written as durable prose — not a snapshot of what you happen to have in context right now.
>
> ### Your task
>
> 1. Read the repo thoroughly before writing. At minimum:
>    - Root-level config (`package.json`, `pyproject.toml`, `Cargo.toml`, `tsconfig`, etc.)
>    - The entry point(s) — `src/main.ts`, `apps/*/src/main.ts`, equivalent
>    - Any existing `ARCHITECTURE.md`, `README.md`, `CLAUDE.md`, `AGENTS.md`, `.cursor/rules`
>    - The shape of the `src/`, `packages/`, or `apps/` tree (two levels deep is usually enough)
>    - Any migration, schema, or types files that define the data model
>    - Recent commits (`git log --oneline -n 30`) to understand what's active
>    - Open PRs and recent issues if accessible
>
> 2. If `ARCHITECTURE.md` already exists, preserve:
>    - Any `## Decision Log` or `## Decisions` section in full
>    - Any human-authored prose that isn't auto-derivable from code (voice, philosophy, intentional non-goals)
>    - Section order the author already chose, unless a section is now genuinely wrong
>
>    Update everything else against current reality.
>
> 3. Produce a document that answers — concisely — every question a fresh agent would ask before touching the code.
>
> ### Required sections
>
> Include each of the following. Omit a section only if it genuinely doesn't apply (e.g. "Permission tiers" for a library); note the omission with a one-line explanation rather than leaving it out silently.
>
> - **Topology** — an ASCII diagram of the system's shape: components, the major external services they talk to, the data stores. This is the map. Keep it to one screen height.
>
> - **Tech stack** — language, runtime, framework, key libraries. One line each. Include version floors only if they're load-bearing (e.g. "Node ≥22.5 for `node:sqlite`").
>
> - **Component guide** — the 3–8 top-level components or packages, one paragraph each. What it does, what it depends on, what calls it. Not a file listing; a map of responsibilities.
>
> - **Key flows** — 2–5 representative end-to-end flows (user request in → effect out). Written as short numbered sequences. The goal is "if I'm asked to change how X happens, I know where to start."
>
> - **Data model** — the core tables, collections, or types. One line per entity, noting the 2–3 fields that actually matter. Not a schema dump.
>
> - **State layers** — if the project has multiple state stores (e.g. SQLite + a vault + a third-party service), name each and describe what's authoritative where.
>
> - **Conventions that matter** — the *decisions* a newcomer would miss. Not style (formatters handle that). Examples: "all agent execution acquires a lease before running," "every HTTP route is zod-openapi typed," "router rules are first-match-wins and order is load-bearing." Three to ten items, each one sentence.
>
> - **Scheduler / orchestration** — if the project has cron, queues, webhooks, or event triggers, describe the authoritative scheduler and how concurrency is prevented.
>
> - **Permission tiers / authority levels** — if the project has actions with different risk profiles (auto / confirm / irreversible), include a small table. Omit for libraries and tools that don't take actions.
>
> - **Decision Log** — a running list of non-obvious architectural calls. Format: one bullet per decision, two to three sentences: what, why, and what alternative was rejected. If one already exists, preserve every entry. If generating fresh, seed it with the 2–3 decisions most evident from the code and mark them `(inferred — verify)`.
>
> - **Known limitations** — what's fragile, what's partial, what will bite a maintainer who doesn't know. Honesty beats exhaustiveness.
>
> - **What's NOT in scope** — explicit non-goals. Things the project deliberately does not do, features that were considered and rejected, or work deferred to a future version.
>
> ### Style rules
>
> - **Under 500 lines.** If it's longer, you've included too much. The cost of a stale doc nobody reads is higher than the cost of an omission.
> - **Prose, not lists of lists.** Bullet points are appropriate for the tables above and for "Conventions that matter." Everywhere else, write sentences.
> - **Specific over comprehensive.** "The router is first-match-wins across five rules defined in `packages/models/src/router.ts`" beats "The system has a flexible routing layer."
> - **Name files and symbols.** Paths (`packages/prompts/src/edit.ts`) and function names (`dispatchPromptRun`) make the doc searchable and reduce re-derivation. Use them.
> - **Flag uncertainty.** If you're not sure how something works, write `(inferred — verify)` at the end of the sentence. Do not fabricate confidence. The author will either confirm or correct on review. A doc that says "I'm not sure" in three places beats a doc that says three plausible-but-wrong things.
> - **Don't describe what the code obviously shows.** Describe what a reader can't easily derive: why the choice, what the alternative was, where the load-bearing invariants are.
> - **No marketing voice.** No "blazingly fast," no "robust," no "elegant." Just the facts a maintainer needs.
>
> ### Delivery
>
> Write the doc to `ARCHITECTURE.md` at the repo root. If this is an update to an existing file, produce the full new content — not a diff or a patch description.
>
> End the doc with a single line: `*Last reviewed: YYYY-MM-DD*` using today's date.
>
> After writing, print a three-sentence summary of what changed compared to the previous version (or, if generating fresh, what the three most load-bearing pieces of the architecture are). This summary is for the human reviewer, not the committed file.

---

## Maintenance

- Run this prompt after any significant architectural change — new subsystem, major refactor, deprecated component.
- Re-run quarterly as a backstop, regardless of whether anything changed. The drift between "what the code does" and "what ARCHITECTURE.md says" accrues silently.
- The Decision Log is the highest-value section and the one most likely to rot. When you make a non-obvious call, write the entry in the same commit as the code change, not later.
- If the generated doc gets something wrong, fix the doc *and* consider whether this prompt needs a tweak. Prompt drift is cheaper to fix than ARCHITECTURE.md drift.
