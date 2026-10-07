# Phase 234: Typespec and Doc Completion Gate - Context

**Gathered:** 2026-10-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Every public function an adopter can see has a `@doc` and a `@spec` that says something real. Coverage cannot regress. Strict Dialyzer is green with zero ignores. The `Threadline` facade page reads by job (four `@doc group:` groups) rather than alphabetically. Requirements: SPEC-01, SPEC-02, SPEC-03.

In scope:
- the coverage gate;
- named option and filter types;
- hand-written struct field types;
- closing the runtime option allowlists so they match the types;
- the Dialyzer flag set;
- facade grouping;
- doc rewrites to a written rubric;
- the 233 WR-01 fix.

Not in scope:
- stable-field promises (235 CONTRACT-05);
- the stability guide (235 CONTRACT-01);
- the upgrade guide (237);
- operator-UI markup. Only call sites forced by D-17 are touched.

</domain>

<decisions>
## Implementation Decisions

Research came from six parallel researchers on 2026-10-04. They covered:
- coverage-gate design;
- spec vocabulary and option types;
- Dialyzer strictness;
- facade grouping;
- the doc-content rubric;
- phase shape and seams.

They read `prompts/`, `brandbook/brand-book.md`, 231–233 CONTEXT, ExDoc 0.40.1 source, and peer libraries (Ecto, Oban, Req, Phoenix, Finch, dialyxir, Rust/Go/TS/Python lint prior art). Several facts were verified by running code in scratch projects; they are marked *(verified)*. The maintainer accepted the full set (27 recommendations) with one confirm: "Accept all". That includes the three flagged calls:
- close the option allowlists (D-15);
- hide 8 helpers (D-07);
- an exact-pinned size exception for `lib/threadline.ex` (D-14).

### Baseline correction
- **D-01:** The roadmap and REQUIREMENTS figure of "129 of 169 missing" predates phases 231–233, which hid `Threadline.Query`, `Threadline.Investigation` and the internal helpers. The measured baseline at `9e1e7642` is **54 of 92** visible public entries across 52 documented modules: 53 lack a `@spec` and 6 lack a `@doc`.
  - Leave the SC text unchanged and add a one-line re-measure note to ROADMAP.md and REQUIREMENTS.md.
  - The committed checker (D-02) makes the number reproducible.
  - VERIFICATION.md states the before and after numbers, and ties each module hidden since the old count to its 231–233 decision id, so the shrink cannot read as gaming.
  - Other measured baseline facts:
    - 33 visible specs use bare `keyword()`, `term()` or `map()`;
    - schema `t()` types have `term()` in every field;
    - `AuditAction` has no `@type t`;
    - 15 of 25 visible `@type`s lack a `@typedoc`.

### SPEC-01: the coverage gate
- **D-02:** New file `test/threadline/doc_spec_coverage_contract_test.exs`, `async: true`. A pure checker `gaps(module, docs_v1, specs) :: [{m, f, a, :missing_doc | :missing_spec | :missing_typedoc}]` sits behind a thin live wrapper.
  - The failure message has one sorted line per gap (`Threadline.Foo.bar/2  missing @spec`), plus the hint "add @doc/@spec, or @doc false plus a reasoned entry in the hidden pin".
  - A new partition-weight line is needed, about 30.
  - Do not extend `public_surface_contract_test.exs`: it is `async: false` and weighted about 19 s.
- **D-03:** Universe. Every app module whose `module_info(:compile)[:source]` is **not under `test/`** and whose moduledoc is not `:hidden`. Modules with no moduledoc (`:none`) count as documented.
  - *(verified)* In `MIX_ENV=test`, `:application.get_key(:threadline, :modules)` returns 192 modules, including about 40 from `test/support`, 28 of them visible. Filtering by "not under `test/`" returns exactly the 52 documented modules.
  - Filter by "not under `test/`", not "under `lib/`". `Threadline.Export.CSV` reports a `deps/nimble_csv` source.
  - Docs chunks are present in the test env *(verified)*.
  - Entries checked: `:function` and `:macro` entries whose doc is not `:hidden`, skipping `__*__` names.
- **D-04:** Rules:
  - Every function needs a `@doc` map plus a `@spec` at the docs-entry (maximum) arity. Lower default-argument arities are exempt. This is Elixir/Ecto convention, and ExDoc renders only the maximum-arity spec.
  - Macros and guards need a `@doc` only: a spec on a `defmacro` is stored as `MACRO-name/arity+1` *(verified)*, and that exemption is pinned.
  - Deprecated entries get no exemption (API-08, 232 D-11).
  - A visible `@impl` callback that carries an explicit `@doc` also needs a spec (today only `ExportQueue.TaskAdapter.enqueue/2`).
  - *(verified)* `@impl true`, protocol impls and `defexception` callbacks come back `:hidden` automatically.
- **D-05:** Every visible `@type` and `@opaque` needs a `@typedoc` (gap kind `:missing_typedoc`). This keeps the gate consistent with the named option types of SPEC-02.
- **D-06:** The `@doc false` escape hatch is pinned.
  - The same test pins the exact set of explicitly hidden functions inside documented modules, as `%{{M, f, a} => "reason"}`.
  - Behaviour callbacks (`module_info(:attributes)[:behaviour]` plus `behaviour_info/1`), `__*__` names and default-argument expansions are excluded automatically.
  - Today the set is 22 entries: `Telemetry.emit_*`/`purge_span`, `changeset/2` ×4, `Health.classify/3`, `Health.coverage_by_schema/1`, `StorageSchema.validate_identifier!/3`, `Mix…Health.Coverage.legacy_findings_or_hint/2`, and `S3.delete/2`/`get/2`. After D-07 it is 30.
  - Every pin must still exist and still be `:hidden`, so no stale pins accumulate.
  - This mirrors TypeScript api-extractor's reviewed hidden surface. Rust `missing_docs` with `#[doc(hidden)]`, and Go's exported-comment lint, show the failure mode it prevents.
