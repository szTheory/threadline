# Phase 6: CI on GitHub — Research

**Role:** gsd-phase-researcher  
**Date:** 2026-04-23  
**Question answered:** What do you need to know to **plan** this phase well?

---

## Executive summary

Phase 6 is **not** a greenfield CI design: `.github/workflows/ci.yml` already encodes the v1.1 contract (triggers on `main`, three stable job keys, Postgres-backed tests). Planning should focus on **(1)** proving **CI-02** with SHA-aligned evidence (not badges alone), **(2)** closing any **CI-03** / **06-CONTEXT** doc gaps (especially “under the badge” placement and link hygiene), **(3)** resolving **local vs CI parity** around `mix compile --warnings-as-errors`, which runs in `verify-test` but is **not** part of `mix ci.all`, and **(4)** hardening **Postgres service** behavior only if flakes appear—prefer healthchecks over sleeps. Elixir/OTP pin changes stay out of scope unless runner breakage forces an explicit decision.

---

## GitHub Actions, SHA alignment, and `gh` CLI

**What “green” means for planning:** Per `06-CONTEXT` (D-01–D-02), success is **`origin/main`’s tip SHA** appearing as the **head SHA** of a **completed** workflow run where **`verify-format`**, **`verify-credo`**, and **`verify-test`** each have **`conclusion: success`**—not skipped. Re-runs count; cancelled/failed runs do not close the phase until a successful completed run exists for that SHA.

**Why SHA matters:** Shields.io / workflow badges summarize **default-branch** state but can **lag**, **cache**, or **differ in semantics** from “this exact commit.” Planners should treat **badge + README prose** as **CI-03** discovery, **not** as **CI-02** proof (`06-CONTEXT` D-11).

**`gh` commands useful in PLAN / verification:**

- List recent runs on `main` for this workflow:  
  `gh run list --repo szTheory/threadline --workflow=ci.yml --branch=main --limit=5`
- Inspect one run (conclusions + head commit):  
  `gh run view <run-id> --repo szTheory/threadline --json conclusion,displayTitle,headSha,url,workflowName`
- Per-job conclusions (if you need job-level JSON):  
  `gh run view <run-id> --repo szTheory/threadline --json jobs` (then inspect job `conclusion` / `name` mapping)

**Local SHA to compare:**  
`git fetch origin main && git rev-parse origin/main` must match the successful run’s `headSha`.

**PR vs main:** CI-02 is **main-only**; branch protection on PRs is recommended (D-03) but not the formal close criterion. Fork PRs may need maintainer approval for Actions—document as operational, not a redefinition of green.

---

## Mix task parity (local `mix ci.all` vs CI)

| Step | `verify-format` | `verify-credo` | `verify-test` (CI) | `mix ci.all` (local) |
|------|-----------------|----------------|---------------------|----------------------|
| Env | default | default | `MIX_ENV: test`, `DB_HOST: localhost` | `:test` for full alias (`mix.exs` `cli/0`) |
| Deps | `mix deps.get` | same | same | developer runs `deps.get` as needed |
| Format / Credo / Test | `mix verify.*` | same | `mix verify.test` | same three aliases in sequence |
| Compile | — | — | **`mix compile --warnings-as-errors`** before tests | **not** included |

**Planning implication:** Contributors who only run `mix ci.all` can still fail **only** on CI if warnings-as-errors trips. Options for PLAN.md: (a) extend `ci.all` or add a documented optional step, (b) document “CI runs stricter compile” in CONTRIBUTING, or (c) accept CI-only gate—pick explicitly so UAT matches expectations.

---

## Postgres service in GitHub Actions

The **`verify-test`** job uses a **`services.postgres`** container (`postgres:16`), env aligned with `config/test.exs` (`postgres` / `postgres` / `threadline_test`), **`DB_HOST: localhost`**, port **5432**, and Docker **healthcheck** (`pg_isready`, interval/timeout/retries). That matches the project’s stated preference to fix infra flakiness via **service definition** (D-09), not `sleep` in tests.

