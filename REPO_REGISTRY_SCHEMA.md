# REPO_REGISTRY_SCHEMA.md

# Repo registry: the manifest every repo carries

Every repo in the consulting ecosystem — internal platforms, client engagements, proof artifacts — registers itself with a manifest. The manifest lives at the repo root as `.repo.yml` and is the single canonical description of what the repo is, who can read its artifacts, and how the hub should treat it.

Repos are not mutually aware. The hub reads manifests; agents read scoped context packs the hub generates. Client repos never read other client repos.

## The manifest

```yaml
# .repo.yml
repo_id: example-corp-os                      # snake_case, globally unique
display_name: "Example Corp Operating System"
repo_type: client-engagement                  # see types below
owner: toni
client_id: example-corp                       # null for internal
engagement_id: eng_2026_05_example_corp       # null for non-engagement
sensitivity_tier: 2                           # 1=public, 2=internal, 3=client-confidential
domains:
  - intake
  - automation
  - reporting
allowed_context_consumers:
  - hub-indexer
  - this-engagement-agents
artifact_roots:
  - requirements/
  - runbooks/
  - decisions/
  - automations/
  - handoff/
source_of_truth_files:
  - ARCHITECTURE.md
  - decisions/DECISION_LOG.md
status: active                                 # active | archived | sunset
created_at: 2026-05-01
last_verified_at: 2026-05-08
```

## Repo types

- `internal-platform` — hub, engineering-playbook, hub-prompts, hub-registry
- `internal-product` — Omnexus, SuperKart (proof artifacts you own)
- `personal-marketing` — tonimontez.co
- `client-engagement` — every paid client engagement
- `client-handoff-archive` — post-engagement archive of a completed client repo
- `experimental` — anything you're exploring; never indexed for patterns

## Sensitivity tiers

- **Tier 1 — public.** Shippable to anyone. Open-source repos, marketing site, public proof artifacts.
- **Tier 2 — internal.** Visible to the hub and your tooling. Decisions, patterns, prompts, the playbook.
- **Tier 3 — client-confidential.** Visible only inside one engagement. Never enters the cross-engagement pattern index without sanitization. Default for any client repo.

## Allowed context consumers

The list of agents/processes allowed to read this repo's artifacts. `hub-indexer` is allowed everywhere. Engagement-specific agents are allowed only inside their own engagement. Cross-engagement agents are allowed only against tier 1 + tier 2 repos.

## Validation

Every repo's `.repo.yml` is validated by the hub on indexing. Missing fields fail loud. The hub never assumes defaults for `sensitivity_tier`, `client_id`, or `allowed_context_consumers` — these must be explicit.

## What this is not

Not a permission system. The hub trusts the manifest; access enforcement happens at the GitHub repo level (private, collaborator-restricted). The manifest is for routing, indexing, and agent-context generation — not authentication.
