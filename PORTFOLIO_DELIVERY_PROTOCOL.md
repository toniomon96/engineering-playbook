# Portfolio Delivery Protocol

This is the operating system for moving Toni's repos without losing the thread. Use it when a session spans more than one project, when a repo does not have its own delivery protocol, or when an agent needs to decide how to branch, plan, verify, and close work.

## Source Of Truth

Use the closest durable source first:

1. Repo-level `AGENTS.md`, `CLAUDE.md`, or `.github/copilot-instructions.md`
2. Repo roadmap, release checklist, or developer plan
3. `.repo.yml` for ownership, sensitivity, and context-routing boundaries
4. This playbook for portfolio-wide rules

If repo guidance conflicts with this file, the repo guidance wins unless it is stale or unsafe. If it is stale, update the repo guidance in the same branch as the work.

## VCS Rules

- Start with `git status --short --branch`, `git fetch --all --prune`, and the upstream ahead/behind count.
- Pull with `--ff-only` when the worktree is clean. If the tree is dirty, preserve the local edits and do not stash, format, or stage them unless Toni explicitly owns those changes in the current task.
- One repo, one branch, one commit series. Do not mix product code, playbook docs, and client-site work in one commit.
- Use Conventional Commits in imperative mood.
- Never use destructive Git commands unless Toni explicitly asks for that operation.
- Do not push secrets, local env files, generated credentials, screenshots with private data, or client-identifying detail outside the repo's sensitivity tier.
- For keys and env vars, store values in the password manager or provider dashboard. Repos track only names, classifications, storage locations, and rotation rules through `SECRET_MANAGEMENT.md` and `secrets/portfolio-secret-register.json`.
- Portfolio status uses repo-aware branch lanes. Do not mark a repo yellow just because it is not on `main` if its protocol names another active branch.

## Branch Lanes

- `fitness-app`: normal work branches from `dev`; release PRs go `dev -> main`; hotfixes branch from `main` only for urgent production or App Store repair.
- `demario-pickleball-1`: default branch is `master`; use `fix/*`, `feat/*`, `docs/*`, or `chore/*` for normal work and merge only after `npm run ci` passes.
- `consulting`: use short `docs/*`, `site/*`, `fix/*`, or `chore/*` branches for site and docs changes; verify with `npm run build`.
- `hub`: keep runtime work separate from dirty draft work. Use clean branches or clean worktrees for deployable fixes.
- `diagnose-to-plan`: build sequence work stays on `v2/harness` until V2 is complete; use feature branches and no-squash merges back into `v2/harness`.
- `engineering-playbook`: direct docs/process changes can land on `main` when isolated and verified.

## Execution Cadence

Run every project with a small Kanban:

- **Now:** one active story or one tight batch of docs/process work
- **Next:** the next 3 to 5 ready stories
- **Later:** useful ideas without ready acceptance criteria
- **Blocked:** work waiting on credentials, external approval, store review, legal/business input, or production access

Do not let speculative ideas skip into implementation. Move them through a story, checklist, or decision note first.

## Definition Of Ready

Before substantive implementation, the work needs:

- a repo and branch lane
- an owner and sensitivity tier
- clear in-scope and out-of-scope boundaries
- acceptance criteria
- verification commands
- rollback or recovery note for user-facing changes

Small docs fixes can skip formal story docs, but they still need a clear commit and a clean repo boundary.

## Definition Of Done

Work is done when:

- the intended files are changed and unrelated dirty work is untouched
- repo-specific verification passes or the skipped verification is named honestly
- docs, checklists, roadmaps, or decision notes are updated when the work changes process or direction
- `.\scripts\secret-inventory-check.ps1` passes when the work changes env templates, deployment env names, OAuth apps, webhook secrets, API tokens, or key rotation policy
- commits are separated per repo and pushed when the repo already has a remote
- the final handoff states branch, commit, verification, and remaining manual gates

## Portfolio Wrapper Semantics

- GREEN means the configured check passed or the repo is clean on its expected branch.
- YELLOW means advisory drift, skipped status-only validation, dirty local work, read-only inventory, optional workflow failure, or manual dashboard work.
- RED means a required check failed, a required checkout is missing, required manifest coverage is missing, or a live health/env requirement is broken.
- `fitness-app` is read-only by default. Use `.\scripts\portfolio-ops-check.ps1 -OwnedRepo fitness-app` only when the current session explicitly owns Omnexus work.
- The wrapper reports next actions for every finding. Fix the underlying issue rather than editing the wrapper to make a report green.

## Repo-Specific Anchors

- Omnexus: `AGENTS.md`, `.github/copilot-instructions.md`, `docs/roadmap/planning-execution-protocol.md`
- DeMario Pickleball: `AGENTS.md`, `docs/DEVELOPER_PLAN.md`, `docs/RELEASE_CHECKLIST.md`, `docs/ADMIN_HANDOFF.md`
- Consulting site: `AGENTS.md`, `docs/SITE_NEXT_PASS_ROADMAP.md`, `docs/LAUNCH_CHECKLIST.md`
- DTP: `AGENTS.md`, `CLAUDE.md`, `docs/build-spec-v2.md`, `decisions/`
- Hub and playbook stack: `.repo.yml`, `engineering-playbook`, `hub-registry`, and portfolio ops wrapper output
