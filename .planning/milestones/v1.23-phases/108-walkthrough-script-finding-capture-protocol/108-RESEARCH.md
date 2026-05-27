# Phase 108: Walkthrough Script + Finding-Capture Protocol — Research

**Researched:** 2026-05-27  
**Phase:** 108-walkthrough-script-finding-capture-protocol  
**Status:** Complete

## Summary

Phase 108 authors documentation and a findings protocol on top of Phase 107’s deterministic seed (`mix demo.seed` / `mix demo.reset`) and manifest SSOT. No `lib/` changes except a narrow examples-only gap fill: seed `redaction_policy` evidence so WALK-04 exercise 2 can cite a real row post-`demo.seed`.

Primary patterns to mirror: `guides/incident-playbook.md` (Question → Diagnosis → Expected output), `DEMO-MANIFEST.md` + `demo_contract_test.exs` (executable ground truth), and Phase 107’s doc-stack separation (integrator guide vs example README vs manifest vs derived runbook).

## Phase Boundary (from CONTEXT)

- **In scope:** `examples/threadline_phoenix/WALKTHROUGH.md`, `.planning/v1.23/findings/{TEMPLATE,README}.md`, examples-only seed for `redaction_policy` evidence, ROADMAP/REQUIREMENTS traceability (“four incidents”), optional `walkthrough_doc_contract_test.exs`, example README pointer to `WALKTHROUGH.md`.
- **Out of scope:** Phase 109 walking, Phase 110 fixes, `lib/threadline/**` changes, adopter-tutorial voice.

## Existing Assets

| Asset | Role for Phase 108 |
|-------|-------------------|
| `DEMO-MANIFEST.md` / `Demo.Manifest` | Literal SSOT; Appendix A copies |
| `DEMO_USERS.md` | Credentials table; extend with `agent2@acme.example.com` for WALK-03-02 |
| `demo_contract_test.exs` | Verify sections cite tests; do not duplicate asserts |
| `RetentionTail.record_evidence!/2` | Seeds `retention_run`, `retention_policy`, `trigger_coverage` — missing `redaction_policy` |
| `anchors.ex` `seed_leaving_agent_window/1` | 12 txs for `agent2@acme.example.com` — WALK-03-02 hero |
| `guides/incident-playbook.md` | Step shape precedent |
| `guides/operator-surface.md` | Route literals for Operator surface tables |

## Seed Gap Resolution (D-108-04e)

**Decision:** Close in Plan 01 (examples-only), not defer to Phase 109.

- Add `@evidence_redaction_policy_ref %{"policy" => "walk-demo-redaction-policy"}` to `Demo.Manifest` + `DEMO-MANIFEST.md`.
- In `RetentionTail.record_evidence!/2`, call `Evidence.record_redaction_policy/3` with `summary_status: "active"` and detail referencing `ticket_replies.internal_note_body` mask (matches `config :threadline, :trigger_capture` in example app).
- Extend `demo_contract_test.exs` with assertion that `mix threadline.evidence.show` (or repo query) finds `redaction_policy` with that `subject_ref` after seed.
- Expected verdict in walkthrough: `inferred_posture` (posture subject family per Evidence.Proof).

## WALKTHROUGH Structure (locked from CONTEXT)

- §0 Before you start — Phase 109 discipline, findings link, recovery `mix demo.reset`
- §1 Clean clone install (WALK-01)
- §2 Onboarding — register + seeded logins (WALK-01)
- §3 Daily use (WALK-02)
- §4 Four operator incidents (WALK-03) — table in D-108-02b
- §5 Three evidence exercises (WALK-04) — hybrid proof model
- Appendix A — demo literals (synced from manifest)
- Appendix B — command cheat sheet from README

**Step ID scheme:** Use `WALK-XX-YY` consistently (matches FINDINGS-02 `walkthrough_step` field).

## Leaving-agent persona

- Email: `agent2@acme.example.com` (from `personas.ex`, used in `anchors.ex`)
- Login for incident 2: `admin@example.com` (cross-org operator)
- Document `user_id` from manifest accessor once added to `DEMO_USERS.md`

## Operator Surface Routes (reference app)

Document capability-based paths (from `guides/operator-surface.md` + example router):

- Org-scoped timeline: `/audit` with org filter
- Actor history: `/audit/actors/user/:id` (or equivalent shipped path)
- Evidence index: `/audit/evidence`
- Policy redaction viewer: `/audit/policy/redaction`
- Coverage: `/audit/coverage`

**Do not** assert LiveView label strings; assert routes, filter keys, and semantic outcomes.

## Findings Protocol

- Directory: `.planning/v1.23/findings/` (create if missing)
- `TEMPLATE.md` — YAML frontmatter lite per D-108-05c
- `README.md` — 4-question tree + routing table + six boundary examples
- Phase 109 files: `0001-slug.md` etc. — not created in Phase 108

## ROADMAP / REQUIREMENTS Traceability

Amend in Plan 04/05:

- ROADMAP Phase 108 success criteria: “three operator scenarios” → “four WALK-03 operator incidents”
- ROADMAP Phase 109 RUN-02: same amendment
- REQUIREMENTS RUN-02: align when touched (optional in 108 if RUN-* are Phase 109 reqs only — ROADMAP is mandatory per D-108-02e)

## Doc Contract Test (discretionary)

`test/threadline_phoenix/walkthrough_doc_contract_test.exs` in example app:

- Assert `WALKTHROUGH.md` contains `4521`, `4518`, `walk-retention-offboarded-co`, `2026-05-20T14:30:00Z`, `mix demo.reset`, `WALK-03-04`
- Root `mix verify.test` may need path filter — run from example app: `mix test test/threadline_phoenix/walkthrough_doc_contract_test.exs`

## Validation Architecture

Nyquist applies: doc authoring with ExUnit contract tests and grep-verifiable plan acceptance.

| Layer | Mechanism |
|-------|-----------|
| Plan task verify | `grep`, `mix test` scoped to example app |
| Seed prerequisite | `demo_contract_test.exs` redaction_policy row |
| Walkthrough literals | `walkthrough_doc_contract_test.exs` (optional Plan 05) |
| Human | Phase 109 dry-run (out of scope for 108) |

**Wave 0:** Not required — existing `demo_contract_test.exs` infrastructure.

**Sampling:** After each plan wave, run `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs` (and walkthrough contract if added).

**Manual-only:** Full maintainer dry-run deferred to Phase 109.

## Risks

| Risk | Mitigation |
|------|------------|
| Appendix A drifts from manifest | Plan tasks require grep parity; contract test locks key literals |
| WALKTHROUGH promises missing evidence row | Plan 01 seeds `redaction_policy` before Plan 05 documents §5 |
| Brittle UI copy in steps | Operator surface tables use routes/filters only (D-108-03d) |
| `mix verify.evidence` naming mismatch | Footnote in WALKTHROUGH; canonical `mix threadline.evidence.show` |

## RESEARCH COMPLETE
