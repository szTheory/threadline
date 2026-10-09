---
phase: 238-current-main-preview-and-acceptance-baseline
plan: "03"
subsystem: testing
tags: [operator-surface, exunit, playwright, postgres, evidence-custody]
requires:
  - phase: 238-02
    provides: Source-bound eleven-route and bounded state capture lanes
provides:
  - Exhaustive generic inventory and independently scanned declaration checklist
  - Ranked findings with approved owners and explicit evidence limitations
  - Independently retained loopback preview with verified stop/reopen custody
affects: [239, 240, 241, 242, 243]
actuals:
  tokens: 86055
  tasks: 2
  commits: 4
  plan_head_before: 636a8a7fd6b1811fcf70448c767f004e26163cf5
  plan_head_after: efef51e40be4a36fffca18c1aafda6d29899479a
tech-stack:
  added: []
  patterns: [Independent source declaration reconciliation, Explicit fail-closed live evidence mode]
key-files:
  created:
    - test/fixtures/operator_surface/source-surface-checklist.json
    - test/threadline/operator_surface/operator_evidence_contract_test.exs
    - .planning/phases/238-current-main-preview-and-acceptance-baseline/238-BASELINE-FINDINGS.md
  modified:
    - test/fixtures/operator_surface/route-inventory.json
    - .planning/phases/238-current-main-preview-and-acceptance-baseline/238-EVIDENCE-INDEX.md
key-decisions:
  - "Scan every active phx attribute; explicitly exclude passive timing, key, target, patch-strategy and payload families."
  - "Source-only declarations remain limited or reasoned exclusions; their existence never substantiates a rendered defect."
  - "Use the approved roadmap owners: shared layout/labels 239, connected investigations/Copy 240, coverage/evidence/redaction 241, export/retention recovery 242, integrated verification 243."
  - "Keep the machine-specific preview receipt and lifecycle script local, with exact durable pointers and hashes in the committed index."
patterns-established:
  - "Ordinary tests require only committed sources and generic fixtures; requested live mode fails on missing or invalid custody."
  - "Preview equality uses immutable base, relevant digest, served assets and semantic fixture, independently of task HEAD, timestamp or generated database name."
requirements-completed: [UIB-01, UIB-02]
coverage:
  - id: D1
    description: Generic inventory closes every independently discovered route, primitive, control and named state declaration
    requirement: UIB-02
    verification:
      - kind: unit
        ref: test/threadline/operator_surface/operator_evidence_contract_test.exs#generic inventories close every independently discovered declaration
        status: pass
      - kind: other
        ref: Clean-files-only Elixir invocation without planning, generated artifacts or running server
        status: pass
    human_judgment: false
  - id: D2
    description: Ranked baseline classifies every item with verified current evidence or an explicit limitation
    requirement: UIB-02
    verification:
      - kind: integration
        ref: THREADLINE_OPERATOR_EVIDENCE_MODE=live mix test test/threadline/operator_surface/operator_evidence_contract_test.exs
        status: pass
    human_judgment: true
    rationale: "Bounded agent visual review is recorded in the findings; visual candidate severity is judgment, and the table does not claim universal design acceptance. Agent review, not maintainer UAT, is the project default."
  - id: D3
    description: Retained seeded preview verifies actual PID, port, database, authentication, deep link and served assets
    requirement: UIB-01
    verification:
      - kind: automated_ui
        ref: THREADLINE_OPERATOR_EVIDENCE_MODE=live THREADLINE_OPERATOR_PREVIEW_REQUIRED=1 mix test test/threadline/operator_surface/operator_evidence_contract_test.exs
        status: pass
      - kind: manual_procedural
        ref: Agent-executed guarded lifecycle stop and fresh-database reopen
        status: pass
    human_judgment: false
duration: 28 min
completed: 2026-10-09
status: complete
---

# Phase 238 Plan 03: Exhaustive operator baseline and retained preview Summary

**355 source-derived inventory IDs, verified ranked evidence links, and an independently retained seeded loopback preview with fail-closed custody.**

## Performance

- Started: 2026-10-09T03:58:47.813103Z
- Completed: 2026-10-09T04:27:25Z
- Tasks: 2/2
- Production files changed: 5; this summary is separate metadata.
- Actuals: 344,218 realized diff characters / 4 = 86,054.5, rounded up to 86,055 estimate tokens. Four production commits measured from the persisted plan ledger, excluding this summary commit.

## Accomplishments

