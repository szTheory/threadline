---
phase: 246-debt-closeout-and-critic-retirement
round: 3
reviewed: 2026-10-26T03:30:00Z
depth: standard
diff_base: b531d65d
files_reviewed: 4
files_reviewed_list:
  - .github/workflows/browser-full.yml
  - CONTRIBUTING.md
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - test/threadline/ci_coverage_doc_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 246: Code Review Report (Round 3, removal slice C8)

**Reviewed:** 2026-10-26T03:30:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

This round covers only `git diff b531d65d..e9a97139` on the four listed files.
`operator-page-capture.spec.ts` and `operator-surface-paths.ts` were read as the source of truth.
`mix test test/threadline/ci_coverage_doc_contract_test.exs` passes: 7 tests, 0 failures.

**Ground truth: what each mode runs and who writes `route-scorecards/`**

- `const ROUTES` (spec:88-95) has 6 entries. Five are distinct paths. The sixth,
  `route.timeline.degraded`, is `/audit/timeline` again with `degrade: true`.
- `const BREAKPOINTS = [1280]` (spec:35).
- Outside evidence mode, the only test that runs is `renders every curated operator route at
  1280` (spec:425-440). It calls `captureCell` for every `ROUTES` entry.
  - `captureCell` ends in `writeJson(scorecardPath(id), …)` (spec:371).
  - `scorecardPath` resolves under `paths.routeScorecardsDir`, which is
    `<repo-root>/test/generated/operator_surface/route-scorecards` by default
    (`operator-surface-paths.ts:75-79`).
  - This test skips itself in evidence mode (spec:430).
- In evidence mode (`THREADLINE_E2E_EVIDENCE=1`):
  - The inventory tests (spec:376-407) write `${id}-scorecard.json` under `runRoot()`
    (spec:401), one per width.
  - The degraded-twin test (spec:409-418) writes no scorecard.
- Browser-full never sets `THREADLINE_E2E_EVIDENCE`, and `run-e2e.sh:19` defaults it to `0`.

So the curated smoke that Browser-full runs is the only writer of `route-scorecards/`, and
evidence mode writes per-width scorecards under its run root. The new playwright.config.ts
comment (lines 27-30) says exactly this. Before C8, it said the route scorecards "run only in
evidence mode", which had the modes backwards.

**Do any docs still contradict the code?** No.

- The `browser-full.yml` header (lines 6-8) and `CONTRIBUTING.md` (lines 311-315) both say "5
  curated operator routes plus a degraded Timeline twin at 1280". Neither mentions scorecards.
- The playwright.config.ts comment is accurate, as described above.
- The spec's own header (spec:17-19) is accurate too.
- I found no other live text outside `.planning/` that makes a claim about scorecard mode.

**R2-WR-01 (overcount): resolved.**

- `curated_routes/1` drops `//` lines and splits the entries on `degrade: true`.
- `curated_phrase/1` gives "5 curated operator routes plus a degraded Timeline twin at 1280".
- All three sources state that phrase, so the sixth "route" is gone.
- Shapes the template cannot state honestly now fail the test instead of passing silently,
  each covered by a synthetic control:
  - two twins
  - a twin whose path matches no curated route
  - zero curated routes
  - empty widths
- One leftover: the count is of entries, not distinct paths (R3-IN-02).

**R2-WR-02 (narrow denylist, unscoped positive check): resolved as R2 specified, with
residual gaps.** All three R2 fix bullets are in place:

- The two file sources are scoped to the browser-full.yml header block and the `//` block
  directly above `name: "route-capture"`.
- A control proves that the phrase in an unrelated comment no longer satisfies the check.
- The substring list became four regexes. Each has a mutation control asserting that its
  sample trips that pattern and only that one.
- The exact round-1 sentence ("in evidence mode, writes the route scorecards") and the
  pre-C8 inversion ("scorecards run only in evidence mode") are both refused.

Two gaps remain:

- Applying the scoping to the denylist as well as to the positive check removed false-claim
  coverage from the rest of each file (R3-WR-01).
- The "both inversions" guarantee falls to one-word paraphrases (R3-WR-02).

No BLOCKER found.

## Warnings

### R3-WR-01: Scoping the sources also scoped the denylist, so a false claim elsewhere in browser-full.yml or playwright.config.ts is no longer refused

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:255-283`, `:288-324`
**Issue:**

- `coverage_sources/0` now returns only the scoped text: the `#` lines before `^name:` in
  browser-full.yml, and the `//` block above `name: "route-capture"`.
- `coverage_wording_errors/3` runs both the positive phrase check and the `@false_claims`
  denylist over that same text.

R2-WR-02 asked for scoping so that a correct phrase *elsewhere* could not launder a wrong
coverage comment. That argument applies to the positive check only. Before C8, the denylist
ran over the whole file. Now it never sees, for example:

- the step comment at browser-full.yml:137-145, or anything after line 28
- any playwright.config.ts comment outside the route-capture block

