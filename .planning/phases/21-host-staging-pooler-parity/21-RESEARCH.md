# Phase 21 — Technical research: host staging / pooler parity

**Question:** What do we need to know to plan STG-01–STG-03 well?

## Summary

Phase 21 is **maintainer-side documentation and doc-contract work**: extend `guides/adoption-pilot-backlog.md`, cross-links in `CONTRIBUTING.md` and `guides/production-checklist.md`, and fixture-backed assertions so the **CI vs host** boundary and **OK / Issue / N/A / Not run** semantics stay stable. No capture API changes, no in-repo Phoenix sample app (per `REQUIREMENTS.md` / `PROJECT.md`). Integrators satisfy STG acceptance via **fork + PR** (short in-repo index + links to host-owned evidence).

## Findings

### 1. Existing contracts to extend

- **`test/threadline/ci_topology_contract_test.exs`** — already asserts `CI-PGBOUNCER-TOPOLOGY-CONTRACT` in the backlog; natural home for additional **stable substrings** that lock STG rubric headings (avoid duplicating entire tables in tests).
- **`test/threadline/readme_doc_contract_test.exs`** — pattern for README ↔ guide links; Phase 21 likely does **not** need README body changes if backlog + CONTRIBUTING carry STG detail (per CONTEXT D-16).

### 2. Topology narrative (STG-01)

- Fixed ordered fields (CONTEXT D-13): **chain**, **pooler product**, **pool mode**, **Postgres role** (if material), **Ecto** `pool_size` / `pool_count`, **`prepare:`** when relevant, **Sandbox note**, **`matches prod: yes | no | partial`**, then **one-paragraph rationale**.
- Reuse **CI-PGBOUNCER-TOPOLOGY-CONTRACT** wording; do not introduce a competing metaphor.

### 3. Evidence paths (STG-02)

- Two rows minimum: **HTTP audited write** and **async job** (`Threadline.Job` or documented equivalent), each with status + pointer.
- **N/A** requires one-line objective justification (D-09); **Not run** ≠ N/A (D-08).

### 4. Backlog alignment (STG-03)

- **Connection topology** stays a narrow index; longform + Mermaid in host-linked doc (D-15).
- Intro must allow **host-maintained linked copy** (REQUIREMENTS.md).

### 5. Pitfalls (from `.planning/research/PITFALLS.md`)

- Do not let readers confuse **`mix verify.threadline` on CI** with **host HTTP/Oban** evidence — explicit labels in tables.

## Recommendations

1. **Plan A (preferred):** Two waves — (1) backlog rubric + doc contracts, (2) CONTRIBUTING + production-checklist + any follow-up contract strings.
2. **Optional D-18:** Defer thin `mix threadline.*` index task unless a single-source-of-truth pattern is trivial.

## Open questions

- None blocking planning; integrator PR timing is outside repo control.

---

## Validation Architecture

**Dimension 8 (Nyquist):** All executable behavior is already covered by `mix ci.all` and targeted doc contract tests. Phase 21 adds **no new runtime code paths** in the default plan set; validation is **regression + doc contract** after each task.

**Sampling:**

- After each task: `MIX_ENV=test mix test test/threadline/ci_topology_contract_test.exs test/threadline/readme_doc_contract_test.exs` (fast slice).
- After each wave: `MIX_ENV=test mix ci.all` (full gate per `CONTRIBUTING.md`).

**Manual-only:** Maintainer review of integrator-submitted PR prose (no automation).

---

## RESEARCH COMPLETE
