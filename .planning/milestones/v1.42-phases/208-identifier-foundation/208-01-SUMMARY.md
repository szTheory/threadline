---
phase: 208-identifier-foundation
plan: 01
subsystem: infra
tags: [release-please, stream_data, crypto, mix]

requires: []
provides:
  - "release-please pre-1.0 policy: BREAKING CHANGE proposes a minor bump, not 1.0.0"
  - "contract test guarding bump-minor-pre-major / bump-patch-for-minor-pre-major"
  - "stream_data 1.4.0 (test-only) and :crypto in extra_applications for later plans"
affects: [208-identifier-foundation, release]

actuals:
  tokens: 1322
  tasks: 2
  commits: 2
plan_head_before: fd128c6794ddce302aee9f31ee6f5760249a12a1

tech-stack:
  added: [stream_data 1.4.0 (test-only)]
  patterns: ["release-please config keys guarded by changelog_contract_test.exs"]

key-files:
  created: []
  modified:
    - release-please-config.json
    - test/threadline/changelog_contract_test.exs
    - mix.exs
    - mix.lock

key-decisions:
  - "REL-01 config flip committed as ci(release): first config-touching commit on milestone/v1.42, with no feat/fix/perf/deps commit before it"

patterns-established:
  - "Test-only deps carry a comment naming their Elixir floor so the 1.15 floor guard stays green"

requirements-completed: [REL-01]

coverage:
  - id: D1
    description: "bump-minor-pre-major is true and bump-patch-for-minor-pre-major is false, guarded by a contract test"
    requirement: REL-01
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs#pre-1.0 breaking changes propose a minor release, not 1.0.0"
        status: pass
    human_judgment: false
  - id: D2
    description: "The ci(release) commit is the first commit touching release-please-config.json on main..HEAD and no releasable commit precedes it"
    requirement: REL-01
    verification:
      - kind: other
        ref: "git log --reverse --format='%h %s' main..HEAD -- release-please-config.json | head -1 | grep -E '^[0-9a-f]+ ci(\\(release\\))?: '"
        status: pass
    human_judgment: false
  - id: D3
    description: "stream_data ~> 1.4 test-only dep locked at 1.4.0 and :crypto in extra_applications; floor guard green"
    verification:
      - kind: unit
        ref: "test/threadline/dep_floor_guard_test.exs"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix run --no-start -e 'Code.ensure_loaded!(ExUnitProperties); ...' prints 9bba11019407"
        status: pass
    human_judgment: false

duration: 2min
completed: 2026-09-25
status: complete
---

# Phase 208 Plan 01: Release Policy Flip and Test Infrastructure Summary

**release-please now proposes a minor bump (not 1.0.0) for pre-1.0 breaking changes, enforced by a changelog contract test, with stream_data 1.4.0 and :crypto installed for the identifier-naming plans**

## Performance

- **Duration:** about 2 min
- **Started:** 2026-09-25T13:43:35Z
- **Completed:** 2026-09-25T13:44:45Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `bump-minor-pre-major` flipped to `true` (`bump-patch-for-minor-pre-major` stays `false`); no other bytes in the config changed
- New contract test "pre-1.0 breaking changes propose a minor release, not 1.0.0" asserts both keys
- `{:stream_data, "~> 1.4", only: :test}` locked at 1.4.0 (elixir ~> 1.14, so the 1.15 floor holds); `:crypto` added to `extra_applications`

## Task Commits

1. **Task 1: Flip bump-minor-pre-major and guard it with a contract test** - `28beadd9` (ci)
2. **Task 2: Add stream_data (test-only) and :crypto to mix.exs** - `c3f207a5` (chore)

## REL-01 Ordering Evidence

Pre-flight before Task 1: `git log --format='%h %s' main..HEAD` had 0 subjects matching `^(feat|fix|perf|deps)(\(...\))?!?:`, and no commit on main..HEAD touched release-please-config.json.

`git log --reverse --format='%h %s' main..HEAD -- release-please-config.json` (first line):

```
28beadd9 ci(release): propose minor bumps for breaking changes before 1.0
```

Full `git log --reverse --format='%h %s' main..HEAD` right after the ci(release) commit:

```
e2b3a980 docs: add milestone guide and the base-library ladder to 1.0.0
4117492c docs: start milestone v1.42 Capture Correctness for Real Table Shapes
9b8672a9 docs: complete v1.42 project research
f04de828 docs: define milestone v1.42 requirements
f33158a0 docs: create milestone v1.42 roadmap (6 phases)
ad6abfff docs(208): capture phase context
d0192be2 docs(state): record phase 208 context session
9e644eab docs(208): research phase domain
db0f1e10 docs(phase-208): add validation strategy
fd128c67 docs(208): create phase plan
28beadd9 ci(release): propose minor bumps for breaking changes before 1.0
```

Releasable-subject count at that point: 0. `git show --name-only 28beadd9` lists exactly release-please-config.json and test/threadline/changelog_contract_test.exs.

## Verification

- `mix test test/threadline/changelog_contract_test.exs --trace`: 8 tests, 0 failures; the new test name appears in the trace
- `mix compile --warnings-as-errors --force`: exit 0, no warnings
- `mix test test/threadline/dep_floor_guard_test.exs test/threadline/zero_skips_contract_test.exs`: 3 tests, 0 failures
- ExUnitProperties loads and `:crypto.hash(:sha256, "billing.invoices")` gives `9bba11019407`
- Plan-level: `mix test test/threadline/changelog_contract_test.exs test/threadline/dep_floor_guard_test.exs`: 9 tests, 0 failures

## Decisions Made
None beyond the plan. Commit types were `ci(release):` and `chore(test):`, both non-releasable.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- `mix deps.get` reports security advisories (EEF-CVE-2026-92106 LOW, EEF-CVE-2026-82672 MEDIUM) against existing locked deps listed as "Unchanged" (reported next to ex_aws_s3; they name lazy_html and Mint). They predate this plan and do not involve stream_data, so they are out of scope and were left alone.
- Dialyzer was not run. mix.exs changed, so the next `mix ci.all` needs `mix dialyzer --plt` first (expected PLT cache miss).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Later plans in phase 208 may now use `feat:`/`fix:` commit types (REL-01 is in effect on the branch).
- ExUnitProperties and `:crypto.hash/2` are available for the naming digest and property tests.
- Flagged assumption still open: on main the squash PR puts the config flip and the feat changes in one commit. release-please reads the config at main HEAD, so this is fine, but it can only be confirmed at the landing PR.

---
*Phase: 208-identifier-foundation*
*Completed: 2026-09-25*

## Self-Check: PASSED
- release-please-config.json, test/threadline/changelog_contract_test.exs, mix.exs, mix.lock: all present
- Commits 28beadd9 and c3f207a5 found in git log
