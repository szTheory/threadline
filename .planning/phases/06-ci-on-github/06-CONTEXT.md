# Phase 6: CI on GitHub - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove **CI-01–CI-03** for v1.1: workflow present on `main` with stable job keys `verify-format`, `verify-credo`, and `verify-test`; **latest commit on `main`** has a **successful** GitHub Actions run for **all three** jobs; **README** (and supporting contributor docs) make it obvious **where** to see CI status and how it maps to local commands. **Out of scope:** Elixir/OTP pin changes in CI unless the only fix for a real breakage (then treat as explicit scope/requirements decision, not a silent tweak); Hex publish (Phase 7); new product features.

</domain>

<decisions>
## Implementation Decisions

### CI-02 — What counts as “green”

- **D-01:** **Source of truth** is the **tip of `origin/main`**: the commit SHA at `origin/main` must have at least one **completed** workflow run (for this repo’s primary CI workflow) in which **`verify-format`**, **`verify-credo`**, and **`verify-test`** each have **`conclusion: success`** for **that same SHA**. A legitimate **re-run** counts; **failure** or **cancelled** does not satisfy CI-02 until a successful completed run exists for that commit.
- **D-02:** **Skipped jobs** are unacceptable as a stand-in for success for these three named jobs: the workflow must be written so all three **run** on every `push` to `main` (no path filters or `[skip ci]` tricks on `main` that skip verifiers). If GitHub shows a job as skipped when it should have run, treat as **not green** until fixed.
- **D-03:** **PR green** vs **main green**: CI-02 is **main-only** wording; **branch protection** + same three checks on PRs is **strongly recommended** so `main` stays honest, but **closing Phase 6** is defined by **main@HEAD** per D-01. Fork PRs may need maintainer workflow approval — that does not redefine “main is green.”
- **D-04:** **Flakes:** intermittent failures are **release blockers** until addressed (fix test, service healthcheck, or workflow glue per D-09 — not “merge anyway”). Prefer **re-run** for transient GitHub incidents; repeated flakes get a tracked fix.

### CI-03 — README and contributor discovery

- **D-05:** **Badge alone is insufficient** for accessibility and “where is live status?” clarity. Keep the **existing CI badge**; add **one short plain-text line** immediately under the badge row that states CI runs on **GitHub Actions** and links to the **Actions** area for the repo (runs/history), not only the static workflow file. **CONTRIBUTING.md** already documents workflow path, job-key contract, and `mix ci.all` — add at most a **single explicit link** to the Actions tab in that CI section if not already present, so discovery is **README (scan) + CONTRIBUTING (detail)** without long duplication.
- **D-06:** **Link hygiene:** Prefer URLs that land contributors on **run history** or the Actions hub (`…/actions`), aligning with “latest on `main`” mental models; workflow-YAML deep links are fine for the badge’s image endpoint but not the only prose link.

### Scope of `ci.yml` edits in this phase

- **D-07 (minimal edits / “option C”):** **Default:** fix failures in **application code**, **tests**, **deps**, and **docs** first. **Edit `.github/workflows/ci.yml` only** for **infra glue** that does **not** change declared **Elixir, OTP, or Postgres version policy**: e.g. `runs-on` label supported on GHA, `actions/checkout` / cache action majors, Postgres **service** healthchecks/ports, env vars needed for reliable `verify-test`. **Do not** rename the three **`jobs:`** keys (`verify-format`, `verify-credo`, `verify-test`).
- **D-08:** **Bump `erlef/setup-beam@v1`** (the action reference) only when required for **action/runtime breakage** on current runners — **without** changing `elixir-version` / `otp-version` unless the failure is **proven** to be pin-related and an explicit decision is made to override the milestone “no pin churn” rule.
- **D-09:** **Postgres / services flakiness:** fix via workflow **service definition** (healthcheck, port, image tag consistent with policy), not `sleep` in application tests.

### How we prove CI-02 (verification / UAT)

- **D-10:** **Primary proof (reproducible):** Maintainer records **`origin/main` SHA** (`git fetch origin main && git rev-parse origin/main`) and shows it matches the **head SHA** of the latest **successful** CI run for this workflow on **`main`**, with all three jobs successful — preferably via **`gh run list --workflow=ci.yml --branch=main --limit=5`** (or `gh run view <id> --json conclusion,headSha,displayTitle`) plus pasted **run URL** in verification notes.
- **D-11:** **GitHub UI** is acceptable for **log inspection** and human sign-off; **do not** accept **README badge alone** as proof of CI-02 (badges can lag or scope differently than “this SHA”).
- **D-12:** **Footgun guard:** Verification text must name the **workflow file** and the three **job keys** so reviewers do not confuse another workflow or a PR run with **main@HEAD**.

### Claude's Discretion

Exact README sentence wording, optional `gh` JSON one-liner vs table in verification doc, and whether CONTRIBUTING gets one new hyperlink line vs two — as long as D-05, D-10, and D-11 are satisfied.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **CI-01**, **CI-02**, **CI-03** (v1.1 Continuous integration); **Out of Scope** (pin bumps).
- `.planning/ROADMAP.md` — Phase 6 goal, success criteria, canonical refs for this phase.

### CI and contributor docs

- `.github/workflows/ci.yml` — Job key contract, triggers, BEAM/Postgres pins, services.
- `README.md` — CI badge and contributor-facing CI discovery (CI-03).
- `CONTRIBUTING.md` — Local parity with CI, job names, branch protection notes.

### Prior phase context

- `.planning/phases/05-repository-remote/05-CONTEXT.md` — Canonical repo, `main` as integration branch, prior CI alignment notes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`mix.exs` aliases:** `verify.format`, `verify.credo`, `verify.test`, `ci.all` — mirror what CI invokes.
- **`.github/workflows/ci.yml`:** Three parallel jobs with stable keys; Postgres 16 service for `verify-test`; `mix compile --warnings-as-errors` before tests in test job.

### Established patterns

- **Job ID contract** documented in workflow header and `CONTRIBUTING.md` — matches Phase 5 / engineering baseline.

### Integration points

- **README** badges row — primary discovery surface for Hex/README readers.
- **Branch protection** (maintainer): CONTRIBUTING already lists check names to require on `main`.

</code_context>

<specifics>
## Specific Ideas

- **Research synthesis (2026-04-23):** Four parallel research passes covered (1) strict **SHA-aligned** green definition vs PR/fork edge cases, (2) **badge + prose + CONTRIBUTING** layering for CI-03 a11y/discoverability vs Elixir/Rust/Ruby norms, (3) **minimal workflow diff** policy vs frozen-workflow purism for runner/service/action glue, (4) **`gh` + SHA match** as primary audit trail vs badge-only footguns. User asked for one coherent, low-surprise set — decisions above unify those threads.

</specifics>

<deferred>
## Deferred Ideas

- **Merge queue / merge-group** automation — overkill for v1.1; revisit if PR volume explodes.
- **Required checks automation** (API/terraform for branch rulesets) — optional hardening; not required to close Phase 6 if checks are documented and manually verified.
- **Matrix expansion** (multiple OTP/Elixir cells) — explicitly later; avoid scope creep during “main green.”

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches.

</deferred>

---

*Phase: 06-ci-on-github*
*Context gathered: 2026-04-23*
