# Project Research Summary

**Milestone:** v1.45 "1.0 API Contract" (last rung before 1.0.0; current package line 0.12.0)
**Synthesized:** 2026-10-02
**Inputs:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md, CONTRACT.md

This summary reconciles five research files that were produced independently and
disagree with each other in places. Where they disagree, this document states ONE
resolution with reasoning, not a menu. Genuinely one-way/judgment calls that only
the maintainer can ratify are pulled into "Decisions for the Maintainer" below.

---

## Executive Summary

Threadline's 1.0 gap is not missing capability — the read API (history, as-of,
timeline, actor-scoped views, cursor paging, diff, export) is already more complete
than every surveyed peer (Carbonite, PaperTrail, ExAudit, Logidze, django-simple-history,
Hibernate Envers). The gap is **surface-area discipline**: three modules
(`Threadline`, `Threadline.Query`, `Threadline.Investigation`) each expose a plausible
"public API" for the same jobs, with inconsistent arg shapes, two incompatible page
structs, inconsistent not-found handling, and ~129 of 169 public functions missing
`@spec`. None of this needs new product scope. All of it needs one coherent,
enforced, documented contract — which is exactly what a 1.0 declaration is for.

The recommended approach is: collapse the facade to one public module (`Threadline`),
make the two genuinely structural decisions (the bounded-history default and the
`AuditTransaction`↔`AuditAction` association) deliberately rather than by default,
backfill specs/docs against the *settled* surface (not before), freeze a two-tier
stability contract (ordinary Hex semver for `lib/`, a separate additive-only promise
for everything the library writes into the adopter's own PostgreSQL instance), raise
the PostgreSQL floor to 15 (PG 14 reaches EOL six weeks after this milestone's likely
ship date), and only then flip `release-please`'s `bump-minor-pre-major` flag and cut
1.0.0. Every one of these is "cannot cheaply undo once adopters depend on it" —
bundling them into one major-version boundary is exactly what adopters expect from a
1.0 upgrade, and exactly what this milestone budgets for.

The key risk is not under-building but over-building: "declaring 1.0" carries
psychological weight disproportionate to the milestone's actual scope (spec
completion, consolidation, docs, floor, release mechanics). The parked operator UI,
any taste-driven renaming with no spec/consolidation rationale, and any rewrite of
stable internals (trigger SQL, capture pipeline) must be explicitly refused scope,
not quietly absorbed because "it's 1.0." A second risk is specific to an audit
library: a silently bounded default on `history`/`row_history` is a correctness
regression, not a UX nicety, if adopters cannot tell a capped result from a complete
one.

---

## Reconciling the Five Conflicts

### 1. Bounded default limit for `row_history`/`history` — RESOLVED

**Conflict:** FEATURES recommends a bare-list 200-row default capped silently with a
telemetry signal only; PITFALLS calls that insufficient for an audit library and
wants the return shape itself to carry a structural truncation signal.

**Resolution:** Default `:limit` to **200**, keep the return a **bare list** (no
return-shape change — this preserves the "collection reads are bare" convention from
§3 of FEATURES/ARCHITECTURE and keeps `Threadline.Page` reserved for genuinely paged
calls), and make the signal structural rather than inferential by splitting the
promise in two instead of trying to make one return value do both jobs:

- The capped, unpaged call (`row_history(schema, id, repo: Repo)`) is documented as
  **not a completeness proof** — hitting exactly `:limit` rows does not establish
  there are no more, by design, the same way `Enum.take/2` doesn't.
- The **only** call shape that can structurally prove completeness is the cursor
  path: `row_history(schema, id, repo: Repo, cursor: :start, page_size: n)` →
  `%Threadline.Page{entries:, cursor:, has_more: false}` once exhausted. This is
  already a real, existing mechanism (the unified `Page` struct, see §2 below) —
  nothing new has to be built for it to serve as the "structural signal" PITFALLS
  demands, it only has to be documented as the audit-grade completeness path.
  `limit: :infinity` is the explicit opt-out for "give me everything in one shot."
- Emit `[:threadline, :row_history, :truncated]` telemetry when `length(entries) ==
  limit`, for production observability (ops teams alert on a table they expect never
  to truncate). This is additive, not the primary correctness mechanism.
- Passing `:limit` and `:cursor` together raises `ArgumentError` — they are mutually
  exclusive modes.

This rejects option (a) (silent cap + telemetry only, FEATURES as originally
written) as insufficient on its own for this domain, rejects (b) (make the unpaged
call itself return a `Page`, which would break the bare-collection-reads convention
for every other collection read), and is a refinement of (c) (the paged function is
the documented default path for anyone who needs proof of completeness) combined
with telemetry as a secondary signal. (d) (require an explicit `limit:` always) is
rejected as needless friction for the common "give me the last couple hundred
edits" case that 200 already serves well.

**ONE-WAY.** This is the single largest behavior change for any future adopter of
`row_history`/`history` (today unbounded). See API-01 below and the maintainer
question in the next section — the number (200) and the choice not to change the
return shape are both worth the maintainer's explicit sign-off.

### 2. Public status of `Threadline.Query` / `Threadline.Investigation` — RESOLVED

**Conflict:** CONTRACT's matrix lists both modules as stable public API (reflecting
their current `@moduledoc`s, which literally say "this is the public API").
ARCHITECTURE and FEATURES both independently conclude they should be demoted to
`@moduledoc false` behind the `Threadline` facade, with one documented escape hatch
kept.

