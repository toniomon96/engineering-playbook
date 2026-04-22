# Engineering Playbook

Cross-project operating principles for my AI-assisted development work.

## Contents

- [HANDBOOK.md](HANDBOOK.md) — Agent-Assisted Engineering Handbook. General principles for directing coding agents.
- [DESIGN_WORKFLOW.md](DESIGN_WORKFLOW.md) — Claude Design + Claude Code workflow for UI generation and upgrades.
- [ARCHITECTURE_PROMPT.md](ARCHITECTURE_PROMPT.md) — The prompt that generates and maintains `ARCHITECTURE.md` files in project repos.
- [stubs/PLAYBOOK.md](stubs/PLAYBOOK.md) — Template stub to copy into each project repo at `docs/PLAYBOOK.md`.

## How this is used

Each of my project repos includes `docs/PLAYBOOK.md` pointing back to the relevant doc here via raw URL. That way a fresh Claude or Copilot session in any repo sees the canonical guidance without re-explaining.

Canonical raw URL base:
`https://raw.githubusercontent.com/toniomon96/engineering-playbook/main/<filename>`

Because this repo is private, raw URLs require authentication. Claude Code (via GitHub MCP) and the Hub (via HUB_GITHUB_TOKEN) have this by default.

## Living docs

These are working documents. When something stops being true, fix it in the same commit where it was noticed. Review cadence: monthly for the first quarter, quarterly after.

## Scope

This repo is for principles that apply across projects. Project-specific docs live in project repos. Prompts live in `hub-prompts`. Runtime target config lives in `hub-registry`.

Every doc here must be referenced by at least one active project's `docs/PLAYBOOK.md`. If no project references it, it's notes, and notes belong in Obsidian.
