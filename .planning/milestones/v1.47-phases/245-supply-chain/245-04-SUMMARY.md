---
phase: 245-supply-chain
plan: 04
subsystem: ci
tags: [github-actions, sha-pinning, supply-chain, provenance, deps-health]
status: complete

requires:
  - phase: 245-03
    provides: "79 canonical `owner/repo@<40-hex> # vX.Y.Z` refs and the offline pin contract"
provides:
  - "bin/verify-action-pins: network pin-to-tag provenance check, GH_BIN seam, --root DIR, fails closed (MISMATCH / UNVERIFIED / NOT-PINNED exit 1, zero refs exit 2)"
  - "test/threadline/verify_action_pins_test.exs: 20 fake-gh table rows (FAKE_GH_MODE, CALL_LOG, lookup file)"
  - "bin/deps-health-report VERIFY_ACTION_PINS_BIN seam; non-zero bumps unknown and writes `## Action pin provenance` right after the title"
  - "deps-health.yml report step env GH_TOKEN; permissions unchanged"
  - "CONTRIBUTING paragraph: verify-action-pins, sha_pinning_required as a maintainer action after landing, zizmor/pinact optional local tools"
affects: [245-05]

actuals:
  tokens: 17500
  tasks: 2
  commits: 2
plan_head_before: 2940e25bc8dc9acf1298250df73da7d99bcde9c4
plan_head_after: e29ba71f47506e45f562204b4264348c30e2d028

tech-stack:
  added: []
  patterns:
    - "Fail-closed network check behind a GH_BIN seam (the inverse of bin/ci-sha-gate's fail-open rule)"
    - "Validate every URL segment (repo, sha, tag) by regex before any gh call; the test proves an invalid value produces no call"
    - "Errexit-independent status capture: `out=$(cmd) && st=0 || st=$?`"

key-files:
  created:
    - bin/verify-action-pins
    - test/threadline/verify_action_pins_test.exs
  modified:
    - test/partition_weights.txt
    - bin/deps-health-report
    - test/threadline/deps_health_report_test.exs
    - .github/workflows/deps-health.yml
    - CONTRIBUTING.md
    - test/threadline/deps_health_doc_contract_test.exs

decisions:
  - "The pass line counts distinct (repo, tag, sha) triples, not raw refs: 8 today (actions/cache, /restore and /save share one triple), so a run makes 8 to 10 API calls"
  - "A docker:// ref is NOT-PINNED for this check (no tag to dereference), so adding one fails the scheduled lane closed until the script learns digests"
  - "A missing or non-executable pin-check binary is unknown (exit 127 is just another non-zero), never clean"
  - "The pin check runs even when a Hex suppression is active; the two are independent unknown sources"

metrics:
  duration: 50min
  completed: 2026-10-25
---

# Phase 245 Plan 04: Action pin provenance in the scheduled lane Summary

`bin/verify-action-pins` checks each pinned action SHA against the commit its `# vX.Y.Z` tag points to today, using read-only `gh api` calls. Annotated tags are followed through to their commit. The script fails closed on every error. The daily deps-health lane runs it once per run, so an impostor commit or a moved tag turns that run `unknown` within a day, with the reason at the top of the issue body. PR CI stays hermetic.

## What shipped

- **`bin/verify-action-pins` (D-14b).** It scans raw `uses:` lines (skipping full-line comments) in `.github/workflows/*.{yml,yaml}` and `.github/actions/**/action.{yml,yaml}`. `./` refs are skipped. Any ref not in canonical form prints `NOT-PINNED <file>:<line>`. The script validates repo, SHA and tag against the three regexes before it builds a URL, then dedups `repo tag sha` triples with `sort -u`. For each triple it calls `git/ref/tags/<tag>`, and if `.object.type == "tag"` also `git/tags/<sha>`. A gh error, or an answer that is not `<commit|tag> <40-hex>`, prints `UNVERIFIED`. A different commit prints `MISMATCH <repo>@<tag>: pinned <pin> resolves to <commit>`. Exit codes: 0 only when every pin matches; 1 on any failure line; 2 on a usage error, a missing root or zero refs. gh's stdin is `/dev/null`, so it cannot consume the triple list. There is one EXIT trap and no `$(...)`-registered cleanup.
- **Fake-gh table test.** 20 rows cover:
  - pass cases: a lightweight match (exactly one call) and an annotated match (a second `git/tags` call)
  - MISMATCH: on both the lightweight and the annotated path
  - UNVERIFIED: gh exits 1, `not-json`, a `null` deref, and an unknown tag (the fake exits 9, like a 404)
  - NOT-PINNED: tag-only (built by concatenation, with file:line), a SHA with no comment, `# v1.0.0;x` and an invalid repo (both with an empty call log), and a quoted ref
  - exit 2: an empty tree, local refs only, and usage errors
  - scanning: local refs and comments are skipped, a composite action under `.github/actions` is scanned, dedup across 3 sub-path actions in 2 files makes one call, and one bad pin among good ones still fails
  
  The partition weight row `1777 test/threadline/verify_action_pins_test.exs` was measured with `--slowest-modules` and is inserted in sorted position.
