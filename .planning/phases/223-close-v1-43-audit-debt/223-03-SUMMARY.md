---
phase: 223-close-v1-43-audit-debt
plan: 03
subsystem: repo-hygiene-guard
tags: [ci, test, docs, contract-test, release-process]
status: complete
dependency-graph:
  requires:
    - "223-01: release.yml checkout credentials hardened (216 CR-01)"
    - "223-02: bin/verify-repo-hygiene R2-WR-01..04 fixed"
  provides:
    - "test/threadline/repo_hygiene_contract_test.exs: exact hint-line assertion + deletion mutation control (R2-IN-01)"
    - "CONTRIBUTING.md: precise allowlist-exemption wording (R2-IN-02) and the D-06 releasable-subject sentence"
    - ".planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md: all 11 findings recorded, 0 open"
    - "phase gate green: mix ci.all (2573 ExUnit tests / 0 failures, 318 Playwright passed / 26 skipped) and bin/verify-repo-hygiene --self-test (ok, 10 cases)"
  affects:
    - test/threadline/repo_hygiene_contract_test.exs
    - CONTRIBUTING.md
    - .planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md
tech-stack:
  added: []
  patterns:
    - "hint_line = ~r/^[ \\t]*printf '%s\\\\n' '[^'\\n]*Writing about machine-local paths[^'\\n]*' >&2[ \\t]*$/m — asserts the stderr line itself, not the phrase anywhere in the file"
    - "deletion mutation control: Regex.replace(hint_line, script, \"\", global: false), then refute mutated == script, refute Regex.match?(hint_line, mutated), and assert the bare phrase still survives elsewhere (proves the old check's vacuity)"
key-files:
  created: []
  modified:
    - test/threadline/repo_hygiene_contract_test.exs
    - CONTRIBUTING.md
    - .planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md
decisions:
  - "D-17 implemented verbatim per the plan's regex/mutation-control spec"
  - "D-18 wording landed on one un-wrapped line so the plan's grep -qF verification (and CONTRIBUTING's own contract test) can match the whole phrase; the paragraph's existing hard-wrap style otherwise unchanged"
  - "D-06 sentence added as one new paragraph after the `### Ongoing releases (0.6.1+)` numbered list, naming BEGIN_COMMIT_OVERRIDE; no new CI guard, per D-06's explicit deferral"
  - "D-20: 217-REVIEW-DISPOSITION.md hand-edited with the Edit tool in one commit; the gsd-core code-review disposition step was never invoked"
metrics:
  duration: "~20min"
  completed: 2026-09-29
actuals:
  tokens: 3200
  tasks: 3
  commits: 3
  plan_head_before: 95f19bafcb773d61ba752b0044d735725068c846
  plan_head_after: 3d2c555e5f1c8876d2e6e03464bd7af0ff23997c
---

# Phase 223 Plan 03: Close phase 217 round-2 review findings (info) + phase gate Summary

Fixed the last two round-2 findings (D-17 contract vacuity, D-18 CONTRIBUTING wording), added the
D-06 release-sentence, hand-recorded all six R2 dispositions as `fixed` (D-20), and ran the phase
gate for the B+C landing. `mix ci.all` and `bin/verify-repo-hygiene` are both green on
`milestone/v1.43` at commit `3d2c555e` with every 223 B+C commit present.

## What was built

**Task 1 (`test(223-03)`, commit `f005358f`, R2-IN-01/D-17):**
- Extended "the guard's failure hint names the CONTRIBUTING heading byte-for-byte" in
  `test/threadline/repo_hygiene_contract_test.exs` with a `hint_line` regex that matches the
  `printf '%s\n' '...' >&2` stderr line itself, not just the bare phrase (which the script's
  header comment also contains).
- Added the non-vacuity mutation control: assert the hint line occurs exactly once, build
  `mutated` by deleting only that line (`Regex.replace(hint_line, script, "", global: false)`),
  then `refute mutated == script`, `refute Regex.match?(hint_line, mutated)`, and
  `assert String.contains?(mutated, "Writing about machine-local paths")` — proving the phrase
  survives in the header comment after the hint line is gone, which is exactly the vacuity
  R2-IN-01 named.
- Kept both pre-existing assertions in the test unchanged (D-23: strengthening only).

**Task 2 (`docs(223-03)`, commit `265d0624`, R2-IN-02/D-18 + D-06):**
- Changed CONTRIBUTING's allowlist paragraph closing clause from "no file or directory is exempt
  from the scan." to "no file or directory is exempt from the scan other than the allowlist's own
  literal column." Kept on one unwrapped line (rather than the paragraph's usual ~78-column hard
  wrap) so the phrase can be matched as a single grep line by both the plan's verification command
  and CONTRIBUTING's own `every documented placeholder form passes the real guard`-style contract
  tests, which read exact substrings.
- Added one new paragraph after the `### Ongoing releases (0.6.1+)` numbered list stating that a
  landing PR carrying an adopter-facing Security/Fixed CHANGELOG entry must merge under a
  releasable squash subject (`fix:`/`feat:`/`perf:`/`deps:`) or carry a `BEGIN_COMMIT_OVERRIDE`
  block, because Release Please only parses the squash subject. No CI guard or lint added, per
  D-06's explicit deferral.

