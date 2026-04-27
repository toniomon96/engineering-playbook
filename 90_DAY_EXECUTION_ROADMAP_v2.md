# 90_DAY_EXECUTION_ROADMAP_v2.md

*Supersedes the original 90-day roadmap. The earlier version shipped infrastructure ahead of revenue. This version ships only what the first audit needs, then earns each next infrastructure step from real engagement evidence.*

# Week by week: narrowest viable Phase 0

The single biggest risk to this practice is over-operationalizing before the first audit. Every infrastructure decision in this roadmap is gated behind a real engagement event — a signed SOW, a completed engagement, a sustained second client.

**Principle: schemas before population, population before indexing, indexing before UI. Each step earns the next.**

## Week 1 — Site criticals + Texas op-doc rewrite + three core prompts

**Site cleanup (one PR, end of week):**
- Remove the "MSFT" credential callout from every surface on `tonimontez.co`
- Replace `tonio.montez@gmail.com` with `toni@tonimontez.co` (set up Google Workspace mailbox first)
- Replace every Bellevue/Seattle reference with McKinney/Dallas, Texas
- Update `astro.config.mjs`, `Base.astro`, `README.md`, `launch-checklist.md` from `toniomontez.com` to `tonimontez.co`
- Resolve "Operating System" vs "Operating Records" copy drift in favor of "Operating System" at every headline level

**Op-doc:** rewrite all Washington law references to Texas (§§ 15.50–.52). Mark interpretive statements as "attorney review required."

**Hub:** ship three core prompts to `hub-prompts/`:
- `coi-fit-screen`
- `client-diagnostic-prep`
- `requirements-from-diagnostic`

Each ships with full frontmatter, golden test cases, expected output schema, and change log per the prompts-as-versioned-software discipline.

**No infrastructure work this week beyond these three prompts.** No `clients.yml` yet. No `repositories.yml` yet. No pattern folder yet. The schemas exist as markdown specs; they don't get populated until there's something real to populate them with.

## Week 2 — Legal and financial spine

- LLC: file Form 205 via SOSDirect ($300 + ~$8 convenience fee)
- EIN: apply online at IRS.gov immediately after LLC approval
- Banking: Mercury account opened with EIN + Certificate of Formation
- Bookkeeping: QuickBooks Solopreneur subscription
- Workspace: Google Workspace on `tonimontez.co`
- Contracts: Bonsai account, customize SOW template with kill-fee, IP, scope, payment, and arbitration clauses
- Legal: 30-minute paid Texas employment-attorney consult
- E&O: Hiscox quote and bind ($50–$110/month range)

**Engineering-playbook updates:**
- Ship `REQUIREMENTS_WORKFLOW.md`
- Ship the four schemas: `REPO_REGISTRY_SCHEMA.md`, `ARTIFACT_FRONTMATTER_SCHEMA.md`, `SANITIZATION_POLICY.md`, `CODING_AGENT_CONTEXT_PACK.md`
- Ship `templates/`: `RUNBOOK.md`, `DECISION_LOG.md`, `REQUIREMENTS_PACKET.md`, `AUDIT_PACKET.md` (markdown templates only — no scripts)

**No hub extensions beyond what's already shipped.** The `clients.yml` and `repositories.yml` are deferred until you have a real client to put in them.

## Week 3 — First soft outreach

Three referrals, hand-selected from the existing network. Personal direct messages, not a mass email. Specific ask:

> "I'm running paid AI Upgrade Audits for the next four weeks at $1,500. Two-week turnaround. Output is a 5-page audit and a 60-minute walkthrough. Know anyone who'd benefit?"

Free intake form. Free 20-minute fit call. $1,500 audit. **No $250 paid diagnostic call yet** — defer until inbound volume justifies it.

**Goal:** one paid Audit booked by end of week 3.

## Weeks 4–6 — First engagement runs (Phase 0.5)

The first Audit runs end-to-end. Manually. **No knowledge harvesting infrastructure yet.** The point of this engagement is to discover what the harvesting infrastructure should actually look like.

During the engagement:
- Use the three core prompts (`coi-fit-screen`, `client-diagnostic-prep`, `requirements-from-diagnostic`)
- Produce all five requirements artifacts manually
- Run `codebase-audit` v3 on the client's repo
- Capture every decision in a markdown decision log
- Note every place a hub feature would have helped — these notes become the next infrastructure backlog

The retro is brutal. What worked, what didn't, what artifacts had value, what was bureaucracy. **The retro determines what gets built next.**

## Weeks 7–9 — First sanitized patterns + first overlay

