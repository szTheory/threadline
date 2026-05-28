# Phase 117: Evidence Plane Doc Authority - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 117-evidence-plane-doc-authority
**Areas discussed:** Evidence-plane entry point, Semver vocabulary, Deferred narrative prose, Doc-contract enforcement
**Mode:** Full-area research via subagents + user request for one-shot coherent recommendations

---

## Evidence-plane entry point (DOC-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Thin `guides/evidence-plane.md` hub | TOC cross-linking split guides; ExDoc extra | |
| README pointer matrix + fix dead refs | Split guides stay authoritative; fix PROJECT.md | ✓ |

**User's choice:** Research-backed recommendation (no hub) — user delegated full decision set.
**Notes:** README strip already contract-locked. Hub risks duplicated non-goals vs how-threadline-works. Matches Operator Surface and Phase 99 doc-contract bundle pattern.

---

## Semver vocabulary sweep (DOC-02)

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Full scrub all v1.xx in guides | High churn, breaks API-era headers | |
| (B) Semver in adopter paths; drop v1.2x; allowlist domain-reference | Coherent with 0.6.0 story | ✓ |
| (C) Milestone labels only in .planning/ | Fails DOC-02 for evaluators | |

**User's choice:** Option B.
**Notes:** Add upgrade-path 0.5→0.6 bullet. Evolution contract locks. Standard evaluator sentence documented in CONTEXT.

---

## Deferred Phase 115 narrative prose

| Option | Description | Selected |
|--------|-------------|----------|
| Hub/semver only; defer narrative again | Leaves known wrong incident JSON | |
| Include all three deferrals narrowly | incident step + upgrade bullet + evolution contracts | ✓ |

**User's choice:** Include all three in Phase 117 with scope guard (no full domain-reference rewrite).

---

## Doc-contract enforcement (DOC-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal-plus | ~5–7 tests, wire exploration_routing, no .planning asserts | ✓ |
| Comprehensive new hub module | Only if hub created — rejected with hub | |

**User's choice:** Minimal-plus per CONTEXT D-117-04 table.

---

## Claude's Discretion

Listed in CONTEXT.md — exact prose wording, optional CONTRIBUTING mapping table, test file placement.

## Deferred Ideas

- evidence-plane hub on pilot feedback
- domain-reference full v1.10+ semver heading pass
- integration-contracts escape-hatch section
