---
artifact_id: art_2026_04_27_console_v0_source_architecture
artifact_type: decision
title: "Console v0 Source Architecture"
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
  - architecture
  - auth
  - source-adapter
allowed_context_consumers:
  - hub-indexer
  - cross-engagement-agents
sanitized: true
sanitization_review_at: 2026-04-27
sanitization_reviewer: toni
supersedes: null
---

# Decision: Console v0 source architecture

## Date

2026-04-27

## Owner

Toni Montez

## Status

accepted

## Context

Console v0 is the private operator surface for Toni Montez Consulting. The original build spec assumed an Astro app reading GitHub-hosted markdown, but the existing Hub web app is Vite React with an Hono server and an existing `HUB_UI_TOKEN` auth wall. The console should be additive inside Hub, read the engineering playbook as its canonical source, and avoid creating a database, index, CRM, or write surface.

Before implementation, the source files were migrated from OneDrive into `engineering-playbook` so Console v0 never depends on OneDrive paths at runtime.

## Decision

Ship Console v0 with Option B: a runtime source adapter.

- In development, the adapter reads from the local filesystem under `engineering-playbook`.
- In production, the adapter can read the same paths from GitHub contents using a read-only token and configured repo/ref.
- The console is mounted at `/console` inside `hub/apps/web`; the existing Hub `/` dashboard remains untouched for v0.
- The v0 API is read-only and returns parsed markdown/manifests plus explicit warnings and empty states.
- Auth uses the existing `HUB_UI_TOKEN` cookie wall for v0.

Re-open auth and switch to GitHub OAuth/Auth.js when either condition becomes true:

- A second user needs read access.
- The deployed console is shared outside Toni's private laptop/operator workflow.

## Rationale

Option B fits the real codebase while preserving the deployment path. Static rendering would be elegant if the deployed build could read a sibling `engineering-playbook` checkout, but the Hub app deploys as its own repo surface. Runtime adapters keep local work fast, production viable, and the UI independent from the storage mechanism.

The existing token wall is enough for a single-user private operator console. GitHub OAuth would add configuration and user-management burden before it earns its keep. The explicit re-open trigger prevents that deferral from becoming accidental permanence.

Manifest parsing must report and surface validation failures instead of rejecting an entire repo panel. The portfolio is still being brought into schema compliance, so non-compliant `.repo.yml` files should remain visible with warning states.

## Alternatives Considered

| Option | Why not |
|---|---|
| Option A: static render at build time | Normal Hub deployment cannot assume a sibling `engineering-playbook` checkout without adding sync/checkout machinery. |
| Option C: GitHub API in all environments | Adds token setup and network dependency to local development even though the canonical files are already on Toni's laptop. |
| GitHub OAuth/Auth.js for v0 | More auth surface than a one-user private console needs. Revisit when a second reader or external sharing appears. |
| Strict manifest rejection | One malformed `.repo.yml` would make the portfolio panel disappear instead of showing the repo and the repair needed. |

## Consequences

- Positive: local development reads real markdown immediately, production still has a GitHub-backed path, and v0 stays additive inside Hub.
- Negative: the adapter layer has two operating modes to keep aligned.
- Follow-up: after v0 ships, decide whether `/console` becomes the primary dashboard, merges the existing Hub dashboard, or leaves `/` explicitly deprecated.
- Follow-up: when `tonimontez.co` ships its next design-token pass, extract shared tokens into a package instead of continuing manual duplication.

## References

- `CONSOLE_BUILD_SPEC.md`
- `90_DAY_EXECUTION_ROADMAP_v2.md`
- `CODING_AGENT_CONTEXT_PACK.md`
- `REPO_REGISTRY_SCHEMA.md`
- `SANITIZATION_POLICY.md`
