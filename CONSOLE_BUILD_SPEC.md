# CONSOLE_BUILD_SPEC.md

*The build specification for `console.tonimontez.co` — the personal control room for Toni Montez Consulting. Integrates the application roadmap, business roadmap, marketing playbook, decision log, and pipeline into a single private admin portal.*

---

## 1. The integration thesis

Every document in the consulting bundle has lived in a separate file until now. The 90-day roadmap is in markdown. The marketing playbook is in markdown. The decision log is in markdown. The pipeline doesn't exist yet. This works for a planning phase. It does not work for a running practice.

**The console makes the practice visible.** It reads from the markdown files where the bundle already lives, and surfaces them as a single pane: today's checklist, this week's roadmap gates, active engagements, the prospect pipeline, the marketing outreach log, the portfolio of past work. You operate the practice from one URL.

The discipline that protects this: **the console reads, it does not write.** Every artifact in the console has a corresponding markdown file in a private GitHub repo that you edit in your editor. The console renders what's there. No forms, no databases, no admin CRUD. The data model is git.

This is the inverse of how most admin portals are built, and it's deliberate. Forms create maintenance burden. Databases create sync problems. Markdown-over-GitHub creates a single source of truth that doubles as your existing work surface. The console becomes a *view layer* over the practice, not a parallel system.

## 2. Application architecture

**Stack.** Astro for the frontend (matches `tonimontez.co`). Tailwind for styling (matches the existing design system). The console lives in your existing `hub` repo at `apps/web` — same monorepo, same Vercel deployment story, separate domain.

**Auth.** GitHub OAuth via Auth.js. Single allowed user: your GitHub username. Anyone else hits a 404. No multi-user support. No invite flow. No password reset. One user, one purpose.

**Data layer.** Read-only over the GitHub API. The console fetches markdown from your private repos at request time, with a 60-second edge cache. No database, no Postgres, no Drizzle, no migrations. Every source file is a markdown file with YAML frontmatter, parsed with `gray-matter` on read.

**Domain.** `console.tonimontez.co` — separate Vercel project, same monorepo. The public consulting site stays at `tonimontez.co` and never has a `/admin` route.

**Deployment.** Vercel. Two projects: `tonimontez-co` (public) and `tonimontez-console` (private). Both deploy from the same monorepo, scoped by directory.

**Visual system.** Inherits from the consulting site: lowercase JetBrains Mono for headers and the wordmark, the `#00FF88` accent on the trailing period, the Steel Ledger color palette, RecordBlock-style components for data display. The console feels like the consulting site's private cousin — same DNA, different audience.

## 3. Information architecture

Seven surfaces, in priority order. Each surface answers a specific operating question.

**`/` — Dashboard.** *"What do I do today?"* Stat cards (active engagements, capacity, MRR, DMs sent), this-week checklist, pipeline counts, latest decision logged. The page you check every morning.

**`/roadmap` — Roadmap.** *"What gate am I behind, and what unlocks next?"* The v2 90-day roadmap rendered with phase gates, current phase highlighted, "what NOT to build until X" list visible. The doc that prevents you from building things you haven't earned yet.

**`/pipeline` — Pipeline.** *"Who's in the funnel, and what's the next action?"* Prospect list with stage (inbound / qualified / scheduled / proposed / signed / closed), filterable by stage, sortable by last contact. Click a prospect → detail view with COI screen, diagnostic notes, next action.

**`/engagements` — Engagements.** *"What's happening in active client work?"* Active client list with status, last update, next deliverable, capacity points used. Click an engagement → per-client detail view (read-only): the engagement's `clients.yml` row, recent decisions, runbooks list, audit findings if any.

**`/marketing` — Marketing.** *"Where is the funnel filling from?"* Outreach log (DMs sent, by date and status), referral source list, content drafts (when phase 1 hits), case studies index. The page that holds the discipline of "no LinkedIn writing until three case studies."

**`/repos` — Portfolio.** *"What does my body of work look like?"* Every repo with a `.repo.yml` rendered as a row. Sensitivity tier, type, status, last verified. Filterable by tier and type. The page that turns the portfolio classification work into a visible asset.

**`/decisions` — Decisions.** *"Why did I decide what I decided?"* Every decision-log entry across the playbook and active engagements, sorted by date, searchable by tag. The page that compounds — read in two years to see how thinking evolved.

