---
artifact_id: art_2026_04_27_template_runbook
artifact_type: runbook
title: "Runbook Template"
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
  - template
  - runbook
allowed_context_consumers:
  - hub-indexer
  - cross-engagement-agents
sanitized: true
sanitization_review_at: 2026-04-27
sanitization_reviewer: toni
supersedes: null
---

# Runbook: [system or workflow name]

## Purpose

What this runbook helps an operator do, in one or two sentences.

## Scope

What this covers:

- [Covered workflow]
- [Covered tool/system]

What this does not cover:

- [Explicit non-goal]

## Ownership

- Owner: [person or role]
- Backup: [person or role]
- Last reviewed: [YYYY-MM-DD]

## Systems

| System | Role | Owner | Cost | Access location |
|---|---|---|---|---|
| [Tool] | [What it does] | [Owner] | [Monthly cost] | [Where credentials live] |

## Normal Operation

1. [Step]
2. [Step]
3. [Step]

## Common Changes

| Change | Steps | Risk |
|---|---|---|
| [Change] | [How to make it] | [Low/Medium/High] |

## Failure Modes

| Symptom | First check | Fix | Escalate when |
|---|---|---|---|
| [What breaks] | [Where to look first] | [What to do] | [When to ask for help] |

## Decision References

- [Decision log link]

## Handoff Checklist

- [ ] Operator can perform the normal workflow.
- [ ] Operator knows where credentials live.
- [ ] Operator knows the first three failure checks.
- [ ] Follow-up work is captured outside this runbook.
