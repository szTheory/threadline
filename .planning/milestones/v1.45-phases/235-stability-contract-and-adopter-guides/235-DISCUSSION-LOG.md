# Phase 235: Stability Contract and Adopter Guides - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `235-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-10-06
**Phase:** 235-Stability Contract and Adopter Guides
**Areas discussed:** 1.x stability and database contract; contract tests and change control; supported PostgreSQL table shapes; redaction guarantees and threat boundary; guide reader journeys and DX

---

## 1.x stability and database contract

Research checked the prior phase handoff and requirements rather than reopening settled compatibility policy.

| Option | Tradeoffs | Disposition |
|--------|-----------|-------------|
| Carry forward D-49/D-51 exactly and pin each promise | Preserves decisions already made, gives adopters a single 1.x contract, and avoids inconsistent semver claims. Requires precise contract tests and changelog discipline. | Recommended and locked in context. |
| Reconsider the deprecation/spec-semver policy in this phase | Could simplify wording if the previous decision proved incoherent, but would reopen decisions from Phase 234, delay the docs, and make Phase 235 absorb broader compatibility debate without new evidence. | Rejected; no contradictory evidence found. |
| Treat JSONB serialization bytes as stable | Easy to state but couples adopters to incidental JSON key ordering/serialization and blocks legitimate additive evolution. | Rejected; stable JSONB keys/shapes are additive, byte serialization is not promised. |

## Contract tests and change control

| Option | Tradeoffs | Disposition |
|--------|-----------|-------------|
| Query PostgreSQL catalogs for actual columns, types, nullability, and indexes; use explicit pins for stable fields and public sets | Proves the installed database contract and keeps each promise attributable. Requires a live PostgreSQL test and deliberate allowlist maintenance. | Recommended. |
| Pin generated SQL or schema dumps byte-for-byte | Simple diff signal, but creates noise from formatting/order and can miss that the deployed catalog differs from the script. | Rejected as the only evidence; snapshots may supplement a focused assertion only where they add distinct value. |
| Derive every expected value from production code | Reduces duplicated literals, but a rename/removal in implementation can update both actual and expected values and make the test vacuous. | Rejected for fixed public contracts; literal independent allowlists are needed. |

## Supported PostgreSQL table shapes

| Option | Tradeoffs | Disposition |
|--------|-----------|-------------|
| One pre-install eligibility matrix with conditions, caveats, and evidence | Lets an adopter make an install decision quickly and distinguishes accepted-with-conditions from unsupported. Needs careful upkeep and direct links to code/tests. | Recommended. |
| Narrative-only guide | Easier to write, but readers must assemble status and caveats across paragraphs; higher risk of missing an installation blocker. | Rejected in favor of a matrix plus short explanations for subtle caveats. |
| Expand the guide to promise additional shapes | Could broaden adoption, but scope must follow tested support; unsupported expansion is a correctness promise Threadline cannot uphold. | Rejected; document current support only. |

Prior-art/code review specifically called out composite/non-`id` keys and their type limits; `primary_key:` exact-set unique-index requirements; schema-qualified names; PostgreSQL identifier limits and derived names; `char(n)` padding; cloned partition triggers and physical leaf recording; unlogged-table crash durability; and row-trigger limitations on views. This is support documentation, not a request to add more shapes.

## Redaction guarantees and threat boundary

**Options actually presented to the maintainer:**

| Option | Tradeoffs | Selected |
|--------|-----------|----------|
| 1. Add migration-time rejection of nonexistent `mask:`/`exclude:` columns, pin both failures plus a valid control, and document migration rollout limits | Closes the typo path before generated trigger install and gives an actionable failure. It changes migration-time behavior for invalid configurations and requires adopters to regenerate/run a host-owned trigger migration to affect an existing installation; it does not repair historical rows. | ✓ |
| 2. Document the current fail-open behavior and defer code | Lowest immediate implementation cost, but leaves a typo capable of storing plaintext while a mask typo may produce a redaction-shaped value. Security reviewers would be told about a known failure mode that remains easy to trigger. | |

**User's choice:** `1`.

The maintainer approved this narrow scope amendment. The discussion does not broaden it to the global redacted function or direct internal trigger calls; those remain separate gaps. The guide must distinguish generated per-table property coverage from shape validation and the configured-vs-deployed presenter check. It must identify residual plaintext locations and name the proof behind every claim.

## Guide reader journeys and DX

| Option | Tradeoffs | Disposition |
|--------|-----------|-------------|
| Separate stability, table eligibility, and redaction threat guides by reader job | Each reader gets a direct path and claims remain close to evidence; introduces cross-links and requires a clear canonical entry point. | Recommended; fits current phase requirements and Diátaxis task separation. |
| One combined contract guide | Fewer files, but mixes release expectations, migration prerequisites, and security threat analysis; harder for a reviewer to locate the evidence needed for one job. | Rejected unless the existing guides already provide a compelling canonical structure. |
| Add an operator UI/design contract | Could be valuable for the operator product, but Phase 235 is docs/contracts and operator UI design is expressly deferred until after 1.0.0. | Out of scope. |

Use the current Brand Book voice: precise, composed, and calm. There is no visual-interface work here; documentation accessibility comes from semantic headings, descriptive links, explicit conditions, and examples that do not rely on color or images. Keep the README's golden install flow canonical rather than copying it into each guide.

## the agent's Discretion

- Exact prose, examples, test filenames/grouping, test helper organization, guide heading hierarchy, and plan/wave structure.
- The concrete catalog query and migration-validation helper, provided the guard runs before trigger DDL and follows the existing host-owned migration architecture.
- Whether doc contracts share one focused file or use siblings, provided every guarantee is scoped, evidence is direct, and failures identify the drift.

## Deferred Ideas

- Global redacted `TriggerSQL.install_function` coverage/removal — `gen.triggers` does not emit this path.
- Direct `TriggerSQL.create_trigger/3` redacted-primary-key guard gap.
- Causal ordering, numeric/timestamptz capture fidelity, historic data cleanup, retention, RLS, broader partitioning policy, and operator UI work.
- No literal repository `prompt.txt` was found; the user's inline discussion brief and the prompt files listed in `235-CONTEXT.md` were used.

---

*Phase: 235-stability-contract-and-adopter-guides*
*Discussion log generated: 2026-10-06*
