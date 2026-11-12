---
phase: 250-brand-foundation-and-first-whole-investigation
plan: "05"
subsystem: ui
tags: [phoenix, exdoc, brand, hex-package, svg, woff2]
requires:
  - phase: 250-04
    provides:
      - Immediate System, Light, and Dark selection through the existing Admin theme flow
provides:
  - Approved README and operator-guide introductory copy with the paired supplied lockup
  - An exact ten-file approved brand asset set in the Hex package and ExDoc inputs
  - The example Admin favicon at its existing static path with exact supplied bytes
affects: [250-08]
actuals:
  tokens: null
  tasks: 2
  commits: 6
  elapsed_seconds: null
plan_head_before: 4b76cb748ed77004de71aadb979e1afb12a8094f
plan_head_after: 277eeac9d0587be07deaff36daacd3f20d0a46ea
tech-stack:
  added: []
  patterns:
    - ExDoc copies only the two named paired logo files into its generated assets.
    - ExDoc theme changes derive the logo variant from body.dark while keeping the README picture on device color scheme.
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
requirements-completed: []
coverage:
  - id: D1
    description: README and operator-guide introductions use the approved product category and paired lockup while retaining technical links.
    verification:
      - kind: unit
        ref: "mix verify.test readme_doc_contract_test.exs operator_surface_doc_contract_test.exs code_walkthrough_doc_contract_test.exs (38 tests)"
        status: pass
      - kind: unit
        ref: "mix verify.test persona_routing_doc_contract_test.exs (4 tests)"
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
    description: Generated ExDoc serves local assets and switches its measured sidebar logo between the approved pair.
    verification:
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors and generated asset byte comparisons"
        status: pass
      - kind: other
        ref: "C31 fresh parent-owned listener URL/root/port and index byte comparison"
        status: pass
      - kind: automated_ui
        ref: "C20 docs-plan05-fixed run, desktop-chromium, 1 passed and 1 failed"
        status: fail
    human_judgment: true
    rationale: "The browser proof failed because generated JavaScript retained the original ExDoc logo path; the parent stop rule ended browser execution after one authorized retest."
  - id: D4
    description: The example Admin serves the exact approved favicon while demo home, login, and /favicon.ico behavior remain unchanged.
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix mix test test/threadline_phoenix_web/operator_surface_test.exs (13 tests)"
        status: pass
    human_judgment: false
duration: null
completed: 2026-11-12
status: halted
---

# Phase 250 Plan 05: Brand foundation and first whole investigation Summary

**Approved README copy, the exact ten-file package asset set, and the Admin favicon shipped; generated ExDoc theme switching remains halted on an emitted-script error.**

## Performance

- **Duration:** Unknown; the parent reconciles elapsed time from the managed process receipt.
- **Started:** Unknown to this executor; parent reconciles the managed start time.
- **Completed:** 2026-11-12
- **Tasks:** 2 complete; Task 2 implementation is present but its required browser acceptance remains blocked.
- **Files modified:** 12

## Accomplishments

- Updated the README and operator-guide introductions with the approved Threadline category and Threadline Admin language; the README retains the supplied light/dark picture pair.
- Restricted the Hex package to the exact approved three SVGs, four WOFF2 files, and three font licenses. The unpacked archive contract checks raw bytes and missing, mutated, and extra-file cases.
- Replaced the example Admin favicon at its existing path with exact source bytes and tested the existing home/login /favicon.ico path and bytes.
- Generated ExDoc with local logo/favicon assets and the 96px sizing rule. The theme-switch browser acceptance did not pass; see the halted verification below.

## Task Commits

1. **Task 1: Align owned introductions** — c0e7b7be (docs)
2. **Task 1: Update the paired-logo doc contract** — 39c912d5 (test)
3. **Task 2: Add archive and generated-doc assertions** — 33e03521 (test)
4. **Task 2: Package approved assets and configure ExDoc** — 6862adbb (feat)
5. **Task 3: Update example Admin favicon bytes and response tests** — 6ec6e400 (feat)
6. **Task 2: Attempt repeated ExDoc theme switching** — 277eeac9 (fix)

**Plan metadata:** this SUMMARY commit.

## Files Created/Modified

- README.md, guides/operator-surface.md — approved intro copy and paired artwork.
- mix.exs, release-please-config.json — exact package allowlist, ExDoc assets and theme hook, and release exclusion alignment.
- test/threadline/release_artifact_contract_test.exs and related doc contracts — archive bytes and approved wording/asset references.
- examples/threadline_phoenix/e2e/tests/operator-brand-docs.spec.ts — two focused generated-doc browser cases.
- examples/threadline_phoenix/priv/static/images/threadline-admin-favicon.svg and operator_surface_test.exs — Admin favicon source and response contract.

## Decisions Made

- Keep packaged identity limited to the specified assets and licenses; repository brand guidance, TTFs, and superseded brandbook package entries stay out.
- Reuse the installed ExDoc hooks and its current asset mapping instead of adding a dependency or host-facing API.

## Deviations from Plan

### Unresolved Rule 1 issue

The first C20 run found that the theme hook only recognized ExDoc's initial /assets/logo.svg path. The parent authorized a focused correction and one fresh retest. The correction used a JavaScript regular expression inside an Elixir heredoc, which emitted a malformed pattern: /^(.*)/brand/assets/logo/threadline-lockup-(?:dark|light).svg$/. The generated hook therefore left the sidebar on assets/logo.svg. C31 passed and the favicon browser case passed, but the sidebar theme case failed again. The parent explicitly stopped further browser invocations after that retest, so this plan is halted.

### TDD sequencing deviation

Task 2 declares tdd="true", but implementation edits existed before its focused assertion runs. No valid red-first evidence was captured; the test-then-feature commit order is not claimed as TDD proof.

**Total deviations:** 0 fully resolved auto-fixes; 1 unresolved Rule 1 issue; 1 TDD sequencing deviation. **Impact:** README wording, package bytes, and Admin favicon checks pass; generated ExDoc theme switching remains unverified and is known to fail.

## Issues Encountered

- The first archive runs caught a stale SVG media-query expectation, old release exclusions, and an incomplete tracked-but-unshipped residue list. Those assertions were corrected; the final archive run passed 21 tests.
- The first ExDoc build exited successfully without copying the paired logos because the nested asset mapping did not create its destination. The mapping was narrowed to the two basenames in the existing logo target, and generated files then matched the source bytes.
- The first Admin test expected image/x-icon; the existing route responds with image/vnd.microsoft.icon. The assertion was updated to the observed unchanged MIME, and the focused test passed 13 tests.
- The initial C20 report is retained. The one parent-authorized retest is also retained with its report and trace artifacts; no further browser invocation was run.

## User Setup Required

None.

## Next Phase Readiness

Plan 05 is **halted**, not complete. Parent-owned follow-up is needed to emit valid ExDoc JavaScript, regenerate docs, and decide whether a new browser proof window is authorized. Phase-wide ADM-09/10/12 remain incomplete; loaded/blocked/disabled font proof remains with Plan 08. The parent owns shared state, final review, and service cleanup. No user action is needed unless the parent requests a new scope or verification decision.

---
*Phase: 250-brand-foundation-and-first-whole-investigation*
*Completed: 2026-11-12*

## Self-Check: FAILED

All listed files exist and all six plan commits are on this branch. The required generated ExDoc theme-switch criterion failed on the only authorized retest: the emitted inline pattern was malformed and the sidebar remained on assets/logo.svg. The archive, README contracts, Admin favicon tests, formatting, docs build, and C31 byte check passed.
