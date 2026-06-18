---
phase: 174
slug: form-components
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2024-06-16
---

# Phase 174 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` / `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/operator_surface/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface/` to ensure no UI regressions.
- **End of wave:** Run full `mix test` to verify no cross-boundary side-effects.

---

## Verification Criteria

1. **WAI-ARIA linkages**: Ensure that `<UI.field>` correctly connects `aria-describedby` with generated IDs for input, errors, and help blocks.
2. **Form Replacement**: Verify across all 11 operator-surface LiveView pages that no raw `<input>`, `<select>`, or `<textarea>` remain where the UI components should be used.
3. **No Regressions**: Replacing inline forms must preserve all `phx-submit`, `phx-change`, and value bindings accurately.
