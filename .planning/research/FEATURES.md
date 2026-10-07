# Feature Research — v1.45 "1.0 API Contract"

**Domain:** Read/query API surface + table-stakes docs for a 1.0 Elixir audit library
**Researched:** 2026-10-02
**Confidence:** MEDIUM-HIGH (codebase claims are file:line-cited; cross-ecosystem precedent is WebSearch-verified for names/signatures, not hexdocs-full-text-verified for every option)

All six recommendations below are designed to be mutually coherent: one naming
scheme (`row_*` / `actor_*` / `timeline*`), one return convention (bare list
for unpaged reads, `Page` struct for paged reads, `{:ok, _}`/`{:error, _}` only
for operations that can legitimately not find their subject, `ArgumentError`
for bad input), one options convention (keyword lists, not NimbleOptions, with
tightened runtime validation).

---

## 1. Read-API consolidation

### Current surface (evidence)

Three layers expose overlapping read entry points today:

| Facade (`lib/threadline.ex`) | Delegates to | Signature |
|---|---|---|
| `history/3` | `Threadline.Query.history/3` | `(schema, id, opts)` — line 103 |
| `as_of/4` | `Threadline.Query.as_of/4` | `(schema, id, ts, opts)` — line 117 |
| `actor_history/2` | `Threadline.Query.actor_history/2` | `(actor_ref, opts)` — line 132 |
| `timeline/2` | `Threadline.Query.timeline/2` | `(filters, opts)` — line 155 |
| `timeline_page/2` | `Threadline.Query.timeline_page/2` | `(filters, opts)` — line 168 |
| `row_history/4` | `Threadline.Investigation.row_history/4` | `(schema, id, filters, opts)` — line 177 |
| `row_history_page/4` | `Threadline.Investigation.row_history_page/4` | `(schema, id, filters, opts)` — line 183 |
| `actor_window/3` | `Threadline.Investigation.actor_window/3` | `(actor_ref, filters, opts)` — line 189 |
| `actor_window_page/3` | `Threadline.Investigation.actor_window_page/3` | `(actor_ref, filters, opts)` — line 195 |

The two JTBDs "show me this row's changes" and "page through this row's
changes" are each served by **two unrelated functions with two unrelated
signatures**: `history(schema, id, opts)` (`Query`, no `filters` arg, `:limit`
caps) vs `row_history(schema, id, filters, opts)` (`Investigation`, `filters`
restricted to `:from`/`:to`/`:repo`, no `:limit`, but returns `LinkedChange`
structs with transaction/action preloaded — `lib/threadline/investigation.ex:33-39`).
`actor_history/2` (cursor-paged by construction, `Query`) vs
`actor_window/3`+`actor_window_page/3` (eager/paged pair, `Investigation`,
cross-table not single-actor-transaction-scoped) look like near-synonyms but
answer different questions: `actor_history` returns `AuditTransaction` rows
for one actor; `actor_window` returns `AuditChange` rows (with linked
transaction/action) across tables, filtered by actor implicitly. That
difference is real and worth keeping, but the *names* don't signal it.

### Job-to-be-done mapping (recommended 1.0 set)

| JTBD | 1.0 entry point | Shape |
|---|---|---|
| Show me this row's changes | `Threadline.row_history/3` | bare list, `AuditChange` + linked transaction/action |
| Page through this row's changes | `Threadline.row_history/3` with `:cursor` opt → returns `Page` | same function, see §1a |
| What did this actor do (transactions) | `Threadline.actor_history/2` | `Page` struct (already cursor-shaped; keep) |
| What did this actor do (cross-table changes) | `Threadline.actor_window/3` | bare list / `Page` via `:cursor` |
| Everything in a window / matching filters | `Threadline.timeline/2` | bare list / `Page` via `:cursor` |
| What did this row look like at T | `Threadline.as_of/4` | `{:ok, map}` / `{:error, reason}` (unchanged — already idiomatic, see §3) |
| Diff | `Threadline.change_diff/2` | map (unchanged) |

#### 1a. Should `history`/`row_history` merge, and should paging be a separate function or an option?

**Recommendation: merge into one `row_history/3`, and make paging an option, not a separate function. ONE-WAY.**

Before (1.0-pre, two names, two shapes):
```elixir
# bare AuditChange, capped by :limit, no filters, no linked context
Threadline.history(MyApp.User, 42, repo: MyApp.Repo, limit: 20)

# LinkedChange (transaction+action preloaded), :from/:to filters, no cap
Threadline.row_history(MyApp.User, 42, [from: ~U[2026-01-01 00:00:00Z]], repo: MyApp.Repo)

# separate page function, separate struct, separate call site
Threadline.row_history_page(MyApp.User, 42, [], repo: MyApp.Repo, page_size: 500)
```

After (1.0, one name, one shape, cursor as the paging signal):
```elixir
# one call, bounded by default (see #2), linked context always present
Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo)

# add a time window — same function, keyword opts, no separate arg
Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo, from: ~U[2026-01-01 00:00:00Z])

# ask for a page explicitly — same function, returns a Page struct instead of a bare list
Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo, cursor: :start, page_size: 500)
%Threadline.Page{entries: [...], cursor: next_cursor, has_more: true} =
  Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo, cursor: next_cursor, page_size: 500)
```

