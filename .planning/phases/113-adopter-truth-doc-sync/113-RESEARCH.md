# Phase 113: Adopter Truth & Doc Sync — Research

**Researched:** 2026-05-27  
**Phase:** 113 — Adopter Truth & Doc Sync  
**Status:** Complete

## Summary

Phase 113 closes reference and documentation drift for 0.5.x evaluators: wire admin-only `evidence_authorize_fn` on the sigra-reference mount, sync adoption-pilot version literals to **0.5.0** / `~> 0.5`, lock canonical evidence CLI naming (`mix threadline.evidence.show` only), fix WALK-03-02 operator fiction (WR-110-001), and add doc-contract tests wired into `mix verify.doc_contract`. No `lib/` changes unless an alias were added — CONTEXT locks **no** `mix verify.evidence` alias.

**Scope guard:** `examples/threadline_phoenix/`, `guides/`, doc-contract tests, living `.planning/PROJECT.md` + `.planning/MILESTONES.md`, v1.23 errata blocks. No new Evidence subjects.

---

## 1. TRUTH-01 — Evidence mount authorization gap

### Current state (`router.ex:134-145`)

Mount passes `actor_fn`, `authorize_fn`, `export_authorize_fn`, `scope_query_fn` — **no** `evidence_authorize_fn`. Library default is fail-closed (`auth.ex:253-254`):

```elixir
evidence_authorize_fn = Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)
```

Result: admin walkthrough steps WALK-03-03, WALK-04-* that open `/audit/evidence` hit **Unsupported View** despite prose implying admin access.

### Target (D-113-01)

| Item | Action |
|------|--------|
| `my_evidence_authorize_fn/1` | Add beside `my_export_authorize_fn/1` at `router.ex:84-89` pattern — admin-only `:ok`, else `{:error, :unauthorized}` |
| Mount opt | `evidence_authorize_fn: &ThreadlinePhoenixWeb.Router.my_evidence_authorize_fn/1` inside `# doc: start/end: operator-surface-mount` block |
| Locked callbacks | Do **not** change `my_authorize_fn/1`, `my_export_authorize_fn/1`, `scope_query_fn/3` (Phase 106 lock) |
| Docs | `examples/threadline_phoenix/README.md` mount snippet + prose: admin reaches `/audit/evidence`; support denied → Unsupported View + `mix threadline.evidence.show` |
| Guide | `guides/getting-started-saas.md` mount snippet (lines ~201-207) + paragraph after export/coverage section citing evidence gate |
| Optional test | Extend `operator_surface_test.exs` or new `evidence_mount_test.exs`: admin GET `/audit/evidence` ≠ unsupported; support sees `"Evidence view unavailable."` |

### Session matrix (from CONTEXT)

| Session | `/audit` | `/audit/evidence` | CLI |
|---------|----------|-------------------|-----|
| Admin | Cross-org | Enabled | `mix threadline.evidence.show` |
| Support | Org-scoped | Unsupported View | Same CLI |
| Agent | 403 pipeline | N/A | N/A |

### Doc-contract touchpoints

- `test/threadline/getting_started_saas_doc_contract_test.exs` — assert `evidence_authorize_fn` in mount marker block
- `test/threadline/example_phoenix_readme_contract_test.exs` — assert `my_evidence_authorize_fn` in router + README mount snippet
- `test/threadline/integration_contracts_doc_contract_test.exs` — already asserts `evidence_authorize_fn` in guide (line 93)

---

## 2. TRUTH-02 — Adoption-pilot version drift

### Current state (`guides/adoption-pilot-backlog.md:11-13`)

| Row | Current (stale) | Target |
|-----|-----------------|--------|
| Hex version | **0.2.0** | **0.5.0** (matches `mix.exs` `@version "0.5.0"`) |
| Dep constraint | `~> 0.2` | `~> 0.5` |
| Evidence pointer | `readme_doc_contract_test.exs` only | Add `adoption_pilot_doc_contract_test.exs` |

### Target edits (D-113-03)

