# SANITIZATION_POLICY.md

# Sanitization policy: how client knowledge becomes reusable knowledge

The cross-engagement pattern system is one careless retro doc away from leaking a client's confidential business logic into the next engagement. This policy defines the gate.

## The principle

**Client-specific artifacts do not become reusable patterns until sanitized.** Sanitization is a deliberate step performed by the practitioner, recorded with a reviewer name and review date, and reflected in the artifact's frontmatter (`sanitized: true`).

## Reusable pattern files MAY include

- Workflow shape (the structure of a process, abstracted from a specific client)
- Integration category (Stripe, Twilio, n8n — not client-specific account names or keys)
- Failure mode (a category of bug, error, or edge case encountered)
- General implementation lesson (what worked, what didn't, why)
- Anonymized before/after (problem state and solution state, with all identifying details removed)
- Generic decision rationale (why one approach was chosen over another, in terms general enough to apply elsewhere)

## Reusable pattern files MUST NOT include

- Client names, unless explicitly approved in writing for that artifact
- Customer or end-user names
- Revenue, financial, or pricing numbers, unless approved
- Credentials of any kind (API keys, passwords, tokens, OAuth secrets)
- Private URLs (admin panels, internal tools, staging environments)
- Proprietary workflows that constitute the client's competitive advantage
- Employee names (of the client, of the client's customers, of anyone identifiable)
- Raw transcripts of calls, meetings, or messages
- Confidential business logic the client would not want competitors to see
- Microsoft confidential information of any kind, ever

## The review

Every artifact marked `sanitized: true` has been read end-to-end by the practitioner with the explicit question:

> *"Would I be comfortable if a competitor of this client read this exact file?"*

If the answer is no, sanitization is incomplete.

The review is recorded in frontmatter:

```yaml
sanitized: true
sanitization_review_at: 2026-05-09
sanitization_reviewer: toni
```

The review timestamp resets on every meaningful edit. Edits that change names, numbers, or workflow specifics require fresh review.

## What gets sanitized vs. what stays raw

- **Engagement decision logs** — stay raw inside the engagement repo (tier 3). A sanitized version may be derived as a pattern; the raw log is never published.
- **Retro docs** — produce two versions. The full retro stays in the engagement repo. The sanitized retro contributes to the pattern library.
- **Audit packets** — stay raw inside the engagement. Lessons may be extracted as patterns; the audit itself is never cross-shared.
- **Runbooks** — usually generalizable; sanitization typically means stripping the client's specific tool URLs, account names, and credential references.
- **ARCHITECTURE.md** — engagement-specific; lessons get extracted into the playbook, the architecture doc itself stays in the engagement repo.

## Microsoft compliance overlay

No artifact, sanitized or otherwise, may include information that originates from Microsoft confidential channels. The sanitization review explicitly checks for this. If an artifact draws on knowledge that *might* have originated from Microsoft work, it does not get sanitized — it gets archived inside the engagement only and never enters the pattern library.

## Enforcement

The hub's pattern indexer skips artifacts missing `sanitized: true`. There is no override.

If a pattern needs to be reused before review, the reuse path is manual: copy the artifact into the new engagement, sanitize it there, mark it sanitized, then index. The point is to make sanitization the default friction, not the optional one.

## When in doubt

Default to not sanitizing. An artifact that stays in the engagement folder is safe. An artifact that prematurely enters the pattern library is a compliance liability. **The friction is the feature.**
