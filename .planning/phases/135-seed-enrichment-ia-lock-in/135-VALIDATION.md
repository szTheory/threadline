---
phase: 135
slug: seed-enrichment-ia-lock-in
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-03
---

# Phase 135 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seed-only + docs phase: the validation surface is doc-contract tests + a seed in-window guarantee assertion + a seed-only diff guard. Derived from `135-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir standard) |
| **Config file** | `examples/threadline_phoenix/test/test_helper.exs` (demo app); `test/test_helper.exs` (library) |
| **Quick run command** | `cd examples/threadline_phoenix && mix verify.format` |
| **Full suite command** | `mix ci.all` (project root) — runs library `verify.test` + demo-app suite |
| **Estimated runtime** | ~30–90 seconds (demo-contract tests run live-DB, `async: false`, unboxed) |

---

## Sampling Rate

- **After every task commit:** `cd examples/threadline_phoenix && mix verify.format` (fast; no DB needed)
- **After every plan wave:** `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs && mix verify.test`
- **Before `/gsd:verify-work`:** `mix ci.all` from project root must be green
- **Max feedback latency:** ~90 seconds (full suite); ~5 seconds (format/quick)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (IA lock) | TBD | 0 | POLISH-SEED | — | N/A | doc-contract | `mix verify.test` (`ia_lock_doc_contract_test.exs`) | ❌ W0 | ⬜ pending |
| (recipe table) | TBD | — | POLISH-SEED | — | N/A | doc-contract | `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` | ❌ W0 | ⬜ pending |
| (actor-kind generalize) | TBD | — | POLISH-SEED | — | actor_ref populated, not null on setup tx | integration | `mix test test/threadline_phoenix/demo_contract_test.exs` | ✅ extend | ⬜ pending |
| (in-window variety) | TBD | — | POLISH-SEED | — | ≥1 UPDATE + ≥1 DELETE in default 24h window | integration | `mix test test/threadline_phoenix/demo_contract_test.exs` | ✅ extend | ⬜ pending |
| (seed-only diff) | TBD | — | POLISH-SEED | — | no schema/route/biz-logic file touched | review/manual | `git diff --name-only` | manual | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Task IDs are placeholders — the planner fills concrete `{NN-NN-NN}` IDs and binds each to its plan/wave.*

---

## Three Validation Surfaces

### Surface 1 — Recipe-table doc-contract (D-03)
- **File (new, Wave 0):** `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs`
- **Exemplar:** `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs`
- **Asserts:** `DEMO-MANIFEST.md` contains the per-state recipe table header + ≥3 screen-state-login triples (e.g. `offboarded-co.example.com`, `empty`).
- **Note:** separate from existing `demo_manifest_test.exs` (which tests the `Manifest` Elixir module, not the `.md`).
- **Signal:** `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` green.

### Surface 2 — IA-IDs doc-contract (D-18)
- **File (new, Wave 0):** `test/threadline/ia_lock_doc_contract_test.exs` (library suite, alongside other `*_doc_contract_test.exs`).
- **Asserts (~15):** `v1.31-PERSONAS-IA.md` contains `P1..P5`, `J1..J11`, `EF1..EF5`, the `Find/Verify/Prove` triad string; `v1.31-UI-AUDIT.md` contains the D-17 pointer line.
- **Sequencing constraint:** `EF1–EF5` do **not** exist in `v1.31-PERSONAS-IA.md` today (RESEARCH-verified). D-16 (write EF IDs) MUST land before/with this test or the EF assertions fail. Same for the J1–J11 reconciliation (D-19).
- **Signal:** `mix verify.test` (project root) passes all `ia_lock_doc_contract_test.exs` assertions.

### Surface 3 — Seed in-window guarantee (D-13)
- **File (extend existing):** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — add a `describe "D-13 in-window variety guarantee"` block.
- **Asserts:** after seed, ≥1 `update` and ≥1 `delete` `AuditChange` with `transaction.occurred_at >= utc_now() - 24h`.
- **Determinism:** assertion is window-relative; variety-pack rows use `DateTime.utc_now() |> DateTime.add(-N, :hour)` (N ≤ 6, per `seed_active_agent_window` in `anchors.ex:56`) → always in-window, stable across CI run times. In-window rows must NOT enter `ctx.timestamps` (Temporal.run leaves wall-clock rows untouched by design).
- **Signal:** `mix test test/threadline_phoenix/demo_contract_test.exs` (`@moduletag :demo_contract`, live DB, `async: false`, unboxed).

---

## Wave 0 Requirements

- [ ] `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` — D-03 recipe-table assertions (new)
- [ ] `test/threadline/ia_lock_doc_contract_test.exs` — D-18 IA-ID assertions (new); **depends on D-16 writing EF1–EF5 + D-19 J1–J11 reconcile first**
- [ ] Extend `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — D-13 in-window variety assertion (extend existing)

*Existing infrastructure (ExUnit, `demo_contract_test.exs` unboxed seed harness) covers the integration surface; the two new doc-contract files are the only net-new test infra.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Seed-only diff guard (criterion #3) | POLISH-SEED | No clean automated proof that a change is "seed-only"; needs human/review judgment over the file set | `git diff --name-only main` — confirm every path is under `examples/threadline_phoenix/lib/threadline_phoenix/demo/`, `DEMO-MANIFEST.md`, `.planning/milestones/v1.31-*.md`, or `test/`. Zero schema/migration/router/LiveView/business-logic files. |
| Per-screen state reachability (criterion #1) | POLISH-SEED | "Drive each screen to empty/long/variety/edge" is a UI walkthrough, not a unit assertion (renders defer to 136–143) | After `mix demo.reset && mix demo.seed`, follow each recipe-table row (login as X, open path Y, apply filter Z) and confirm the documented state renders. |

*Determinism, in-window variety, and IA IDs all have automated verification (Surfaces 1–3).*

---

## Validation Sign-Off

- [ ] All tasks have an automated verify or a Wave 0 dependency (two manual-only items justified above)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers both new doc-contract files + the D-13 assertion extension
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s (full) / < 5s (quick)
- [ ] `nyquist_compliant: true` set in frontmatter (planner/checker flips this once the map is bound to concrete task IDs)

**Approval:** pending
