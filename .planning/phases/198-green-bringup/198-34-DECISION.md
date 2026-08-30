# 198-34 Decision: Export status copy contract canonicalization (CR-01)

**Status:** AWAITING MAINTAINER DECISION
**Blocking task:** 198-34 Task 1 (`checkpoint:decision`, `gate="blocking-human"`)

## The problem

`lib/threadline/operator_surface/live/export_status_live.ex:476-493` holds a private `defp
export_job_status_label/1` that is the **only thing rendered** at line 308:

```elixir
<span class="tl-hint" role="status"><%= export_job_status_label(job) %></span>
```

`lib/threadline/operator_surface/presentation.ex:326-347` holds a public, spec-tested
`Presentation.export_action_label/2`, pinned by `test/threadline/operator_surface/presentation_test.exs`
since Phase 137, that is **called from nowhere in `lib/`** — only from its own test file.

The two diverge on 3 of 5 branches:

| readiness | `Presentation.export_action_label/2` (`presentation.ex:326-347`) | rendered `export_job_status_label/1` (`export_status_live.ex:476-493`) |
|---|---|---|
| `:preparing` | `"Preparing download"` | `"Queued"` / `"Processing"` |
| `:needs_attention` | `"Reopen source search"` | `"Failed"` |
| `:unavailable` + expired | `"Export expired"` | `"Export expired"` ✓ |
| `:unavailable` + missing file | `"File unavailable"` | `"File unavailable"` ✓ |

The private copy also uses a bare `to_string/1` (`export_status_live.ex:477`) instead of the
canonical `normalize_status/1` path (`presentation.ex:513-516`), and hardcodes
`DateTime.utc_now()` (`export_status_live.ex:481`) instead of honouring the `:now` option that
`Presentation.expired?/2` already supports (`presentation.ex:506-509`). It cannot be tested at a
frozen clock.

Round 4's fix changed one string literal (`"Expired"` → `"Export expired"`) and left the
duplicate-function mechanism live. This is the exact drift condition — two independently
maintained copies of one copy contract — that produced that original defect, and nothing
currently prevents the next one.

**Why this is not the executor's call.** The rendered strings are product-visible copy, locked
by the Phase-186 contract test (`test/threadline/operator_surface/copy_contract_test.exs:443-463`,
which explicitly names `["Queued", "Processing", "Failed", "Export expired", "File unavailable"]`
as "non-ready status text") and asserted by e2e specs. There is also a real semantic question:
`export_action_label/2` returns *action*-shaped text (`"Reopen source search"`), while the
rendered element is `role="status"`. Two directions are defensible; the difference is a product
decision, not an implementation detail.

## Evidence gathered (read_first)

- `lib/threadline/operator_surface/live/export_status_live.ex:308` — the render site:
  `<span class="tl-hint" role="status"><%= export_job_status_label(job) %></span>`
- `lib/threadline/operator_surface/live/export_status_live.ex:476-493` — the private duplicate,
  `to_string/1` normalization, hardcoded `DateTime.utc_now()`
- `lib/threadline/operator_surface/presentation.ex:326-347` — `export_action_label/2`, already
  `:now`-aware via `opts` (delegates to `expired?/2` at `presentation.ex:506-509`) and already
  routed through `normalize_status/1` (`presentation.ex:513-516`)
- `test/threadline/operator_surface/presentation_test.exs:74` (Phase-137 anchor) — pins
  `Presentation.export_action_label(job, now: @now) == "Reopen source search"` for
  `:needs_attention`, and equivalent assertions for `:preparing` / `:unavailable` branches
  nearby (lines ~65-88)
- `test/threadline/operator_surface/copy_contract_test.exs:443-463` — the Phase-186 lock; its
  helper `export_job_status_label_block/1` (`copy_contract_test.exs:553-558`) greps source
  text between `defp export_job_status_label` and `defp download_link_attrs`, i.e. it is
  anchored to the **private duplicate's source location**, not to `Presentation`
- e2e call sites (`grep -rn "Queued\|Processing\|"Failed"\|Reopen source search" examples/threadline_phoenix/e2e/tests/`):
  - `operator-screenshots.spec.ts:190-191` — `getByText("Failed")`, `getByText("Queued")`
  - `operator-prove-mobile.spec.ts:57` — `getByText(/Queued|Processing/)`
  - `operator-prove-mobile.spec.ts:112` — `failedRow` `toContainText("Failed")`
  - `operator-features.spec.ts:146-147` — `getByText("Failed")`, `getByText("Queued")`
  - `operator-accessibility.spec.ts:608` — `getByText(/Queued|Processing/)`

  Note: `"Reopen source search"` also appears as a `getByRole("link", ...)` assertion in
  `operator-prove-mobile.spec.ts:59` and `operator-accessibility.spec.ts:602`, but that link is
  an **unrelated, always-present UI element** — the "Source Timeline search" reopen link at
  `export_status_live.ex:341` — not the export status label. It coincidentally shares text with
  `export_action_label/2`'s `:needs_attention` string but is not part of this contract. Neither
  option below touches those two assertions.

## Option A — adopt the canonical action vocabulary

Delete the private `export_job_status_label/1`. Render `Presentation.export_action_label/2` at
`export_status_live.ex:308` instead.

**Files that must change:**
- `lib/threadline/operator_surface/live/export_status_live.ex` — delete `defp
  export_job_status_label/1` (lines 476-493), change render site line 308 to call
  `Presentation.export_action_label(job)`
