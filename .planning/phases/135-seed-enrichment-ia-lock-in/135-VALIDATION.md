---
phase: 135
slug: seed-enrichment-ia-lock-in
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-03
---

# Phase 135 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seed-only + docs phase: the validation surface is doc-contract tests + a seed in-window guarantee assertion + a seed-only diff guard. Derived from `135-RESEARCH.md` § Validation Architecture.
> Task IDs bound to concrete plans/tasks on 2026-06-03 (planner). Form: `{plan}-T{task}` within phase 135.

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
| 01-T1 (D-07 generalize) | 135-01 | 1 | POLISH-SEED | T-135-02 | 6-kind-guarded GUC, no :integration | compile | `cd examples/threadline_phoenix && mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 01-T2 (actor literals) | 135-01 | 1 | POLISH-SEED | T-135-01 | no real secrets/PII (synthetic ids) | unit | `mix test test/threadline_phoenix/demo_manifest_test.exs` | ✅ | ⬜ pending |
| 01-T3 (D-05 personas fix) | 135-01 | 1 | POLISH-SEED | — | setup tx actor_ref non-null + backdated outside 24h | integration | `mix test test/threadline_phoenix/demo_contract_test.exs` | ✅ extend | ⬜ pending |
| 02-T1 (IA lock + EF1–EF5 + pointer) | 135-02 | 1 | POLISH-SEED | T-135-02D | N/A | doc-contract (data) | `grep -F EF1..EF5 / pointer` then 02-T2 | ✅ | ⬜ pending |
| 02-T2 (IA doc-contract test) | 135-02 | 1 | POLISH-SEED | T-135-02D | N/A | doc-contract | `mix test test/threadline/ia_lock_doc_contract_test.exs` | ❌ W0→created | ⬜ pending |
| 03-T1 (in-window 5/4/2 + D-13) | 135-03 | 2 | POLISH-SEED | T-135-03, T-135-04 | ≥1 UPDATE + ≥1 DELETE in 24h window; [REDACTED] preserved | integration | `mix test test/threadline_phoenix/demo_contract_test.exs` | ✅ extend | ⬜ pending |
| 03-T2 (filler DELETE branch) | 135-03 | 2 | POLISH-SEED | — | corpus op-mix ~55/35/10, deterministic | integration | `mix test test/threadline_phoenix/demo_contract_test.exs` | ✅ extend | ⬜ pending |
| 03-T3 (SavedView seed F-204) | 135-03 | 2 | POLISH-SEED | — | ≥1 SavedView for admin actor_ref; no schema/route diff | integration | `mix test test/threadline_phoenix/demo_contract_test.exs` | ✅ extend | ⬜ pending |
| 04-T1 (recipe table + literals) | 135-04 | 3 | POLISH-SEED | T-135-05, T-135-06 | example.com logins only, no secrets | doc-contract (data) | `grep -c "State recipes"` then 04-T2 | ✅ | ⬜ pending |
| 04-T2 (recipe doc-contract test) | 135-04 | 3 | POLISH-SEED | T-135-05 | N/A | doc-contract | `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` | ❌ W0→created | ⬜ pending |
| (seed-only diff guard) | 135-04 | 3 | POLISH-SEED | — | no schema/route/biz-logic file touched | review/manual | `git diff --name-only main` | manual | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*The two new doc-contract files (`ia_lock_doc_contract_test.exs`, `demo_manifest_contract_test.exs`) are created in their owning plans (02/04) — they are the Wave-0 test infra for this phase. The D-13 assertion extends the existing `demo_contract_test.exs` in 03-T1; an actor-attribution assertion extends it in 01-T3.*

---

## Three Validation Surfaces

### Surface 1 — Recipe-table doc-contract (D-03)
- **File (new, created in 04-T2):** `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs`
- **Exemplar:** `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs`
- **Asserts:** `DEMO-MANIFEST.md` contains the per-state recipe table header + ≥3 screen-state-login triples (e.g. `offboarded-co.example.com`, `empty`) + named actor literals + the Phase-138 deferral note.
- **Note:** separate from existing `demo_manifest_test.exs` (which tests the `Manifest` Elixir module, not the `.md`).
- **Signal:** `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` green.

### Surface 2 — IA-IDs doc-contract (D-18)
- **File (new, created in 02-T2):** `test/threadline/ia_lock_doc_contract_test.exs` (library suite, alongside other `*_doc_contract_test.exs`).
- **Asserts (~15):** `v1.31-PERSONAS-IA.md` contains `P1..P5`, `J1..J11`, `EF1..EF5`, the `Find/Verify/Prove` triad string; `v1.31-UI-AUDIT.md` contains the D-17 pointer line.
- **Sequencing constraint:** `EF1–EF5` do **not** exist in `v1.31-PERSONAS-IA.md` today (RESEARCH-verified). 02-T1 (write EF IDs + J1–J11 reconcile) MUST land before 02-T2 — both are in the SAME plan (135-02), 02-T1 before 02-T2, so they pass together.
- **Signal:** `mix verify.test` (project root) passes all `ia_lock_doc_contract_test.exs` assertions.

### Surface 3 — Seed in-window guarantee (D-13)
- **File (extend existing, in 03-T1):** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — add a `describe "D-13 in-window variety guarantee"` block.
- **Asserts:** after seed, ≥1 `update` and ≥1 `delete` `AuditChange` with `transaction.occurred_at >= utc_now() - 24h`.
- **Determinism:** assertion is window-relative; variety-pack rows use `DateTime.utc_now() |> DateTime.add(-N, :hour)` (N ≤ 6, per `seed_active_agent_window` in `anchors.ex:56`) → always in-window, stable across CI run times. In-window rows DO call `put_timestamp` with a wall-clock-recent VALUE (PATTERNS correction: it is a timestamp-value choice, not a put_timestamp skip).
- **Prerequisite:** 03-T1 depends on 135-01 (`set_actor_guc!/2`, `set_anonymous_actor_guc!/0`, `Manifest.actor_id/1`).
- **Signal:** `mix test test/threadline_phoenix/demo_contract_test.exs` (`@moduletag :demo_contract`, live DB, `async: false`, unboxed).

---

## Wave 0 Requirements (test infra created within owning plans)

- [ ] `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` — D-03 recipe-table assertions (created in 04-T2)
- [ ] `test/threadline/ia_lock_doc_contract_test.exs` — D-18 IA-ID assertions (created in 02-T2); **02-T1 writes EF1–EF5 + reconciles J1–J11 first, same plan**
- [ ] Extend `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — D-13 in-window variety assertion (03-T1) + D-05 actor-attribution assertion (01-T3)

