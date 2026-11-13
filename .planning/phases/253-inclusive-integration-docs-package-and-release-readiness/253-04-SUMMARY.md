---
phase: 253-inclusive-integration-docs-package-and-release-readiness
plan: "04"
subsystem: docs
tags: [admin, discovery, anchors, compatibility]
provides: ["Current README/example Admin language with preserved incoming anchors"]
requires:
  - phase: 252
    provides: "Current Admin behavior and accepted brand shell"
affects: ["253-05", "253-07", "253-09"]
tech-stack:
  added: []
  patterns: ["Preserve incoming documentation fragments with explicit anchors"]
key-files:
  created: []
  modified: [README.md, examples/threadline_phoenix/README.md, test/threadline/readme_doc_contract_test.exs, test/threadline/example_phoenix_readme_contract_test.exs, test/threadline/persona_routing_doc_contract_test.exs]
requirements-completed: []
requirements-partial: [ADM-29]
actuals:
  tokens: null
  tasks: 1
status: complete
completed: 2026-11-13
coverage:
  - id: discovery-and-anchors
    description: "Current Admin discovery preserves API/setup routing, old incoming fragments and canonical guide links"
    verification:
      - kind: integration
        ref: "mix verify.test test/threadline/readme_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/persona_routing_doc_contract_test.exs"
        status: pass
    human_judgment: false
---

# Plan04 — Current discovery without broken incoming links

README now names Threadline Admin and its record/history/coverage/operation jobs, explains capture on registered tables and supplied actor context, and replaces visible Evidence plane wording with a concrete coverage/operations heading. The existing evidence-plane and operator-surface fragments remain explicit anchors; the example also preserves mounted-operator-boundary. Technical OperatorSurface/API/route/guide names and version/setup/support boundaries remain stable. Header theme preferences are described as the actual native form; System mount behavior remains documented.

The same three existing owners first failed on the stale headings/absent new Admin destination, then passed35 tests. After explicit-anchor spacing and formatting, docs-discovery-green-02 again passed35 with0 failures; the managed receipt binds the actual README/example Markdown digests. Existing invalid-path/anchor controls remain, and the link helper recognizes both headings and explicit compatibility anchors. No adopter comprehension or rendered ExDoc/package claim is inferred. The code-walkthrough routing delimiter belongs to the already planned253-07 owner in this wave; complete current-doc acceptance is pending that batch and later package/review gates.

Task commit: 54503f39955f1ff8367ac5f901744d99227735f8. Receipts: threadline-253-docs-discovery-red-01 (35tests/6 intended stale-contract failures), green-01, format-01 and green-02. The private check helper now hashes all changed tracked/untracked file owners, including Markdown and shell, rather than only code suffixes; no permanent runner or dependency was added.

ADM-29 receives a partial contribution. No public support policy/API, asset bytes or authority changed. Continue253-05 in the same isolated context; independent copy/source review remains253-10.

## Self-Check: PASSED

Five source owners committed; current source-bound35-test result and formatting check are retained. Phase-wide requirements remain pending.
