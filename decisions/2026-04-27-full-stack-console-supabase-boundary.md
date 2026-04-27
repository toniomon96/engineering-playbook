---
artifact_id: art_2026_04_27_full_stack_console_supabase_boundary
artifact_type: decision
title: "Full-stack console Supabase boundary"
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
  - console
  - supabase
  - vercel
  - intake
  - todos
allowed_context_consumers:
  - hub-indexer
  - cross-engagement-agents
sanitized: true
sanitization_review_at: 2026-04-27
sanitization_reviewer: toni
supersedes: null
---

# Decision: Full-stack console Supabase boundary

## Date

2026-04-27

## Owner

Toni Montez

## Status

accepted

## Context

Console v0 made the consulting practice visible from markdown, manifests, and roadmap files. The next operating need is action management: todos, outreach, and inbound intake should be manageable from the private console without turning the playbook into a mutable database or turning the public consulting site into an admin surface.

The Hub web app and consulting site are both deployed on Vercel. Hub also has a Railway-hosted Hono runtime for legacy agent APIs, SQLite-backed capture/run data, cron, and webhook behavior. Toni also has Supabase available as the managed Postgres layer.

## Decision

Use Supabase as the live operational data layer for the consulting console's first writable slice:

- `admin_todos`
- `outreach_events`
- `intake_submissions`

Keep `consulting` and `hub` as separate Vercel apps. `consulting` remains the public intake surface. `hub` remains the private operator console. Supabase connects them through server-side endpoints.

Add focused Vercel Functions in Hub for consulting-console operations while leaving legacy Hub APIs, auth, webhooks, health checks, SQLite data, cron jobs, and agent-runtime behavior on the existing Railway server until a separate backend migration is justified.

Keep `engineering-playbook` as the source for schemas, templates, roadmap, decisions, and operating doctrine. It is not the mutable todo/outreach backend.

## Rationale

This gives the admin console the missing operational loop without building a CRM, billing system, client portal, search index, or full cockpit. Todos and outreach are the immediate business actions Toni needs to manage. Intake submissions are the bridge between the public site and private operator workflow.

The boundary keeps each app in its lane:

- Public site sells and collects context.
- Private Hub console operates the practice.
- Engineering playbook defines standards and source documents.
- Supabase stores live operational records.

Server-side Vercel Functions keep Supabase secret keys out of browser bundles and let the new console APIs run on the same Vercel surface as the Hub UI.

## Alternatives Considered

| Option | Why not |
|---|---|
| Keep todos/outreach only in markdown | Safe for v0, but it cannot support real console-based todo management without editing files. |
| Move all Hub data from SQLite to Supabase now | Too broad. Agent runs, embeddings, prompts, cron, and capture history are a separate migration. |
| Add Supabase directly from the browser | Exposes more auth/RLS surface than needed for a single-user private console. |
| Merge consulting and Hub into one repo/app | Conflates public marketing with private operations and creates unnecessary deployment coupling. |
| Build a CRM or pipeline dashboard now | Overbuilds before the first paid audit and violates the Phase 0 gate discipline. |

## Consequences

- Positive: the console can manage todos, outreach, and inbound intake as real business records.
- Positive: the public site can feed the private operator workflow without becoming an admin app.
- Negative: Vercel now has a split API surface: consulting-console functions run locally on Vercel while legacy Hub APIs still proxy to Railway.
- Negative: Supabase migrations and environment variables become a manual deployment gate.
- Follow-up: after this slice is stable, decide whether any legacy Hub SQLite tables should move to Supabase. Do not migrate embeddings, runs, prompts, or cron jobs in this pass.

## References

- `hub/supabase/migrations/202604270001_consulting_console_ops.sql`
- `hub/api/console/dashboard.ts`
- `hub/api/console/todos.ts`
- `hub/api/console/outreach.ts`
- `hub/api/intake.ts`
- `consulting/src/components/ContactIntake.astro`
