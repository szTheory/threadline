# Phase 108: Walkthrough Script + Finding-Capture Protocol - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 108-walkthrough-script-finding-capture-protocol
**Areas discussed:** All six gray areas (user requested full research + one-shot recommendations via subagents)
**Mode:** Research-backed auto-resolution (no per-area interactive Q&A)

---

## 1. Walkthrough doc shape & self-containment

| Option | Description | Selected |
|--------|-------------|----------|
| Fully self-contained inline | Duplicate all literals in procedural body | |
| Hub-and-spoke links | TOC pointing at README/manifest/guides | |
| Procedural runbook + reference appendix | Body = steps; Appendix A = copied literals; Appendix B = commands | ✓ |
| Split walkthrough + Livebook | Interactive notebook + markdown runbook | |

**User's choice:** Procedural runbook + reference appendix (D-108-01) — recommended after subagent research across Phoenix guides, Oban Training, Carbonite docs, SIEM playbook patterns, and Threadline OSS DNA.

**Notes:** RUN-01 self-containment satisfied by inlined appendix, not by forking SSOT. Manifest + `Demo.Manifest` remain edit-first sources. Four doc roles preserved (integrator guide vs example README vs manifest vs maintainer runbook).

---

## 2. Operator incident count & SEED-05 delete story

| Option | Description | Selected |
|--------|-------------|----------|
| Keep 3 | WALK-03 stays at three; delete unscripted | |
| Expand to 4 | Add #4518 delete attribution playbook | ✓ |
| Fold delete into scenario 1 | One "Acme Tuesday" mega-scenario | |
| Separate redaction drill section | Move delete to cross-cutting section | |

**User's choice:** Expand to four operator incidents (D-108-02) — aligns `DEMO-MANIFEST.md` heroes (#4521 close, #4518 delete, leaving-agent window, org Y purge) with four atomic playbooks. ROADMAP/Phase 109 "three scenarios" wording amended in Phase 108 doc pass.

**Notes:** django-auditlog / CloudTrail pattern — separate attribution for semantic actions vs destructive ops. WALK-04 redaction exercise stays policy plane; incidents #1 and #4 teach operational redaction/delete.

---

## 3. Expected outputs per step

| Option | Description | Selected |
|--------|-------------|----------|
| Checklist-only | Vague pass/fail boxes | |
| Narrative-only | Prose expected states | |
| Hybrid checklist + literals | Imperatives + manifest literals + semantic checklist | ✓ |
| Executable test-style in doc | Full assert blocks in markdown | |

**User's choice:** Hybrid checklist + literals with fixed step skeleton (D-108-03). ExUnit assertions stay in `demo_contract_test.exs`. CloudTrail/Grafana runbook pattern: copy-paste filters with bounded time windows, capability-based UI checks not label text.

**Notes:** Canonical CLI `mix threadline.evidence.show`; `mix verify.evidence` footnoted as naming gap. Never assert trigger UUIDs; assert correlation_id, ticket #, actor email, `[REDACTED]`.

---

## 4. Evidence exercises (WALK-04)

| Option | Description | Selected |
|--------|-------------|----------|
| All-live runs | Walker executes purge + records live | |
| All-seeded read-only | Walker only reads seeded rows | |
| Hybrid | Seeded org Y + seeded snapshots + live viewer parity | ✓ |

**User's choice:** Hybrid model (D-108-04). Retention proof = read seeded `walk-retention-offboarded-co` + empty org Y timeline. Trigger coverage = seeded snapshot + optional health.coverage parity. Redaction = seeded `redaction_policy` row (gap: not seeded yet — D-108-04e) + live policy viewer + #4521 capture corroboration.

**Notes:** Live purge footgun avoided (destroys negative check). SOC2/Terraform analogue: durable evidence rows + live reconciliation viewers. Subagent verified `redaction_policy` missing from current seed — flagged as planner prerequisite.

---

## 5. Findings protocol rigidity

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal paragraph | Title + class + one paragraph | |
| Comprehensive KEP-style | Many sections per finding | |
| YAML frontmatter lite + 3 body sections | SEED-001 / 106-REVIEW pattern | ✓ |
| GitHub issue-template conditionals | Multi-template picker | |

**User's choice:** Structured minimal + YAML frontmatter (D-108-05). 4-question <30s classification tree. Six boundary examples in README. Phase 109 no-fix discipline echoed in walkthrough front-matter.

**Notes:** Borrowed bug-bounty severity-first + GitHub type-at-top + Phase 104 v1.24-seeds routing vocabulary. Avoid classification paralysis via ordered decision tree; (b) budget gate (≤1 plan) prevents laundering into scope creep.

---

## 6. Voice & audience

| Option | Description | Selected |
|--------|-------------|----------|
| Maintainer runbook | Imperative, Expected/If different, checkpoints | ✓ |
| Tutorial | Pedagogical, progressive disclosure | |
| Dual-audience doc | Two voices in one file | |
| Split files | Public walk + planning-only runbook | |

**User's choice:** Maintainer operator runbook voice (D-108-06). Primary reader = Phase 109 maintainer. Secondary = post-110 adopter by subtraction, not dual-voice upfront. Incident-playbook headers; brand-aligned calm senior engineer tone.

**Notes:** Stripe task-oriented expected shapes; K8s "do not mutate during audit" → "do not fix during walk." Split only what ROADMAP already splits (walk script vs findings artifacts).

---

## Claude's Discretion

- § numbering scheme consistency
- `mix verify.evidence` alias vs footnote
- `walkthrough_doc_contract_test.exs` timing (108 vs 110)
- Leaving-agent persona exact email (manifest-locked once published)

## Deferred Ideas

- Livebook runner from appendix literals
- Post-110 adopter-tutorial polish pass
- Public vs maintainer split files