Why one function with a `:cursor` opt rather than two functions:
- **Pros:** one name to learn and document; `:cursor` present/absent cleanly
  signals which return shape to expect (dispatch on presence of the opt, not
  on function identity) without breaking Elixir's "same name, same return
  shape" expectation in the no-cursor case, which stays a bare list; matches
  `timeline/2` + `timeline_page/2` precedent *in spirit* but collapses them
  into the single name adopters actually reach for first.
- **Cons:** a function whose return type depends on an option value is less
  type-transparent than two separately-named functions (Dialyzer sees a union
  type); adopters skimming docs may not immediately notice `:cursor` changes
  the shape.
- **Verdict:** accept the Dialyzer union-type cost. It is the same shape
  `Flop.validate_and_run/3` and `Paginator.paginate/2` already accept
  (`Flop.Meta` vs plain list depending on call), and it keeps exactly one
  name per JTBD, which this milestone's own guide text (§Scope) calls for
  ("consolidate overlapping entry points with deprecations"). Keep
  `timeline/2`/`timeline_page/2` as the one **exception** — they're already
  two names in public use since before 1.0 and multi-table timeline paging is
  reached for independently of the eager form often enough (operator UI,
  export) that a visible, separately-documented page function earns its
  keep. Do **not** add a third pattern; two patterns (cursor-opt for
  `row_history`/`actor_window`, named `_page` pair for `timeline`) is already
  the ceiling — see the discoverability cost called out in §6.

Deprecation path (ONE-WAY, semver-breaking at 1.0): keep `Threadline.history/3`
and `Threadline.row_history_page/4` as `@deprecated` thin wrappers for one
minor (1.1) emitting a compile warning, then remove in 1.2. `Query.history/3`
stays as the low-level primitive `row_history/3` delegates to — it already
has `:limit`; expose `:limit` as the row_history opt alias for the final cap,
with `:cursor`/`:page_size` driving the keyset path.

#### 1b. Filters: separate positional arg or keyword opts?

**Recommendation: fold `filters` into `opts`. ONE-WAY, breaking.**

Today `history(schema, id, opts)` has no filters arg while
`row_history(schema, id, filters, opts)` does — an adopter who learns one
signature writes nonsense calling the other. Elixir/Ecto precedent is
unanimous: `Ecto.Repo.all(queryable, opts)` takes one opts list; `Flop` takes
one params map; `Req.get(url, opts)` takes one opts keyword list that mixes
what other libraries would split into "params" and "options". There is no
widely-idiomatic Elixir library that asks callers to thread two parallel
keyword lists through every call.

Before:
```elixir
Threadline.row_history(MyApp.User, 42, [from: ts], repo: MyApp.Repo)
```
After:
```elixir
Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo, from: ts)
```
- **Pros:** one opts list, matches `history/3`'s existing shape, removes an
  entire class of "which list does `:from` go in" bugs, shrinks arity.
- **Cons:** the `filters`/`opts` split existed to let `Investigation`
  validate a *restricted* key allowlist (`@allowed_row_history_filter_keys`)
  separately from paging/repo opts (`lib/threadline/investigation.ex:21-23`).
  Merging means the validator must distinguish "filter keys" from "mechanism
  keys" (`:repo`, `:cursor`, `:page_size`, `:preload`, `:scope*`) within one
  list — a straightforward `Keyword.split/2` against a known key set, not a
  real cost.
- **Verdict:** merge. Keep per-function allowlists (`row_history` still only
  accepts `:from`/`:to` as filter-shaped keys) implemented as validation
  logic, not as a second positional argument.

#### 1c. `actor_history`/`actor_window` naming

**Recommendation: keep both names, but make the distinction explicit in
`@moduledoc`/`@doc` and in the guide, because the names alone under-signal
the difference (transactions vs cross-table changes).**

- `actor_history/2` → `AuditTransaction` rows for one actor (already
  cursor-paged, keep as-is).
- `actor_window/3` → `AuditChange` rows across tables scoped to one actor
  (eager or paged via `:cursor`, same consolidation as §1a).

