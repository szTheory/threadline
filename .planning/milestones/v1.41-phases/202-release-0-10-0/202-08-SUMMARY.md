---
phase: 202-release-0-10-0
plan: 08
subsystem: testing
tags: [exunit, elixir, flake, fixtures, _build, on_exit]

requires:
  - phase: 202-release-0-10-0
    provides: "deferred-items.md CORRECTION entry proving the counter-reuse mechanism"
provides:
  - "critic_trust_test.exs scratch directory names that are unique across mix test runs and across concurrent runs on one checkout"
  - "self-cleaning scratch trees — _build/critic-trust-path-tests/ no longer grows"
  - "a recorded, on-demand reproduction of the File.LinkError intermittent"
affects: [202-05 publish gate, CI _build cache hygiene, release 0.10.0 green-suite claim]

actuals:
  tokens: 2400
  tasks: 1
  commits: 1
  plan_head_before: 4f02e8e81fdf6cd778c9d2c72f80b4d2a0b22bf9

tech-stack:
  added: []
  patterns:
    - "Test scratch paths carry a per-run component (OS pid + nanosecond clock) in addition to the per-BEAM counter"
    - "Scratch trees are torn down by ExUnit on_exit, removing only the directory the test created"

key-files:
  created:
    - .planning/phases/202-release-0-10-0/202-08-SUMMARY.md
  modified:
    - test/threadline/operator_surface/critic_trust_test.exs

key-decisions:
  - "Cleanup is unconditional — it runs on failure too. The unbounded leak IS the defect; retaining trees on failure reintroduces growth precisely on the hard-to-notice path, and the tree is reconstructible from the checked-in fixtures plus the test body."
  - "Uniqueness is OS pid + System.os_time(:nanosecond) + System.unique_integer/1, not a timestamp alone — two concurrent mix test processes against one checkout must not collide."
  - "The 542 pre-existing leftover directories are NOT deleted by test code; a one-time manual command is recommended instead."

patterns-established:
  - "Per-run uniqueness: any _build scratch name seeded only by System.unique_integer/1 is reused across runs, because that counter restarts with each BEAM instance."

requirements-completed: [RELEASE-01]

coverage:
  - id: D1
    description: "Scratch directory names are unique across mix test runs and across concurrent runs on the same checkout"
    requirement: RELEASE-01
    verification:
      - kind: integration
        ref: "mix test test/threadline/operator_surface/critic_trust_test.exs --repeat-until-failure 25"
        status: pass
      - kind: integration
        ref: "mix test (full suite, twice, with the 542 pre-existing leftovers in place)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each test removes the scratch tree it created, so _build/critic-trust-path-tests/ stops growing"
    requirement: RELEASE-01
    verification:
      - kind: integration
        ref: "ls _build/critic-trust-path-tests | wc -l before and after a full suite run — 542 -> 542"
        status: pass
    human_judgment: false
  - id: D3
    description: "The collision was reproduced on demand before the fix"
    verification:
      - kind: manual_procedural
        ref: "measurement_roots!/1 suffix temporarily pinned to 132290; mix test ...:838 raised File.LinkError"
        status: pass
    human_judgment: false
  - id: D4
    description: "preserve_repository_ledger/1 still restores test/fixtures/operator_surface/design-system-ledger.json"
    verification:
      - kind: other
        ref: "git diff HEAD~1 HEAD — preserve_repository_ledger/1 is outside the diff hunks; full suite green"
        status: pass
    human_judgment: false

duration: 22min
completed: 2026-09-22
status: complete
---

# Phase 202 Plan 08: Critic-trust scratch-name collision Summary

**`critic_trust_test.exs` scratch trees are now named `<label>-<os pid>-<nanoseconds>-<counter>` and torn down in `on_exit`, so a restarting per-BEAM counter can no longer re-draw a previous run's directory and `_build/critic-trust-path-tests/` stopped growing at 542.**

## Performance

