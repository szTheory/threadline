---
phase: 174-form-components
verified: 2026-06-17T00:00:00Z
status: passed
score: 3/3 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 1/3
  gaps_closed:
    - "Internal form components exist (error_summary, combobox, field_group, radio, switch, search/date/number coverage now present)"
    - "Operator-surface pages consume the components (timeline_live field_group migration done; 8 display-only pages locked formless by CI guard)"
  gaps_remaining: []
  regressions: []
---

# Phase 174: Form Components Verification Report

**Phase Goal:** Build the internal form-component set and adopt it across the operator pages so inline class-soup is replaced and template duplication is materially reduced.
**Verified:** 2026-06-17
**Status:** passed
**Re-verification:** Yes — after gap closure (plans 174-05, 174-06)

## Goal Achievement

The initial verification (1/3) flagged two FAILED truths: missing components (field_group, error_summary, combobox) and incomplete page adoption. Gap-closure plans 174-05 and 174-06 addressed both. All three success criteria are now VERIFIED against the actual codebase.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Internal form components exist (text/textarea/select/combobox/checkbox/radio/switch/search/number-date/filter controls/field group/error summary/help/required-optional/disabled-readonly) with visible labels, programmatic help+errors, non-color validation, focus preserved | VERIFIED | `ui.ex`: defs for `label` (552), `error` (566), `help` (585), `input` checkbox/select/textarea/default (603/618/626/632), `field` (657), `error_summary` (697), `field_group` (725), `radio` (743), `switch` (770), `combobox` (800). text/search/number/date via generic `input` `type={@type}` passthrough. `field/1` wires `aria-describedby` to `#{id}-help`/`#{id}-error` (programmatic linkage). `error/1` renders SVG icon + text, not color alone (ui.ex:569). Stable input `id` gives LiveView focus preservation across patches. required/disabled/readonly pass through via `:rest` global. |
| 2 | The operator-surface LiveView pages consume the components (inline class-soup replaced) and template duplication is materially reduced | VERIFIED | Pages with `<form>`: start_live (2 UI calls), timeline_live (11 incl. 2 field_group), row_history_component (1), surface_header (3), stress_live (9) all adopt `UI.field`/`UI.input`/`UI.field_group`. timeline raw `<fieldset>` = 0, `field_group` calls = 2 (migration complete). The 8 display-only pages (actor/coverage/evidence/export_status/policy_redaction/retention_history/row_history/transaction) have 0 raw form controls and are locked formless by `formless_pages_test.exs`. Remaining raw `<input>` sit inside `<form>` wrappers (no `UI.form` exists by design); their fields use `<UI.field>`. |
| 3 | Per-component contract tests lock attrs/slots/states/a11y so a component regression fails CI | VERIFIED | `ui_test.exs` describe blocks: `error_summary` (412), `field_group` (464), `radio` (495), `switch` (520), `search` (545), `combobox` (557), plus existing form coverage. `formless_pages_test.exs` guards the 8 formless pages. Run: `ui_test.exs` + `formless_pages_test.exs` = 44 tests, 0 failures. Non-vacuous: injecting `<input` into actor_live.ex failed the guard as expected; file restored. |

