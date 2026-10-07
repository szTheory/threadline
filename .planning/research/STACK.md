# Stack Research — v1.45 "1.0 API Contract"

**Domain:** Toolchain support floor, enforcement tooling, deprecation mechanics, ExDoc structure, and release mechanics for declaring Threadline 1.0.0.
**Researched:** 2026-10-02
**Confidence:** HIGH on verified floors/EOL dates and existing codebase facts (file:line cited); MEDIUM on ecosystem precedent framing; LOW flagged inline where a claim could not be verified.

This file answers six decision points for the 1.0 milestone. Each carries a single RECOMMENDATION. Decisions that cannot be walked back after 1.0.0 ships are marked **ONE-WAY**.

---

## 1. Support floor (Elixir / OTP / PostgreSQL)

### Current declared state

- `mix.exs:38` — `elixir: "~> 1.15"`, with an explicit mix.exs comment (mix.exs:39-47) already forbidding raising this: *"Do not bump `~> 1.15` to a newer minor: that would strand applications on the supported floor."*
- `dialyzer` flags and `plt_add_apps` (mix.exs:56-74) — not a version lever, covered in §2.
- CI matrix (`.github/workflows/ci.yml:600-616`), three lanes under one job:
  - `min`: Elixir 1.15.8, OTP 26.2.5.21, PG 14
  - `current`: pinned via `.tool-versions` (repo's working toolchain), PG 16
  - `latest`: Elixir 1.20.4, OTP 29.1.1, PG 18.6
- The `min` lane is the enforced floor — it runs the full suite, not a smoke test. `latest` is "tested-on evidence, not a support promise" per the mix.exs comment.

### What upstream dependencies actually require (verified 2026-10-02)

| Dependency | Threadline's constraint | Upstream's own Elixir floor (current release) |
|---|---|---|
| `ecto_sql` (mix.exs:91, `~> 3.10`) | 3.10+ | `~> 1.14` (ecto_sql `master`/3.14.x, per GitHub mix.exs) — **below** Threadline's floor, not a blocker |
| `postgrex` (mix.exs:92, `~> 0.17`) | 0.17+ | 0.15+ requires Elixir 1.6+; 0.22.x requires Elixir 1.15+ (hexdocs changelog) — in range at 1.15 |
| `oban` (mix.exs:103, `~> 2.15`, optional) | 2.15+ | current Oban requires `~> 1.15` (GitHub mix.exs) — **exactly** matches Threadline's floor |
| `phoenix` (mix.exs:99, `~> 1.7`, optional) | 1.7+ | Phoenix 1.7.x itself floors lower than 1.15, no conflict |
| `phoenix_live_view` (mix.exs:100, `~> 1.0`, optional) | 1.0+ | current/`main` LiveView requires `~> 1.15` (GitHub mix.exs) — **exactly** matches Threadline's floor |

No optional or required dependency needs Elixir newer than 1.15 today. Oban and LiveView have *already* independently converged on 1.15 as their own floor — this is strong outside corroboration that 1.15 is still a live, supported floor in the ecosystem, not a stale one Threadline alone clings to.

### PostgreSQL EOL (verified 2026-10-02)

PostgreSQL's release policy is five years of support per major version, final releases each November:
- PG 13 — EOL 2025-11-13 (already past)
- **PG 14 — EOL 2026-11-12** (≈6 weeks after this milestone's likely ship date)
- PG 15 — EOL 2027-11-11
- PG 16 — EOL 2028-11-09

Sources: [endoflife.ai PG14](https://endoflife.ai/article-postgresql-14-eol), [TuxCare PG14 EOL](https://tuxcare.com/blog/postgresql-14-end-of-life/), [Instaclustr PG versions](https://www.instaclustr.com/education/postgresql/postgres-versions-supported-releases-eol-dates-upgrades/).

### Decision A — Elixir/OTP floor

**Options:**

1. **Keep `~> 1.15` / OTP 26.** No code or doc change beyond re-stating the policy for 1.0.
   - Pro: zero adopter disruption; matches Oban's and LiveView's own current floor; the mix.exs comment and `min` CI lane already encode and test this.
   - Con: 1.15 is 3+ years old by the time 1.0 ships; some would read "1.0" as a chance to modernize.
2. **Raise to `~> 1.16` or `~> 1.17`.** Would unlock `Code.fetch_docs/1` niceties, `Duration`, PG18-era driver improvements (none of which Threadline currently needs), and align the floor to a less ancient release.
   - Con: **ONE-WAY** in the sense that lowering it back later needs a new major; raising the floor on day one of 1.0 strands anyone currently on 1.15 LTS platforms (e.g. a team pinned to an older Erlang/OTP for a Heroku/Nix/Debian buildpack) and is a pure regression for them with zero corresponding capability Threadline ships.
   - No concrete Threadline feature in the v1.45 scope (per the milestone's own scope list — spec/doc completion, entry-point consolidation, support-floor documentation) requires 1.16+.
3. **Decouple "floor" from "tested."** Keep the floor, but widen what CI tests to validate the decision rather than change it.

**Precedent:** Oban and Phoenix LiveView, two of Threadline's own optional deps, sit at `~> 1.15` on their current stable lines — i.e. the wider ecosystem is not pressuring library authors past 1.15 yet. Ecto/ecto_sql stay even lower (`~> 1.14`), consistent with Ecto's historically conservative floor policy. Raising past what your *own dependencies* require, with no feature driving it, is the classic unforced-error pattern this phase is designed to prevent (the milestone context explicitly warns against new scope).

**RECOMMENDATION:** Keep `elixir: "~> 1.15"` and OTP 26 as the 1.0.0 floor. Do not raise it. **ONE-WAY note:** declaring this at 1.0 and documenting a public floor-change policy (see below) converts any *future* floor raise from an implicit assumption into an explicit, documented minor-version event — which is itself the right outcome for a 1.0 contract. The floor commitment itself is not one-way (floors can still rise in a later minor under semver for libraries, see FAQ below), but *silently* raising it without a changelog/guide entry would break the contract this milestone is building.

### Decision B — PostgreSQL floor

**Options:**

1. **Keep PG 14 as the floor**, matching the current `min` CI lane (`.github/workflows/ci.yml:606`).
   - Con: PG 14 is EOL 2026-11-12 — about 6 weeks after a 1.0.0 cut on 2026-10-02's trajectory. Shipping a 1.0 "trustworthy API contract" that advertises support for a version with no vendor security patches left is a credibility gap a DBA/SRE reviewer will flag immediately.
2. **Raise the floor to PG 15** (EOL 2027-11-11, 13 months of runway from today) at 1.0.0.
   - Pro: aligns the floor with a still-supported release for the whole first year of the 1.0 line; PG 15 adds nothing Threadline's trigger/PL-pgSQL capture layer needs, but neither does keeping 14 — the choice is support-window hygiene, not a technical dependency.
   - Con: **ONE-WAY** for anyone currently deployed on PG 14 who upgrades to Threadline 1.0.0 before 2026-11-12 — they'd be running an unsupported combination. Mitigate by shipping this as a documented, called-out change (CHANGELOG `BREAKING CHANGE:` footer + an upgrade-guide line), not a silent bump, and by timing the 1.0.0 release close to the PG 14 EOL date so the overlap window is small or already closed.
3. **Keep 14 at 1.0.0, pre-announce a PG-15 floor for 1.1.0 at the PG 14 EOL date.** Defers the breaking change to a minor that can carry its own migration note.
   - Pro: zero adopter disruption on the 1.0.0 cut itself.
   - Con: ships a 1.0 "trustworthy contract" whose stated floor is already-or-nearly EOL on day one — arguably worse optics than option 2 for a library explicitly selling operational trustworthiness (DBA/SRE lens).

**Precedent:** Ecto/Postgrex do not hard-floor a specific PostgreSQL *server* version in `mix.exs` (that's a runtime/driver concern, not a compile-time dependency constraint) — they document supported server versions in guides/README prose instead. Threadline should follow the same shape: the PG floor is a **documentation + CI-matrix** commitment, not a `mix.exs` constraint (there is no `mix.exs` field for "minimum PostgreSQL server version" — only the EXTENSION-equivalent check at runtime, if any). Carbonite and pgaudit, the nearest capture-layer precedents, both track PostgreSQL's own support window rather than freezing to an old major indefinitely, because trigger/PL-pgSQL surface area is sensitive to server-version removals (e.g. deprecated catalog columns).

**RECOMMENDATION:** Raise the floor to **PostgreSQL 15** as part of the 1.0.0 cut, update the `min` CI lane (`ci.yml:606`) from `pg: "14"` to `pg: "15"`, and state the new floor explicitly in the upgrade guide and CHANGELOG as a `BREAKING CHANGE:` footer (even though no Elixir code changes — it is a contract change for anyone on PG 14). **ONE-WAY.** This is the only part of the support-floor decision that should actually move at 1.0; the Elixir/OTP floor stays put (Decision A).

### Decision C — how to document the floor as policy (not just a pin)

**Options:**

1. **No written policy** — the floor is just whatever `mix.exs` says this release. (Status quo plus a comment, which is what exists today.)
2. **A documented support-floor policy** in a guide (e.g. `guides/upgrade-path.md` or a new `guides/support-policy.md`), stating in plain language: *"Threadline supports the current and previous two Elixir minors with upstream security support, and the newest PostgreSQL major still inside community support at time of floor review, reviewed each minor release."* This is the common "N-2" or "last N with community support" framing used by Phoenix, Ecto, and most BEAM-ecosystem libraries informally, made explicit.
3. **A machine-checked contract** — e.g. a test asserting `mix.exs`'s `elixir:` requirement matches a documented floor string, so the floor can't silently drift between code and docs.

**RECOMMENDATION:** Do both 2 and 3, cheaply. Add a short "Support Policy" subsection (floor table: Elixir/OTP/PG minimums + the CI matrix's three lanes explained) to an existing guide (`guides/upgrade-path.md` is the natural home — it is already in the ExDoc "Adopt" group per mix.exs:68) rather than a new doc file (avoids ExDoc extras-list churn). Then add one cheap `ExUnit` doc-contract test (the repo already has a pattern for this — note `test/threadline/audit_doc_contract_test.exs`, `audit_indexing_doc_contract_test.exs` per the partition-weights listing) asserting the guide's stated floor numbers textually match `Mix.Project.config()[:elixir]` and the CI `min` lane's `pg:`/`elixir:`/`otp:` values (parse `.github/workflows/ci.yml` as text/YAML in the test). This prevents the exact failure mode CLAUDE.md already warns about elsewhere in this repo (docs and code drifting silently) and costs one test file, no new tooling dependency.

---

## 2. Typespec/doc enforcement tooling

### What Threadline already has (verified)

- `mix.exs:56-74` — Dialyzer is configured with `plt_add_apps` covering every optional dependency, `flags: [:unmatched_returns, :extra_return]`, `ignore_warnings: ".dialyzer_ignore.exs"`, and `list_unused_filters: true`.
- `.dialyzer_ignore.exs` is `[]` — **zero ignores**, confirmed by reading the file directly. `.planning/PROJECT.md:599` documents this as a deliberate, measured gate from Phase 199: *"made strict full-app Dialyzer a measured blocking gate with a zero ignore ceiling."*
- `verify.dialyzer_slice` (mix.exs:135-143) is a second, independent live-proof test (`dialyzer_slice_contract_test.exs`) that fails closed if Dialyzer didn't actually run — guarding against a silently-skipped gate, not just a silently-passing one.
- Credo is run `--strict` (mix.exs `verify.credo` alias) with one explicit check configuration visible: `Credo.Check.Readability.ModuleDoc` (grep hit, `.credo.exs`) — i.e. module docs are already enforced via Credo, but nothing currently enforces **function**-level `@doc`/`@spec` presence.
- The measured baseline (from the milestone context, not independently re-verified here): ~129 of 169 public functions across non-`@moduledoc false` modules lack `@spec`, including all 17 on the `Threadline` facade (`lib/threadline.ex`).

### Options for gating "every public function has `@spec` and `@doc`"

1. **`Code.fetch_docs/1`-based ExUnit test.** Walk every non-`@moduledoc false`, non-`@doc false` public module (via `Code.fetch_docs/1` returning `{:docs_v1, _, :elixir, _, moduledoc, _, docs}`), assert every `{:function, name, arity}` entry with `:none`/`:hidden` doc metadata and public visibility fails, and separately assert a `@spec` exists for the same function via `Kernel.Typespec`-equivalent (in modern Elixir, `Code.Typespec.fetch_specs/1` against the compiled `.beam`).
   - Pro: zero new dependencies; runs in the existing `mix verify.test` / `ci.all` path at ExUnit speed (milliseconds, not Dialyzer's minutes); fully introspectable — a failing test prints exactly which `Module.function/arity` is missing which artifact, which is far more actionable than a Dialyzer warning; this is exactly the pattern the repo already uses elsewhere (the "doc_contract_test.exs" family visible in `test/partition_weights.txt`, e.g. `audit_doc_contract_test.exs`, `audit_indexing_doc_contract_test.exs` — Threadline already tests doc *content* structurally, not just presence).
   - Con: you write and own ~40-80 lines of introspection code (one-time cost); must explicitly special-case macros, callbacks, and `Mix.Task` behaviours (`run/1`) that have different doc/spec conventions.
2. **Credo custom check.** Write a `Credo.Check` that walks the AST for `def`/`defp` without a preceding `@spec`/`@doc`.
   - Pro: integrates with the existing `--strict` Credo run (one gate, not two); gets Credo's existing AST tooling for free.
   - Con: Credo checks operate on source AST, not compiled docs — correctly distinguishing "has no `@doc` but is `@doc false`'d" or "has `@spec` via a macro-generated `defdelegate`" is fiddlier in AST-land than in `Code.fetch_docs/1`'s already-normalized output; Credo's own built-in checks don't cover this (there is no `Credo.Check.Readability.Specs` or doc-presence check shipped in Credo core as of 1.7.x — this would be fully custom, LOW confidence on current Credo versions since not independently verified here).
3. **Dialyzer `:underspecs` / `:missing_return` flags.** Dialyzer's `:underspecs` flag warns when a `@spec` is looser than what Dialyzer infers; `:missing_return` is not a real Dialyzer flag (closest real ones are `:unmatched_returns` — already enabled — and `:extra_return` — already enabled). Neither flag *requires a `@spec` to exist* — Dialyzer only ever checks specs that are present; it is structurally incapable of enforcing "every function must have one."
   - Con: doesn't solve the stated problem at all. Keep the current `:unmatched_returns`/`:extra_return` flags for what they do (catch stale specs vs. inferred returns), but they are not a `@spec`-presence gate.
4. **`doctor`-style library** (e.g. `mix doctor` / `doctor` hex package, or `ex_doc`'s own coverage reporting via `mix docs` output warnings).
   - Pro: purpose-built, configurable thresholds (e.g. "90% spec coverage"), a ready-made `mix doctor.gen.config`/report.
   - Con: a **new runtime/dev dependency** for a check that is ~50 lines of `Code.fetch_docs/1` test code; threshold-based tools ("90% coverage") are a worse fit than a hard "100% of the public surface" gate, which is what this milestone's stated scope line actually wants ("complete @spec/@doc on the public surface" — a ceiling, not a percentage); adds a dependency-floor/CI-matrix surface to manage (does `doctor` itself support the `min` Elixir 1.15 lane? Not verified — LOW confidence, avoid the risk).

**Precedent:** Ecto, Phoenix, and Oban do not use `doctor` or a custom Credo check for this; they rely on `@spec`/`@doc` discipline as a PR-review norm plus `ex_doc`'s build warnings (`mix docs --warnings-as-errors`, which Threadline already runs at `mix.exs:336` in the release-verification alias) catching `@doc` cross-reference errors, not presence. Threadline's own existing `verify.dialyzer_slice` pattern — a cheap ExUnit test that proves a more expensive gate actually ran — is the right template to reuse here rather than reach for a new tool.

**RECOMMENDATION:** Build a single new ExUnit test (e.g. `test/threadline/public_api_contract_test.exs`) using `Code.fetch_docs/1` + `Code.Typespec.fetch_specs/1`, enumerating every module under `lib/threadline` compiled into the `:threadline` app that is not `@moduledoc :hidden`/`false`, asserting every exported `{name, arity}` not marked `@doc false` has both a non-`:none` doc entry and a spec. This is the cheapest durable gate: no new dependency, reuses an established in-repo pattern, runs in the already-blocking `mix verify.test`/`ci.all` path (not a separate 10-20 minute Dialyzer lane), and gives precise per-function failure output. Keep Dialyzer's `:unmatched_returns`/`:extra_return` as-is — they are a different, complementary check (spec *correctness*, not spec *presence*) and are already a proven zero-ignore gate per Phase 199. Do not add `doctor` or a Credo custom check; both are strictly more machinery for the same outcome.

---

## 3. Deprecation mechanics

### The three Elixir-native mechanisms

1. **`@deprecated "message"`** — compiler-level. Emits a compile-time warning at every call site, including inside the defining application's own test suite and inside host apps. This is the only mechanism that a host building with `--warnings-as-errors` (which Threadline's own `verify.compile_no_optional` alias does at `mix.exs:201`, and which many mature Phoenix apps do in CI) will actually *see as a build failure* until they update the call site — i.e. it is the only one of the three that is enforceable, not just advisory.
   - Works on `def`/`defmacro`, and critically on `defdelegate` (`defdelegate old_name(args), to: Mod, as: :new_name` plus `@deprecated` immediately above it) — the idiomatic Elixir shape for "old name forwards to new implementation, callers get a compiler warning, behavior is unchanged."
2. **`@doc deprecated: "message"`** — docs-only metadata. No compiler warning at all; ExDoc renders a "Deprecated" badge/banner on the function's doc page. Purely advisory to someone *reading the docs*, invisible to someone who copy-pasted a call from an old example or upgraded a dependency without reading changelogs.
3. **Runtime `Logger.warning/1` (once per call, or on first call via a `:persistent_term`/`Process` flag "warn once" guard) or `IO.warn/2`.** Fires at runtime, not compile time; `IO.warn/2` additionally accepts a stacktrace and is what the compiler itself uses internally for `@deprecated`. A hand-rolled runtime warning is strictly worse than `@deprecated` for anything that isn't dynamically dispatched (e.g. a callback invoked via `apply/3` where `@deprecated` can't attach to the call site) because it fires in production logs instead of at the adopter's own build time.

### How ExDoc renders each

- `@deprecated` functions get an ExDoc "deprecated" tag/strikethrough-style badge automatically — ExDoc reads the `:deprecated` BEAM chunk metadata the compiler attaches, so `@deprecated` alone already gets you the ExDoc badge **and** the compile warning, making `@doc deprecated:` largely redundant once `@deprecated` is used (confirm no double-badging needed).
- `since:` metadata — `@doc since: "1.0.0"` — renders as a small "Since 1.0.0" annotation next to the function signature in ExDoc. It does not affect compilation or warnings at all; it is pure provenance documentation, valuable for a 1.0 API contract because it lets adopters see at a glance which parts of the surface are new-at-1.0 vs. carried forward from 0.x.

### Options for Threadline's specific consolidation task

The milestone's own scope item is: *"consolidate overlapping entry points with deprecations"* — concretely `row_history/4` vs `row_history_page/4`, `actor_history/2` vs `actor_window/3`, `timeline/2` vs `as_of/4`, all duplicated across `Threadline`, `Threadline.Query`, and `Threadline.Investigation`.

1. **`@deprecated` + `defdelegate` for the entry point being retired**, pointing at the one being kept, on every facade that exposes it.
   - Pro: a host app that upgrades and builds with `--warnings-as-errors` gets a hard, actionable, call-site-specific compiler error naming the exact replacement — the strongest possible signal short of actually removing the function, and the **only** one of the three mechanisms that moves adopters to act rather than just informs them.
   - Con: noisy for a library's own internal cross-calls (if `Threadline.Query.timeline/2` internally calls the facade's deprecated alias, that internal call itself now warns — mitigate by having the retained implementation be the single source of truth and having every alias, including other library-internal callers, call the *kept* name directly, never the deprecated one).
2. **`@doc deprecated:` only**, no `@deprecated`.
   - Con: silent to anyone building with `--warnings-as-errors`, which is exactly the audience most likely to *also* run `mix hex.outdated`/read CHANGELOGs carefully — i.e. it under-serves the careful adopter and does nothing for the careless one. Wrong choice for a 1.0 API *contract*, whose whole purpose is enforceability.
3. **Runtime warning only.**
   - Con: as above, worse than `@deprecated` for anything that's a normal function call (which all six duplicated entry points are) — no reason to choose it here.

**Precedent:** Ecto uses `@deprecated` on functions it is retiring (e.g. deprecated repo callbacks across major versions) specifically because Ecto host apps are exactly the kind of codebase that runs `--warnings-as-errors` in CI, and Ecto wants that CI to go red immediately rather than rely on changelog-reading. Phoenix has done the same for `Phoenix.LiveView` API consolidations. This is the dominant idiom; `@doc deprecated:`-only is used by libraries that want to flag soft stylistic preferences (e.g. "prefer the keyword-list form"), not to retire overlapping public API surface — not Threadline's situation.

**RECOMMENDATION — ONE-WAY-adjacent policy, not a single call:**
- Every retired entry point gets `@deprecated "Use Mod.kept_fun/arity instead. Will be removed in 2.0."` directly above the `defdelegate` (or above the function head if the body can't be a pure delegate), on **every** facade that currently exposes the duplicate name (`Threadline`, `Threadline.Query`, `Threadline.Investigation` as applicable) — not just one.
- Pair every deprecation with `@doc since: "1.0.0"` on the **kept** function (marks it as the stable 1.0 surface) and leave the deprecated one's own `@doc` intact (not `@doc false`) so ExDoc still renders it with its automatic deprecated badge — hiding it entirely (`@doc false`) would strand anyone who lands on its hexdocs page from an old bookmark or search result with no migration guidance.
- State the removal policy once, in the CHANGELOG/upgrade guide: deprecated-at-1.0 functions are removed no earlier than 2.0.0 (standard semver deprecation-cycle promise). This itself is a **ONE-WAY** commitment once published — it is the thing that makes the 1.0 contract "trustworthy" rather than just "versioned," so do not skip writing it down.
- Do not use plain `@doc deprecated:` or a runtime `Logger.warning` anywhere in this consolidation — they are strictly weaker for a case where the goal is adopters updating call sites, not just awareness.

---

## 4. ExDoc structure for 1.0

### Current state (verified, `mix.exs` `docs()`, lines ~shown above)

- `groups_for_extras` — six intent lanes (Overview, Integrations, Evaluate, Adopt, Operate, Contribute), matched by regex against `extras:` paths, already well-organized and extensible; no change needed for 1.0 beyond adding a new extra for the support-policy subsection if it's split into its own file (recommended above: don't — fold into `guides/upgrade-path.md` instead, avoiding this churn).
- `groups_for_modules` — five groups: "Core API" (13 facade-shaped modules), "Data Types" (15 struct/schema modules), "Configuration & Extension Points" (10 modules), "Integrations" (1), "Operator Surface" (3), "Mix Tasks" (11). This is already a mature, deliberate taxonomy — the milestone's scope does not ask for a redesign of this, only for completing specs/docs *within* it and for the entry-point consolidation.
- No `groups_for_docs` configured today (not present in the `docs()` output read above) — i.e. within a single module's doc page (e.g. `Threadline`), functions are not currently grouped by job/concern; they render in source-declaration order (or alphabetically, depending on ExDoc version defaults).
- `@moduledoc since: "0.4.0"` is used at least once already (`lib/threadline/operator_surface.ex:20`), confirming `since:` metadata is an established, already-adopted pattern in this codebase — extending it project-wide for 1.0 is continuity, not a new convention.
- `main: "readme"`, `api_reference` is not explicitly disabled anywhere seen — ExDoc generates it by default from `groups_for_modules`; no action needed unless 1.0 wants to suppress or retitle it (not indicated by scope).

### Options for `groups_for_docs` on the facade

Given the milestone's own framing ("Overlapping read entry points... History / Action / Investigation-shaped jobs"), the `Threadline` facade (17 public functions, lib/threadline.ex) is the one module that most benefits from function-level grouping once specs/docs are complete and duplicates are deprecated.

1. **No `groups_for_docs`** — leave functions in declaration order. Cheapest, but a 1.0 facade with ~12-15 kept functions (after consolidation) benefits from visible grouping (capture-related vs. query-related vs. action-related) for discoverability — one of the design pillars this research must weigh.
2. **`groups_for_docs` keyed by `@doc group:` metadata** (ExDoc's modern mechanism — place `@doc group: "Querying"` etc. above each function, then `groups_for_docs: [Querying: & &1[:group] == "Querying", ...]` in `docs()`).
   - Pro: co-locates the grouping decision with the function definition (one less place to keep in sync when a function moves categories); this is the ExDoc-recommended modern approach over regex-on-function-name matching.
   - Con: adds one more `@doc` metadata key to get right across ~15 functions — trivial given specs/docs are being written fresh in this milestone anyway (zero marginal cost, since the facade's `@doc` blocks are being authored from scratch per the baseline gap).
3. **`groups_for_docs` keyed by name-pattern regex** (matching on function name prefix, e.g. `~r/^(timeline|as_of)/`).
   - Con: brittle versus option 2 — a rename breaks the grouping silently with no compiler signal, whereas a missing `@doc group:` is visible in the source right next to the function.

**RECOMMENDATION:** Use `@doc group: "..."` metadata (option 2) on the consolidated `Threadline` facade only (the module with the overlapping-entry-point problem), grouped around the domain verbs already in the milestone brief — suggested groups: `"Capture & Transactions"`, `"Querying & Timelines"`, `"Actions & Context"`, `"Operations"` (export/retention/health) — matching CLAUDE.md's own domain language (AuditTransaction/AuditChange/AuditAction/AuditContext). This is near-zero incremental cost since every one of these `@doc` blocks is being written from scratch this milestone to close the spec/doc gap, and it directly serves the "entry-point consolidation" scope item by making the *post-consolidation* facade self-evidently organized rather than a flat list of 12-15 functions. Do not touch `groups_for_modules` or `groups_for_extras` — both are already mature and out of this milestone's stated scope.

### `@moduledoc false` vs `@doc false`

Both already used correctly per the pattern implied by the codebase (operator-surface internals, mechanical checker, critic tooling — all excluded from the package via `package()`'s `exclude_patterns`, mix.exs). Policy for 1.0: `@moduledoc false` for modules that are implementation detail end-to-end (internal helpers, Mix-task-only support modules); `@doc false` for individual functions on an otherwise-public module (e.g. a struct module with one internal constructor alongside public accessors). No change needed — just apply consistently as the spec/doc backfill proceeds, and explicitly do **not** use `@doc false` on the deprecated duplicate entry points (see §3 — they need to stay visible with their deprecation badge).

---

## 5. 1.0.0 release mechanics with release-please

### Current config (verified, `release-please-config.json`)

```json
{
  "release-type": "elixir",
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": false,
  "packages": { ".": { "changelog-path": "CHANGELOG-GENERATED.md", "include-v-in-tag": true, ... } }
}
```

`bump-minor-pre-major: true` means: while the manifest version has major `0`, a `feat:` commit bumps the **minor** (0.x → 0.(x+1).0) instead of what it would do post-1.0 (bump the **major**). `bump-patch-for-minor-pre-major: false` means a `fix:` commit bumps patch as normal pre-1.0 (not collapsed into a no-op). This is release-please's standard, documented pre-1.0 SemVer-caution behavior — exactly as intended, and it must change at the moment of the 1.0 cut, not before.

### Options for cutting exactly 1.0.0

1. **`Release-As: 1.0.0` commit footer** on the PR/commit that triggers the release-please run. release-please reads this footer and forces the next release to be exactly that version regardless of what conventional-commit bump math would otherwise produce, **once**, as a one-time override — it does not change the manifest's ongoing bump behavior afterward.
   - Pro: explicit, auditable in the git log and PR description; no config file to remember to revert; this is release-please's documented sanctioned mechanism for "non-standard" version jumps including the 0.x → 1.0.0 crossing.
   - Con: must still separately update `bump-minor-pre-major` to `false` (or remove it) in `release-please-config.json` at or before this point — otherwise the **next** release after 1.0.0 (a routine `feat:`) would incorrectly try to bump the minor again instead of the major, because the pre-major bump behavior is still configured. This is the single most important interplay point: **the config edit is not optional just because `Release-As` handled the version number once.**
2. **Edit `release-please-config.json` directly** (set/remove `bump-minor-pre-major`, or hand-edit `.release-please-manifest.json`'s version to `1.0.0` as a one-time manual seed) with no `Release-As` footer.
   - Con: hand-editing the manifest file bypasses release-please's own PR-based review flow for the version bump itself — a maintainer could do this, but it's less auditable than a commit footer and the project's existing CI (`verify-bump-rehearsal` job, `.github/workflows/ci.yml`) is explicitly built around trusting PR-driven bump mechanics, not manual manifest edits. Avoid for consistency with the project's own built tooling.
3. **Do nothing special — let a `feat!:`/`BREAKING CHANGE:` commit on the current config drive the bump.** Under `bump-minor-pre-major: true`, a breaking-change commit pre-1.0 still only bumps the **minor** (this is exactly what happened at 0.11.0 per CHANGELOG-GENERATED.md, which shows a `⚠ BREAKING CHANGES` entry that bumped 0.10.2 → 0.11.0, not to 1.0.0) — so this path **cannot** produce 1.0.0 on its own under the current config. Confirms option 1 or 2 is required; there is no passive path to 1.0.0.

**RECOMMENDATION:** Use **both**, in this order, as a single coordinated PR:
1. Flip `release-please-config.json`'s `bump-minor-pre-major` to `false` (or delete the two pre-major keys entirely — they are no-ops post-1.0 and release-please's elixir release-type defaults to standard SemVer bump math without them) in the same PR that contains the 1.0 API-contract changes.
2. Put `Release-As: 1.0.0` in the footer of the commit/PR that should trigger the cut, once all 1.0-scoped work (spec/doc completion, deprecations, PG floor bump) has landed on the target branch.
3. Verify with the repo's own existing `verify.bump_rehearsal` alias/CI job (`.github/workflows/ci.yml` "Next-minor release rehearsal" job, mix.exs:16) **before** merging — this job already exists specifically to rehearse bump math against the live config, so it is the correct, already-built gate to catch a misconfigured `bump-minor-pre-major` before the real release-please run fires. **ONE-WAY**: once 1.0.0 is tagged and published to Hex, there is no "un-crossing" major version 1 — treat the rehearsal as mandatory, not optional, for this specific release.

### CHANGELOG and version-pin sync files

- `CHANGELOG-GENERATED.md` is release-please-owned (per `changelog-path` in config) — no manual edits needed beyond the standard conventional-commit discipline already in place (feat/fix/perf/deps sections, confirmed from the file's own rendered history).
- `extra-files` in the config (`guides/adoption-pilot-backlog.md`, `guides/evaluating-threadline.md`) are version-string-synced by release-please automatically on every release — if the 1.0 docs work touches either guide's version-string placeholders, no extra action is needed; release-please will re-sync on the 1.0.0 commit same as any other.
- `mix.exs`'s own `@version` module attribute is the `elixir` release-type's primary target — release-please edits it directly on each release PR (confirmed by the `@version "0.11.2"` value currently in the file matching the CHANGELOG's latest entry 0.11.2).

### Hex package metadata quality bar for 1.0

Current `package()` (mix.exs) already has: `licenses: ["MIT"]`, a populated `keywords:` list, `links:` (GitHub + Changelog), an explicit `files:` allowlist plus `exclude_patterns:` proven against the unpacked tarball by a dedicated contract test (`test/threadline/release_artifact_contract_test.exs`, referenced in the mix.exs comment). This already meets or exceeds the typical Hex 1.0 bar — most libraries only have `licenses`/`links`/default `files:`. The one option worth considering for 1.0 specifically:

- **Add a `links: "Sponsor"` or `"Docs"` entry** — optional polish, not required; Hex auto-populates a docs link from the published ExDoc build regardless, so this is cosmetic. Not recommended as a scope item — avoid adding anything the milestone's "no new scope" constraint would flag.

**RECOMMENDATION:** No package-metadata changes needed beyond what already exists; it already clears the bar. Do not add sponsorship/funding links or additional keywords as part of this milestone — out of stated scope.

---

## 6. Carried CI items

### `bin/ci-test-partitions --write-weights`

Read directly from the script's own header comment (`bin/ci-test-partitions`): `--write-weights` runs the full suite once, unpartitioned, with `mix test --slowest-modules 1000`, and rewrites `test/partition_weights.txt` from the per-module timings (summed per file). It needs:
- **Elixir >= 1.17** (stated explicitly in the script's own usage comment) — this is purely a tooling requirement for the measurement run itself (the `--slowest-modules` flag's output format), **not** a reason to raise Threadline's own `elixir:` floor (Decision A, §1) — the CI `current`/`latest` lanes already run on 1.17+ equivalents, so this constraint is already satisfied by the existing toolchain pin (`.tool-versions`), and the floor lane (1.15.8) never needs to run this maintenance command itself.
- The local test database (standard `mix test.setup` prerequisites already documented elsewhere in the repo).

**Current staleness:** `test/partition_weights.txt`'s own header states *"A stale or missing entry only makes the partitions less even; every test file still runs exactly once"* — i.e. staleness is fail-safe by design (confirmed by reading the script's exactly-once invariant checks, items (i)/(k)/(o) in its self-test list). This milestone's spec/doc work will add/rename test files for the consolidated entry points and the new public-API-contract test (§2) — new test files get the median weight automatically (no crash), but will unbalance partitions somewhat until weights are refreshed.

**RECOMMENDATION:** Run `bin/ci-test-partitions --write-weights` once, locally, **after** all of this milestone's test-file churn has landed (new deprecation tests, the new public-API-contract test, any PG-floor-related CI changes) and commit the refreshed `test/partition_weights.txt` as part of the closing housekeeping commit — not mid-milestone, since weights would just go stale again with more churn. This is a non-blocking hygiene step (the fail-safe design means skipping it entirely would not break CI, only leave partitions mildly uneven) — treat as optional-but-cheap, not a gate.

### Async DataCase tests given no SQL Sandbox

CLAUDE.md's Key Design Constraints and the existing CI/testing conventions (per MEMORY: "Test determinism conventions... no SQL Sandbox by design") establish that Threadline deliberately does **not** use Ecto's `Ecto.Adapters.SQL.Sandbox` — because the capture layer's trigger-backed writes need **committed transactions** to fire and be visible (triggers execute inside the transaction, but cross-connection visibility of their effects, and anything depending on `NOTIFY`/LISTEN or a second connection querying the audit tables, needs the write actually committed, which Sandbox's wrap-and-rollback-per-test model prevents). Each test gets its own real database/schema instead (seen in CI as `threadline_test<i>` per-partition databases, `bin/ci-test-partitions` header).

**Is async safe for *pure-read* DataCase tests specifically?**

- **Pro-async case:** A test that only reads already-seeded, static fixture data (no writes in the test itself, no shared mutable rows) has no cross-test interference even without Sandbox, *provided* it doesn't share a connection pool checkout pattern that assumes serialization, and provided no other async test in the same run mutates the same rows.
- **Con-async case:** Without Sandbox's isolation, two async tests that both read-then-assert against rows another async test is concurrently *writing* (even a nominally "pure read" test can be sharing a database with a writer test in the same partition under `async: true`) risk flaky, order-dependent failures — this is precisely the class of bug this repo's own MEMORY entry ("Test determinism conventions") already documents as previously fixed (a retention-pruner flake, fixed via `async_helpers`, specific tests forced to `async: false`, plus a dedicated `mix verify.flake` / Flake Detection CI workflow built specifically to catch this class of regression).

**RECOMMENDATION:** Do **not** blanket-convert DataCase tests to `async: true` as part of this milestone — it is out of the stated v1.45 scope (no new product/test-infra scope), and the repo already has purpose-built tooling (`mix verify.flake`, the Flake Detection workflow) to catch exactly this risk if it were attempted. If a specific new test added for this milestone (e.g. the public-API-contract test in §2, which is a pure in-memory `Code.fetch_docs/1`/`Code.Typespec` introspection test with **no database access at all**) is async-safe by construction (no DB, no shared mutable state), mark *that individual new test* `async: true` on its own merits — it needs no DataCase at all, so the Sandbox question doesn't even apply to it. Leave all existing DataCase tests' async settings untouched.

---

## Summary table — all six decisions

| # | Decision | Recommendation | ONE-WAY? |
|---|---|---|---|
| 1A | Elixir/OTP floor | Keep `~> 1.15` / OTP 26 | No (floor itself); yes if changed silently later |
| 1B | PostgreSQL floor | Raise to PG 15, update CI `min` lane, document as `BREAKING CHANGE:` | **Yes** |
| 1C | Floor documentation | Add Support Policy subsection to `guides/upgrade-path.md` + a doc-contract test asserting it matches `mix.exs`/CI | No |
| 2 | Spec/doc enforcement | New `Code.fetch_docs/1` + `Code.Typespec` ExUnit test, no new dependency | No |
| 3 | Deprecation mechanics | `@deprecated` + `defdelegate` on every facade exposing a retired entry point, paired with `@doc since:` on the kept one; removal no earlier than 2.0.0 | Policy commitment is **Yes** once published |
| 4 | ExDoc structure | `@doc group:` on the `Threadline` facade only; leave `groups_for_modules`/`groups_for_extras` unchanged | No |
| 5 | Release mechanics | `Release-As: 1.0.0` footer + flip `bump-minor-pre-major` to false in the same PR; verify via existing `verify.bump_rehearsal` | **Yes** (the cut itself) |
| 6 | CI carry items | Refresh `test/partition_weights.txt` once after milestone's test churn settles; leave DataCase async settings untouched; new pure-introspection test may be `async: true` on its own merits | No |

## Sources

- [PostgreSQL 14 End of Life — endoflife.ai](https://endoflife.ai/article-postgresql-14-eol) (HIGH — cites 2026-11-12, cross-checked against two other results)
- [PostgreSQL 14 End of Life: Dates, Risks — TuxCare](https://tuxcare.com/blog/postgresql-14-end-of-life/) (HIGH, corroborating)
- [Postgres Versions: Supported Releases, EOL Dates — Instaclustr](https://www.instaclustr.com/education/postgresql/postgres-versions-supported-releases-eol-dates-upgrades/) (HIGH, corroborating)
- [ecto_sql mix.exs — GitHub](https://github.com/elixir-ecto/ecto_sql/blob/master/mix.exs) (HIGH, primary source)
- [Oban mix.exs — GitHub](https://github.com/sorentwo/oban/blob/master/mix.exs) (HIGH, primary source)
- [phoenix_live_view mix.exs — GitHub](https://github.com/phoenixframework/phoenix_live_view/blob/main/mix.exs) (HIGH, primary source)
- [Postgrex changelog — hexdocs](https://hexdocs.pm/postgrex/changelog.html) (MEDIUM — version-to-floor mapping inferred from search-result summary, not a direct file read; treat the "0.22.x requires 1.15" claim as MEDIUM confidence)
- Codebase citations: `mix.exs` (lines as noted inline), `.github/workflows/ci.yml` (lines as noted inline), `.dialyzer_ignore.exs`, `release-please-config.json`, `.release-please-manifest.json`, `CHANGELOG-GENERATED.md`, `bin/ci-test-partitions`, `test/partition_weights.txt`, `.planning/PROJECT.md:599` (all HIGH — direct file reads)
