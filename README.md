# Engineering Playbook

Cross-project operating principles for my AI-assisted development work.

## Contents

- [HANDBOOK.md](HANDBOOK.md) — Agent-Assisted Engineering Handbook. General principles for directing coding agents.
- [DESIGN_WORKFLOW.md](DESIGN_WORKFLOW.md) — Claude Design + Claude Code workflow for UI generation and upgrades.
- [ARCHITECTURE_PROMPT.md](ARCHITECTURE_PROMPT.md) — The prompt that generates and maintains `ARCHITECTURE.md` files in project repos.
- [REPO_REGISTRY_SCHEMA.md](REPO_REGISTRY_SCHEMA.md) — Manifest shape for repos in the consulting ecosystem.
- [ARTIFACT_FRONTMATTER_SCHEMA.md](ARTIFACT_FRONTMATTER_SCHEMA.md) — Required metadata for consequential markdown artifacts.
- [SANITIZATION_POLICY.md](SANITIZATION_POLICY.md) — Rules for moving client-confidential knowledge into reusable patterns.
- [CODING_AGENT_CONTEXT_PACK.md](CODING_AGENT_CONTEXT_PACK.md) — Context-pack format for scoped coding-agent work.
- [CONSOLE_BUILD_SPEC.md](CONSOLE_BUILD_SPEC.md) — Private operator console v0 build specification.
- [90_DAY_EXECUTION_ROADMAP_v2.md](90_DAY_EXECUTION_ROADMAP_v2.md) — Business execution roadmap and phase gates.
- [templates/](templates/) — Markdown templates for runbooks, decisions, requirements packets, and audit packets.
- [decisions/](decisions/) — Accepted operating decisions for the playbook and consulting portfolio.
- [log/weekly.md](log/weekly.md) — Weekly execution checklist rendered by Console v0.
- [log/outreach.md](log/outreach.md) — Referral DM and intake tracking log rendered by Console v0.
- [marketing/referrals.md](marketing/referrals.md) — Referral source list for future marketing surfaces.
- [pipeline/](pipeline/) — Empty Phase 0 holder for future signed-engagement pipeline artifacts.
- [engagements/](engagements/) — Empty Phase 0 holder for future engagement records.
- [stubs/PLAYBOOK.md](stubs/PLAYBOOK.md) — Template stub to copy into each project repo at `docs/PLAYBOOK.md`.
- [scripts/portfolio-ops-check.ps1](scripts/portfolio-ops-check.ps1) — Local portfolio status and validation wrapper for the consulting operating stack.

## How this is used

Each of my project repos includes `docs/PLAYBOOK.md` pointing back to the relevant doc here via raw URL. That way a fresh Claude or Copilot session in any repo sees the canonical guidance without re-explaining.

Canonical raw URL base:
`https://raw.githubusercontent.com/toniomon96/engineering-playbook/main/<filename>`

Because this repo is private, raw URLs require authentication. Claude Code (via GitHub MCP) and the Hub (via HUB_GITHUB_TOKEN) have this by default.

## Living docs

These are working documents. When something stops being true, fix it in the same commit where it was noticed. Review cadence: monthly for the first quarter, quarterly after.

## Local ops check

Run the portfolio ops wrapper from PowerShell:

```powershell
.\scripts\portfolio-ops-check.ps1
```

The script reports red/yellow/green status without printing secrets or mutating sibling repos. It checks repo branch/status, `.repo.yml` coverage, `hub-registry` validation, configured health URLs, GitHub Actions when `gh` is available, Vercel env names when `vercel` is available, and Supabase migrations through suppressed-output CLI checks. Configure health checks with `-HealthUrl`, `PORTFOLIO_HEALTH_URLS`, `HUB_HEALTH_URL`, or `CONSULTING_HEALTH_URL`; if none are configured, the wrapper checks `https://onhand.dev/health`. Local Supabase status is skipped by default because it can require Docker; set `PORTFOLIO_RUN_SUPABASE_STATUS=1` when you intentionally want that check. The older `consulting-ops-check.ps1` name remains as the implementation entrypoint for compatibility.

## Scope

This repo is for principles that apply across projects. Project-specific docs live in project repos. Prompts live in `hub-prompts`. Runtime target config lives in `hub-registry`.

Every doc here must be referenced by at least one active project's `docs/PLAYBOOK.md`. If no project references it, it's notes, and notes belong in Obsidian.
