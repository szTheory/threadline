# Phase 112: Reference App Adopts Helper - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 112-reference-app-adopts-helper
**Areas discussed:** Migration breadth, Guide & doc-marker sync, Capture-only paths, Oban job return shape
**Mode:** User requested all areas + subagent research + one-shot cohesive recommendations

---

## Migration breadth

| Option | Description | Selected |
|--------|-------------|----------|
| Minimum only (Blog + HelpDesk ticket close) | Satisfies ADOPT-HELPER-01 literally | |
| Minimum + touch_post_for_job | Fixes SEED-001 linkage footgun; proves HTTP + Oban | ✓ (part of full scope) |
| Also delete_reply | Capture-only helper demo; requires lib meta fix | ✓ (part of full scope) |
| Sweep all set_config | Demo seeds, registration, scripts | |

**User's choice:** Auto-resolved via research synthesis — **four paths** (create_post, ticket_replied_and_closed, touch_post_for_job, delete_reply) plus lib bugfix for capture-only `:transaction_meta`. Explicitly exclude demo seeds and registration bootstrap.

**Notes:** django-auditlog `set_actor` + disable blocks; Carbonite transaction metadata without semantic events; PaperTrail opt-in vs trigger correctness tradeoff. Minimum-only leaves documented broken Oban pattern.

---

## Guide & doc-marker sync

| Option | Description | Selected |
|--------|-------------|----------|
| A — Replace legacy; marker → helper in blog.ex | Single golden path; example SSOT | ✓ |
| B — Helper primary + full manual appendix | Two fenced blocks; drift risk | |
| C — Marker in lib/threadline/audit.ex | Breaks example↔guide contract | |

**User's choice:** Option A with B-lite link-out to integration-contracts (no second fenced block).

**Notes:** Phase 47 D-03 locks markers in example app. getting_started_saas_doc_contract_test.exs built around blog_block() extract. ExAudit/django-auditlog keep manual paths outside quickstart.

---

## Capture-only paths (delete_reply)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Helper without :action | GUC dedup only; meta gap today | |
| B — Leave hand-rolled GUC | Intentional contrast | |
| C — Helper + capture_only: true | Explicit intent; needs lib meta fix | ✓ |

**User's choice:** Option C with prerequisite lib extension for capture-only `:transaction_meta`. Preserve `{:ok, :deleted}` public return. No `:ticket_reply_deleted` action (D-107-05d).

**Notes:** Fake action names blur capture/semantics layers. Two patterns in HelpDesk confuses adopters. audit.ex finalize_success only applies meta in link_action branch today.

---

## Oban job return shape

| Option | Description | Selected |
|--------|-------------|----------|
| A — Keep {:ok, %Post{}} | Worker unchanged; strips audit handle | |
| B — {:ok, %{post:, audit_transaction_id:}} | Matches create_post envelope | ✓ |
| C — Opt-in return_audit: true | Two return shapes; rejected | |

**User's choice:** Option B. PostTouchWorker stays at :ok. Callback returns `%{post: updated}` for map-merge.

**Notes:** Naive struct callback yields ugly `%{result: post, ...}`. COMP-01 incident path needs audit_transaction_id. Conditional return APIs violate OSS single-blessed-pattern DNA.

---

## Claude's Discretion

- with/case nesting in migrated functions
- Optional doc marker rename
- Correlation timeline assertion beyond action_id linkage in worker test

## Deferred Ideas

- Demo seed set_config sweep
- provision_default_workspace audit wrapping
- :ticket_reply_deleted semantic action