- Closed eleven routes, five theme/export seams, 54 shared primitive IDs (all exported declaration clauses mapped), 147 controls and 138 material/named state IDs. Independent scanning includes native navigation/forms, active phx controls, viewport paging and lifecycle actions. Passive attribute families carry explicit reasons. The degraded Timeline is a separate state, not a twelfth route.
- Mapped all 355 IDs exactly once in a stable risk/ID table. Reconciled every preflight route and all four named candidates plus scalar-key/unbounded-history boundaries. Confirmed direct-entry Copy binding failure, enabled disconnected Exports affordance and long-filter Timeline overflow. History header overlap remains a bounded visual candidate; empty paper/ink aliases are latent debt. Approved ownership corrects the provisional plan 02 suggestions.
- Retained the supported runner preview independently at http://127.0.0.1:4109, PID 32249, database `threadline_phoenix_testoperator_preview_reopen_1791519872`. Actual process cwd, loopback listener and PostgreSQL client ports match the receipt. Separate fresh contexts prove local unauthenticated redirect, seeded authenticated shell and transaction deep entry. Loaded JS modules and inline operator CSS match accepted/local byte hashes.

## Task Commits

1. Task 1 RED: `7172b71e` — require nonempty exhaustive inventory/checklist.
2. Task 1 GREEN: `a273df11` — generic inventories, independent contract and ranked findings.
3. Task 1 supplemental correction: `d3ebcdb6` — viewport/lifecycle declarations, refreshed findings and runtime verifier corrections.
4. Task 2: `efef51e4` — final accepted bundle and retained-preview custody index.

All commits are scoped and on the retained executor branch. After each, the local isolation receipt verified the exact existing first-parent prefix, exact new file scope and absence of deletions before appending the commit. The summary commit follows these measured task commits.

## Verification

- TDD RED target actually executed and failed the intended missing-inventory assertion. A corrected real TAP reporter rerun returned `RED_EVIDENCE_OK`; evidence and semantic assessment remain in generated `red-238-03-task1.json`. Initial malformed reporter diagnostics were rejected and did not authorize GREEN.
- Final focused static contract: 9 tests, 0 failures. Independent negative mutations remove an item from both JSON files, add actual route/function/action/paging/probe declarations, break anchors, blank fields, remove routes and duplicate IDs. Findings controls reject absent IDs, forged hashes, source-only defects and unstable equal-risk ordering. Output controls alter actual bytes and reject missing/escaping artifacts.
- Clean-files-only verification: copied committed fixtures/source/specs/test into a temporary tree containing no `.planning`, generated evidence or server state; standalone Elixir/Jason ran 9 tests, 0 failures. The final test file was copied and rerun after runtime hardening.
- Parent corpus compatibility plus this contract: 24 tests, 0 failures. The parent `e36bd1f8` exact-filename exclusions and unknown-reference negative control are preserved. `mix verify.format` passes.
- Final ordinary live evidence: 9 tests, 0 failures. Final live + preview-required command from the plan: 9 tests, 0 failures (3.9s), using the reopened independent server.
- Real explicit-live negatives reject a nonexistent manifest and a copied bundle whose actual output bytes were corrupted: each executed 9 tests with exactly the intended live-contract failure and exit 2. Separate runtime negatives reject wrong PID, port and database before any lifecycle mutation.
- Final capture lanes: 12 route/degraded browser tests pass (one intentional legacy reference-writer skip), 11 dark state tests pass, 11 System/light state tests pass. Preflight helper tests execute in each lane. Final accepted bundles are `operator_routes_1791519644`, `operator_states_1791519710`, `operator_system_1791519768`; 135/63/63 output files respectively. Raw earlier/intermediate bundles remain retained.
- Custody validator passes exact routes, source changes, ancestry prefixes, all output/served/local asset hashes and semantic fixture identity. Its former strict reference-path assertion now permits precisely the existing parent README change and the two generic JSON fixture names; all actual rendered references still receive byte checks.
- Final relevant digest: `36502f568b3e354a7859d654dafcd8ad443445f5605d447df9964611c4566a39`. It includes the generic route inventory as the existing capture helper requires. Immutable base remains `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`.
- Preservation checks pass for copied context, original dirty-file hashes, 429 pre-existing reference-file hashes excluding only the authorized inventory edit, and unchanged immutable `manifest.sha256`. No product UI source changed.

## Files Created/Modified

- `route-inventory.json` / `source-surface-checklist.json`: domain-named declarations and reasoned passive exclusions; no owners, capture locations or run IDs in authored metadata. Historical browser spec filenames are exact source anchors, not new planning terminology.
- `operator_evidence_contract_test.exs`: clean static contract, independently scanned declarations, meaningful negatives, strict generated custody and preview verifier.
- `238-BASELINE-FINDINGS.md`: exact ranked item table, approved owners, bounded review and limitations.
- `238-EVIDENCE-INDEX.md`: accepted raw bundle hashes, runtime receipt pointer/hash and lifecycle proof; prior custody remains explicitly historical.
- Local-only `238-PREVIEW-RECEIPT.json`: process/worktree/fixture/assets identity and guarded commands. The generated lifecycle script is retained in the original preview run directory. Neither machine-specific runtime artifact is staged; the committed index is its durable pointer. Parent owns byte-for-byte small-receipt synchronization back to the original checkout.