- `test/threadline/operator_surface/copy_contract_test.exs` — re-anchor
  `export_job_status_label_block/1` (or its equivalent) to grep `presentation.ex`'s
  `export_action_label/2` instead of the deleted private function; update the five-literal
  loop to `["Preparing download", "Reopen source search", "Failed"?, "Export expired", "File
  unavailable"]` — **note the `:needs_attention` branch has no `"Failed"` under this option**,
  only `"Reopen source search"`, so the loop's literal set actually shrinks/changes shape, not
  just its values
- `test/threadline/operator_surface/live/export_status_live_test.exs` — update expectations for
  `:preparing` and `:needs_attention` branches to `"Preparing download"` / `"Reopen source
  search"`
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts:190-191` — `"Failed"` →
  (needs new locator; `"Reopen source search"` collides with the unrelated link, so the spec
  needs a scoped locator, not a bare text match), `"Queued"` → `"Preparing download"`
- `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts:57` — `/Queued|Processing/`
  → `/Preparing download/`; line 112's `failedRow` `"Failed"` assertion needs the same scoped-
  locator treatment as above
- `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts:146-147` — same as
  operator-screenshots
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts:608` — `/Queued|Processing/`
  → `/Preparing download/`

**User-visible strings that change:**
- `:preparing` branch: `"Queued"` and `"Processing"` (two distinct pending/running states) both
  collapse to a single `"Preparing download"` string — loses the pending-vs-running distinction
  the operator currently sees
- `:needs_attention` branch: `"Failed"` → `"Reopen source search"` — loses the plain-language
  failure state entirely; the operator now sees action text with no status word, and this new
  text is **ambiguous with the pre-existing, unrelated "Reopen source search" link** at
  `export_status_live.ex:341`, which will now appear twice on a failed job's row with the same
  text but different roles (`role="status"` span vs. an `<a>` link)

**Newly-failing measured-CI-facing tests if not reconciled in this diff:** all four e2e specs
listed above, plus `copy_contract_test.exs`'s Phase-186 lock (source anchor changes shape, not
just target).

## Option B — promote the rendered status vocabulary into `Presentation`

Add a new public `Presentation.export_status_label/2`, `:now`-aware and routed through
`normalize_status/1`, carrying exactly the vocabulary the private duplicate currently renders
(`"Queued"`, `"Processing"`, `"Failed"`, `"Export expired"`, `"File unavailable"`). Delete the
private duplicate. Render the new function at `export_status_live.ex:308`. Re-point the
Phase-186 lock at the new canonical location.

**Files that must change:**
- `lib/threadline/operator_surface/presentation.ex` — add `export_status_label/2` near
  `export_action_label/2` (~line 347), `:now`-aware (reuse `expired?/2`), routed through
  `normalize_status/1`
- `lib/threadline/operator_surface/live/export_status_live.ex` — delete `defp
  export_job_status_label/1` (lines 476-493), change render site line 308 to call
  `Presentation.export_status_label(job)`
- `test/threadline/operator_surface/presentation_test.exs` — add spec tests for the new
  function covering all 5 branches plus the frozen-clock expiry boundary, nil-`expires_at`
  fallback, nil/unrecognised-status fallback, and atom/string parity (this plan's `must_haves`)
- `test/threadline/operator_surface/copy_contract_test.exs` — re-anchor
  `export_job_status_label_block/1` to grep `presentation.ex`'s `export_status_label/2` instead
  of the deleted private function; the five-literal loop is unchanged in content
  (`["Queued", "Processing", "Failed", "Export expired", "File unavailable"]`), only its anchor
  moves
- `test/threadline/operator_surface/live/export_status_live_test.exs` — expectations are
  unchanged in value (still `"Queued"` / `"Processing"` / `"Failed"` / etc.), only the code path
  producing them moves to `Presentation`
- e2e specs — **no change expected** (see below); this plan's Task 3 must re-verify against
  live source rather than assume

**This option must also settle `export_action_label/2`'s fate** (it stays uncalled either way
unless wired somewhere):
- **Wire it:** no current UI surface needs action-shaped copy for export jobs — the only
  candidate render site is the one Option B just gave a status-shaped function. Wiring it
  elsewhere is out of this plan's scope (`files_modified` does not include a new call site).
- **Delete it, with its Phase-137 test:** removes the uncalled function and its spec, but the
  Phase-137 test (`presentation_test.exs:74` et al.) is the independent anchor that made round
  4's fix direction trustworthy per this plan's `must_haves` — deleting it is not free ("Do not
  delete the Phase-137 assertions... they must remain untouched-in-meaning").
- **Retain with reason:** keep `export_action_label/2` and its Phase-137 test as a spec-tested,
  currently-uncalled function, explicitly documented as reserved action-shaped copy for a future
  surface (e.g. a bulk-action toolbar, a notification, or an API response) that has not been
  built yet. This is the only disposition consistent with the plan's constraint to keep the
  Phase-137 anchor "untouched-in-meaning."

**User-visible strings that change:** none. Byte-identical to current rendered output.

**Newly-failing measured-CI-facing tests if not reconciled:** `copy_contract_test.exs`'s
Phase-186 lock (source anchor moves from `export_status_live.ex` to `presentation.ex`) —
mechanical, not a content change. E2E specs are expected to need **no changes**; Task 3 confirms
this by re-deriving the grep against live source rather than trusting this expectation.

## Reversibility

Option A changes product-visible copy that a Phase-186 contract test deliberately locks and that
four e2e specs assert. Once shipped and observed, reverting it is a second copy change, not an
undo — **one-way** within this milestone.

Option B is **reversible**: it adds a public function and moves an implementation location; no
observed copy changes.

## Decision

**Selected option:** _(awaiting maintainer)_

**Rationale:** _(awaiting maintainer)_

**Disposition of `export_action_label/2` (required if Option B):** _(awaiting maintainer — wire /
delete / retain-with-reason)_
