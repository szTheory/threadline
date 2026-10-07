# Pitfalls Research — v1.45 "1.0 API Contract"

**Domain:** declaring 1.0.0 of a pre-adoption Elixir/Ecto/Phoenix audit library (Hex package `threadline`)
**Researched:** 2026-10-02
**Confidence:** HIGH on Elixir/Hex ecosystem conventions and on this repo's own code/config (cited file:line); MEDIUM on cross-ecosystem (Rails/Django/Envers/PaperTrail/Logidze) specifics, which are recalled from general knowledge and not re-verified against primary sources this pass — treat those as directional, not quoted fact.

## ONE-WAY Decision 1: Deprecate-vs-Remove at 1.0

**Recommendation: (a) with a twist — deprecate now, in 1.45 itself, ship 1.0.0 with the deprecated aliases still present and warning, remove them in a later 1.x (not 2.0, not a prior 0.13).**

This is not quite options (a), (b), or (c) as posed — it's an amended (a): don't ship a separate 0.13 deprecation release first (there's no adopter base to protect from the duplicate-surface pain of a two-step rollout, and splitting it costs a whole extra milestone), but don't keep deprecated aliases for the *entire* 1.x line either (that guarantees `row_history/4`, `actor_window/3` etc. live forever as zombie code nobody can safely delete, since 1.0 forecloses removing them without a major bump).

Reasoning, by source:

- **Elixir core's own policy** (hexdocs.pm/elixir/compatibility-and-deprecations): soft-deprecate (no warning) → hard-deprecate (`@deprecated`, warning text names the replacement) for **at least 3 minor versions** → remove only at a **major**. Applied here: hard-deprecate the overlapping entry points (`row_history/4`, `row_history_page/4`, `actor_window/3`, and whichever of `history`/`actor_history` loses) in 1.0.0 itself. That satisfies "at least 3 minors" trivially once 1.1/1.2/1.3 ship, and removal becomes a clean, pre-announced 2.0 decision later — not an open-ended promise.
- **Phoenix/Ecto/Oban/LiveView precedent**: every one of these libraries hard-deprecates inside its stable major (`Ecto.Multi.run/3` arities, `Phoenix.View`, `Ecto.Adapters.SQL.query/4` variants) and only drops the deprecated shim at the next major (Ecto 2→3, Phoenix 1.6→1.7 LiveView changes bundled with a major bump of LiveView itself, Oban kept `Oban.Worker` shims across its 2.x line and dropped only at the 2.0→... boundary when the behaviour changed). None of them remove a deprecated public function **inside** a stable major. That rules out (c) (remove now, in 1.0.0, with no deprecation period) — it breaks the promise 1.0.0 is supposed to make on day one.
- **Hex semver convention**: Hex's own ecosystem norm (elixir `Version`, the `~>` operator) treats 1.0.0→2.0.0 as the only sanctioned place to drop public functions. Removing in a 1.x minor/patch is a semver violation adopters will notice via Dialyzer/compile warnings turning into undefined-function errors.
- **Adopter base signal** (PROJECT.md: "Hold — v1.28 External Pilot only on sustained real-adopter signal", no external pilot shipped; package is pre-adoption/pilot-stage): this is the argument *against* (b) "keep aliases through all of 1.x." With effectively zero production adopters today, there is no large installed base whose upgrade pain justifies carrying duplicate entry points for the library's entire stable lifetime. A small, deliberate deprecation window (hard-deprecate at 1.0.0, remove at a *later*, explicitly-announced major) costs little now and avoids permanent API surface debt. Conversely, this same low-adopter-count is exactly why (c) "remove now with an upgrade guide" is tempting — but 1.0.0 is a *promise* to future adopters, not just a cleanup of current ones; shipping it with functions that silently disappear undermines the promise before it's made.

**Verdict:** hard-deprecate the losing entry points in 1.0.0 (not a prior 0.13 — no adopters to protect from a two-release rollout), keep them functioning and `@deprecated`-annotated for the 1.x line, and record the removal target as a 2.0 decision to make later with real usage data. Do not promise "all of 1.x" explicitly in the docs — promise "at least until 2.0, which is not currently planned."

---

## Critical Pitfalls

### Pitfall 1: `@deprecated` warnings break adopters' `--warnings-as-errors` builds

**What goes wrong:** Threadline's own CI runs `mix compile --warnings-as-errors` (CLAUDE.md). Many serious adopters copy that convention. The moment a deprecated function is called anywhere in dependency-resolved code (including Threadline's own internals, if `history/3` calls into a soon-to-be-deprecated helper, or if the example app still calls the old name), a `--warnings-as-errors` build goes red for every adopter on the old call site, with zero action from them.

**Why it happens:** `@deprecated` is a compiler-level warning in Elixir, indistinguishable in severity from any other compile warning, so it's naturally caught by the same flag that's supposed to raise the bar on code quality. Maintainers test their own code warningless and assume adopters are also warningless, but the deprecation is often introduced *and* left uncalled internally while adopter code elsewhere still calls the old name.

