# Phase 126: Nyquist Validation Sign-off (122–124) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 126-nyquist-validation-signoff-122-124
**Areas discussed:** Scope boundary, Execution shape, Manual-only disposition, Green gate policy

---

## Scope boundary — VALIDATION refresh depth

| Option | Description | Selected |
|--------|-------------|----------|
| A — Frontmatter flip only | Set `nyquist_compliant: true` without updating per-task map | |
| B — Full re-litigation | Rerun every task, regenerate tests, recreate VERIFICATION | |
| C — Hybrid refresh | Anchor on existing VERIFICATION.md + named rerun bundle; full VALIDATION map update | ✓ |

**User's choice:** C — Hybrid refresh (research-backed recommendation, user requested all areas with deep analysis)
**Notes:** Rejects merge-theater sign-off per OSS DNA. VERIFICATION already passed; 126 is bookkeeping finalization. Adds Commands Actually Used, retroactive backfill note, per-task ✅/attested rows.

---

## Execution shape

| Option | Description | Selected |
|--------|-------------|----------|
| A — Raw `/gsd-validate-phase` ×3 | Three standalone invocations, no 126 plans | |
| B — Unified batch plan | One plan updating all three VALIDATION files | |
| C — One phase, three sequential plans | 126-01→122, 126-02→123, 126-03→124 | ✓ |

**User's choice:** C — Three sequential plans
**Notes:** Matches ROADMAP three-criterion shape with GSD tracking. Atomic per-target commits. Rejects batch (wrong blast radius for audit proof chains). CI analogy: sequential jobs with durable attestation artifacts, not matrix.

---

## Manual-only verifications disposition

| Option | Description | Selected |
|--------|-------------|----------|
| A — Keep manual, attested complete | Manual-Only table persists; rows marked attested with VERIFICATION pointer | ✓ |
| B — Remove manual rows at sign-off | Cleaner VALIDATION but hides CI boundary | |
| C — Add automated proxy tests | Full automation including registry/ExDoc CI | Partial |

**User's choice:** A+ — Attested manual-complete with selective proxy
**Notes:**
- **122 hex publish:** Keep Manual-Only; mark attested; evidence tier `inferred_posture`; pointer to 122-VERIFICATION.md; no PR hex polling
- **123 ExDoc anchor:** Close manual row — proven via heading+link doc-contract proxy; tier `proven`
- **124 prose spot-reads:** Keep manual; mark attested via VERIFICATION traceability

---

## Green gate before sign-off

| Option | Description | Selected |
|--------|-------------|----------|
| Targeted per-phase only | Run only per-task map commands | |
| `mix verify.doc_contract` only | Single alias, no per-task | |
| `mix ci.all` per phase | Full ladder ×3 | |
| Tiered | Per-task map + doc_contract per phase; one ci.all at session close | ✓ |

**User's choice:** Tiered gate policy
**Notes:** v1.27 audit footgun: targeted band green while full doc_contract failed. Phase 103 precedent: named bundle authority. Expected ~5–8 min targeted+doc_contract across three phases + one ~3–5 min ci.all at close.

---

## Claude's Discretion

- Optional 122-VERIFICATION.md structure proxy test (no network)
- Optional 126-04 for milestone audit Nyquist table refresh
- Exact retroactive backfill note wording

## Deferred Ideas

- Phase 125 Nyquist sign-off
- Example `:schemas` wiring (Phase 127)
- Per-PR hex.pm polling
- `mix docs` HTML anchor CI in PR path