Precedent check: no surveyed library (PaperTrail, audited, Logidze, Envers,
django-simple-history, Carbonite, ExAudit) has an actor-centric cross-table
query at all — this is a Threadline differentiator, not a place to copy a
name. Given that, optimize for internal consistency over external precedent:
`actor_history` = transactions (matches "history of what the actor did, as
transactions"), `actor_window` = changes ("a window of change rows touched by
this actor"). This is already the existing naming — no rename needed, just
documentation tightening (`@doc` cross-links one to the other, stating return
type up front, which neither currently does as of `lib/threadline.ex:119-132`
and `:185-195`).

#### 1d. Facade vs submodule story

**Recommendation: `Threadline.*` is the only supported public surface.
`Threadline.Query` and `Threadline.Investigation` become `@moduledoc false` +
internal, keeping their functions as the implementation `Threadline.*`
delegates to. ONE-WAY.**

Evidence this is already half-true: `Threadline.Query`'s own `@moduledoc`
(`lib/threadline/query.ex:1-29`) documents itself as "the Threadline public
API," and `Threadline.Investigation`'s `@moduledoc` (`lib/threadline/investigation.ex:1-7`)
invites direct use ("Use these helpers when you want..."). That's two
publicly-documented entry points into the *same* functionality the facade
also exposes, which is the opposite of "one obvious way to do it" and is
exactly what forces the `history` vs `row_history` arg-shape mismatch in
§1a/§1b to leak to adopters instead of staying an internal implementation
seam.

Before (today — three valid, inconsistent ways to get row history):
```elixir
Threadline.history(MyApp.User, 42, repo: MyApp.Repo)
Threadline.Query.row_history(MyApp.User, 42, [], repo: MyApp.Repo)
Threadline.Investigation.row_history(MyApp.User, 42, [], repo: MyApp.Repo)
```
After (1.0 — one way):
```elixir
Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo)
```

- **Pros:** matches Ecto (`Ecto.Repo` is the public surface;
  `Ecto.Repo.Queryable` internals aren't advertised), Oban (`Oban` +
  `Oban.Job`/`Oban.Config` public, but the query-building internals in
  `Oban.Queries` are private), Req (`Req` facade; `Req.Request` is the
  advanced/internal escape hatch, documented as such, not as a parallel
  front door). One discoverable module beats three.
- **Cons:** some adopters currently depend on `Threadline.Query.*` directly
  (anyone who wants `timeline_query/1`'s raw `Ecto.Query.t()` to compose
  further, e.g. add their own `where`). Marking the module
  `@moduledoc false` without an escape hatch would strand them.
- **Verdict:** keep **exactly one** documented low-level escape hatch:
  `Threadline.Query.timeline_query/1` and `Threadline.Query.row_history_query/3`
  (both already return `Ecto.Query.t()`, both already `@doc false` for
  `row_history_query` — `lib/threadline/query.ex:438`, but `timeline_query/1`
  is currently public-documented at line 240). Promote `timeline_query/1`
  itself into `Threadline`'s moduledoc as "the composition escape hatch" and
  hide everything else. This gives power users one supported way to drop to
  raw Ecto composition without three parallel modules claiming to be "the"
  public API.

### Cross-ecosystem precedent (table)

| Library | Row-history call | Point-in-time call | Paging story | Facade story |
|---|---|---|---|---|
| PaperTrail (Ruby, gem) | `record.versions` (ActiveRecord association) | `record.version_at(time)` | ActiveRecord `.limit`/`.page` (via kaminari/will_paginate, bolted on) | One module, versions are AR objects |
| paper_trail (Elixir, hex) | `PaperTrail.get_versions(model, id)` / `get_versions(record)` [verified via hexdocs 1.1.2] | `PaperTrail.get_version(model, id)` (latest only; no as-of-time built in) | none built in — caller adds `Ecto.Query` opts | One module (`PaperTrail`) is the facade |
| audited (Ruby gem) | `record.audits` (AR association) | `record.revision(n)` (ordinal, not timestamp) | AR pagination bolted on | One module |
| Logidze (Ruby gem, Postgres jsonb log) | `record.log_data` / `record.diff_from(version)` | `record.at(time: t)` | n/a (log capped by `logidze_version_limit` on the trigger, not query-side) | One module |
| django-simple-history | `instance.history.all()` (QuerySet) | `instance.history.as_of(datetime)` | Django QuerySet `.filter()[:n]` / standard paginator | One manager (`.history`) |
| Hibernate Envers (Java) | `AuditReader.createQuery().forRevisionsOfEntity(...)` | `AuditReader.find(Entity.class, id, revision)` | `AuditQuery.setFirstResult/setMaxResults` | One `AuditReader` facade, builder-pattern queries |
| Carbonite (Elixir, hex, Postgres trigger-based — closest architectural peer to Threadline) | `Carbonite.Query.changes(record, opts)` returns `Ecto.Query.t()` [verified via hexdocs] — caller runs it | not built in | caller composes `Ecto.Query` `limit`/`where` themselves | Deliberately query-builder-only — no "run it for me" convenience layer; `Carbonite.Query` is the whole surface |
| ExAudit (Elixir, hex) | `ExAudit.history(struct)` [verified via hexdocs] | via `history/2` + manual filter (no dedicated as-of) | not built in | `ExAudit.Repo`-wrapping facade + `history/2`/`revert/2` |

Takeaway: Threadline's facade-with-cursor-paging story is **already more
complete** than every surveyed peer (Carbonite and paper_trail leave paging
entirely to the caller; none offer a true as-of-timestamp *and* diff *and*
actor-window in one coherent namespace). The 1.0 gap isn't missing
capability, it's **surface area discipline** — too many names/modules for
the same capability, which is exactly what §1a/§1b/§1d fix.

---

## 2. Bounded default limit for `history`/`row_history` — **ONE-WAY**

### Current state (evidence)

`Threadline.Query.history/3` defaults `:limit` to `nil` (unbounded) —
`lib/threadline/query.ex:98-101`, enforced by `Threadline.Query.HistoryLimit.validate!/1`
(`lib/threadline/query/history_limit.ex`). The milestone's required reading
confirms this was a deliberate v1.44 deferral: "v1.44 added a `limit:`
option, default nil = unbounded; the bounded default was deferred to this
milestone as a one-way semver decision" (common-context line 9).
`Investigation.row_history/4` has **no** `:limit` concept at all today — it
takes `:from`/`:to` only — so merging it into `row_history/3` (§1a) is also
where the bounded default must land.

### Ecosystem precedent on unbounded reads

- `Ecto.Repo.all/2` is itself unbounded by design — it's the lowest-level
  primitive and Ecto explicitly expects callers to add `limit`. That's
  correct for a query-builder level API; it is not a template for a
  convenience-level API like `Threadline.row_history/3`, which is one level
  above `Repo.all` specifically to remove boilerplate.
- Phoenix generated contexts (`mix phx.gen.context`) generate
  `list_things/0` as `Repo.all(Thing)` — unbounded — and this is a
  **well-known Phoenix footgun** flagged repeatedly in community posts and
  the Phoenix guides' own pagination docs; it is not something to emulate.
- **Flop**, **Paginator**, and **Scrivener** — the three dominant Elixir
  pagination libraries — all require the caller to pass an explicit page
  size, and all three default that size to a bounded number (Flop defaults
  `default_limit: 50`; Scrivener defaults `page_size: 10`; Paginator has no
  built-in default and requires `:cursor_fields` + an explicit limit at the
  call site, erroring without one in practice). None of the three lets an
  unscoped list query return an unbounded result silently.
- **Oban Web** paginates its job list views by default (fixed page size in
  the UI layer) — never serves an unbounded job list in one response.

The unanimous ecosystem pattern for *convenience-level* read APIs (vs raw
`Repo.all`) is: **bounded by default, unbounded only by explicit opt-in.**

### Recommendation: default `:limit` to **200**, ONE-WAY, truncate silently with a signal via telemetry — not via changing the return shape

```elixir
# before 1.0 — unbounded, a 500k-row history table returns every row
Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo)

# at 1.0 — capped at 200 by default, same call site, same bare-list return
Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo)
# -> 200 most recent AuditChange, newest first

# opt out explicitly when you want everything
Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo, limit: :infinity)

# or page through it properly
Threadline.row_history(MyApp.User, 42, repo: MyApp.Repo, cursor: :start, page_size: 500)
```

Why 200, not 100 or 1000: 100 is Flop-adjacent but tight for an audit history
view that legitimately wants "last couple hundred edits" in one shot; 1000 is
`timeline_page/2`'s *page* size (`@default_timeline_page_size`,
`lib/threadline/query.ex:42`) — reusing it as the **unbounded-call** cap
would make a casual, unpaged `row_history` call return up to 1000 rows by
accident, which is still "surprisingly large" for the common single-row
inspection UI (most rows have single-digit-to-low-dozens of real edits; 200
comfortably covers the long tail without being `timeline_page`'s bulk-export
size). Pick a number clearly smaller than the page default so the two
concepts ("history" vs "a page of timeline") stay visually distinct in docs
and code.

