# ARTIFACT_FRONTMATTER_SCHEMA.md

# Artifact frontmatter: every markdown file carries its own metadata

Every consequential markdown artifact — pattern, decision, runbook, requirements packet, audit packet, retro doc, overlay — carries YAML frontmatter that the hub indexes. Without this, the cross-repo pattern search degrades into grep, and the sanitization policy cannot be enforced.

## The frontmatter

```yaml
---
artifact_id: art_2026_05_01_intake_triage      # snake_case, globally unique
artifact_type: pattern                          # see types below
title: "Lead intake triage workflow"
repo_id: example-corp-os
client_id: example-corp                         # null for non-client artifacts
engagement_id: eng_2026_05_example_corp
source_repos:                                   # repos this artifact draws from
  - example-corp-os
sensitivity_tier: 2                             # tier of this artifact specifically
status: active                                  # draft | active | archived | superseded
created_at: 2026-05-01
last_verified_at: 2026-05-08
tags:
  - intake
  - automation
  - home-services
allowed_context_consumers:
  - hub-indexer
  - cross-engagement-agents                     # only if sanitized: true
sanitized: true                                 # required for cross-engagement reuse
sanitization_review_at: 2026-05-09
sanitization_reviewer: toni
supersedes: null                                # artifact_id of replaced doc, if any
---
```

## Artifact types

- `pattern` — reusable engineering or operational pattern, sanitized for cross-engagement use
- `decision` — a single architectural or operational decision (one decision per file)
- `runbook` — a recurring operational task in repeatable form
- `requirements-packet` — the five artifacts from REQUIREMENTS_WORKFLOW.md
- `audit-packet` — output of `codebase-audit` v3
- `retro-doc` — output of `engagement-retro`
- `overlay` — vertical adaptation file
- `handoff-packet` — engagement-end deliverable
- `compliance-memo` — COI screen, MS approval check, attorney consult notes

## Two-tier sensitivity

The artifact's `sensitivity_tier` is independent of its repo's tier. A client repo (tier 3) can produce a tier 2 sanitized pattern. The hub respects the artifact's tier, not the repo's. This is how knowledge moves from confidential to reusable: through a deliberate sanitization step, not through manifest re-tagging.

## The `sanitized: true` gate

No artifact crosses engagement boundaries without `sanitized: true`. The hub's pattern indexer skips any artifact missing this flag, regardless of other fields. The sanitization policy (`SANITIZATION_POLICY.md`) defines what "sanitized" means.

## Validation

The hub fails loud on:
- Missing required fields
- `sanitized: true` without `sanitization_reviewer` and `sanitization_review_at`
- `client_id` set but `sensitivity_tier: 1`
- `allowed_context_consumers` including `cross-engagement-agents` without `sanitized: true`

## What this is not

Not a database. The frontmatter is the markdown surface; the hub indexes it. The artifact is still a portable markdown file you can email, paste, or hand off — the metadata is just there to make it queryable when it's part of the system.