- **Distribution preflight table only** — not ExampleCloud matrix, test-count prose, or Evidence pass date
- One orientation sentence: distribution preflight reflects tree **0.5.x** (`mix.exs` SSOT); lane story in `guides/upgrade-path.md`
- New test `test/threadline/adoption_pilot_doc_contract_test.exs`:
  - `expected = MixProject.project()[:version]`
  - assert guide contains `"#{expected}"` and `"~> 0.5"`
  - refute `0.2.0`, `~> 0.2`
  - optionally assert cross-link to `guides/upgrade-path.md`

### Wire into verify

Add to `mix.exs` `verify.doc_contract` alias list (line ~81).

---

## 3. TRUTH-03 — Evidence CLI naming

### Canonical vs drift

| Surface | Canonical | Drift to fix |
|---------|-----------|--------------|
| Runnable task | `lib/mix/tasks/threadline.evidence.show.ex` | — |
| Guides | `operator-surface.md:130`, `domain-reference.md:77` | Already canonical |
| WALKTHROUGH §5 | Footnote at line 570 mentions `verify.evidence` | Tighten to past tense: alias **never shipped** |
| `.planning/PROJECT.md` | Lines 38, 64, 284 dual naming | Canonical only + footnote |
| `.planning/MILESTONES.md` | Line 50 dual naming | Same |
| v1.23 archive | `v1.23-REQUIREMENTS.md:59` WALK-04 checkbox | 2-line errata block (D-113-05c), do not rewrite checkbox |
| `mix.exs` aliases | No `verify.evidence` | Refute in contract test |
| README | `readme_doc_contract_test.exs:63` refutes `mix threadline.evidence.show` in compact strip | Keep refute on both CLI strings |

### New doc contract (`test/threadline/evidence_cli_doc_contract_test.exs`)

Assert/refute per D-113-02e:

- `guides/domain-reference.md`, `guides/operator-surface.md` — assert `mix threadline.evidence.show`; refute `mix verify.evidence`
- `examples/threadline_phoenix/WALKTHROUGH.md` — assert canonical in command blocks; allow **at most one** footnote `verify.evidence` (or refute after cleanup)
- Root `mix.exs` — refute `"verify.evidence":`
- `README.md` — refute both `mix verify.evidence` and `mix threadline.evidence.show` (compact strip unchanged)

Wire into `verify.doc_contract` alias.

---

## 4. TRUTH-04 — WALK-03-02 prose + contracts (WR-110-001)

### Current drift (`WALKTHROUGH.md:451-464`)

**Operator question (wrong):** "…in the **last 24 hours** before offboard?"

**Expected outcome (overclaim):** "multiple **ticket/reply** mutations"

### Seed truth (`anchors.ex:95-120`)

- `@leaving_agent_tx_count 12` ticket status updates only (`tickets` table)
- No `ticket_replies` in leaving-agent window
- Bounds: `Manifest.last_tuesday()` → `Manifest.epoch()` (same as step 2 prose at lines 458-459)

### Target prose (D-113-04a/b)

**Operator question:**

> **Operator question:** Agent **`agent2@acme.example.com`** is leaving — what did they touch from **`demo_last_tuesday`** through **`demo_epoch`**?

**Expected outcome:** ticket **status** changes on **`tickets`** only — remove ticket/reply overclaim.

**Step 4:** Scan for `tickets` table activity (not `ticket_replies`).

### Contract hardening

| Test file | Change |
|-----------|--------|
| `walkthrough_doc_contract_test.exs` | Add literals: `demo_last_tuesday`, `demo_epoch`, `33123cc4-da21-5674-b030-e168cee90521` |
| `demo_contract_test.exs` `"SEED-03 leaving agent window"` | `assert count == 12`; join `audit_changes` where `table_name == "tickets"` ≥ 1; use `Manifest.last_tuesday()` / `Manifest.epoch()` for bounds |

Do **not** lock full operator-question prose or `"last 24 hours"` in contract (avoid brittle prose lock).

---

## 5. TRUTH-05 / D-113-05 — Verification + planning hygiene

