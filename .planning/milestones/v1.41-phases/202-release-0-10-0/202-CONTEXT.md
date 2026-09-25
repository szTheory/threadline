# Phase 202: Release 0.10.0 - Context

**Gathered:** 2026-09-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish threadline 0.10.0 to hex.pm with a public surface Phases 200 and 201
already made clean, every version-bearing line managed by release automation,
and a changelog an adopter can read. Covers RELEASE-01..05.

Four research areas were investigated before planning. Their findings changed
the shape of this phase substantially: PR #26 is **born red for four distinct
reasons**, one of which is a silent breaking change for every existing adopter
that every automated gate would have passed.

In scope: making the release PR green by construction, the publish pipeline's
gates, the human-readable changelog, the upgrade guide, and what the tarball
contains.

Out of scope: new capture/semantics/exploration features; the `.planning/`
divergence between local and `origin/main`; Phase 203's gate work.
</domain>

<decisions>
## Implementation Decisions

### Storage schema default (the release-blocking one)

- **D-01:** Flip `Threadline.StorageSchema` `@default` from `"threadline"` to
  `"public"`; a dedicated schema becomes explicit opt-in via
  `config :threadline, storage_schema: "threadline"`.
  — **Reversibility:** one-way — once 0.10.0 publishes with a given default,
  changing it again breaks whichever population did not set the key. hex.pm has
  no unpublish beyond a ~1 hour revert window, and HexDocs are permanent.

  **Why.** `lib/threadline/storage_schema.ex` is new in 0.10.0 (verified absent
  at `v0.9.0`) and is threaded through `audit`, `evidence`, `query`,
  `retention`, and `continuity`. It cannot detect the schema an adopter
  actually installed into. A 0.9.x adopter on `public` who upgrades gets every
  read path prefixed `threadline.*` — tables that do not exist — while their
  already-deployed, unqualified triggers keep writing to `public`. Capture
  continues; exploration breaks. That is a split-brain failure in an audit
  library, the exact outcome the product exists to prevent.

  Flipping the default converts 0.10.0 from breaking to non-breaking for the
  entire existing population, and honours this repo's own surface deprecation
  policy, which a breaking default violates.

  **Verified clean:** `config/test.exs:50` and
  `examples/threadline_phoenix/config/config.exs:16` both set
  `storage_schema: "threadline"` EXPLICITLY, so the flip does not alter this
  repo's own tests or example app. It changes behaviour only for consumers who
  do not set the key — precisely the pre-0.10 population.

- **D-02:** New installs must be steered to opt in. `mix threadline.install`,
  the installer docs, and `guides/getting-started-saas.md` need to present the
  dedicated schema as the recommended choice for a NEW install, since the
  default no longer provides isolation.

- **D-03:** Add an end-to-end test proving a legacy `public`-schema install
  reads green on 0.10.0. Today only unit tests exercise
  `storage_schema: "public"` at the SQL/opts level; nothing encodes what a 0.9
  install looks like, which is why every gate would have passed a release that
  broke it. The hex evaluator fixture is the natural home (see D-08).

### Version-bearing lines (RELEASE-02)

- **D-04:** Install pins keep the contract's `major.minor.0` derivation. A new
  `mix release.pins` task rewrites the six pins in `README.md` + `guides/**`
  from `@version`; `version_truth_doc_contract_test.exs` remains the gate.
  Pins are NOT added to release-please `extra-files`.

  **Why, verified:** release-please's generic updater writes the FULL version
  onto a marked line, so `x-release-please-version` would emit `~> 0.10.1` on a
  patch release while the contract derives `~> 0.10.0`. Component markers
  (`x-release-please-minor`) replace the first bare integer on the line, which
  inside `{:threadline, "~> 0.9.0"}` is the leading `0` — producing
  `~> 10.9.0`. Both are dead ends.

  Two-segment pins (`~> 0.10`) were considered and REJECTED: measured with
  `Version.match?`, `~> 0.10` admits `0.99.0`, so for a pre-1.0 library it
  would silently admit future breaking minors into an adopter's `mix.exs`.
  `~> 0.10.0` admits the whole `0.10.x` patch series and stops at the minor,
  which is the correct floor.

