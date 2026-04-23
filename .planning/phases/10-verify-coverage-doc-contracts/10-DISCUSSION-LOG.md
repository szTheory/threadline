# Phase 10: Verify coverage & doc contracts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 10 — Verify coverage & doc contracts
**Areas discussed:** Expected audited table list; Mix task design; Doc contract tests; CI wiring
**Mode:** User selected **all** areas and requested parallel **subagent research** plus a single synthesized recommendation bundle (applied in CONTEXT.md as D-01–D-18).

---

## Expected audited table list (TOOL-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Host config explicit list | Expected tables in `config/*.exs` / `runtime.exs`; Health for discovery only | ✓ |
| B — Checked-in manifest | Versioned JSON/YAML list; great for diffs; second source unless generated | |
| C — All `public` user tables | Matches raw Health enumeration; zero config; wrong semantics for most apps | |
| D — Parse migrations | Fragile across squashes and repos | |
| E — Schema macro introspection | Good for schema-centric apps; misses raw SQL / legacy tables | |

**User's choice:** Research-synthesized bundle — **explicit expected set + Health-only catalog implementation** (fail closed if verification invoked without configuration).

**Notes:** Prior art (PaperTrail, Audited, Hibernate-style) favors **opt-in / explicit** audited entities, not full-catalog sweeps, to avoid false positives on system tables.

---

## Mix task design (`mix threadline.verify_coverage`)

| Option | Description | Selected |
|--------|-------------|----------|
| Thin Mix → Health | Single SQL source; formatter + exit codes in Mix | ✓ |
| Standalone SQL in Mix | Isolated but high drift risk vs Health | |
| Shared lib policy only | Pure filter over `trigger_coverage/1` tuples; Mix is I/O | ✓ (combined with thin Mix) |

**User's choice:** Thin task + **no duplicate SQL**; stdout table + summary; `Mix.raise` for misuse; exit **1** for audit failure.

**Notes:** Idiomatic with `mix credo`, `mix format --check-formatted`, Ecto tasks — exit-code-first, human-readable default.

---

## Doc contract tests (TOOL-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Compile-checked mirror modules | README-critical snippets live in `test/` (or similar) and always compile | ✓ |
| `Code.string_to_quoted!/2` only | Fast but misses renames | |
| Doctest-only | Great for `@moduledoc`; README not native | Partial — use as secondary |
| README extraction + compile | Possible; brittle fences | Optional later |
| Separate example app | Best E2E; highest friction | Defer unless needed |

**User's choice:** **Hybrid:** compile-checked modules + doctests where appropriate; do not use parse-only as sole gate; `groups_for_modules` is not an API boundary.

---

## CI wiring

| Option | Description | Selected |
|--------|-------------|----------|
| Extend `ci.all` + new `verify.*` | Single blessed full gate; Mix source of truth | ✓ |
| Actions-only extra steps | Easy but split local vs CI | |
| New separate required job | Only if policy needs visible check | Defer — reuse `verify-test` |

**User's choice:** **`verify.threadline` + `verify.doc_contract`** atoms composed into **`ci.all` after `verify.test`**; same steps in **`verify-test` GHA job**; update **Nyquist CI-02** literal.

---

## Claude's Discretion

- Exact config keys, optional CLI overrides for expected tables, optional JSON flag timing.

## Deferred Ideas

- JSON default output; multi-schema Health; `boundary` dependency — see CONTEXT.md `<deferred>`.
