# Threadline documentation and typespec rubric

Frozen at plan 234-01; any later edit is a review finding.

This rubric is binary. The reviewer applies it to every visible function,
macro, public type, and moduledoc in scope. A surviving broad type must name
the rule that permits it.

## Spec rubric: broad types

- **R1 — Caller-owned opaque value.** Threadline never inspects the value
  (`:scope`, a callback result, rollback reasons). Prefer a type variable, or
  a named type whose typedoc says "opaque to Threadline".
- **R2 — Predicate or validator over arbitrary input**, including the
  offending value echoed back in an error tuple.
- **R3 — jsonb column or JSON-bound wire map.** Use a named type such as
  `json_map`; its typedoc lists the guaranteed keys and the additive-key
  promise. This applies to `data_after`, `changed_from`, `meta`, `ChangeDiff`
  output, and export rows.
- **R4 — Options forwarded to an adapter or behaviour implementer** that
  Threadline does not own; the typedoc says "adapter-defined".
- **R5 — Inside a private or hidden spec only.** This is out of SPEC-02 scope.

An occurrence of `term()`, `any()`, `map()`, `keyword()`, or `Keyword.t()`
fails when any condition below holds:

- **(a)** The value has a known finite shape: a struct, tagged tuple, atom
  set, or string-keyed map with a key list.
- **(b)** An options argument is `keyword()` or `Keyword.t()` instead of
  `[named_opt()]`.
- **(c)** A struct type is `%__MODULE__{}` or `%Other{}` with term fields.
- **(d)** A public spec references a `@typep` or a type in a hidden module.
- **(e)** A public type has no `@typedoc`.
- **(f)** A return is `map()` with fixed atom keys.

## Documentation rules

### Summary paragraph

The first paragraph states what the caller gets back, in domain nouns such as
`AuditChange`, `AuditTransaction`, `LinkedChange`, or `ActorRef`. It is the
only part ExDoc shows in the sidebar, search, and autocomplete. Side-effect
functions start with a verb such as "Records" or "Enqueues" and name the
return in the same paragraph. There is no global "must start with Returns"
rule: it would reject legitimate verbs and reward boilerplate.

### Full template

The full template applies to every facade function, every function taking
options, and every function that touches the database. It includes the summary,
when to use the sibling with a cross-link, a semantics paragraph, filters for
`(filters, opts)` functions, options, unknown-key behavior, every return/error
shape and raise, optional examples, and the captured-data note where required.

```elixir
@doc """
Returns <shape in domain nouns> for <subject>, <ordering/bound>.

Use `sibling/2` when <the other case>. <Semantics: defaults, edge cases, what "empty" means.>

## Filters                     (only for (filters, opts) functions)

- `:table` — string or atom. Optional. Limits to one captured table.

## Options

- `:repo` — `Ecto.Repo` module. Required.
- `:page_size` — positive integer. Defaults to `1000`.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Returns

- `{:ok, %LinkedTransaction{}}` — ...
- `{:error, :not_found}` — ...

## Examples

    {:ok, txn} = Threadline.transaction_context(id, repo: MyApp.Repo)

Results contain column values as captured; redaction is applied when triggers
are generated, not on read. Authorize reads with `:scope_query_fn`.
"""
```

### Floor template

The floor applies to small pure helpers: one sentence covering the input
domain, output shape, and failure, with no headings or filler.

```elixir
@doc "Returns `name` double-quoted for SQL after validating it; raises `ArgumentError` if it is not a PostgreSQL identifier."
```

### Options and filters

Use exactly `## Options` and `## Filters`. Each bullet has this form, followed
by its meaning and any raise behavior:

```text
- `:key` — type in words. Required. | Defaults to `x`. | Optional.
```

Mark required options inline. Migrate `record_action/2`'s required/optional
headings into one list. Split `timeline/2`'s filters from options, turn
`timeline_page/2`'s option prose into bullets, and add lists for
`actor_window/3` and `correlation_bundle/3`. Deprecated options use
`## Deprecated options`; those bullets are excluded from D-21 parity.

### Captured-data note

Functions that return or write captured row values include this note:

> Results contain column values as captured; redaction is applied when
> triggers are generated, not on read. Authorize reads with `:scope_query_fn`.

This applies to `timeline`, the `row_history` family, `incident_bundle`,
`change_diff`, and `export_*`. Make no other security claims or unscoped
absolutes.

