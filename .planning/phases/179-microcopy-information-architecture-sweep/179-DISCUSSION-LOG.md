# Phase 179: Microcopy & information-architecture sweep - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-19
**Phase:** 179-Microcopy & information-architecture sweep
**Areas discussed:** Navigation and task language, Domain terminology rules, State and destructive microcopy, Progressive disclosure and dense operator efficiency

---

## Navigation and task language

| Option | Description | Selected |
|--------|-------------|----------|
| Keep `Find / Verify / Prove` | Lowest churn; preserves current shell/Home grouping. Leaves ambiguity and overclaiming risk. | |
| Keep triad, rename `Prove` to `Evidence` | Reduces one overclaim but creates partial terminology drift and does not cover redaction/retention cleanly. | |
| Hybrid: task Home, domain nav | Home uses job prompts; shell uses stable domain/task buckets without route churn. | yes |
| Flat noun nav | Literal and expert-friendly, but loses task grouping and first-run orientation. | |

**User's choice:** User selected all areas and asked for subagent research plus one-shot recommendations.
**Notes:** Advisor recommendation: keep URLs/current atoms stable; use task-led Home labels and clearer shell buckets. Reserve evidence verdict language for evidence records, not top-level IA.

---

## Domain terminology rules

| Option | Description | Selected |
|--------|-------------|----------|
| Plain operator nouns | Fast scan and brand-aligned, but may blur Threadline's action/change/transaction distinctions. | |
| Exact schema/domain terms | Maximizes code/docs parity, but visible CamelCase is jargony and less usable. | |
| Hybrid layered vocabulary | Plain visible UI plus exact domain terms in detail, docs, tooltips, ARIA, and advanced contexts. | yes |

**User's choice:** User selected all areas and asked for recommendations.
**Notes:** Advisor recommendation: use a glossary mapping. Primary UI says transaction/change/action/actor/correlation id/evidence; exact terms such as `AuditTransaction`, `AuditChange`, `AuditAction`, and `ActorRef` appear where precision helps.

---

## State and destructive microcopy

| Option | Description | Selected |
|--------|-------------|----------|
| Strict templated copy helpers | Maximum consistency and testability, but can become generic and hide page context. | |
| Controlled templates with page-specific domain slots | Consistent grammar with enough page-specific object/action detail. | yes |
| Per-page bespoke sweep | Best local editorial fit, but highest drift risk and harder COPY-* verification. | |

**User's choice:** User selected all areas and asked for recommendations.
**Notes:** Advisor recommendation: keep repeated grammar in existing components/helpers and let pages fill object/action/cause/next-action slots. Use severity-correct ARIA roles and GOV.UK-style validation summaries.

---

## Progressive disclosure and dense operator efficiency

| Option | Description | Selected |
|--------|-------------|----------|
| Explanatory-first rails everywhere | Strong first-run clarity but creates scan fatigue and pushes rows/actions down. | |
| Dense-first compressed surface | Fast for trained operators but risks hiding trust/caveat information. | |
| Layered context budget | Dense investigation paths, explicit risk/governance states, and full recovery copy for empty/error/destructive states. | yes |
| User-selectable help/density mode | Could serve novice/expert modes but adds state, copy variants, and scope. | |

**User's choice:** User selected all areas and asked for recommendations.
**Notes:** Advisor recommendation: keep explanation where it changes judgment; compress repeated legends and do not add a persistent mode.

---

## Claude's Discretion

- Exact final wording may be adjusted during planning/implementation to fit responsive shell widths and existing tests, but the direction is locked: task-led Home, domain-led shell, hybrid vocabulary, controlled templates, layered disclosure.
- Planners may choose whether copy-contract tests scan rendered pages, source strings, or both, as long as they catch the named drift classes.

## Deferred Ideas

- Persistent novice/expert help or density mode.
- Full i18n or externalized copy registry.
- Any new operator capability outside COPY-01..03.
