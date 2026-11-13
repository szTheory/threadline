---
phase: 251-complete-investigation-and-inspection-screens
plan: "03"
subsystem: ui
status: complete
completed: 2026-11-13
requirements-completed: []
provides:
  - "Selected-schema Coverage rows/header share the successful snapshot and checked time"
  - "Invalid, empty, stale, unavailable, disabled and denied meanings remain distinct"
  - "Measured narrow Coverage and history Close layout correction"
key-files:
  modified:
    - lib/threadline/operator_surface/live/coverage_live.ex
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/operator_surface/ui/page.ex
    - lib/threadline/operator_surface/style/08_overlays_motion.css
---

# Plan03 — Selected Coverage inspection

Coverage's header now projects the selected successful snapshot, with explicit schema and inspection limits. Empty/expected-only results imply no global completeness. Malformed structured schema input produces a safe correction state; unexpected raw errors remain hidden. Same-schema stale and changed-schema failures retain their separate existing meanings.

The final owning gate passed191 selected ExUnit tests, existing Node evidence controls passed32 cases, and named formatting plus warnings-as-errors compile passed. Four affected mounted cases passed together first attempt with retries disabled, including the selected long-schema/remediation flow, availability boundaries, existing badge control and keyboard history Close. [Pair evidence](251-PAIR-EVIDENCE.md) records the two matched four-image pairs, unchanged business materialization and proof limits.

The shared Close correction moved forward from Plan04 into the measured layout batch. Grid intrinsic minimum width caused narrow Coverage overflow; shrinking header text had wrapped Close into five lines. The existing stylesheet now permits the content column to shrink/wrap and keeps the Close control intact. Historical renderer receipts, unrelated structure pins and negative controls remain intact; the golden/full-style pins changed only with this attributed CSS batch.

Initial expected regression failures, a browser fixture assumption that an empty schema appears in the table-based picker, a dirty-source startup rejection, coupled old-copy/structure failures and narrow geometry failures remain retained. Corrected checks use the real supported picker/direct-empty paths, exact committed startup source and unchanged assertions. No timeout, scope boundary or full-repeat budget was expanded.

Independent phase source/security/UI/goal reviews remain pending in Plan04. Requirements are not marked complete here. Continue Redaction/Evidence in this isolated checkout; no user action is needed.

## Self-Check: PASSED

Current source, passed receipt exits, exact mounted outcomes and both PNG pairs were reconciled before this summary. Native clipboard, zoom, full-root and hosted results are not established.