Now there's real material. Phase 0.5 builds:
- `repositories.yml` populated with the first client repo and the existing internal repos
- `clients.yml` populated with the first client
- `patterns/` folder created with the first 3–5 sanitized patterns extracted from the first engagement's retro
- First industry overlay populated from the first engagement's vertical
- Sanitization policy applied for the first time, with the practitioner walking through every artifact and asking the explicit *"would I be comfortable if a competitor of this client read this?"* question

**No SQLite FTS5 yet. No `apps/web` cockpit views yet.** The pattern files are searchable via grep, which is fine for 3–5 patterns.

The site gets its first case study (anonymized if the client requires).

Second referral push goes out — three more contacts, this time including a soft pitch for the Operating System retainer.

## Weeks 10–12 — Second client onboarded

Second client lands — ideally a retainer, possibly a second audit. The second engagement uses the patterns and overlay produced from the first.

**The first measurable proof that the spine + skin model works** is whether the second engagement onboards 30%+ faster than the first.

Still no cockpit. Still no FTS5. Still no `/patterns` route. The grep-based pattern lookup remains adequate.

If the second engagement onboards meaningfully faster: the spine + skin model is validated. If it doesn't: the retro identifies why, and the patterns get rewritten before infrastructure gets built.

## Days 90–120 — Phase 1: index, then deferred UI

After two completed engagements with sanitized patterns, build:
- SQLite FTS5 indexing script (`scripts/index-patterns.ts`)
- `consulting-knowledge-sync` prompt running on cron weekly
- `generate-context-pack` script — generates scoped packs for coding agents per the schema spec

**Still no `apps/web` cockpit.** The index runs in the background; the practitioner queries via the CLI or grep.

## Days 120–180 — Phase 2: minimal cockpit, only if 2+ clients sustained

The cockpit ships only if both conditions hold:
1. Two or more active clients sustained for 30+ days
2. The grep/CLI pattern lookup has hit a real wall

Phase 2 ships in this order:
- `/patterns` search surface in `apps/web` (FTS5-backed)
- `/engagements/:client_id` per-client view (read-only)
- Push notifications for weekly digests, audit-finding alerts, COI re-screen reminders, MS approval annual re-affirmation

**Pipeline view, audit roll-up, decisions index, compliance tracker — all deferred to Phase 3 (post-month-9) unless a specific operational pain demands them.**

## Capacity points (replaces flat client cap)

Active capacity ceiling: **5 points**. The cap is operational, not symbolic — it constrains attention, not labor hours.

| Engagement type | Points |
|---|---|
| Operating System retainer | 2.0 |
| Launch Sprint | 3.0 |
| AI Upgrade Audit | 1.0 |
| AI Assistant retainer | 0.5 |
| Maintenance-only past client | 0.25 |

Examples:

```
Healthy:
  2 Operating System retainers   = 4.0
  1 AI Assistant retainer         = 0.5
                                  ----
  Total                           = 4.5  ✓

Too much:
  2 Operating System retainers   = 4.0
  1 Launch Sprint                = 3.0
                                  ----
  Total                           = 7.0  ✗ (decline or defer)
```

When totaled capacity exceeds 5, the next inbound goes to a waitlist or down-tier offer. The cap protects W-2 performance, family bandwidth, and high-judgment work — not abstract clientcount aesthetics.

## Explicit "what NOT to build" gates

- Do not build the Pipeline view in `apps/web` until 2+ active clients for 30+ days
- Do not build a second industry overlay until the first overlay's vertical has a second client
- Do not start writing on LinkedIn until three case studies exist
- Do not raise pricing until the third client books at the current band
- Do not hire a subcontractor or VA before month nine
- Do not buy paid ads in year one
- Do not build vector search before SQLite FTS5 hits a documented wall
- Do not populate `repositories.yml` or `clients.yml` until the first paid engagement is signed
- Do not build the `consulting-knowledge-sync` prompt until two engagements have produced sanitized patterns

## Cash flow expectations

| Period | Expected revenue |
|---|---|
| Month 1 | $0 (LLC formation, prep) |
| Month 2 | $1,500 (first audit) |
| Month 3 | $3,000 (audit converts to retainer + second audit) |
| Months 4–6 | $3,000–$5,000/month |
| Months 7–9 | $4,000–$6,000/month |
| Months 10–12 | $5,000–$8,000/month |

**Year-one floor target: $40,000 top line. Ceiling: $80,000.** Year two clears six figures if the band holds and three retainers stick.

## The headline

The previous roadmap shipped infrastructure ahead of revenue. This roadmap ships exactly what's needed to run the first audit, then earns each next infrastructure step from real engagement evidence.

**The first audit is the gate that turns this from a strategy doc into a practice.** Everything before the first audit is preparation. Everything after the first audit is iteration. The infrastructure backlog is filled by retros, not by planning.