- **deps-health wiring (D-14, D-25).** `VERIFY_ACTION_PINS_BIN="${VERIFY_ACTION_PINS_BIN:-$SCRIPT_DIR/verify-action-pins}"` sits next to `MIX_BIN=`, and the header documents it. The check runs once, after the suppression check and before the per-directory loop. A non-zero exit bumps `unknown` and writes `## Action pin provenance` plus the exit code and the strip_ansi'd output (fenced) into a temp file. That file is printed right after the title and is removed in the existing EXIT cleanup.
- **Offline seam.** `run_report/2` and the copied-root "missing directory" test both pass a fake pins binary (`FAKE_PINS_EXIT`, `FAKE_PINS_OUTPUT`), so no report test reaches gh. There are 5 new tests:
  - a mismatch with clean dirs gives `unknown`, and the body starts `# Dependency health: unknown\n\n## Action pin provenance\n` with the MISMATCH line
  - a mismatch plus a root advisory gives `advisory`
  - a pass gives no block and `clean`
  - a missing binary gives `unknown`
  - a suppression does not skip the pin check
- **Workflow.** The report step gained `env: GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` and a comment explaining it. Job permissions are still `contents: read` + `issues: write`, and the job `id:` is unchanged. `ci.yml` has no reference to the check.
- **Docs + contract.** The CONTRIBUTING policy section has one new paragraph. It covers what the check does, that a mismatch leaves the issue open with the reason on top, that the check never runs on PRs, that `sha_pinning_required` is turned on only after the pins are on `main` (D-15), and that zizmor/pinact are optional local tools only (D-11). The doc contract gained 3 tests: the section names `bin/verify-action-pins`, `sha_pinning_required` and "never runs on pull requests"; the report step's env has `GH_TOKEN`; ci.yml never runs the check.

## Live provenance proof (second proof after 245-03's table, run 2026-10-25 against the working tree, authenticated read-only gh)

```
$ bin/verify-action-pins
verify-action-pins: 8 pin(s) match their tags
exit=0
```

## Verification

- `mix test test/threadline/verify_action_pins_test.exs`: 20 tests, 0 failures.
- The Task 2 list (deps_health_report, deps_health_doc_contract, verify_action_pins, ci_action_pin_contract, ci_token_permissions_contract): 151 tests, 0 failures.
- `ci_topology_contract_test.exs` + `ci_action_pin_contract_test.exs` after the weight row was added: 50 tests, 0 failures.
- Full `mix test` on an ephemeral postgres:16: **32 properties, 3409 tests, 0 failures, 3 excluded** (default pgbouncer_topology + live_dialyzer exclusions; +28 tests vs 245-03's 3381).
- `bash -n` and `shellcheck` pass on both scripts. The new script is clean. In deps-health-report, the only new findings are SC2016 at info level for literal backticks, the same pattern the file already uses. `actionlint .github/workflows/deps-health.yml` exits 0. `mix format --check-formatted` passes, `mix verify.credo` reports no issues, and `bin/verify-repo-hygiene` exits 0.
- Acceptance greps: the script is executable; the `GH_BIN=${GH_BIN:-gh}` count is 1; the weights row is present; `verify-action-pins` appears 0 times in ci.yml; the seam literal is in deps-health-report; `VERIFY_ACTION_PINS_BIN` is in the report test; `bin/verify-action-pins` and `sha_pinning_required` are both in CONTRIBUTING.

## Tracer feedback gate

Auto mode is active (`workflow.auto_advance=true`). Task 1's `<verify>` is automated only and was re-run end to end: the table test passed 20/0 and the live run exited 0. Tracer verified end to end, so expansion went ahead with Task 2.

## Deviations from Plan

None that change scope. Additions within the plan's intent:
- **[Rule 2] Extra fail-closed rows.** An annotated-deref garbage answer, an unknown-tag 404, an invalid repo with no gh call, a quoted ref, a composite action scan, local refs only (exit 2), and a missing pin binary in deps-health-report (unknown). Each guards a fail-open path the plan's prohibitions name.
- **[Rule 2] gh stdin set to `/dev/null`.** The triple loop reads a file on stdin. A gh that read stdin would silently swallow the remaining pins and make the run report fewer checks.
- **Doc-contract row "ci.yml never runs verify-action-pins".** It makes the PR-hermetic prohibition a test, not just a grep in the acceptance criteria.

## Maintainer hand-offs (deferred to landing)

- **D-15:** after the pins reach `main`, enable `sha_pinning_required`. Read-only check: `gh api repos/<owner>/<repo>/actions/permissions --jq .sha_pinning_required`. It stays `false` until then.
- **D-32:** this plan edits `.github/workflows/deps-health.yml`, so the push token needs `workflow` scope.
- The first real scheduled run is the first one that calls the check with `GITHUB_TOKEN`. Anonymous-rate or permission problems there would show up as `UNVERIFIED`, which means `unknown` with the reason in the issue, never a silent pass.

## Known Stubs

None.

## Self-Check: PASSED

- Files exist: bin/verify-action-pins, test/threadline/verify_action_pins_test.exs
- Commits reachable from HEAD: a36716cd, e29ba71f
