# Phase 203: Real Gates - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-22
**Phase:** 203-real-gates
**Areas discussed:** Credo gate shape & finding disposition, Layer inversions (GATE-03), Capture↔Semantics cycle (GATE-04)
**Mode:** Advisor, research-then-recommend (3 parallel gsd-advisor-researcher passes). Maintainer: "go ahead follow ur recs auto" — all recommendations accepted.

---

## Credo gate shape & finding disposition

| Option | Description | Selected |
|--------|-------------|----------|
| A. Fix all 356 AliasUsage at upstream defaults | 91 alias pairs / 56 files; no register row; resolves "never disable" conflict | ✓ |
| B. `if_called_more_often_than: 2` | Measured 356→279; doesn't earn a delta | |
| C. Scope AliasUsage to lib/ + 332-count register row | Partial disable; defers cheap debt | |
| D. Structural (46): per-site disable-for-next-line + ceiling contract test | Exact, ratchetable by Phase 204; mirrors dialyzer ceiling | ✓ |
| E. Raise thresholds / disable with register row | Max complexity 33 hides new debt; disabling breaks GATE-02 | |

**User's choice:** Recommended (A + D), 5-plan split, register enforced in a contract test.
**Notes:** Re-measured 484 findings (not 377). Dialyzer already 0 — verify-only.

---

## Layer inversions (GATE-03)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) `git mv` Scope/FilterParams down into `Threadline.Query.*` | Not extraction; no behaviour change; pins move in same commit | ✓ |
| (a') Inline Scope into Query | Merge arguably crosses the 204 line | |
| (b) Dependency inversion via opts/config | New config surface; Scope already is DI | |
| (c) Split core/surface halves | Forbidden by 204 hard rule | |
| (d) critic.synth: leave + explicit allowlist | Outside the four layers; not shipped to Hex | ✓ |
| Enforcement: ExUnit source-scan contract test | Matches repo style | ✓ |
| Enforcement: xref / custom Credo / `boundary` | Heavier; boundary deferred | |

**User's choice:** Recommended.

---

## Capture↔Semantics cycle (GATE-04)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Delete `@compile no_warn_undefined`, keep association | Line suppresses nothing; no API change; 0 compile-connected cycles | ✓ |
| (b) Replace belongs_to with `field :action_id` | Breaks `Repo.preload(tx, :action)` — HIGH-IMPACT | |
| (c) Flip direction, Semantics owns association | Same breakage | |
| (d) Query-layer read schema | New surface; still breaks preload | |

**User's choice:** Recommended (a), with GATE-04 read as "no compile-connected cycles + no no_warn_undefined papering"; pinned by xref `--label compile-connected --fail-above 0` + contract test.

---

## Claude's Discretion

- Test file names, alias `as:` names, in-place flattening of individual Nesting sites (only without function split/extract).

## Deferred Ideas

- 46 structural findings → Phase 204; `max_nesting: 3` → 204 decision; `boundary` lib → 204+; runtime association edge removal → breaking milestone; critic retirement → separate; opt-in checks → TYPES-01.
