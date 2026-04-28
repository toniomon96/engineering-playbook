# Agent Instructions

This repo owns portfolio operations, docs, and cross-repo checks. It should inspect sibling repos without mutating them unless Toni explicitly transfers ownership for that repo.

## Operating Rules

- Keep portfolio automation in this repo, not in Hub runtime code.
- Use `PORTFOLIO_DELIVERY_PROTOCOL.md` before making cross-repo process, VCS, branch, or execution changes.
- Do not stage, format, revert, or fix unrelated dirty work in sibling repos.
- Treat `fitness-app` as read-only unless Toni explicitly says this session owns it.
- Do not print secrets. Vercel and Supabase checks should report names, presence, and status only.
- Prefer Hub intake as primary, Formspree as fallback, and email as the final fallback in consulting ops docs.

## Portfolio Check

- Use `.\scripts\portfolio-ops-check.ps1` for the red/yellow/green portfolio report.
- The wrapper may call `gh`, `vercel`, `npx supabase`, `git`, `npm`, and health URLs.
- A red report can be expected when live GitHub Actions are failing; do not treat that as permission to edit those repos.

## Verification

- After script changes, run `.\scripts\portfolio-ops-check.ps1`.
- Commit playbook-only changes separately from any repo-specific code changes.
