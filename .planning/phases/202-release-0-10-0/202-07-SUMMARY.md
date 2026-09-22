---
phase: 202-release-0-10-0
plan: 07
subsystem: docs
tags: [exdoc, changelog, release-gate, autolink]

requires:
  - phase: 202-03
    provides: the 0.10.0 changelog entry whose module inventory triggers the autolink warnings
provides:
  - "`mix docs --warnings-as-errors` exits 0 with an empty warning inventory (was 60 lines)"
  - "Measured before/after warning inventory, diffed rather than eyeballed"
  - "House style for release notes that document a module going private: de-linkify at the reference site"
affects: [202-09, release-0.10.0]

actuals:
  tokens: 2300
  tasks: 2
  commits: 4
plan_head_before: 98692abf

tech-stack:
  added: []
  patterns:
    - "Release notes naming now-private modules write them as plain text, not code spans — ExDoc resolves code spans and warns on hidden targets"
    - "Callback references in extras files are module-qualified (`c:Mod.fun/arity`); an unqualified `c:fun/arity` has no module context and cannot resolve"

key-files:
  created: []
  modified:
    - CHANGELOG.md
    - CONTRIBUTING.md
    - guides/upgrade-path.md

key-decisions:
  - "Option B — de-linkify at the reference site; `mix.exs` untouched, no `skip_code_autolink_to` allowlist"
  - "`c:put/2` QUALIFIED to `c:Threadline.Storage.put/2`, not exempted — the callback is real and public, so qualification both resolves the reference and makes the upgrade note link to the callback adopters must change"
  - "`skip_undefined_reference_warnings_on` explicitly rejected — a per-file blanket mute would silence every future genuinely-broken reference in a 660-line guide"

patterns-established:
  - "Warning gates are closed by diffing a captured before-inventory against an after-inventory, not by reading the tail of a build log"

requirements-completed: []

coverage:
  - id: D1
    description: "`mix docs --warnings-as-errors` exits 0 with zero `warning:` lines, in both html and epub"
    requirement: RELEASE-01
    verification:
      - kind: other
        ref: "mix docs --warnings-as-errors (exit 0; sorted warning inventory diffed 60 -> 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The 0.10.0 changelog entry still names all 25 now-private modules"
    verification:
      - kind: other
        ref: "awk 'NR>=97 && NR<=115' CHANGELOG.md | grep -o 'Threadline\\.[A-Za-z0-9_.]*' | sort -u | wc -l => 25"
        status: pass
    human_judgment: false
  - id: D3
    description: "No module's `@moduledoc false` status changed — the Phase 200 privacy decision is untouched"
    verification:
      - kind: other
        ref: "git diff --name-only -- lib/ => empty"
        status: pass
    human_judgment: false
  - id: D4
    description: "The documentation contract tests still pass after the prose edits"
    verification:
      - kind: integration
        ref: "mix verify.doc_contract (134 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D5
    description: "`mix verify.release` reaches and passes its documentation step"
    verification:
      - kind: other
        ref: "mix verify.release halts at its pre-step ensure_clean_tree!; all four of its steps run individually, each exit 0"
        status: pass
    human_judgment: true
    rationale: "The end-to-end `mix verify.release` invocation could not run to completion in this working tree — its `ensure_clean_tree!` pre-step is tripped by two pre-existing uncommitted `.planning/` files this plan is forbidden to commit. Each of the four steps it would run was executed individually and passed. A maintainer with a clean tree should confirm the single end-to-end invocation."

duration: 18 min
completed: 2026-09-22
status: complete
---

# Phase 202 Plan 07: ExDoc warning gate Summary

**Born-red cause BR-4 closed: `mix docs --warnings-as-errors` went from 60 warning lines / exit 1 to an empty inventory / exit 0, by de-linkifying four classes of unresolvable reference at the reference site — with `mix.exs` untouched, the 0.10.0 changelog entry intact, and no module's privacy changed.**

## Performance

- **Duration:** 18 min (Task 2; Task 1 ran in a prior session)
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- `mix docs --warnings-as-errors` exits 0. The sorted warning inventory, captured to a scratch file before the change and re-captured after, went **60 lines -> 0 lines**; the diff is `1,60d0` (every baseline line deleted, nothing added).
- All **25** module names survive in the 0.10.0 entry, verbatim and readable.
- Nothing under `lib/` was touched and `mix.exs` was not modified.

## Task 1 — measured warning inventory (carried forward)

`mix docs --warnings-as-errors` at `98692abf`: **exit 1, exactly 60 `warning:` lines**, in
**three** distinct classes (the plan anticipated two).

| # | Class | Lines | Source | Authored by |
|---|-------|-------|--------|-------------|
| 1 | `references module "X" but it is hidden` — 25 distinct `Threadline.*` modules × 2 formats (html + epub) | 50 | `CHANGELOG.md:97–115` (the 0.10.0 inventory) | Plan 202-03 (`291d061a`) |
| 2 | `references callback "c:put/2" but it is undefined` — 3 sites × 2 formats | 6 | `CHANGELOG.md:56`, `CHANGELOG.md:123`, `guides/upgrade-path.md:112` | Plan 202-03 (`291d061a`, `c35cb0dc`) |
| 3a | `references module "mix release.pins" but it is hidden` × 2 formats | 2 | `CONTRIBUTING.md:661` | Phase 202 (`43c64458`) |
| 3b | `references file "bin/verify-environment-protection" but it does not exist` × 2 formats | 2 | `CONTRIBUTING.md:649` | Phase 202 (`d4eddcbf`) |

