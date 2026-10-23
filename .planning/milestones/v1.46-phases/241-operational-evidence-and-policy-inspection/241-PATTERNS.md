# Phase 241: Operational evidence and policy inspection - Pattern Map

**Mapped:** 2026-10-10  
**Files analyzed:** 15 existing implementation and verification files; no new production module is implied  
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/operator_surface/live/coverage_live.ex` | LiveView | request-response / read | same file, `CoverageLive` | exact |
| `lib/threadline/operator_surface/presentation.ex` | utility / presenter | transform | same file, `coverage_remediation/2` | exact |
| `lib/threadline/operator_surface/live/evidence_live.ex` | LiveView | request-response / read | same file, `EvidenceLive` | exact |
| `lib/threadline/policy/redaction_presenter.ex` | presenter | transform / database read | same file, `RedactionPresenter` | exact |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | LiveView | request-response / read | same file, `PolicyRedactionLive` | exact |
| `test/threadline/operator_surface/live/coverage_live_test.exs` | test | request-response | same file, `CoverageLiveTest` | exact |
| `test/threadline/operator_surface/presentation_test.exs` | test | transform | same file, presentation helper tests | exact |
| `test/threadline/operator_surface/live/evidence_live_test.exs` | test | request-response | same file, `EvidenceLiveTest` | exact |
| `test/threadline/policy/redaction_presenter_test.exs` | test | transform | same file, presenter tests | exact |
| `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | test | request-response | same file, `PolicyRedactionLiveTest` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` | test / browser | request-response / rendered interaction | same file, coverage route checks | exact |
| `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | test / browser | request-response / rendered states and clipboard | same file, route-state and copy checks | exact |
| `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`, `operator-motion.spec.ts`, `operator-earned-flows.spec.ts` | tests / browser | rendered interaction | corresponding operator browser suites | exact |

All analog paths above are git-tracked in the phase worktree. `241-VALIDATION.md` is the source of the focused-suite map; the coverage-readiness spec is present and tracked despite not being listed among the older canonical refs.

## Pattern Assignments

### Coverage LiveView, snapshot state, and remediation

**Analog:** `lib/threadline/operator_surface/live/coverage_live.ex`

**Assigns and scoped parameter flow** (lines 25-69): initialize `:coverage_for_schema`, `:schema_param`, `:available_schemas`, and `:form_error`; `handle_params/3` validates schema via `safe_available_schemas/1` and `safe_validate_schema/3` before fetching. Preserve this assign split and the existing authorization/on-mount boundary. The query parameter carries requested scope; it does not authorize access.

**Failure and stale-data pattern** (lines 384-415): the read is wrapped in `try/rescue`, emits the existing health error telemetry, preserves a prior snapshot only when it belongs to the same schema and has a check timestamp, otherwise assigns `Snapshot.empty(nil)` with an error. The renderer currently checks `all_empty?/1` before the error-aware verdict (lines 451-475, 540-547); change verdict precedence so an error without same-schema last-good data renders unavailable and cannot fall through to healthy/empty. Retain the same-schema stale timestamp and warning path (lines 155-160).

**Remediation helper** (`lib/threadline/operator_surface/presentation.ex`, lines 471-496): `coverage_remediation/2` returns a small map of `label`, `command`, and `follow_up`; it uses `@safe_generator_identifier` and emits `command: nil` with manual instructions for unsafe inputs. Extend the predicate check to both schema and table before composing `SCHEMA.TABLE`; keep the nil-command/manual path. The table renders only the helper command as its copy attribute (`coverage_live.ex`, lines 236-256).

**Snapshot and topbar analogs:** `lib/threadline/operator_surface/coverage/snapshot.ex` lines 4-19 defines counts, error, observation time, and the three table buckets; keep inspection failure distinct from an actual empty bucket. `lib/threadline/operator_surface/coverage/on_mount.ex` lines 69-110 keeps topbar error separate from the last-good snapshot. Keep topbar and selected-schema verdicts consistent.

### Evidence LiveView and allowlisted row projection

**Analog:** `lib/threadline/operator_surface/live/evidence_live.ex`

**Read-state assignment seam** (lines 23-58): `mount/3` initializes `:request`, `:groups`, and `:form_error`; `handle_params/3` parses URL state and fetches through `fetch_records/3`. Add a distinct read-error assign/state at this boundary so a failed query does not become the successful empty result. Keep disabled access separate from both outcomes.

**Existing query modes and history URL** (lines 235-276, 429-447): overview, latest-by-subject, exact latest-by-reference, and history each use their existing `Evidence` calls with resolved repo/storage-schema options. `history_path/3` carries subject, JSON subject ref, and `mode=history`; preserve those URL values. In particular, exact lookup `nil -> []` (lines 256-263) means no matching record only when the read succeeded.

**Secure presenter projection** (lines 288-301): `Proof.present_record/1` feeds a fixed map containing id, subject, subject reference, summary status, proof label, recorded timestamp, and verdict status. Keep `summary_status` distinct from `proof_label`/assessment and do not project `detail`, `provenance`, or arbitrary maps. The empty UI currently renders whenever groups are empty (`render/1`, lines 96-104); branch on unavailable before that state.

### Redaction presenter and policy page

**Analog:** `lib/threadline/policy/redaction_presenter.ex`

**Classification/report shape** (lines 8-12, 109-196): the public internal grouping order is exactly `:drift_detected`, `:could_not_introspect`, `:config_matches_deployed`; rows carry normalized configured/deployed policy, diff, safe warning, and hint. In the missing-trigger branch (lines 114-133), an absent deployment is currently treated as a match when config is empty. Classify every configured table with no deployed trigger as drift and retain `@missing_trigger_warning`. Only a successfully parsed existing trigger can match. Unsupported language or parse failures stay `could_not_introspect` (lines 171-195).

