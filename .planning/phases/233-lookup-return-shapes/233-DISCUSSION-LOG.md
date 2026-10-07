# Phase 233: Lookup Return Shapes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-10-03
**Phase:** 233-lookup-return-shapes
**Areas discussed:** naming and completeness, migration and semver, existence semantics and scope surfaces, option surface, error design, fail-closed scoping

**Process:**
- **Round 1.** Four advisor researchers ran at the minimal_decisive tier. The maintainer rejected that roll-up as too shallow.
- **Round 2.** Four deep researchers ran. They read `prompts/`, covered prior art (Ecto, phoenix_ecto, Phoenix generators, Ash, Oban, Req, Rails, Django) and applied the expert lenses. They also surfaced two angles the roadmap did not name: the semver tension of the in-place change, and the naming convention. Round 2 found the fail-open scope bug and the 500 on a malformed `TransactionLive` id.
- **Outcome.** The maintainer asked for a recommendation, then accepted R1–R7 plus folding the scope fix in.

---

## Naming

| Option | Description | Selected |
|--------|-------------|----------|
| Plain nouns + `!` | the locked names; `File.read`/`File.read!`, `Ash.get/3` precedent | ✓ |
| `fetch_*` + `fetch_*!` | `Map.fetch` convention; renames 2 shipped names | |
| `fetch_*` + `get_*!` | phx.gen feel; two prefixes per subject | |

## Completeness

| Option | Description | Selected |
|--------|-------------|----------|
| Add `incident_bundle!/2` | makes "everywhere" true | ✓ |
| Leave it out | literal requirement text | |
| Also `as_of!/4` | its errors are outcomes to branch on; deferred | |

## Fate of `Threadline.Query.audit_transaction/2`

| Option | Description | Selected |
|--------|-------------|----------|
| Deprecated delegate keeping nil | matches 232 D-02/D-04 | ✓ |
| Change in place | silent: a tuple is truthy | |
| Hidden, unchanged | contradicts the CHANGELOG, which already treats it as callable | |

## `transaction_context/2` migration

| Option | Description | Selected |
|--------|-------------|----------|
| In place, documented 1.0 break | struct→tuple fails loudly (KeyError) | ✓ |
| `legacy: true` opt | conflicts with the unknown-keys-raise rule | |
| New name for the new shape | violates the locked API-06 | |

## Existence semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Row-first via one shared fetch | zero-change txns are real (retention) | ✓ |
| Inline duplicate of incident_bundle logic | re-divergence risk | |
| Derive from changes | an empty txn reads as not_found | |

## Option surface and hydration

| Option | Description | Selected |
|--------|-------------|----------|
| Allowlist repo/storage_schema/scope/scope_query_fn; always hydrate `.action` | removes the nil ambiguity | ✓ |
| Allowlist, no hydration (round-1 pick) | layer-purity argument; overridden | |
| Pass `:preload` through | reaches the unscoped, unbounded `:changes` | |
| Adopter-settable `:surface` | relabels binding shapes | |

## Error design

| Option | Description | Selected |
|--------|-------------|----------|
| `Threadline.NotFoundError` + Plug 404, bare `:not_found` value | phx FallbackController fit | ✓ |
| `Ecto.NoResultsError` | message leaks scope SQL | |
| `{:error, %NotFoundError{}}` | breaks the fallback clause and precedent | |

## Malformed id

| Option | Description | Selected |
|--------|-------------|----------|
| Non-UUID binary → `:not_found`; wrong type → ArgumentError | fixes the TransactionLive 500 | ✓ |
| Keep ArgumentError and fix the LiveView with a cast | strict, but every adopter needs a guard | |
| `{:error, :invalid_id}` | a third shape; no fallback clause | |

## Fail-open `Scope.apply` (security, maintainer scope call)

| Option | Description | Selected |
|--------|-------------|----------|
| Fold the fail-closed fix into 233 | cheap before 1.0; the same files are already in play | ✓ |
| Separate phase before 237 | extra phase gate | |
| Defer past 1.0, docs only | tightening later needs 2.0 | |

**User's choice:** "i authorize u, i accept that". This accepts all recommendations plus option 1.

## Claude's Discretion
- The name and return shape of the shared hidden fetch, and its location.
- The ArgumentError wording.
- The plan split.

## Deferred Ideas
- `as_of!/4` (additive in 1.x).