A sentence such as "# route-capture renders every inventoried route at three viewports" added
above the `Run Playwright` step now passes all three checks. Before this commit it went red.
Net effect: the laundering hole is closed, but a new non-detection hole is open, on the very
claims WR-01 was about.
**Fix:** Check the positive phrase against the scoped text and the denylist against the whole
file:
```elixir
defp coverage_sources do
  [
    {"CONTRIBUTING.md ## CI Coverage", coverage_section(), coverage_section()},
    {"browser-full.yml", scoped_source(:browser_full, File.read!(@browser_full_workflow)),
     File.read!(@browser_full_workflow)},
    {"playwright.config.ts", scoped_source(:playwright, File.read!(@playwright_config)),
     File.read!(@playwright_config)}
  ]
end
# coverage_wording_errors(label, scoped, whole, phrase): `missing` from prose(scoped),
# `false_claims` from prose(whole)
```
Add a control in which the scoped block is correct and a denylisted sentence sits elsewhere
in the file, and assert that it goes red.

### R3-WR-02: The "both inversions of which mode writes the route scorecards" guarantee is a two-sentence literal; one-word paraphrases pass, and nothing positively pins scorecard ownership

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:31-38`, `:62-74`
**Issue:** The moduledoc (lines 37-38) and the attribute comment (lines 62-65) claim the
denylist works "as patterns so a paraphrase cannot slip past" and refuses "both inversions".
I checked the four patterns with `Regex.match?` against these inverted or false sentences.
None of them matches:

| Sentence | Patterns matched |
|---|---|
| `In evidence mode it writes the route scorecards.` | none |
| `Evidence mode writes the route scorecards.` | none |
| `in evidence mode, writes their route scorecards` | none (the comment itself uses "their") |
| `The route scorecards are written only in evidence mode.` | none |
| `It renders every route in the inventory.` | none |
| `It renders at 1280, 768 and 375.` | none |
| `the 6 curated operator routes at 1280` (the R2-WR-01 overcount) | none |

The positive check requires only the route phrase and `only in evidence mode`. It says
nothing about which mode writes `route-scorecards/`. The scorecard-mode truth, the exact fact
WR-01 got wrong twice, is therefore guarded only by literals that a rewording defeats. The
docstring overstates the guarantee.
**Fix:** Take one of these two approaches.

- **Positive pin.** Pin the true statement positively in the playwright.config.ts scoped
  block. Require a derived sentence such as `writes their route scorecards to
  route-scorecards/`, with the directory name taken from `operator-surface-paths.ts:79`.
  Then widen the inversion patterns to tolerate filler words:
  `~r/evidence mode\b[^.]{0,40}\bwrites?\b[^.]{0,20}\broute scorecards/i` and
  `~r/route scorecards\b[^.]{0,40}\bonly in evidence mode/i`. Also add
  `~r/(?<!\d)#{count + 1} curated operator routes/` to refuse the old overcount.
- **Narrower docstring.** Narrow the moduledoc and attribute comment to say what is actually
  guaranteed: "refuses these specific sentences".

## Info

### R3-IN-01: The non-vacuity test hard-pins the derived values, so "derived, never hand-written" needs a second hand edit

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:357-361`
**Issue:** `assert length(routes) == 5`, `twin_label(twin) == "Timeline"` and
`breakpoints(spec) == "1280"` pin today's spec. Adding a route turns this test red as well as
the prose check. The comment at lines 162-166 says the derive exists so that a route change
needs only a doc edit. This is acceptable as a tripwire, but the two claims disagree.
**Fix:** Assert the shape instead: `length(routes) > 0`, `length(twins) <= 1`,
`Enum.all?(twins, &(&1 in routes))`. Or add a comment saying the pin is intentional.

### R3-IN-02: "distinct curated routes" is not what the code counts

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:32`, `:170`
**Issue:**

- The moduledoc says the phrase "counts the distinct curated routes".
- `count = length(routes)` counts non-degraded *entries*. Two non-degraded entries with the
  same path, for example a second `/audit/timeline` capture under another id, would be
  counted twice.
- The twin test also relies on a literal substring: `degrade: true` (line 214). A
  `degrade:true` or multi-space variant would be counted as a curated route, which brings
  back the R2-WR-01 overcount without anything failing.

**Fix:** `count = routes |> Enum.uniq() |> length()`. Detect the flag with
`~r/\bdegrade:\s*true\b/`, and flunk on any other `degrade:` value.

### R3-IN-03: The playwright.config.ts comment line 29 is 126 columns, unwrapped

**File:** `examples/threadline_phoenix/e2e/playwright.config.ts:29`
**Issue:** Every other comment line in the file wraps near 80 columns. Line 29 runs two
sentences onto one 126-column line, which is clearly an editing leftover. It has no
functional effect, because `prose/1` joins lines before matching.
**Fix:** Rewrap after "that is what Browser-full runs."

### R3-IN-04: The inventory-route denylist pattern also refuses a true statement

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:69`
**Issue:** `~r/\b(every|all) inventor(y|ied) routes?\b/i` takes no account of mode. The
accurate sentence "in evidence mode it expands to every inventoried route" (the spec's own
header, spec:18-19) would be refused if it appeared in a scoped source. The scoped comments
are therefore forbidden from describing evidence mode in the spec's own words. Today's
wording avoids the phrase, so nothing fails.
**Fix:** Anchor the pattern to the Browser-full or non-evidence context, for example refuse
it only when no `evidence mode` appears within the same sentence. Or document the
restriction in the attribute comment.

---

_Reviewed: 2026-10-26T03:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