**Planning checks:** If tests fail intermittently, first inspect **service startup ordering** and healthcheck logs; avoid broad test retries before confirming Postgres readiness.

---

## CI-03 gaps vs current README

**REQUIREMENTS.md CI-03** (minimal): README must document where to find CI (Actions link and/or badge).

**Current README (first lines):** Badge targets the **workflow file** URL (`…/actions/workflows/ci.yml`); a dedicated **CI** paragraph links to the **Actions hub** (`…/actions`), names the three job keys, and points to CONTRIBUTING for local parity.

**`06-CONTEXT` D-05–D-06 (stricter than raw CI-03):**

- **D-05:** One short **plain-text** line **immediately under** the badge row linking to Actions—not badge alone. Today there is a **blank line** between the badge block and the `**CI:**` paragraph; decide whether to tighten layout (move CI line up) for strict “immediately under.”
- **D-06:** Prose should prefer **run history / Actions hub** links; the badge image endpoint may stay workflow-scoped—that is acceptable if prose satisfies discovery.

**CONTRIBUTING.md:** Already includes workflow path, **main-filtered** Actions URL, and job-key contract—aligns with D-05’s “README + CONTRIBUTING” split; optional single extra link to `/actions` is low value unless you want symmetry with README.

---

## Risks and mitigations

| Risk | Mitigation in planning |
|------|-------------------------|
| **Flaky CI** (Postgres timing, network) | D-04: treat as release blocker; prefer re-run for GitHub incidents, then fix root cause (D-09). |
| **Fork PR Actions** disabled until approval | Document for contributors; does not change main@HEAD definition. |
| **Branch protection “required check” labels** | GitHub shows `name:` or job context strings; CONTRIBUTING already warns—PLAN should say “map UI labels to the three job keys.” |
| **`mix ci.all` vs warnings-as-errors drift** | Explicit decision in PLAN / UAT (see Mix parity). |
| **Silent workflow skips** on `main` | Forbidden for the three jobs (D-02)—no path filters or skip tricks that skip verifiers on `main`. |

---

## Validation Architecture (automated vs manual, CI-02 proof, sampling, REQ mapping)

**Automated (in-repo):** The workflow **is** the automated verifier: each push/PR to `main` runs the three jobs. No additional in-repo bot is required for Phase 6 unless you choose to add one (out of scope unless decided).

**Manual / maintainer (required for close):**

1. **CI-01:** Confirm on GitHub that `.github/workflows/ci.yml` on `main` defines jobs **`verify-format`**, **`verify-credo`**, **`verify-test`** (unchanged keys)—quick UI or raw file view on `main`.
2. **CI-02:** Collect **primary proof** (D-10): `origin/main` SHA + `gh run` (or `gh run view`) showing **same `headSha`**, workflow **`ci.yml`**, all three jobs **success**—paste **run URL** in verification notes. Do **not** rely on badge alone (D-11). Name workflow file + job keys in write-up (D-12).
3. **CI-03:** Human read of README (and CONTRIBUTING as supporting): badge **plus** obvious Actions discovery; reconcile with D-05 layout if you want zero ambiguity vs “immediately under badge.”

**Sampling strategy:** For CI-02, **at least** the latest successful run on `main` for `ci.yml`; if diagnosing flakes, sample **last N** runs (`--limit=5`) for the same SHA or consecutive SHAs.

**Requirement mapping:**

| Requirement | What “done” needs |
|-------------|-------------------|
| **CI-01** | Workflow present on `main` with three named jobs (file + YAML keys). |
| **CI-02** | **SHA-aligned** successful completed run for all three jobs on `main@HEAD`. |
| **CI-03** | README (primary) documents where to see status; **06-CONTEXT** adds accessibility/link layering—verify against D-05/D-06, not only the one-line REQ text. |

---

## RESEARCH COMPLETE