- **D-05:** RELEASE-02's wording narrows to: no version-bearing line requires a
  HAND edit; the minor-release pin bump is produced by `mix release.pins` and
  enforced by contract. Patch releases stay genuinely zero-edit because the
  derivation is patch-invariant (the task is a provable no-op).

- **D-06:** STRENGTHEN the contract: assert that no line carrying a
  `{:threadline, "~> …"}` pin also carries an `x-release-please-version`
  marker. Today that rule lives only in a code comment. This promotes
  "release-please must never own a pin line" from remembered convention to
  enforced invariant.

### Hex evaluator (RELEASE-03)

- **D-07:** Remove the version literal from `priv/ci/hex_evaluator` entirely.
  Mode-switch its dep: rehearsal mode (default) resolves from a throwaway local
  registry built by `mix hex.registry build` from this tree's own `mix hex.build`
  tarball; published mode (set only by `release.yml`) uses `== <version>` from
  hexpm. Exact match, not `~>` — `~> 0.9.0` is precisely what let 0.9.0 keep
  silently passing, and `~> 0.10.0` would drift onto 0.10.1 the same way.

- **D-08:** `priv/ci/hex_evaluator/mix.lock` is committed and pins
  `threadline 0.9.0` from `hexpm` with a checksum — a second stale artifact
  beyond the mix.exs pin. It must be untracked and gitignored; this fixture's
  job is resolvability, not reproducibility. Record that as a decision in the
  file header, not as an omission.
  NOTE for planning: confirm the exact Mix behaviour when a locked version no
  longer satisfies a changed requirement before relying on any "the lock
  overrides" framing — that claim was NOT verified in discussion.

- **D-09:** A new `smoke-published` job in `release.yml` (stable job id),
  NOT in `ci-required`. `ci-required`'s `allowed-skips`/`allowed-failures` stay
  empty — that empty list is the standing tell that nothing has been laundered.
  A post-publish job inside `ci.yml` would be a conditionally-skipped member on
  every PR, and GitHub scores a skip as passing.

- **D-10:** `distribution-sync` gains `needs: smoke-published`. Never attest a
  published artifact that has not been proven to install.

### Changelog (RELEASE-04)

- **D-11:** Split ownership by FILE. release-please's `changelog-path` points at
  a new bot-owned `CHANGELOG-GENERATED.md`; `CHANGELOG.md` becomes fully
  human-owned and is the file shipped in the tarball.
  — **Reversibility:** costly — changing it back after publishing means the
  published `Changelog` package link and the file adopters read swap meaning
  between versions.

  **Why, measured:** 317 releasable subjects since `v0.9.0`; **40** of them trip
  `release_artifact_contract_test.exs`'s actual regexes (15 `D-\d{2,}`,
  24 requirement IDs, 3 `v1.4x` milestone literals). `CHANGELOG.md` is in
  `package.files`, so merging PR #26 as-is ships internal planning vocabulary to
  hex.pm AND turns `mix test` red on the release commit. History is immutable,
  so commit-message policing is not available; the prevention must be
  structural.

- **D-12:** Highlights accumulate under a standing `## Unreleased — highlights`
  block in `CHANGELOG.md` as each phase lands, retitled at release time. Do NOT
  use `## [Unreleased]` — the `[` matches release-please's version-header regex.
  An orphaned `## [Unreleased]` block currently stranded below `0.7.0` carries
  real adopter content and should be folded in and deleted.

- **D-13:** Section order: breaking changes and required action ABOVE the
  feature tour. An upgrader's first two questions are "will this break me" and
  "what must I do". An explicit "None" beats omission, which reads as oversight.

