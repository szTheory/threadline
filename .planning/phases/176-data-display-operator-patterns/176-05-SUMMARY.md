---
phase: 176-data-display-operator-patterns
plan: 05
subsystem: operator-surface
tags: [destructive-actions, security, t3-confirm, secure-compare, data-table, kebab, redaction, diff-table, a11y, wave-4]

# Dependency graph
requires:
  - "176-02: UI.data_table/1 (stream/:col label/:action), UI.dropdown/1 (kebab role=menu), UI.divider/1, UI.modal/1 (focus_first/pop_focus), UI.ref/1 (data-tl-copy=full)"
provides:
  - "retention prune is a SERVER-ENFORCED T3 type-to-confirm: re-check authz in the event, secure_compare typed value vs server-canonical policy name, Pruner.trigger on match, record an AuditAction, fail closed on any mismatch (forged token / forged id / missing authz)"
  - "client-only data-confirm prune is DELETED (zero server enforcement)"
  - "retention runs table migrated to UI.data_table stream with a kebab (UI.dropdown) whose destructive prune item renders last after UI.divider with tl-button--danger + non-color cue (D-18)"
  - "UI.ref run-id copy affordance on the runs table (data-tl-copy=full, ref-copy contract GREEN)"
  - "policy/redaction stays a 2-col diff table with scope=row field headers that render when stacked at <=480px (D-10); no bulk multi-select on either destructive surface (D-19)"
  - ":kebab icon glyph added to the registry"
affects:
  - "DATA-04 destructive-action mitigation is now enforced server-side (the BLOCKING high-severity threat is closed); the Plan-01 T3 + ref-copy Wave-0 RED tests are GREEN"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "T3 with-chain: authorize_prune/1 -> Plug.Crypto.secure_compare(typed, @canonical_policy_name) -> Pruner.trigger/0 -> Threadline.record_action(:\"retention.pruned\") -> else fail-closed refusal flash"
    - "canonical confirmation token is a server-side module attribute re-derived at action time; phx-value-id is ignored as a scope grant (forged scope fails closed); the token is never shipped to the client for a client-side compare"
    - "destructive action audited as an AuditAction via the existing Threadline.record_action/2 insertion path — no capture/semantics edit"
    - "diff-table responsive collapse fix = scope=row + data-label on the field <th> (keeps the 2-col Configured-vs-Deployed comparison; NOT converted to kv)"

key-files:
  created:
    - .planning/phases/176-data-display-operator-patterns/176-05-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - lib/threadline/operator_surface/live/policy_redaction_live.ex
    - lib/threadline/operator_surface/components/icon.ex
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs

key-decisions:
  - "[176-05] Task 1 checkpoint (PRE-RESOLVED by human): approved option 1 — ship the T3 pattern via 'prune now' ONLY this phase; DEFER the redact destructive flow. Rationale: prune is the real load-bearing destructive surface with a real backend (Pruner.trigger/0); redact has NO runtime backend (redaction is codegen-time only in capture/redaction_policy.ex + trigger_sql.ex), and building one would touch the capture layer — a v1.37 invariant violation. Deferring preserves capture/semantics-untouched. No redact handle_event was written; policy_redaction_live.ex stays a read-only 2-col diff table."
  - "[176-05] The retention policy is a process singleton (no per-policy DB row), so the object's OWN identifier (D-20) is the canonical policy name 'default', held as a server-side module attribute (@canonical_policy_name) and re-derived at action time. secure_compare runs against this server constant; the operator types the policy name (never a constant like 'DELETE')."
  - "[176-05] phx-value-id is ignored entirely as a scope grant: the prune is policy-scoped, not id-scoped, so a forged id can never broaden scope and fails closed via the token mismatch. Authorization is re-derived from the server-resolved policy gate (threadline_policy_enabled), not from any client claim."
  - "[176-05] Rule 3 (blocking): added a :kebab icon glyph (three vertical dots) to the registry — D-18 requires a kebab trigger and none existed. No icon contract test enumerates the registry, so this is purely additive."

# Metrics
metrics:
  duration: ~50m
  tasks: 3
  files_created: 1
  files_modified: 5
  completed: 2026-06-18
---

# Phase 176 Plan 05: Destructive-action server enforcement (T3 prune) + diff-table collapse Summary

Closed the security core of Phase 176: the retention "prune now" action is now enforced ENTIRELY server-side as a T3 type-to-confirm flow (re-check authz in the event, `Plug.Crypto.secure_compare` the typed value against a server-canonical policy name, trigger the real `Pruner` only on match, record an `AuditAction` for the destructive action itself, and fail closed on every mismatch). The client-only `data-confirm` — which provided zero server enforcement — is deleted. The runs table moves to `UI.data_table` `stream:` with a kebab whose destructive prune item renders last after a divider with a non-color danger cue, and the policy/redaction page keeps its 2-col diff table while fixing the responsive collapse (`scope="row"` field headers). The redact destructive flow is deferred (option 1) because it has no runtime backend.