**Truncate silently, don't raise.** Raising on "more rows exist than your
default" would make `row_history/3` unusable without first knowing the row's
edit count — a correctness trap, not a safety net. Keyset `:cursor` already
exists as the deliberate, discoverable "I want all of it" tool; use it as
the pressure-relief valve instead of an exception.

**Signal truncation via telemetry, not via changing the return type.**
Switching the bare-list return to a tagged/wrapped shape whenever the cap
bites would violate §3's "reads return bare values" convention and would be
a silent breaking change for any pattern-matching caller depending on call
site. Instead:
- Emit (or extend) a `[:threadline, :row_history, :truncated]` telemetry
  event carrying `limit` and `table` when `length(entries) == limit` (cannot
  prove more rows exist without a cursor probe, but equality-with-cap is the
  conventional signal, same heuristic `Cursors.timeline_page_next_cursor/2`
  already uses internally for `has_more` — `lib/threadline/query.ex` via
  `Threadline.Query.Cursors`).
- Document in `@doc` that hitting exactly `:limit` rows does not prove
  completeness and that `:cursor` is the only query that can.
- This keeps `row_history/3`'s return type a single, always-bare list (no
  union with a "maybe truncated" wrapper), which is what §3 standardizes on.

**`:limit` vs `:cursor`/`page_size` relationship:** `:limit` is the *default
unpaged cap* (replaces today's optional cap on `history/3`); `:cursor`
switches the function into paged mode where `:page_size` (not `:limit`)
governs page size and the cap concept doesn't apply (a cursor walk is
definitionally unbounded across pages, bounded per page). Passing both
`:limit` and `:cursor` together should raise `ArgumentError` — they are
mutually exclusive modes, and letting them silently combine (e.g. does
`:limit` cap the first page, all pages, or get ignored?) is exactly the kind
of API ambiguity a 1.0 contract should foreclose rather than leave
undefined.

**Semver story:** this is the single largest breaking behavior change in the
milestone for existing adopters — anyone relying on `row_history`/`history`
returning "everything" today will silently start getting 200 rows after
upgrading, with no exception to catch it. Required mitigations:
1. CHANGELOG `[1.0.0]` entry under a `### BREAKING` heading, example call
   sites before/after (as above).
2. `guides/upgrading-to-1.0.md` (see §5) gets its own numbered step: "Audit
   every `history`/`row_history` call site your app makes; if you depend on
   unbounded results (exports, backfills), add `limit: :infinity` or switch
   to `:cursor` paging explicitly."