## 4. Page-by-page spec

### `/` — Dashboard

The page rendered in the mockup above. Four stat cards on top, two-column "past artifacts + pipeline" mid-section, this-week checklist, future roadmap gates at the bottom.

**Stat cards.** Each card sources from a single markdown file or computed value:
- *Active engagements* — count of files in `engineering-playbook/engagements/` with `status: active` in frontmatter
- *Capacity used* — sum of capacity points from active engagements (Operating System retainer = 2.0, Launch Sprint = 3.0, Audit = 1.0, Vertical Assistant = 0.5, Maintenance = 0.25), shown as `X.X / 5`
- *MRR* — sum of `monthly_revenue` field across active engagements
- *DMs sent this week* — count of entries in `engineering-playbook/log/outreach.md` with date in current ISO week

**Past — proof artifacts panel.** Reads `.repo.yml` from every registered repo, filters to `repo_type` in `internal-product`, `personal-marketing`, `client-handoff-archive`. Sorted by `last_verified_at` descending.

**Now — pipeline panel.** Counts files in `engineering-playbook/pipeline/` grouped by `stage` frontmatter field. If zero across all stages, displays the warning: *"no inbound yet — send the dms"*.

**This week — checklist.** Parses `engineering-playbook/log/weekly.md`, finds the most recent `## week of YYYY-MM-DD` heading, renders the checkbox list under it. Strikethrough for `- [x]`, accent color for `- [ ] **bold**` items (priority).

**Future — roadmap gates.** Parses `90_DAY_EXECUTION_ROADMAP_v2.md`, extracts the phase sections, renders each phase with its gate condition. Currently active phase is highlighted with the accent color.

### `/roadmap` — Roadmap

The full v2 roadmap, rendered. Three sub-sections:

**This week.** The current week's content from `90_DAY_EXECUTION_ROADMAP_v2.md`, with the current week derived from the engagement state (`Week 1` if no engagements signed, `Weeks 4–6` if first audit is active, etc.).

**Phase gates.** All phase gates from the roadmap, with the current phase highlighted. Each gate shows: the unlock condition, what shipping looks like, what's deferred behind it.

**What NOT to build.** The roadmap's negative list, rendered as a panel. The page exists in part to make this list unavoidable to look at.

### `/pipeline` — Pipeline

**List view.** Table of every file in `engineering-playbook/pipeline/`. Columns: name, company, stage, last contact, next action, COI status. Filterable by stage (chips at top: inbound / qualified / scheduled / proposed / signed / closed). Sortable by last contact descending by default.

**Detail view (click a prospect).** Renders the prospect's markdown file as a structured page:
- Top: name, company, stage, frontmatter facts
- Middle: the markdown body (your notes from the call, observations, scope drafts)
- Bottom: action history derived from the file's git log (when stage changed, when fields updated)

A "next action" field at the top, parsed from frontmatter, rendered prominently. If `coi_status: green`, a small green dot. If `escalate`, amber. If `decline`, red.

### `/engagements` — Engagements

**List view.** Table of every file in `engineering-playbook/engagements/` with `status: active`. Columns: client, offering, started, capacity points, MRR, last status report. The empty state in phase 0.5 is explicit: *"no active engagements — first audit lands here"*.

**Detail view (click an engagement).** Per-client read-only page:
- Header: client name, offering, status, capacity points, MRR
- Frontmatter facts rendered as a card (the `clients.yml` row)
- Linked artifacts: the engagement's requirements packet, decision log, runbooks (read from the client repo via GitHub API if `repo_id` is set)
- Recent activity: last 5 commits to the client repo, last 3 decisions, last status report

**Out of scope for v0.5.** Status report editor, audit finding viewer, PR review surface. All deferred to phase 1+.

### `/marketing` — Marketing

**Outreach log.** Table view of `engineering-playbook/log/outreach.md`. Columns: date, name, channel, ask, status (sent / replied / declined / converted). Recent entries on top.

**Referral source list.** Reads `engineering-playbook/marketing/referrals.md` — your hand-curated list of people who might refer you, with notes on relationship and last contact. Used to drive the "three DMs this week" stat.

