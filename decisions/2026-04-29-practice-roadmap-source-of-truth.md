---
decision_id: 2026-04-29-practice-roadmap-source-of-truth
title: Move Current Practice Production Roadmap To DTP
status: accepted
date: 2026-04-29
repos:
  - engineering-playbook
  - diagnose-to-plan
  - consulting
  - hub
  - hub-prompts
  - hub-registry
tags:
  - roadmap
  - practice-os
  - documentation
  - source-of-truth
---

# Move Current Practice Production Roadmap To DTP

## Context

The consulting operating stack now spans multiple repos:

- `diagnose-to-plan` for Practice OS, Client Operating Kits, COI, redaction, proof promotion, and hosted DTP planning.
- `consulting` for the public storefront and proof surface.
- `hub` for intake/runtime records and private console support.
- `engineering-playbook` for portfolio schemas, templates, historical decisions, secret-management references, and general operating doctrine.
- `hub-prompts` for Hub prompt markdown.
- `hub-registry` for Hub automation targets.

The older 90-day roadmap in this repo remains useful business context, but it is no longer the clearest place to coordinate DTP, hosted DTP, public proof, Hub boundaries, and `tm-skills`.

## Decision

Use `diagnose-to-plan/docs/PRACTICE_PRODUCTION_ROADMAP.md` as the current source of truth for practice production sequencing.

Keep `engineering-playbook` as the source for portfolio-level schemas, templates, historical decisions, secret-management references, and general operating doctrine.

Do not update `hub-prompts` or `hub-registry` for roadmap-only changes. Those repos should change only when prompt behavior or automation target routing changes.

## Consequences

- Future roadmap implementation chats should start from the DTP roadmap and documentation map.
- The old 90-day roadmap remains readable historical context, not the current master plan.
- Hub docs can link to DTP for current practice sequencing while keeping Hub focused on intake/runtime support.
- `hub-prompts` and `hub-registry` stay clean unless an implementation changes prompt catalogues or automation routes.
