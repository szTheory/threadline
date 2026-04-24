# Phase 30 — Technical research

**Question:** What do we need to know to plan retention-at-scale documentation well?

## RESEARCH COMPLETE

### Shipped APIs (source of truth)

- **`Threadline.Retention.purge/1`** — `lib/threadline/retention.ex`: requires `repo:`, honors `dry_run:`, `batch_size` (default 500), `max_batches` (default 10_000); returns `{:error, :disabled}` when `config :threadline, :retention` → `enabled` is not `true`. Cutoff from `Threadline.Retention.Policy.cutoff_utc_datetime_usec!/0` unless stricter `:cutoff` passed.
- **`Threadline.Retention.Policy`** — `lib/threadline/retention/policy.ex`: validates `keep_days` XOR `max_age_seconds`, positive window, `enabled`, `delete_empty_transactions`.
- **`Mix.Tasks.Threadline.Retention.Purge`** — `lib/mix/tasks/threadline.retention.purge.ex`: `--dry-run`, `--execute`, `--batch-size`, production `MIX_ENV=prod` + explicit `--execute` gate (matches checklist bullets).

### Checklist insertion constraints (Phase 28 inheritance)

- **`guides/production-checklist.md`** §4 ends with index bullet linking `audit-indexing.md`; §5 Export, §6 Observability, §7 Brownfield use stable `#6-observability` style anchors in cross-links from domain-reference.
- **Do not** add a new top-level `##` between §4–§7 — CONTEXT D-1 locks new volume content under **`### Volume, growth, and purge cadence`** inside **`## 4. Retention and purge`** after existing gate bullets.

### Cross-doc linkage (D-3)

- **`Threadline.Query.timeline/2`** and **`Threadline.Export`** share filter keys (`:from`, `:to`, `:correlation_id`, etc.) — domain-reference already documents; checklist §5 should gain one retention-bound sentence, not duplicate SQL.

### Discovery hub (D-4)

- Add **`## Operating at scale (v1.9+)`** (exact working title per CONTEXT) in **`guides/domain-reference.md`** as links-only orientation to Telemetry, Trigger coverage, `audit-indexing.md`, `production-checklist.md` §4 volume H3.
- README: single paragraph near Maintainer checks / operator path pointing to that hub — README already has "### Data retention and purge" under Maintainer checks; hub paragraph should **complement** (routing to v1.9 map) without duplicating Phase 28 telemetry tables.

### Verification approach

- **`mix verify.doc_contract`** / existing doc tests if extended; primary gate: **`mix test`**, **`mix compile --warnings-as-errors`**, grep-able headings per plan acceptance criteria.
- No schema migrations — no `[BLOCKING]` db push.

---

## Validation Architecture

This phase is **documentation-only** with **grep- and test-backed** verification.

| Dimension | Approach |
|-----------|----------|
| Correctness vs code | Plans cite `lib/threadline/retention.ex`, `retention/policy.ex`, mix task moduledocs; acceptance criteria grep module names and checklist headings. |
| Anchor stability | H3 title in §4 and hub H2 fixed strings in acceptance criteria; optional HTML `id=` on hub if ExDoc slug risk called out in plan. |
| Regression | Full `mix test` after edits; doc-contract suite unchanged unless a plan explicitly adds a new test file (not required by SCALE-01/02 REQ text). |
| Security / data loss narrative | Plans include `<threat_model>`: mis-stating purge irreversibility or `enabled` gate is **high** severity — mitigated by quoting retention moduledoc and existing §4 bullets. |

Nyquist sampling: after each plan’s tasks, run `mix format` and targeted `mix test`; wave end `mix ci.all` or `mix test` per repo norms.
