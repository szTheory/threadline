---
phase: 176-data-display-operator-patterns
phase_number: 176
phase_name: "Data Display & Operator Patterns"
audited: 2026-06-18
asvs_level: standard
block_on: open_threats
register_authored_at_plan_time: true
threats_total: 16
threats_closed: 16
threats_open: 0
unregistered_flags: 0
status: secured
---

# Phase 176 Security Verification

Plan-time threat mitigations were verified against implementation code and tests — not against SUMMARY self-reports. The five high/medium destructive-action threats (T-176-10 … T-176-14) were verified by reading the `prune_now` handler directly and running its security test suite (`retention_history_live_test.exs`: 15 tests, 0 failures). Documentation-only intent was not accepted as closure.

All 15 `mitigate` threats are CLOSED with code/test evidence; the single `accept` threat (T-176-SC, supply chain) is logged. The high-severity blocking gate (T-176-10) is satisfied: the client-only confirm is gone and the server `handle_event` is the sole authority.

## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| operator browser → `prune_now` `handle_event` | `phx-value-id` + typed confirmation are untrusted client claims; the server is the sole authority (the security core of this phase). |
| canonical token (server) → comparison | The token is re-derived server-side and compared constant-time; it is never shipped to the client. |
| destructive action → audit trail | Every irreversible action is recorded as an `AuditAction` (audit the auditor). |
| stored audit value → rendered copy target | Forensic integrity boundary: a truncated value must never become the copied/recovered value — `ref.full` is the only copy source. |
| server typed reason → rendered state | Distinct data-states (unauthorized / no_data / unavailable) must not collapse to one glyph — preserving the forensic distinction. |
| CSS source string ↔ contract test | Style-contract tests assert literal source strings so a CSS deletion cannot silently regress. |

## Threat Verification

| Threat ID | Plan | Category | Component | Disposition | Status | Evidence |
|---|---:|---|---|---|---|---|
| T-176-01 | 01 | Tampering (evidence) | `Presentation.ref/2` / `truncate_middle/3` | mitigate | CLOSED | `:tail_min` guarantees ≥8 tail chars survive and `full` == complete value: `lib/threadline/operator_surface/presentation.ex:60,72,96`; tests `test/threadline/operator_surface/presentation_test.exs:122` (last-8 verbatim), `:145` (`ref.full == value`). |
| T-176-02 | 01 | Tampering / EoP | retention `prune_now` (client-only `data-confirm`) | mitigate | CLOSED | RED fail-closed + audit tests authored `test/threadline/operator_surface/live/retention_history_live_test.exs:319-403`; server enforcement landed in Plan 05 (see T-176-10 … T-176-14) — the gating tests are now GREEN. |
| T-176-03 | 02 | Tampering (evidence) | `UI.ref/1` | mitigate | CLOSED | `data-tl-copy={@r.full}` bound on both `<code>` (`:383`) and button (`:388`); zero-JS fallback renders `@r.full`: `lib/threadline/operator_surface/ui.ex:376,383,388`; test `test/threadline/operator_surface/ui_test.exs:693-717` (copy==full, refute visible). |
| T-176-04 | 02 | Information disclosure / Repudiation | data-state components | mitigate | CLOSED | permission / no_data / unavailable are structurally distinct (own role, icon shape, heading); test `test/threadline/operator_surface/data_state_mapping_wave0_test.exs:69` (distinct headings), `:84` (distinct glyphs), `:89` ("not a permissions issue"). |
| T-176-05 | 03 | Tampering (evidence) | `transaction_live` copy bindings | mitigate | CLOSED | footgun removed — `lib/threadline/operator_surface/live/transaction_live.ex:120,133` use `UI.ref` (copy=full); diff-cell copy bound to full value `:188,198`; no `ref.title` in copy bindings (grep: 0). |
| T-176-06 | 03 | Tampering (evidence) | `.tl-secondary-ref` CSS ellipsis | mitigate | CLOSED | `overflow-wrap: anywhere`, no `text-overflow: ellipsis`: `lib/threadline/operator_surface/style.ex:2490-2499`; test `test/threadline/operator_surface/style_contract_test.exs:98-107` refutes ellipsis + asserts wrap. |
| T-176-07 | 03 | Information disclosure | per-page typed-reason rendering | mitigate | CLOSED | `:unauthorized` / `:source_down` / `:redacted` / `:pruned` preserved and rendered distinct per page; test `test/threadline/operator_surface/data_state_mapping_wave0_test.exs:31-34`. |
| T-176-08 | 04 | Tampering (silent regression) | `tl-coverage-command__*` CSS deletion | mitigate | CLOSED | `tl-coverage-command` fully removed from lib (grep: 0); test `test/threadline/operator_surface/style_contract_test.exs:515` `refute String.contains?(src, "tl-coverage-command")` — re-introduction fails CI. |
| T-176-09 | 04 | Defense-in-depth | accidental card nesting across pages | mitigate | CLOSED | card-nesting regression test renders all 11 surfaces and refutes card-under-card: `test/threadline/operator_surface/card_nesting_regression_test.exs`. |
| **T-176-10** | 05 | Tampering / EoP (**high — BLOCKING**) | client-only `data-confirm` prune | mitigate | CLOSED | client-only `data-confirm` deleted (grep: 0 in lib); ALL enforcement in the server `with`-chain `lib/threadline/operator_surface/live/retention_history_live.ex:67-97`; template uses `<form phx-submit="prune_now">` `:290`; test refutes `data-confirm` `:160,330`. |
| **T-176-11** | 05 | Elevation of Privilege (high) | forged `phx-value-id` targeting another scope | mitigate | CLOSED | `authorize_prune/1` re-checked in the event `retention_history_live.ex:70,325`; `phx-value-id` ignored as a scope grant (reads only `confirm` `:320`); test "forged phx-value scope fails closed" `:353-365`. |
| **T-176-12** | 05 | Spoofing (high) | replaying / forging the typed confirmation token | mitigate | CLOSED (deviation noted) | `Plug.Crypto.secure_compare(typed, canonical)` `retention_history_live.ex:72`; canonical re-derived server-side and never shipped to client `:25,72`; tests `:324` (token absent from DOM), `:337` (forged token fails closed). See **Noted Deviation**. |
| **T-176-13** | 05 | Information disclosure / timing (medium) | timing attack on token compare | mitigate | CLOSED | constant-time `Plug.Crypto.secure_compare/2` `retention_history_live.ex:72`; no hand-rolled `==` on the token (verified by read). |
| **T-176-14** | 05 | Repudiation (medium) | unaudited destructive prune | mitigate | CLOSED | `audit_prune/2` records an `AuditAction` via `Threadline.record_action(:"retention.pruned", ...)` `retention_history_live.ex:73,332-340` (`record_action` at `lib/threadline.ex:41`); runs BEFORE `Pruner.trigger` and only after a valid compare; test "valid prune records an AuditAction" `:378-395`, "forged token records nothing" `:349`. |
| T-176-15 | 05 | Tampering (medium) | redact handler against a non-existent backend | mitigate | CLOSED | redact intentionally deferred — `handle_event` count in `policy_redaction_live.ex` is 0; no handler written against the non-existent runtime redaction backend; the `checkpoint:human-verify` resolved to prune-only (option 1) per 176-05-SUMMARY. |
| T-176-SC | 01-05 | Tampering (supply chain) | npm/pip/cargo/Hex installs | accept | CLOSED (accepted) | No new runtime deps — `mix.exs:52-72` unchanged; `plug` (provides `Plug.Crypto.secure_compare`) already a direct dep (`:58`). Zero-new-deps v1.37 invariant holds. Accepted risk logged below. |