- **D-14:** Measured fact for the 0.10.0 entry: **0 `BREAKING CHANGE` footers
  and 0 `!` subjects** across all 317 commits. Combined with D-01, "Breaking
  changes: none" becomes TRUE rather than asserted — but the entry must still
  document the S3 dependency swap and the operator-surface routes (D-16), which
  the current `[Unreleased]` block covers neither of.

### Upgrade path and publish gate (RELEASE-01, RELEASE-05)

- **D-15:** `guides/upgrade-path.md:89` currently states existing installs need
  no storage-schema action. Under D-01 that becomes true, but it is stated in
  the wrong era section and must be re-scoped to the 0.10.x bump rather than
  left implying the 0.6–0.9 era settled it.

- **D-16:** The `0.9.x -> 0.10.x` row must still document genuine adopter
  actions that D-01 does not remove:
  1. S3 export adopters: `:hackney` → `{:req, "~> 0.7"}`, and the `:ex_aws`
     floor rose `~> 2.4` → `~> 2.7` (a raised floor, not additive) — VERIFIED.
  2. Operator-surface mounters: new `POST <path>/theme` and
     `<path>/rows/:table/:record_id` routes must pass any method allowlist,
     proxy rule, or CSP in front of `/audit`.
  3. Custom `Threadline.Storage` adapters: `c:put/2` narrowed to binary content
     (Dialyzer-visible, no runtime change).
  4. ~23 implementation modules became `@moduledoc false` — callable, but not a
     supported surface from 0.10 on.

- **D-17:** Keep the existing `production-hex` environment human approval,
  exactly where it is — after `gate-ci-green`, immediately before
  `mix hex.publish`. Argued from irreversibility: every other gate answers "is
  the artifact well-formed"; a human answers "is this the release I meant to
  make, from this SHA". Document it honestly as a CONFIRMATION step, not peer
  review — with a single maintainer and `prevent_self_review: false` it is not
  four-eyes.

- **D-18:** Add `bin/verify-environment-protection` (modelled on
  `bin/verify-branch-protection`, fail-closed). Today only
  `release_control_plane_contract_test.exs:12` asserts the YAML line; nothing
  asserts the GitHub-side rule still exists, so deleting the required reviewer
  leaves the gate green and inert. That is the vacuous-gate shape this repo has
  now hit three times.

- **D-19:** Document the recovery procedure BEFORE publishing, so it is a
  procedure rather than a decision made under pressure: within ~1 hour,
  `mix hex.publish --revert`; after that, `mix hex.retire` (which warns but does
  NOT remove the tarball, break existing lockfiles, or move anyone already
  pinned) plus a same-day patch. Removal beyond retirement is a support request
  and should be planned as unavailable.

### Tarball contents

- **D-20:** Narrow `mix.exs` `files:` to exclude maintainer-only tooling:
  `lib/mix/tasks/critic.*`, `lib/threadline/critic_trust/`, and the
  operator-surface stress/mechanical harness (~5,000 lines). Add a contract
  assertion that they stay out.
  — **Reversibility:** one-way for anything already published — a shipped file
  cannot be withdrawn from a published version.

  **Why, verified:** `lib/mix/tasks/critic.measure.ex` and `critic.synth.ex`
  both carry `@shortdoc`, so once published they appear in EVERY adopter's
  `mix help` under a non-`threadline.` namespace.

### Claude's Discretion

Mechanism details left to research/planning: the exact `mix release.pins`
implementation and whether it shares a derivation module with the contract (the
advisor recommended deliberate duplication, self-policed by CI); the rehearsal
registry's CI wiring; retry/backoff shape for hex.pm CDN propagation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### This phase's measured findings
- `.planning/phases/202-release-0-10-0/RELEASE-BLOCKERS.md` — the born-red
  analysis, measured by simulating the version bump

### Contracts that gate this phase
- `test/threadline/version_truth_doc_contract_test.exs` — Families A/B/C; the
  `major.minor.0` derivation is deliberate (T-191-03)
- `test/threadline/release_artifact_contract_test.exs` — the archive vocabulary
  and packaging guard; its regexes are at lines 6-11