3. Because this is silent-truncation rather than an error, it is the single
   highest-value target for the telemetry signal above — ops teams running
   1.0 in production should be able to alert on
   `[:threadline, :row_history, :truncated]` firing against a table they
   expect to never truncate.

---

## 3. Return-shape consistency — **ONE-WAY**

### Inventory (evidence)

| Function | Current return | File:line |
|---|---|---|
| `record_action/2` | `{:ok, %AuditAction{}}` / `{:error, reason}` (4 distinct error shapes: changeset, `:missing_actor`, `:invalid_actor_ref`, `:missing_repo`) | `lib/threadline.ex:41-63` |
| `history/3` | bare list, raises `ArgumentError` on bad `:limit`/`id` | `lib/threadline/query.ex:402-409` |
| `row_history/4`, `actor_window/3`, `timeline/2` | bare list | `query.ex:66-75`, `investigation.ex:62-71`, `query.ex:661-677` |
| `row_history_page/4`, `timeline_page/2`, `actor_window_page/3` | `%TimelinePage{entries:, next_cursor:}` struct | `query.ex:44-57`, `:99-103` |
| `actor_history/2` | `%Threadline.Query.ActorHistoryPage{entries:, next_cursor:, prev_cursor:}` — a **different** page struct shape (has `prev_cursor`, `TimelinePage` doesn't) | `query.ex:563-567` |
| `as_of/4` | `{:ok, map}` / `{:error, :deleted_record}` / `{:error, :before_audit_horizon}` | `query.ex:475-488` |
| `incident_bundle/2` | `{:ok, %IncidentBundle{}}` / `{:error, :not_found}` | `investigation.ex:151-181` |
| `transaction_context/2` | bare `%LinkedTransaction{}` struct, `nil` fields when nothing found (not an error tuple at all) | `investigation.ex:130-145` |
| `audit_changes_for_transaction/2` | bare list, `[]` when nothing found; raises `ArgumentError` on bad UUID | `query.ex:600-624` |
| `audit_transaction/2` | bare struct **or `nil`** (Repo.one-style) | `query.ex:117-139` |
| `change_diff/2` | bare map (delegates to `ChangeDiff`) | `lib/threadline.ex:262-264` |
| Filter/opt validation (`validate_timeline_filters!`, `validate_row_history_filters!`, `:preload` checks) | raises `ArgumentError`, 6+ distinct call sites | `query.ex:150-184, 136-138, 621-622` |

This is already *mostly* consistent, but has three concrete inconsistencies
worth fixing before 1.0 freezes the contract:

1. **Two page struct shapes** (`TimelinePage` vs `ActorHistoryPage`) for the
   same semantic concept (a keyset page), one with `prev_cursor` and one
   without, under two different names. A caller writing generic pagination
   UI against one has to special-case the other.
2. **`transaction_context/2` is the only "may not find its subject" read
   that doesn't return `{:ok, _}`/`{:error, :not_found}`** — it returns a
   struct with `nil` fields instead, while its sibling `incident_bundle/2`
   (same subject: one `transaction_id`) correctly returns
   `{:error, :not_found}`. Two functions, same input, same "doesn't exist"
   case, two different shapes.
3. **`audit_transaction/2` returns a bare `nil`** (Repo.one convention) while
   `as_of/4` and `incident_bundle/2` (same "might not exist" semantics) use
   `{:error, _}` tuples. Elixir has no single universal convention here (this
   is the field's one genuinely contested point, see below), so Threadline
   must pick one and hold the line.

### The actual Elixir-ecosystem convention (and where it's contested)

- **Ecto.Repo**: `all/2` returns a bare list (never errors on "not found" —
  empty list is the "not found" signal); `get/3` returns the struct or
  `nil`; `get!/3` raises; `insert/2`/`update/2`/`delete/2` return
  `{:ok, struct}`/`{:error, changeset}`; `insert!/2` etc. raise. The
  pattern: **plural/collection reads are bare, singular "might not exist"
  reads are `nil`-or-struct (with a `!` sibling that raises), write
  operations that can produce structured validation failures use ok/error
  tuples.**
- **Req**: `Req.get/2` returns `{:ok, %Req.Response{}}`/`{:error, exception}`
  by default, with `Req.get!/2` raising — Req treats *all* I/O as fallible
  because network calls always can fail, unlike a local Ecto query.
- **Oban**: `Oban.insert/2` mirrors `Repo.insert/2` (`{:ok, job}`/`{:error,
  changeset}`); `Oban.cancel_job/2` returns `:ok`/`{:error, reason}`; reads
  like job-state queries return bare structs or `nil`.
- Threadline's own domain split maps cleanly onto this: **"did I find the
  thing" reads** (`audit_transaction/2`, `as_of/4`, `incident_bundle/2`,
  `transaction_context/2`) are the `nil`-or-{:ok,_} contested zone;
  **"give me everything matching" reads** (`history`, `row_history`,
  `timeline`, `actor_window`, `actor_history`) are correctly *already* bare
  lists/page-structs and should stay that way — do not wrap list reads in
  ok/error tuples, that would be un-idiomatic (no Ecto `Repo.all` caller
  expects `{:ok, list}`).

### Recommendation: four rules, ONE-WAY where they change existing behavior

1. **Collection reads stay bare** (`history`→`row_history`, `timeline`,
   `actor_window`, `actor_history`, `audit_changes_for_transaction`) — no
   change needed, codify in a `@moduledoc` convention note on `Threadline`.
2. **Single-subject-might-not-exist reads standardize on `{:ok, result}` /
   `{:error, :not_found}`** (matching `incident_bundle/2`'s existing
   contract, the strictest/most explicit of the three current shapes).
   - `transaction_context/2` changes from a bare struct with `nil` fields to
     `{:ok, %LinkedTransaction{}}`/`{:error, :not_found}` — **ONE-WAY,
     breaking.** Before: `tx = Threadline.transaction_context(id, repo: Repo); tx.action`.
     After: `{:ok, tx} = Threadline.transaction_context(id, repo: Repo); tx.action`.
   - `audit_transaction/2` changes from bare-struct-or-`nil` to
     `{:ok, struct}`/`{:error, :not_found}` — **ONE-WAY, breaking**, but add
     `audit_transaction!/2` (raising) as the escape hatch for callers who
     want the terser `Repo.get!`-style call (precedent: Ecto's own
     `get`/`get!` pairing is exactly this fork).
   - `as_of/4` already fits this convention (`{:error, :deleted_record}` /
     `{:error, :before_audit_horizon}` instead of a generic `:not_found` is
     *correct*, not an inconsistency — those are semantically distinct
     outcomes an adopter needs to branch on differently, keep them).
3. **Merge the two page structs into one `Threadline.Page` struct** with
   `entries`, `cursor` (rename `next_cursor`→`cursor` for brevity — ONE-WAY),
   and `has_more` (boolean, computed the same way `ActorHistoryPage`'s
   implicit completeness check already works, made explicit). Drop
   `prev_cursor` as a separate field; backward cursor walks pass `cursor:
   {:before, token}` instead of a second field — one field, one shape, every
   paged function returns it.
   ```elixir
   %Threadline.Page{entries: [...], cursor: next_token, has_more: true} =
     Threadline.timeline(filters, repo: Repo, cursor: :start)
   ```
4. **Invalid *options* (wrong type, unknown key, mutually exclusive opts)
   keep raising `ArgumentError`** at call time, not wrapped in `{:error, _}}`
   — this is already the codebase's convention everywhere (`HistoryLimit.validate!/1`,
   `validate_timeline_filters!/1`, `:preload` validation) and matches Ecto
   (`Repo.all(query, bogus_opt: true)` raises, doesn't return `{:error,
   _}}`) and Oban (bad job opts raise at `new/2`, not at insert). Options are
   a programmer error class, not a runtime data-dependent failure — tuples
   are for the latter.

Net picture for 1.0: **lists/pages are bare, single-subject lookups are
ok/error (with `!` siblings for the terse path), bad options raise.** This is
exactly Ecto's own three-way split, which is the strongest precedent
available since Threadline's whole persistence layer already speaks Ecto.

---

## 4. Is NimbleOptions worth it at 1.0?

### What Oban/Req/Broadway do

- **Oban** uses hand-rolled validation (`Oban.Validation` module, not
  NimbleOptions) for job/queue config — predates widespread NimbleOptions
  adoption and the project has never migrated, suggesting the payoff curve
  is not automatically obvious even for a library of Oban's scale and
  config-surface size.
- **Broadway** *does* use NimbleOptions for producer/processor/batcher
  config — but Broadway's options are deeply nested, numerous, and have
  cross-field constraints (batch size vs batch timeout vs concurrency), the
  exact shape NimbleOptions is built for (generated docs sections, nested
  schemas, default propagation).
- **Req** uses a hand-rolled options/step pipeline, not NimbleOptions, for
  its larger-than-Threadline options surface.

### Applied to Threadline

Threadline's heaviest options list (`timeline/2`'s filters:
`:table`/`:table_schema`/`:actor_ref`/`:from`/`:to`/`:correlation_id`/`:repo`/`:storage_schema`,
plus paging opts `:cursor`/`:page_size`) is flat, not nested, and already has
hand-written validators with excellent, specific error messages
(`lib/threadline/query.ex:150-210` — the `:correlation_id` validator alone
gives four distinct tailored messages for nil/wrong-type/empty/too-long).
NimbleOptions would:
- **Pros:** auto-generated "Options" doc sections (reduces drift between
  `@doc` prose and actual accepted keys — a real risk given `history/3` and
  `row_history/3` today list overlapping-but-different allowed keys in
  prose only); typed schema as a single source of truth; a new dependency
  signal of "serious library" to some adopters.
- **Cons:** new runtime dependency for a library whose OSS DNA (per
  `prompts/threadline-elixir-oss-dna.md`) favors a tight dependency
  footprint; existing hand-written validators already produce *more*
  specific, more human messages than NimbleOptions' generic schema-mismatch
  errors (compare today's `:correlation_id cannot be nil — omit the key
  entirely...` to a typical NimbleOptions `invalid value for :correlation_id
  option: expected non-nil value`); migrating ~6 validator functions for a
  flat, non-nested options surface is a rewrite with no capability gain,
  only a docs-generation gain; the options surface across functions is
  **not shared** (each function has its own allowed-key set), so
  NimbleOptions' main selling point — one schema reused across many
  call sites — doesn't apply here the way it does for Broadway's
  producer/processor/batcher trio.

**Recommendation: do not adopt NimbleOptions at 1.0.** Keep hand-rolled
keyword validation, but close the doc-drift gap a different way: generate
the "Options" table in each function's `@doc` from the same
`@allowed_*_filter_keys` module attribute the validator already uses (a
`Macro`/doc-test or a `mix docs.verify_options` script, not a new runtime
dependency), so accepted keys can never silently drift from documented keys
without a test failure. Revisit NimbleOptions post-1.0 only if/when a truly
nested, cross-function-shared options schema emerges (e.g. a future
`scope_query_fn` config DSL) — not before.

---

## 5. Docs adopters expect at 1.0

### What already exists (evidence)

`guides/` has 16 files. Relevant existing coverage:
- `guides/upgrade-path.md` + `guides/upgrading-to-0.11.md` — an existing,
  working "upgrading to X" pattern to extend for 1.0.
- `guides/configuration-and-commands.md`, `guides/domain-reference.md`,
  `guides/audit-indexing.md` — touch on composite/primary-key shapes in
  passing (`grep` hits above) but **no dedicated supported-table-shapes
  guide exists**.
- `guides/evaluating-threadline.md`, `guides/upgrade-path.md`,
  `guides/telemetry.md` mention "semver"/"stability" in passing — **no
  dedicated stability/semver-policy page exists.**
- **No redaction threat model doc exists** (`grep -il redaction` matched
  files that merely reference redaction features, not a threat-model
  document).

### Classification

| Doc | Table stakes / Differentiator / Anti-feature | Complexity | Depends on |
|---|---|---|---|
| Supported-table-shapes guide | **Table stakes** — every row-level audit library hits "does this work on my weird table" in its first adopter hour; currently scattered across 3 guides, not a single referenceable answer | LOW (collate + extend existing knowledge, mostly writing) | `RowKey.match!/3` behavior (composite keys, `primary_key:` override, dropped/renamed-table fallback, `char(n)` caveat — all already documented inline in `lib/threadline/query.ex:70-100,383-400`) — no code changes, just needs explicit statements on partitioned tables, unlogged tables, views, and cross-schema tables (currently undocumented either way) |
| Redaction threat model | **Table stakes** for a compliance-adjacent product — "what does redaction actually guarantee" is the first question a security reviewer asks, and an *unanswered* one is worse than an honest partial answer | MEDIUM (requires auditing every place plaintext could persist pre-redaction: WAL, logs, telemetry payloads, backups, the `:comment` free-text field on `record_action`, already-captured rows before a redaction rule was added) | No code changes; needs a pass over `Threadline.Telemetry` emit call sites and the capture trigger generator to confirm what it does/doesn't scrub |
| Stability/semver policy page | **Table stakes** at 1.0 specifically — this is the page that makes "1.0.0" mean something; without it, "breaking in a minor" has no documented contract to violate | LOW (write down the policy this milestone is itself enacting: public = `Threadline.*` only per §1d, `@doc false`/private modules excluded from semver, deprecation-then-removal cadence per §1a) | §1d's facade decision (can't write the policy until the public surface is actually settled) |
| Upgrading-to-1.0 guide | **Table stakes** — every breaking change in this milestone (bounded `:limit` default §2, return-shape changes §3, removed `Threadline.Query`/`Threadline.Investigation` public status §1d) needs one canonical, numbered guide, following the existing `upgrading-to-0.11.md` pattern | MEDIUM (one step per ONE-WAY decision above; follows an established template so mostly transcription once decisions are final) | All of §1-§3's ONE-WAY decisions must be finalized first — this doc is written last |

**Anti-feature:** a generic "API reference" guide duplicating `@doc`
content — ExDoc already generates this from moduledocs; a hand-maintained
parallel copy would drift immediately and violates the OSS DNA "doc contract
tests" principle (CLAUDE.md: "README, guides, and example app README stay
aligned via test assertions" — a duplicate reference page has no such test
achievable without literally re-deriving ExDoc).

### Docs voice

Per `brandbook/brand-book.md` ("precise, grounded, composed... useful over
impressive... trustworthy because it is inspectable") and the milestone
guide's JTBD/GOV.UK voice direction: each of the four docs above should open
with a one-line "who this is for" / "what this answers" sentence (the
pattern `guides/upgrading-to-0.11.md:7-12` already uses — "Use this guide
if..."), state constraints in plain declarative sentences rather than
hedging ("The fallback cannot reproduce blank-padding" — not "there may be
some edge cases around padding"), and the redaction threat model in
particular should state what it does **not** guarantee as plainly as what it
does, matching the brand's "trustworthy because it is inspectable" promise —
a redaction doc that only lists guarantees and omits gaps reads as "quietly
confident" turning into overconfident, which is an explicit anti-trait.

---

## 6. Other 1.0 API gaps (evidence-only, no new product scope)

- **No `row_history!`/`audit_transaction!` raising siblings** for the
  `{:ok,_}/{:error,_}` functions once §3's rule 2 lands — Ecto's own
  `get`/`get!` pairing means adopters will reach for a `!` variant by
  muscle memory; omitting it for exactly the functions that just gained
  ok/error tuples (`audit_transaction/2`, `transaction_context/2`) is a gap
  the migration itself creates. Low complexity (thin wrapper), should ship
  in the same PR as §3's change, not deferred.
- **Two page-struct shapes today** (`TimelinePage` vs `ActorHistoryPage`)
  is itself the gap §3 flags — restated here because it is the kind of
  "fit and finish" miss a 1.0 contract review exists to catch: a generic
  pagination component built against one struct breaks against the other.
- **No documented escape hatch policy** for `Ecto.Query.t()`-returning
  functions once `Threadline.Query`/`Threadline.Investigation` go private
  (§1d) — `timeline_query/1` needs an explicit "this one stays public and
  here's why" callout, or adopters composing custom queries lose their only
  legitimate path and will reach into the hidden modules anyway (Elixir has
  no access-control enforcement, so hiding a moduledoc doesn't prevent the
  call, it just makes the compatibility contract silently absent).
- **No `mix threadline.doctor`/schema-coverage check is a gap this research
  found evidence AGAINST, not for** — `guides/audit-indexing.md` and
  `guides/production-checklist.md` suggest capture-coverage checking already
  exists in some form; do not add new "coverage" API surface here, it is out
  of this milestone's scope per the common-context (no new product scope).
- **Nothing found evidence for** beyond the above: no gap was found in
  cross-table joins, export parity, or diff rendering — those already have
  dedicated, consistent entry points (`timeline`/`export_csv`/`export_json`/`change_diff`)
  that this research's inventory did not flag as inconsistent.

---

## Summary table for REQUIREMENTS.md scoping

| Item | Category | Complexity | ONE-WAY? | Depends on |
|---|---|---|---|---|
| Merge `history`+`row_history` into one `row_history/3`, paging via `:cursor` opt | Table stakes | MEDIUM | Yes | `HistoryLimit`, `RowKey`, `Investigation.linked_changes/2` |
| Fold `filters` into `opts` (drop the parallel-list signature) | Table stakes | LOW-MEDIUM | Yes | same functions as above |
| Bounded default `:limit` (200) + truncation telemetry | Table stakes | MEDIUM | **Yes** | `HistoryLimit`, new telemetry event |
| Unify `TimelinePage`/`ActorHistoryPage` → one `Threadline.Page` | Table stakes | MEDIUM | Yes | `Cursors` module, every paged function's call sites |
| `transaction_context/2`, `audit_transaction/2` → `{:ok,_}/{:error, :not_found}` + `!` siblings | Table stakes | LOW-MEDIUM | Yes | `Investigation`, `Query` |
| Hide `Threadline.Query`/`Threadline.Investigation` publicly; keep `timeline_query/1` as the one documented escape hatch | Table stakes | LOW | Yes | all facade delegation call sites |
| Keep hand-rolled option validation; add generated-from-attribute options doc check | Differentiator (DX polish) | LOW | No | `@allowed_*_filter_keys` attributes |
| Supported-table-shapes guide | Table stakes (docs) | LOW | No | none (writing only) |
| Redaction threat model | Table stakes (docs) | MEDIUM | No | audit of Telemetry/capture trigger plaintext paths |
| Stability/semver policy page | Table stakes (docs) | LOW | No | the facade decision above |
| Upgrading-to-1.0 guide | Table stakes (docs) | MEDIUM | No | all ONE-WAY rows above finalized first |
| NimbleOptions adoption | Anti-feature at 1.0 | — | No | — (explicitly recommended against) |
| Generic API-reference guide duplicating ExDoc | Anti-feature | — | No | — (explicitly recommended against) |

## Sources

- Codebase: `lib/threadline.ex`, `lib/threadline/query.ex`,
  `lib/threadline/investigation.ex`, `lib/threadline/query/history_limit.ex`,
  `guides/` directory listing, `brandbook/brand-book.md` (all read directly,
  cited by file:line above).
- [PaperTrail (Elixir) VersionQueries — hexdocs v1.1.2](https://hexdocs.pm/paper_trail/PaperTrail.VersionQueries.html)
- [PaperTrail (Elixir) README — hexdocs v1.1.2](https://hexdocs.pm/paper_trail/readme.html)
- [Carbonite.Query — hexdocs](https://hexdocs.pm/carbonite/Carbonite.Query.html)
- [Carbonite GitHub — bitcrowd/carbonite](https://github.com/bitcrowd/carbonite)
- [ExAudit README — hexdocs v0.10.0](https://hexdocs.pm/ex_audit/readme.html)
- [ExAudit.Repo — hexdocs v0.10.0](https://hexdocs.pm/ex_audit/ExAudit.Repo.html)
- General knowledge (not re-verified this session, flag as MEDIUM
  confidence): `audited` gem `audits`/`revision` API, Logidze `at`/`diff_from`
  API, django-simple-history `history.as_of`, Hibernate Envers
  `AuditReader.forRevisionsOfEntity`/`find`, Ecto/Oban/Req/Flop/Paginator/Scrivener
  return-shape and pagination-default conventions — these are stable,
  long-documented public APIs consistent with training knowledge; recommend
  a spot-check against current hexdocs/PyPI/Maven pages before quoting exact
  option names verbatim in REQUIREMENTS.md or user-facing docs.
