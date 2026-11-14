---
phase: 250-brand-foundation-and-first-whole-investigation
plan: "05"
subsystem: ui
tags: [phoenix, exdoc, brand, hex-package, svg, woff2]
requires:
  - phase: 250-04
    provides: Immediate System, Light, and Dark selection through the existing Admin theme flow
provides:
  - Approved README and operator-guide introductions with the paired supplied lockup
  - The exact ten-file approved brand asset set in the Hex package
  - Local approved paired logos and favicon in generated ExDoc
  - Generated ExDoc theme switching with measured 96px minimum logo width
  - The example Admin favicon at its existing static path with exact supplied bytes
affects: [250-08]
actuals:
  tokens: null
  tasks: 3
  elapsed_seconds: 4928.448
  commits: 8
plan_head_before: 4b76cb748ed77004de71aadb979e1afb12a8094f
plan_head_after: 02e8c0744feae3fd30eae400398a239c66380abe
tech-stack:
  added: []
  patterns:
    - ExDoc copies only the two named paired logo files into generated assets.
    - The logo hook matches trusted path suffixes and preserves a nested documentation prefix.
    - Generated-doc browser cases register only when the private listener URL is supplied.
key-files:
  created:
    - examples/threadline_phoenix/e2e/tests/operator-brand-docs.spec.ts
  modified:
    - README.md
    - guides/operator-surface.md
    - mix.exs
    - release-please-config.json
    - test/threadline/code_walkthrough_doc_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
    - test/threadline/persona_routing_doc_contract_test.exs
    - test/threadline/readme_doc_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - examples/threadline_phoenix/priv/static/images/threadline-admin-favicon.svg
    - examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs
key-decisions:
  - Package the exact three SVGs, four approved WOFF2 files, and three OFL files; exclude the wider brand tree and TTFs.
  - Keep ExDoc and Admin behavior on their existing extension and asset paths without adding dependencies or public APIs.
  - Require the explicit parent-owned docs URL before registering generated-doc browser cases.
requirements-completed: ["ADM-09", "ADM-10", "ADM-12"]
coverage:
  - id: D1
    description: README and operator-guide introductions use the approved product category and paired lockup while retaining technical links.
    verification:
      - kind: unit
        ref: "mix verify.test test/threadline/readme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/code_walkthrough_doc_contract_test.exs (38 tests)"
        status: pass
      - kind: unit
        ref: "mix verify.test test/threadline/persona_routing_doc_contract_test.exs (4 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: The unpacked Hex archive contains the exact approved SVG, WOFF2, and OFL bytes and rejects missing, mutated, or extra assets.
    verification:
      - kind: integration
        ref: "mix verify.test test/threadline/release_artifact_contract_test.exs (21 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: Generated ExDoc serves local assets, switches its measured sidebar logo between the approved pair, and preserves favicon and Mermaid hooks.
    verification:
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors; node --check of the generated inline logo hook"
        status: pass
      - kind: other
        ref: "C31 loopback listener preflight matched generated index bytes and parent-owned listener root"
        status: pass
      - kind: automated_ui
        ref: "C20 desktop-chromium run of operator-brand-docs.spec.ts: 2 passed, 0 skipped, 0 unexpected, 0 flaky, no errors or retries"
        status: pass
    human_judgment: false
  - id: D4
    description: The example Admin serves the exact approved favicon while demo home, login, and /favicon.ico behavior remain unchanged.
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix mix test test/threadline_phoenix_web/operator_surface_test.exs (13 tests)"
        status: pass
    human_judgment: false
duration: 82min
completed: 2026-11-12
status: complete
---

# Phase 250 Plan 05: Owned docs, favicon and package assets Summary

**Approved brand assets now flow through the README, Hex package, generated ExDoc, and Admin favicon; ExDoc theme switching is verified.**

## Performance

- **Duration:** 4928.448 seconds of managed wall time, including checkpoint and parent coordination waits; not active test runtime.
- **Started:** 2026-11-12T16:51:57.628319Z
- **Completed:** 2026-11-12T18:14:06.075955Z
- **Tasks:** 3 complete.
- **Files modified:** 12 product and test files.

## Accomplishments

