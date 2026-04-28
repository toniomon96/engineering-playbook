# Agent Instructions

This repo owns portfolio operations, docs, and cross-repo checks. It should inspect sibling repos without mutating them unless Toni explicitly transfers ownership for that repo.

## Operating Rules

- Keep portfolio automation in this repo, not in Hub runtime code.
- Use `PORTFOLIO_DELIVERY_PROTOCOL.md` before making cross-repo process, VCS, branch, or execution changes.
- Do not stage, format, revert, or fix unrelated dirty work in sibling repos.
- Treat `fitness-app` as read-only unless Toni explicitly says this session owns it. In the portfolio wrapper, use `-OwnedRepo fitness-app` only for that scoped pass.
- Do not print secrets. Vercel and Supabase checks should report names, presence, and status only.
- Do not read real `.env`, `.env.local`, `.env.test`, provider export, keychain export, or locked-note files unless Toni explicitly asks for a credential migration session. Use `.env.example`, provider env-name lists, and `secrets/portfolio-secret-register.json` for normal work.
- When env names, provider tokens, OAuth apps, webhook secrets, or deployment envs change, update `SECRET_MANAGEMENT.md` or `secrets/portfolio-secret-register.json` as needed and run `.\scripts\secret-inventory-check.ps1`.
- Prefer Hub intake as primary, Formspree as fallback, and email as the final fallback in consulting ops docs.

## Portfolio Check

- Use `.\scripts\portfolio-ops-check.ps1` for the red/yellow/green portfolio report.
- Use `.\scripts\secret-inventory-check.ps1` for value-free key inventory checks.
- The wrapper may call `gh`, `vercel`, `npx supabase`, `git`, `npm`, and health URLs.
- A red report means a required check is failing. Yellow means advisory drift, dirty local work, read-only inventory, skipped checks, or manual gates.
- A red report can be expected when live GitHub Actions are failing; do not treat that as permission to edit those repos unless the current task grants ownership.

## Verification

- After script changes, run `.\scripts\portfolio-ops-check.ps1`.
- After secret registry changes, run `.\scripts\secret-inventory-check.ps1`.
- Commit playbook-only changes separately from any repo-specific code changes.