- **Duration:** ~22 min
- **Tasks:** 1
- **Files modified:** 1 (`test/threadline/operator_surface/critic_trust_test.exs`)

## Reproduction (recorded, as required before the fix)

Two independent pieces of evidence, both produced before any fix was applied.

**1. The counter restarts per BEAM instance.** Three fresh BEAMs, each printing one draw:

```
$ for i in 1 2 3; do elixir -e 'IO.puts(System.unique_integer([:positive]))'; done
2630
2626
2626
```

A name seeded only by that counter is therefore drawn from the same small range on every `mix test`.

**2. The real test fails with `File.LinkError` on a reused name.** `_build/critic-trust-path-tests/root-overlap-132290/` (mtime Sep 22 09:50) already held the self-referential symlink `output-alias -> .../root-overlap-132290`. `measurement_roots!/1`'s suffix was temporarily pinned to the literal `132290` and the single test re-run:

```
$ mix test test/threadline/operator_surface/critic_trust_test.exs:838

  1) test critic.measure rejects bidirectional canonical overlap without prefix confusion
     test/threadline/operator_surface/critic_trust_test.exs:838
     ** (File.LinkError) could not create symlink from
        ".../_build/critic-trust-path-tests/root-overlap-132290" to
        ".../_build/critic-trust-path-tests/root-overlap-132290/output-alias": file already exists
     stacktrace:
       (elixir 1.17.3) lib/file.ex:693: File.ln_s!/2
       test/threadline/operator_surface/critic_trust_test.exs:846
  30 tests, 1 failure, 29 excluded
```

That is the exact reported failure, on demand. The pin was then reverted (`git checkout --`, byte-identical to a pre-edit copy) before the real fix was written.

## Accomplishments

- **Per-run uniqueness.** `scratch_dir_name/1` produces `"#{name}-#{System.pid()}-#{System.os_time(:nanosecond)}-#{System.unique_integer([:positive])}"`. The OS pid separates two `mix test` processes running concurrently against the same checkout (a coarse timestamp alone would not); the nanosecond clock separates sequential runs that recycle a pid; the counter separates calls within one run. `System.unique_integer/1` is no longer the sole source of uniqueness.
- **Leak closed.** `cleanup_scratch/1` registers `on_exit(fn -> File.rm_rf(base) end)`. It removes only the directory the test created — never the shared `critic-trust-path-tests` root, never a sibling — and `File.rm_rf/1` is a no-op if the path is already gone. `on_exit` fires even when the test raises. `File.rm_rf/1` unlinks the self-referential `output-alias` symlink rather than following it (confirmed: no leftover trees after 26 runs).
- **Same treatment for the `/tmp` escape-control root.** `threadline-critic-outside-<counter>` had the same name shape and the same leak (61 old-format leftovers in `$TMPDIR`). It now uses `scratch_dir_name/1` and an `on_exit` removal. Zero new-format leftovers after 26 runs.
- **`preserve_repository_ledger/1` untouched.** The real repository fixture `test/fixtures/operator_surface/design-system-ledger.json` is still saved and restored exactly as before; the function is outside every diff hunk.

## Decision: cleanup is NOT skipped on failure

**Decision:** the scratch tree is removed unconditionally, including when the test fails.

**Reason:** the unbounded leak is the proximate cause of this defect, and skipping cleanup on failure reintroduces growth on exactly the path that is hardest to notice — an intermittent failure in CI, which is where the trees would accumulate fastest and where nobody is watching `_build`. The retained evidence would also be worth little: the scratch tree is a verbatim copy of three checked-in fixtures plus whatever the test body wrote, so it is reconstructible at will (as the reproduction above demonstrates — pinning the suffix recreates the failing state deterministically). A conditional retention policy would trade a real, recurring hygiene defect for diagnostic value that can be obtained on demand.

## Verification

