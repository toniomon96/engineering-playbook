# Secret Management

This is the portfolio rule: repos can know which secrets exist, where they belong, and how to rotate them. Repos never hold the values.

## Recommendation

Move from locked notes to a password manager with shared-item structure. Locked notes are acceptable as a temporary vault, but they do not give you clean item history, field-level copy, or emergency rotation workflow.

Use one vault named `Toni Portfolio Ops`. Create one item per project and environment:

- `consulting / production`
- `consulting / preview`
- `hub / production`
- `hub / local`
- `demario-pickleball / production`
- `demario-pickleball / preview`
- `omnexus / production`
- `omnexus / preview`
- `omnexus / test`
- `dse-content / local`
- `diagnose-to-plan / local`

Each item should have fields named exactly like the env var or provider secret name. Do not rename fields to friendly labels. Copying `SUPABASE_SERVICE_ROLE_KEY` into a dashboard should not require interpretation.

## Storage Rules

- Actual values live only in the password manager, provider dashboards, local `.env*` files, or deployment env stores like Vercel, Supabase, GitHub Actions, Apple, Google, Stripe, Resend, Sentry, Azure, and PostHog.
- `engineering-playbook/secrets/portfolio-secret-register.json` tracks variable names, classification, environment, storage location, and rotation policy. It must never include values.
- Local `.env`, `.env.local`, and `.env.test` files are allowed on Toni's machine, but they must stay untracked.
- Public client config still belongs in the registry. `NEXT_PUBLIC_*`, `VITE_*`, and `PUBLIC_*` values are usually not secret, but they still affect production behavior.
- Service-role keys, webhook secrets, OAuth client secrets, API tokens, App Store shared secrets, private keys, and GitHub tokens are treated as high-blast-radius secrets.
- Never paste secrets into agent chat, issue bodies, PR descriptions, commit messages, screenshots, markdown docs, or memory files.

## Item Shape

Use this field order inside the password manager item:

1. `environment`: `local`, `preview`, `production`, or `test`
2. `provider`: `vercel`, `supabase`, `stripe`, `apple`, `google`, `github`, `resend`, `sentry`, `azure`, `posthog`, `anthropic`, `openai`, or `local`
3. env var fields, one per value
4. `rotation cadence`
5. `last rotated`
6. `where deployed`
7. `recovery note`

Do not put multiple projects in one item. The point is to rotate a project without touching the whole portfolio.

## Rotation Cadence

- Rotate immediately after suspected exposure, repo leak, accidental paste, employee/contractor access change, or provider dashboard compromise.
- Rotate high-blast-radius secrets every 90 days until the portfolio stabilizes.
- Rotate normal service tokens every 180 days.
- Rotate public config only when the underlying service target changes.
- Keep test credentials separate from production credentials. Test users may be reset without ceremony.

## Local Workflow

1. Add or rename env vars in the repo's `.env.example` or provider template first.
2. Update `secrets/portfolio-secret-register.json` in the same branch.
3. Run:

```powershell
.\scripts\secret-inventory-check.ps1
.\scripts\op-secret-check.ps1
.\scripts\portfolio-ops-check.ps1
```

4. Add the real value to the password manager and target provider dashboard.
5. Verify the app with the repo's normal validation command.

## 1Password CLI

Use 1Password CLI as the operating bridge, not as a place to print secrets.

Install on Windows:

```powershell
winget install -e --id AgileBits.1Password.CLI
op --version
```

Then open the 1Password desktop app and enable:

```text
Settings > Developer > Integrate with 1Password CLI
```

Use Windows Hello for local approval. Test access with:

```powershell
op vault list
```

The playbook checker is:

```powershell
.\scripts\op-secret-check.ps1
.\scripts\op-secret-check.ps1 -CheckFields
```

Default mode checks that the CLI, vault, and expected items exist. `-CheckFields` verifies field labels against the registry. It still prints only names and status, not values. Do not run `op read` in a shared transcript unless Toni explicitly asks for a local secret injection task.

The bootstrapper creates the empty vault/item/field structure from the registry:

```powershell
.\scripts\op-bootstrap-secret-items.ps1
.\scripts\op-bootstrap-secret-items.ps1 -Apply
.\scripts\op-bootstrap-secret-items.ps1 -Apply -AddMissingFields
```

Default mode is dry-run and does not require sign-in. `-Apply` creates the `Toni Portfolio Ops` vault if it is missing and creates missing project/environment items. New fields are created with `TODO: paste value manually`, never real values. Existing items are not edited unless `-AddMissingFields` is passed.

## Migration From Locked Notes

Do this in small batches:

1. Create the vault and empty project/environment items.
2. Move `consulting`, `hub`, and `diagnose-to-plan` first because they are the consulting operating stack.
3. Move `demario-pickleball-1`.
4. Move `fitness-app` last because it has the largest credential surface.
5. For each moved item, record `last rotated`. If the original source was messy or widely copied, rotate the value during the move.

## Agent Rules

- Agents may inspect env variable names and `.env.example` templates.
- Agents may run the inventory checker.
- Agents may set provider env vars only when Toni explicitly supplies the value through a secure manual path or the value is already available in an authenticated provider CLI.
- Agents must not print secret values or copy them into repo files.
- If a secret is missing, the correct output is the missing name and target provider, not the value.