- Updated the README and operator-guide introductions with approved Threadline language and the supplied light/dark lockup.
- Limited the package to the exact ten approved SVG, WOFF2, and license files, and generated ExDoc identity inputs to the approved SVGs. The unpacked archive contract checks raw bytes and missing, mutated, and extra-file controls.
- Kept the existing Admin favicon path and verified the supplied bytes through its existing response behavior.
- Generated ExDoc with local paired assets, a 96px logo rule, valid theme-switch JavaScript, and a passing two-case browser proof.

## Task Commits

1. **Task 1: Align owned introductions** — `c0e7b7be` (docs), `39c912d5` (test).
2. **Task 2: Package approved assets and verify generated docs** — `33e03521` (test), `6862adbb` (feat), `277eeac9` (fix), `02e8c074` (fix).
3. **Task 3: Update the example Admin favicon** — `6ec6e400` (feat).

The earlier halted checkpoint was recorded in `89c44dd0`; this summary supersedes its halted status. The plan closeout commit contains this summary.

## Decisions Made

- Keep packaged identity limited to the specified assets and licenses; do not add a dependency, public API, or broad brand-tree migration.
- Preserve normal Playwright discovery by registering the generated-doc cases only when their private listener URL is explicitly supplied.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Emit valid JavaScript from the ExDoc logo hook**

- **Found during:** Task 2 continuation.
- **Issue:** Elixir string escaping removed JavaScript regex escapes, producing an invalid regular expression in generated `readme.html`.
- **Fix:** Match the generated logo and the two approved paired-logo suffixes with literal path checks while retaining the documentation path prefix.
- **Files modified:** `mix.exs`, `examples/threadline_phoenix/e2e/tests/operator-brand-docs.spec.ts`.
- **Verification:** The compile-only regression first failed on the old generated hook, then passed after the fix; the emitted hook passed `node --check` and both authorized browser cases passed.
- **Committed in:** `02e8c074`.

**2. [Rule 3 - Blocking] Keep default browser test discovery usable without the private docs listener**

- **Found during:** Task 2 continuation.
- **Issue:** An unconditional missing-URL exception prevented the existing Home cases from being discovered in ordinary runs.
- **Fix:** Register docs cases only when the explicit listener URL is supplied; no fallback URL or skip-only acceptance was added.
- **Verification:** Docs plus Home without a URL listed nine Home cases; docs-only without a URL listed zero and failed; docs-only with a stub URL listed exactly two cases.
- **Committed in:** `02e8c074`.

**Total deviations:** 2 auto-fixed (one Rule 1, one Rule 3). Both were required to complete the planned generated-doc proof and preserve normal test discovery.

### TDD Sequencing Deviation

Task 2 already had implementation commits before its original focused assertions, so no valid red-first sequence is claimed for the original task. This continuation did add a generated-script compile regression, observed its expected failure on the old output, and verified it passed after the correction; that does not retroactively change the original sequencing.

## Historical Verification

- The first C20 attempt selected the initial light variant but could not switch later because the guard accepted only the original `/assets/logo.svg` path. The paired-path correction in `277eeac9` fixed that guard but introduced the separately recorded emitted-JavaScript syntax defect.
- The next C20 attempt exposed the malformed emitted regular expression and was stopped under the existing browser limit. Its report and traces remain preserved.
- After the source-bound static proof and parent authorization, the single fresh C31→C20 run passed both cases with zero skipped, unexpected, flaky, or retried results. No browser run followed it.
- Earlier package mapping, release exclusion, archive residue, and observed MIME expectation failures were corrected; the final focused archive and Admin contracts passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 05 is complete. This summary claims no phase-wide requirement completion; parent-owned phase verification and independent acceptance remain authoritative. No user action is needed for this plan.

---
*Phase: 250-brand-foundation-and-first-whole-investigation*
*Completed: 2026-11-12*

## Self-Check: PASSED

The summary and generated-doc spec exist, and all eight plan-range commits are ancestors of the current HEAD.


## Final milestone traceability writeback

This plan's declared requirement contributions are now reflected in `requirements-completed`, following the independently passed phase goal and final34-requirement integration check/current candidate CI. Earlier empty completion fields were local contribution bookkeeping, not a new missing implementation. Historical results remain preserved; the bounded successor-impact verification owns current fingerprint freshness.