**Resolution:** ARCHITECTURE and FEATURES win; **CONTRACT's matrix row is stale** —
it describes the *current* state, not the *target* 1.0 state, and both other
research files did the deeper call-site analysis (grepping every guide and
cross-checking which modules guides actually call) that CONTRACT's contract-matrix
pass did not redo. Final shape:

- `Threadline` is the only public facade. Every adopter-facing read/write entry
  point lives here exactly once.
- `Threadline.Query` and `Threadline.Investigation` both become `@moduledoc false`.
  They remain real modules — the shared Ecto implementation `Threadline` delegates
  to — but stop being advertised as parallel public APIs.
- **Exactly one** documented escape hatch survives: `Threadline.Query.timeline_query/1`
  (already returns `Ecto.Query.t()`), promoted into `Threadline`'s own moduledoc as
  "the composition escape hatch" for adopters who need to add their own `where`/`join`
  on top of a timeline query. `row_history_query/3` and the other raw query builders
  (`history_query/3`, `as_of_query/4`, `export_changes_query/1,2`) move to `@doc false`
  — they are composition primitives for `Export`, not a second supported entry point.
- Three guides (`guides/audit-indexing.md`, `guides/how-threadline-works.md`,
  `guides/code-walkthrough.md`) call the soon-to-be-hidden modules directly today and
  must be updated to call `Threadline.*` instead — this is in-scope, small, and
  already identified.

This matches Ecto (`Ecto.Repo` is the facade; `Ecto.Query` is a DSL, not a second
facade), Oban (`Oban` is the facade; query-building internals aren't advertised), and
Req (`Req` is the facade; `Req.Request` is the one documented advanced escape hatch).
**ONE-WAY, breaking** for the (believed small) set of adopters calling
`Threadline.Query.*`/`Threadline.Investigation.*` directly instead of the facade.

### 3. `AuditTransaction` ↔ `AuditAction` Ecto association edge — RESOLVED

**Conflict:** ARCHITECTURE recommends Option C (drop the Ecto `belongs_to`/`has_many`
pair, move the join into an exploration-layer helper that still returns the same
`.action` key shape) with Option A (keep and document the association) as the
fallback if C's cost is too high for the milestone budget.

**Resolution: adopt Option C**, checked against PITFALLS and CONTRACT and found
mutually reinforcing, not in tension:

- **PITFALLS' struct-exposure point** (every field and association on a returned
  Ecto struct becomes public API the moment 1.0 ships) argues *for* decoupling now:
  the mutual `belongs_to`/`has_many` pair is the most literal possible violation of
  CLAUDE.md's "capture does not own action naming, semantics does not own row
  capture" boundary that still compiles, and it is exactly the kind of schema-shape
  commitment that is expensive to undo after 1.0 (Pitfall 7's own recovery-cost table
  rates an exposed, later-regretted struct/association shape as HIGH cost to fix
  within the 1.x line).
- **CONTRACT's additive-only DB tier** is satisfied either way at the SQL level —
  the `action_id` foreign key and its `ON DELETE SET NULL` constraint stay exactly as
  they are (that's a capture-migration concern, not an Ecto-schema concern). Option C
  only removes the *compile-time* Ecto association declared on the two schema
  structs; it does not touch the database contract at all.
- Half of the codebase's own usage (`Threadline.Export`'s join path,
  `filter_by_correlation/2`) **already** hand-writes the join instead of using the
  association — proving the coupling isn't load-bearing even internally.
- Option C's blast radius is bounded and entirely internal: five known call sites
  inside `lib/threadline/` (`Query.preload_investigation_context/3`, two
  `Investigation` preload sites, two LiveViews), all of which can preserve the exact
  external `.action` key shape via manual hydration (`Map.put(transaction, :action,
  action)`), so **no public struct shape changes for adopters** — unlike Option B's
  full rewrite, which would also break the `%LinkedChange{}`/`%IncidentBundle{}`
  public struct contract.

Net effect: Option C is the one choice of the three that is simultaneously (a) the
most architecturally honest relative to CLAUDE.md's named layer boundary, (b)
non-breaking for the public struct shapes adopters already depend on, and (c)
proven by the codebase's own export path to need no Ecto-level coupling. **ONE-WAY**
regardless (all three options freeze a schema/association shape once 1.0.0 ships) —
flagged for the maintainer below because it is foundational, cross-cutting work done
in Phase 231 before anything else.

### 4. Deprecate vs. remove wording — RESOLVED, single wording

**Conflict:** three slightly different phrasings across the files. PITFALLS: hard-
deprecate in 1.0.0, keep working through the 1.x line, removal is "a 2.0 decision to
make later." STACK: `@deprecated` + "removed no earlier than 2.0.0." CONTRACT:
removal reserved for 2.0. FEATURES, written before the others, separately proposed
removing the losing entry points in **1.2** — this is the one genuine outlier and is
explicitly **superseded** by the other three, which converge independently.

**Final wording (use verbatim in CHANGELOG/guides):**

> Deprecated in 1.0.0. Kept as a functioning, fully-specced delegate for the rest of
> the 1.x line. Removed no earlier than 2.0.0, which is not currently planned.

Mechanics, unified across all five files' agreement:

- `@deprecated "Use Mod.kept_fun/arity instead."` + `defdelegate` (never
  `@doc deprecated:` alone, never a runtime `Logger.warning` alone) — this is the
  only one of the three Elixir mechanisms that an adopter's own
  `--warnings-as-errors` CI will see as a build failure, which is the entire point
  of an enforceable 1.0 contract.
