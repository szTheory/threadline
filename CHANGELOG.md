# Changelog

<!--
  This file is HUMAN-OWNED. release-please has no write access to it: its
  `changelog-path` points at CHANGELOG-GENERATED.md, and no `extra-files` entry
  or version marker may ever name this file. Bot-generated, commit-subject-
  derived release notes live in CHANGELOG-GENERATED.md, which is deliberately
  absent from the published package and from HexDocs.

  This is the changelog adopters read: it ships in the Hex tarball and renders
  on HexDocs. Write for an upgrader. Within a release entry, breaking changes
  and required action come BEFORE the feature tour — an upgrader's first two
  questions are "will this break me" and "what must I do". An explicit "None"
  beats omission, which reads as oversight.

  Entries dated 0.9.0 and earlier were written by release automation when this
  file was its target. They stay as published history.
-->

## Unreleased — highlights

Highlights accumulate here as work lands, and this heading is retitled to the
dated release heading at release time. The heading is deliberately unbracketed:
a bracketed form collides with release automation's version-header pattern and
would be read as a release.

`mix threadline.install` could give two or three of its generated migrations the
same version, so `mix ecto.migrate` refused to run them. Every release through
0.10.1 is affected. The installer has written the audit and semantics migrations
with a shared one-second timestamp since 0.1.0, and it has written the
governance migration since 0.6.0. The installer now gives each migration a
distinct version that sorts after every migration already in the directory.

### Breaking changes

None.

### Required action

None for an app that has already migrated, including one whose migration files
were renamed by hand, because the installer runs once.

If you are on an earlier release and `mix ecto.migrate` failed with the error
below, rename the `_threadline_semantics_schema.exs` migration's numeric prefix,
and then the `_threadline_governance_schema.exs` one, to later timestamps so the
order is audit, then semantics, then governance. Then re-run `mix ecto.migrate`.

### Fixed

- `mix threadline.install` no longer writes duplicate migration versions, which
  made `mix ecto.migrate` fail with
  `(Ecto.MigrationError) migrations can't be executed, migration version <N> is duplicated`.
  The versions are computed once, before any file is written, and sort after
  the newest existing migration, including a future-dated one.
- `mix threadline.gen.triggers` had the same kind of bug: run in the same second
  as the installer, its migration could share a version. It now uses the same
  version logic.
- The dedicated-schema advice now prints only after a fresh install that wrote
  all three migrations. A re-run that finds some Threadline migrations already
  present is told to keep `:storage_schema` unset, because switching then would
  split Threadline's tables across two schemas. The fresh-install advice no
  longer ends with a paragraph that contradicted its own steps.

## [0.10.1] - 2026-09-22

A patch release that corrects the storage-schema advice `mix threadline.install`
prints on a new install, and the default the configuration reference states for
`storage_schema`. No library behavior changes: an install that followed the
getting-started guide, or that ignored the installer's advice, is unaffected.

### Breaking changes

None.

### Required action

None for most installs. One case needs a check: on 0.10.0, if you ran
`mix threadline.install` with no `storage_schema` configured, then followed its
advice to add `config :threadline, storage_schema: "threadline"` and re-ran the
task, the re-run kept the migrations it had already generated for `public`. Your
config then names a schema your migrations do not create. To fix it:

- **Not yet migrated:** delete the three generated `*_threadline_*_schema.exs`
  migrations and run `mix threadline.install` again. The dedicated schema is
  then frozen into the new migrations.
- **Already migrated:** remove the `storage_schema` key (or set it to
  `"public"`) so Threadline reads the tables where your migrations put them.
  Moving them to a dedicated schema is deliberate migration work — see
  [`guides/upgrade-path.md`](guides/upgrade-path.md).

### Fixed

- `mix threadline.install` now gives its storage-schema advice after generating,
  names the migration files it just wrote, and says to delete them before
  re-running. It gives no advice when every migration already exists, which is
  an existing install that `public` already describes correctly.
- `guides/configuration-and-commands.md` stated the `storage_schema` default as
  `"threadline"`; it has been `"public"` since 0.10.0. A test now ties the
  documented default to the resolved one.

## [0.10.0] - 2026-09-22