**Task 3 (`docs(217)`, commit `3d2c555e`, D-20 + phase gate):**
- Resolved the milestone-branch SHAs for all six R2 fixes:
  - R2-WR-04 → `354dde9a` (223-02 Task 1)
  - R2-WR-02 → `e99e172c` (223-02 Task 2)
  - R2-WR-01 and R2-WR-03 → `635de447` (223-02 Task 3)
  - R2-IN-01 → `f005358f` (223-03 Task 1)
  - R2-IN-02 → `265d0624` (223-03 Task 2)
- Hand-edited `217-REVIEW-DISPOSITION.md` with the Edit tool: all six `R2-*` frontmatter
  `disposition:` values set to `fixed`, `open: 0`, `total: 11` kept, `recorded:` refreshed to
  `2026-09-29T22:41:45.000Z`. Each R2 table row's Disposition cell set to `fixed` and Source cell
  set to `223-0N Task N <sha>` per the mapping above. R1 rows, titles, and the trailing explanation
  paragraphs left unchanged. The gsd-core code-review disposition step was never invoked.
- Verified every cited SHA resolves to a real commit (`git cat-file -t` = `commit`) and is an
  ancestor of `milestone/v1.43` (`git merge-base --is-ancestor` exits 0).
- Ran the phase gate on `milestone/v1.43` at commit `3d2c555e`:
  - `mix ci.all`: exit 0. ExUnit: **2573 tests, 0 failures, 3 excluded** (plus supporting suites:
    130 tests/0 failures, 17 tests/0 failures/16 excluded). Credo: `4474 mods/funs, found no
    issues`. `verify-deps-audit`: `3 lockfile(s) audit clean`. `verify-repo-hygiene`:
    `4243 tracked text file(s) clean; 8 allowlist entries used, 0 inert`. Dialyzer ran clean
    (part of the overall exit-0 `ci.all` run; no PLT rebuild or retry needed — no red at
    Dialyzer, no `too_many_connections`). Playwright/browser lane:
    `26 skipped, 318 passed (3.3m)`.
  - `bin/verify-repo-hygiene --self-test`: `verify-repo-hygiene self-test: ok (10 cases)`.
  - `bin/verify-repo-hygiene` (direct, post-gate): `4243 tracked text file(s) clean; 8 allowlist
    entries used, 0 inert`.

## Verification

- `mix test test/threadline/repo_hygiene_contract_test.exs`: 11 tests, 0 failures (after Task 1
  and again after Task 2).
- `grep -c 'refute mutated == script' test/threadline/repo_hygiene_contract_test.exs` → `1`.
- `grep -cF "exempt from the scan other than the allowlist's own literal column" CONTRIBUTING.md`
  → `1`; `grep -cF 'BEGIN_COMMIT_OVERRIDE' CONTRIBUTING.md` → `1`; the `awk` heading-scope check
  for the D-06 sentence prints `ok`.
- `grep -c '| open |' .planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` → `0`;
  `grep -c 'disposition: open'` → `0`; `open: 0` and `total: 11` present; the six R2 rows all
  match `| R2-XX-0N | severity | fixed | 223-0N Task N <8+-hex-sha> |`; the frontmatter id list and
  the table's Finding column diff clean.
- `grep -c "$(whoami)" <file>` printed `0` on all three modified files before each commit (D-22);
  `bin/verify-repo-hygiene` stayed clean after every task.
- `git show --name-only --format= HEAD` on each of the three commits lists exactly the one file
  the plan named for that task.
- Full `mix ci.all` run: exit 0, ExUnit 2573/0/3-excluded, Playwright 318 passed/26 skipped, credo
  clean, deps-audit clean, repo-hygiene clean, no dependency cycles.

## Deviations from Plan

None — plan executed exactly as written. The only adjustment was cosmetic: the D-18 sentence was
kept on one unwrapped line instead of re-wrapping at ~78 columns, so the exact-phrase grep checks
(both the plan's own verification command and CONTRIBUTING's existing placeholder-convention
contract tests) could match it as a single line; this does not change the paragraph's meaning or
any other line's wrapping.

## Known Stubs

None.

## Threat Flags

None — this plan implements the threat mitigations named in its own `<threat_model>`
(T-223-10..13); it introduces no new unmitigated surface. T-223-11 (the automated disposition step
overwriting the hand-edit) did not occur: the gsd-core code-review disposition step was never run
against `217-REVIEW-DISPOSITION.md`.

## Self-Check: PASSED

- `test/threadline/repo_hygiene_contract_test.exs` contains `refute mutated == script` — FOUND.
- `CONTRIBUTING.md` contains "exempt from the scan other than the allowlist's own literal column"
  and `BEGIN_COMMIT_OVERRIDE` — FOUND.
- `.planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` has `open: 0`, `total: 11`, and
  zero `| open |` rows — FOUND.
- Commit `f005358f` — FOUND (`git log --oneline --all | grep f005358f`).
- Commit `265d0624` — FOUND (`git log --oneline --all | grep 265d0624`).
- Commit `3d2c555e` — FOUND (`git log --oneline --all | grep 3d2c555e`).
- `mix ci.all` on `milestone/v1.43` at `3d2c555e`: exit 0 — confirmed.
- `bin/verify-repo-hygiene --self-test`: `ok (10 cases)` — confirmed.
