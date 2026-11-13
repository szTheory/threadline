---
phase: 253-inclusive-integration-docs-package-and-release-readiness
plan: "06"
subsystem: docs
tags: [brand, history, tokens, contrast, provenance]
requires:
  - phase: 250
    provides: "Approved brand palette in functional styles"
provides: ["Current four-source brand authority and explicit superseded historical provenance"]
affects: ["253-03", "253-09", "253-10"]
tech-stack:
  added: []
  patterns: ["Keep historical token/artifact bytes separate from current runtime authority"]
key-files:
  created: []
  modified: [DESIGN-SYSTEM.md, brandbook/README.md, brandbook/brand-book.md, brandbook/pressure-test.md, test/threadline/brandbook_token_parity_test.exs]
requirements-completed: []
requirements-partial: [ADM-29, ADM-30]
actuals:
  tokens: null
  tasks: 1
status: complete
completed: 2026-11-13
coverage:
  - id: authority-and-history
    description: "Current approved sources are discoverable while historical content and runtime token responsibility remain distinct"
    verification:
      - kind: unit
        ref: "test/threadline/brandbook_token_parity_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/stress_ledger_test.exs"
        status: pass
    human_judgment: false
---

# Plan06 — Current authority, preserved history

The design-system introduction links brand/BRAND.md, brand/brand.json, brand/tokens.json and brand/assets/README.md as current authority. Its original heading fragment remains, and ledger scores/cohorts are explicitly historical inventory metadata rather than current acceptance. Functional spacing and gap aliases stay owned by the existing stylesheet.

Three brandbook documents now carry a superseded, unshipped-history banner. Removing only that banner reproduces each original document byte-for-byte; historical tokens and asset paths are unchanged. Every ledger table row is unchanged. Old tests no longer promote retired brandbook theming or token aliases to current authority. They retain provenance and original dual-mode evidence, enforce functional numeric/gap aliases in the stylesheet, and keep those aliases out of approved brand data. The approved both-theme contrast, operation/control-role code and mutation controls are byte-unchanged.

The intended red run failed2 of6 authority/provenance assertions. After guidance updates and formatting,6 brand checks plus9 existing ledger/projection checks passed15/15. Preservation receipt: threadline-253-brand-history-preservation.json. Managed receipts: docs-brand-authority-red-01, docs-brand-format-01 and docs-brand-authority-01. No runtime CSS, approved token data, logo/font bytes or public API changed.

Task commit: 1849a472252bcb3c3f3c5d15ec423c3c7219840a. ADM-29/30 receive partial contributions; complete current-doc/package/visual acceptance remains pending. Continue253-07 in the same context. Independent copy/source review remains253-10; no routine human UAT or new authority is inferred.

## Self-Check: PASSED

Five planned owners committed, exact history/control preservation checked, and current15-test proof retained.
