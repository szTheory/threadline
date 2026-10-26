# Phase 226: Pure Property Tests and Run Budget - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-01
**Phase:** 226-pure-property-tests-and-run-budget
**Areas discussed:**
- the cursor property and the SQL it can't see
- scale wiring
- independent expected results
- mutation evidence and timing
- defects the properties expose

**Process:** I first proposed initial recommendations. The maintainer asked for deeper research: one subagent per area, covering Elixir idioms, cross-ecosystem prior art, footguns and contributor experience. Four `gsd-advisor-researcher` agents ran in parallel at the full_maturity tier. Their reports were combined into one consistent set of recommendations, and the maintainer chose **"1 — accept all"**, including Q1-Q4.

---

## Cursor property and the SQL it can't see

| Option | Description | Selected |
|--------|-------------|----------|
| A | Pure property over an in-memory model of the SQL; the SQL boundary documented as a gap | |
| B | A, plus DB example tests that pin the model to the real SQL on fixed tie-heavy fixtures | ✓ |
| B+ | B, plus moving the post-fetch page assembly into `Cursors` (behaviour-preserving lib refactor) | ✓ |
| C | Extract a shared comparator or ordering constant for both the SQL and the model | Rejected: the mutation control could never go red |
| D | Make the cursor property DB-backed | Rejected: breaks the "pure" criterion; that is 227's harness |

**User's choice:** B + B+ (accept all).

## Scale wiring

| Option | Description | Selected |
|--------|-------------|----------|
| A | One variable, read at runtime, `pure`/`db` tier multipliers, env on the Flake Detection repeat step | ✓ |
| B | Separate one-shot `--only property` step at scale | Fallback, if the budget doesn't fit |
| C | Two variables (pure and DB) | |
| D | `config :stream_data, max_runs:` or an ExUnit tag | Rejected: an explicit per-call `max_runs:` overrides app config |

**User's choice:** A.

## Independent expected results

| Sub-target | Options considered | Selected |
|------------|--------------------|----------|
| ChangeDiff | expected output from the moduledoc table; facts generated first and the struct built from them; structural checks; metamorphic checks | Facts-first as the primary oracle, plus structural and metamorphic checks |
| Redaction policy | predicate oracle; inputs built by construction with tagged defects; boundary ladder | Built by construction with the ladder folded in |
| Export | decode with NimbleCSV; hand-written strict RFC 4180 decoder; second CSV library; OTP `:json` | Strict decoder for CSV, `Jason` for JSON, plus a cross-format agreement property |

**User's choice:** as recommended.

## Mutation evidence and timing

| Option | Description | Selected |
|--------|-------------|----------|
| A1 | Mutation applied by hand, then reverted, with prose evidence | |
| A2 | Committed patches plus a re-runnable script (K seeds) | ✓ |
| A3 | Seam mutants inside the test suite | Not adopted |
| A4 | muex or Muzak | Deferred as an optional sweep |
| B2 | Seeded generator-coverage floors | ✓ |
| W2 | Each new file's own cost, primary timing figure | ✓ |
| W1 / W3 | Local whole suite and CI comparison, as context | ✓ |

**User's choice:** A2 + B1 + B2; timing W2 primary, with W1 and W3 as context; partition weights untouched.

## Defects the properties expose

| Finding | Recommendation | Selected |
|---------|----------------|----------|
| Q1: export nil → `{}` defaults | Document and pin now, change in v1.45 | ✓ |
| Q2: NimbleCSV leaves a bare `\r` unquoted | Fix in 226 | ✓ |
| Q3: non-list `exclude:`/`mask:` silently accepted; non-binary placeholder raises FunctionClauseError | Fix in 226 (raise ArgumentError), keep the grapheme limit, correct the docs | ✓ |
| Q4: CSV formula injection | Out of scope, backlog/v1.45 | ✓ |

## Claude's Discretion
- File names and layout of the property tests, the exact refactor shape, the plan/wave split, and the mechanism for the CSV `\r` fix.

## Deferred Ideas
- v1.45: export's nil defaults; CSV formula injection.
- An optional muex sweep.
- A DB-backed cursor layer in 227.
- Partition weight refresh in 230.