**Sensitive SQL boundary** (`redaction_presenter.ex`, lines 77-107): catalog query reads `p.prosrc` for internal parsing. Do not return or render the source; keep report fields to normalized policy and safe metadata. Continue using `TriggerCaptureConfig`/`RedactionPolicy` normalization rather than adding a second parser.

**LiveView assigns and summary** (`lib/threadline/operator_surface/live/policy_redaction_live.ex`, lines 25-64, 290-343): assigns include schema URL state, validation error, report, and sections; schema is validated before `fetch_report_for_schema/2`. The all-clear helper depends on zero drift and zero introspection failures. Keep the three-state report taxonomy and preserve host authorization, selected schema, and table-scoped links. For any copy addition, use only safe normalized policy/remediation fields.

### ExUnit fixtures and regression assertions

**Coverage fixture:** `test/threadline/operator_surface/live/coverage_live_test.exs` lines 1-58 wires a test authorization callback into `threadline_operator_surface`, starts its endpoint, uses `Threadline.OperatorSurfaceCase`, and sets up the poll interval with cleanup. `force_broken_repo!/0` is the existing deterministic failure seam. Lines 298-338 cover same-schema stale retention and cross-schema failure; extend it with first-read failure and assert unavailable rather than empty/ready. `test/threadline/operator_surface/presentation_test.exs` lines 373-397 gives direct helper assertions for safe copy commands and unsafe manual fallback; add safe non-public schema and unsafe schema/table cases here.

**Evidence fixture:** `test/threadline/operator_surface/live/evidence_live_test.exs` lines 1-68 wires evidence authorization, endpoint, cleanup, and `insert_evidence/1` (including `detail`/`provenance` canaries). Lines 298-341 demonstrate history rendering and successful empty state; lines 343-359 pin storage-schema options and all read calls. Use this DB/LiveView fixture to test empty versus read failure and verify unapproved fields stay out of HTML.

**Redaction fixtures:** `test/threadline/policy/redaction_presenter_test.exs` lines 132-137 covers missing configured trigger with nonempty policy; use `build_report/3` with empty policy and no deployed rows for the missing-trigger regression. Lines 331-358 show report-level canary assertions. `test/threadline/operator_surface/live/policy_redaction_live_test.exs` lines 1-62 creates a separate authorized endpoint and test tables; lines 139-210 checks section ordering, safe normalized detail, warnings, and HTML canaries. Add assertions for empty-policy drift and sensitive strings absent from HTML/copy attributes here.

### Mounted browser verification

**Coverage analog:** `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` lines 1-110 provides login, viewport, overflow, bounds, visible-keyboard-focus, and command/copy geometry helpers. Lines 112-195 exercise five viewport sizes plus keyboard interaction; lines 197-213 check scoped links. Extend this spec for schema-qualified remediation, safe copy payload, and unavailable/empty states where the mounted app can produce them.

**Evidence and policy route analog:** `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` lines 1-32 shows the evidence-gated Playwright lane; lines 233-312 demonstrates checking actual rendered content, copy attributes, and non-copyable/redacted values. For a new policy copy affordance, assert the attribute allowlist and read the browser clipboard after clicking. Keep route-state checks bounded and record unavailable tooling as an evidence gap.

**Cross-cutting browser checks:** use the phase-listed `operator-accessibility.spec.ts`, `operator-motion.spec.ts`, and `operator-earned-flows.spec.ts` for keyboard/focus, reduced motion, and operator journeys respectively; keep tests focused on user-visible behavior rather than brittle markup. The coverage spec already supplies responsive table and actual keyboard patterns.

## Shared Patterns

### Authorization and schema scope

**Sources:** `coverage_live.ex` lines 40-69; `policy_redaction_live.ex` lines 36-64; `coverage_live_test.exs` lines 2-19. Preserve the existing per-surface authorize callback at router construction. Validate client-controlled schema query parameters before every corresponding read; scope catalog reads to the selected schema. URL state never grants host authorization or broadens tenant scope.

### Safe errors and honest empty states

**Sources:** `coverage_live.ex` lines 384-415; `evidence_live.ex` lines 32-58 and 96-104; `ui/data.ex` lines 56-103. Render safe unavailable state for read failures without echoing database details; use existing `unavailable`/`error` display variants where appropriate. Successful no-match is distinct from read failure and from an `unsupported` proof assessment. Same-schema last-good coverage remains visibly stale with its original timestamp.

### Copy and rendered data allowlists

**Sources:** `coverage_live.ex` lines 236-256; `evidence_live.ex` lines 288-301; `redaction_presenter.ex` lines 153-196; `operator-route-states.spec.ts` lines 295-312. Build command text only after both schema and table pass the existing conservative identifier rule. Evidence and redaction UI/copy values must come from explicit allowlists and normalized policy; never expose trigger SQL, sample values, redacted values, or arbitrary evidence maps.

## No Analog Found

None. The Nyquist validation map points to existing ExUnit fixtures and mounted-browser suites for every phase behavior. No new production layer, API, route, dependency, or test framework is needed.

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/`, `lib/threadline/policy/`, corresponding `test/threadline/` suites, and `examples/threadline_phoenix/e2e/tests/` named by `241-VALIDATION.md`.  
**Files scanned:** 18 tracked source/test/browser analogs, including supporting snapshot, on-mount, and UI display primitives.  
**Pattern extraction date:** 2026-10-10