**How to avoid:**
- Grep the full `lib/`, `test/`, example app, and every guide for every soon-to-be-deprecated call site before merging the deprecation; update all internal callers to the new name in the same phase.
- The `@deprecated` message text must name the exact replacement function and arity, not just "use the new API" — this is what lets adopters silence warnings with a one-line sed instead of reading a guide.
- Add a CHANGELOG "Deprecated" subsection (not just "Breaking") distinct from the breaking-changes block, so adopters scanning for breakage know this won't fail their *next* upgrade, only a future major.

**Warning signs:** `mix compile --warnings-as-errors` only tested inside the Threadline repo itself (which has update all its own call sites) rather than from a fresh adopter app depending on the new version; example app or any guide code block still calling the deprecated name.

**Phase to address:** the consolidation phase that introduces the deprecations (verify via a doc-contract/compile check that scans `lib/`, `test/`, example app, and `guides/` for the deprecated names after the deprecation lands).

---

### Pitfall 2: Deprecated delegates drift in behavior from the function they forward to

**What goes wrong:** A deprecated function kept as a thin delegate (e.g., `row_history/4` calling into whatever `history/3` becomes) silently stops matching its own documented contract once the target function's defaults or return shape change underneath it — because nobody re-reads the deprecated function's moduledoc/spec when editing the thing it delegates to.

**Why it happens:** Deprecated code gets a pass on "revisit this" scrutiny — it's marked as going away, so changes to the surviving function don't trigger review of the alias. This is a widely observed failure mode in long-lived libraries (Rails has many) and in PaperTrail's history, where deprecated reader methods silently returned stale shapes after the main association changed.

**How to avoid:** Make every deprecated function a *pure one-line delegate* (`defdelegate` or a single-expression `def` that calls the replacement with translated args) with no independent logic, so there is no behavior to drift — the delegate inherits the target's current contract by construction. Add one test per deprecated function asserting it returns byte-identical output to the replacement for the same logical inputs, so any future edit to the target that changes shape fails the delegate's test too.

**Warning signs:** a deprecated function with its own `case`/`cond`/post-processing logic rather than a single forwarding call; a deprecated function's test suite that pins fixtures captured before the replacement last changed shape.

**Phase to address:** the consolidation phase (implementation review checklist item: "is every deprecated path a pure delegate with a parity test?").

---

### Pitfall 3: `@spec` on deprecated functions is skipped, inherited stale, or lies

**What goes wrong:** Either (a) the deprecated function gets no `@spec` at all because "it's going away," defeating the public-surface @spec-coverage gate this milestone is building, or (b) it keeps a stale spec from before the replacement changed shape, so Dialyzer silently stops being useful on the one code path adopters are actively being pushed off of (which is exactly when they need the most accurate type signal, mid-migration).

**Why it happens:** Specs on deprecated code feel like wasted effort to the person writing the deprecation. But the coverage gate this milestone adds (PROJECT.md: "complete @spec/@doc on the public surface... add a gate so coverage can't regress") doesn't know "deprecated" means "exempt" unless that's designed in explicitly — so either the gate is accidentally satisfied by a lying spec, or the deprecated function becomes an unintended carve-out that quietly erodes the 100%-coverage story.

**How to avoid:** Decide explicitly, in the gate's design, whether deprecated public functions count toward spec coverage (recommendation: yes — a function is public until it's removed, and adopters mid-migration deserve the same Dialyzer help). Write the deprecated function's spec to exactly match the replacement's spec (modulo the old arg shape being translated), not a hand-wavy `term()` escape hatch.

**Warning signs:** a deprecated function typed `term() -> term()` or with no `@spec`; the coverage gate's exemption list (if one exists) growing to include every deprecated name "temporarily."

**Phase to address:** the @spec/@doc completion phase, done in the same phase as (or immediately after) the consolidation/deprecation phase so the gate's rules are decided once, not retrofitted.

---

### Pitfall 4: Docs search and guides keep surfacing the old names

**What goes wrong:** HexDocs full-text search, ExDoc's sidebar, and the guides themselves (`guides/*.md`) keep presenting `row_history/4` as a normal, first-class way to do the job, because deprecating a function in code doesn't remove it from prose written before the deprecation. New adopters land on the deprecated name via search before ever seeing the recommended one.

**Why it happens:** `@deprecated` only affects the function's own doc page (ExDoc greys it out / adds a deprecation notice) and compiler warnings. It does nothing to guide prose, README snippets, or any narrative doc that references the old call by name. This repo already has 19 doc-contract tests (`test/threadline/*_doc_contract_test.exs`) proving specific guides don't drift, which is exactly the right mechanism — but it only catches what it's told to look for.

**How to avoid:** Grep every file under `guides/`, `README.md`, and the example app for every soon-to-be-deprecated function name as part of the deprecation phase, and either remove the reference or explicitly caption it "deprecated, prefer X." Add (or extend) a doc-contract test asserting the deprecated names appear in guides *only* inside an explicit "migrating from older names" section, never as the primary recommended call.

**Warning signs:** `grep -rn "row_history\|actor_window" guides/ README.md` returning hits outside a migration-focused guide; the moduledoc of a deprecated function not linking to the replacement.