The public-surface and release-truth release: a documented surface an evaluator
can read end to end, a storage-schema default that matches what existing
installs already have, and an operator surface with a theme lane and row-level
deep links.

### Breaking changes

**None.** No commit in this release carries a breaking-change footer or a
breaking-change subject marker, and the one default that did change — the
storage schema — was changed *toward* what every existing install already runs,
which is what makes this release non-breaking rather than merely declared so.
See "Storage schema default" below.

### Required action

Four adopter actions remain. None of them break an install that does nothing,
but each one leaves something unchanged that you probably wanted changed.

- **S3 export adopters** — the export HTTP client moved from `:hackney` to
  `{:req, "~> 0.7"}`, and the `:ex_aws` floor rose from `~> 2.4` to `~> 2.7`.
  Swap the dependency and raise the floor in your host `mix.exs`; a raised floor
  is not additive.
- **Operator-surface mounters** — two new routes, `POST <path>/theme` and
  `<path>/rows/:table/:record_id`, must pass any method allowlist, proxy rule,
  or Content-Security-Policy in front of your `/audit` mount.
- **Custom `Threadline.Storage` adapters** — the `c:Threadline.Storage.put/2` callback narrowed to
  binary content. This is visible to Dialyzer with no runtime change; update
  your adapter's typespec.
- **Callers of implementation modules** — 25 implementation modules became
  `@moduledoc false`. They remain callable for Threadline's own composition, but
  they are no longer a supported surface.

### Storage schema default

Threadline-owned tables, functions, and triggers now default to the host's
`public` schema. A dedicated schema became an explicit opt-in:
`config :threadline, storage_schema: "threadline"`, set before
`mix threadline.install`.

- **Existing installs need no action.** The default now matches the schema your
  install already generated into, so the read paths and your already-deployed
  triggers keep agreeing about where Threadline-owned objects live. This is
  settled by the change in this release, not by an earlier one.
- **New installs should opt in.** The default no longer provides schema
  isolation. Choose `storage_schema` before you run the installer — the choice
  is frozen at generation time, and changing it later is deliberate migration
  work rather than a runtime config edit.

### Added

- **Architecture documentation** — rewrote How Threadline Works as an end-to-end
  visual architecture guide and added a source-driven Code Walkthrough, with
  dark/light Mermaid rendering and the Threadline mark as the HexDocs favicon.
- **Operator-surface theme lane** — `threadline_operator_surface/2` accepts
  `:theme` (`:dark | :light | :system`, default `:dark`), backed by a
  session-persisted picker served from the new `POST <path>/theme` route.
- **Row-level history deep links** — `<path>/rows/:table/:record_id` addresses a
  single audited row's history directly, rather than only through a transaction.

### Changed

- **Documented surface** — generated module documentation now focuses on
  supported façades, returned data, extension points, integrations, the operator
  `Threadline.OperatorSurface.Router` and `Threadline.OperatorSurface.Auth`
  boundary, and adopter Mix tasks. The following implementation modules that had
  pages in the 0.9 documentation are no longer listed:
  - Capture and lifecycle implementation: Threadline.Capture.Migration,
    Threadline.Capture.RedactionPolicy,
    Threadline.Capture.TriggerCaptureConfig, Threadline.Capture.TriggerSQL,
    Threadline.Export.CleanupTask, Threadline.Governance.ExportJob,
    Threadline.Governance.Migration, Threadline.Governance.RetentionRun,
    Threadline.Governance.SavedView, Threadline.Policy.RedactionPresenter,
    Threadline.Retention.Pruner, and Threadline.Semantics.Migration.
  - Operator implementation: Threadline.OperatorSurface.Style,
    Threadline.OperatorSurface.Script, Threadline.OperatorSurface.Scope,
    Threadline.OperatorSurface.SessionPlug,
    Threadline.OperatorSurface.ExportAuthPlug,
    Threadline.OperatorSurface.Components.SurfaceHeader,
    Threadline.OperatorSurface.Controllers.ExportController,
    Threadline.OperatorSurface.Coverage.OnMount,
    Threadline.OperatorSurface.Coverage.Snapshot,
    Threadline.OperatorSurface.Exports.Filename,
    Threadline.OperatorSurface.Exports.FilterParams,
    Threadline.OperatorSurface.Live.ActorLive, and
    Threadline.OperatorSurface.Live.TransactionLive.

  These modules remain callable for Threadline's own composition; this is a
  documentation-surface clarification, not runtime privacy or a change to
  supported façade behavior.