- **D-07:** Triage of the 54 gaps: 46 get a doc and spec, 8 are hidden.
  - The hidden ones are six `StorageSchema` SQL-building helpers (`quote_ident/1`, `qualify/2`, `function/2`, `parse_table_identifier/1`, `qualified_host_table/1`, `host_table_suffix/1`) and two in `Evidence.Proof` (`present_record/1` and `record_claim_assessment/1`, whose only caller is `operator_surface/live/evidence_live.ex`). guides/, README and the example app have no hits for them; re-grep at execution time per API-05.
  - Every other gap is documented and specced:
    - `Threadline`: `as_of/4`, `audit_changes_for_transaction/2`, `change_diff/2`, `export_csv/2`, `export_json/2`, `record_action/2`, `timeline/2`.
    - `Continuity` ×2 and `Evidence` ×13 (the example app calls `record_*`).
    - `Evidence.Proof`: the other 4.
    - `Evidence.Subject.supported_subjects/0`.
    - `Export.Orchestrator.run/2`, the extension point for custom adapters.
    - `ExportQueue.TaskAdapter.enqueue/2` and `Health.trigger_coverage/1`.
    - `Health.Policy.validate!/1`; production-checklist tells adopters to call it.
    - `Job` ×2; integration-contracts and the example `blog.ex` use them.
    - `OperatorSurface.Auth.on_mount/4`; operator-surface.md names it.
    - `OperatorSurface.Router.threadline_operator_surface/2`, a macro, which needs a doc only. Move or summarise its options from the moduledoc into its `@doc`.
    - `ActorRef` ×3 and `Telemetry.transaction_committed/2`.
    - `StorageSchema`: `get/1`, `repo_opts/1`, `table/2`, `validate!/1`, `threadline_table?/1`. The example app and guides use them, and `table/2` serves SQL-native adopters.
    - `Verify.CoveragePolicy` ×2.
  - **Reversibility:** one-way. Hiding after 1.0 would be breaking. Un-hiding later is additive, which is why hiding now is the right direction.
- **D-08:** Hiding is a breaking change. Each newly hidden, previously visible function gets:
  - one grouped CHANGELOG `Unreleased` → Breaking changes bullet: "no longer part of the documented API; still callable, may change in 1.x";
  - a `BREAKING CHANGE:` footer on that commit;
  - a mechanical assertion that every name in the D-07 hidden set appears in the CHANGELOG `Unreleased` section.

  The default for anything not in D-07 is to document, not hide.
- **D-09:** The gate lands first as a ratchet.
  - Plan 234-01 commits the gate with every current gap pinned exactly, following the `source_size_contract_test` exact-pin pattern: a pinned entry that has since been fixed also fails.
  - Each later plan deletes the pins for what it fixed. The last plan deletes the pin machinery, so the test asserts zero gaps.
  - The same ratchet covers the bare-type lint (D-25) and ungrouped facade functions (D-33).
- **D-10:** Mutation controls.
  - **In-test fixture:** `Code.compile_string` compiles a uniquely named fixture holding an undocumented function, a documented-but-unspecced function, a hidden one, a defaults one, a documented macro, a deprecated one, an `@impl` callback and an untypedoc'd `@type`. Read it **from the binary**: `:beam_lib.chunks(bin, [~c"Docs"])` and `Code.Typespec.fetch_specs(bin)`. *(verified)* `Code.fetch_docs/1` on a compile_string module returns `:error`.
  - The test asserts the exact gap list, asserts the Docs chunk exists so the fixture cannot pass vacuously, and purges the fixture in `on_exit`.
  - **Live mutation:** also record one in VERIFICATION.md: delete one real `@spec`, run the test, observe it fail, revert.
- **D-11:** Vacuity sentinels: the universe has at least 50 modules, at least 90 entries are checked, and `{Threadline, :timeline, 2}` is in the checked set.
- **D-12:** No new `mix verify.docs` alias. The file runs in `verify.test`/`ci.all`. Name the file in CONTRIBUTING instead.

### SPEC-02: specs that say something real
- **D-13:** Shared option and filter types live **on the `Threadline` facade**, so they render on the one page adopters read. Struct and result types live in their visible owning modules (`Page`, `ChangeDiff`, `Export`, the schemas).
  - No `Threadline.Types` module.
  - *(verified)* A visible spec referencing a type in a `@moduledoc false` module makes ExDoc 0.40.1 warn ("documentation references type … but the module … is hidden"), so `mix docs --warnings-as-errors` fails.
  - *(verified)* A `@typep` in a public spec renders as an unlinked name with no warning.
  - So the rule: every type a visible spec references lives in a documented module and is a public `@type`.
  - The `Investigation` structs `LinkedChange`, `LinkedTransaction`, `IncidentBundle` and `IncidentChange` are visible ("Data Types"), so referencing them is fine.
  - Hidden modules may reference facade types. Facade specs never reference hidden ones.
- **D-14:** `lib/threadline.ex` (607 lines today against `@file_limit 800`) will exceed 800 once types, groups and the D-36/D-37 doc sections land. Add **one exact-pinned `@file_exceptions` entry** in `test/threadline/source_size_contract_test.exs`.
  - Named reason: "single adopter-facing facade; length is @doc/@type prose, not logic".
  - Update that test's "exactly one named exception remains" assertion to the two-file set. Pin the exact measured line count at the end of the phase.
  - Do not split the types into another module to dodge the limit.
  - **Reversibility:** reversible.
- **D-15:** Close every runtime option allowlist so that unknown keys raise `ArgumentError`.
  - Applies to `timeline/2`, `timeline_page/2`, `actor_window/3`, `correlation_bundle/3`, `actor_history/2`, and the `Export.*` functions (`to_csv_iodata`, `to_json_document`, `stream_changes`, `stream_export_rows`, `count_matching`, `format_changes_iodata`, `csv_header`).
  - Today only `row_history` (`investigation.ex:21`) and the three lookups (`transaction_lookup.ex:15`) validate opts; the rest validate filters only or nothing. That contradicts the locked rule "bad options raise `ArgumentError`".
  - Use per-function allowlists (232 D-03 pattern, no NimbleOptions).
  - This is a 1.0 breaking change: a CHANGELOG `Unreleased` → Breaking changes bullet listing the functions, plus a `BREAKING CHANGE:` footer. 237's upgrade guide carries it.
  - **Reversibility:** one-way. Widening later is additive, but closing after 1.0 would be breaking.
- **D-16:** The internal-only key `:surface` leaves `@row_history_opt_keys`. Once D-17 is done, no public allowlist contains an internal-only key.
- **D-17:** **Fix this before closing the types.** The operator surface passes the internal keys `:surface`/`:params` to public functions in literal lists: `Threadline.actor_history` at `lib/threadline/operator_surface/live/actor_live.ex:32,309,351,394,431`, and `Export.*` at `lib/threadline/operator_surface/controllers/export_controller.ex:178` (re-grep the exact lines).
  - *(verified)* With closed `[opt()]` types, literal calls with an unknown key are Dialyzer errors ("breaks the contract" / "no local return"), and zero-ignores would go red.
  - Move these call sites onto the hidden `Threadline.Query`/`Investigation` functions that legitimately take internal keys.
  - These are forced call-site edits; markup is not touched.
