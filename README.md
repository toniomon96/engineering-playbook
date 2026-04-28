# Engineering Playbook

Cross-project operating principles for my AI-assisted development work.

## Contents

- [HANDBOOK.md](HANDBOOK.md) — Agent-Assisted Engineering Handbook. General principles for directing coding agents.
- [DESIGN_WORKFLOW.md](DESIGN_WORKFLOW.md) — Claude Design + Claude Code workflow for UI generation and upgrades.
- [ARCHITECTURE_PROMPT.md](ARCHITECTURE_PROMPT.md) — The prompt that generates and maintains `ARCHITECTURE.md` files in project repos.
- [REPO_REGISTRY_SCHEMA.md](REPO_REGISTRY_SCHEMA.md) — Manifest shape for repos in the consulting ecosystem.
- [ARTIFACT_FRONTMATTER_SCHEMA.md](ARTIFACT_FRONTMATTER_SCHEMA.md) — Required metadata for consequential markdown artifacts.
- [SANITIZATION_POLICY.md](SANITIZATION_POLICY.md) — Rules for moving client-confidential knowledge into reusable patterns.
- [SECRET_MANAGEMENT.md](SECRET_MANAGEMENT.md) — Portfolio key strategy, vault structure, rotation cadence, and agent rules.
- [CODING_AGENT_CONTEXT_PACK.md](CODING_AGENT_CONTEXT_PACK.md) — Context-pack format for scoped coding-agent work.
- [CONSOLE_BUILD_SPEC.md](CONSOLE_BUILD_SPEC.md) — Private operator console v0 build specification.
- [PORTFOLIO_DELIVERY_PROTOCOL.md](PORTFOLIO_DELIVERY_PROTOCOL.md) — Cross-repo VCS, agile execution, branch, verification, and closeout rules.
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
- [scripts/secret-inventory-check.ps1](scripts/secret-inventory-check.ps1) — Value-free secret inventory checker for env-template coverage and untracked local env files.
- [scripts/op-secret-check.ps1](scripts/op-secret-check.ps1) — 1Password CLI structure checker for the `Toni Portfolio Ops` vault.
- [scripts/op-bootstrap-secret-items.ps1](scripts/op-bootstrap-secret-items.ps1) — Dry-run-first 1Password vault/item/field bootstrapper generated from the secret registry.
- [secrets/portfolio-secret-register.json](secrets/portfolio-secret-register.json) — Secret names, classifications, storage locations, and rotation rules without values.

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
.\scripts\portfolio-ops-check.ps1 -OwnedRepo fitness-app
```

The script reports red/yellow/green status without printing secrets or mutating sibling repos. It checks repo-aware branch lanes, `.repo.yml` coverage across every configured repo, `hub-registry` validation, configured health URLs, required GitHub Actions when `gh` is available, Vercel env names when `vercel` is available, and Supabase migrations through suppressed-output CLI checks. `fitness-app` is read-only by default; pass `-OwnedRepo fitness-app` only when the current session explicitly owns Omnexus work. Configure health checks with `-HealthUrl`, `PORTFOLIO_HEALTH_URLS`, `HUB_HEALTH_URL`, or `CONSULTING_HEALTH_URL`; if none are configured, the wrapper checks `https://onhand.dev/health`. Local Supabase status is skipped by default because it can require Docker; set `PORTFOLIO_RUN_SUPABASE_STATUS=1` when you intentionally want that check. The older `consulting-ops-check.ps1` name remains as the implementation entrypoint for compatibility.

Run the secret inventory checker whenever an env template, Vercel env name, Supabase key, OAuth app, webhook secret, or provider token changes:

```powershell
.\scripts\secret-inventory-check.ps1
.\scripts\op-secret-check.ps1
.\scripts\op-bootstrap-secret-items.ps1
```

The inventory checker scans variable names only. It does not read or print values from real `.env*` files. The 1Password checker verifies vault/item structure through the `op` CLI and can check field labels with `-CheckFields`; it prints status only, never secret values. The bootstrapper runs dry by default; use `-Apply` only after 1Password desktop integration is enabled.

## Scope

This repo is for principles that apply across projects. Project-specific docs live in project repos. Prompts live in `hub-prompts`. Runtime target config lives in `hub-registry`.

Every doc here must be referenced by at least one active project's `docs/PLAYBOOK.md`. If no project references it, it's notes, and notes belong in Obsidian.
