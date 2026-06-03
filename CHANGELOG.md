# Changelog

## [0.9.0](https://github.com/szTheory/threadline/compare/v0.8.0...v0.9.0) (2026-06-03)


### Features

* **105-01:** add help-desk domain migration ([33a54f6](https://github.com/szTheory/threadline/commit/33a54f6397dba7dd79566232cb4f5f933b242773))
* **105-01:** add HelpDesk Ecto schemas ([c9a690d](https://github.com/szTheory/threadline/commit/c9a690db8d3e061845cf53866262809e0965646a))
* **105-02:** add ticket_replied_and_closed help-desk write path ([c38ad37](https://github.com/szTheory/threadline/commit/c38ad3715aa593d8c8b474f723b830a4c583750b))
* **105-02:** configure help-desk trigger capture and coverage ([d1cfa46](https://github.com/szTheory/threadline/commit/d1cfa46a99dd01a4634f782033342131aafbac50))
* **105-02:** generate help-desk audit triggers ([356dfe0](https://github.com/szTheory/threadline/commit/356dfe0c0ec4b7d4ea5399a896e18c3b13b4adf0))
* **106-01:** add home page and document Sigra walkthrough URLs ([28312e9](https://github.com/szTheory/threadline/commit/28312e9a82f15a13ac7b63b71f0a8efa4ebc073b))
* **106-01:** bootstrap Phoenix HTML stack for Sigra templates ([a476ed1](https://github.com/szTheory/threadline/commit/a476ed1036fce80edbfce1ccd34e3c5407ad31ff))
* **106-01:** install Sigra auth and users migrations ([b50e51e](https://github.com/szTheory/threadline/commit/b50e51e4ffb9f2ff697d8b53982abe6cc9ecd371))
* **106-01:** provision help-desk workspace on Sigra registration ([d3cdc50](https://github.com/szTheory/threadline/commit/d3cdc50e543579402e68165af6ad825e37ea04f7))
* **106-02:** add HelpDesk membership role and org lookup helpers ([b65213e](https://github.com/szTheory/threadline/commit/b65213e6fe86fa6d8f1bc7b82125adb15090d09a))
* **106-02:** add OperatorUser plug mapping Sigra scope to current_user ([2f7e6aa](https://github.com/szTheory/threadline/commit/2f7e6aa8c248345d318bc2ab66cfd8888d29c6f5))
* **106-02:** wire operator_browser pipeline and login workspace safety-net ([2348720](https://github.com/szTheory/threadline/commit/2348720b29c07627414672ad5466d0d5aa3ca0fa))
* **106-03:** add HTTP help-desk audit capture proof route ([20d9916](https://github.com/szTheory/threadline/commit/20d99161cb1dd3eb371cbea26aabd38c0ff11f1a))
* **106-03:** add login_via_sigra/2 ConnCase helper ([8c3e372](https://github.com/szTheory/threadline/commit/8c3e372cac5134370b1389b832c07b57f64a79f3))
* **106-03:** migrate operator surface tests to login_via_sigra ([90eded2](https://github.com/szTheory/threadline/commit/90eded237ce568f7169c95f067e300771ddc553c))
* **107-01:** add Demo.Manifest contract module ([a073b97](https://github.com/szTheory/threadline/commit/a073b9714d7b6521c19a09997528fc722f9c0abd))
* **107-02:** add HelpDesk.delete_reply/3 with audit capture ([5df28f3](https://github.com/szTheory/threadline/commit/5df28f3b513136beb7341b24f12c4148d2f8dd50))
* **107-02:** add mix demo.reset with prod guard and Seed stub ([52d9491](https://github.com/szTheory/threadline/commit/52d9491bb3ded8ea493ad81c6a0ba9a0e16b0350))
* **107-02:** centralize demo truncate SQL in Demo.Tables ([91b19d2](https://github.com/szTheory/threadline/commit/91b19d288e53c2d26b989aafc99a28fb10413e1f))
* **107-03:** add mix demo.seed orchestrator and shared seed helpers ([f1bc720](https://github.com/szTheory/threadline/commit/f1bc72068fee7eceb314f50ce583445358b97f30))
* **107-03:** backfill audit occurred_at and captured_at from manifest ([cb5c420](https://github.com/szTheory/threadline/commit/cb5c4206af75e57d901e1444ada91042ef12a607))
* **107-03:** seed anchor incidents for tickets 4521 and 4518 ([b3a2d9d](https://github.com/szTheory/threadline/commit/b3a2d9dd5c835794ac871f0ef4cca42d44361ad8))
* **107-03:** seed PRNG filler tickets per organization ([f9fc7df](https://github.com/szTheory/threadline/commit/f9fc7df0d140c01b6aa4959e540787a370f59f9b))
* **107-03:** seed Sigra personas and manifest org memberships ([fb87560](https://github.com/szTheory/threadline/commit/fb875602fa2bc0c092aa24eaad0e42a59cb311d0))
* **107-04:** org Y retention tail and governance tables ([eab3514](https://github.com/szTheory/threadline/commit/eab3514a220b9d4cd1644e0cf0905cd9737fa1eb))
* **108-01:** add redaction policy evidence subject ref to demo manifest ([b01accb](https://github.com/szTheory/threadline/commit/b01accb254bf9f16b8ae7f9fc4f8a5efa74310d6))
* **108-01:** seed redaction_policy evidence and contract test ([1e15b25](https://github.com/szTheory/threadline/commit/1e15b2518dde900ad34da0313b795d9294a28728))
* **108-02:** README.md decision tree and routing ([dc2f9c4](https://github.com/szTheory/threadline/commit/dc2f9c4d2ccddfe4547caaea7e565f5b7c89d77b))
* **108-02:** TEMPLATE.md with YAML frontmatter lite ([90eedea](https://github.com/szTheory/threadline/commit/90eedeaa630fbd450606f1a8d14cae8f65a23a93))
* **108-03:** §1–§3 walkthrough steps with WALK-01/02 IDs ([81ad55c](https://github.com/szTheory/threadline/commit/81ad55c3c7c75b2665d8cdef7e66c0278cfaa44f))
* **108-03:** WALKTHROUGH.md file + §0 header block ([5822fe5](https://github.com/szTheory/threadline/commit/5822fe5774140c382d4d28f0d8d454f889b29282))
* **108-04:** add WALKTHROUGH §4 four operator incident playbooks ([cedf21e](https://github.com/szTheory/threadline/commit/cedf21e6744a5bfdb03a52ef6a772830950dcb03))
* **111-01:** add Threadline.Audit.transaction/3 audited write helper ([157b5fa](https://github.com/szTheory/threadline/commit/157b5fa6d7674e65452a0f7968927ca674d14411))
* **112-01:** persist transaction_meta on capture-only audit path ([6c1d526](https://github.com/szTheory/threadline/commit/6c1d52690e60156ce28fcf59cc40f877a8a35360))
* **112-02:** migrate Blog.create_post to Audit.transaction helper ([7541be2](https://github.com/szTheory/threadline/commit/7541be2295b240a99862c89ef458f265585929eb))
* **112-03:** migrate HelpDesk writes to Audit.transaction helper ([52debfc](https://github.com/szTheory/threadline/commit/52debfc4760c6602aab7df888be8bee43e4b24f8))
* **112-04:** migrate Oban touch path and README helper cross-links ([092489e](https://github.com/szTheory/threadline/commit/092489ee884090279872f8017b4892e42b7608e2))
* **114-01:** bump [@version](https://github.com/version) to 0.6.0 ([8e9d3ec](https://github.com/szTheory/threadline/commit/8e9d3ec8689863ff357590f2ed6cc1efcf7bdd13))
* **114-01:** cut CHANGELOG [0.6.0] release section ([704eda6](https://github.com/szTheory/threadline/commit/704eda6522518150a8182bdb6520fa41cef78c88))
* **114-01:** extend ExDoc groups and lock Evidence plane in contract test ([f652037](https://github.com/szTheory/threadline/commit/f652037427d9d507742265e677a470c83ba1f01d))
* **114-02:** update install snippets to ~&gt; 0.6 across adopter surfaces ([a69c0df](https://github.com/szTheory/threadline/commit/a69c0df45b4d0545c9944f1f349a77565835169d))
* **114-03:** refresh CONTRIBUTING release runbook to v0.6.0 ([c78abaa](https://github.com/szTheory/threadline/commit/c78abaa6f79d2a0be9fec65ea522bff671443cf1))
* **116-01:** add session plugs to example :api pipeline ([5fe306b](https://github.com/szTheory/threadline/commit/5fe306bf9671fba662b6fb55aeb36b07087a88d4))
* **119-01:** add operator surface, semantics, and non-goals sections ([4867a42](https://github.com/szTheory/threadline/commit/4867a423452378ed2d296df6ed5ba26b5962631b))
* **119-01:** add phx-gen-auth guide skeleton and prerequisites ([90d033b](https://github.com/szTheory/threadline/commit/90d033bc138ccb83d8d11e602c281b007936012e))
* **119-01:** add plug wire-up and host AuditActor template ([375f064](https://github.com/szTheory/threadline/commit/375f0646dbdf58bc6287c01e9e47cdb3d092943c))
* **123-01:** add Configure Threadline subsection to getting-started ([7b929a1](https://github.com/szTheory/threadline/commit/7b929a17963b01b09cd1c51d0972f77cce73927a))
* **123-02:** add Host repo wiring prerequisite to production checklist ([a07775d](https://github.com/szTheory/threadline/commit/a07775dd039aa3dedfa6b40eca21f3c6bf80bd5f))
* **127-01:** wire :schemas mount and sync operator-surface doc snippets examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex guides/getting-started-saas.md examples/threadline_phoenix/README.md .planning/phases/127-example-app-schemas-demonstration/127-01-SUMMARY.md ([17507ba](https://github.com/szTheory/threadline/commit/17507ba958215b86c761d1e4b613ab5193bdd502))
* **128-02:** add PhxGenAuthReference.Audit mirroring guide module ([2836be1](https://github.com/szTheory/threadline/commit/2836be141df0e5c2547a9fb91f9478cf35431213))
* **95-01:** add evidence record schema, migration, and DDL ([936e21c](https://github.com/szTheory/threadline/commit/936e21cd8708d9dcd2e2dea07f5e8cbb2de6e674))
* **95-02:** add closed evidence subject inventory ([ea9a2dc](https://github.com/szTheory/threadline/commit/ea9a2dcd0e1300e96bab9051508a6bc14b76eb41))
* **96:** apply overview limit across combined subject inventory ([62b0104](https://github.com/szTheory/threadline/commit/62b0104266b92cdbef0ee2332432ccaf449920db))
* **97-02:** classify evidence proof verdicts ([e38e164](https://github.com/szTheory/threadline/commit/e38e164c13ce0585149c0fcf054622df8b27276b))
* **97-02:** expand evidence proof presentation and Mix-task validation ([ba488f3](https://github.com/szTheory/threadline/commit/ba488f3a69f8bad88a0773ac4e0095b65e73bb70))
* **98-01:** mount read-only evidence view on /audit surface ([55e7c3e](https://github.com/szTheory/threadline/commit/55e7c3ebcf8b1540286c6d24c09a064160cc9c7a))
* **98-02:** mounted/API/CLI parity and host-owned authz wiring ([ccc77c9](https://github.com/szTheory/threadline/commit/ccc77c90243ce504fa2d5c1ed8f6f56dcae5c908))
* **99-02:** lock evidence-plane wording with doc-contract tests ([b707a87](https://github.com/szTheory/threadline/commit/b707a87558b0c29b0acdfc909f5004420aa1f240))
* **release:** shift-left Hex publish and distribution doc sync ([81dc17b](https://github.com/szTheory/threadline/commit/81dc17b005448c3ca97446918ad9798068ded0ca))


### Bug Fixes

* **106:** bind dev ticket_reply to organization ([333a729](https://github.com/szTheory/threadline/commit/333a7297b1c9007039a1ce35cd24f514fc64a3ff))
* **106:** halt login when workspace provisioning fails ([e2e51a6](https://github.com/szTheory/threadline/commit/e2e51a6c5f049cf2ed41734885e2edf8ad64173c))
* **107:** remove unused Ecto.Query import; mark phase complete in tracking ([60475aa](https://github.com/szTheory/threadline/commit/60475aa13e6394140ed2c8a4150b628cd689699f))
* **114-03:** align example operator mount with getting-started evidence gate ([7d2dbcf](https://github.com/szTheory/threadline/commit/7d2dbcf51870bae93ffb1f6a6a6e107935dcb4fe))
* **115-02:** wire audit_doc_contract into verify.doc_contract ([e8f5176](https://github.com/szTheory/threadline/commit/e8f517695b7f3c1541cd7ae38d759457948bc36a))
* **116-01:** stage sigra_conn via session token for :api plugs ([70b8557](https://github.com/szTheory/threadline/commit/70b855778186a748c4c61b9b494b1a67186caa10))
* **119:** register phx-gen-auth guide in ExDoc extras allowlist ([f2c074e](https://github.com/szTheory/threadline/commit/f2c074e03013db75d17478e03b26ea5273a019d2))
* **130-02:** format phx_gen_auth_integration_test for ci.all gate ([e04f275](https://github.com/szTheory/threadline/commit/e04f275cd3bd123ae18f192da73f6da332aa1285))
* **99-02:** update ci.all topology contract to expanded doc_contract alias ([b636c17](https://github.com/szTheory/threadline/commit/b636c17beb234f1dbb3b7c3f1e30d3cbd0e8a989))
* **examples:** align WALK-03-02 window and WALK-03-03 CLI (findings 0002, 0003) ([8dfcb87](https://github.com/szTheory/threadline/commit/8dfcb87b8405ca232c0d114bf02844aa71b54d30))
* **examples:** nil-safe current_scope on landing (finding 0001) ([7b9e46b](https://github.com/szTheory/threadline/commit/7b9e46b5b90c5da7f64c88ae539e8390f8734826))
* **example:** use Jason.encode! for Elixir 1.17 CI compatibility ([2555247](https://github.com/szTheory/threadline/commit/25552479843c1c6e4f8386e46ff22ad3397de313))
* **guides:** align SaaS quickstart mount pipe_through with Phase 106 router ([52b862a](https://github.com/szTheory/threadline/commit/52b862a4c267d4abbd1677c42c3f6c33514dd542))
* operator timeline crash on correlation_id filter (+ release-please changelog guard) ([43a6f23](https://github.com/szTheory/threadline/commit/43a6f2364feb3a285c15b13a68f35f905bc8a0d5))
* **operator-surface:** prevent timeline crash on correlation_id filter ([d62e509](https://github.com/szTheory/threadline/commit/d62e509e932b3b85b1749a13745b510ad78c0042))
* **release:** run publish chain when release-ref succeeds via dispatch ([19c7549](https://github.com/szTheory/threadline/commit/19c7549d64f67f34329566590ebf45eca96223a7))
* **release:** split dispatch bootstrap from release-please path ([136b650](https://github.com/szTheory/threadline/commit/136b650d6a96a11db1987811803d6a6c8ebd7b5e))
* **release:** use hex.build preflight instead of verify.release in CI ([d4413ef](https://github.com/szTheory/threadline/commit/d4413efe783779554a8d9b39d395034d0dea405f))
* **test:** align README proof-artifact contract with 108-05 copy ([93ad9b9](https://github.com/szTheory/threadline/commit/93ad9b99a448e3955da4d04e383f76a34fda7408))

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
