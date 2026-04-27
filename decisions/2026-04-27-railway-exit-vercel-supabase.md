---
artifact_id: art_2026_04_27_railway_exit_vercel_supabase
artifact_type: decision
title: "Railway exit to Vercel and Supabase"
repo_id: engineering-playbook
client_id: null
engagement_id: null
source_repos:
  - engineering-playbook
  - hub
  - consulting
sensitivity_tier: 2
status: active
created_at: 2026-04-27
last_verified_at: 2026-04-27
tags:
  - railway-exit
  - vercel
  - supabase
  - hub
  - console
allowed_context_consumers:
  - hub-indexer
  - cross-engagement-agents
sanitized: true
sanitization_review_at: 2026-04-27
sanitization_reviewer: toni
supersedes: null
---

# Decision: Railway exit to Vercel and Supabase

## Date

2026-04-27

## Owner

Toni Montez

## Status

accepted

## Context

Hub currently has a split deployment shape: the private web app is deployed on Vercel, but legacy API, auth, health, cron, webhooks, SQLite-backed state, and local agent runtime assumptions still depend on Railway. The consulting console now has Supabase-backed todos, outreach, and intake, so the next infrastructure move is to remove Railway intentionally instead of continuing to run two hosted backends.

## Decision

Move hosted Hub runtime responsibilities from Railway to Vercel Functions and move persistent hosted state from SQLite to Supabase.

The migration is phased:

- Vercel owns auth, health, console APIs, intake, status, cron endpoints, and webhook receipt routes first.
- Supabase stores cloud-readable Hub tables: captures, runs, briefings, projects, feedback, prompts, prompt targets, agent locks, cron run logs, webhook receipt logs, and consulting operations tables.
- Existing Vercel rewrites keep unported legacy APIs on Railway until those routes are migrated.
- Embeddings, vector search, Obsidian vault writes, Ollama, desktop MCP, shell access, and local filesystem actions stay out of cloud functions and require a future local worker.

## Rationale

Vercel is already the deployment home for the Hub UI and consulting site. Supabase is the right managed Postgres layer for operational records. Moving the hosted runtime there simplifies the platform footprint without collapsing public marketing, private operations, and internal playbook repos into one app.

Keeping a local-worker boundary is load-bearing. Some Hub behavior is not cloud-hostable as-is because it depends on local files, local model runtimes, desktop tools, or shell access. Returning explicit "local worker required" states is more honest than hiding those failures behind cloud endpoints.

## Alternatives Considered

| Option | Why not |
|---|---|
| Keep Railway indefinitely | Leaves two hosted backends for one private operator surface and keeps SQLite/cron/webhook responsibilities on a platform Toni wants to retire. |
| Move everything in one pass | Too risky. It would mix API migration, DB migration, cron migration, local runtime redesign, and deployment cleanup in one change. |
| Merge consulting, Hub, and playbook into one repo | Breaks the clean separation: consulting sells, Hub operates, engineering-playbook defines discipline. |
| Run local-only actions inside Vercel Functions | Vercel Functions cannot safely own desktop filesystem, shell, Obsidian, Ollama, or MCP assumptions. |

## Consequences

- Positive: Vercel becomes the hosted API/runtime layer for the private admin console.
- Positive: Supabase becomes the managed operational database for consulting and cloud-readable Hub state.
- Positive: Railway can be removed after legacy routes pass smoke tests on Vercel.
- Negative: there is a transitional period where some `/api/*` routes still proxy to Railway.
- Negative: cloud cron endpoints can record and gate jobs, but local-only jobs need a future worker before they can fully execute off Railway.
- Follow-up: after Vercel status, auth, cron, webhooks, and one legacy API route are verified, migrate the remaining legacy API routes from SQLite to Supabase and then remove the Railway rewrites.

## References

- `hub/vercel.json`
- `hub/supabase/migrations/202604270002_hub_cloud_runtime_foundation.sql`
- `hub/scripts/export-sqlite-to-supabase.mjs`
- `hub/api/status.ts`
- `hub/api/cron/[job].ts`
- `hub/api/webhooks/[source].ts`
- `hub/docs/CONSULTING_CONSOLE_FULL_STACK.md`
