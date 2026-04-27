---
artifact_id: art_2026_04_27_template_frontmatter
artifact_type: decision
title: "Ship Phase 0 templates with artifact frontmatter"
repo_id: engineering-playbook
client_id: null
engagement_id: null
source_repos:
  - engineering-playbook
sensitivity_tier: 2
status: active
created_at: 2026-04-27
last_verified_at: 2026-04-27
tags:
  - phase-0
  - templates
  - frontmatter
allowed_context_consumers:
  - hub-indexer
  - cross-engagement-agents
sanitized: true
sanitization_review_at: 2026-04-27
sanitization_reviewer: toni
supersedes: null
---

# Decision: Ship Phase 0 templates with artifact frontmatter

## Date

2026-04-27

## Owner

toni

## Status

accepted

## Context

Phase 0 requires markdown templates only, while the artifact schema requires consequential markdown artifacts to carry frontmatter.

## Decision

The four template files include concrete artifact frontmatter for the template artifact itself, not placeholder client metadata.

## Rationale

This keeps the templates indexable and schema-shaped without pretending a first client, engagement, repository registry, or pattern library exists yet.

## Alternatives Considered

| Option | Why not |
|---|---|
| Omit frontmatter from templates | Would violate the Phase 0 frontmatter discipline. |
| Use placeholder client frontmatter | Would look like populated engagement data before a signed engagement exists. |

## Consequences

- Positive: templates are raw-URL-referenceable and metadata-shaped now.
- Negative: future validators may need to understand template artifacts separately from engagement artifacts.
- Follow-up: keep client-specific copies in engagement repos once a real SOW exists.

## References

- `ARTIFACT_FRONTMATTER_SCHEMA.md`
- `templates/RUNBOOK.md`
- `templates/DECISION_LOG.md`