**Case studies.** Reads `engineering-playbook/marketing/case-studies/*.md`. Empty until the first engagement converts. Each case study is a markdown file with frontmatter (client, offering, outcome metrics) and body (the sanitized story).

**Content drafts.** Reads `engineering-playbook/marketing/posts/*.md`. Empty in phase 0–0.5; the gate in the v2 roadmap is "no LinkedIn writing until three case studies." This panel exists to enforce that — it stays empty as a visible reminder.

### `/repos` — Portfolio

Single table view of every repo with a `.repo.yml` manifest. Columns: repo_id, type, sensitivity tier, status, last verified. Filter chips at top: tier (1/2/3), type (internal-platform / internal-product / personal-marketing / client-engagement / client-handoff-archive / experimental).

Click a repo → detail page rendering its `.repo.yml` plus links to its key artifacts (ARCHITECTURE.md, decisions/, runbooks/) via GitHub API.

### `/decisions` — Decisions

**List view.** Every decision-log entry across `engineering-playbook/decisions/` and `engineering-playbook/engagements/<client>/decisions/`. Sorted by date descending. Filterable by tag (frontmatter `tags: []`), searchable by text.

**Detail view.** Renders the decision file: the decision, the alternatives considered, the reasoning, who decided, when. Shows linked decisions (via frontmatter `supersedes` or `related_to`).

This page compounds. After a year of practice, it's the most valuable surface in the console.

## 5. Data model — the markdown source files

Six new files (and one new directory pattern) are added to `engineering-playbook` to feed the console. Each is markdown with YAML frontmatter; each is editable in your editor and committed via git.

### `pipeline/<slug>.md`

One file per prospect. Created when a referral introduction lands in your inbox.

```yaml
---
name: "Sarah Chen"
company: "Bright Path Coaching"
stage: scheduled                 # inbound | qualified | scheduled | proposed | signed | closed
source: "Referral from Marcus"
intake_date: 2026-04-29
last_contact: 2026-05-02
next_action: "Run diagnostic call 2026-05-08 14:00"
coi_status: green                # green | escalate | decline | pending
budget_band: "$1,500-$3,000"
industry: "fitness-coaching"
current_systems: "Trainerize, Stripe, Gmail"
ms_overlap_check: clear
---

## 2026-04-29 — Initial intake
Marcus introduced Sarah. Solo coach, ~80 active clients,
running her business out of Trainerize and a chaos of
spreadsheets. Pain: client retention, manual billing
follow-ups eating ~6 hours/week.

## 2026-05-02 — Discovery email exchange
Confirmed budget band. Sarah wants the audit, not implementation.
Scheduled diagnostic for 2026-05-08.

## Next
Run client-diagnostic-prep prompt against this file, prep questions.
```

### `engagements/<slug>.md`

One file per active engagement. Created when an SOW is signed.

```yaml
---
client_id: example-corp
display_name: "Example Corp"
offering: operating-system          # operating-system | audit | vertical-assistant | launch-sprint
status: active                       # active | paused | completed | terminated
start_date: 2026-05-15
capacity_points: 2.0
monthly_revenue: 2000
end_date: null
repo_id: example-corp-os
vertical: home-services
sensitivity_tier_max: 3
ms_overlap_check_date: 2026-05-12
---

## Engagement summary
Example Corp Operating System retainer. Three-month
initial commitment, monthly renewal after.

## Active deliverables
- n8n automation spine for dispatch triage
- Weekly status reports via hub
- Decision log in client repo

## Recent status
See linked client repo: example-corp-os
```

### `log/weekly.md`

A single rolling file. New section added each Monday. Old sections stay for retrospective viewing.

```markdown
## Week of 2026-04-27

- [x] Ship Phase 0 schemas + three core prompts
- [ ] **Resolve audit pricing → $1,500 (update op_doc + bundle)**
- [ ] /start path A upgrade (company, industry, systems, budget)
- [ ] Ship engagement_start_checklist.md
- [ ] **Send three referral DMs**

## Week of 2026-04-20

- [x] Ship four schema docs to engineering-playbook
- [x] Ship 90_DAY_EXECUTION_ROADMAP_v2.md
- [x] Update master spec to reference v2
```

Bold items are priority. The console highlights them in the dashboard checklist.

### `log/outreach.md`

Append-only log. Every DM, every referral introduction, every cold-ish outreach — one line per contact event.

