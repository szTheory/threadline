# Phase 234: Typespec and Doc Completion Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-10-04
**Phase:** 234-typespec-and-doc-completion-gate
**Areas discussed:** all six, by the maintainer's instruction to discuss everything and fan out research:
- coverage-gate design;
- spec vocabulary and option types;
- Dialyzer strictness;
- facade grouping;
- the doc-content rubric;
- phase shape and seams.

**Mode:** research-then-recommend (CLAUDE.md standing rule). Six parallel general-purpose researchers produced one coherent set of 27 recommendations, which the maintainer confirmed once.

---

## Baseline measurement (orchestrator, before fan-out)

A scratch script used `Code.fetch_docs` and `Code.Typespec.fetch_specs` over the app modules. The first run had a bug: a binding in a `for` acted as a filter, giving a false 5/92. The corrected run shows:
- 54 of 92 visible entries missing a doc and/or spec;
- 33 visible specs with bare `keyword()`, `term()` or `map()`;
- schema `t()` types with `term()` in every field.

The roadmap's 129/169 figure predates phases 231–233.

## Cross-researcher conflicts resolved in synthesis

| Conflict | Resolution |
|----------|------------|
| Types researcher: option types on the facade page. Phase-shape researcher: `lib/threadline.ex` is at 607/800 lines, so move types to a module. | Keep the types on the facade, with one exact-pinned size exception (D-14). Alternative offered to the maintainer: a visible `Threadline.Options` module. |
| Coverage researcher: one CHANGELOG line for hidden functions. Phase-shape researcher: breaking bullet plus footer. | Breaking bullet, footer, and a mechanical CHANGELOG cross-check (D-08). |
| Group test in a new file vs. the existing `facade_naming_contract_test.exs`. | A describe block in the existing async file; no new weight (D-33). |
| Doc rubric: `## Options` ↔ type parity. Types researcher: allowlist ↔ type parity. | Merged into a three-way parity guard (D-21). |

## Single confirm

| Option | Description | Selected |
|--------|-------------|----------|
| Accept all (Recommended) | Lock all 27 decisions, including closing the allowlists, hiding 8 helpers and the facade size exception | ✓ |
| Accept, but don't close allowlists | Option types become documentation only; the type ↔ allowlist drift check is dropped | |
| Accept, but keep StorageSchema public | The 6 SQL helpers get floor docs and specs instead of being hidden | |
| Accept, types in a separate module | `Threadline.Options` instead of a size exception | |

**User's choice:** Accept all (Recommended)

## Calls the researchers flagged
- Closing the opts allowlists, a 1.0 runtime break (types researcher). Accepted.
- Hiding the 6 StorageSchema helpers that 0.12 documented (coverage and rubric researchers). Accepted.
- Group order: REQUIREMENTS order vs. Querying first (grouping researcher, no clear winner). REQUIREMENTS order was recommended and accepted.
- Spec-change semver policy after 1.0 (Dialyzer researcher, no clear winner). Recorded as seam D-51 for 235 to write.

## Claude's Discretion
See CONTEXT.md `### Claude's Discretion`: group description wording, test file split, the `__option_keys__` shape, collapsing the Evidence arities, and how each Dialyzer finding is fixed.

## Deferred Ideas
- Groups for Evidence and StorageSchema.
- A visible-surface snapshot (235).
- A doc-substance floor (measured vacuous).
- NimbleOptions-generated docs.
- `as_of!/4`.
