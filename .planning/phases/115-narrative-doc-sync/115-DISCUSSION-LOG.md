# Phase 115: Narrative Doc Sync - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 115-Narrative Doc Sync
**Areas discussed:** Blessed-path prominence, Legacy record_action framing, Cross-doc discovery contract, Doc-contract literals + evolution prose
**Mode:** User requested all areas + subagent research + one-shot coherent recommendations (delegated decision-making)

---

## Gray Area 1: Blessed-path prominence in how-threadline-works

| Option | Description | Selected |
|--------|-------------|----------|
| A. Surgical swap | ~30 lines: formula, flow, example, Public API, JTBD Job 2 | ✓ (base) |
| B. Layer-native full rewrite | Restructure short version + flow around three layers | |
| C. Additive “Audited writes” section | New section; old record_action text remains above | |
| D. Concept/API split (hybrid) | Domain language + Audit.transaction in all executable examples | ✓ (combined with A) |

**User's choice:** Delegated — **D implemented as A (surgical retarget, not full rewrite).**

**Notes:** Carbonite/Ecto/Oban/django-auditlog pattern: blessed path first screenful. Current how-threadline-works contradicts getting-started §6 — discovery-order bug. JTBD and Architecture layers stay; only semantics write-path story is stale.

---

## Gray Area 2: Legacy record_action/2 framing

| Option | Description | Selected |
|--------|-------------|----------|
| A. Escape hatch only | record_action vanishes from narrative; link integration-contracts | |
| B. Visible building block | Helper face + composition one-liner; record_action as primitive | ✓ |
| C. Dual-documented legacy recipe | Recommended + fenced deprecated recipe block | |

**User's choice:** Delegated — **Option B with A-lite link-out (Phase 112 B-lite).**

**Notes:** Deprecate hand-rolled recipe, not `record_action/2` API. Keep correlation_id strict-filter story. Capture-only omit-`:action` is valid. No second fenced legacy block in how-threadline-works. integration-contracts escape-hatch subsection deferred (out of Phase 115 scope).

---

## Gray Area 3: Cross-doc discovery contract (NARR-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Fix README Semantics bullet only | Low-cost; how-threadline-works still primary edit | ✓ (partial) |
| Full how-threadline-works + README + getting-started cross-link pass | Align ownership matrix + discovery order | ✓ |
| Demote record_action in README opening API list | Stronger narrative | |
| Keep opening API laundry list unchanged | Completeness + existing contracts | ✓ |

**User's choice:** Delegated — **Fix Semantics bullet + how-threadline-works as primary edit + cross-link tightening; keep L10 API list.**

**Notes:** README maps (Oban/Phoenix). Evaluator paths: architecture → how-threadline-works; adoption → getting-started; both converge on Audit.transaction/3 §6.

---

## Gray Area 4: Doc-contract literals + 0.6.0 evolution prose

| Option | Description | Selected |
|--------|-------------|----------|
| A. Minimal literal add | 2 asserts after doc edit | |
| B. Comprehensive update in existing test file | Second test + write-side ordering + §6 link | ✓ |
| C. Separate NARR test file | New module for traceability | |
| Evolution 0.6.0 bullet prose in 115 | Add while editing guide | ✓ |
| Evolution semver contract locks in 115 | Assert 0.6.0 in Evolution section | |
| Evolution semver contract locks in 117 | Phase DOC authority | ✓ |

**User's choice:** Delegated — **Option B; Evolution prose in 115, contract locks in 117.**

**Notes:** SSOT phrase: `recommended audited write path`. Retain record_action/2 positive asserts. Optional: wire audit_doc_contract into verify.doc_contract.

---

## Claude's Discretion

User explicitly requested one-shot recommendations without further decision rounds — all discretion items listed in CONTEXT.md D-115-04g and Claude's Discretion section.

---

## Deferred Ideas

- integration-contracts escape-hatch fenced subsection — later doc phase
- domain-reference incident prose — Phase 117
- upgrade-path 0.5→0.6 bullet + semver contracts — Phase 117
- example README / Job moduledoc alignment — Phase 116
- lib/threadline/job.ex moduledoc standalone record_action — future note
