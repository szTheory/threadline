---
phase: 251-complete-investigation-and-inspection-screens
plan: "04"
subsystem: ui
status: complete
completed: 2026-11-13
requirements-completed: ["ADM-21", "ADM-22"]
provides:
  - "Current configured/deployed policy comparison without zero-policy assurance"
  - "Explicit snapshot recording time and bounded caller-overridable provenance"
  - "Working direct-entry Evidence copy with controlled full-value proof"
  - "Independent source/security/UI review and bounded correction disposition"
key-files:
  modified:
    - lib/threadline/operator_surface/live/policy_redaction_live.ex
    - lib/threadline/operator_surface/live/evidence_live.ex
    - lib/threadline/operator_surface/style/03_page_home.css
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
  created:
    - .planning/phases/251-complete-investigation-and-inspection-screens/251-REVIEW.md
    - .planning/phases/251-complete-investigation-and-inspection-screens/251-SECURITY.md
    - .planning/phases/251-complete-investigation-and-inspection-screens/251-UI-REVIEW.md
    - .planning/phases/251-complete-investigation-and-inspection-screens/251-REVIEW-DISPOSITION.md
---

# Plan04 — Policy definitions and recorded operational snapshots

Redaction names current host configuration versus deployed trigger source and successful inspection time; unexpected errors are safe/unavailable, malformed schema input is correctable, and zero configured policy never claims a match. Only explicit selected-schema configuration keys enter the comparison; deployed-but-unconfigured tables are counted separately. Left out, Redacted and Replacement remain distinct from stored-value claims and historical/export correctness.

Evidence labels snapshot recording time, retains selected latest versus append-only history and projects only exact subject/writer-entrypoint metadata into bounded constant copy with an explicit caller-overridable identity limitation. Unknown metadata, arbitrary detail and actor values remain hidden. Direct entry now enables the existing shared copy handler, while embedded-script opt-out preserves full selectable values without inert copy buttons.

[Pair evidence](251-PAIR-EVIDENCE.md) records current exact single-case retries-disabled passes, a coupled three-case affected batch, eight matched inspection images per half and two matched Home images per half. Audit materialization is unchanged. Initial97 owning tests passed; the review correction gate passed155/156 with one outdated fixture expectation, followed by a passed bounded18-case policy retest. Existing32 Node controls, warnings-as-errors compile and named format passed. No full-root repeat is claimed.

[Review disposition](251-REVIEW-DISPOSITION.md) links clean40-file source review,14-threat secured audit with zero risk acceptance and22/24 UI review. Actual review caught and corrected the zero-config/deployed semantic bug and Home typography mismatch; its badge/citation errors were checked against evidence and corrected. Existing shared palette and uncaptured broad error/zoom/inclusive evidence remain explicit Phase253 work. Engine flags retain their actual unresolved statuses. Independent whole-phase goal verification subsequently passed63/63 truths and all six requirements; requirement completion is reconciled by the phase owner, not inferred from this plan summary.

## Deviations and lessons

The [bounded continuation](251-04-BOUNDARY-CONTINUATION.md) retains wrong-checkout/test-setup/reporter/locator failures and the actual Evidence copy defect. The first script-binding failure was diagnosed from the existing source owner, not treated as timing. The presenter API, runtime/public config, routes, schemas and locks remain unchanged. The [run retrospective](../../research/2026-11-12-autonomous-run-retrospective.md) remains in progress until actual autonomous closeout; lessons are retained now and must be finalized and linked at the end.

## Self-Check: PASSED

Current source/capture/report identities and scoped outcomes were reconciled; independent review findings have dispositions. This completes the plan's implementation/review tasks, and its independent phase goal check; release readiness remains separate. No user action is needed.


## Final milestone traceability writeback

This plan's declared requirement contributions are now reflected in `requirements-completed`, following the independently passed phase goal and final34-requirement integration check/current candidate CI. Earlier empty completion fields were local contribution bookkeeping, not a new missing implementation. Historical results remain preserved; the bounded successor-impact verification owns current fingerprint freshness.