```markdown
| Date | Name | Channel | Ask | Status |
|---|---|---|---|---|
| 2026-04-29 | Marcus T. | LinkedIn DM | Audit referral ask | Replied — sent Sarah |
| 2026-04-29 | Priya S. | Email | Audit referral ask | Sent |
| 2026-04-29 | James K. | Text | Audit referral ask | Sent |
```

### `marketing/referrals.md`

Hand-curated list of potential referral sources. Edited deliberately — this is the list you DM from.

```yaml
---
last_reviewed: 2026-04-29
---

## Tier 1 — high signal, ready to ask
- **Marcus T.** — ex-MS, runs ops at Frontage, owes me one
- **Priya S.** — Austin tech network, fitness-adjacent
- **James K.** — old college friend, real estate operator

## Tier 2 — good network, save for round 2
- **Aisha R.** — coaching collective in Dallas
- **Daniel L.** — local SMB law firm
```

### `marketing/case-studies/<slug>.md` and `marketing/posts/<slug>.md`

Both empty in phase 0–0.5. Exist as directory placeholders. The gate is enforced by absence: no posts until three case studies exist.

## 6. Build phases

The console itself follows the same discipline as the rest of the bundle: ship the minimum that earns the next step.

### Console v0 — Dashboard + roadmap (this week)

**Routes shipped:** `/` (dashboard), `/roadmap`.