**Phase to address:** consolidation/deprecation phase, verified by extending the existing doc-contract test pattern (`test/threadline/*_doc_contract_test.exs` already in the repo — this is a proven, cheap mechanism to reuse, not invent).

---

### Pitfall 5: Specs that lie — too broad (`term()`) or too narrow (Dialyzer-clean but useless)

**What goes wrong:** Chasing "129 of 169 public functions have no `@spec`" to zero creates pressure to write *something* fast. The two failure shapes: (a) `@spec foo(term()) :: term()` — technically present, satisfies a naive coverage gate, tells an adopter and Dialyzer nothing; (b) a spec narrower than reality (e.g. typing an options keyword list as a closed set of exactly the keys used in today's one call site) that passes Dialyzer today but means Dialyzer will flag a *future*, perfectly valid caller as a type error, training the team to ignore Dialyzer warnings on this module.

**Why it happens:** Writing a precise spec for Ecto-heavy code (schemas, changesets, queries, `Ecto.Query.t()`) is genuinely harder than writing a vague one, and a line-count-driven gate rewards the vague one equally.

**How to avoid:** Review specs for *informativeness*, not just presence — a lightweight rubric: does the spec name the actual union of valid shapes (e.g. `ActorRef.t() | nil`, not `term()`), does it use `Keyword.t()` + a `@type opts :: [...]` for option lists rather than a bare `keyword()`, does it reuse named `@type`s (e.g. `Threadline.Capture.AuditChange.t()`) instead of re-deriving `Ecto.Schema.t()`. Add this as an explicit agent-review checklist item (zero-human-verification per CLAUDE.md) rather than trusting a mechanical "has @spec" count.

**Warning signs:** `@spec` grep showing many `term()` or `any()` return/arg types; Dialyzer passing 100% while spot-checking 5 random specs by hand finds one that's clearly wrong.

**Phase to address:** the @spec/@doc completion phase; gate design must include a "no bare `term()`/`any()` on a function with >0 real argument types" rule, not just presence-or-absence.

---

### Pitfall 6: Specs on delegates silently duplicate (and can drift from) the target's spec

**What goes wrong:** A deprecated delegate (Pitfall 2) gets its own hand-written `@spec` that's a slightly different shape than the function it forwards to — e.g. the delegate's spec allows `atom()` for a table name where the target's spec was tightened to `String.t()`. Dialyzer won't catch this because both specs are individually self-consistent; it only shows up as adopter confusion.

**How to avoid:** Where Elixir's `defdelegate` is used, prefer *not* writing a separate `@spec` on the delegate at all (the delegate inherits no spec automatically, so document this as "see `Target.fun/2`" in the moduledoc instead of hand-duplicating the type); where a thin wrapper function (not `defdelegate`) is required because the arg shape differs, derive its spec mechanically from the target's spec rather than writing a parallel one by hand.

**Warning signs:** two specs for logically-the-same operation that use different type names for the same argument.

**Phase to address:** same phase as Pitfall 2/3 (consolidation + spec completion are tightly coupled — do them together or in strict sequence within one phase).

---

### Pitfall 7: Exposing Ecto schema structs makes every field public API (ONE-WAY)

**What goes wrong:** `Threadline.Capture.AuditChange`, `Threadline.Capture.AuditTransaction`, and `Threadline.Semantics.AuditAction` are plain `Ecto.Schema` structs returned directly from the public API (`history/3` and friends return lists of these structs — confirmed at `lib/threadline/capture/audit_change.ex:1-40`, which documents `:table_schema`, `:table_name`, `:table_pk`, `:op`, `:data_after`, `:changed_fields`, `:changed_from`, `:captured_at`, and the `belongs_to :transaction` association). Returning the raw struct means **every field name, every association, and the presence/absence of `__meta__` is now public API** the moment 1.0.0 ships — adopters will pattern-match `%AuditChange{table_pk: pk}` in their own code, and Dialyzer-driven refactors that rename or restructure a field become a breaking change even if the *function* signature (`history/3 :: [AuditChange.t()]`) looks unchanged.

**Why it happens:** It's the path of least resistance — Ecto gives you the struct for free, and wrapping it in an opaque type or a plain map means writing and maintaining a translation layer. Teams defer that decision, then discover at 1.0 that the struct's internal shape (including Ecto-internal fields like `__meta__`, `__struct__`, and any future association preload) is now frozen.

**How to avoid:** This is the single highest-leverage ONE-WAY call in this milestone, on the level of the deprecation decision. Two real options, pick one explicitly and document the choice in the guide:
  1. **Keep exposing the Ecto struct, but declare in docs exactly which fields are the stable contract** (name them individually: `table_schema`, `table_name`, `table_pk`, `op`, `data_after`, `changed_fields`, `changed_from`, `captured_at`, `inserted_at`/`id`/`transaction_id` as applicable) and explicitly disclaim `__meta__`/preload behavior as not part of the contract. This is cheapest and matches how Ecto itself documents `Ecto.Changeset` fields — accept the struct is the type, but scope the *promise* narrower than the *shape*.
  2. **Introduce an opaque result struct per read path** (e.g. `Threadline.ChangeRecord.t()`, built via `@opaque`) that the schema struct is mapped into before returning. This is the textbook "don't leak your persistence layer" answer, used by Ash and Broadway for their public result types, but it's a larger, genuinely one-way redesign of every read-path return type — too big for a 1-2 week, 4-6 phase milestone whose scope is explicitly "consolidate, don't rewrite" (see Pitfall 13).
  **Recommendation: option 1.** Document the stable field subset of `AuditChange`/`AuditTransaction`/`AuditAction` explicitly in the supported-table-shapes guide and in each schema's moduledoc, with an explicit "these fields are not part of the 1.0 contract" callout for `__meta__` and any association preload state. This matches the milestone's own stated scope (spec/doc/consolidate, not rearchitect) and gives adopters the clarity they need without a rewrite.

**Warning signs:** a struct field documented only in a `@moduledoc` paragraph of prose rather than in a scannable field list; any association (`belongs_to :transaction`) left ambiguous about whether it's preloaded by default (changing preload defaults after 1.0 is itself a breaking behavior change even though the struct's *type* doesn't change).

**Phase to address:** the @spec/@doc + supported-table-shapes guide phase. This should be decided before — or in the same phase as — the `@spec` work on the three schemas, since the spec for `history/3`'s return type depends on the answer.

---

### Pitfall 8: `@moduledoc false` on a module adopters (or guides) already reference is a silent breaking change

**What goes wrong:** "Hide internal helpers" (an explicit v1.45 target feature) is good practice, but if any module getting `@moduledoc false` is already named in a guide, in the example app, or — worse — already called directly by an adopter who skipped the facade (common when the facade doesn't yet cover their use case), hiding it from docs doesn't remove the module, but `@moduledoc false` plus removing it from the public surface contract test's expectations is frequently *paired* with actually un-exporting/renaming functions, which does break callers with no deprecation warning at all (there's no `@deprecated`-style compiler nudge for "this module is no longer documented").

**Why it happens:** `@moduledoc false` feels purely cosmetic ("just hides it from ExDoc"), so it doesn't get the same breaking-change scrutiny as removing a function. But this repo's own `test/threadline/public_surface_contract_test.exs` treats module visibility as a tracked, intentional surface (it already has a `@renamed_modules` map and `@hidden_modules` list for exactly this reason) — meaning the project has already been burned by, or anticipated, this exact class of change.

**How to avoid:** Before hiding any module, grep `guides/`, `README.md`, the example app, and (if any exist) adopter-facing CHANGELOG entries for its name. If it's referenced anywhere adopter-facing, either keep it documented (even if de-emphasized) or treat the hide as a breaking change requiring a CHANGELOG entry and, ideally, a compile-time nudge (e.g., if it's a function being removed from the public call path, deprecate the function first per the ONE-WAY decision above — don't just stop documenting it while leaving it technically callable, which is the worst of both worlds: still-breakable, no warning).
Extend `@hidden_modules` / `public_surface_contract_test.exs`'s existing rename-tracking pattern to cover this milestone's hides explicitly, the same way it already tracks `Threadline.OperatorSurface.Exports.FilterParams => Threadline.Query.FilterParams`.

**Warning signs:** a module about to get `@moduledoc false` turning up in `grep -rln "ModuleName" guides/ README.md example_app/ 2>/dev/null`; a hide that isn't paired with an entry in the CHANGELOG or the `public_surface_contract_test.exs` tracking maps.

**Phase to address:** the "hide internal helpers" work item, done as part of the @spec/@doc completion phase, gated by extending the existing `public_surface_contract_test.exs` mechanism (don't invent a new one).

---

### Pitfall 9: Bounded default limit — silent truncation is a compliance/correctness risk, not just a UX nicety

**What goes wrong:** `history/3`'s `:limit` defaulted to `nil` (unbounded) in v1.44; this milestone's deferred decision is to give it a bounded default. For an *audit* library, a silently-truncated result set is categorically worse than for an ordinary pagination API: an operator or compliance reviewer who calls `history(txn, table, pk)` expecting "the complete trail" and gets the newest N rows with no visible signal has just been handed a false sense of completeness — exactly the failure mode an audit trail exists to prevent. This is compounded if `export` (a separate code path) doesn't share the same default/behavior, so "what I saw in `history/3`" and "what came out in the export" silently disagree.

**Why it happens:** Bounding a default is motivated by operational safety (an unbounded query against a busy production table is a real DoS/latency risk), which is a legitimate concern — but the fix is usually applied as a plain function-default change, the same pattern used for any ordinary API, without the audit-specific requirement that truncation be *observable*, not silent.

**How to avoid:**
- Whatever bound is chosen, the result must carry a machine-checkable signal that more rows exist (e.g. return a struct/tuple with `truncated?: boolean()` or reuse the existing cursor-paging contract so "there's a next page" is structurally visible, not an easy-to-miss `length(result) == limit` inference adopters have to do themselves).
- `export` and `history`/`row_history` must use *the same* bounding semantics or an explicit, documented divergence (e.g., "export is deliberately unbounded, history defaults bounded for interactive use — use export for a complete record"). A mismatch here is the single most compliance-relevant inconsistency this milestone could ship.
- Property tests (already a strength of this codebase per v1.44 — cursor paging, export round-trip, retention cutoff) must be updated for this: any property test that currently asserts "pages joined == full list" or treats `history/3` as unbounded needs to either explicitly test the new bounded contract or be pointed at an unbounded path (e.g. cursor paging) so the property's meaning doesn't silently change.

**Warning signs:** a bounded default shipped as a bare integer default with no accompanying truncation signal in the return shape; `grep` showing `history/3`'s default and `export`'s default diverge with no doc explaining why; an existing property test (e.g. `cursor paging (pages joined == full list)` from v1.44) that would pass against a silently-truncated single-call `history/3` without anyone changing its assertions.

**Phase to address:** the consolidation phase (this is explicitly the deferred v1.44 item), with its own property-test update as an in-phase success criterion, not deferred again.

---

### Pitfall 10: Raising the Elixir/PG support floor — minor-release footgun and CI matrix gaps

**What goes wrong:** Two distinct mistakes: (a) bumping `mix.exs`'s `elixir: "~> 1.15"` or dropping PG 14 support in a way that reads as a minor/patch rather than being clearly flagged, which silently breaks adopters still on the old floor with no major-version signal; (b) raising the floor and leaving the CI matrix (the "current" and "latest" lanes referenced in v1.43/v1.44 work) untested against the *old* floor, so the project no longer has evidence the stated minimum actually works — the floor becomes aspirational prose, not a tested guarantee.

**Why it happens:** PG 14 EOL on 2026-11-12 (confirmed in PROJECT.md) creates real pressure to bump the floor during this exact milestone window, and "bump a version requirement in mix.exs" looks like a one-line change that doesn't obviously require a semver-major conversation — but a support-floor raise is a breaking change for anyone still on the old floor, by Hex/Elixir convention (raising a dependency's minimum Elixir/OTP requirement is listed as a reason for a major bump in Elixir's own library guidelines).

**How to avoid:** Treat the floor decision explicitly as part of the 1.0.0 contract being set, not a routine bump: document the new floor in the CHANGELOG's breaking-changes section (this repo already has a convention of listing breaking changes first, per the CHANGELOG preamble), and make sure the CI matrix has a lane proving the *new* stated floor (not just "latest") so "Elixir ~> 1.16, PG 15+" (or whatever is chosen) is a tested fact, not a mix.exs string nobody runs CI against. Check whether any trigger SQL (the hand-written PL/pgSQL in `gen.triggers`) uses a PG-version-specific feature (e.g. `MERGE`, certain JSON functions) that would make the real floor higher than the stated one regardless of what mix.exs says.

**Warning signs:** `mix.exs`'s `elixir:` constraint and the oldest CI lane's Elixir/OTP/PG version disagreeing; any SQL in trigger-generation code using a function only available from a specific PG major without a documented minimum.

**Phase to address:** the support-floor phase (likely combined with CI matrix review), scheduled so the CI matrix change lands in the *same* phase as the mix.exs bump — not split across phases where one could ship without the other being verified.

---

### Pitfall 11: release-please produces 0.13.0 instead of 1.0.0 (confirmed live risk in this repo)

**What goes wrong:** `release-please-config.json:4` currently sets `"bump-minor-pre-major": true` — this is the release-please flag that, while a package is pre-1.0, caps every bump at minor instead of major (so a `feat!`/`BREAKING CHANGE` commit bumps 0.12.0 → 0.13.0, not 1.0.0). **If this flag is left in place, committing the 1.0.0-worthy breaking changes in this milestone will not produce a 1.0.0 release-please PR — it will produce 0.13.0**, and the maintainer will discover this only when the release PR opens with the wrong version.

**Why it happens:** `bump-minor-pre-major` is a correct, intentional setting for a library that hasn't reached 1.0 yet (it's why 0.10→0.11→0.12 worked correctly across the last three milestones) — but it has to be *manually removed* for the release that crosses the 1.0 threshold. release-please does not know "this is the 1.0 release" on its own; it only knows commit types and this flag.

**How to avoid:** Remove (or set `false`) `bump-minor-pre-major` in `release-please-config.json` as an explicit, reviewed step in the release phase — before the first `feat!`/breaking commit of this milestone lands, not after. Verify with a dry-run (release-please supports a manifest/PR preview) that the next release PR title reads `1.0.0`, not `0.13.0`, before merging the release PR. This should be a named, tested step (e.g. a one-line assertion or a documented manual-verify checklist item) rather than trusted to "someone will notice."

**Warning signs:** the release-please PR title or `CHANGELOG-GENERATED.md`/manifest showing `0.13.0`; `bump-minor-pre-major: true` still present in `release-please-config.json` after the milestone's breaking commits have landed.

**Phase to address:** the final "declare 1.0.0" phase, as an explicit, verifiable gate step before merging the release PR.

---

### Pitfall 12: BREAKING footers collapsing in generated changelogs (already happened once, in 0.12.0)

**What goes wrong:** This repo's own 0.12.0 release already had a known issue (per the research-plan's question framing) with BREAKING-change commit footers collapsing/not rendering distinctly in the generated output. For a 1.0.0 release specifically — the one release where adopters most need an accurate, complete list of what changed and what breaks — a repeat of this defect would undermine exactly the trust 1.0.0 exists to establish. CLAUDE.md's own convention separates `CHANGELOG.md` (human-owned, ships to adopters) from `CHANGELOG-GENERATED.md` (bot-owned, not shipped) precisely because of this class of risk — but the human-owned file still has to be manually assembled correctly for 1.0.0, and the failure mode is a human missing a breaking change when hand-writing the curated entry, not just a bot rendering bug.

