# Phase 121: Adopter Doc Neutrality - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 121-adopter-doc-neutrality
**Areas discussed:** Getting-started §5 snippet, §6 example coupling, README/evaluator discovery, doc-contract strategy (all four gray areas, research-backed one-shot recommendations)

---

## Research method

Four parallel research passes (ecosystem idioms, OSS DNA, prior phases 119–120, current doc-contract state) plus `prompts/threadline-elixir-oss-dna.md` and `.planning/research/sigra-integration-context.md`. User requested coherent locked recommendations without further decision burden.

---

## 1. Getting-started §5 primary snippet

| Option | Description | Selected |
|--------|-------------|----------|
| A — Generic host callbacks | `MyApp.Audit` fence; integration-contracts SSOT | ✓ (primary tier) |
| B — phx.gen.auth-shaped primary | `current_scope` + `MyApp.AuditActor` as hero fence | |
| C — Sigra fence + disclaimer | Minimal change; label after fence | |
| D — Two-tier | A primary + optional Sigra subsection | ✓ (structure) |

**User's choice:** **D + A** — two-tier §5; primary fence matches `integration-contracts.md`; optional `<!-- getting-started-sigra-reference-fence -->` with example-router anchor; lane bullets to phx + sigra guides.

**Notes:** Rejects C (ADOPT-AUTH-01 failure). B belongs in phx guide link, not universal quickstart. Ecosystem: Sentry/OTel generic seam first; django-auditlog host sets actor before write.

---

## 2. §6 authenticate + example coupling

| Option | Description | Selected |
|--------|-------------|----------|
| A — Delegate curl to example README | Strongest neutrality; less self-contained | |
| B — Generic contract + collapsed sigra-reference curl | Lane table + `<details>` for example-only steps | ✓ |
| C — Minimal §6 change | One-line disclaimer only | |

**User's choice:** **B** — generic auth contract and lane router in open §6; runnable curl under visible **sigra-reference example app only** collapse; example README remains SSOT for cookie steps.

**Notes:** Rejects C (contradicts neutral §5). A over-corrects for Track A evaluators.

---

## 3. README & evaluator discovery

| Option | Description | Selected |
|--------|-------------|----------|
| A — Four lanes; peer phx + Sigra links | Update three-lane literal; grouped auth bullet | ✓ |
| B — phx first as “default Phoenix path” | | |
| C — Lanes only in upgrade-path | | |

**User's choice:** **A (refined)** — four named lanes in README; phx and Sigra as peer **reference** integrations; matrix table only in upgrade-path; phx before sigra in list order without “default” language.

**Notes:** Rejects B (oversells `reference` as supported). Rejects C (ADOPT-AUTH-02 / README-as-map DNA).

---

## 4. Doc-contract strategy

| Option | Description | Selected |
|--------|-------------|----------|
| A — New phx_gen_auth_doc_contract + targeted edits | ~12–18 asserts; register in verify.doc_contract | ✓ |
| B — Extend existing files only | | |
| C — A + remove router_block() from getting-started contract | Required part of A | ✓ |

**User's choice:** **A + C** — new `phx_gen_auth_doc_contract_test.exs`; remove blanket `router_block()` assert; neutrality + phx link asserts in getting-started/readme/evaluating contracts; do not duplicate upgrade-path matrix locks.

**Notes:** C is not optional scope — structural conflict with ADOPT-AUTH-01.

---

## Claude's Discretion

- Subsection marker mechanism (`<!-- -->` vs heading)
- `<details>` vs visible `###` for sigra-reference curl block
- `mount_block()` fate after §5 rewrite

## Deferred Ideas

- `sigra_doc_contract_test.exs` in `verify.doc_contract`
- Global `MyApp.Audit` / `MyApp.AuditActor` naming harmonization
- Example app auth stack swap
