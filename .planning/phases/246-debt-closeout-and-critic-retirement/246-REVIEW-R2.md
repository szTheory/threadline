---
phase: 246-debt-closeout-and-critic-retirement
round: 2
reviewed: 2026-10-26T02:28:00Z
depth: standard
diff_base: d8b8422f
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/browser-full.yml
  - CONTRIBUTING.md
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - test/threadline/ci_coverage_doc_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 246: Code Review Report (Round 2, gap closure 246-08 / 246-09)

**Reviewed:** 2026-10-26T02:28:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

This round covers only the gap-closure hunks in `git diff d8b8422f..HEAD` on the six listed
files. `operator-page-capture.spec.ts` was read as the source of truth.

**Round-1 disposition**

- **R1 WR-01: resolved.** The prose in all three sources now matches what Browser-full runs.
  - Browser-full sets no `THREADLINE_E2E_EVIDENCE`. Nothing under `.github/` sets it, and
    `run-e2e.sh:19` defaults it to `0`.
  - Without evidence mode, the only test that runs is `renders every curated operator route at
    1280` (spec:425). It loops over `ROUTES` (6 entries) × `BREAKPOINTS = [1280]`.
  - The 1280/768/375 tests over `inventory.routes` (spec:376) and the degraded-twin evidence
    test (spec:409) skip outside evidence mode. `widths` is `[1280, 768, 375]` in
    `operator-browser-evidence.ts:13`.
  - The playwright.config comment no longer has scorecards and evidence mode backwards.
- **R1 IN-02: resolved.**
  - The job id `verify-example-browser-full` is unchanged.
  - The new `name:` is pinned by exact equality at `ci_workflow_parity_contract_test.exs:1114`.
  - No other live reference to `(all projects)` remains outside `.planning/`.
  - `bin/ci-sha-gate` keys on workflow file names, not job names, so the rename cannot break
    the nightly skip.

**New contract (`CiCoverageDocContractTest`)**

- It fails closed on the main vacuity paths:
  - A missing `const ROUTES … ];` block flunks.
  - Zero `{ id: "` entries flunks.
  - A missing or empty `BREAKPOINTS` list flunks.
- The digit lookbehind/lookahead correctly refuses `16 …`, `7 …` and `… at 1280/768`.
- The mutation controls exercise the false claims, a dropped phrase, a wrong count and a padded
  count.
- `mix test` on both changed contract files: 57 tests, 0 failures.

**verify-phase.sh**

- Adding `UI-HOME-SHOT-101` to `REQUIRED_IDS` is sound.
- The id exists in `246-DEBT-REGISTER.md:134`, and the register frontmatter totals match (24
  routed, 132 total).
- `gen_register` picks the id up automatically, and `--self-test` prints
  `verify-phase: all checks passed`.

**Residual problems**

- The derived phrase counts the degraded Timeline twin as a sixth "operator route", and the
  contract now locks that wording in.
- The false-claim denylist is narrow enough that the third WR-01 misstatement, or a close
  paraphrase of the first two, would pass next to the required phrase.

No BLOCKER found.

## Warnings

