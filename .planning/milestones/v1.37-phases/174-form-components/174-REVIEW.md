---
phase: 174-form-components
reviewed: 2026-06-17T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/threadline/operator_surface/ui.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - test/threadline/operator_surface/ui_test.exs
  - test/threadline/operator_surface/formless_pages_test.exs
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 174: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the phase 174 gap-closure changes since `a8a2f48`: five new internal form
components in `ui.ex` (`error_summary`, `field_group`, `radio`, `switch`, `combobox`),
the `timeline_live` migration of two `<fieldset>` blocks to `UI.field_group`, and the
new contract/guard tests (`ui_test.exs`, `formless_pages_test.exs`).

The `field_group` migration is clean and semantics-preserving. The contract tests for
`error_summary` and `field_group` are solid. However, several of the new components ship
with correctness, accessibility, and integration defects that the accompanying tests do
not exercise — the tests only assert against slug-safe, happy-path inputs, so the
defects below pass CI while being broken in realistic use.

No Critical issues (no injection, secret, crash, or data-loss vector). The findings are
WARNING-tier correctness/robustness defects and INFO-tier quality gaps.

## Warnings

### WR-01: `radio` and `combobox` generate invalid/broken DOM ids from option values

**File:** `lib/threadline/operator_surface/ui.ex:749-755` (radio), `lib/threadline/operator_surface/ui.ex:824` (combobox)
**Issue:** `radio` builds `id={"#{@name}-#{value}"}` and the matching `label for={"#{@name}-#{value}"}`. If an option `value` contains a space or special character — which is realistic for this domain (e.g. actor kinds like `service_account` are fine, but free-form table/schema values, display labels reused as values, or any value with spaces/`/`/`#`) — the resulting `id`/`for` pair is an invalid HTML id and the label-to-input association silently breaks. That defeats the component's stated purpose ("each input has a distinct id and an associated `<label>`") and is an accessibility regression (clicking the label no longer toggles the input; screen readers lose the name). The `error_summary` href pattern (`##{field_id}-error`) has the same fragility if a field id ever contains non-fragment-safe characters. The `radio` test (`ui_test.exs:495-518`) only uses `"a"`/`"b"`, so this is untested.
**Fix:** Slugify or index the value when composing ids, and keep the `for`/`id` derivation identical:
```elixir
<div :for={{{label, value}, idx} <- Enum.with_index(@options)} class="tl-radio">
  <% opt_id = "#{@name}-#{idx}" %>
  <input type="radio" id={opt_id} name={@name} value={value}
         checked={to_string(value) == to_string(@value)} class="tl-radio__input" />
  <label for={opt_id} class="tl-radio__label"><%= label %></label>
</div>
```

### WR-02: `combobox` listbox options are non-functional and misleading for assistive tech

**File:** `lib/threadline/operator_surface/ui.ex:800-829`
**Issue:** The `<li role="option" data-value={value}>` entries have no click/select wiring. The input's `phx-click` only toggles listbox visibility and `aria-expanded`; nothing populates the input value, sets `aria-activedescendant`, or closes the listbox when an option is chosen. A keyboard/screen-reader user is told (via `role="combobox"`/`role="listbox"`/`role="option"`) that selectable options exist, but selecting one does nothing. The docstring claims graceful degradation ("submits like any text field"), which is true only because the listbox is purely decorative — the ARIA contract advertises behavior the component does not implement. The test (`ui_test.exs:557-578`) only asserts the markup is present, never that selection works. This is an accessibility/correctness defect: either wire up selection or drop the option `role`s so AT is not misled.
**Fix:** Either make options functional (set the input value on click via JS and close the listbox, manage `aria-activedescendant`), or — if this is intentionally a static-suggestion control — remove `role="listbox"`/`role="option"` and document it as a styled suggestion list, not a combobox.

### WR-03: `switch` (and the checkbox `input` it mirrors) submit nothing when unchecked

**File:** `lib/threadline/operator_surface/ui.ex:770-786`
**Issue:** `switch` renders a bare `<input type="checkbox" value="true">`. Unchecked checkboxes are omitted entirely from form submission, so a server cannot distinguish "switch turned off" from "switch field absent." For an audit/operator surface where a toggle going from on→off is meaningful (e.g. disabling a filter or a policy flag), this loses the off signal. The standard Phoenix pattern pairs the checkbox with a hidden companion input carrying the unchecked value. The component is presented as a reusable form control, so the omission is a behavioral defect, not a style choice. (The pre-existing `input/1` checkbox branch at lines 603-616 has the same gap; `switch` propagates it.)
**Fix:**
```elixir
~H"""
<input type="hidden" name={@name} value="false" />
<input type="checkbox" role="switch" id={@id} name={@name} value="true"
       checked={@checked} aria-checked={if @checked, do: "true", else: "false"}
       class={["tl-checkbox", "tl-switch", @class]} {@rest} />
"""
```

### WR-04: `error_summary` links to field error ids that `field` renders non-uniquely

