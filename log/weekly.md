# Weekly Operating Log

*The dashboard checklist source. New section added each Monday. Old sections kept for retrospective viewing. Bold items are priority and render with the accent highlight on the dashboard.*

---

## Week of 2026-04-27

- [x] Ship Phase 0 schemas to engineering-playbook
- [x] Ship 90_DAY_EXECUTION_ROADMAP_v2.md
- [x] Ship CONSOLE_BUILD_SPEC.md
- [ ] **Resolve audit pricing — single canonical answer ($1,500 for first three)**
  - Update `operating_doc_v2.md` audit price from $300–$500 to $1,500
  - Update master spec audit reference if needed
  - Add a single "canonical pricing" reference line in the bundle index
- [ ] **/start path A intake upgrade**
  - Primary: route qualified diagnostic intake to Hub via `PUBLIC_CONSULTING_INTAKE_ENDPOINT`
  - Fallback: keep Formspree live via `PUBLIC_FORMSPREE_ENDPOINT` if Hub intake is unavailable
  - Last resort: render the email intake path only when Hub and Formspree are both unconfigured
  - Add fields: company, industry, current systems, budget band
  - Keep existing diagnostic fields (project, messy context, 30-day target)
  - Verify Hub intake end-to-end first; then verify Formspree fallback and email fallback explicitly
- [ ] Ship `ENGAGEMENT_START_CHECKLIST.md` to engineering-playbook
  - When to create a new client repo
  - What files to populate (`.repo.yml`, `docs/PLAYBOOK.md`, etc.)
  - Sensitivity tier defaults
  - Validation checklist before first commit
- [ ] **Send three referral DMs**
  - Marcus T. (LinkedIn DM)
  - Priya S. (email)
  - James K. (text)
  - Script per the v2 roadmap: paid AI Upgrade Audits, $1,500, two-week turnaround

---

## Week of 2026-05-04 *(planned)*

- [ ] Coding agent kickoff — console v0 (dashboard + roadmap routes)
- [ ] Domain `console.tonimontez.co` configured on Vercel
- [ ] Auth.js GitHub OAuth setup with single-user allowlist
- [ ] Verify console v0 renders real data from real markdown files

---

## Week of 2026-04-20 *(retrospective)*

- [x] Ship four schema docs to engineering-playbook
- [x] Build out portfolio classification (`.repo.yml` across all repos)
- [x] Hub-registry boundary preserved (no auto-cross-repo indexing yet)

---

## Notes

The bolded items each week are priority. The dashboard renders them with the accent highlight. Non-bold items are still tracked but don't pull focus.

The discipline: edit this file, commit, push. The console reflects the new state on next page load.