**Source files created:**
- `engineering-playbook/log/weekly.md` (with this week's content)
- `engineering-playbook/log/outreach.md` (empty table header)
- `engineering-playbook/marketing/referrals.md` (your hand-curated list)
- `engineering-playbook/pipeline/.gitkeep` (empty directory)
- `engineering-playbook/engagements/.gitkeep` (empty directory)

**Auth shipped:** GitHub OAuth, single-user allowlist. Hardcoded `ALLOWED_GH_LOGIN` env var.

**Out of scope for v0:** every other route, the pipeline detail view, the engagement detail view, search.

**Success criterion:** you load `console.tonimontez.co` Monday morning and see your week. The dashboard reflects reality. The roadmap shows you what gate you're behind.

**Build effort:** 2–3 days for a competent coding agent. Auth setup is half of that.

### Console v0.5 — Pipeline + repos (after first DM lands a reply)

**Routes added:** `/pipeline` (list + detail), `/repos`.

**Source files created on demand:**
- `engineering-playbook/pipeline/<first-prospect>.md` when the first qualified intake lands
- `clients.yml` populated when the first SOW is signed

**Out of scope for v0.5:** engagement detail beyond the basic frontmatter render, marketing surface, decisions surface.

**Success criterion:** when a referral introduces you to a prospect, you create the pipeline file, and the console reflects the new prospect within 60 seconds.

**Build effort:** 1–2 additional days.

### Console v1 — Engagements + marketing + decisions (after first audit ships)

**Routes added:** `/engagements` (list + detail), `/marketing`, `/decisions`.

**Source files now in active use:**
- `engineering-playbook/engagements/<first-client>.md`
- First decisions logged in the active engagement's decisions folder
- First case study drafted in `marketing/case-studies/`

**Out of scope for v1:** search, alerts, notifications, the cockpit's full Phase 2 surfaces from the bundle.

**Success criterion:** the console becomes the place you operate the practice from. You no longer open markdown files directly to find things — you go to the console.

**Build effort:** 2–3 additional days.

### Console v2+ — Search, alerts, push (gated behind 2+ sustained clients)

This is the bundle's `HUB_AS_COCKPIT_BLUEPRINT.md` Phase 2. SQLite FTS5, push notifications via the existing event trigger system, the audit roll-up, the compliance tracker.

**Do not build until 2+ active clients sustained for 30+ days.** This gate is in the v2 roadmap and is non-negotiable.

## 7. Integration with the business roadmap

The v2 90-day roadmap stops being a separate document and becomes the `/roadmap` page. The integration:

**Phase gates as roadmap milestones.** Each phase gate from the roadmap (`Phase 0`, `Phase 0.5`, `Phase 1`, `Phase 2`) renders as a panel on `/roadmap`. The current phase is computed from engagement state: zero engagements = Phase 0, one signed = Phase 0.5, two completed = Phase 1, two sustained × 30d = Phase 2.

**This-week checklist as living doc.** `log/weekly.md` becomes the source for both the dashboard checklist and the `/roadmap` "this week" section. Editing the markdown file updates both views.

**"What NOT to build" as visible constraint.** The negative list from the roadmap renders as a panel on `/roadmap`. The page exists in part to make this list unavoidable to look at.

**Cash flow expectations as a stat.** The roadmap's month-by-month revenue table is rendered on `/roadmap` as a small chart, with the current month highlighted and actual MRR overlaid (from `engagements/*.md`).

The discipline: the roadmap doc and the console can never disagree because the console reads from the doc. Edit the doc, the console updates.

## 8. Integration with marketing

The marketing playbook from the bundle becomes the `/marketing` page. The integration:

**Outreach log drives DM count.** `log/outreach.md` powers the dashboard's "DMs sent this week" stat. When you send a DM, you append a row. The dashboard reflects it on next load.

**Referral source list drives next-action thinking.** `marketing/referrals.md` is the curated list of people you can DM. When the dashboard shows "0 / 3 DMs sent" with the warning highlight, clicking through goes to `/marketing` where the referral list is the prompt.

**Case studies gate content.** `marketing/case-studies/` and `marketing/posts/` are both rendered on `/marketing`. The page makes visible the rule from the bundle: posts directory stays empty until case studies has three entries. The console enforces the discipline by showing the empty state.

**Anti-pattern list visible.** The bundle's "anti-pattern: AI automation agency" content renders as a panel on `/marketing`. Same discipline as the roadmap's negative list — visible because it's load-bearing.

## 9. The starter source files (commit these today)

Three files to create in `engineering-playbook` before the coding agent starts work. These are the data model. Once they exist, the console has something to read.

**1. `engineering-playbook/log/weekly.md`** — see schema in Section 5. Populate with this week's checklist from the synthesis: pricing decision, /start upgrade, engagement_start_checklist.md, three DMs.

**2. `engineering-playbook/log/outreach.md`** — table header only, no rows yet. The first row gets added when you send the first DM.

**3. `engineering-playbook/marketing/referrals.md`** — your hand-curated list of 5–10 names you'd actually DM. Tier 1 = ready to ask now; Tier 2 = save for round 2.

These three files take 30 minutes to write and commit. They unblock the entire console build.

## 10. Coding agent handoff

The build prompt for your coding agent. Paste this with the schema docs already attached.

> **Goal.** Build console v0 in `apps/web` in the existing `hub` repo. Two routes only: `/` (dashboard) and `/roadmap`. New routes only — do not touch existing surfaces.
>
> **Read first.** This file (`CONSOLE_BUILD_SPEC.md`), `90_DAY_EXECUTION_ROADMAP_v2.md`, the four schema docs from Phase 0 (`REPO_REGISTRY_SCHEMA`, `ARTIFACT_FRONTMATTER_SCHEMA`, `SANITIZATION_POLICY`, `CODING_AGENT_CONTEXT_PACK`).
>
> **Stack.** Astro + Tailwind. The console matches `tonimontez.co`'s visual system — JetBrains Mono headers, `#00FF88` trailing-period accent, Steel Ledger palette. Inherit the design tokens from the public site if they're shared via a package; otherwise mirror them.
>
> **Auth.** GitHub OAuth via Auth.js. Single-user allowlist via `ALLOWED_GH_LOGIN` env var. Anyone else returns 404.
>
> **Data layer.** Read-only via GitHub API. Use Octokit. Cache reads for 60 seconds at the edge. Parse markdown with `gray-matter`. Render markdown bodies with `marked` or equivalent.
>
> **Source repos.** Read from the user's `engineering-playbook` private repo. Files needed for v0:
> - `log/weekly.md` (parse current-week checklist)
> - `log/outreach.md` (count rows in current ISO week)
> - `90_DAY_EXECUTION_ROADMAP_v2.md` (parse phase sections)
> - `engagements/*.md` (count active, sum capacity points and MRR — directory may be empty in v0)
> - `pipeline/*.md` (count by stage — directory may be empty in v0)
>
> **Domain.** `console.tonimontez.co`. Configure as a separate Vercel project pointing at `apps/web`'s console subdirectory. The public consulting site at `tonimontez.co` stays untouched.
>
> **Acceptance criteria for v0.**
> - `console.tonimontez.co` loads with GitHub OAuth wall, only the allowlisted user can pass it
> - Dashboard renders the four stat cards with real data from real markdown files
> - Past artifacts panel renders from `.repo.yml` files across the user's repos
> - This-week checklist renders from `log/weekly.md`, with strikethrough on `[x]` and accent on bold-priority items
> - Future roadmap gates render from `90_DAY_EXECUTION_ROADMAP_v2.md` with current phase highlighted
> - `/roadmap` renders the full v2 roadmap with this-week, phase gates, and "what NOT to build" panels
> - 60-second edge cache on all reads
> - Empty states are explicit (e.g., "no active engagements — first audit lands here") not generic
> - No 500s when source markdown files are missing — render an empty state instead
>
> **Out of scope for v0.**
> - Pipeline route, engagements route, marketing route, repos route, decisions route — all deferred
> - Any form, any write operation, any database, any cron job, any FTS5 index, any vector search
> - Any cross-repo aggregation beyond reading `.repo.yml` files
> - Any push notification, any alert
>
> **Failure modes to flag, not work around.**
> - GitHub API rate limit hit: stop, log, ask
> - Source markdown file format mismatches the schema: stop, ask which version is canonical
> - Auth flow fails for the allowlisted user: stop, do not lower the auth bar to "make it work"
> - "Could just add a database for this" feeling: stop, the markdown-only constraint is the feature
>
> **Decision log requirement.** Every meaningful technical choice (auth library version, markdown parser, deployment config, edge caching strategy) gets a decision-log entry in `engineering-playbook/decisions/` per the existing convention.

That's the v0 prompt. After v0 ships and works, the v0.5 prompt adds `/pipeline` and `/repos`, with the same discipline.

## 11. The marketing rhythm — codified

The marketing playbook from the bundle stops being aspirational the moment the console exists. The weekly cadence:

**Monday.** Open `/`. Check this week's checklist. Note what's bolded (priority). Open `/marketing` if DMs are owed. Check `/pipeline` for prospects awaiting action.

**Friday.** Update `log/weekly.md` for next week. Note what shipped, what slipped, what's owed. The console reflects the new state Monday morning.

**Daily during active engagement.** Check `/engagements`. Read the recent activity. Decide what gets touched today.

**Quarterly.** Open `/decisions`. Read the decisions from the last 90 days. Look for patterns. Update `engineering-playbook/decisions/` with a quarterly synthesis decision.

This rhythm replaces the alternative — opening 12 markdown files in 12 different folders to figure out what to do. The console makes the practice operable in under five minutes a day.

## 12. The build sequence — explicit

In order, the most expensive failure mode at each step in parentheses:

1. **Today (30 min):** Commit the three starter source files: `log/weekly.md`, `log/outreach.md`, `marketing/referrals.md`. *(Failure mode: starting the coding agent before the data model exists.)*

2. **This week (2–3 days):** Coding agent ships console v0 (dashboard + roadmap). *(Failure mode: scope expanding to "while we're at it, let's build pipeline too." It doesn't.)*

3. **Same week (30 min):** Send three referral DMs. *(Failure mode: shipping the console replaces sending the DMs. The console exists to make sending DMs easier, not to replace the act.)*

4. **When the first reply lands:** Create the first pipeline file. Watch the console reflect it. *(Failure mode: not creating the pipeline file because "it's just one prospect, I can remember it." The discipline of writing it down is the practice.)*

5. **When the first prospect converts to scheduled diagnostic:** Coding agent ships console v0.5 (pipeline detail + repos). *(Failure mode: building v0.5 before the first prospect exists. There's nothing to view.)*

6. **When the first audit ships:** Coding agent ships console v1 (engagements + marketing + decisions). *(Failure mode: building v1 before there's an engagement to show.)*

7. **When two clients have run for 30+ days:** Decide whether v2 (search, alerts, push) is earned. *(Failure mode: deciding before the gate is met.)*

The console grows with the practice. Each phase ships exactly when there's real material to view. The console is never ahead of the work — it's a render of the work.

---

*End of build spec. The console is the answer to "everything is in too many files." The discipline is that the console reads, the markdown is the truth, and every phase ships only when the phase before it has produced something real to render.*