- **S3 export HTTP client** — `:hackney` gave way to `{:req, "~> 0.7"}` and the
  `:ex_aws` floor rose to `~> 2.7`. Both remain optional dependencies; only
  hosts that export to S3 are affected.
- **`c:Threadline.Storage.put/2`** — the first argument narrowed from a path
  or content union to binary content.

## [0.9.0](https://github.com/szTheory/threadline/compare/v0.8.0...v0.9.0) (2026-06-03)


### Features

* **operator-surface:** first-class positioning + accessibility pass ([#16](https://github.com/szTheory/threadline/issues/16)) ([4bf1a07](https://github.com/szTheory/threadline/commit/4bf1a071cc26a81efd08b01cd19c8f91a16f6cc0))

## [0.8.0] - 2026-06-03

Operator-surface release: the `/audit` admin UI matured into a coherent, branded operator console, backed by a fully automated (zero-human-verification) test gate.

### Added

- **Operator surface overhaul** — dark "night infrastructure" theme; a Home task-launcher (Find / Verify / Prove) as the default `/audit` page; copy-to-clipboard affordances for correlation and transaction ids; evidence verdicts (Proven / Inferred / Unsupported) with drill-down history; forward "completion" links so every Verify/Prove screen reaches a done state; a scoped-view indicator and scope-aware empty states for support-read-only operators; explicit "all clear" success states; and restrained, brand-coherent motion.
- **Asset/CSP controls** — `config :threadline, operator_surface_embed_scripts: false` opts out of the embedded (zero-dependency) copy-to-clipboard helper; the new "Assets and Content-Security-Policy" section in `guides/operator-surface.md` documents the inline style/font/script embeds and CSP guidance.

### Changed

- **Design system** — consolidated onto tokenized status stripes and a letter-spacing scale, a canonical metric card (`tl-card--metric` + `[data-status]`) and metadata row (`tl-meta`), and ARIA-driven selected/active state.
- **CI / quality** — official GitHub Actions bumped to their Node 24 majors ahead of GitHub's forced migration; an opt-in/nightly flake-detection gate; and test-determinism hardening across the suite. The operator-surface behaviors are locked by deterministic LiveView + Playwright assertions that gate every PR.

## [0.7.0](https://github.com/szTheory/threadline/compare/v0.6.0...v0.7.0) (2026-05-30)


### Features

* **documentation:** add Configure Threadline subsection to getting-started ([7b929a1](https://github.com/szTheory/threadline/commit/7b929a17963b01b09cd1c51d0972f77cce73927a))
* **documentation:** add host-repository wiring prerequisite to the production checklist ([a07775d](https://github.com/szTheory/threadline/commit/a07775dd039aa3dedfa6b40eca21f3c6bf80bd5f))
* **operator surface:** wire the schemas mount and synchronize operator-surface examples ([17507ba](https://github.com/szTheory/threadline/commit/17507ba958215b86c761d1e4b613ab5193bdd502))
* **auth integration:** add the PhxGenAuthReference.Audit guide module ([2836be1](https://github.com/szTheory/threadline/commit/2836be141df0e5c2547a9fb91f9478cf35431213))


### Bug Fixes

* **ci:** format the phx-gen-auth integration contract for the ci.all gate ([e04f275](https://github.com/szTheory/threadline/commit/e04f275cd3bd123ae18f192da73f6da332aa1285))
* operator timeline crash on correlation_id filter (+ release-please changelog guard) ([43a6f23](https://github.com/szTheory/threadline/commit/43a6f2364feb3a285c15b13a68f35f905bc8a0d5))
* **operator-surface:** prevent timeline crash on correlation_id filter ([d62e509](https://github.com/szTheory/threadline/commit/d62e509e932b3b85b1749a13745b510ad78c0042))
* **release:** run publish chain when release-ref succeeds via dispatch ([19c7549](https://github.com/szTheory/threadline/commit/19c7549d64f67f34329566590ebf45eca96223a7))
* **release:** use hex.build preflight instead of verify.release in CI ([d4413ef](https://github.com/szTheory/threadline/commit/d4413efe783779554a8d9b39d395034d0dea405f))

## [0.6.0] - 2026-05-27

Threadline 0.6.0 is the adopter-ready release: it packages the in-repo stack since 0.5.0 — the Evidence plane (`Threadline.Evidence`, proof vocabulary, `/audit/evidence`), the blessed audited write path (`Threadline.Audit.transaction/3`), and operator/demo surfaces from the realistic walkthrough — so Hex evaluators and pilot hosts see the same truth the library already ships in-tree.

### Added

- **Evidence plane** — `Threadline.Evidence`, `Threadline.Evidence.Proof`, `Threadline.Evidence.Subject`, evidence persistence schema, and `mix threadline.evidence.show` for machine-readable proof export.
- **Audited write path** — `Threadline.Audit.transaction/3` as the blessed helper wrapping capture + semantics in one transaction.
- **Operator and evidence surfaces** — `/audit/evidence` LiveView, host-owned `evidence_authorize_fn` (not inherited from `/audit` auth), and viewer parity with coverage/policy Mix tasks.
- **Reference composition (sigra-reference)** — example app and maintainer walkthrough demonstrate end-to-end audited writes and evidence mounts; see `examples/threadline_phoenix/README.md` and walkthrough docs.

### Changed

- **Public documentation and evidence-plane contract** — Evidence-plane contract locks across public docs: canonical non-goals list, shared verdict vocabulary, and narrower `/audit/evidence` support language. Public guidance treats `/audit/evidence` as a separately authorized capability under the `phoenix-surface` lane instead of a blanket `/audit` inheritance claim.
- **Release metadata** — install snippets target `{:threadline, "~> 0.6"}`; Hex metadata and adoption-pilot distribution preflight align with `0.6.0`.

### Deprecated

- Manual `SET LOCAL` GUC recipes and hand-rolled `record_action/2`-only write paths remain supported as legacy escape hatches; new code should prefer `Threadline.Audit.transaction/3`.

### Breaking

- **None** for existing `capture-only` and `phoenix-surface` adopters who do not opt into Evidence or the audited write helper.

### Upgrade from 0.5.x

- Bump dependency to `{:threadline, "~> 0.6"}` in host `mix.exs`.
- Run `mix deps.get` and `mix deps.compile`.
- If using Evidence: apply evidence schema migrations from library docs / example migrations before calling `Threadline.Evidence` APIs.
- Wire `evidence_authorize_fn` on `threadline_operator_surface/2` when mounting `/audit/evidence` — it does **not** inherit timeline/export `authorize_fn`.
- Adopt `Threadline.Audit.transaction/3` for new write paths; keep legacy GUC/`record_action/2` only where migration cost is high.
- Use `mix threadline.evidence.show` (not the earlier `verify.evidence` alias) for CLI proof export.
- Re-run host verification: `mix threadline.verify_coverage`, `mix verify.doc_contract` (host), and operator-surface smoke tests if mounted.
- See `guides/upgrade-path.md` for lane matrix (`capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference`) and surface deprecation policy.
- ExDoc sidebar adds **Evidence** group and Core API entries for Audit, Query, Investigation, ChangeDiff.
- Maintainer pre-flight before tag: `mix verify.release` on a clean tree (see `CONTRIBUTING.md`).
- Apply evidence migrations before enabling `/audit/evidence` in production — schema must exist before first proof query.
- Deny `/audit/evidence` with the same host-owned auth UX as timeline/export; do not rely on blanket `/audit` session checks.
- Correlation filter semantics on timeline/export are unchanged from 0.5.x — no migration needed for existing query params.
- Re-run `mix threadline.gen.triggers` after evidence schema changes if audited tables gain new columns.
- Confirm `evidence_authorize_fn` returns explicit deny reasons for operator logs — inherited `/audit` auth is not sufficient.

## [0.5.0] - 2026-05-08

Threadline 0.5.0 is the integration-breadth release: the package now ships a narrower and more honest support matrix, a first-party Sigra/Phoenix reference path, canonical admin and support-read-only operator-surface mount recipes, an explicit `threadline_web` extraction-readiness scorecard with a documented stay-in-tree decision, and a repaired shared authorization/scope contract that keeps auth and scoping host-owned across timeline, actor, transaction, and export flows.

### Added

- **Upgrade-path guide** at `guides/upgrade-path.md` — canonical lifecycle policy for the optional Phoenix/LiveView/HTML/PubSub surface. It distinguishes `capture-only` from `surface-mounted`, documents the supported compatibility matrix from declared deps + current lock resolution + CI coverage, and locks the surface-only deprecation/removal overlap policy in one place.
- **Integration breadth guide** at `guides/integration-contracts.md` — canonical host-integration contract for actor extraction, additive audit context, optional dependency posture, operator-surface composition, and fallback CLI workflows.
- **Support-matrix closeout** — the project now names only the three proven lanes `capture-only`, `phoenix-surface`, and `sigra-reference`, and the compile-without-optional / example / doc-contract proof chain is locked to those claims.
- **Sigra/Phoenix reference refresh** — the first-party Sigra integration path and example app were refreshed to the current supported lines while keeping Sigra a soft dependency.
- **Canonical access-tier runbooks** — docs, example code, and tests now prove one shared host-owned `authorize_fn` contract, one host-owned `scope_query_fn` seam, and a real support-read-only `exports: false`/scoped-query story across the operator surface.
- **Packaging Boundary Scorecard** — `guides/upgrade-path.md` now records the explicit `threadline_web` extraction-readiness rubric and the current answer: stay in-tree for now.
- **Coverage dashboard** at `/audit/coverage` — polled three-bucket coverage view with a surface-header pill on every operator-surface LV. `?schema=NAME` URL param for multi-schema adopters; manual Refresh affordance with cancel-and-reschedule timer semantics; on-poll-error UX that keeps the last-good snapshot and ALWAYS reschedules.
- **`mix threadline.health.coverage`** parity Mix task with `--json` and `--schema=NAME` flags. Viewer-only — always exits 0; the CI gate remains `mix threadline.verify_coverage`.
- **Policy redaction drift viewer** at `/audit/policy/redaction` — read-only configured-vs-deployed redaction reconciliation with the three operator-safe states `Config matches deployed`, `Drift detected`, and `Could not introspect`. The surface never shows sample values; it exposes only column names and placeholder metadata, and drift/introspection failures instruct operators to rerun `mix threadline.gen.triggers` and apply the migration.
- **`mix threadline.policy.show`** parity Mix task with `--json`. Default output prints one summary line plus an aligned `TABLE / STATUS / CONFIG / DEPLOYED / HINT` table; `--json` emits the same stable state taxonomy as `config_matches_deployed`, `drift_detected`, and `could_not_introspect`. Viewer-only — drift does not exit non-zero by itself.
- **`Threadline.Health.trigger_coverage/1` `:schema` opt** (default `"public"`). Both inner SQL queries are now parameterized; the `pg_trigger`/`pg_class` query gains a `pg_namespace` join so cross-schema results no longer leak into the covered set. Programmatic callers are responsible for sanitizing `:schema`; surfaces that take untrusted input validate at the edge.
- **Three-bucket return shape on `Threadline.Health.trigger_coverage/1`** — `[{:covered | :uncovered | :expected_uncovered, name}]`. The third bucket is hardcoded to `["schema_migrations"]` plus `config :threadline, :health, expected_uncovered_tables: [...]`, with `:audit_anyway` removing entries. Existing pattern-match callsites (`Continuity.assert_capture_ready!/2`, `TimelineLive` datalist) remain unchanged — the third tuple variant is purely additive.
- **`Threadline.Health.Policy.validate!/1`** — pure-stdlib config validator mirroring capture-time redaction validation. Validate at boot to fail loud on bad config.
- **`[:threadline, :health, :checked]` event metadata** gains `expected_uncovered` measurement key (additive). Old subscribers reading only `covered`/`uncovered` keep working unchanged.
- **`[:threadline, :health, :checked, :error]` sibling event** for polled coverage check failures.
- **`mix threadline.verify_coverage --schema=NAME`** additive flag with the same edge validation contract as the new Mix task. Default behavior unchanged.

### Changed

- **Release metadata** — install snippets now target `{:threadline, "~> 0.5"}`, ExDoc names the operator surface `Optional In-Tree`, and the release/audit artifacts record the integration-breadth release boundary.
- **Operator-surface auth/scoping contract** — the example app no longer relies on a socket-only auth bypass, and timeline, actor, transaction, and export flows all consume the same host-owned scope seam.
- **`Threadline.Verify.CoveragePolicy.violations/2`** treats `{:expected_uncovered, _}` as covered-equivalent for tables not in the adopter's `:expected_tables`. Existing semantics preserved for tables IN `:expected_tables`.

## [0.4.0] - 2026-05-06

Threadline 0.4.0 is the operator-surface foundation release: an opt-in web UI ships behind optional Phoenix/LiveView/HTML/PubSub deps so capture-only adopters keep zero new transitive bloat, the timeline / export query and Mix-task surface gains a `:correlation_id` filter that walks `audit_actions.correlation_id` via the action linkage, and exports learn an opt-in action-metadata pair (JSON `action` object, CSV `include_action_metadata: true`) so incident-response tooling can correlate rows back to the action that produced them — all without changing the default column order or breaking pre-0.4 callers.

### Added

- **Operator Surface** — introduces an opt-in web UI via `Threadline.OperatorSurface.Router`. `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` are now declared as `optional: true` dependencies, meaning zero bloat for capture-only adopters. Hosts that want the UI must add these dependencies to their `mix.exs` and use the `threadline_operator_surface` mount macro in their router.
- **`examples/threadline_phoenix`** — **`audit_transaction_id`** on **`POST /api/posts`** and **`GET /api/audit_transactions/:id/changes`** returning ordered changes with **`change_diff`** maps per row (composition demo; add auth in production). **`guides/domain-reference.md`** documents the pattern under **COMP-EXAMPLE-INCIDENT-JSON**.
- **`:correlation_id` timeline / export filter** — optional keyword on `Threadline.Query.timeline/2`,
  `timeline_query/1`, `export_changes_query/1`, and export entrypoints. Values are trimmed; empty
  after trim, `nil`, non-binary, or longer than **256 UTF-8 bytes** raise `ArgumentError`. When set,
  only `audit_changes` whose transaction has a matching `audit_actions.correlation_id` (via
  `action_id`) are returned (inner join; omit the key for previous behavior). See `Threadline.Query`
  moduledoc for full rules.
- **Export JSON `action` object** — each change may include `"action": {"id", "correlation_id"}`
  when the transaction is linked to an `audit_actions` row.
- **Export CSV `include_action_metadata: true`** — opt-in trailing columns `correlation_id` and
  `action_id`; default CSV column order is unchanged.
- **`guides/adoption-pilot-backlog.md`** — matrix aligned to the production checklist for host pilots, plus distribution preflight and prioritized issue rows.
- **Telemetry (operator reference)** — `[:threadline, …]` event table in **`guides/domain-reference.md`**, linked from **`guides/production-checklist.md`** observability section.

### Changed

- **README** — Documentation list includes the adoption pilot backlog; **ExDoc** extras include the new guide.

## [0.3.0] - 2026-05-05

Threadline 0.3.0 is the drop-in production adoption release for Phoenix SaaS teams: the release packages the first-hour SaaS onboarding path, Sigra-ready actor capture, operator incident guidance, and published capture baselines into one taggable Hex surface.

### Added

- **SaaS onboarding route** — [`guides/getting-started-saas.md`](guides/getting-started-saas.md) ships as the first-hour Phoenix SaaS path and is now promoted from the package front door.
- **Sigra integration route** — [`guides/integrations/sigra.md`](guides/integrations/sigra.md) ships as the best-supported auth bridge for Sigra-backed Phoenix hosts and is surfaced separately in ExDoc navigation.
- **Published capture baselines** — the cold-single-table benchmark now anchors the release story with `insert` at `4.87 K` IPS / `205.13 µs`, `update` at `4.30 K` IPS / `232.49 µs`, and `delete` at `7.61 K` IPS / `131.39 µs`.
- **Release-surface contract** — `test/threadline/release_artifact_contract_test.exs` locks package files, ExDoc extras/module grouping, guide presence on disk, and release-only README / maintainer literals.

### Changed

- **README install and routing** — the install snippet now targets `{:threadline, "~> 0.3"}` and sends new adopters first to the SaaS quickstart and Sigra guide, with performance and incident docs one step deeper.
- **ExDoc information architecture** — `guides/integrations/sigra.md` now matches an `Integrations` extras group before the broader reference bucket, and `Threadline.Integrations.Sigra` now appears under a new plural `Integrations` module group while Plug / Job / Health / Continuity / Telemetry remain under the singular `Integration` group.
- **Release pre-flight** — `mix verify.release` now validates the exact taggable tree through release metadata checks, pure file-read release contracts, `MIX_ENV=dev mix docs`, and `mix hex.build`.
- **Maintainer publish runbook** — `CONTRIBUTING.md` now documents the `mix verify.release` pre-flight and the `main` CI wait before tagging `v0.3.0`.

### Deprecated

- No runtime API is deprecated in 0.3.0. Older install snippets using `{:threadline, "~> 0.2"}` should be treated as stale documentation, not a supported release target.

### Breaking

- No breaking runtime, dependency, config, or schema changes are introduced in 0.3.0.

### Upgrade from 0.2.x

- **Dependencies:** no runtime dependency changes are required to adopt 0.3.0.
- **Config changes:** none.
- **Migration steps:** none beyond bumping the dependency and re-running your normal dependency fetch/docs sync flow.
- **Sigra adapter:** use `Threadline.Integrations.Sigra.actor_ref_from_conn/1` as the `Threadline.Plug` `actor_fn` when your host already authenticates requests with Sigra.

## [0.2.0] - 2026-04-23

### Added

- **Production checklist** — [`guides/production-checklist.md`](guides/production-checklist.md) for first-week production review (capture, redaction, retention, export, observability, brownfield).
- **`Threadline.Query.timeline_repo!/2`** — resolves `:repo` from filters or opts with clear `ArgumentError` messages for timeline and export callers.
- **ExDoc** — `guides/production-checklist.md` in extras; **`Threadline.Retention`** and **`Threadline.Retention.Policy`** listed under Core API module groups.

### Changed

- **Timeline filter errors** — `validate_timeline_filters!/1` messages now point at allowed keys and `Threadline.Export`.
- **Validation order** — `timeline/2` and export entrypoints validate filter keys before resolving `:repo`, so unknown keys surface before a missing-repo error.

### Release notes (capabilities since 0.1.0)

This minor release documents and packages capabilities shipped after **0.1.0** that were not fully reflected in that changelog entry:

- **Before-values** — optional `changed_from` on UPDATE when triggers are generated with `--store-changed-from`; `Threadline.history/3` loads the column when present.
- **Verify coverage & doc contracts** — `mix threadline.verify_coverage`, CI `verify.threadline` / `verify.doc_contract`, README fixture contracts.
- **Brownfield continuity** — `Threadline.Continuity`, `mix threadline.continuity`, [`guides/brownfield-continuity.md`](guides/brownfield-continuity.md).
- **Redaction at capture** — `config :threadline, :trigger_capture`, per-table `exclude` / `mask`, codegen validation.
- **Retention** — `Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`.
- **Export** — `Threadline.Export`, `Threadline.export_csv/2`, `Threadline.export_json/2`, `mix threadline.export`, shared timeline filter validation.

## [0.1.0] - 2026-04-23

### Added

- `Threadline` core API plus `Threadline.Semantics.ActorRef` and `Threadline.Semantics.AuditContext` for attributing writes to actors in audit context.
- `Threadline.Plug` for resolving `ActorRef` from `Plug.Conn`, plus integration modules `Threadline.Job`, `Threadline.Health`, and `Threadline.Telemetry`.
- `Threadline.Semantics.AuditAction` and `Threadline.Capture` schemas (`AuditTransaction`, `AuditChange`) for PostgreSQL trigger-backed row-change capture.
- Mix tasks `Mix.Tasks.Threadline.Install` and `Mix.Tasks.Threadline.Gen.Triggers` to generate migrations and table-specific audit triggers.
