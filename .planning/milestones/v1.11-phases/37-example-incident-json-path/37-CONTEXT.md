# Context: Phase 37 — Example incident JSON path

## Goal
Prove a **copy-pasteable** HTTP JSON composition on **`Threadline.audit_changes_for_transaction/2`** + **`Threadline.change_diff/2`** in **`examples/threadline_phoenix/`**.

## Requirements
- **COMP-01**: `POST /api/posts` returns `audit_transaction_id`.
- **COMP-02**: `GET /api/audit_transactions/:id/changes` returns ordered changes with diffs.
- **COMP-03**: Documentation and contract tests in `guides/domain-reference.md`.

## Evidence
- Controller: `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex`
- Test: `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs`
- Doc Anchor: `COMP-EXAMPLE-INCIDENT-JSON` in `guides/domain-reference.md`
