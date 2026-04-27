---
artifact_id: art_2026_04_27_portfolio_registry_phase_0_1
artifact_type: decision
title: "Adopt manifest-only portfolio registry for Phase 0.1"
repo_id: engineering-playbook
client_id: null
engagement_id: null
source_repos:
  - consulting
  - engineering-playbook
  - hub
  - hub-prompts
  - hub-registry
  - fitness-app
  - family-trips
  - demario-pickleball-1
  - dse-content
sensitivity_tier: 2
status: active
created_at: 2026-04-27
last_verified_at: 2026-04-27
tags:
  - phase-0-1
  - portfolio-registry
  - manifests
  - sanitization
allowed_context_consumers:
  - hub-indexer
  - cross-engagement-agents
sanitized: true
sanitization_review_at: 2026-04-27
sanitization_reviewer: toni
supersedes: null
---

# Decision: Adopt Manifest-Only Portfolio Registry For Phase 0.1

## Date

2026-04-27

## Owner

toni

## Status

accepted

## Context

The consulting ecosystem now spans the public consulting site, the engineering playbook, Hub infrastructure, owned product proof artifacts, personal UX labs, and client-style delivery repos. Phase 0 already established the schema-first rule. Phase 0.1 makes the repo portfolio visible without moving into population, indexing, or UI.

## Decision

Each known portfolio repo carries a root `.repo.yml` manifest using `REPO_REGISTRY_SCHEMA.md`. The manifests classify repo purpose, sensitivity tier, allowed consumers, artifact roots, and source-of-truth files.

The manifests are inventory only. They do not authorize raw artifact extraction, cross-repo pattern mining, vector search, FTS5, dashboards, or client-facing surfaces.

## Portfolio Roles

| Repo | Role | Sensitivity | Reuse rule |
|---|---|---:|---|
| `consulting` | Public consulting front door | 1 | Public-safe site and positioning only. |
| `engineering-playbook` | Standards, schemas, and templates | 2 | Canonical operating standards. |
| `hub`, `hub-prompts`, `hub-registry` | Runtime, prompt, and routing infrastructure | 2 | Internal platform references. |
| `fitness-app` | Owned product proof artifact | 2 | Public-safe proof of product, AI, launch, privacy, and entitlement discipline. |
| `FamilyTrips` | Personal UX/product lab | 2 | Generalize UX patterns only; never reuse trip data. |
| `demario-pickleball-1` | Client-style SMB delivery proof | 3 | Treat as confidential until explicit approval and sanitization. |
| `dse-content` | Enterprise workflow operating-system lab | 3 | Never reuse raw Microsoft, MSX, customer, or internal-system context. |

## Extraction Gates

1. Schemas before population.
2. Population before indexing.
3. Indexing before UI.
4. Tier 3 repos can produce cross-engagement patterns only after sanitized artifact frontmatter explicitly allows reuse.
5. `dse-content` and `demario-pickleball-1` stay out of public consulting copy unless rewritten into generic, approved proof language.

## Hub Registry Boundary

`hub-registry/targets.yml` remains the automation target registry. It is not the consulting knowledge registry. Adding a repo to `targets.yml` can trigger prompt dispatch, so Phase 0.1 uses root `.repo.yml` manifests as the source of truth and treats any Hub target activation as a separate decision.

## Consequences

- Positive: future agents can see the whole portfolio shape without reading private contents first.
- Positive: sensitivity and allowed-consumer choices are explicit before any indexing work starts.
- Negative: future validators will need to check manifests across multiple sibling repos.
- Follow-up: after the first signed or controlled engagement, create sanitized artifact packets only for approved repos.

## References

- `REPO_REGISTRY_SCHEMA.md`
- `ARTIFACT_FRONTMATTER_SCHEMA.md`
- `SANITIZATION_POLICY.md`
- `CODING_AGENT_CONTEXT_PACK.md`
