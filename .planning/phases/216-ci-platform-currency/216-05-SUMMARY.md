---
phase: 216-ci-platform-currency
plan: 05
subsystem: ci
tags: [github-actions, node24, release-please, contract-test, runbook]
status: complete
requires:
  - 216-04 (Node 24 action majors in every workflow; rehearsal recorded in 216-EVIDENCE.md)
provides:
  - test/threadline/ci_action_runtime_contract_test.exs — fail-closed {action, ref} allowlist over every workflow file
  - CONTRIBUTING "### Upgrading the Release Please action" runbook, doc-contract-tested against release.yml
affects:
  - 216-06 / 216-07 (pre-push controls and post-landing evidence)
tech-stack:
  added: []
  patterns:
    - "Fail-closed action allowlist: every `uses:` ref must be a verified {action, ref} pair; unused entries fail (stale-entry rule)"
    - "Doc contract: the action major in release.yml must match the major named in the runbook, which must also name the bundled library version"
key-files:
  created:
    - test/threadline/ci_action_runtime_contract_test.exs
  modified:
    - CONTRIBUTING.md
decisions:
  - "uses_refs/1 captures the whole `uses:` value then classifies it, so a ref with no `@` is reported as needing a decision, alongside `./` and `docker://` refs (stricter than the plain Pattern 4 regex, same coverage for normal refs)"
  - "The runbook section is bounded by the next `##` or `###` heading, so the contract cannot read into a following top-level section"
metrics:
  duration: ~25 min
  completed: 2026-09-26
  tasks: 2
  files: 2
actuals:
  tokens: 3400
  tasks: 2
  commits: 2
plan_head_before: 950842925c961788bc1885900ee03c8223b41c3e
---

# Phase 216 Plan 05: Node 24 action allowlist and Release Please runbook Summary

A fail-closed contract test now checks every `uses:` ref in `.github/workflows/*.{yml,yaml}` against an exact allowlist of 10 verified Node 24 or composite `{action, ref}` pairs. A new CONTRIBUTING runbook records the release-please-action v5 rehearsal, and a doc contract fails when release.yml's action major moves without the runbook being updated.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tracer: fail-closed node24 allowlist test over every workflow | 060cf713 | test/threadline/ci_action_runtime_contract_test.exs |
| 2 | Release Please upgrade runbook and its doc contract | 4a8514d6 | CONTRIBUTING.md, test/threadline/ci_action_runtime_contract_test.exs |

## Non-vacuity against real history

- Plan 04 cache-bump commit: `702d3d5f684223288de0b1fbc61bcd534cf78fd5` (`ci(actions): move cache and upload-artifact to their Node 24 majors`)
- Its parent: **`21bb7e1bbdc395826ca2510edbd6846d99378059`**
- `git show 21bb7e1b:.github/workflows/ci.yml | grep -c 'uses: actions/cache@v4'` = **13**, in the same `uses: actions/cache@v4` form the synthetic controls use. `node20_errors/1` would have failed on that tree. On today's tree it returns `[]`.

## Verification

- Targeted run (new file plus the parity, topology and release control-plane contract files): 63 tests, 0 failures
- Mutation controls (all return errors): known Node 20 cache major; release-please-action v4; unknown action; list-item `- uses:`; quoted ref; `./` and `docker://` refs. A commented-out ref is ignored, and a benign allowlisted workflow returns `[]`. Runbook: release.yml bumped to v6, heading deleted, and bundled library version removed each fail.
- Live: the scan finds more than 0 refs, and no allowlist entry is unused
- Full `mix test`: 2317 tests, 0 failures, 2 excluded (see note below)
- `mix verify.format`, `mix verify.credo` (no issues), `actionlint -shellcheck=` (clean)
- Acceptance greps: 10 map entries; alls-green SHA present once; 0 phase/requirement IDs in the test; runbook sits between the two named headings and names `@v5`, `17.6.0` and `--dry-run`; no `ghp_`/`gho_` tokens in CONTRIBUTING

## Deviations from Plan

None in scope. One note: the first full `mix test` run had 1 failure, with an Ecto.Migrator stack trace. It passed on `mix test --failed`, and a second full run was clean (2317/0). The failure is unrelated to this plan's files (a docs subsection and a pure-text test module). It looks like a pre-existing ordering flake in the DB/migration tests, so it is not tracked here as a regression.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: test/threadline/ci_action_runtime_contract_test.exs
- FOUND: CONTRIBUTING.md `### Upgrading the Release Please action`
- FOUND: 060cf713, 4a8514d6