### WR-01: The derived phrase says "6 curated operator routes", but `ROUTES` holds 5 routes plus a degraded twin, and the contract now enforces the overcount

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:149-165`, `CONTRIBUTING.md:311`, `.github/workflows/browser-full.yml:6-7`, `examples/threadline_phoenix/e2e/playwright.config.ts:27`
**Issue:** `route_count/1` counts every `{ id: "` line in `const ROUTES`. Entry 2 is
`{ id: "route.timeline.degraded", path: "/audit/timeline", degrade: true }`. That is the same
route as entry 1, with `DEGRADE_CSS` injected (spec:90, spec:302-305). Browser-full renders 6
cells but only 5 distinct operator routes.

All three sources now tell readers "the 6 curated operator routes". Round 1 suggested "5 curated
operator routes plus a degraded Timeline twin" for this reason. CONTRIBUTING's coverage table is
the baseline Phase 247 measures from (the contract's own failure message says so), so it should
not overstate route breadth by one.

The derive also counts commented-out entries: a `// { id: "route.x", … }` line inside the array
still matches `~r/\{ id: "/`.

The wording cannot be corrected without changing the test, because the test demands the
overcounted phrase.
**Fix:** Count distinct, non-degraded, uncommented entries, and derive the twin separately:
```elixir
entries =
  body
  |> String.split("\n")
  |> Enum.reject(&String.match?(&1, ~r/^\s*\/\//))
  |> Enum.filter(&String.contains?(&1, "{ id: \""))

routes = Enum.count(entries, &(not String.contains?(&1, "degrade: true")))
twins = length(entries) - routes
# phrase: "#{routes} curated operator routes plus #{twins} degraded twin at #{bps}"
```
Then reword the three sources to "the 5 curated operator routes plus a degraded Timeline twin at
1280".

### WR-02: The false-claim denylist misses WR-01's third misstatement and trivial paraphrases; the positive phrase is matched anywhere in the file

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:57-58`, `:194-215`, `:217-223`
**Issue:** `@false_claims` refuses only two exact substrings, `"every inventoried route"` and
`"at three viewports"`.

Round-1 WR-01 named three misstatements. The third was the playwright.config claim that the
project drives the routes "at 1280/768/375 and, in evidence mode, writes the route scorecards",
which gets the modes backwards. That sentence contains neither denylisted string. If it were
re-added next to the new comment, all three checks would still pass. Paraphrases of the first two
also pass, for example "all inventoried routes", "across three viewports" and "every inventory
route at 1280/768/375".

The positive check is also weaker than the moduledoc claims (lines 27-32). The moduledoc says the
`browser-full.yml` header comment and the `playwright.config.ts` route-capture comment must state
the phrase. The test actually runs `prose/1` over the whole file (lines 217-223), so the phrase
anywhere in the file satisfies it. A contradictory route-capture comment survives as long as the
phrase appears in some other comment in the file.

The contract pins the presence of a correct sentence. It does not pin the absence of a wrong one,
and that absence is what WR-01 was about.
**Fix:**
- Scope the two file sources to the comment that describes coverage: the `#` header block before
  `name:` in browser-full.yml, and the comment block directly above
  `name: "route-capture"` in playwright.config.ts.
- Replace the substring denylist with patterns that also catch the inverted-mode claim:
```elixir
@false_claims [
  ~r/\b(every|all) inventor(y|ied) routes?\b/i,
  ~r/\bthree viewports\b/i,
  ~r/in evidence mode,? writes the route scorecards/i
]
```
- Add one mutation control per pattern. Make one of them a source whose required phrase sits in
  an unrelated comment while the scoped block is wrong.

## Info

### IN-01: The inventory widths in the prose are hand-written, not derived

**File:** `CONTRIBUTING.md:312`, `.github/workflows/browser-full.yml:7`, `examples/threadline_phoenix/e2e/playwright.config.ts:28`
**Issue:** The contract derives the curated count and `BREAKPOINTS` from the spec. The
evidence-mode widths `1280/768/375` in all three sources come from `widths` in
`support/operator-browser-evidence.ts:13`, and nothing checks them. If `widths` changes, the
prose drifts silently: the same class of drift WR-01 was about.
**Fix:** Parse `export const widths = [...]` from `operator-browser-evidence.ts`. Require
`inventory-wide #{Enum.join(widths, "/")}` in each source.

### IN-02: Missing negative controls for two of the four wording checks

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:241-272`
**Issue:** The mutation test never removes `only in evidence mode`, so nothing would show if that
branch were broken. It also never tries a wrong breakpoint suffix such as `… at 1280/768` or
`… at 12800`. The lookahead `(?!\d|\/\d)` handles both cases today, but no test pins that.
**Fix:** Add
`assert Enum.any?(coverage_wording_errors("control", String.replace(passing, @evidence_only, "in evidence mode"), phrase), &(&1 =~ "lacks `only"))`
and a `phrase <> "/768"` control that must report `lacks the spec`.

### IN-03: The "non-vacuous" test is partly redundant

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:231-237`
**Issue:** `route_count/1` already flunks on 0 and `breakpoints/1` already flunks on an empty
list, so `assert route_count(spec) > 0` and `refute curated_phrase() =~ ~r/^0 /` can never be the
assertion that fails. The test is harmless, but it reads as stronger than it is.
**Fix:** Either drop it, or replace it with a synthetic-spec control. Feed `route_count/1` and
`breakpoints/1` a string with an empty `ROUTES` and a missing `BREAKPOINTS`, and assert they
flunk (`assert_raise ExUnit.AssertionError`). That proves the fail-closed path rather than
restating it.

### IN-04: The `REQUIRED_IDS` pin checks that `UI-HOME-SHOT-101` is present, not that it is routed to SEED-008

**File:** `.planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh:90`
**Issue:** The coverage check requires the id to appear in the register. Per 246-09-PLAN, the
row's whole point is that it is `routed` to SEED-008. Flipping the row to `closed` with any
reason keeps `--close` green, as long as the frontmatter counts are edited to match.
**Fix:** If disposition matters, add a targeted assertion. For example, grep the register for
`` `UI-HOME-SHOT-101` `` and require `| routed | SEED-008` on that row, with a self-test mutation
that flips it.

---

_Reviewed: 2026-10-26T02:28:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