- **D-18:** Option-type architecture:
  - Small shared pieces: `repo_opt`, `storage_schema_opt`, and `scope_opt`, which is `{:scope, term()} | {:scope_query_fn, scope_query_fn()}`.
  - These compose into **one union per function or family**: `row_history_opt`, `timeline_page_opt`, `lookup_opt`, `actor_history_opt`, …
  - Specs use `[row_history_opt()]`.
  - Filter types stay separate (`timeline_filter`, …) for the functions that keep `(…, filters, opts)` (232 D-10). `:repo` is in `timeline_filter` because filters accept it at runtime.
  - Naming: `*_opt` and `*_filter` (singular, as in Finch's `request_opt`), plus `row_id`, `result` and `t`.
  - Not one big `Threadline.opts()`: Dialyzer would then miss a key that is valid elsewhere but wrong for this function.
  - *(verified)* Against `[row_history_opt()]`, Dialyzer flags `limitt: 3` and `limit: 0`. With `keyword()` neither is flagged.
  - Options built at runtime are not checked. There the type is documentation, and the rubric must not over-claim.
  - Example sketches (`repo_opt`, `scope_opt`, `row_id`, `row_history_opt`, `timeline_filter`, `lookup_opt`, `export_result`, `ActorRef.t`) are in `<specifics>`.
  - **Reversibility:** one-way after 1.0.0 publishes. Renaming or narrowing a public type then breaks adopters who run Dialyzer in CI.
- **D-19:** A named `row_id()` type replaces `term()` for host row keys: a scalar for a single-column key, or every key field as a map or keyword list. It covers composite and non-`id` keys, matching the supported-table-shapes work.
- **D-20:** Deprecated options stay in the types through 1.x, for example `actor_history`'s `:after`/`:before`/`:limit` (232 D-09). They are marked deprecated in the typedoc, so adopters' Dialyzer doesn't break inside 1.x. Removal is no earlier than 2.0.
  - Deprecated delegates keep honest specs for the old accepted shape. Don't borrow the replacement's narrowed type where the shapes differ; 232 D-02's `history/3` exception still stands.
- **D-21:** Three-way option drift guard: **runtime allowlist == `@type` keys == `## Options` (and `## Filters`) bullets**.
  - Each allowlist is exposed through a hidden `__option_keys__/1` (or equivalent).
  - Type keys come from `Code.Typespec.fetch_types/1` plus a small walker over `:union`, `:tuple`, `:list`, local `user_type` and `remote_type`. *(verified feasible)*
  - Doc keys come from parsing ``^- `:key` `` under the exact headings.
  - The check must also fail when a function has an options section but no named type (a type still bare `keyword()`).
  - A mutation control applies: a fixture type with an extra key turns the test red.
  - Lives in a sibling `async: true` file, or alongside the D-02 test.
- **D-22:** Schema struct types are hand-written for every field in 234. 235 reads them and documents stability; it does not write types.
  - Every field must be written. *(verified)* A partial `%S{a: integer()}` expands the rest to `term()`.
  - `__meta__: Ecto.Schema.Metadata.t()`.
  - Associations are typed `X.t() | Ecto.Association.NotLoaded.t()`.
  - jsonb columns use a named `json_map` type (rubric R3).
  - `AuditTransaction`'s virtual `action` field is `struct() | nil`, with a typedoc: "a hydrated `Threadline.Semantics.AuditAction`; nil until hydrated". This honors 231 D-05: the capture schema must not reference `AuditAction.t()`. The precise type is exposed through `LinkedChange.action :: AuditAction.t() | nil` and the other `Investigation` structs.
  - `AuditAction` gains a `@type t`. `ActorRef.t` gets `type: actor_type()`, `id: String.t() | nil`, and `actor_type` is the six-atom union from the domain model. `AuditContext` gets real field types.
  - No typed_ecto_schema or typed_struct dependency.
  - **Reversibility:** one-way after 1.0.
- **D-23:** `Page.t(entry)` stays parameterized, and facade specs always instantiate it (`Page.t(LinkedChange.t())`).
  - Cursor types stay transparent maps (232 D-06).
  - Fix the `Page.actor_cursor` typedoc: it names `actor_window/3`, but `actor_window` pages with a change cursor. Only `actor_history`'s page carries `actor_cursor`.
- **D-24:** Legitimate generic types:
  - `Audit.transaction/3` uses a type variable (`when result: term()`);
  - `ActorRef.identifiable?(term())` stays (rubric R2);
  - `Export.to_csv_iodata`/`to_json_document` return a named `export_result()`, not `{:ok, map()}`;
  - `Storage.options()` stays adapter-defined, with a typedoc (rubric R4);
  - underspecs findings on validators (for example `TransactionLookup.resolve_id(term())`) are narrowed to what the code accepts, never to `any()`.
- **D-25:** The written spec rubric. The verifier applies it to every visible spec and public `@type`, and records each surviving `term()`/`any()`/`map()`/`keyword()` with the rule that allows it.
  - **R1 — Caller-owned opaque value** that Threadline never inspects (`:scope`, a callback result, rollback reasons). Prefer a type variable, or a named type whose typedoc says "opaque to Threadline".
  - **R2 — Predicate or validator over arbitrary input**, including the offending value echoed back in an error tuple.
  - **R3 — jsonb column or JSON-bound wire map.** Must be a named type such as `json_map`, whose typedoc lists the guaranteed keys and the additive-key promise. Applies to `data_after`, `changed_from`, `meta`, `ChangeDiff` output and export rows.
  - **R4 — Options forwarded to an adapter or behaviour implementer** that Threadline does not own; the typedoc says "adapter-defined".
  - **R5 — Inside a private or hidden spec only.** Out of SPEC-02 scope.
  - **Fails** if any of these hold:
    - (a) the value has a known finite shape (struct, tagged tuple, atom set, string-keyed map with a key list);
    - (b) an options argument is `keyword()` or `Keyword.t()` instead of `[named_opt()]`;
    - (c) a struct type is `%__MODULE__{}` or `%Other{}` (term fields);
    - (d) a public spec references a `@typep` or a hidden module's type;
    - (e) a public type has no `@typedoc`;
    - (f) a return is `map()` with fixed atom keys.

  This becomes slot S-4 of the D-34 rubric.

### Dialyzer strictness
- **D-26:** Flags become `[:unmatched_returns, :extra_return, :missing_return, :underspecs, :error_handling]`, with `list_unused_filters: true`. PLT paths and `plt_add_apps` are unchanged.
  - *(measured at HEAD, dialyxir 1.4.8, OTP 27)* The added set yields **22 warnings**, all fixed in-phase by fixing code or specs, never the ignore file:
    - **9 `missing_range`** from `:missing_return`. These are deprecated legacy-paging specs on `Threadline` and their `Investigation` twins, plus `Query.preload_investigation_context/3`. The specs lie, so widen them or make the code return only the spec'd shape.
    - **9 `contract_supertype`** from `:underspecs`: `Export` `{:ok, map()}`, `TransactionLookup.resolve_id(term())`, `Query.Cursors.validate_*_cursor!`, `Presentation` ×2, `CriticTrust.LedgerSplice` ×2.
    - **4 from `:error_handling`**: private raise-only helpers that need `no_return()` specs.
  - Prior art: Oban uses error_handling/missing_return/underspecs; dialyxir itself uses unmatched_returns/error_handling/underspecs.
  - Rejected:
    - `:overspecs`: 66 more warnings that punish deliberately narrow public contracts;
    - `:specdiffs`: 135 warnings;
    - `:no_opaque`: there are no `@opaque` types;
    - `:overlapping_contract`/`:no_improper_lists`: 0 today, and version-sensitive.
  - Dialyzer runs on `lib/` in the dev env only.
- **D-27:** Zero ignores stays enforced. `.dialyzer_ignore.exs` stays present as `[]`.
  - Update `test/threadline/dialyzer_ignore_contract_test.exs`'s flags assertion to the sorted 5-flag list, and assert no `:no_*` flags are present.
  - Add a grep contract: no `@dialyzer` attribute anywhere under `lib/` (0 today). An inline `nowarn_function` is an ignore under another name.
  - The `verify-dialyzer` CI job `id:`, `mix verify.dialyzer` and the `ci.all` steps are unchanged.
  - Editing `mix.exs` busts the CI PLT cache key once (about 9 min cold). Expected.
  - Check that the sealed `critic-tooling` slice in `dialyzer_slice_contract_test` stays at 0 live warnings.
- **D-28:** No `no_return()` on public `!` functions (233 D-08). `no_return()` goes only on private raise-only helpers.
  - Never add `@opaque` for 1.0: opaque violations surface in adopters' own Dialyzer, and OTP 28 nominal types shift that behaviour.
  - `defdelegate` with defaults produces several arities. Spec every arity that has its own docs entry (D-04).

### SPEC-03: facade grouped by job
- **D-29:** Mechanism: `@moduledoc groups: [%{title:, description:}]` plus per-function `@doc group:`, following `Ecto.Repo` (`deps/ecto/lib/ecto/repo.ex:223`). Do **not** use `groups_for_docs` in mix.exs.
  - *(verified, ExDoc 0.40.1)* A function's group is `metadata[:group]` (`config.ex:7`). `groups_for_docs` predicates take precedence (`config.ex:116-124`), so never add a broad one later.
  - Group order is `@moduledoc groups:` first, then `groups_for_docs` keys, then `Types`/`Callbacks`/`Functions`, then any other titles sorted (`retriever.ex:146-152,267`). **Without `@moduledoc groups:` the four sort alphabetically.**
  - Within a group, entries sort by name/arity. Deprecated entries are not moved and keep their badge.
  - An ungrouped function silently falls into a trailing "Functions" section.
  - `&` in titles is safe: anchors become `#capture-transactions` etc. (`utils.ex:38-45`).
  - `@doc group:` works on `defdelegate` and deprecated functions, and merges with `@doc since:`.
- **D-30:** Group order follows REQUIREMENTS: **Capture & Transactions, Querying & Timelines, Actions & Context, Operations.** Each group has a one-sentence description:
  - Capture & Transactions: capture itself is the triggers your migrations install (`mix threadline.gen.triggers`); these functions read one captured `AuditTransaction` by id.
  - Operations: exports. Retention, health and coverage live in `Threadline.Retention`, `Threadline.Health` and `mix threadline.verify_coverage`.
  - Write the other two descriptions in the same voice.
- **D-31:** Function → group, assigned by the key the caller already holds. Deprecated delegates go in their replacement's group, and no group named "Deprecated" exists.

  | Group | Functions |
  |---|---|
  | Capture & Transactions (7) | `audit_transaction/2`, `audit_transaction!/2`, `transaction_context/2`, `transaction_context!/2`, `incident_bundle/2`, `incident_bundle!/2`, `audit_changes_for_transaction/2` |
  | Querying & Timelines (8) | `timeline/2`, `timeline_page/2`, `row_history/3`, `as_of/4`, `change_diff/2`, `history/3` (dep), `row_history/4` (dep), `row_history_page/4` (dep) |
  | Actions & Context (6) | `record_action/2`, `actor_history/2`, `actor_window/3`, `actor_window_page/3` (dep), `correlation_bundle/3`, `correlation_bundle_page/3` (dep) |
  | Operations (2) | `export_csv/2`, `export_json/2` |

  Re-check the 23 entries against `Code.fetch_docs(Threadline)` at execution time.
- **D-32:** Replace the moduledoc's hand-written "Reading audit data" list of 13 functions with a short `## Jobs` section. It has one bullet per group, naming 2–3 entry points. This is also the only group signal that ExDoc's Markdown/llms.txt output keeps.
  - The 231 D-02 escape-hatch text naming `Threadline.Query.timeline_query/1` must survive.
  - Option types are not grouped (no `@typedoc group:`, which interleaves types with functions). They render in the default "Types" section after the four groups, and `## Options` cross-links them.
- **D-33:** The group test is a new `describe` block in `test/threadline/facade_naming_contract_test.exs`, which is already `async: true`, so no new weight is needed. It asserts:
  - (a) every visible `:function`/`:macro` entry's group is in the 4-name allowlist, naming each offender;
  - (b) an exact `{name, arity} => group` pin of D-31;
  - (c) the `@moduledoc groups` titles equal the allowlist in order, and every group is non-empty;
  - (d) every backticked `name/arity` in `## Jobs` exists and belongs to that bullet's group;
  - (e) a mutation control: a pure `ungrouped/2` helper run on a literal fixture.
- **D-34:** Raise `{:ex_doc, "~> 0.34"}` (mix.exs:108) to `"~> 0.40"`. `:group` metadata arrived in 0.36, so 0.34–0.35 would silently drop the grouping. ExDoc is dev-only, so adopters are unaffected. Check whether any deps contract test pins the version string.

### What a real @doc contains: rubric and templates
- **D-35:** The first paragraph is a summary stating what the caller gets back, in domain nouns (`AuditChange`, `AuditTransaction`, `LinkedChange`, `ActorRef`). It is the only part ExDoc shows in the sidebar, search and autocomplete. This extends API-02 and 233 D-05.
  - Side-effect functions start with a verb ("Records…", "Enqueues…") and name the return in the same paragraph.
  - There is no global "must start with Returns" regex: it would fail legitimate verbs and reward "Returns the foo." boilerplate.
- **D-36:** Two tiers.
  - The **full template** applies to every facade function, every function taking options, and every function that touches the database. Its parts:
    - the summary;
    - when to use the sibling, with a cross-link;
    - a semantics paragraph;
    - `## Filters`, only for `(filters, opts)` functions;
    - `## Options`;
    - the unknown-key `ArgumentError` sentence;
    - `## Returns`, naming every error tuple, raise and `!` exception;
    - optional `## Examples`;
    - the D-38 note where it applies.
  - The **floor** applies to small pure helpers: one sentence covering input domain, output shape and failure, with no headings or filler.
  - Both templates are in `<specifics>`.
- **D-37:** Option docs use exactly `## Options` (and `## Filters`). Each bullet has the form ``- `:key` — type in words. Required. | Defaults to `x`. | Optional.`` then meaning, then any raise behaviour.
  - Required options are marked inline.
  - `record_action/2`'s `## Required options`/`## Optional options` split is migrated.
  - `timeline/2`'s mixed filters-and-options list is split; today it contradicts its own sentence.
  - `timeline_page/2`'s prose becomes bullets.
  - `actor_window/3` and `correlation_bundle/3` gain lists.
  - Deprecated options get `## Deprecated options` (the `actor_history/2` precedent), excluded from D-21 parity.
- **D-38:** Captured-data note on functions that return or write captured row values: `timeline`, the `row_history` family, `incident_bundle`, `change_diff`, `export_*`. It says:
  - results contain column values as captured;
  - redaction is applied when triggers are generated, not on read;
  - read access control is the caller's job, through `:scope_query_fn`.

  No other security claims and no unscoped absolutes. The DOCS-02 absolutes ban stays scoped to the 236 threat-model guide.
- **D-39:** Examples are plain indented code with **no `iex>`** (database-backed functions cannot be doctested, and an `iex>` prompt invites a broken `doctest Threadline`).
  - Examples are required for `record_action/2`, the composite-id and cursor-walk reads, and `Audit.transaction/3`. Elsewhere they are optional.
- **D-40:** `@doc since:` goes only on names new in 1.0, exactly `"1.0.0"`. No historical archaeology.
  - Functions whose return shape changed but whose name did not (the 233 lookups) get no `since`. The CHANGELOG and the 237 upgrade guide own that history.
- **D-41:** Docs and moduledocs must not point to a deprecated function as the way to do something. 10 hits today: `as_of/4` ("same `id` shapes as `history/3`"), `Health.legacy_key_findings/1`, and the `Continuity`, `Health.Finding` and `Telemetry` moduledocs.
  - The facade moduledoc's paragraph that lists the deprecated names is the one allowance.
- **D-42:** Moduledocs of every touched module get a one-sentence domain-language summary first. A module with 3 or more public functions names its entry points and when to use them.
  - Struct modules may keep one sentence, with the `@typedoc` on `t/0` carrying the shape.
  - No field-stability promises: that is 235 CONTRACT-05's job.
- **D-43:** Voice follows `brandbook/brand-book.md` §Voice and the brand book in `prompts/`, where `brandbook/` is the newer source:
  - short declarative sentences in active voice, no exclamation marks;
  - no "powerful", "seamless", "robust" or "next-generation";
  - avoid "provenance", "governance" and "immutable ledger";
  - plain language with no idioms;
  - exact domain boundaries: an action is not a change, a transaction is not a request, a user is not always the actor.
- **D-44:** Mechanized doc checks run first, `async: true`, from `Code.fetch_docs` only:
  - **M2:** non-empty first paragraph, no TODO/FIXME/XXX;
  - **M3:** = D-21 parity;
  - **M4:** = D-41, no references to deprecated `fun/arity`;
  - **M6:** banned hype words and `!`;
  - **M7:** `since`, when present, equals `"1.0.0"` and the name is in a pinned list of new names;
  - **M8:** indented code blocks parse with `Code.string_to_quoted/1`, and no `iex>` appears in modules that are not doctested;
  - **M9:** keep the family-specific first-paragraph checks (233 lookups, API-02); no global regex.
  - Broken links stay with `mix docs --warnings-as-errors` and are not duplicated.
- **D-45:** The written rubric is committed as `234-SPEC-RUBRIC.md` in plan 234-01, **before any spec or doc is written**, so executors cannot tailor it to their work. It is binary pass/fail with this codebase's examples.
  - **Doc items:**
    - D-1: exists, non-empty first paragraph (M2);
    - D-2: the first paragraph states the return or side effect;
    - D-3: it adds information beyond the name;
    - D-4: links the sibling and says when to use which;
    - D-5: `## Options`/`## Filters` complete in the D-37 form;
    - D-6: every error, raise and `!` exception named, plus the unknown-key sentence;
    - D-7: no deprecated pointer (M4);
    - D-8: domain terms correct, no avoid-list terms;
    - D-9: examples without `iex>` that parse (M8);
    - D-10: the D-38 note where required;
    - D-11: voice, and the doc does not restate the spec;
    - D-12: `since` rule (M7).
  - **Spec items:**
    - S-1: a spec at every docs-entry arity;
    - S-2: the spec return matches the doc's first paragraph;
    - S-3: deprecated delegates' specs are honest;
    - S-4: = the D-25 rubric;
    - S-5: every public type used in a public spec has a `@typedoc`.
  - **Moduledoc items:**
    - M-1: a one-sentence summary;
    - M-2: entry points named when the module has 3 or more functions;
    - M-3: no stability promise owned by 235.
- **D-46:** Review procedure: **exhaustive**, every visible entry (about 92 functions plus touched moduledocs and public types).
  - The reviewer is a fresh agent, never the executor. It reads the frozen rubric plus a `Code.fetch_docs`/spec/type dump and the diff from the phase base. It does not read SUMMARY.md before forming its verdict.
  - VERIFICATION.md records:
    - mechanized check results in the header, which the agent does not re-judge;
    - one row per entry: `Module.fun/arity | tier (F/floor) | failed item ids | note`;
    - every surviving `term()`/`map()`/`keyword()` with its R-rule;
    - every newly hidden function, judged;
    - findings with their fix SHAs;
    - reviewer type and model, `source: automated-review`, and the verdict.
  - The gate is 100% of rows passing. Failures loop back to the executor. Re-review rows are hand-merged with `R1-`/`R2-` prefixes, because ids restart on re-review. Anything still failing after two rounds is a scope escalation, not a waiver.

### Phase shape
- **D-47:** Six plans, executed **sequentially in the main tree without worktrees**. Worktrees have no `deps/`/`_build`, so the red-then-green proofs cannot run there. Set `workflow.use_worktrees false` and re-record `.gsd/dispatch-isolation-sentinel.json` as `none` per plan, then restore both after the phase. Plans:
  - **234-01 (W1) — gate:**
    - Owns `test/`, `234-SPEC-RUBRIC.md` and partition weights only.
    - The D-02 checker and coverage test with the 54 gaps pinned.
    - The D-06 hidden pin.
    - The D-21/D-44 doc checks and the bare-type lint, with ratchet pins plus the reasoned permanent R-rule allowlist.
    - The D-33 group test with all 23 functions pinned as ungrouped.
    - The D-27 contract updates; the flags assertion moves in 234-06.
    - Mutation controls, the rubric file, and weight lines.
  - **234-02 (W2) — facade:**
    - Covers `lib/threadline.ex`, the facade option and filter types, the D-29..D-32 groups, and D-35..D-41 doc rewrites.
    - D-17 call-site moves, D-15/D-16 allowlist closing with CHANGELOG and footer, the D-14 size pin, and the D-34 ExDoc bump.
    - **233 WR-01 as its own test-first commit with a mutation control.** In `lib/threadline/query/transaction_lookup.ex` `fetch_row/2` and `fetch/2`, hoist `Keyword.fetch!(opts, :repo)` above `resolve_id/1`. A malformed id plus a missing `:repo` then raises like the well-formed path does, instead of returning `:not_found`. Amend the existing Unreleased bullet; 233 is unreleased.
  - **234-03 (W2) — evidence:** `evidence.ex`, `evidence/proof.ex` and `evidence/subject.ex` (20 gaps, plus the 2 hides).
    - Planner's discretion: collapse `list_latest_subject_refs/2,3` and `list_subject_ref_history/3,4` into default-argument forms, so docs show one entry each.
  - **234-04 (W2) — operations and small modules:**
    - `StorageSchema` (hide 6, spec 5), `Continuity`, `Job`, `Telemetry`, `Health`, `Health.Policy`, `Verify.CoveragePolicy`, `OperatorSurface.Auth`/`Router`, `Export` incl. `Orchestrator`, `ExportQueue.TaskAdapter`, `Retention`, `Retention.Policy`, `Storage`, `ChangeDiff`.
    - Narrow their `keyword()`/`map()` types.
    - Sync the `Storage` `@type options` excerpt quoted in `guides/code-walkthrough.md:462-477`; no test catches that drift.
  - **234-05 (W2) — data types:** D-22/D-23/D-24 for `AuditChange`, `AuditTransaction`, `AuditAction`, `AuditContext`, `ActorRef`, `Page`, `NotFoundError`, the `Investigation` structs, `Health.Finding`, and the `Audit.transaction/3` result variable.
  - **234-06 (W3) — close:**
    - The D-26 flags, the D-27 flags assertion and the 22 fixes.
    - Delete the remaining pins and the ratchet machinery.
    - The CHANGELOG aggregate "Changed" line (D-49).
    - The D-01 ROADMAP/REQUIREMENTS note.
    - `MIX_ENV=dev mix docs --warnings-as-errors` and `mix ci.all`.

  Dependencies: 02–05 depend only on 01, and 06 depends on all.
  - Every plan ends with `mix verify.dialyzer` and `MIX_ENV=dev mix docs --warnings-as-errors`. `ci.all` does not run the docs build; only `verify.release` and the 237 publish do.
  - Every plan re-runs the tests that pin current doc or spec text: `lookup_return_shapes_contract_test.exs` (~:97), `deprecation_parity_test.exs` (~:170), `facade_naming_contract_test.exs`, `actor_reads_doc_contract_test.exs`, `public_surface_contract_test.exs`, telemetry doc, health findings doc, evidence show, gen_triggers.
- **D-48:** Executor dispatch halt clause, mandatory in every plan's dispatch prompt:
  - never edit gate or pin files except to delete entries the plan fixed;
  - never add `@doc false` outside D-07 without halting and reporting;
  - never touch `.dialyzer_ignore.exs` or add `@dialyzer`;
  - no `--no-verify` or `core.hooksPath`;
  - never run `npx` for `@opengsd`;
  - leave no background shells or poll loops;
  - never `git add .planning/` wholesale;
  - before committing planning prose, use the placeholder path forms and grep for the username.
- **D-49:** CHANGELOG policy for this phase:
  - **Breaking:** the D-08 hidden functions, the D-15 closed allowlists, and the WR-01 raise change (amending the existing 233 bullet).
  - **Changed:** one aggregate line: "options and results now have named types; Dialyzer users may see new warnings on calls Threadline already rejects at runtime".
  - Spec narrowing with no runtime change is not breaking and carries no footer.

### Seams with later phases
- **D-50:** **234 → 235 (CONTRACT-05):** 234 gives every schema field a precise type and makes no stability claim. 235 writes the "stable fields" moduledoc sections and the test pinning them against `__schema__(:fields)`. 235 may only add fields to `t`.
- **D-51:** **234 → 235 (CONTRACT-01):** the stability guide must state that 1.x guarantees option `@type` names and that option lists are additive. It must also state the spec-semver policy:
  - a spec change not backed by a runtime behaviour change is minor or patch, with a CHANGELOG note;
  - a narrowing that can create warnings for adopters who gate on Dialyzer also gets a note.

  The researcher flagged this as the one policy call with no clear winner. Ecosystem practice leans toward minor/patch; it is recorded here for 235 to write.
- **D-52:** **234 → 236:** 234 adds weight lines for its new test files. 236 regenerates the weights (CI-01) and owns the permanent missing-weight check.
- **D-53:** **234 → 237:** the upgrade guide takes the D-08 hidden functions and the D-15 closed allowlists as part of the facade-collapse step. The D-49 Dialyzer note goes in an unnumbered "Notes" item.
- **D-54 (2026-10-05 gap-closure scope amendment):** The maintainer approved one narrow exception to D-48's gate/pin edit prohibition. A Phase 234 gap-closure plan may edit only `test/threadline/doc_spec_coverage_contract_test.exs` to raise the existing checked-entry vacuity sentinel from `>= 82` to `>= 90` (and correct its matching failure message), satisfying the already locked D-11 floor and T-234-01. This permits no other gate or pin edit; every other D-48 restriction remains unchanged.
- **D-55 (2026-10-05 checked-entry floor amendment):** The maintainer sets the final D-11/D-54 checked-entry floor to `>= 82`, superseding only their earlier `>= 90` threshold. The checked-in source has 82 visible function/macro entries under D-03's existing universe and entry definition; D-07 deliberately hid exactly eight internal functions from the earlier 90-entry baseline. Keep the existing `>= 82` assertion and correct only its stale failure message from 88 to 82 in `test/threadline/doc_spec_coverage_contract_test.exs`. Do not add or expose public APIs, count typedocs as function/macro entries, or change the D-07 hidden pin. Pre-amendment references to the 90-entry D-11/D-54 floor in earlier plans and research are historical; execution and sign-off use this `>= 82` floor. D-11's 50-module and facade-timeline sentinels, the Docs-chunk check, and every other D-48 restriction remain unchanged.
- **D-56 (2026-10-05 finite string-key type exception):** The maintainer approves a narrow exception to D-25(a)/S-4 for the literal string-key portions of only `Threadline.Semantics.ActorRef.actor_map/0`, `Threadline.Evidence.Subject.subject_descriptor/0`, and `Threadline.Retention.Policy.config_map/0`. Elixir 1.17 typespecs cannot express literal binary map keys, while these runtime APIs intentionally accept extra string keys and, for subject/retention inputs, mixed atom/string forms. Preserve those behaviors; do not reject, normalize differently, or narrow accepted maps. Keep atom-key fields and their value domains as precise as the language permits. Each typedoc must state recognized/emitted keys, per-key values, unknown-key behavior, and mixed-key precedence where applicable. Add executable contract tests that pin the actual accepted behavior. No other type receives this exception. The existing D-2 correction for `Audit.transaction/3` remains in scope per Plan 234-09.

### Claude's Discretion
- Exact wording of the group descriptions beyond D-30, and of the doc prose.
- Whether the D-21 parity and D-44 doc checks share the D-02 file or a sibling `doc_rubric_contract_test.exs`, as long as everything is `async: true` and weighted.
- The internal shape of `__option_keys__/1`, or an equivalent way to expose allowlists.
- Whether the `Evidence` list-function arities collapse into defaults (D-47, 234-03).
- How each of the 22 Dialyzer findings is fixed: code versus spec, as long as nothing is ignored and the result stays honest.

- **D-57 (2026-10-06 StorageSchema role type documentation):** After the fresh Plan 13 review found that exported `Threadline.StorageSchema.role/0` has `@typedoc false`, the maintainer approves one narrow gap-closure plan to replace the suppressed typedoc with a concise description of its five identifier-validation role labels. Preserve the existing exported `@type` union and all runtime behavior; do not change D-55's `>= 82` checked-entry floor or D-07's hidden-function pin. Plan 13 must regenerate its review input and obtain a fresh independent D-46 verdict after this correction.

- **D-58 (2026-10-06 scoped example dependency-advisory disposition):** After Plan 234-15's required `mix ci.all` gate found EEF-CVE-2026-95105 in `cloak 1.1.4` and EEF-CVE-2026-94206 in `cloak_ecto 1.3.0`, the maintainer approves one narrow gap-closure plan for accountable, project-local Hex audit acknowledgements of these two findings only. Keep the dependency graph and lockfiles unchanged. This disposition is allowed only while the reference app configures AES-GCM as its sole Cloak cipher (with no CTR/deprecated-CTR decryptor or legacy CTR ciphertext to read) and uses `Cloak.Ecto.Binary` without `Cloak.Ecto.PBKDF2`; preserve source-level contract checks for those reachability conditions, both exact advisory IDs, matching reason/reachability/review-by metadata, and a future review date. The reviewed-by date is 2027-01-06. If CTR ciphertext or PBKDF2 use is found, or those reachability checks stop passing, keep the corresponding finding blocking and re-scope to a fixed dependency or safe migration instead of suppressing it. Plan 234-15 remains pending until the new plan summary exists and the required full `mix ci.all` passes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and scope
- `.planning/ROADMAP.md` — Phase 234 section (goal, SC1–SC4); phases 235–237 for seams
- `.planning/REQUIREMENTS.md` — SPEC-01, SPEC-02, SPEC-03; maintainer decisions (no NimbleOptions, bad options raise `ArgumentError`, deprecation policy); Out of Scope (no hand-maintained API reference)
- `.planning/PROJECT.md` — Constraints, incl. "Zero human verification by default"

### Prior phase decisions this phase must cohere with
- `.planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-CONTEXT.md` — D-01/D-02 escape-hatch naming (ExDoc can't link hidden modules), D-05 virtual `action` field must not reference `AuditAction.t()`
- `.planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-CONTEXT.md` — D-02 `history/3` spec exception, D-03 per-function allowlists, D-06 transparent cursors, D-09 `actor_history` deprecated options, D-10 `(filters, opts)` shapes, D-11 deprecated delegates keep `@doc` and specs
- `.planning/phases/233-lookup-return-shapes/233-CONTEXT.md` — D-05 lookup doc-contract pattern, D-08 lookup specs and no `no_return` on bangs, D-13 lookup option set
- `.planning/phases/233-lookup-return-shapes/233-REVIEW.md` — WR-01 (folded into 234-02)

### Project DNA, domain and voice
- `prompts/threadline-elixir-oss-dna.md` — doc-contract tests, honest default tests, named entrypoints, stable CI job ids
- `prompts/audit-lib-domain-model-reference.md` — domain nouns and layer boundaries used in docs and group descriptions
- `brandbook/brand-book.md` §Voice — newer brand source; preferred over `prompts/Threadline Brand Book.txt`
- `prompts/Threadline Brand Book.txt` §6–7 — docs voice: "sober, explanatory, practical"

### Code and tests touched
- `lib/threadline.ex` — the facade (types, groups, docs)
- `lib/threadline/query/transaction_lookup.ex:97-111` — WR-01 site; `:15` lookup allowlist
- `lib/threadline/investigation.ex:21` — `@row_history_opt_keys` (drop `:surface`)
- `lib/threadline/operator_surface/live/actor_live.ex`, `lib/threadline/operator_surface/controllers/export_controller.ex` — D-17 call sites
- `lib/threadline/page.ex` — `actor_cursor` typedoc fix
- `mix.exs` — `dialyzer:` flags (~L56-73), `{:ex_doc, "~> 0.34"}` (~L108), `docs()` (~L560-700)
- `.dialyzer_ignore.exs`, `test/threadline/dialyzer_ignore_contract_test.exs`, `test/threadline/dialyzer_slice_contract_test.exs`
- `test/threadline/source_size_contract_test.exs` — `@file_limit 800`, `@file_exceptions` (D-14)
- `test/threadline/facade_naming_contract_test.exs` — home of the D-33 group test
- `test/threadline/public_surface_contract_test.exs` — existing hidden-module pin, `:none` moduledoc check
- `test/partition_weights.txt`, `bin/ci-test-partitions` — weights for new test files
- `guides/code-walkthrough.md:462-477` — quotes `Storage` `@type options`
- `deps/ex_doc/lib/ex_doc/config.ex:7,116-124`, `deps/ex_doc/lib/ex_doc/retriever.ex:144-152,202,267,303`, `deps/ex_doc/lib/ex_doc/utils.ex:38-45` — grouping behaviour (D-29)
- `deps/ecto/lib/ecto/repo.ex:223` — `@moduledoc groups:` precedent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/threadline/source_size_contract_test.exs`: an exact-pin exception pattern, where a stale pin also fails. It is the model for the D-09 ratchet and the D-06 hidden pin.
- The 233 lookup-family doc contract (`@lookups` driven) and `actor_reads_doc_contract_test.exs`: `Code.fetch_docs`-based doc assertions to generalize from.
- `facade_naming_contract_test.exs`: already `async: true`. It asserts facade `since`/`deprecated` metadata and has a `paired_names` fixture-test style to reuse for D-33(e).
- `dialyzer_ignore_contract_test.exs`: already enforces a 0-entry ceiling, exact-tuple and comment rules, and fail-closed unused filters. Extend it; don't replace it.
- Per-function allowlists in `investigation.ex:21` and `transaction_lookup.ex:15`: the pattern for closing D-15.
- `Threadline.Query.Cursors`: transparent cursor maps whose types `Page` reuses.

### Established Patterns
- No NimbleOptions; hand-rolled allowlists that raise `ArgumentError` with the allowed keys.
- Deprecated names are one-line `@deprecated` delegates with their own `@doc`, an honest spec and a parity test.
- `Investigation` structs are visible "Data Types". `Query` and `Investigation` modules are `@moduledoc false`.
- `mix docs --warnings-as-errors` is the link checker (CI and `verify.release`).
- New test files require a `test/partition_weights.txt` line; the missing-weight check is permanent.

### Integration Points
- Adopters' Dialyzer PLTs consume our public types (D-18 reversibility, D-28 no `@opaque`).
- The CI `verify-dialyzer` job's PLT cache key includes `hashFiles('mix.exs')`.
- The example app (`examples/threadline_phoenix`) calls `Evidence.record_*`, `Job.*` and `StorageSchema.repo_opts`/`threadline_table?`. It must compile clean with `--warnings-as-errors`.

</code_context>

<specifics>
## Specific Ideas

### Example facade types (sketch from research; the planner refines keys against the real allowlists)
```elixir
@typedoc "An `Ecto.Repo` module."
@type repo_opt :: {:repo, module()}
@typedoc "Threadline storage-schema override (default `\"threadline\"`)."
@type storage_schema_opt :: {:storage_schema, String.t()}
@typedoc "Tenant scoping. `:scope` is opaque to Threadline (R1); it is handed to `:scope_query_fn`."
@type scope_opt :: {:scope, term()} | {:scope_query_fn, scope_query_fn()}

@typedoc "A captured row's key: a scalar for a single-column key, or every key field as a map or keyword list."
@type row_id :: row_key_scalar() | %{optional(atom() | String.t()) => row_key_scalar()} | [{atom() | String.t(), row_key_scalar()}]

@type row_history_opt ::
        repo_opt() | storage_schema_opt() | scope_opt()
        | {:from, DateTime.t()} | {:to, DateTime.t()}
        | {:limit, pos_integer() | :infinity}
        | {:cursor, :start | Threadline.Page.change_cursor()}
        | {:page_size, pos_integer()}
@spec row_history(module(), row_id(), [row_history_opt()]) ::
        [Threadline.Investigation.LinkedChange.t()] | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())

@typedoc "Options accepted by `audit_transaction/2`, `transaction_context/2`, `incident_bundle/2` and their `!` siblings."
@type lookup_opt :: repo_opt() | storage_schema_opt() | scope_opt()

# Threadline.Export
@type export_result :: %{data: iodata(), truncated: boolean(), returned_count: non_neg_integer(), max_rows: pos_integer()}

# Threadline.Audit
@spec transaction(module(), [transaction_opt()], (-> result)) :: {:ok, result | map()} | {:error, term()} when result: term()

# Threadline.Semantics.ActorRef
@type actor_type :: :user | :admin | :service_account | :job | :system | :anonymous
@type t :: %__MODULE__{type: actor_type(), id: String.t() | nil}
```

### Full doc template (D-36)
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
are generated, not on read. Authorize reads with `:scope_query_fn`.   (D-38 functions only)
"""
```

### Floor template (D-36)
```elixir
@doc "Returns `name` double-quoted for SQL after validating it; raises `ArgumentError` if it is not a PostgreSQL identifier."
```

### Doc failures already seen (rubric examples)
- `Evidence.record_retention_run/3`: "Records retention-run evidence." fails D-2: it gives no return value and no subject.
- `export_csv/2` and `export_json/2` don't cross-link (D-4), and neither names its errors (D-6).
- `actor_window/3` has no `## Options` (D-5).
- `timeline/2` mixes filters and opts in one list (D-5).
- `as_of/4` points at deprecated `history/3` (D-7).
- `Evidence.Proof`'s moduledoc is jargon and names no entry point (M-1).

</specifics>

<deferred>
## Deferred Ideas

- `@moduledoc groups:` for `Threadline.Evidence` (13 functions) and `Threadline.StorageSchema`. Cheap later with the Ecto pattern; SPEC-03 covers the facade only.
- A full visible-surface snapshot that catches removed functions belongs to 235's stability contract.
- A doc-substance floor in the gate was measured as vacuous today: no first line is under 30 characters. Substance stays with the D-45 agent rubric.
- NimbleOptions-generated `## Options` as a single source of truth stays excluded by REQUIREMENTS. A possible 1.x revisit; D-21 parity covers drift now.
- `as_of!/4` is still additive in 1.x (233 D-03).

</deferred>

---

*Phase: 234-typespec-and-doc-completion-gate*
*Context gathered: 2026-10-04*