### Corrections to the plan's stated measurements

1. **25 modules, not 26.** The 0.10.0 inventory names 25 modules, and the entry's own prose at
   `CHANGELOG.md:62` says "25 implementation modules". The 26th module-shaped warning was
   `mix release.pins`, from `CONTRIBUTING.md` — a different file and a different cause. The plan
   and its acceptance criteria were corrected to 25 before Task 2 ran.
2. **The `c:put/2` references are NOT pre-existing.** `git blame` puts all three on Phase 202
   commits from 2026-09-22 (`291d061a`, `c35cb0dc`). Both `CHANGELOG.md` references sit *inside*
   the 0.10.0 entry (which spans lines 29–125), not in older entries.
3. **`c:put/2` warns "undefined", not "hidden".** `Threadline.Storage` is public and does define
   `@callback put(content(), options())` at `lib/threadline/storage.ex:53`. The reference failed
   only because an unqualified `c:put/2` inside an extras file has no module context.
4. **A third warning class the plan did not anticipate:** `bin/verify-environment-protection`.
   The file *does* exist in the repo; the markdown link at `CONTRIBUTING.md:649` is repo-relative
   and `bin/` is not published into the doc output.

## Task 1 — decision (recorded)

**Option B — de-linkify at the reference site. `mix.exs` is not modified.**

Rationale, and why Option A was not merely unpreferred but *incomplete*: ExDoc's
`url(string = "mix " <> name, mode, config)` clause at
`deps/ex_doc/lib/ex_doc/autolink.ex:191` matches **before** the generic
`url(string, mode, config)` clause at line 195 that consults
`config.skip_code_autolink_to`. A `mix release.pins` reference therefore never reaches the skip
list, so `skip_code_autolink_to` structurally cannot suppress class 3a. Option B was required
regardless; applying both would have been the blended approach the plan's action text forbids.

`c:put/2` was **qualified, not exempted** — the callback is real and public, and qualification
makes the upgrade note link to the exact callback adopters must change.

`skip_undefined_reference_warnings_on` was considered and **explicitly rejected**. It would have
resolved the two `CONTRIBUTING.md` classes, but it is a per-file blanket mute that would silence
every future genuinely-broken reference in a 660-line contributor guide.

The decision is reversible: flip to Option A if many more modules go private and monospace
rendering of the inventory starts to matter.

## Task 2 — what was applied

| Class | Site | Change |
|---|---|---|
| 1 | `CHANGELOG.md:97–115` | Backticks dropped from the 25 module names. Names remain, plain text. |
| 2 | `CHANGELOG.md:56`, `guides/upgrade-path.md:112` | `` `c:put/2` `` -> `` `c:Threadline.Storage.put/2` `` |
| 2 | `CHANGELOG.md:123` | `` - **`Threadline.Storage` `c:put/2`** `` -> `` - **`c:Threadline.Storage.put/2`** `` (qualified; the now-redundant bare module name dropped from the bold lead-in) |
| 3a | `CONTRIBUTING.md:661` | `` `mix release.pins` `` -> `mix release.pins` (table Owner cell) |
| 3b | `CONTRIBUTING.md:649` | ``[`bin/verify-environment-protection`](bin/verify-environment-protection)`` -> `` `bin/verify-environment-protection` `` (link unwrapped, code span kept) |

### Before/after warning inventory

```
BEFORE: 60 lines, 28 distinct, exit 1
AFTER:   0 lines,  0 distinct, exit 0
diff warn-before.txt warn-after.txt  =>  1,60d0
```

No warning survived, so no second mechanism was added.

Both output formats are clean. Each warning appeared exactly twice in the baseline because ExDoc
warns separately per format; the passing run generates html, markdown (`llms.txt`), and epub.

### Verification results

| Command | Result |
|---|---|
| `mix docs --warnings-as-errors` | **exit 0**, zero `warning:` lines |
| `mix verify.doc_contract` | **exit 0** — 134 tests, 0 failures |
| `bin/verify-release-shape` | exit 0 — "Release shape OK for version 0.9.0" |
| `mix test …release_artifact_contract_test.exs …ci_topology_contract_test.exs` | exit 0 — 36 tests, 0 failures |
| `MIX_ENV=dev mix docs --warnings-as-errors` | exit 0 |
| `mix hex.build` | exit 0 — `threadline-0.9.0.tar` (gitignored) |
| Module count in the 0.10.0 inventory | **25** |
| `git diff --name-only -- lib/` | empty |

### Which step `mix verify.release` reached

**It did not reach any of its four steps.** It halts at its pre-step `ensure_clean_tree!`
(`mix.exs:381`), which runs `git diff --quiet HEAD --` before the step list. The working tree
carries two **pre-existing** modifications this plan is forbidden to commit —
`.planning/WINDOWS.md` and `.planning/config.json` — so the gate can never pass here.

