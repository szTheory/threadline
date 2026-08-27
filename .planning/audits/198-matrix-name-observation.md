# 198 — Emitted check-run name observation (GREEN-08 / D-11)

**This artifact records what GitHub actually emitted, observed from the check-runs API.**
It is not a restatement of what `ci.yml`'s comment predicted. D-11 requires the
matrix-naming question to be settled by observation "after the matrix has reported
once"; this is that observation.

## Provenance

| Field | Value |
|---|---|
| Repository | `szTheory/threadline` |
| Branch | `ci/v1_41-green-bringup` |
| Pull request | [#27](https://github.com/szTheory/threadline/pull/27) → `main` |
| Observed commit SHA | `009edbd9d7c526939b3cf2c854a711ae36e8cd05` |
| Primary run id (`pull_request`) | `33113148222` |
| Secondary run id (`workflow_dispatch` rehearsal) | `33113172280` |
| API queried | `GET repos/szTheory/threadline/commits/009edbd9d7c526939b3cf2c854a711ae36e8cd05/check-runs` |
| Observed | 2026-08-27, ~20:33 UTC |

Both runs are on the **same** head SHA, so the commit-level check-runs endpoint
returns each name twice (once per run). The per-run listing below is taken from
`GET repos/.../actions/runs/33113148222/jobs` to give one unambiguous row per job.

## Full emitted check-run list (verbatim, `pull_request` run 33113148222)

```json
[
  { "conclusion": "success", "name": "Build ExDoc (dev)" },
  { "conclusion": "failure", "name": "CI required" },
  { "conclusion": "success", "name": "Check formatting" },
  { "conclusion": "failure", "name": "Compile without optional deps" },
  { "conclusion": "failure", "name": "Example app browser E2E (Playwright)" },
  { "conclusion": "success", "name": "Hex evaluator smoke (threadline from hex.pm)" },
  { "conclusion": "success", "name": "Hex package tarball" },
  { "conclusion": "failure", "name": "Mechanical checker (committed scorecards)" },
  { "conclusion": "failure", "name": "PgBouncer transaction topology" },
  { "conclusion": "success", "name": "Release metadata (version / changelog)" },
  { "conclusion": "success", "name": "Run Credo (strict)" },
  { "conclusion": "failure", "name": "Run test suite (current)" },
  { "conclusion": "failure", "name": "Run test suite (min)" },
  { "conclusion": "failure", "name": "Tier A capture lane (byte-stable evidence)" }
]
```

Fourteen emitted names from thirteen YAML job ids — `verify-test` fans out into two.

## The verify-test matrix

`ci.yml` declares a **static** `name: Run test suite` over a base axis
`lane: [min, current]` whose per-lane `elixir` / `otp` / `pg` / `runner` values are
carried only via `include:`. GitHub emitted, verbatim:

```
Run test suite (min)
Run test suite (current)
```

- **min lane** → `Run test suite (min)` — conclusion `failure`
- **current lane** → `Run test suite (current)` — conclusion `failure`

Two distinct names. The suffix is the **base-axis** value (`min` / `current`) and
nothing else: none of the `include:`-only keys (`elixir`, `otp`, `pg`, `runner`)
appear in either emitted name. So the emitted suffix is `(min)` / `(current)`, not
`(min, 1.15, 26, 14, ubuntu-22.04)`.

## Verdict

**GitHub appended the matrix value to the static job name, yielding two distinct
suffixed check names — `Run test suite (min)` and `Run test suite (current)` — exactly
as the `ci.yml` comment asserted.**

### The ci.yml comment agrees with reality — no edit made

The comment block above `verify-test` asserts that GitHub "posts exactly
`Run test suite (min)` and `Run test suite (current)`" and that `include`-only keys do
not append to the suffix. **The observation confirms both halves of that claim, byte
for byte.** Per Task 2's instruction, the comment is therefore left unchanged: it was
not stale, and rewriting a correct comment would be a fabricated correction.

What *has* changed is the comment's epistemic status. It was flagged
`RESEARCH A2 — unverified`: mainstream-but-undocumented platform behavior, with the
base-axis-plus-`include` shape specifically the subject of unresolved GitHub Community
discussions (#26822, #60792). It is now **observed**, once, on this repository's own
matrix. This artifact is the evidence; the comment is the summary.

## Why this no longer creates a deadlock risk

The original GREEN-08 hazard was a *protection* hazard, not a naming curiosity: if a
required status check is enumerated by emitted name, and the emitted name embeds a
matrix axis, then renaming or re-shaping the matrix silently orphans the required
context — and GitHub blocks every pull request forever waiting on a check name that
nothing will ever emit again.

Under **D-08** that failure mode is structurally gone:

1. **The only required check is the aggregate `CI required`.** Its name carries no
   matrix axis, so it cannot rot when the matrix changes.
2. **`needs: verify-test` is satisfied by the completion of all matrix legs**,
   regardless of what suffix GitHub renders for each leg. `needs:` binds to the YAML
   **job id**, which this repo's `CLAUDE.md` already treats as an immutable contract —
   not to the emitted display name.
3. Therefore the verdict above could have gone **either** way — appended or not — and
   branch protection would be unaffected. The observation is recorded because D-11
   requires the question settled by evidence rather than assumption, not because a
   different answer would have forced a redesign.

The residual, and it is worth naming: this is a **one-time** observation of behavior
GitHub does not document. It is not a guarantee. It is safe to depend on precisely
because nothing in the protection design depends on it.

## Min-lane rehearsal

Per D-21 the `min` lane stays **pull-request-blocking from day one** — no
`continue-on-error` was added, and `grep -c 'continue-on-error' .github/workflows/ci.yml`
returns `0`. It was rehearsed rather than downgraded.

| Field | Value |
|---|---|
| Rehearsal mechanism | `gh workflow run ci.yml --ref ci/v1_41-green-bringup` (`workflow_dispatch`) |
| Run id | **`33113172280`** |
| Dispatch rejected? | **No** — the fallback to the Task 1 pull-request run was not needed |
| Job | `Run test suite (min)` (job id `98661003718`) |
| Lane pinning | Elixir 1.15 / OTP 26 / PostgreSQL 14 / `ubuntu-22.04` |
| **Conclusion** | **`failure`** |
| Result | `1382 tests, 83 failures, 1 excluded` (finished in 153.6s) |

### Failing job and first error line, verbatim

Failing job: **`Run test suite (min)`**. First `##[error]` emitted by the run:

```
##[error]     test/threadline/operator_surface/formless_pages_test.exs:61
     policy_redaction_live.ex must stay formless but contains form control(s): ["<select", "<form"]. Display-only pages must not add forms; use UI.field/UI.field_group on a real form page instead. (The hidden _csrf_token and theme-picker form live in the separate surface_header component and are intentionally excluded.)
```

### Cause classification

**Genuine code/test failure — not runner image drift, not Playwright/browser version drift.**

The evidence for that classification, rather than the assertion alone:

- The Elixir 1.15 / OTP 26 toolchain installed, dependencies resolved, and the suite
  **compiled and executed 1382 tests** on `ubuntu-22.04`. A runner-image or toolchain
  drift failure aborts before or during compilation; this one ran to completion and
  reported a normal ExUnit summary.
- The failures are ordinary assertion and database failures — the first is a docs/UI
  contract assertion, and the bulk are
  `** (Postgrex.Error) ERROR 42P01 (undefined_table) relation "audit_transactions" does not exist`,
  i.e. an un-migrated test schema. Neither is version-specific.
- **Decisively: the `current` lane (Elixir 1.17.3 / OTP 27 / pg16 / `ubuntu-24.04`)
  reported the identical `1382 tests, 83 failures, 1 excluded`.** The min lane
  contributes **zero** additional failures over the current lane.

### What this means for the milestone's highest-variance risk

The ROADMAP records that the `min` lane has never executed on origin, and flags it as
this milestone's highest-variance risk on the theory that the Elixir 1.15 floor promise
might be quietly broken. **It is not.** Min and current fail identically, which means
the 83 failures are the milestone's already-known shared red baseline — the same
baseline v1.41 exists to retire — and **not** a floor break. The declared Elixir 1.15
support is, on this evidence, sound.

This is the first time that has been measured rather than assumed, and it retires a
risk the roadmap was carrying at a much higher weight.

### No fallback proposal is handed to Plan 05

The roadmap's stated fallback — moving the browser lanes off the pull-request trigger
onto nightly — is conditioned on the failure being diagnosed as **runner or Playwright
version drift**. It was not. Per Task 3's "if and only if" clause, **no such proposal is
recorded and nothing is handed to Plan 05.** Recording a drift-mitigation proposal for a
failure that is not drift would hand Plan 05 a fabricated premise.

(Separately, `Example app browser E2E (Playwright)` did fail in both runs. That job is
not the min lane, is out of this task's scope, and is Plan 05's owned surface. It is
mentioned here only so a later reader does not mistake this section's narrow "not
drift" finding for a claim about the Playwright job.)

## The aggregate gate's own behaviour under real failure

Recorded here because it is the tracer's actual payload, and because a gate that has
only ever been observed green is an unproven gate:

`CI required` (job id `ci-required`, check-run id `98663112338`) **completed with
conclusion `failure`** at 2026-08-27T20:32:10Z, on both the pull-request run and the
dispatch run, with six of its twelve needed jobs red. It did **not** report `skipped`,
and it did **not** report a stale success.

That is the exact behavior `if: always()` plus `jobs: ${{ toJSON(needs) }}` exists to
produce (D-09), and the exact behavior a hand-rolled result-string containment gate
would have failed to produce: without `always()`, a job that `needs:` a failed job is
marked *skipped*, and GitHub scores a skipped required check as **passing**. The gate
has now been proven red-on-failure by observation, not by reading the action's README.

The complementary case — the gate going **green** when all twelve needed jobs succeed —
has **not** been observed and cannot be until the lanes are green. That is Plans 04–06's
work, and this artifact makes no claim about it.

---
*Phase: 198-green-bringup · Plan 03 · Tasks 2 and 3*
*Observed: 2026-08-27*
