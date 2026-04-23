# Phase 20: first-external-pilot - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `20-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-23  
**Phase:** 20-first external pilot  
**Areas discussed:** Evidence workflow, Pilot environment bar, Triage and issue hygiene, Completion criteria (user delegated full recommendation after option “Continue and replan”)

---

## Evidence workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Merged PR updating `guides/adoption-pilot-backlog.md` | Canonical artifact on `main`; matches ADOP-03; issues for heavy evidence | ✓ (recommended) |
| Private doc + maintainer copy | Good for regulated hosts; risk of handoff lag | ✓ (allowed when host cannot PR) |
| Fork PR only (never merge) | Weak—upstream lacks durable record | |
| Gist-only + empty matrix | Fails ADOP-03 letter and discoverability | |

**User's choice:** Continue and replan; delegated “do whatever is recommended” after parallel research.  
**Notes:** Subagent synthesis + OSS patterns (Ruby audit libs use issues first; Threadline’s matrix is the durable doc). Footguns: Slack-only completion, unstable links, unmerged forks.

---

## Pilot environment bar

| Option | Description | Selected |
|--------|-------------|----------|
| Local dev only | Fast feedback; false confidence on GUC + pooler | |
| Shared staging with topology parity | Meets ADOP-03 when pooler/job paths match prod class | ✓ (minimum bar) |
| Production-like / production | Lowest false confidence; not required by ADOP-03 if staging is honest | ✓ (when available) |

**User's choice:** Recommended package — **not** local-only; **staging+** with **PgBouncer mode** and **HTTP + job** evidence where applicable.  
**Notes:** Aligns with PROJECT.md PgBouncer lesson and trigger+transaction semantics; Carbonite-class adopters care about same-transaction and Multi patterns.

---

## Triage and issue hygiene

| Option | Description | Selected |
|--------|-------------|----------|
| Unstructured “something broke” issues | Low DX, duplicate churn | |
| ID + template + labels + repro-first | Oban/Req-style OSS hygiene | ✓ |
| GitHub for every gripe including roadmap vision | Wrong venue | |

**User's choice:** **AP-* IDs**, GitHub body template (see CONTEXT D-10), labels `adoption-pilot` + area + `triage`, classifier routes bug vs v1.6 vs host-internal.  
**Notes:** Anti-patterns from audit-adjacent ecosystems: opaque PDF-only reports, unredacted PII, missing versions.

---

## Completion criteria

| Option | Description | Selected |
|--------|-------------|----------|
| Maintainer review + REQ update | Traceable close | ✓ |
| Implicit close without REQ checkbox | Breaks traceability | |

**User's choice:** Host sign-off + maintainer review of merged backlog; ADOP-03 → Complete in REQUIREMENTS; `/gsd-transition` per habit.

---

## Claude's Discretion

- User asked for one-shot coherent recommendations; no separate “you decide” buckets—all captured as **D-01–D-13** in CONTEXT.

## Deferred Ideas

- Optional `.github/ISSUE_TEMPLATE` for adoption pilot (nice follow-up).