### Examples

Examples are plain indented code with no `iex>` prompt. Database-backed
functions cannot be doctested, and an `iex>` prompt invites a broken
`doctest Threadline`. Examples are required for `record_action/2`, composite-id
and cursor-walk reads, and `Audit.transaction/3`; elsewhere they are optional.

### Version, references, modules, and voice

- `@doc since:` appears only on names new in 1.0, with exactly `"1.0.0"`.
  Do no historical archaeology. Functions whose return shape changed but whose
  name did not get no `since`; the CHANGELOG and upgrade guide own that history.
- Docs and moduledocs do not point to a deprecated function as the way to do
  something. Ten hits were noted today: `as_of/4` ("same `id` shapes as
  `history/3`"), `Health.legacy_key_findings/1`, and the `Continuity`,
  `Health.Finding`, and `Telemetry` moduledocs. The facade moduledoc paragraph
  listing deprecated names is the sole allowance. Deprecated entries' own
  docs are not treated as pointers.
- Every touched moduledoc starts with a one-sentence domain-language summary.
  A module with three or more public functions names its entry points and when
  to use them. Struct modules may keep one sentence, with `t/0`'s typedoc
  carrying the shape. Do not promise field stability; that belongs to 235.
- Use short declarative sentences and active voice, with no exclamation marks.
  Avoid "powerful", "seamless", "robust", and "next-generation". Avoid
  "provenance", "governance", and "immutable ledger". Use plain language
  without idioms. Preserve the domain boundaries: an action is not a change, a
  transaction is not a request, and a user is not always the actor.

## Binary review checklist

### Documentation

- **D-1:** Exists and has a non-empty first paragraph (M2).
- **D-2:** The first paragraph states the return or side effect.
- **D-3:** It adds information beyond the name.
- **D-4:** It links the sibling and says when to use which.
- **D-5:** `## Options` and `## Filters` are complete in the D-37 form.
- **D-6:** Every error, raise, and `!` exception is named, plus the unknown-key
  sentence.
- **D-7:** No deprecated pointer (M4).
- **D-8:** Domain terms are correct and avoid-list terms are absent.
- **D-9:** Examples have no `iex>` and parse (M8).
- **D-10:** The D-38 note appears where required.
- **D-11:** Voice is clear and the doc does not restate the spec.
- **D-12:** The `since` rule passes (M7).

### Specs and types

- **S-1:** A spec exists at every docs-entry arity.
- **S-2:** The spec return matches the doc's first paragraph.
- **S-3:** Deprecated delegates' specs are honest.
- **S-4:** The D-25 rubric passes.
- **S-5:** Every public type used in a public spec has a `@typedoc`.

### Moduledocs

- **M-1:** The moduledoc starts with a one-sentence summary.
- **M-2:** Entry points are named when the module has three or more functions.
- **M-3:** It makes no stability promise owned by 235.

## Mechanized checks

These checks run asynchronously from `Code.fetch_docs`; each compares measured
findings with an exact ratchet. Broken links remain with
`mix docs --warnings-as-errors` and are not duplicated here.

- **M2:** Non-empty first paragraph and no TODO/FIXME/XXX.
- **M3:** D-21 option/filter parity: runtime allowlist, named type keys, and
  `## Options`/`## Filters` bullets agree; key order is free.
- **M4:** D-41 deprecated-reference rule, apart from its stated allowances.
- **M6:** No banned voice words or sentence-ending exclamation marks outside
  code.
- **M7:** A present `since` equals `"1.0.0"` and names a pinned 1.0 addition.
- **M8:** Every indented code block parses with `Code.string_to_quoted/1`; no
  `iex>` appears in modules without test doctests.
- **M9:** Keep family-specific first-paragraph checks for the 233 lookups and
  API-02; do not add a global regex.

## Existing failures to resolve

- `Evidence.record_retention_run/3`: "Records retention-run evidence."
  fails D-2 because it gives no return value or subject.
- `export_csv/2` and `export_json/2` do not cross-link (D-4), and neither names
  its errors (D-6).
- `actor_window/3` has no `## Options` (D-5).
- `timeline/2` mixes filters and options in one list (D-5).
- `as_of/4` points at deprecated `history/3` (D-7).
- `Evidence.Proof`'s moduledoc uses jargon and names no entry point (M-1).
