# Phase 209: Collision-Free Emission - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-25
**Phase:** 209-collision-free-emission
**Areas discussed:** Orphan-safe drop shape, Legacy name retirement + sibling exposure, Rerun detection rewrite, Truncation NOTICE guard

The standing rule is to research first and then recommend. Four research agents ran in parallel, one per area. Their findings were combined into one coherent recommendation set, and the maintainer confirmed it with a single approval.

---

## Orphan-safe drop shape

| Option | Description | Selected |
|--------|-------------|----------|
| Inline frozen DO block | `to_regprocedure` + `tgfoid` check, then `DROP FUNCTION` without CASCADE; `RAISE WARNING` if the function is still referenced | ✓ |
| Installed helper SQL function | Called from migrations; missing on 0.10.x installs, couples to install order | |
| Plain RESTRICT drop | Today's behaviour; fails `up` in the shared-legacy case | |

**When referenced:** WARNING, keep the function. Rejected: skip silently, NOTICE (logged at `:info`, so adopters miss it), EXCEPTION (blocks the upgrade).

## Legacy name retirement + sibling exposure

| Option | Description | Selected |
|--------|-------------|----------|
| Rely on health (212) and the guide (213) only | No migrate-time protection | |
| Warn always | The migration continues even when it moves a sibling onto another table's rules | |
| Warn on a strict improvement, raise when a sibling would switch rules | A post-condition guard with a HINT, atomic, plus an advisory gen-time warning | ✓ |
| Raise always until the sibling is regenerated | Blocks the moved table's own fix | |

**User's choice:** "auto follow ur recs keep us on track". This accepted option 1, the full recommended set, including the HIGH-IMPACT migrate-time `RAISE EXCEPTION` in the legacy-keeping-table-only case.

## Rerun detection rewrite

| Option | Description | Selected |
|--------|-------------|----------|
| Name-based matching (status quo) | Collides on the `_` join and on 63-byte cuts | |
| `ON`-clause matching on normalized CREATE TRIGGER statements | Unqualified `ON` matches any schema (conservative) | ✓ |

## Truncation NOTICE guard

| Option | Description | Selected |
|--------|-------------|----------|
| Logger-based | Would see nothing: Postgrex doesn't log, ecto logs DDL only at `:info`, and test Logger is `:warning` | |
| Telemetry `result.messages`, code 42622, `after_suite` + `at_exit` | Verified to exit non-zero; positive control plus canary contract test | ✓ |
| PG promote NOTICE → ERROR | Not possible | |
| Static ≤63-byte check only | Kept as a second layer, not the SC4 mechanism | |

## Claude's Discretion

- Helper names and how the code is split into modules.
- Warning and HINT wording.
- Test layout.
- Guard granularity: one DO block per function or per migration.

## Deferred Ideas

- **Phase 212:** the `:shared_capture_function` and duplicate-trigger health findings.
- **Phase 212/213:** the pre-0.10 unqualified `ON` under a non-public `search_path`.
- **Phase 213:**
  - the upgrade guide and CHANGELOG security note;
  - the frozen 0.10.x `down` `CASCADE` rollback hazard, which is critical.