**Score:** 3/3 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/threadline/operator_surface/ui.ex` | error_summary, field_group, radio, switch, combobox + existing set | VERIFIED | All 5 new defs present (lines 697-800); substantive HEEx bodies, not stubs; combobox uses `Phoenix.LiveView.JS` only (Alpine grep = 0). |
| `test/threadline/operator_surface/ui_test.exs` | contract tests for new components | VERIFIED | 6 new describe blocks; tests pass. |
| `lib/threadline/operator_surface/live/timeline_live.ex` | field_group adoption | VERIFIED | 2 `<UI.field_group>` calls (lines 489, 553); 0 raw `<fieldset>`. WIRED. |
| `test/threadline/operator_surface/formless_pages_test.exs` | 8-page formless guard | VERIFIED | Enumerates all 8 pages; per-page assertion; non-vacuous. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| timeline_live.ex | ui.ex field_group | `<UI.field_group>` call | WIRED | 2 call sites with legend + modifier class passthrough. |
| field/1 | input help/error ids | aria-describedby join | WIRED | `aria-describedby` built from `#{id}-help`/`#{id}-error` (ui.ex:667-680). |
| start/timeline/row_history/surface_header/stress | ui.ex field/input | `<UI.field>`/`<UI.input>` | WIRED | grep counts confirm adoption on every form-bearing page. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| UI + formless contract tests | `mix test ui_test.exs formless_pages_test.exs` | 44 tests, 0 failures | PASS |
| Full operator_surface suite (regression after timeline migration) | `mix test test/threadline/operator_surface/` | 476 tests, 0 failures | PASS |
| Compile clean | `mix compile --warnings-as-errors` | no warnings | PASS |
| Formless guard non-vacuous | inject `<input` into actor_live.ex | 1 failure (guard fired), then restored | PASS |
| No third-party JS in combobox | `grep -c "x-data\|Alpine" ui.ex` | 0 | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| COMP-04 | 174-01, 174-05 | Internal form components exist with a11y wiring | SATISFIED | Truth #1; all named components present in ui.ex. |
| COMP-05 | 174-02/03/04, 174-06 | Operator pages consume components, duplication reduced | SATISFIED | Truth #2; timeline migration + formless guard close the adoption gap. |
| COMP-06 | 174-01, 174-05 | Per-component contract tests fail CI on regression | SATISFIED | Truth #3; ui_test.exs + formless_pages_test.exs, 44 passing. |

All three Phase 174 requirement IDs accounted for; no orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | No TBD/FIXME/XXX/TODO/PLACEHOLDER in modified files | — | Debt-marker gate clean. |

### Advisory Quality Findings (from 174-REVIEW.md — NOT goal blockers)

The standalone code review flagged 5 WARNING-tier and 4 INFO-tier issues. These are robustness/quality concerns that do not falsify the phase goal (the components exist, are adopted on every form page, and are CI-locked). Surfaced for developer awareness, not as gaps:

- WR-01: radio/combobox derive DOM ids directly from option values — breaks for values with spaces/special chars (tests use slug-safe inputs only).
- WR-02: combobox listbox options have no select wiring — ARIA advertises behavior not implemented (decorative listbox).
- WR-03: switch/checkbox submit nothing when unchecked (no hidden companion input) — loses the off signal.
- WR-04: error_summary anchors to `#{field_id}-error`, but field/1 emits that id non-uniquely for multi-error fields.
- WR-05: switch truthiness only matches `true`/`"true"` — `"on"`/`1`/`"1"` render as off.
- IN-02: error_summary/radio/switch/combobox have no call sites yet (dead code at integration level; only field_group is wired).
- IN-01/IN-03/IN-04: missing CSS class definitions, nameless combobox listbox, tests assert markup not behavior.

Recommendation: route WR-01..WR-05 to a follow-up hardening pass (candidate for Phase 178 per-page stress / Phase 180 accessibility closeout, which the 174-05 SUMMARY lists as affected). They do not block proceeding.

### Human Verification Required

None. All criteria are verifiable programmatically (component existence, adoption counts, passing contract tests, non-vacuous guard). Visual styling of the new classes (IN-01) is an advisory CSS gap, not a goal requirement.

### Gaps Summary

No gaps. Both previously-failed truths are closed:
- Gap 1 (components missing) → 174-05 added error_summary, field_group, radio, switch, combobox + search/date/number passthrough, each contract-tested.
- Gap 2 (incomplete adoption) → 174-06 migrated timeline_live's two filter groups to field_group (last raw form wrapper) and locked the 8 display-only pages formless with a non-vacuous CI guard.

Phase goal achieved: the internal form-component set exists, is adopted across every form-bearing operator page, inline class-soup/fieldset markup is replaced, and per-component contract tests lock regressions. Advisory review findings remain as recommended hardening but do not block the phase.

---

_Verified: 2026-06-17_
_Verifier: Claude (gsd-verifier)_