*Existing infrastructure (ExUnit, `demo_contract_test.exs` unboxed seed harness) covers the integration surface; the two new doc-contract files are the only net-new test infra.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Seed-only diff guard (criterion #3) | POLISH-SEED | No clean automated proof that a change is "seed-only"; needs human/review judgment over the file set | `git diff --name-only main` — confirm every path is under `examples/threadline_phoenix/lib/threadline_phoenix/demo/`, `DEMO-MANIFEST.md`, `.planning/milestones/v1.31-*.md`, or `test/`. Zero schema/migration/router/LiveView/business-logic files. |
| Per-screen state reachability (criterion #1) | POLISH-SEED | "Drive each screen to empty/long/variety/edge" is a UI walkthrough, not a unit assertion (renders defer to 136–143) | After `mix demo.reset && mix demo.seed`, follow each recipe-table row (login as X, open path Y, apply filter Z) and confirm the documented state renders. |

*Determinism, in-window variety, actor attribution, and IA IDs all have automated verification (Surfaces 1–3 + 01-T3).*

---

## Validation Sign-Off

- [x] All tasks have an automated verify or a Wave 0 dependency (two manual-only items justified above; doc-data tasks 02-T1/04-T1 are gated by their paired doc-contract test 02-T2/04-T2)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers both new doc-contract files + the D-13 assertion extension
- [x] No watch-mode flags
- [x] Feedback latency < 90s (full) / < 5s (quick)
- [x] `nyquist_compliant: true` set in frontmatter (map bound to concrete task IDs 01-T1..04-T2)

**Approval:** planner-bound 2026-06-03; checker to confirm.