This is an environmental blocker, not a failure attributable to this plan, and it is not at or
before `mix docs`: it is before the step list entirely, and was equally true at `98692abf`
before any change in this plan. To prove the documentation step regardless, all four steps
`verify_release/1` would run were executed individually and **each exited 0** (table above).
`mix docs --warnings-as-errors` — the step this plan exists to unblock — is proven green.

## Task Commits

1. **Task 1: record the measured inventory** - `a1933884` (docs)
2. **Task 1: correct the module count to 25 and record the decision** - `4cfb2dbb` (docs)
3. **Task 2: de-linkify hidden doc references** - `2f731387` (fix)

Plan-scoped context commit: `3bcd5159` (docs — shifted the born-red defect class left).

## Files Created/Modified

- `CHANGELOG.md` — 25 module names de-linkified; 2 callback references qualified
- `guides/upgrade-path.md` — 1 callback reference qualified
- `CONTRIBUTING.md` — `mix release.pins` de-linkified; `bin/verify-environment-protection` link unwrapped

## Decisions Made

See "Task 1 — decision (recorded)" above. Three decisions, all documentation-only and reversible.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The plan's file list omitted two of the four files that had to change**

- **Found during:** Task 2
- **Issue:** The plan's `files_modified` frontmatter and Task 2's `<files>` named `mix.exs, CHANGELOG.md`. `mix.exs` did not need to change at all under the chosen option, and two of the four warning classes live in `CONTRIBUTING.md` and `guides/upgrade-path.md`, which were not listed. Restricting edits to the listed files would have left 10 of 60 warning lines standing and the gate red.
- **Fix:** Edited `CHANGELOG.md`, `CONTRIBUTING.md`, and `guides/upgrade-path.md`. `mix.exs` left untouched, per the Option B prohibition.
- **Verification:** Warning inventory 60 -> 0; `git diff --stat` shows exactly those three files.
- **Committed in:** `2f731387`

**2. [Rule 1 - Bug] `CHANGELOG.md:123` would have read redundantly under a literal qualification**

- **Found during:** Task 2
- **Issue:** A literal substitution would have produced ``- **`Threadline.Storage` `c:Threadline.Storage.put/2`**`` — the module named twice in one bold lead-in, in a published changelog.
- **Fix:** Collapsed the lead-in to ``- **`c:Threadline.Storage.put/2`**``. The module is still named; only the duplicate was removed. The two other sites (`CHANGELOG.md:56`, `guides/upgrade-path.md:112`) read naturally with the plain substitution and were left as such.
- **Verification:** `mix verify.doc_contract` passes; no test asserts on that line.
- **Committed in:** `2f731387`

**3. [Bookkeeping] The Task 1 precondition was satisfied by the plan, not the SUMMARY**

- **Found during:** Task 2 precondition check
- **Issue:** Task 2's `<precondition>` requires Task 1's decision be recorded *in the SUMMARY*. At the start of Task 2 the SUMMARY still read `status: halted` / "decision pending"; the decision had been recorded in the PLAN frontmatter's `must_haves.decision_recorded` block (commit `4cfb2dbb`) instead.
- **Fix:** Treated the precondition as met — the decision was recorded in a committed planning artifact and restated verbatim in the dispatching instruction, so nothing was inferred. This SUMMARY now carries the decision, closing the gap for any re-read.
- **Verification:** The applied change matches the recorded decision exactly (Option B, `mix.exs` untouched, `c:put/2` qualified rather than exempted).

---

**Total deviations:** 3 (1 blocking, 1 bug, 1 bookkeeping)
**Impact on plan:** No scope creep. Deviation 1 was required for the plan's own acceptance criterion to be reachable; the corrected file set is strictly documentation.

## Issues Encountered

- **`mix verify.release` cannot run end-to-end in this working tree.** Its `ensure_clean_tree!`
  pre-step is tripped by two pre-existing uncommitted `.planning/` files that are out of scope.
  Worked around by running its four steps individually. A maintainer with a clean tree should
  run the single end-to-end invocation before tagging. Note that `mix hex.build` and
  `bin/verify-release-shape` still report **0.9.0** — the version bump to 0.10.0 is owned by
  Release Please, not by this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- BR-4 is closed: the documentation gate no longer blocks `mix verify.release`.
- `mix verify.release` may still fail later at its contract-test step until plan **202-09** lands.
  That is expected and out of scope here.
- **RELEASE-01 is deliberately NOT marked complete.** 0.10.0 is not published and sibling plans
  in this phase still declare the requirement.

## Self-Check: PASSED

- `CHANGELOG.md`, `CONTRIBUTING.md`, `guides/upgrade-path.md` all exist on disk and carry the changes.
- Commit `2f731387` exists in `git log`.
- All Task 2 `<acceptance_criteria>` re-run and passing: empty diffed warning inventory; 25 modules named; no `lib/` file touched; only Option B applied (`mix.exs` unmodified).

---
*Phase: 202-release-0-10-0*
*Completed: 2026-09-22*