## Task 1 — Redact runtime-backend checkpoint (PRE-RESOLVED: option 1)

The blocking `checkpoint:human-verify` was resolved by the human before execution: **approved option 1** — ship the T3 pattern via "prune now" only this phase and DEFER redact's destructive flow.

- Rationale (recorded per the checkpoint): "prune now" has a real runtime backend (`Threadline.Retention.Pruner.trigger/0`); the "redact an already-captured value" action has NO runtime backend — redaction is codegen-time only (`capture/redaction_policy.ex` + `capture/trigger_sql.ex`), and `policy_redaction_live.ex` has no redact `handle_event`. Building a runtime redaction backend would touch the capture layer, violating the v1.37 capture/semantics-untouched invariant. Deferring preserves that invariant.
- Outcome: NO redact `handle_event` was written. `policy_redaction_live.ex` remains a read-only Configured-vs-Deployed diff table. Redact's destructive flow is logged as a deferred item (see Deferred Items).

## Task 2 — Prune rebuilt as a server-enforced T3 type-to-confirm (`f1181f0`)

- **Deleted both client-only `data-confirm` prune buttons** (the empty-state CTA and the page-actions CTA). They now open a confirm modal (`phx-click="open_prune_modal"`); they no longer carry any destructive instruction the client could bypass.
- **Added a `UI.modal/1` + `<form phx-submit="prune_now">`** requiring the operator to type the policy name `default` (D-20 — the object's own identifier, never a constant). Cancel uses the modal `on_cancel`/`pop_focus` path; the danger submit reads "Prune now — removes matching records permanently".
- **Rewrote `handle_event("prune_now", ...)` as a `with` chain** (RESEARCH §"T3 destructive enforcement skeleton"): `authorize_prune/1` (re-check `threadline_policy_enabled` at action time) → `Plug.Crypto.secure_compare(typed, @canonical_policy_name)` (constant-time, server-canonical token re-derived at action time, never shipped to the client) → `Pruner.trigger/0` → `Threadline.record_action(:"retention.pruned", ...)` (audit the destructive action via the existing `lib/threadline/audit.ex` insertion path) → `else _ -> fail closed` (refusal flash, no prune, no audit). `phx-value-id` is ignored as a scope grant — a forged id can never broaden scope and fails closed via the token mismatch.
- **Migrated the runs table to `UI.data_table/1`** with `stream:` (`phx-update="stream"`), a `:col label` per column (Run / Status / Deleted Rows / Duration / Date), and an `:action` kebab (`UI.dropdown/1`) whose destructive "Prune now" item renders LAST after `UI.divider/1` with `tl-button--danger` + a non-color icon cue (D-18).
- **Added `UI.ref/1`** for the run id (`data-tl-copy={full}`), turning the Wave-0 ref-copy contract GREEN.
- Added a `:kebab` icon glyph (Rule 3 — D-18 needs a kebab trigger; none existed).
- Updated two pre-existing tests that asserted the old client-confirm behavior to the new server-enforced T3 form flow.

## Task 3 — Policy/redaction diff-table collapse + no-bulk-multi-select (`635b786`)

- Added `scope="row"` + `data-label="Field"` to the three field `<th>` rows (exclude / mask / mask placeholder). `scope="row"` makes each field the announced row header; `data-label` drives the responsive `::before` so the field name renders when the table stacks at ≤480px (D-10). The page stays a 2-col `tl-table--policy` Configured-vs-Deployed diff table — NOT converted to `kv`.
- Added tests asserting `scope="row"` on the three field headers, the field name rendering when stacked, and that NO bulk multi-select / select-all-over-destructive control exists on either the redaction or retention surface (D-19).
- Updated the pre-existing mask-placeholder header assertion to the new `<th scope="row" data-label="Field">` markup.
- Per the Task-1 checkpoint (option 1): no redact handler was added; the page stays read-only.

## Verification

- `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` → 14 tests, 0 failures, INCLUDING the BLOCKING T3 security gate: token mismatch → no prune; forged `phx-value-id`/scope → no prune; missing authz → no prune + no prune affordance; valid type-to-confirm → an `AuditAction` is recorded.
- `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs` → 4 tests, 0 failures (scope=row + no-bulk-multi-select).
- Source assertions: `grep -c secure_compare …retention_history_live.ex` = 2 (≥1); `grep -c data-confirm …retention_history_live.ex` = 0; `grep -c 'scope="row"' …policy_redaction_live.ex` = 3 (≥3); table stays `tl-table--policy`.
- `mix verify.credo` → no issues. `mix format --check-formatted` clean on all five changed files (the only project-wide format drift is `ui_stress_test.exs`, pre-existing and out of scope — see Deferred Issues).
- `mix test style_contract_test.exs brandbook_token_parity_test.exs ui_test.exs` → 89 tests, 0 failures (no new `--tl-*` token; no `style.ex` change).
- `mix compile --warnings-as-errors` clean.
- Capture & semantics layers byte-for-byte UNTOUCHED — the only new DB writes are the destructive prune (via the existing `Pruner`) and the `AuditAction` recording it, both through existing insertion paths. Files changed are exploration-layer UI only (2 live views, the icon registry, 2 test files).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a `:kebab` icon glyph**
- **Found during:** Task 2.
- **Issue:** D-18 requires a per-row kebab (`dropdown/1`) trigger; the icon registry (`icon.ex`) had no kebab glyph (`history`, `shield`, `trash`, `evidence`, `refresh`, … but no kebab).
- **Fix:** Added `defp paths(:kebab), do: ["M12 5h.01", "M12 12h.01", "M12 19h.01"]` (three vertical dots). No icon contract test enumerates the registry, so the addition is purely additive.
- **Files modified:** lib/threadline/operator_surface/components/icon.ex
- **Commit:** f1181f0

**2. [Rule 3 - Blocking] Updated pre-existing tests invalidated by the T3 rewrite**
- **Found during:** Tasks 2 and 3.
- **Issue:** Two retention tests asserted the old client-only behavior — the empty-state test asserted the deleted `data-confirm` string, and the "Run retention prune CTA" test clicked the button expecting a direct prune. One redaction test asserted the bare `<th>mask placeholder</th>` markup that gained `scope="row"`.
- **Fix:** Re-targeted the retention empty-state test to assert `refute data-confirm` + `assert phx-submit="prune_now"`; re-targeted the CTA test to submit the server-enforced `form[phx-submit=prune_now]` with the policy name; updated the redaction header assertion to the new `<th scope="row" data-label="Field">` markup. These are the same surfaces this plan modifies — the old assertions encoded the security hole being closed.
- **Files modified:** test/threadline/operator_surface/live/retention_history_live_test.exs, test/threadline/operator_surface/live/policy_redaction_live_test.exs
- **Commits:** f1181f0, 635b786

**3. [Rule 1 - Bug] `record_action/2` requires an atom name**
- **Found during:** Task 2 (test run).
- **Issue:** The first cut passed `"retention.pruned"` (a string) to `Threadline.record_action/2`, which guards `when is_atom(name)` — a `FunctionClauseError` at action time.
- **Fix:** Pass `:"retention.pruned"` (a dotted atom); `build_attrs/3` stringifies it back to `"retention.pruned"`.
- **Commit:** f1181f0

**4. [Rule 1 - Bug] Confirmation token discovery regex matched the input aria-label**
- **Found during:** Task 2 (valid-prune test failed — submitted `confirm: "to"`).
- **Issue:** The test's `canonical_policy_name/1` regex (`/type the policy name .../i`) matched the input's `aria-label="Type the policy name to confirm"` and captured `to` instead of falling back to the default `"default"`. A `confirm: "to"` then failed `secure_compare` (correct fail-closed behavior, but not the intended test path).
- **Fix:** Reworded the input `aria-label` to "Policy name to confirm" and rendered the policy name inside `<code>default</code>` in both the description and the field label, so the regex finds no bare-text match and falls back to its `"default"` default — which equals `@canonical_policy_name`.
- **Commit:** f1181f0

## Deferred Issues

- **Redact destructive flow (T3 redact)** — DEFERRED per the Task-1 checkpoint (option 1). No runtime redaction backend exists (redaction is codegen-time only); building one would touch the capture layer (v1.37 invariant violation). `policy_redaction_live.ex` stays read-only. Revisit only if/when a runtime "redact a stored value" operation is explicitly scoped (and even then, only if it can be done without editing the capture layer).
- **`ui_stress_test.exs` format drift** — pre-existing project-wide `mix format` drift in a file NOT in this plan's scope; left untouched (scope boundary).

## Known Stubs

None. The prune T3 flow is fully wired (real `Pruner` backend + real `AuditAction` record); the diff-table fix is a real markup change with passing tests. The redact flow is intentionally NOT stubbed — it is deferred with no placeholder handler (per the checkpoint), so there is no stub to wire.

## Threat Flags

None new. The plan's threat register is satisfied: T-176-10 (client-confirm deleted; all enforcement in `handle_event`), T-176-11 (authz re-checked + forged id fails closed), T-176-12 (canonical token re-derived server-side + `secure_compare`, never shipped to client), T-176-13 (constant-time `Plug.Crypto.secure_compare/2`, no hand-rolled `==`), T-176-14 (prune recorded as an `AuditAction`), T-176-15 (redact gated by the checkpoint, deferred — no handler against a non-existent backend). No new security surface introduced; the only DB writes go through existing `Pruner` / `record_action` paths.

## Self-Check: PASSED

All five modified files + the SUMMARY exist on disk; both task commits (`f1181f0`, `635b786`) are present in git history; `retention_history_live.ex` contains `secure_compare` and `record_action` and no `data-confirm`; `policy_redaction_live.ex` contains three `scope="row"` field headers and stays `tl-table--policy`.