| Check | Result |
|---|---|
| `mix test .../critic_trust_test.exs --repeat-until-failure 25` | 26 × `30 tests, 0 failures` (initial run + 25 repeats), no failures |
| `ls _build/critic-trust-path-tests \| wc -l` before full run | **542** |
| `ls _build/critic-trust-path-tests \| wc -l` after full run | **542** (no increase — leak closed) |
| `mix test` (full suite, run 1) | `1692 tests, 0 failures, 1 excluded` — 139.3s |
| `mix test` (full suite, run 2) | `1692 tests, 0 failures, 1 excluded` — 146.4s |
| `git diff --stat` | only `test/threadline/operator_surface/critic_trust_test.exs` |
| `mix format --check-formatted` | clean |

Both full-suite runs were executed with all 542 pre-existing leftover directories still in place, so the fix does not depend on starting from a clean `_build`.

## Task Commits

1. **Task 1: Make scratch names unique across runs and clean them up** — `2ef3be68` (fix)

**Plan metadata:** see the `docs(202-08)` commit.

## Files Created/Modified

- `test/threadline/operator_surface/critic_trust_test.exs` — `scratch_dir_name/1` and `cleanup_scratch/1` helpers; `measurement_roots!/1`, `synth_root!/1`, and the `/tmp` escape-control root now use them.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Same defect class in the `/tmp` escape-control root**

- **Found during:** Task 1 (reading every call site before editing)
- **Issue:** `critic_trust_test.exs:790` built `System.tmp_dir!()/threadline-critic-outside-#{System.unique_integer([:positive])}` — the identical per-BEAM-counter name shape, never cleaned up (61 leftovers found in `$TMPDIR`). It does not raise today only because `File.mkdir_p!` is idempotent and the symlink it feeds lands in a fresh base; fixing the `_build` path while leaving this one would have left the same latent trap one edit away.
- **Fix:** routed it through `scratch_dir_name/1` and added `on_exit(fn -> File.rm_rf(outside) end)`.
- **Files modified:** `test/threadline/operator_surface/critic_trust_test.exs` (same file, inside the plan's declared blast radius)
- **Verification:** after 26 runs, `ls -d $TMPDIR/threadline-critic-outside-*-*-*` matches nothing — zero new-format leftovers.
- **Committed in:** `2ef3be68`

---

**Total deviations:** 1 auto-fixed (1 missing critical).
**Impact on plan:** contained to the one file the plan authorizes. No scope creep.

## Issues Encountered

None. The mechanism was already proven in `deferred-items.md`; this plan reproduced it, fixed it, and verified the fix from a dirty `_build`.

## Recommended one-time maintenance (NOT done by test code)

The pre-existing leftovers are deliberately left in place — a test that deletes directories it did not create is a worse defect than the leak. Clear them manually when convenient:

```bash
rm -rf _build/critic-trust-path-tests
rm -rf "${TMPDIR:-/tmp}"/threadline-critic-outside-*
```

Neither is required for the suite to be green; both runs above passed with all 542 still present.

## CI note

The earlier `deferred-items.md` caveat — "CI is only safe here if its `_build` cache does not carry prior scratch trees" — is now moot. Names are unique per run regardless of what the cache carries, and each run cleans up after itself, so a warm `_build` cache can no longer accumulate colliding names.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The last unexplained intermittent blocking the 0.10.0 "green suite" claim is explained, reproduced, fixed, and verified.
- 202-05 may now state the stronger claim honestly: the flake had a proven mechanism (per-BEAM counter reuse against never-cleaned scratch trees) and it is fixed at the source.

---
*Phase: 202-release-0-10-0*
*Completed: 2026-09-22*

## Self-Check: PASSED

- `.planning/phases/202-release-0-10-0/202-08-SUMMARY.md` — FOUND
- `test/threadline/operator_surface/critic_trust_test.exs` — FOUND
- commit `2ef3be68` — FOUND in `git log --oneline --all`
- `git rev-list --count 4f02e8e8..HEAD` = 1 code commit (this plan's ledger base is `4f02e8e81fdf6cd778c9d2c72f80b4d2a0b22bf9`)