## Decisions Made

Default tests operate without planning or generated evidence. Live mode is explicit, requires real files, and fails closed. Source-only evidence receives limited/debt/not-applicable dispositions, never a rendered-defect claim. Shared primitive variants and historical probe declarations are fully accounted for without claiming all were freshly exercised.

Preview startup uses the supported `--preview` runner in a detached session. Guarded stop checks source/fixture/assets and actual PID/port/database/auth before sending SIGTERM. Reopen checks base/branch/source, a free loopback port and a fresh absent test database before the runner touches it. The first owned preview was stopped; immediate reuse of 4108 failed the free-port guard; reopen on 4109 succeeded with a new unique database. Old synthetic databases and all bundles remain retained. No shared DB reset, branch switch, push, publication or cleanup occurred.

## Deviations from Plan

1. **[Rule 2 — Missing critical custody] Inventory edits change the existing source digest.** The parent's expected plan 02 digest could not remain valid because the existing helper hashes `route-inventory.json`. Refreshed only the same three bounded lanes after relevant inventory bytes changed, including the final action audit correction. No product or capture-tooling source changed. Files: both fixtures/findings/index. Verification: source/asset/output validator and strict live contracts. Commits: `a273df11`, `d3ebcdb6`, `efef51e4`.
2. **[Rule 2 — Missing critical completeness] Final phx audit found viewport and lifecycle declarations.** Expanded the scanner to default every active phx attribute into the declaration set, retained explicit passive-family reasons, added an undeclared viewport-event negative and accounted for twelve additional controls. Final total is 355 IDs. Files: both fixtures/test/findings. Verification: final static/live/clean-tree runs and renewed bounded captures. Commit: `d3ebcdb6`.
3. **[Rule 1 — Test harness bug] Standalone preview verification required separate auth contexts and loaded-module provenance.** The unauthenticated request set a login return destination; reusing that context made a home-URL expectation fail. Separated contexts and used the exact local origin. HTML script-tag enumeration missed imported Phoenix modules, so verification now checks actual resource timing plus exact response/local bytes. No auth/product behavior changed. File: ExUnit contract. Verification: final preview-required pass and actual wrong-PID/port/database rejection. Commit: `d3ebcdb6`.

Total deviations: 3 auto-fixed (2 missing-critical, 1 harness bug). Scope remained inventory, tests and custody. Keeping machine-specific runtime artifacts local is the user's explicitly permitted portability choice.

## Issues Encountered

Initial malformed TAP reporter output was rejected and rerun unchanged through a corrected reporter. Runtime harness assumptions failed before final proof and were corrected. The busy-port reopen rejection demonstrated the fail-closed guard; a verified free port resolved it. No unresolved execution blocker remains.

Actual browser-chrome 200% zoom remains unverified because Computer Use was not approved to use Google Chrome for Testing. Clipboard denial remains unverified because the denied CDP probe still reported prompt/copied feedback. These remain precise limitations in both findings and index. Viewport/DPR/CSS zoom do not substitute. Touch is emulated Chromium; no Safari/Firefox/physical-device, full focus inventory or all-animation acceptance is claimed. Retention prune was not submitted; export worker completion/download bodies were not newly proven. These planned limitations are not capture failures or skipped mandatory verifications.

## User Setup Required

None. Preview lifecycle and authentication proof were agent-executed. No credentials, cookies, CSRF-bearing HTML or response headers are stored in receipts/evidence.

## Next Phase Readiness

Plan 03 is complete. The parent owns phase verification, requirement/state/roadmap advancement and original-checkout receipt synchronization. The retained worktree, raw bundles and independent preview remain available for phases 239–243. Existing observed defects and declared unsupported conditions are follow-up baseline inputs, not fixed by this plan. Codebase-map changes were unnecessary for this fixture/test/custody-only scope.

## Self-Check: PASSED

All key files exist. Four measured task commits are current-branch ancestors; evaluation-scope resolves all four with no unreachable commit. Both task acceptance gates and plan verification passed, real negatives rejected, final source/asset/fixture identity matches, and preservation hashes remain unchanged. Only this summary is staged for metadata close-out; STATE, ROADMAP, REQUIREMENTS and copied context stay untouched.