- `@doc since: "1.0.0"` on the kept function; the deprecated function keeps its own
  `@doc` (not `@doc false`) so it still renders with ExDoc's automatic deprecated
  badge for anyone who lands on its hexdocs page from an old link.
- Every deprecated function is a **pure one-line delegate** with no independent
  logic (so there's nothing to drift), gets a parity test asserting byte-identical
  output to its replacement, and gets a **real spec matching the replacement's spec**
  — "it's going away" is not a license to ship `term() -> term()` or skip the spec
  entirely; deprecated functions count toward the 1.0 spec-coverage gate like
  everything else public.
- Grep `lib/`, `test/`, the example app, and every guide for every retiring name
  before merging the deprecation, and update all internal/example/guide call sites
  to the new name in the same phase — a library that ships its own deprecation
  warning internally undermines the contract on day one.

**Why hard `@deprecated` despite the `--warnings-as-errors` impact, and why that's
fine right now:** Threadline has no external pilot and no production adopter base
yet (`PROJECT.md`: "Hold — v1.28 External Pilot only on sustained real-adopter
signal," never shipped). There is no installed base today whose CI would actually go
red from this deprecation. That is precisely the reason to do the hard, enforceable
thing *now*, at zero real cost, rather than defer to a softer mechanism that would
under-serve the real future adopters this milestone exists to protect. Once 1.0
ships and adopters exist, this same mechanism will trip their
`--warnings-as-errors` builds by design — that's the contract working as intended,
not a defect; the mitigation is precise replacement-naming in the warning text and a
dedicated CHANGELOG `### Deprecated` section, not avoiding the mechanism.

### 5. Consistency pass — confirmed, no further conflicts found

- **Naming:** `history/3` and `row_history/4` merge into one `Threadline.row_history/3`;
  paging is the `:cursor`/`:page_size` option pair, not a second function name.
  `timeline/2`/`timeline_page/2` stay as the one deliberate two-name exception
  (multi-table export/operator-UI paging is reached for independently often enough
  to earn a separately documented function). `actor_history/2` (transactions) and
  `actor_window/3` (cross-table changes) keep their current, different names — the
  distinction is real, not accidental, and gets stronger `@doc` cross-linking
  instead of a rename.
- **Filters fold into opts.** The `filters`/`opts` two-list split that exists only
  on the `Investigation` side today is dropped; one keyword list per call, matching
  `Ecto.Repo.all/2`/`Req.get/2` precedent. Per-function key allowlists stay as
  validation logic, not a second positional argument.
- **Return-shape convention, confirmed and finalized:** bare values for collection
  reads (`row_history`, `timeline`, `actor_window`, `actor_history`,
  `audit_changes_for_transaction`); `{:ok, _}`/`{:error, :not_found}` with `!`-raising
  siblings for single-subject lookups (`audit_transaction/2`, `transaction_context/2`
  both move to this shape — today they're the two outliers, a bare `nil` and a
  struct-with-nil-fields respectively, while `incident_bundle/2` already does it
  correctly); `ArgumentError` for bad options/invalid input shapes; no NimbleOptions
  (hand-rolled validators are already more specific than NimbleOptions' generic
  messages, and the options surface isn't shared across functions the way Broadway's
  is, so NimbleOptions' main selling point doesn't apply).
- **Floor:** Elixir stays `~> 1.15`/OTP 26 (matches Oban's and LiveView's own current
  floor — raising it strands adopters for zero corresponding capability). PostgreSQL
  floor raises to **15** (PG 14 is EOL 2026-11-12, about six weeks after this
  milestone's likely ship date) — the only floor that actually moves, and it's a
  `BREAKING CHANGE:`-flagged, CI-matrix-verified documentation/CI change, not a
  `mix.exs` constraint (Ecto/Postgrex precedent: PG server version isn't a
  compile-time dependency field).
- **Release:** flip `release-please-config.json`'s `bump-minor-pre-major` to `false`
  in the same PR as the 1.0-scoped changes, and add a `Release-As: 1.0.0` commit
  footer once all 1.0 work has landed — without both, the next release-please run
  produces `0.13.0`, not `1.0.0` (confirmed live risk: this exact flag is still
  `true` in the repo today).
- **DB contract:** additive-only for the life of 1.x — table/index/GUC/trigger-
  function-naming-scheme stay frozen, new columns/indexes/finding-codes/telemetry
  events may be added in any minor. A **named exception class** (security or
  correctness-critical fixes to generated SQL only — the same shape as 0.11.0's
  mandatory trigger regeneration) is the one case a minor may require regenerating
  triggers; routine evolution may not.

---

## Decisions for the Maintainer

These are the genuinely one-way, semver-shaping calls from the reconciliation above.
Everything else in this research is a recommendation the roadmap can proceed on
without further sign-off.

1. **Bounded `row_history`/`history` default.** Recommend: cap at **200**, keep the
   return a bare list (no shape change), document the cursor/`Page` path as the only
   provably-complete read, add truncation telemetry. Alternative: skip the default
   entirely and require an explicit `limit:` on every call (more friction, zero
   silent-truncation risk by construction). **Use 200 with telemetry+cursor-as-proof,
   or require explicit `limit:` always?**

2. **PostgreSQL floor.** Recommend: raise to **15** at the 1.0.0 cut, documented as a
   `BREAKING CHANGE:`. Alternative: keep 14 at 1.0.0 and pre-announce a PG 15 floor
   for 1.1.0 at the PG 14 EOL date (zero disruption on the 1.0.0 cut itself, but ships
   a "trustworthy" 1.0 contract whose stated floor is already-or-nearly EOL on day
   one). **Raise to PG 15 now, or defer the floor bump to 1.1.0?**

3. **`AuditTransaction` ↔ `AuditAction` association.** Recommend: **Option C** —
   drop the Ecto `belongs_to`/`has_many` pair, move the join into an
   exploration-layer helper, keep the DB foreign key and the `.action` key shape
   unchanged for callers. Alternative: **Option A** — keep the association as-is,
   document it as an intentional, formalized contract (zero code changes, but freezes
   a cross-layer Ecto coupling CLAUDE.md's own layering rule argues against).
   **Decouple the association (Option C), or keep and document it (Option A)?**

4. **Facade collapse.** Recommend: hide `Threadline.Query`/`Threadline.Investigation`
   (`@moduledoc false`), `Threadline` becomes the only public facade, and
   `timeline_query/1` is kept as the sole documented raw-Ecto-composition escape
   hatch. Alternative: keep `Threadline.Investigation` public alongside `Threadline`
   (closer to today's status quo, and to how CONTRACT's matrix currently describes
   it) at the cost of re-introducing the "which of three modules is the real API"
   confusion this milestone exists to fix. **Collapse to one facade with one escape
   hatch, or keep `Investigation` public too?**

5. **Deprecation removal horizon.** Recommend: `@deprecated` at 1.0.0, functioning
   through the entire 1.x line, **removed no earlier than 2.0.0, not currently
   planned**. Alternative: name a specific earlier removal target (e.g., 1.2, as one
   early draft in this research suggested) to force a concrete cleanup date.
   **Leave removal open-ended at "no earlier than 2.0, not planned," or commit to a
   specific earlier 1.x removal release?**

---

## Key Findings

**From STACK.md:** Elixir floor stays `~> 1.15` (matches Oban/LiveView's own current
floor; no feature in scope needs newer). PG floor raises to 15 (EOL-driven). Spec/doc
coverage gate: a new `Code.fetch_docs/1` + `Code.Typespec.fetch_specs/1` ExUnit test,
no new dependency (reuses the repo's own `verify.dialyzer_slice`-style
"proves the gate ran" pattern). Deprecation: `@deprecated` + `defdelegate`, paired
with `@doc since:` on the kept function. Release: `Release-As: 1.0.0` footer +
flip `bump-minor-pre-major` to `false`, verified via the existing
`verify.bump_rehearsal` gate before merge.

**From FEATURES.md:** Merge `history`/`row_history` into one `row_history/3` with a
`:cursor` opt; fold filters into opts; unify `TimelinePage`/`ActorHistoryPage` into
one `Threadline.Page{entries, cursor, has_more}`; standardize single-subject lookups
on `{:ok,_}/{:error,:not_found}` with `!` siblings; do not adopt NimbleOptions; four
table-stakes docs are missing (supported-table-shapes, redaction threat model,
stability/semver policy, upgrading-to-1.0) and none is individually hard.

**From ARCHITECTURE.md:** Full public-surface inventory (~55 non-hidden modules,
~85 already correctly `@moduledoc false`) confirms the baseline gap and pinpoints
exactly which "documented but genuinely internal" functions need hiding
(`Telemetry`'s `emit_*` family, `Query`'s raw query builders,
`Health.coverage_by_schema/1` already correctly flagged). Facade collapse and the
`AuditTransaction`↔`AuditAction` edge are the two foundational, must-happen-first
structural decisions; a dependency-ordered 8-step build sequence is given and maps
directly onto the phase breakdown below.

**From PITFALLS.md:** 14 named pitfalls, the two highest-leverage being (1) exposing
raw Ecto structs makes every field public API — mitigated by explicitly documenting
the stable field subset per schema rather than a full opaque-struct rewrite (too big
for this milestone), and (2) silent truncation on a bounded default is a
compliance/correctness risk specific to an audit library, not an ordinary API
nicety — resolved above. `release-please`'s `bump-minor-pre-major: true` is a
**confirmed live risk today**: left as-is, this milestone's breaking commits produce
`0.13.0`, not `1.0.0`.

**From CONTRACT.md:** The real 1.x contract is wider than the Elixir API — it
includes everything Threadline writes into the adopter's own PostgreSQL instance
(table/index/trigger-function-name/GUC names), which needs a **separate,
additive-only promise** alongside ordinary Hex semver, enforced by new
schema-snapshot and literal-string contract tests following the repo's own proven
`telemetry_registry_contract_test.exs`/`public_surface_contract_test.exs` pattern.
`data_after`/`changed_fields` JSONB content must be promised at the key/shape level
only, never byte-stable (PostgreSQL's own serialization isn't stable across majors).
Ash's "6 months of critical fixes on the prior major" is the cleanest precedent for
the 0.12.x backport window after 1.0.0 ships.

---

## Recommended Requirements Sketch

Grouped by category, new REQ-ID prefixes (do not reuse v1.44 IDs).

### API — public surface consolidation
- **API-01** — `Threadline.row_history/3` merges `history/3` and `row_history/4`;
  filters fold into opts; default `:limit` 200 (bare list, undocumented-as-complete);
  `:cursor`+`:page_size` returns `%Threadline.Page{}`; `:limit`+`:cursor` together
  raises `ArgumentError`. Testable: a call with >200 rows returns exactly 200 and
  fires `[:threadline, :row_history, :truncated]`; a cursor walk to exhaustion
  returns `has_more: false` and the union of all pages equals the full row history
  fixture.
- **API-02** — `actor_history/2` (transactions) and `actor_window/3` (cross-table
  changes) keep distinct names, each documented with an explicit return-type
  statement and a cross-link to the other. Testable: doc-contract test asserts both
  `@doc` strings mention the other function by name.
- **API-03** — `timeline/2`/`timeline_page/2` remain the one dual-name exception; no
  third function-naming pattern is introduced anywhere in the facade.
- **API-04** — `Threadline.Query` and `Threadline.Investigation` become
  `@moduledoc false`; `Threadline` is the sole public facade;
  `Threadline.Query.timeline_query/1` is the one documented escape hatch, promoted
  into `Threadline`'s own moduledoc. Testable: `public_surface_contract_test.exs`
  asserts the two modules are hidden and only `timeline_query/1` remains
  doc-visible among `Query`'s functions.
- **API-05** — Unify `TimelinePage`/`ActorHistoryPage` into one
  `Threadline.Page{entries, cursor, has_more}`; every paged function returns it.
  Testable: every `*_page`/`:cursor`-returning call site returns the same struct
  type, asserted by a shared property test.
- **API-06** — `transaction_context/2` and `audit_transaction/2` return
  `{:ok, _}`/`{:error, :not_found}`; add `transaction_context!/2` and
  `audit_transaction!/2` raising siblings. Testable: a nonexistent id returns
  `{:error, :not_found}` from both; the `!` siblings raise.
- **API-07** — Implement the `AuditTransaction`↔`AuditAction` edge per the
  maintainer's chosen option (default: Option C, decoupled association +
  exploration-layer join helper preserving the `.action` key). Testable: every
  existing preload call site's return shape (`transaction.action`) is unchanged,
  verified by the existing `Investigation`/`TimelineLive`/`TransactionLive` test
  suites passing unmodified at the call-site assertion level.
- **API-08** — Every retired entry point (`history/3`'s old unbounded-no-filters
  shape via the `row_history/4`/`row_history_page/4` names, the `filters`-as-second-arg
  shape) gets `@deprecated` + `defdelegate` on every facade that exposed it, `@doc
  since: "1.0.0"` on the kept function, a parity test, and a matching (not `term()`)
  spec. Testable: `mix compile --warnings-as-errors` is clean on `lib/`, `test/`, and
  the example app; calling a deprecated name emits exactly one compiler warning
  naming the replacement.

### SPEC — typespec/doc completion and gate
- **SPEC-01** — A new `test/threadline/public_api_contract_test.exs` using
  `Code.fetch_docs/1` + `Code.Typespec.fetch_specs/1` asserts every public,
  non-`@doc false` function in every non-`@moduledoc false` module under
  `lib/threadline` has both a `@doc` and a `@spec`. Testable: the test fails if any
  current gap (baseline ~129/169) is reintroduced.
- **SPEC-02** — No public function has a bare `term()`/`any()` spec on an argument
  or return with a real shape; option-list arguments use a named `@type opts ::
  [...]`, not bare `keyword()`. Testable: an agent-review pass against a documented
  rubric (not a mechanical count) as part of phase verification.
- **SPEC-03** — `@doc group:` metadata on the `Threadline` facade only, grouped as
  "Capture & Transactions" / "Querying & Timelines" / "Actions & Context" /
  "Operations". Testable: `mix docs` renders four groups on the `Threadline` page.
- **SPEC-04** — Deprecated functions' specs exactly match their replacement's spec
  (modulo translated arg shape); no hand-duplicated spec on a `defdelegate` target.
  Testable: a lint/test comparing the deprecated function's declared types against
  the target's.

### CONTRACT — stability policy and DB-contract enforcement
- **CONTRACT-01** — Publish `guides/stability.md` with two named tiers (Elixir API:
  ordinary Hex semver; Database Contract: additive-only for columns/indexes/trigger-
  function-naming-scheme/GUC name), plus a named exception class (security- or
  correctness-critical fixes only) permitting a mandatory trigger regeneration inside
  a 1.x minor. Testable: doc-contract test asserts both tier names and the exception
  class appear.
- **CONTRACT-02** — A schema-snapshot contract test pins `audit_changes` and
  `audit_transactions` column names, Ecto types, and nullability, plus the existence
  of `audit_changes_row_history_idx` and sibling indexes. Testable: altering a pinned
  column in a test migration fails the test.
- **CONTRACT-03** — A literal-string contract test pins the GUC name
  `threadline.actor_ref` (static scan, no second occurrence under a different
  name). Testable: renaming the GUC anywhere fails the test.
- **CONTRACT-04** — Extend the existing contract-test pattern
  (`telemetry_registry_contract_test.exs`, `public_surface_contract_test.exs`) to
  cover the four gaps CONTRACT.md identifies with no current enforcement: the CSV/JSON
  export header (literal order, with/without `include_action_metadata`), the
  `Health.Finding` `code` union (additive-only), Mix task flag allowlists per task,
  and the `threadline_operator_surface/2` macro's option-key list + documented
  mounted route paths. Testable: each is a new or extended test file asserting a
  pinned list.
- **CONTRACT-05** — State a 6-month 0.12.x security/correctness backport window
  post-1.0.0 in `guides/stability.md` and `guides/upgrade-path.md` (policy statement,
  no code test — a maintainer commitment).

### DOCS — adopter-facing guides
- **DOCS-01** — Supported-table-shapes guide: composite keys, `primary_key:`
  override, dropped/renamed-table fallback, `char(n)` caveat, and explicit
  statements (currently undocumented either way) on partitioned tables, unlogged
  tables, views, and cross-schema tables. Testable: doc-contract test checks
  referenced table/option names against real schema/option names.
- **DOCS-02** — Redaction threat model: every guarantee claim scoped to a named
  verification mechanism (a specific property test or `mix threadline.health.coverage`
  check); explicit statement of what redaction does **not** guarantee (replication
  slots, logical decoding, superuser bypass, pre-redaction-rule-change rows).
  Testable: doc-contract test fails on an unscoped absolute ("all"/"never"/
  "guarantees"/"prevents") with no adjacent qualifier; agent review hunts
  unscoped absolutes specifically.
- **DOCS-03** — `guides/upgrading-to-1.0.md`, one numbered step per ONE-WAY decision
  in this milestone (facade collapse, association edge, bounded default, return-shape
  changes, PG floor), following the existing `upgrading-to-0.11.md` template.
  Testable: doc-contract test asserts one step per breaking-change commit landed in
  the milestone's range.
- **DOCS-04** — `data_after`/`changed_fields`/`changed_from` documented as an
  additive key/shape promise (keys are the audited table's own column names), not a
  byte-stable serialization promise (PostgreSQL's own JSON formatting varies across
  majors). Testable: doc-contract test asserts the guide states this caveat.
- **DOCS-05** — Each of DOCS-01/DOCS-02 ships with its own
  `test/threadline/*_doc_contract_test.exs`, matching the existing 19-file pattern.
  Testable: the test file exists and runs in `mix verify.test`.

### FLOOR — support floor
- **FLOOR-01** — Raise the PostgreSQL floor to 15; update the `min` CI lane
  (`.github/workflows/ci.yml`) from `pg: "14"` to `pg: "15"`; CHANGELOG entry under
  `### BREAKING`. Testable: the `min` CI lane runs and passes against PG 15; CI fails
  if anyone reverts the lane to 14 without a corresponding CHANGELOG edit (via the
  doc-contract test in FLOOR-02).
- **FLOOR-02** — Keep `elixir: "~> 1.15"`/OTP 26. Add a "Support Policy" subsection
  to `guides/upgrade-path.md` (floor table + the three CI lanes explained) and a
  doc-contract test asserting the guide's stated floor numbers match
  `Mix.Project.config()[:elixir]` and the CI `min` lane's `pg:`/`elixir:`/`otp:`
  values. Testable: the doc-contract test fails if `mix.exs` and the guide disagree.

### REL — release mechanics
- **REL-01** — Flip `release-please-config.json`'s `bump-minor-pre-major` to
  `false` (or remove the pre-major keys) in the same PR as the milestone's
  1.0-scoped breaking changes, before the first `feat!`/`BREAKING CHANGE` commit of
  this milestone lands. Testable: the repo's existing `verify.bump_rehearsal`
  CI job, run against the updated config, previews a `1.0.0` version bump, not
  `0.13.0`.
- **REL-02** — Add a `Release-As: 1.0.0` commit/PR footer once all 1.0-scoped work
  has landed on the target branch. Testable: the resulting release-please PR title
  reads `1.0.0`.
- **REL-03** — Cross-check the hand-written `CHANGELOG.md` 1.0.0 entry's
  breaking-changes section against `git log --grep="BREAKING CHANGE"` for the
  milestone's commit range before merging the release PR. Testable: every commit the
  grep returns is represented in the hand-written entry.

### CI — carried housekeeping
- **CI-01** — Run `bin/ci-test-partitions --write-weights` once, after this
  milestone's test-file churn settles, and commit the refreshed
  `test/partition_weights.txt` as part of closing housekeeping. Testable: the
  committed file's timestamp/contents postdate the milestone's last new test file.
- **CI-02** — The new `public_api_contract_test.exs` (SPEC-01) is marked
  `async: true` on its own merits (pure `Code.fetch_docs/1` introspection, no DB
  access) — no blanket DataCase async conversion. Testable: the test file declares
  `async: true` and the suite stays green under partitioning.

---

## Implications for Roadmap

Suggested phase breakdown, numbered from 231, following ARCHITECTURE's dependency-
ordered build sequence (§6 of ARCHITECTURE.md). Budget: **1-2 weeks**, matching the
milestone guide's own re-estimate.

1. **Phase 231 — Facade topology + the `AuditTransaction`↔`AuditAction` edge.**
   The two foundational ONE-WAY structural decisions, done together because they
   touch overlapping files (`query.ex`, `investigation.ex`). Collapse
   `Threadline.Query`/`Threadline.Investigation` to `@moduledoc false` behind
   `Threadline`, keep `timeline_query/1` as the one escape hatch, update the three
   guides that call the now-internal modules directly. Implement the maintainer's
   chosen option for the association edge. *Delivers: API-04, API-07.*

2. **Phase 232 — Consolidation, deprecation, and the bounded default.**
   Merge `history`/`row_history` into `row_history/3`, fold filters into opts, unify
   `TimelinePage`/`ActorHistoryPage` into `Threadline.Page`, implement the 200-row
   bounded default + truncation telemetry, and hard-deprecate every retired entry
   point with parity tests. *Delivers: API-01, API-02, API-03, API-05, API-08.*

3. **Phase 233 — Return-shape consistency.**
   `transaction_context/2`/`audit_transaction/2` move to `{:ok,_}/{:error,
   :not_found}` + `!` siblings; document the atom-vs-changeset split in
   `record_action/2`/`Audit.transaction/3`/`Evidence.record_*/3` as intentional.
   Small, but must land before specs are written against final signatures.
   *Delivers: API-06.*

4. **Phase 234 — `@spec`/`@doc` completion and the coverage gate.**
   The largest mechanical pass: build the `Code.fetch_docs`/`Code.Typespec` gate
   test first, then backfill specs/docs module-by-module against the now-settled
   surface (`Threadline` facade → consolidated read API → `Evidence` → `StorageSchema`'s
   public subset → `Telemetry.transaction_committed/2` and the health/retention/
   continuity stragglers), using `Threadline.Export`/`Threadline.Integrations.Sigra`
   (already 100% specced) as house style. Add `@doc group:` to the facade.
   *Delivers: SPEC-01, SPEC-02, SPEC-03, SPEC-04.*

5. **Phase 235 — Stability contract tests and the two new guides.**
   `guides/stability.md` (two-tier policy), the schema-snapshot test, the GUC
   literal-string test, the export-header/health-finding-code/operator-surface-macro/
   Mix-flag allowlist tests, the supported-table-shapes guide, and the redaction
   threat model — each with its own doc-contract test. *Delivers: CONTRACT-01
   through CONTRACT-05, DOCS-01, DOCS-02, DOCS-04, DOCS-05.*

6. **Phase 236 — Support floor and CI.**
   Raise the PG floor to 15, update the CI `min` lane, add the Support Policy
   subsection + its doc-contract test, refresh `test/partition_weights.txt`.
   *Delivers: FLOOR-01, FLOOR-02, CI-01, CI-02.*

7. **Phase 237 — Declare 1.0.0.**
   Finalize `guides/upgrading-to-1.0.md` against the now-complete set of breaking
   changes, flip `bump-minor-pre-major`, verify via `verify.bump_rehearsal`, add the
   `Release-As: 1.0.0` footer, cross-check the CHANGELOG breaking-changes section
   against `git log --grep`, cut the release. *Delivers: DOCS-03, REL-01, REL-02,
   REL-03.*

**Research flags:** none of the seven phases needs a further `--research-phase`
dispatch — this five-file research set already covers the implementation choices in
the depth a phase plan needs (exact file:line call sites, exact struct shapes, exact
precedent). Phases 231 and 232 carry the highest discussion stakes (they implement
the maintainer's ONE-WAY sign-offs above) and should get a careful
`/gsd-discuss-phase` pass, not a research pass. Phases 234-236 follow well-worn,
already-proven in-repo patterns (`verify.dialyzer_slice`, `telemetry_registry_
contract_test.exs`, `*_doc_contract_test.exs`) and can move straight to planning.

---

## Out of Scope / Deferred

- **Operator/admin UI** — parked until after 1.0.0 per `PROJECT.md` and
  `MILESTONE-GUIDE.txt`; no phase in this milestone touches `operator_surface`
  LiveView/markup except where an API change in Phases 231-233 forces a call-site
  update (the five known preload sites from the association decision).
- **Opaque result structs replacing raw Ecto schemas** (ARCHITECTURE/PITFALLS
  Option 2 under Pitfall 7) — a genuinely larger, separately one-way redesign;
  rejected for this milestone in favor of documenting the stable field subset of the
  existing structs. Revisit only if a future milestone's evidence calls for it.
  Carried as a named future candidate, not a silent drop.
- **NimbleOptions adoption** — explicitly recommended against; hand-rolled
  validators already give more specific errors and the options surface isn't shared
  across functions the way it would need to be to pay for a new dependency.
  Revisit only if a nested, cross-function-shared options schema emerges later.
- **Generic hand-maintained API-reference guide** — anti-feature; would duplicate
  and drift from ExDoc-generated content with no achievable doc-contract test.
- **`mix threadline.gen.backfill`, an `:invalid_config` health finding, query-level
  telemetry, telemetry from Mix task bodies** — all explicitly decided against in
  v1.44's own research; nothing in this milestone's scope reopens them.
- **Carried from v1.44 (beyond partition weights, which is in-scope as CI-01):**
  the stateful PropEr model and continued adopter-twin table-shape growth remain
  deferred — this milestone's scope is the public API contract, not new
  test-infrastructure investment; both stay named candidates for a post-1.0 quality
  milestone, not silently dropped.
- **GDPR post-hoc erasure, per-table retention, partitioned tables/RLS tenancy,
  multiple repos, the external pilot, compliance packs** — all LONG-horizon items
  per `MILESTONE-GUIDE.txt` §7, gated on sustained adopter demand this milestone
  does not change.

---

## Watch-Outs

Condensed from PITFALLS.md's 14 named pitfalls; see that file for full detail and
recovery costs.

- **`--warnings-as-errors` breaks on any missed internal call site.** Grep `lib/`,
  `test/`, the example app, and every guide for every retiring name before merging
  each deprecation (Phase 232); verify with a fresh `mix new` app depending on the
  new version, not just this repo's own clean compile.
- **Deprecated delegates drift from their target.** Enforce "pure one-line delegate
  + parity test," never independent logic in a deprecated function (Phase 232).
- **Specs that lie.** `term()`/`any()` satisfies a naive coverage-percentage gate
  but gives Dialyzer and adopters nothing; review for informativeness, not just
  presence (Phase 234, agent-review rubric).
- **`@moduledoc false` on a module a guide already names is a silent breaking
  change with no compiler nudge.** Grep every guide/README/example app for a
  module's name before hiding it (Phase 231, Phase 234).
- **Silent truncation in an audit trail is a compliance failure, not a UX
  nicety.** Resolved above (200 cap, cursor/`Page` as the only completeness proof,
  telemetry as a secondary signal) — do not regress to "just cap it" during
  implementation (Phase 232).
- **`release-please` ships `0.13.0` instead of `1.0.0` if `bump-minor-pre-major`
  isn't flipped before the first breaking commit lands.** This is a confirmed live
  risk in the current config, not a hypothetical (Phase 237, REL-01).
- **BREAKING-change footers can collapse/be missed in the hand-written
  CHANGELOG.** Cross-check against `git log --grep` for the milestone's full commit
  range before merging the release PR, not against memory of what was planned
  (Phase 237, REL-03).
- **Scope creep under "1.0 should be perfect."** Every phase must trace to one of
  the six target-feature bullets in `PROJECT.md`'s Current Milestone section or the
  release-mechanics bullet; a phase touching `operator_surface`/LiveView without an
  API-forced justification, or a rename/restructure with no spec/consolidation
  rationale, is out of scope by construction.
- **New guides overclaiming or drifting from the tests that back them.** Every
  guarantee in the redaction threat model and table-shapes guide must name the
  specific property test or health check that proves it; no unscoped "all"/"never"/
  "guarantees" language (Phase 235, DOCS-02).

---

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Stack (floors, enforcement tooling, release mechanics) | HIGH | Verified floors/EOL dates and current repo config read directly (file:line); ecosystem precedent (Oban/LiveView/Ecto mix.exs) verified via primary GitHub sources. |
| Features (consolidation, return shapes, docs gaps) | MEDIUM-HIGH | Codebase claims file:line-cited; cross-ecosystem precedent (PaperTrail, Carbonite, ExAudit) spot-verified via hexdocs; some general-knowledge precedent (audited gem, Logidze, Envers) flagged MEDIUM/LOW and not re-verified this pass. |
| Architecture (facade topology, the association edge, full surface inventory) | HIGH for inventory/call-sites (direct code read); MEDIUM for the 1.0 topology/edge judgment itself (design reasoning cross-checked against Ecto/Oban/Ash precedent, no adopter telemetry exists to validate against — Threadline has no production adopters yet). |
| Pitfalls (deprecation mechanics, gate design, scope-creep guardrails) | HIGH on Elixir/Hex conventions and this repo's own code/config; MEDIUM on cross-ecosystem specifics (Rails/Django/Envers/PaperTrail precedent recalled, not re-verified line-by-line this pass). |
| Contract (two-tier stability policy, DB-contract matrix) | HIGH for named-project precedent (Elixir, Django, Ash, pgaudit — official docs) and for this repo's own schema/GUC/telemetry citations; MEDIUM for Ecto/Phoenix/Oban/Req precedent (changelog-derived, not a single canonical policy page per project). |

**Gaps flagged for attention during planning, not resolved by this research:**

- Whether any of this milestone's own decisions (the bounded-default change, the
  entry-point consolidation, the association-edge decision) touch *generated SQL*
  is not yet known — if any do, the `0.12.x → 1.0.0` row in `guides/upgrade-path.md`
  must say so explicitly before declaring 1.0.0 (CONTRACT.md's own stated gap).
- The exact 0.12.x backport-window length (recommended: 6 months, following Ash) is
  a maintainer policy choice, not derivable from Threadline's own history — surface
  it as a named decision at the start of Phase 235/236, not an assumed default.
- Postgrex's own "0.22.x requires Elixir 1.15" claim in STACK.md is marked MEDIUM
  confidence (inferred from a search-result summary of the changelog, not a direct
  file read) — worth a one-line spot-check before citing it in the Support Policy
  guide text.

## Sources

Aggregated from the five research files; see each file's own Sources section for
full citations and confidence grading.

- Codebase (HIGH, direct reads): `mix.exs`, `.github/workflows/ci.yml`,
  `release-please-config.json`, `.release-please-manifest.json`,
  `CHANGELOG-GENERATED.md`, `lib/threadline.ex`, `lib/threadline/query.ex`,
  `lib/threadline/investigation.ex`, `lib/threadline/capture/*`,
  `lib/threadline/semantics/*`, `lib/threadline/export.ex`, `lib/threadline/health.ex`,
  `lib/threadline/telemetry.ex`, `lib/threadline/storage_schema.ex`,
  `test/threadline/public_surface_contract_test.exs`,
  `test/threadline/telemetry_registry_contract_test.exs`, `guides/*.md`,
  `.planning/PROJECT.md`, `.planning/MILESTONE-GUIDE.txt`.
- External, HIGH confidence (official docs/primary sources): PostgreSQL EOL pages
  (endoflife.ai, TuxCare, Instaclustr), `ecto_sql`/`oban`/`phoenix_live_view` GitHub
  `mix.exs` files, Elixir's own Compatibility and Deprecations / Library Guidelines
  docs, Carbonite/ExAudit/PaperTrail hexdocs, Ash upgrade/changelog docs, Oban Web /
  Phoenix LiveDashboard / ErrorTracker router docs, pgaudit README, Django API
  stability / deprecation-timeline docs.
- External, MEDIUM/LOW confidence (flagged inline in source files, not re-verified
  this pass): Postgrex changelog version-to-floor mapping; Ecto/Phoenix/Oban
  deprecation-precedent specifics; Req's pre-1.0 stability history; Rails
  `audited`/Logidze/Hibernate Envers/django-simple-history API precedent.
