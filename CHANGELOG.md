# Changelog

## [0.10.0](https://github.com/szTheory/threadline/compare/v0.9.0...v0.10.0) (2026-06-07)


### Features

* **135-01:** add named non-human actor literals to Manifest (D-06) ([37fd4de](https://github.com/szTheory/threadline/commit/37fd4de12f9bd758ef341cb29825584479b3282a))
* **135-01:** fix D-05 — persona/setup rows get :admin actor + backdate 21d before epoch (GREEN) ([098e8a8](https://github.com/szTheory/threadline/commit/098e8a83cef39a4b03eac31c77ed8525502a096b))
* **135-01:** generalize Support actor helpers to all ActorRef kinds (D-07) ([9fa676b](https://github.com/szTheory/threadline/commit/9fa676bbd9eddd19b21d65078d4e778e8253b095))
* **135-03:** add seed_variety_pack/1 — in-window 5/4/2 op mix with multi-kind actors (D-10/11/12/14) + D-13 assertion ([878f5e9](https://github.com/szTheory/threadline/commit/878f5e9ac32dabb406d32ae816bfe53c1ee20e72))
* **135-03:** seed SavedView rows for admin actor_ref (F-204 data) ([912919f](https://github.com/szTheory/threadline/commit/912919fe7b13d6bb069058ee1156857ccdcb9680))
* **135-03:** shift filler corpus op-mix toward 55/35/10 via DELETE branch (D-11) ([1ffd0ae](https://github.com/szTheory/threadline/commit/1ffd0ae4b7b7a0188ef64eb68c26f93026311d15))
* **137-01:** add prove presentation primitives ([7b9e034](https://github.com/szTheory/threadline/commit/7b9e034878462f3bef626ed226ec55f79842be6d))
* **137-02:** group exports by readiness ([8e839d4](https://github.com/szTheory/threadline/commit/8e839d466476b6a6b74317cbc5d2ee5b44759781))
* **137-03:** make retention prune context first ([7a4a513](https://github.com/szTheory/threadline/commit/7a4a51390258c6438cf6c49a3501a9f4ac0f77e7))
* **137-04:** align evidence and redaction proof polish ([e123009](https://github.com/szTheory/threadline/commit/e1230096a417a0e12abf53b25ba635ed47ad36f3))
* **138-01:** add find css primitives ([16bd29a](https://github.com/szTheory/threadline/commit/16bd29a8703830d464a817c5ffac7526840c1b5f))
* **138-01:** implement find presentation helpers ([3ef67a8](https://github.com/szTheory/threadline/commit/3ef67a8be1f3414610c568065740955c7a303979))
* **138-02:** render row history snapshots with value tokens ([fed7438](https://github.com/szTheory/threadline/commit/fed7438e979f7907af56c0c5a4f7b4aaa7d6132d))
* **138-02:** render transaction diffs with semantic values ([1f02175](https://github.com/szTheory/threadline/commit/1f021754db778df4842441861e82091fe075cbb7))
* **138-03:** polish Timeline dense and recovery states ([3e8eca6](https://github.com/szTheory/threadline/commit/3e8eca61727c4890a953748261b0ca7077e8d9a2))
* **138-04:** add scope-safe actor row summaries ([9967025](https://github.com/szTheory/threadline/commit/9967025f83086a495cc4f94b0aa5f2ac2bf0cedb))
* **138-04:** make coverage rows remediation first ([2a55372](https://github.com/szTheory/threadline/commit/2a55372d079594c1d7cd1e798209d3c56350f612))
* **139-01:** add surface header nav handoff primitives ([84d7576](https://github.com/szTheory/threadline/commit/84d7576daf551c75d91b780b98deb74320d4da77))
* **139-02:** polish home orientation hub ([1ce7184](https://github.com/szTheory/threadline/commit/1ce71845cc5f14983ecdebdd387a83fa448e68c5))
* **140-01:** mount first-class row history ([457ee36](https://github.com/szTheory/threadline/commit/457ee366a46caac1174ba558af41c86a26e6c574))
* **140-02:** add home earned-flow shortcuts ([11e2a09](https://github.com/szTheory/threadline/commit/11e2a09f4e6b8cd5ecab49a3bee8fbbfb6a5a8b5))
* **140-03:** carry timeline filters into exports ([e4d84d6](https://github.com/szTheory/threadline/commit/e4d84d6c87dd8e6ac04827af992d2c012bc7ce3f))
* **140-04:** carry evidence proof context into exports ([b56c065](https://github.com/szTheory/threadline/commit/b56c06562ff840200db76bb447e8a7602c7c14c7))
* **142-01:** tokenize responsive breakpoint scale ([4f13cf0](https://github.com/szTheory/threadline/commit/4f13cf0a45f0da72fa3bf3a514f71127a02fdc9d))
* **144-02:** add shared operation presentation helpers ([a8c6eec](https://github.com/szTheory/threadline/commit/a8c6eecdf961df5ece2aa6c7f57b1e8b2e16ccc9))
* **144-03:** mark design-system token freeze source ([c232115](https://github.com/szTheory/threadline/commit/c2321151442c3b5f6c507450124ae5c970274351))
* isolate Threadline storage schema ([a837aac](https://github.com/szTheory/threadline/commit/a837aaca8acbedeec925446b49a5f101df2bd945))


### Bug Fixes

* **135:** CR-01 extend idempotency to variety pack no-DML stories ([c24203d](https://github.com/szTheory/threadline/commit/c24203dfe4239d9970ceec2a9ea899f8a72dc820))
* **135:** CR-01 guard seed_memberships against no-DML re-seed crash ([610361c](https://github.com/szTheory/threadline/commit/610361cf969d3f0c9076219fe140af278fd0a5b7))
* **135:** CR-02 correct DEMO-MANIFEST membership operation descriptions ([708008e](https://github.com/szTheory/threadline/commit/708008e8cb97c19b79576f8354be0a1ecb0c9b13))
* **135:** WR-01/WR-02 remove dead ref scaffolding and rename misleading variable ([28741a6](https://github.com/szTheory/threadline/commit/28741a6bbaa99fbceb713052e485c7feff79d36f))
* **138:** constrain coverage remediation commands ([5791e1a](https://github.com/szTheory/threadline/commit/5791e1aa64e257ce6adc2cf1f77e852b3dbfa74d))
* **139:** enforce mobile viewport for operator e2e ([f319ecc](https://github.com/szTheory/threadline/commit/f319ecc1cde123a9f865a7351f8d755f86861515))
* **139:** preserve scoped home header state ([1786677](https://github.com/szTheory/threadline/commit/178667783e2e56aa1e24a838bac471df1553c751))
* **139:** revise plans based on checker feedback ([7d7aa1b](https://github.com/szTheory/threadline/commit/7d7aa1bf3fd61b8d41f4fbb5cb415b82ecf2b175))
* **140:** close earned-flow review findings ([e064898](https://github.com/szTheory/threadline/commit/e064898fa8f66fb15f87f248c37ccc739ef1d38b))
* **140:** mark research questions resolved ([735e7eb](https://github.com/szTheory/threadline/commit/735e7ebc2c852ab8edd9bbdad4a2b65c3e9ac2e9))
* **140:** resolve earned flow planning questions ([ab4d1b2](https://github.com/szTheory/threadline/commit/ab4d1b27b9fc8cc3deeb554732b825c71018ebed))
* **140:** wire liveview assets for earned-flow e2e ([5cc0983](https://github.com/szTheory/threadline/commit/5cc09832b7e3f7e94a88e17a75827b896d48a71d))
* **141-03:** enforce motion preference emulation in spec ([65eece2](https://github.com/szTheory/threadline/commit/65eece2d779b3aaf6eb1f86a6fecbeeb2b8d7c23))
* **141:** use valid motion transition longhands ([8b8b913](https://github.com/szTheory/threadline/commit/8b8b913d286280a55b26bb4a9119e053eaea5cbb))
* **143:** make screenshot snapshots portable ([f771160](https://github.com/szTheory/threadline/commit/f771160ed6313eaaea682c91b954378a4fc233b6))

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

* **123-01:** add Configure Threadline subsection to getting-started ([7b929a1](https://github.com/szTheory/threadline/commit/7b929a17963b01b09cd1c51d0972f77cce73927a))
* **123-02:** add Host repo wiring prerequisite to production checklist ([a07775d](https://github.com/szTheory/threadline/commit/a07775dd039aa3dedfa6b40eca21f3c6bf80bd5f))
* **127-01:** wire :schemas mount and sync operator-surface doc snippets examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex guides/getting-started-saas.md examples/threadline_phoenix/README.md .planning/phases/127-example-app-schemas-demonstration/127-01-SUMMARY.md ([17507ba](https://github.com/szTheory/threadline/commit/17507ba958215b86c761d1e4b613ab5193bdd502))
* **128-02:** add PhxGenAuthReference.Audit mirroring guide module ([2836be1](https://github.com/szTheory/threadline/commit/2836be141df0e5c2547a9fb91f9478cf35431213))


### Bug Fixes

* **130-02:** format phx_gen_auth_integration_test for ci.all gate ([e04f275](https://github.com/szTheory/threadline/commit/e04f275cd3bd123ae18f192da73f6da332aa1285))
* operator timeline crash on correlation_id filter (+ release-please changelog guard) ([43a6f23](https://github.com/szTheory/threadline/commit/43a6f2364feb3a285c15b13a68f35f905bc8a0d5))
* **operator-surface:** prevent timeline crash on correlation_id filter ([d62e509](https://github.com/szTheory/threadline/commit/d62e509e932b3b85b1749a13745b510ad78c0042))
* **release:** run publish chain when release-ref succeeds via dispatch ([19c7549](https://github.com/szTheory/threadline/commit/19c7549d64f67f34329566590ebf45eca96223a7))
* **release:** use hex.build preflight instead of verify.release in CI ([d4413ef](https://github.com/szTheory/threadline/commit/d4413efe783779554a8d9b39d395034d0dea405f))

## [Unreleased]

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
- Use `mix threadline.evidence.show` (not deprecated `mix verify.evidence` naming) for CLI proof export.
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
- **`Threadline.Health.Policy.validate!/1`** — pure-stdlib config validator mirroring `Threadline.Capture.RedactionPolicy.validate!/1`. Validate at boot to fail loud on bad config.
- **`[:threadline, :health, :checked]` event metadata** gains `expected_uncovered` measurement key (additive). Old subscribers reading only `covered`/`uncovered` keep working unchanged.
- **`[:threadline, :health, :checked, :error]` sibling event** for polled coverage check failures.
- **`mix threadline.verify_coverage --schema=NAME`** additive flag with the same edge validation contract as the new Mix task. Default behavior unchanged.

### Changed

- **Release metadata** — install snippets now target `{:threadline, "~> 0.5"}`, ExDoc names the operator surface `Optional In-Tree`, and the release/audit artifacts record v1.19 as the integration-breadth closeout milestone.
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

This minor release documents and packages capabilities shipped across the **v1.1–v1.3** planning cycles that were not fully reflected in the **0.1.0** changelog entry:

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