**How to avoid:** For the 1.0.0 entry specifically, cross-check the hand-written `CHANGELOG.md` breaking-changes section against every `feat!`/`fix!`/`BREAKING CHANGE:` commit footer merged during the milestone (a simple `git log` grep against the milestone's commit range), not just against memory of what was planned. Given CLAUDE.md's "doc contract tests" convention, consider a one-off test (or a manual checklist item, since this is a single release-day event) asserting every deprecated/removed public name mentioned in this milestone's phase SUMMARYs also appears in the `CHANGELOG.md` 1.0.0 entry's breaking-changes list.

**Warning signs:** a `git log --grep="BREAKING CHANGE" <milestone-range>` turning up a commit not represented in the hand-written CHANGELOG entry; the 1.0.0 CHANGELOG entry's breaking-changes section being shorter than the number of deprecated/removed functions this milestone actually touches.

**Phase to address:** the final "declare 1.0.0" phase, same gate as Pitfall 11.

---

### Pitfall 13: "1.0 means done" scope creep — parked UI, polish without evidence, rewriting stable internals

**What goes wrong:** Three distinct creep vectors, all plausible given this milestone's prestige ("the last rung before 1.0"): (a) pulling operator/admin UI work back in because "1.0 should look finished" — explicitly parked per PROJECT.md and MILESTONE-GUIDE.txt until after 1.0.0; (b) general polish (renaming things for taste, restructuring modules "while we're in there") that isn't load-bearing for the spec/consolidation/floor/docs scope and has no measured problem driving it; (c) rewriting genuinely stable internals (e.g. the trigger-generation SQL, the capture pipeline) under the banner of "1.0 quality" when nothing in the milestone's actual target features requires touching them — this risks reintroducing defects in code that's been hardened across v1.42-v1.44's property tests and adopter twins.

**Why it happens:** "Declaring 1.0" carries psychological weight disproportionate to the actual scope (spec completion, consolidation, docs, floor) — it invites "shouldn't everything be perfect for 1.0?" thinking that the project's own stated posture (PROJECT.md: "operator/admin UI design is PARKED... New product scope... is out") explicitly forecloses.

**How to avoid (keeping to ~4-6 phases, 1-2 weeks):**
- Each phase's SUMMARY/SPEC should trace directly to one of the six explicit target-feature bullets in PROJECT.md (spec/doc completion, consolidation+deprecation, consistent return shapes, table-shapes+threat-model guides, the AuditTransaction↔AuditAction edge decision, support floor) or the release mechanics (1.0.0 declaration). Anything that doesn't trace to one of these is out of scope for this milestone by construction.
- Treat "the operator UI is parked" and "no new product scope" as a standing halt condition for every phase's planning, the same way CLAUDE.md already treats secrets/spend/push/scope as maintainer-only — if a plan references `/audit` UI routes or LiveView templates for reasons other than "an API change forced a call-site update" (the one explicit exception in PROJECT.md), stop and flag it rather than execute it.
- Don't let "hide internal helpers" or "consistent return shapes" become a pretext for a broader internal refactor — the scope is the *public* surface; internals that already work and aren't part of the public contract don't need touching just because someone's looking at the file anyway.

**Warning signs:** a phase plan touching `lib/threadline_web` or operator-surface LiveView files without an API-change justification; a phase whose SUMMARY describes a rename/restructure with no adopter-facing or spec-coverage rationale; phase count creeping past 6 or duration estimates exceeding 2 weeks without a corresponding scope addition being explicitly re-ratified against PROJECT.md's constraints.

**Phase to address:** this is a cross-phase discipline, not a single phase — enforce it at phase-planning time (gsd-discuss-phase / gsd-plan-phase) for every phase in this milestone, and re-check at milestone-audit time against the six target-feature bullets.

---

### Pitfall 14: Threat-model and table-shapes docs overclaim guarantees, and drift from tests

**What goes wrong:** Two linked risks in the new "supported-table-shapes guide" and "redaction threat model" deliverables: (a) overclaiming — language like "redaction prevents all plaintext exposure" or "every table shape is supported" is the kind of absolute a security/compliance reviewer (one of this project's own named lenses) will immediately treat as a liability, because it's essentially never literally true (redaction, by this project's own v1.44 property-test findings, had a "silent redaction misconfiguration" bug caught by a test — meaning the honest claim is "redaction is correct *when configured and verified via `health.coverage`*," not "redaction prevents all plaintext"); (b) drift — the docs describe behavior at the moment they're written, with no mechanism tying their claims to the actual property tests/health checks that back them, so a future change to redaction or trigger behavior can falsify the guide silently (exactly the failure this repo's 19 existing doc-contract tests exist to prevent for *other* guides).

**Why it happens:** Threat-model docs are typically written in prose by someone reasoning about the system, not generated from or checked against the property tests that actually prove the claims — so there's a structural gap between "what we tested" (property tests for redaction-never-leaks, retention cutoff, etc. — already built in v1.44) and "what we promise in prose" (a new document with no automated link to those tests).

**How to avoid:**
- Scope every guarantee claim in both new guides to a specific, named verification mechanism: "redaction policy X is enforced and proven by the redaction-never-leaks property test (`test/...`) and surfaced by `mix threadline.health.coverage`" rather than an unscoped "redaction prevents...". Name the limits explicitly (e.g., what happens if an adopter sets up a table without running `health.coverage --strict`; what a replication slot, logical decoding consumer, or a superuser bypassing triggers can still see).
- Add one doc-contract test per new guide, matching this repo's own established pattern (`test/threadline/*_doc_contract_test.exs`, 19 of which already exist) — at minimum, assert the guide's code examples/table names/option names match real schema/option names (compile-checked or string-checked against `mix.exs`/schema modules), and assert any claim like "supports composite keys" has a corresponding test name referenced or at least a corresponding property test file existing in the suite.
- Have the security/compliance reviewer lens (named in PROJECT.md's lens list) read the threat-model guide specifically hunting for unscoped absolutes, as part of the phase's verification rather than general code review.

**Warning signs:** the words "all", "never", "guarantees", "prevents" in the new guides without an adjacent "when X is true" / "except Y" qualifier; a new guide with no corresponding `*_doc_contract_test.exs` file, breaking this repo's own established pattern for every other guide.

**Phase to address:** the supported-table-shapes + redaction threat-model phase, with the doc-contract test as an explicit in-phase deliverable (not a follow-up), matching the existing 19-file pattern already proven in this repo.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|--------------------|-----------------|------------------|
| Ship 1.0.0 with deprecated aliases but no removal-target version named | Avoids a hard promise under time pressure | Deprecated code lives forever by default, nobody owns killing it | Never for this milestone — name "removal no earlier than 2.0, not currently planned" explicitly |
| Write `@spec` as `term()` to hit a coverage percentage | Fast, unblocks the gate | Dialyzer and adopters get no real signal; false sense of "done" | Never — treat as equivalent to no spec in review |
| Leave the bounded `history/3` default unsigned (no truncation flag) | Simpler return shape, no struct change | Silent incompleteness in an audit trail — the worst possible failure mode for this domain | Never |
| Defer the `bump-minor-pre-major` flag flip to "whenever we remember" | One less thing to think about now | Live risk of shipping 0.13.0 instead of 1.0.0, discovered only at release-PR time | Never — do it before the first `feat!` commit lands |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|------------------|-------------------|
| release-please | Leaving `bump-minor-pre-major: true` through the 1.0 release | Flip to `false`/remove before the milestone's breaking commits land; dry-run the version bump |
| HexDocs (multi-version) | Publishing 1.0.0 docs without checking 0.x doc retention/canonical-version settings | Verify Hex's docs page still serves 0.12.x docs for adopters pinned `~> 0.12`, and that the "latest" canonical tag correctly points to 1.0.0 only once it's out |
| Dialyzer in CI | Adding ~129 new specs in one pass without a staged Dialyzer run locally first | Run `mix dialyzer` incrementally per module/phase, not once at the end — PLT cost and error volume both compound (per this repo's own noted "Dialyzer cost" concern and prior PLT-cache gotchas in project memory) |
| `--warnings-as-errors` (adopter-side) | Assuming adopter CI mirrors this repo's own clean compile | Explicitly test a fresh `mix new` + `{:threadline, "~> 1.0"}` app with `--warnings-as-errors` as part of verification, not just this repo's own compile |

## "Looks Done But Isn't" Checklist

- [ ] **@spec coverage:** "100% of public functions have a spec" — verify none are bare `term()`/`any()` on functions with real argument shapes (Pitfall 5).
- [ ] **Deprecation:** "overlapping entry points consolidated" — verify the losing functions are hard-deprecated (not silently removed) and every internal/example/guide call site was updated (Pitfall 1, 4).
- [ ] **Hidden modules:** "internal helpers hidden" — verify none of the hidden modules are referenced in guides/README/example app, or the hide is treated as a breaking change (Pitfall 8).
- [ ] **Bounded default:** "history/3 has a sane default limit" — verify truncation is structurally observable in the return shape, not just inferable from `length(result) == limit` (Pitfall 9).
- [ ] **Support floor:** "Elixir/PG floor raised" — verify a CI lane actually tests the new stated floor, not just documents it (Pitfall 10).
- [ ] **1.0.0 release:** "milestone declares 1.0.0" — verify the release-please PR title is literally `1.0.0`, not `0.13.0`, before merging (Pitfall 11).
- [ ] **New guides:** "table-shapes guide and threat model shipped" — verify each has its own doc-contract test, matching the existing 19-file pattern (Pitfall 14).

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|-----------------|-------------------|
| release-please ships 0.13.0 instead of 1.0.0 | LOW | Catch before merging the release PR (Pitfall 11's gate); if already merged, release-please supports a manual version override in a follow-up PR — costly in confusion but not in code |
| A deprecated function's delegate drifts from its target | MEDIUM | Add the parity test retroactively, fix behavior, ship a patch release with a CHANGELOG note; no semver violation since behavior is being *corrected* to match documented contract |
| An Ecto struct field gets exposed, then needs restructuring in 1.x | HIGH | Can't fix within 1.x without a breaking change; must wait for 2.0, or add a *new* field/function alongside the old one and deprecate the old shape — this is exactly why Pitfall 7's decision must be made carefully now |
| A hidden module turns out to be in active use by guides | LOW-MEDIUM | Un-hide it (restore `@moduledoc`), document it properly, and treat it as "we were wrong to park this one, not worth a major bump to revert a doc-visibility change alone" |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| Deprecate-vs-remove ONE-WAY call | Consolidation phase | CHANGELOG + moduledoc each hard-deprecated function names the exact replacement; `mix compile --warnings-as-errors` clean on internal code |
| `--warnings-as-errors` breaking adopters | Consolidation phase | Internal/example/guide call sites updated; fresh adopter-app smoke test with the flag on |
| Delegate drift | Consolidation phase | Parity test per deprecated function; delegates are pure one-liners |
| Lying/narrow specs | @spec/@doc completion phase | Agent-review rubric rejects bare `term()`/`any()` on non-trivial functions |
| Specs on delegates | Consolidation + spec phase (same or sequential) | No duplicated hand-written spec on `defdelegate` targets |
| Docs search surfacing old names | Consolidation phase | Doc-contract test extension; grep sweep of guides/README/example app |
| Ecto struct field exposure (ONE-WAY) | @spec/@doc + table-shapes guide phase | Explicit stable-field list documented per schema moduledoc; decision recorded before schema specs are written |
| Hiding referenced modules | @spec/@doc completion phase | Extend `public_surface_contract_test.exs`'s existing hide/rename tracking |
| Bounded default truncation | Consolidation phase (deferred v1.44 item) | Property test updated for bounded contract + truncation-signal field; export/history parity documented |
| Support floor raise | Support-floor phase | CI matrix lane actually runs the new stated floor; CHANGELOG breaking-changes entry |
| release-please 0.13.0 vs 1.0.0 | Release/declare-1.0.0 phase | `bump-minor-pre-major` flipped before breaking commits; release PR title verified pre-merge |
| BREAKING footer collapse | Release/declare-1.0.0 phase | `git log --grep="BREAKING CHANGE"` cross-checked against hand-written CHANGELOG entry |
| Scope creep (parked UI, polish, internals rewrite) | Cross-phase discipline, enforced at every discuss/plan step | Every phase traces to one of PROJECT.md's six target-feature bullets; no `operator_surface`/LiveView edits without an API-forced justification |
| Threat-model/table-shapes overclaiming + drift | Table-shapes + threat-model phase | New doc-contract test per guide; security-reviewer-lens pass hunting unscoped absolutes |

## Sources

- This repository, verified directly (HIGH confidence): `.planning/PROJECT.md`, `.planning/MILESTONE-GUIDE.txt` §7, `release-please-config.json:4` (`bump-minor-pre-major: true`), `CHANGELOG.md` (0.12.0 entry structure, human-owned/generated split), `lib/threadline/capture/audit_change.ex:1-40`, `test/threadline/public_surface_contract_test.exs`, `test/threadline/semver_adopter_doc_contract_test.exs`, and the 19 `test/threadline/*_doc_contract_test.exs` files.
- [Compatibility and deprecations — Elixir docs](https://hexdocs.pm/elixir/1.19.0-rc.0/compatibility-and-deprecations.html) — the 3-step soft/hard-deprecate/remove-at-major policy cited for the ONE-WAY recommendation. HIGH confidence, official source.
- [Library Guidelines — Elixir docs](https://hexdocs.pm/elixir/main/library-guidelines.html) — general Hex library semver conventions. HIGH confidence, official source.
- Phoenix/Ecto/Oban/LiveView major-version deprecation behavior (Ecto 2→3 adapter/type changes, Oban 2.x worker-shim retention, Phoenix 1.6/1.7 LiveView-aligned majors): MEDIUM confidence, recalled from general ecosystem knowledge, not re-verified line-by-line against each project's own changelog this pass — directionally reliable (all four projects are well known for *not* removing public functions mid-major) but specific version numbers should be spot-checked if a roadmap author wants to cite exact precedent commits.
- Rails gems / Django / Hibernate Envers / PaperTrail / Logidze precedent on deprecated-delegate drift and long-tail deprecation debt: LOW-MEDIUM confidence, general cross-ecosystem pattern recall rather than a specific verified incident — presented as a known *class* of failure (widely discussed in the Ruby/Rails gem-maintenance community), not a cited specific commit or issue.

---
*Pitfalls research for: Threadline v1.45 "1.0 API Contract"*
*Researched: 2026-10-02*