**File:** `lib/threadline/operator_surface/ui.ex:697-717` (summary), interaction with `lib/threadline/operator_surface/ui.ex:682` (field)
**Issue:** `error_summary` links each message to `##{field_id}-error`. The `field` component renders one `<.error id={@error_id}>` per error message (`:for={msg <- @errors}` at line 682) using the **same** `id="#{@id}-error"` for every message. So a field with N>1 errors emits N elements sharing one id — invalid HTML, and the `error_summary` anchor jumps to whichever the browser resolves first. Because `error_summary` is being introduced specifically to point at `field` error targets, this cross-component contract is broken for any multi-error field. The `error_summary` test (`ui_test.exs:412-462`) tests the summary in isolation and never renders it alongside a multi-error `field`, so the broken linkage is uncovered.
**Fix:** Make `field` error ids unique (e.g. `"#{@id}-error-#{idx}"` and point the summary at the first, or render a single `<.error>` wrapping a list of messages) so each `field_id-error` id is unique and the anchor target is deterministic. Document the `field_id` → `#{field_id}-error` contract on `error_summary` so callers know the id must match the field's `id` attr.

### WR-05: `switch` value coercion silently rejects common truthy representations

**File:** `lib/threadline/operator_surface/ui.ex:771`
**Issue:** `assigns.value == true || assigns.value == "true"` treats only the literal `true` and `"true"` as checked. Form round-trips and HTML conventions frequently surface checked state as `"on"`, `1`, `"1"`, or `:true`; all of these render the switch as **off**, which for a toggle that reflects persisted state is a silent data-display bug (the UI shows "off" for a value that is actually on). Same coercion exists in the checkbox `input` branch (line 604).
**Fix:** Normalize against the documented truthy set, e.g.:
```elixir
checked = assigns.value in [true, "true", "on", 1, "1"]
```
or centralize a `truthy?/1` helper shared by `input` checkbox and `switch` so both branches agree.

## Info

### IN-01: New components ship with CSS class names that have no stylesheet definitions

**File:** `lib/threadline/operator_surface/ui.ex:704,745,753,757,782,802,823-824`
**Issue:** `tl-error-summary`, `tl-radio`/`tl-radio__input`/`tl-radio__label`, `tl-switch`, `tl-combobox`/`tl-combobox__listbox`/`tl-combobox__option`, and the base `tl-error`/`tl-field`/`tl-checkbox` classes are not defined in `lib/threadline/operator_surface/style.ex`. (Confirmed: `grep -c` returns 0 for each of these in the 3,881-line inlined stylesheet, while `tl-control` returns 25.) The new components will render unstyled. Note the gap is partly pre-existing — `tl-field`/`tl-label`/`tl-help`/`tl-error` were already undefined before this phase — but `radio`/`switch`/`combobox`/`error_summary` extend the surface of unstyled classes with no corresponding style work in the phase.
**Fix:** Add the missing rules to `style.ex` (or confirm and document that these classes are styled elsewhere). At minimum track the gap so the components are not shipped as visually broken.

### IN-02: New components have no usages anywhere in the codebase

**File:** `lib/threadline/operator_surface/ui.ex:697,725,743,770,800`
**Issue:** Only `field_group` is actually wired in (timeline_live). `error_summary`, `radio`, `switch`, and `combobox` have zero call sites in `lib/` outside their own definitions and tests — they are dead code at the integration level. Adding unused public-ish components increases surface area and the chance the WR-01..WR-05 defects above ship undetected because no real page exercises them.
**Fix:** Either integrate them on the form pages they were built for, or hold them until a consuming page exists so their contracts get exercised against real data.

### IN-03: `combobox` emits an empty `aria-label` when `name` is nil

**File:** `lib/threadline/operator_surface/ui.ex:823`
**Issue:** `combobox` defaults `name` to `nil` and uses `aria-label={@name}` on the `<ul role="listbox">`. When `name` is nil the listbox loses its accessible name. The combobox input also reuses `@name` as its only labelling hint; there is no `aria-label`/associated `<label>` for the input itself, so a nameless combobox is unlabeled for AT.
**Fix:** Add a dedicated `attr :label` (or require `aria-label` via `:rest`) for the combobox, and fall back to a sensible listbox label rather than relying on `name`.

### IN-04: Tests assert markup presence but not behavior, leaving the WR-tier defects uncovered

**File:** `test/threadline/operator_surface/ui_test.exs:412-578`
**Issue:** The new tests are pure `html =~` substring/regex checks on happy-path slug inputs. They never cover: option values with spaces/special chars (WR-01), combobox option selection (WR-02), unchecked-switch submission semantics (WR-03), multi-error field + summary id collisions (WR-04), or alternate truthy values (WR-05). The `radio` "exactly one name= group" assertion (`length(Regex.scan(...)) == 2`, line 505) hardcodes the two-option count rather than asserting a property, so it will need editing for any option-count change and gives a false sense of coverage.
**Fix:** Add regression cases for non-slug values, alternate truthy inputs, and the `field`+`error_summary` integration so the contracts the docstrings promise are actually enforced.

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