- `test/threadline/upgrade_path_doc_contract_test.exs` — structural themes
- `test/threadline/release_control_plane_contract_test.exs` — line 12 asserts
  only the YAML line (see D-18)

### Release pipeline
- `.github/workflows/release.yml` — `release-please`, `bootstrap-release-pr-ci`,
  `dispatch-bootstrap`, `release-ref`, `gate-ci-green`, `publish-hex`
  (`environment: production-hex`), `distribution-sync`
- `.github/workflows/ci.yml` — the `ci-required` and no-path-filter headers
  explain why a skipped required member launders a pass
- `.github/workflows/branch-protection.yml` — the precedent for a live-state
  check living outside `ci-required`
- `bin/verify-release-shape`, `bin/post-publish-distribution-sync` (its header
  documents the existing release-please ownership split),
  `bin/verify-branch-protection` (model for D-18)
- `release-please-config.json`, `.release-please-manifest.json`

### Subject code
- `lib/threadline/storage_schema.ex` (`@default` at line 10),
  `lib/threadline/capture/trigger_sql.ex`
- `priv/ci/hex_evaluator/mix.exs` (line 27), `priv/ci/hex_evaluator/mix.lock`
- `mix.exs` — `package.files` allowlist, `aliases/0`, `verify_hex_evaluator/1`
- `guides/upgrade-path.md` (lines 89, 96-113)

### Project standards
- `prompts/threadline-elixir-oss-dna.md` — honest reporting over green dashboards
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md`
- `CLAUDE.md` — named `verify.*`/`ci.*` entrypoints, stable CI job ids, doc
  contract tests, the trigger-backed capture boundary

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/verify-branch-protection` — the fail-closed live-GitHub-state verifier
  pattern D-18 should copy, including its explicit handling of fields the
  default Actions token cannot read.
- `.github/workflows/branch-protection.yml` — the precedent for a live-state
  check that deliberately sits OUTSIDE `ci-required`.
- `mix hex.registry build` — confirmed present in this toolchain; Hex's
  equivalent of Verdaccio/TestPyPI, and the basis for D-07's rehearsal.
- The `dry_run` dispatch input already wired into `release.yml`, and
  `mix hex.publish --dry-run`.

### Established Patterns
- Contract tests guard WIRING, not just content (the
  `post-publish-distribution-sync` header is the precedent) — D-06, D-18 and
  D-20's assertions all follow it.
- `package.files` is an explicit allowlist, not a wildcard, so anything new is
  excluded by default — which is what makes D-11 safe.

### Integration Points
- `gate-ci-green` is the publish gate; every member must be satisfiable
  PRE-publish (this is why D-07 splits rehearsal from published mode).
- `distribution-sync` writes the Hex attestation row and must move behind
  `smoke-published` (D-10).

</code_context>

<specifics>
## Specific Ideas

- Publishing must not be gated on anything that can only become true after the
  publish. Stated as the organising constraint for the whole pipeline.
- The user's standing preference, applied throughout: research broadly, return
  ONE coherent recommendation rather than an option menu.
- Three vacuous gates have now been found in this repo within a week (the
  ungrouped-module grouping assertion, the critic-reader adapter-import proxy,
  and the inert environment assertion in D-18). Prefer assertions that measure
  the artifact over assertions that measure the configuration producing it.

</specifics>

<deferred>
## Deferred Ideas

- The `.planning/` divergence: `origin/main` is ~55 commits behind local, which
  is the mechanism that silently invalidated Phase 199 and 200 verification
  targets (three dangling SHAs were found in the old 199 report). Not a release
  concern; belongs in its own phase or a maintenance decision.
- A hex.pm staging organisation as a rehearsal target was evaluated and
  rejected: a private-org publish exercises a different auth path and still does
  not render public HexDocs, so it buys rehearsal theatre rather than proof.
- Extending the module-group completeness assertion beyond this phase's needs
  (Phase 203 GATE-05 overlaps).

</deferred>
