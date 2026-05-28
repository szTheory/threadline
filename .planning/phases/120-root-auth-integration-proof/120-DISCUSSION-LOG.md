# Phase 120: Root Auth Integration Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 120-Root Auth Integration Proof
**Areas discussed:** All six gray areas (user requested one-shot recommendations after subagent research)

---

## 1. Proof depth — assigns-only vs full Plug

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Inline anonymous fns on shaped conns | Fast, doesn't match guide module | |
| (B) Guide-equivalent module functions | Matches MyApp.AuditActor; living cookbook | ✓ primary |
| (C) Full Plug regression suite | Duplicates plug_test.exs | |
| Hybrid B + minimal C | Module functions + one Plug smoke | ✓ |

**User's choice:** Research synthesis — hybrid B + one minimal C (locked D-120-01–04)

**Notes:** Sigra precedent; Sentry/OpenTelemetry/PaperTrail test host callbacks, not full stack per lane.

---

## 2. Fixture shape — maps vs structs

| Option | Description | Selected |
|--------|-------------|----------|
| Nested plain maps | Guide parity, sigra_test pattern | ✓ |
| defstruct test doubles | Extra dialect adopters don't see | |
| Example app Scope structs | Couples Hex package to one host | |

**User's choice:** Maps + `test/support/phx_gen_auth_fixtures.ex` (D-120-05–08)

**Notes:** Struct/map parity optional single test; string ids.

---

## 3. Reference semantics coverage

| # | Semantic | Prove in phx file | Selected |
|---|----------|-------------------|----------|
| 1 | Scope → user actor | Yes | ✓ |
| 2 | Logged-out → nil | Yes | ✓ |
| 3 | Admin authorize_fn | Yes | ✓ |
| 4 | x-request-id wins | Cite plug_test | ✓ |
| 5 | Correlation additive | Cite plug_test | ✓ |
| 6 | Unknown keys raise | Cite plug_test | ✓ |

**User's choice:** Prove 1–3 only; ~8–12 tests (D-120-09–11). phx_gen_auth_doc_contract deferred to 121.

---

## 4. Legacy current_user fallback

| Option | Description | Selected |
|--------|-------------|----------|
| Include secondary describe | Optional D-07; not in AUTH-PROOF | |
| Guide-only | Brownfield escape hatch | ✓ |
| Defer to Phase 121 | Wrong phase scope | |

**User's choice:** Guide-only, no CI (D-120-12–13)

---

## 5. authorize_fn test posture

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Conn-shaped via ExportAuthPlug | AUTH-PROOF-02 + export footgun | ✓ |
| (B) Full operator_surface mount | Macro/compile scope | |
| (C) LiveView socket auth_test patterns | Duplicate | |

**User's choice:** (A) + fix guide 2-arity → 1-arity (D-120-14–17)

**Notes:** Discovered guide/runtime arity mismatch during research.

---

## 6. Matrix row + doc-contract literals

| Option | Description | Selected |
|--------|-------------|----------|
| Extend upgrade_path_doc_contract only | ~12–16 asserts; four-lane | ✓ |
| New phx_gen_auth_doc_contract in 120 | ~50 sigra-scale | |
| Separate phx doc contract | Phase 121 ADOPT-AUTH-03 | ✓ deferred |

**User's choice:** Matrix row + upgrade_path locks + refute forthcoming (D-120-18–22)

---

## Claude's Discretion

- Nil-branch coverage detail
- Plug smoke header fields
- Matrix cell exact wording

## Deferred Ideas

- phx_gen_auth_doc_contract_test.exs → Phase 121
- Legacy capture CI → adopter signal only
- Pow/bearer lanes → v2