## Noted Deviation (non-blocking)

**T-176-12 — canonical token source.** The threat-register and Plan 05 mitigation text say "re-fetch the canonical token from the DB at action time." The implementation instead compares the operator-typed value against a server-side module constant (`@canonical_policy_name "default"`, `retention_history_live.ex:25`), because retention configuration is a process-wide singleton with no per-row policy table — there is no DB row to re-fetch (documented `:19-25`). All load-bearing security guarantees are present and stronger-or-equal: the token is server-authoritative, is never shipped to the client for comparison, `phx-value-id` is ignored as a scope grant, the compare is constant-time, and the default path is refusal. This is a wording mismatch, not a missing or weakened mitigation. Flagged for register hygiene only; it does not block the phase.

## Unregistered Flags

None. All `## Threat Flags` sections in `176-01-SUMMARY.md` through `176-05-SUMMARY.md` report "None new" and map to registered threat IDs. No new network endpoints, auth paths, file access, schema changes, or runtime dependencies were introduced — the phase touched only exploration-layer render/display code plus the single server-enforced prune handler. Capture and semantics layers are untouched.

## Accepted Risks

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| T-176-SC | Supply chain (Tampering) | No npm/pip/cargo/Hex installs in this phase. The only crypto primitive used (`Plug.Crypto.secure_compare/2`) comes from `plug ~> 1.15`, an existing direct dependency (`mix.exs:58`). No new attack surface introduced; zero-new-deps v1.37 invariant holds. | gsd-secure-phase (auditor) | 2026-06-18 |

## Transfer Documentation

None. No registered Phase 176 threats use the `transfer` disposition.

## Audit Trail

| Date | Auditor | Result | Closed | Open |
|---|---|---|---:|---:|
| 2026-06-18 | gsd-security-auditor | SECURED | 16 | 0 |