### Closeout gates

```bash
mix verify.doc_contract   # includes new evidence_cli + adoption_pilot tests
mix verify.example        # walkthrough + demo_contract after WALK-03-02
```

Both must be green for TRUTH-05.

### Planning doc scope (D-113-05)

| Target | Action |
|--------|--------|
| `.planning/PROJECT.md`, `.planning/MILESTONES.md` | Canonical CLI only + global footnote |
| `.planning/milestones/v1.23-REQUIREMENTS.md` WALK-04 | 2-line errata atop section |
| `.planning/milestones/v1.23-ROADMAP.md` WALK-04 criteria | Same errata pattern |
| **Immutable** | `.planning/milestones/v1.22-phases/**`, Phase 107/108 discussion artifacts, `RETROSPECTIVE.md` body |

---

## 6. Validation Architecture (Nyquist Dimension 8)

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (root + example app) |
| **Config** | `test/test_helper.exs`, `examples/threadline_phoenix/config/test.exs` |
| **Doc contract gate** | `mix verify.doc_contract` |
| **Example gate** | `mix verify.example` |
| **Full CI** | `mix ci.all` |
| **Estimated quick runtime** | Targeted tests ~10–30s each; full verify ~2–3 min |

### Per-wave sampling

| Wave | Delivers | Automated command | Requirement |
|------|----------|-------------------|-------------|
| 1 / Plan 01 | Evidence mount + docs | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs` (+ evidence test if added) | TRUTH-01 |
| 1 / Plan 02 | WALK-03-02 + demo/walk contracts | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/walkthrough_doc_contract_test.exs` | TRUTH-04 |
| 1 / Plan 03 | Adoption-pilot table + test | `mix test test/threadline/adoption_pilot_doc_contract_test.exs` | TRUTH-02 |
| 2 / Plan 04 | Evidence CLI contracts + planning errata + verify wiring | `mix verify.doc_contract && mix verify.example` | TRUTH-03, TRUTH-05, TRUTH-05 adjunct |
| Closeout | Full phase | `mix ci.all` or `mix verify.example && mix verify.doc_contract && mix verify.test` | TRUTH-05 |

**Sampling rule:** Run wave command after each plan; run closeout before `/gsd-verify-work`.

---

## 7. Dependencies, risks, wave grouping

### Dependencies

| Dependency | Status |
|------------|--------|
| Phase 112 complete (helper on write paths) | ✅ |
| `mix threadline.evidence.show` shipped | ✅ |
| `Threadline.OperatorSurface.EvidenceLiveTest` lib patterns | ✅ Reference for optional example test |
| Phase 106 authorize_fn lock | ✅ — evidence is additive opt only |

### Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Support accidentally granted evidence scope | High | Admin-only callback; do not reuse export fn; document denial |
| Doc contract brittleness on WALKTHROUGH prose | Medium | Lock literals only, not full operator question |
| Adoption-pilot scope creep (ExampleCloud matrix) | Medium | D-113-03d scope guard in plan |
| Planning archive silent rewrite | Low | Errata blocks only on v1.23 closed milestone files |

### Recommended plan split (4 plans, 2 waves)

| Plan | Wave | Requirements | Primary files |
|------|------|--------------|---------------|
| 01 | 1 | TRUTH-01 | `router.ex`, README, getting-started, operator tests |
| 02 | 1 | TRUTH-04 | `WALKTHROUGH.md`, `demo_contract_test.exs`, `walkthrough_doc_contract_test.exs` |
| 03 | 1 | TRUTH-02 | `adoption-pilot-backlog.md`, `adoption_pilot_doc_contract_test.exs`, `mix.exs` |
| 04 | 2 | TRUTH-03, TRUTH-05, D-113-05 | evidence CLI test, WALKTHROUGH §5 footnote, PROJECT/MILESTONES, v1.23 errata, closeout verify |

Plans 01–03 are parallelizable (disjoint file sets). Plan 04 depends on 01–03 for consistent doc surface before final `verify.*` gate.

---

## RESEARCH COMPLETE
