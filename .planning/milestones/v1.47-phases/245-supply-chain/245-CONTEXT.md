# Phase 245: Supply chain - Context

**Gathered:** 2026-10-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 245 makes the supply chain hold up without anyone watching it:

- Every GitHub Actions reference is immutable (SHA-pinned) and kept current by one grouped Dependabot PR.
- Only advisories that reach adopters (shipped runtime dependencies in the root lock) block required CI and the release lane. Dev, test, bench and example advisories are reported, not blocking.
- The scheduled deps-health issue opens only for real findings (advisory, retirement, unknown) and closes itself when clean.

Requirements: SUP-01 (reworded, D-01), SUP-02, SUP-03, SUP-04.

Out of scope: new capabilities beyond these four, digest pinning for service images, OpenSSF Scorecard, and local-gate DX (see `<deferred>`).

</domain>

<decisions>
## Implementation Decisions

Research method: five parallel researchers, one per SUP cluster plus an adversarial cross-cutting pass. The maintainer approved the synthesized set with a single confirm on 2026-10-25.

### SUP-01 — Dependabot (requirement reworded)

- **D-01: Reword SUP-01 and ROADMAP 245 success criterion 1.**
  - New SUP-01 text: "Dependabot keeps SHA-pinned GitHub Actions current through one grouped monthly version-update PR with a 7-day cooldown. Hex security coverage comes from the tiered `hex.audit` gate (SUP-03) and the deps-health issue (SUP-04), because Dependabot does not serve Hex. A contract test pins the config."
  - Why the original cannot work:
    - GitHub's ecosystem table lists `mix` security updates as "Not supported", and Hex is absent from the dependency graph, so there are no alerts and no security PRs ([supported ecosystems](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories)).
    - "For GitHub Actions, alerts are only generated for actions that use semantic versioning, not SHA versioning" ([Dependabot alerts](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-alerts)). Once SUP-02 lands, a security-only actions config would never fire.
  - The executor updates `.planning/REQUIREMENTS.md` (SUP-01) and `.planning/ROADMAP.md` (Phase 245 criterion 1) in the first plan.
  - **Reversibility:** reversible.
- **D-02: `.github/dependabot.yml` has exactly one entry,** with this shape:
  - `package-ecosystem: github-actions`, `directory: "/"`
  - `schedule.interval: monthly`
  - `cooldown.default-days: 7`, so new pins never adopt a release less than 7 days old (the tj-actions pattern)
  - one group (`applies-to: version-updates`, `patterns: ["*"]`)
  - `commit-message: {prefix: "ci", include: "scope"}`, which gives `ci(deps): …` titles
  - Rationale: this is the only automatic way to keep SHA pins and their `# vX.Y.Z` comments current, including through runtime deprecations such as Node 20→24 that `ci_action_runtime_contract_test.exs` fails closed on.
  - Prior art: elixir-lang/elixir and hexpm/hex SHA-pin their actions and run a github-actions-only Dependabot with a 7-day cooldown.
  - Monthly rather than weekly, to stay closest to "no routine noise".
- **D-03: Deliberately absent from the config:**
  - no `mix` entry: it would be dead config that claims coverage Dependabot does not provide
  - no `npm` entry: the e2e Playwright lock is a test harness and ships nothing
  - no `target-branch`: setting it stops the config from applying to security updates
  - no `ci-deps` label: `bin/upsert-ci-issue` dedups by label, and PRs are issues
  - no `allow`, `ignore` or `rebase-strategy`
  - no `open-pull-requests-limit: 0`
  - no auto-merge
- **D-04: The `ci` prefix is never releasable.** release-please's releasable types here are feat, fix, perf and deps (the non-hidden `changelog-sections`). A lock-only change never needs a Hex release, because adopters resolve their own lock. Only raising a `mix.exs` requirement floor is a releasable `deps:` change, and that is a human edit, not a Dependabot one.
- **D-05: Contract test for `dependabot.yml`.** Parse the file with `yaml_elixir` into a pure checker function with mutation controls, in the style of `ci_token_permissions_contract_test.exs`. It asserts:
  - `version: 2`
  - the ecosystem×directory set is exactly `[{"github-actions", "/"}]`, so any mix or npm entry fails
  - `interval: monthly` and `cooldown.default-days >= 7`
  - exactly one group, with `applies-to: version-updates` and `patterns == ["*"]`
  - the prefix is not releasable, derived from `release-please-config.json` rather than restated
  - no `target-branch`, and `open-pull-requests-limit` is not 0
  - any labels are disjoint from every workflow `LABEL:`
  - no composite `action.yml` lives outside `/`

  Mutation controls: adding a mix entry, setting prefix `fix`, adding `target-branch`, and setting limit 0 must each make the checker fail.
- **D-06: Change these existing guards in the same commit:**
  - `test/threadline/deps_health_doc_contract_test.exs` around lines 160 and 168: it pins the sentence "does not use Dependabot version-update pull requests" and refutes that `dependabot.yml` exists.
  - `CONTRIBUTING.md` around lines 656–662.

  New wording, approximately: "Dependabot keeps GitHub Actions pins current with one grouped monthly PR; it opens no Hex PRs because GitHub does not support Hex security updates. Hex advisories come from `mix verify.deps_audit` and the deps-health issue." Record in the SUMMARY that this supersedes v1.43 decision T-215-19 (`215-SECURITY.md`).
- **D-07: Merge policy for Dependabot PRs.** The maintainer extended the standing merge grant to Dependabot's grouped actions PRs. Claude may merge one when all of the following hold:
  - required CI is green
  - the cooldown has elapsed
  - if the PR touches `release.yml`, the release-shape and bump-rehearsal checks have been run, because `release.yml`'s bumped actions are not exercised on the PR and only run after merge

  No auto-merge, ever. Record this in CONTRIBUTING's dependency section.

### SUP-02 — SHA-pinned actions

- **D-08: Pin every `uses:` ref, including first-party `actions/*`.**
  - Canonical form: `owner/repo[/path]@<40 lowercase hex> # vX.Y.Z`, unquoted, with the exact semver tag of the pinned commit.
  - Rationale:
    - Scorecard Pinned-Dependencies exempts nothing.
    - tj-actions (CVE-2025-30066) moved tags, and only SHA pins were immune.
    - Dependabot rewrites only an exact-tag single comment.
  - `./` local refs must point to a path that exists. `docker://` refs must use `@sha256:<64 hex>`. Neither exists today; the rules make Phase 247's new jobs pin by default.
  - **Reversibility:** reversible.
- **D-09: Pin the commit SHA, not the tag object SHA.**
  - Annotated tags (setup-beam v1, release-please v5) return a tag-object SHA from `git/ref/tags/X`. Dereference it with `git/tags/<sha>` → `.object.sha`.
  - Re-resolve the SHAs at execution time. Every floating major currently points at its latest patch, so pinning changes no behaviour.
  - Research-time table (verify before use):

    | action | latest tag | commit SHA |
    |---|---|---|
    | actions/checkout | v5.1.0 | `fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09` |
    | erlef/setup-beam | v1.24.1 | `54075bcc5e249e4758d363f27d099f55d843f124` |
    | actions/cache (+ /restore, /save) | v5.1.0 | `caa296126883cff596d87d8935842f9db880ef25` |
    | actions/upload-artifact | v7.0.2 | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` |
    | actions/setup-node | v5.0.0 | `a0853c24544627f65ddf259abe73b1d18a591444` |
    | googleapis/release-please-action | v5.0.0 | `45996ed1f6d02564a971a2fa1b5860e934307cf7` |
    | actions/github-script | v8.0.0 | `ed597411d8f924073f98dfc5c65a23a2325f34cd` |
    | re-actors/alls-green | v1.3.0 | `b5b5b37504aa4183270bd3d855c52a67f212be35` |

  - The alls-green comment at `ci.yml:1219` is wrong today: it says `v1.2.2 / release/v1`, but the SHA is v1.3.0. Fix it.
- **D-10: setup-node reads `node-version-file: .tool-versions` and has no `node-version`.**
  - `.tool-versions` already pins `nodejs 22.14.0`.
  - Affected steps: `ci.yml` around lines 684, 889 and 1052, and `browser-full.yml` around line 103.
  - setup-node falls back to the whole file when its regex does not match, so a contract must require exactly one `nodejs X.Y.Z` line.
- **D-11: The pin contract lives in a new `test/threadline/ci_action_pin_contract_test.exs`.**
  - It is hand-written ExUnit: no zizmor or pinact dependency (they may be mentioned as optional local tools in CONTRIBUTING).
  - It scans `.github/workflows/*.{yml,yaml}` and `.github/actions/**/action.{yml,yaml}`.
  - Rules:
    - **PIN-SCAN:** refuse an empty glob or zero refs.
    - **PIN-PARITY:** the multiset of `uses:` values from the parsed YAML (`jobs.*.uses`, `jobs.*.steps[*].uses`, composite `runs.steps[*].uses`) must equal the multiset from a raw scan of `uses:` lines with comment lines stripped. This closes phase 220's bypass classes: quoted keys, flow style, anchors, aliases, merge keys and block scalars.
    - **PIN-FORM:** each raw line matches the canonical regex from D-08.
    - **PIN-LOCAL** and **PIN-DOCKER:** per D-08.
    - **PIN-CONSISTENT:** one (action, SHA) pair always carries the same comment, and one action major uses one SHA across all files.
    - **NODE-FILE:** per D-10.
    - **NODE-PIN:** exactly one `^nodejs \d+\.\d+\.\d+$` line in `.tool-versions`.
  - Each rule has a mutation control asserting its own rule id fires:
    - a tag-only `actions/checkout@v5` (the success criterion's required negative control)
    - a 7-character short SHA
    - a SHA with no comment
    - a `# v5` comment
    - a quoted ref
    - a flow-style `{uses: …}`
    - `node-version: "22"`
    - a missing nodejs line

    Plus one benign positive control.
- **D-12: Re-key the `@node24_or_non_js` allowlist** in `ci_action_runtime_contract_test.exs` from `{action, ref}` to `{action, major}`, with the major read from the version comment.
  - A Dependabot patch or minor bump stays green; a major bump forces someone to re-check `runs.using`.
  - Keying by SHA would turn every Dependabot PR red, so don't.
  - The runbook regex `release-please-action@v(\d+)` reads the major from the comment.
- **D-13: Pin the refs in one atomic commit,** together with:
  - the setup-node switch
  - every test that matches literal `@vN` refs or `alls-green@<sha>\n` anchors. Known: `ci_workflow_parity_contract_test.exs` around lines 713/722/730 (alls-green anchors), around line 2336 (`"actions/cache@v5"`) and around line 5830 (a `node-version: "22"` fixture), plus its `step_uses`/`setup-node@` helpers. Also grep `hex_pin`, `repo_hygiene`, `ci_topology`, `browser_journey_evidence`, `flake_classifier` and CONTRIBUTING for `@v` refs.

  Job `id:`s and `with:` inputs stay untouched (CLAUDE.md stable-ids rule). No major bumps; 216 already deferred cache@v6 and checkout@v7.
- **D-14: Proving a pin matches its tag (impostor-commit defence).**
  - Offline tests can't prove a SHA belongs to its tag, because GitHub resolves fork-network SHAs.
  - (a) The executor proves every pin against its tag with read-only `gh api` at pin time and records the evidence in the plan SUMMARY.
  - (b) Add `bin/verify-action-pins`: it dereferences each comment's tag through `gh api` and compares it to the pinned SHA. It has a fake-`gh` seam for offline tests, in the same idiom as `MIX_BIN`.
  - It runs only in the scheduled deps-health lane, so PR CI stays hermetic. A mismatch classifies that run as `unknown`, with the reason at the top of the report (see D-25).
- **D-15: Maintainer action after the pins are on main:** set `sha_pinning_required=true` under Settings → Actions (changelog 2025-08-15).
  - Turning it on before then turns every open branch red.
  - Verify it read-only with `gh api repos/szTheory/threadline/actions/permissions --jq .sha_pinning_required` (currently `false`).
  - Record this as a pending human action, not a blocker for phase verification.

### SUP-03 — Tiered dependency-audit gate

- **D-16: Tier definition.** A finding (advisory or retirement) is BLOCKING if and only if:
  - it is in the root `mix.lock`, and
  - its package is in the root's runtime closure from `mix deps.tree --only prod --format plain`, which includes `optional: true` deps and transitive deps.

  Everything else is NON-BLOCKING: root dev/test-only packages, and every bench and example finding, even for packages that share a runtime package's name. Classify per (directory, package), never by package alone.

  Do not use `runtime: false` to decide the tier: a `runtime: false` dep without `only:` still ships as a requirement.

  **Reversibility:** reversible. It is a policy change: root dev-dep advisories stop blocking. State that explicitly in CONTRIBUTING.
- **D-17: Don't require `mix.exs` ranges to exclude vulnerable versions.** Hex ships ranges, not a lock, so adopters' own lock and `hex.audit` govern their exposure (precedent: cargo-audit, `npm audit --omit=dev`, pip-audit). Raising a floor stays a human call when Threadline's own code reaches the vulnerable path.
- **D-18: Mechanism.** No new dependency; mirego/mix_audit is rejected.
  - Parse `mix hex.audit --format sarif --output <tmp>` (Hex 2.6.0, OTP 27+). Its versioned fingerprint `partialFingerprints."hexAudit/v1" = "<kind>:hexpm/<pkg>:<id>"` is the machine contract; the human-format output is printed for display only.
  - Ignored advisories are absent from the SARIF results (verified), so `hex_audit_ignores/0` keeps working unchanged.
  - Put the tiering in a shared `bin/deps-audit-tier` helper, sourced by both `bin/verify-deps-audit` and `bin/deps-health-report`. One parser, two consumers.
  - Key the parser on `hexpm/<pkg>:` whatever the kind is. Before planning, the researcher confirms the retirement fingerprint prefix (expected `retirement:`) against real Hex 2.6.0.
  - Emit:
    - one machine line per finding: `deps-audit-finding tier=<blocking|non-blocking> dir=<d> kind=<advisory|retirement> package=<p> id=<id>`
    - `::error::` / `::warning::` annotations
    - a `$GITHUB_STEP_SUMMARY` table saying which tier applies and why, for example "plug is in the shipped runtime closure (root mix.lock)" or "benchee is only in bench/mix.lock; not shipped in the Hex package".
- **D-19: Fail closed in every ambiguous case,** each with its own FAIL line:
  - `hex.audit` exits non-zero but the SARIF has zero parseable results (a registry fetch failure looks like this)
  - a SARIF result has no parseable fingerprint
  - `deps.tree` fails or returns an empty closure
  - OTP is below 27, so SARIF is unavailable. Fail with a clear message, never a quiet green.

  Don't wrap the SARIF call in `bin/retry-network`: real findings also exit 1, so it would retry them. Write temp files under the repo's gitignored `tmp/`, with trap cleanup.
- **D-20: Everything other than findings stays blocking in all three directories:**
  - the Hex version floor
  - refusal of env and global Hex ignores
  - lock hygiene
  - `deps.get --check-locked`
  - `deps.unlock --check-unused`
  - a missing lock
  - audit errors that can't be classified

  These are correctness problems, not advisories. Fold in 244 R2-IN-01: the hygiene FAIL line in `bin/verify-deps-audit` currently blames empty managers for every hygiene failure; make it report the actual reason.
- **D-21: Non-blocking findings leave the job at exit 0.** release.yml `gate-ci-green` requires the push-to-main `ci.yml` run's conclusion to be `success`, so `allowed-failures` or a failing job would still block publish.

  The per-PR and push-to-main `verify-deps-audit` job only annotates. It never gets `issues: write`, which keeps `ci_token_permissions_contract_test.exs` and fork and Dependabot PRs working. The deps-health lane files the issue (D-27).
- **D-22: Keep the example app's cloak `hex_audit_ignores` entries.** Tiering alone would make them look unnecessary, but dropping them would keep the deps-health issue from ever closing.
- **D-23: Tests.**
  - **Offline, in `deps_audit_gate_test.exs`.** Extend the fake `MIX_BIN` to answer `deps.tree` and `hex.audit --format sarif --output P` from fixtures. Cases:
    1. root `plug` advisory → exit 1, `tier=blocking`
    2. root transitive `plug_crypto` → blocking
    3. root optional `oban` → blocking
    4. root dev-only `ex_doc` → exit 0, `tier=non-blocking` plus a warning
    5. bench `benchee` → exit 0
    6. example `plug` → exit 0 (pins the per-directory rule)
    7. retirement: runtime → exit 1, dev-only → exit 0
    8. non-zero audit with empty or malformed SARIF → exit 1
    9. `deps.tree` fails → exit 1
    10. a non-blocking finding plus bench lock drift → exit 1
    11. clean output reports a count of non-blocking findings
    12. matching `deps-health-report` cases through the shared helper
  - **Live-tree contract, offline.** The real `--only prod` closure contains every root dep without `only:` and none of credo, dialyxir, ex_doc, lazy_html, stream_data or yaml_elixir.
  - **Network self-test.** Keep case (a). Add case (e): the same vulnerable lock with `{:plug, "== 1.19.1", only: :test}` (mix.lock does not record `only:`, so `--check-locked` still passes). It must exit 0 and report `tier=non-blocking … package=plug id=EEF-CVE-2026-54892`. This is the real-Hex proof of the downgrade, and it catches SARIF format drift.
  - Update CONTRIBUTING's dependency sections and their doc contracts together (honest-default rule).

### SUP-04 — Self-closing deps-health issue

- **D-24: Drop `outdated` entirely.** Remove the class and stop running `hex.outdated` in the classifier.
  - `hex.outdated` exits 1 whenever anything is outdated, a permanent state, and also on crashes. The line-23 rule "any non-zero means outdated" hid both.
  - Optionally print `hex.outdated` into `$GITHUB_STEP_SUMMARY` with `continue-on-error`. It must never classify a run and never appear in the issue.
- **D-25: Classes and precedence: `advisory` > `retirement` > `unknown` > `clean`,** using the same max-rank idiom. A confirmed finding outranks an unrelated unknown, and the body still lists every directory's state.
  - `unknown` covers:
    - an active suppression (no audits run)
    - a missing dir or `mix.exs`
    - a failed `deps.get --check-locked` (that dir's audit is skipped)
    - an unclassifiable audit
    - a `bin/verify-action-pins` mismatch (D-14)
  - Classification takes the findings from the shared SARIF helper (D-18), with each finding's tier noted. `hex.audit` exiting non-zero with no SARIF result is `unknown`.
  - Never parse `deps.get` output: it prints "Found packages with security advisories" and still exits 0.
- **D-26: Issue lifecycle.**
  - Any non-clean class opens or updates the single `ci-deps` issue (marker "Dependency health"). Only `clean` closes it, after commenting first (already in place). `unknown` never closes it. No flapping guard.
  - The job goes red on any non-clean class; the fail step's exempt list becomes `clean` only.
  - In update mode, `bin/upsert-ci-issue` retitles the issue when the title differs (the marker prefix stays stable). This also fixes the Flake lane issue (#36). Add one row to its table test.
  - Body noise trim: include `deps.get` output only when the fetch fails.
- **D-27: One issue, with a tier section per finding** ("Blocking — shipped runtime" / "Non-blocking — dev/test/bench/example"). This is the SUP-03 non-blocking tier's issue path.

  Triggers:
  - a daily cron (replacing Monday-only, so a dev-tier advisory reaches the issue within about 24 hours)
  - `push: branches: [main]`, path-filtered to the three `mix.exs`/`mix.lock` pairs, so the issue closes as soon as a fix lands
  - `workflow_dispatch`

  `concurrency: cancel-in-progress: false` already serializes runs. Update `label-description` to match.
- **D-28: Let #61 close itself; don't close it by hand.** The next run retitles it to its current class and comments the tiered report. It closes on the first run where all three lockfiles are clean. (decimal is already 3.2.0 in all three locks on this branch; the remaining items are whatever the first run reports.)
- **D-29: Tests (fake `MIX_BIN`, fixture text copied from real Hex 2.6.0 output, ANSI included):**
  - every class arm, one directory at a time
  - precedence across directories: advisory(example) + retirement(bench) → advisory; retirement + fetch failure elsewhere → retirement; unknown + clean → unknown
  - regression for line 23: `hex.outdated` is never invoked (assert on the call log; the fake's `hex.outdated` exits 1, yet the run must be clean)
  - `GITHUB_OUTPUT` only ever emits a value from {clean, retirement, advisory, unknown}
  - workflow shape: the fail step exempts only `'clean'`; upsert fires on `!= 'clean'`; close fires on `== 'clean'`; the push path filter lists exactly the three lockfile directories, derived from CANONICAL_DIRS
  - `upsert-ci-issue` update mode retitles only when the title differs
  - doc contract: the class set CONTRIBUTING names equals `RANK_NAMES`; the "outdated result alone stays green" phrasing is gone; the open and close rules match the workflow

  Remove or rewrite the stale cases (around test:171, test:500, the moduledoc precedence at test:8–12) and the script header (around bin/deps-health-report:19–24 and :49).

### Cross-cutting: sequencing, verification, landing

- **D-30: Plan order:**
  1. SUP-04 (classifier, issue lifecycle, `upsert-ci-issue` retitle). It doesn't touch ci.yml.
  2. SUP-03 (shared tier helper; `verify-deps-audit` tiering; deps-health consumes it).
  3. SUP-02 (one atomic pin commit, plus `bin/verify-action-pins`).
  4. SUP-01 (`dependabot.yml` and its contract), last, so Dependabot's first scan sees SHA pins.
  5. A phase gate: `CI=true mix ci.all` on an ephemeral postgres:16 container, `bin/verify-repo-hygiene`, and `mix verify.credo`.

  The REQUIREMENTS/ROADMAP rewording from D-01 lands in plan 1's docs commit.
- **D-31: Verification is fully automated** (zero human UAT):
  - offline `mix test` contracts with negative and mutation controls
  - the network self-test in the `verify-deps-audit` CI job
  - an observed PR CI run at landing
  - after `dependabot.yml` reaches main, a read-only check that GitHub accepted the config (no Dependabot config error; the first grouped PR or "no updates" status).

  Things that can only be observed after landing are recorded as deferred-to-landing items, not gaps.
- **D-32: Landing.**
  - Phase 244 is still unlanded (REL-02 observed run, REL-01 live release PR, A3 matrix lanes, PAT expiry). Land 244 in its own PR first, then 245 in a separate PR, so a red run is attributable.
  - Pushes touch `.github/workflows`, so the push token needs `workflow` scope; check that before landing.
  - Executor dispatch prompts must include a halt clause: never loosen PIN-FORM or the tier rules, move protected files, or bypass hooks to get to green. Also no leftover poll or sleep shells.
- **D-33: Optional, fold in while touching the file:** move `${{ needs.release-ref.outputs.release_sha }}` out of the github-script body at `release.yml` around line 396 and into `env:`. It is a low-risk injection-hygiene fix.

### Claude's Discretion

- Exact rule ids and fixture file layout for the new contracts.
- Whether `bin/deps-audit-tier` is a sourced bash library or a small executable, as long as both scripts share one parser.
- Exact CONTRIBUTING wording, as long as the doc-contract tests pin the facts.
- Whether the `hex.outdated` job-summary section (D-24) is included at all.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and milestone intent
- `.planning/REQUIREMENTS.md` — SUP-01..04 (SUP-01 to be reworded per D-01)
- `.planning/ROADMAP.md` §Phase 245 — goal and success criteria (criterion 1 to be reworded per D-01); §246 and §247 for downstream dependencies
- `.planning/research/QUALITY-ROADMAP-2026-10-24.md` — the findings behind SUP-01..04 and the carried-debt register rows (216 action pinning, setup-node float, 215 WR-01)
- `.planning/PROJECT.md` — v1.47 section, Constraints ("Zero human verification by default"), Key Decisions
- `CLAUDE.md` — stable CI job ids, honest default tests, named `mix verify.*` entrypoints
- `prompts/threadline-elixir-oss-dna.md` — the quality bar and CI conventions

### Prior phase decisions
- `.planning/milestones/v1.43-phases/215-supply-chain-gate/` — the original gate design, T-215-19 (superseded by D-06), WR-01, and the CR-01 ignore refusal
- `.planning/milestones/v1.43-phases/216-ci-platform-currency/` — the pinning deferral and the cache@v6/checkout@v7 deferral
- `.planning/milestones/v1.43-phases/218-ci-economy-remove-waste/218-CONTEXT.md` — ECON-02 close-on-clean
- `.planning/milestones/v1.43-phases/220-newest-toolchain-lane/` — regex-over-text bypass classes, closed by parsing YAML
- `.planning/phases/244-release-flow/244-VERIFICATION.md`, `244-REVIEW-DISPOSITION.md`, `244-REL02-EVIDENCE.md` — the release flow this builds on, R2-IN-01, and the deferred landing items

### Code under change
- `bin/verify-deps-audit`, `bin/deps-health-report`, `bin/upsert-ci-issue`, `bin/verify-lock-hygiene`, `bin/retry-network`
- `.github/workflows/ci.yml`, `release.yml` (`gate-ci-green`), `deps-health.yml`, `browser-full.yml`, `flake-detection.yml`, `branch-protection.yml`, `community-health.yml`, `environment-protection.yml`
- `.tool-versions`, `mix.exs` (root deps; `hex_audit_ignores/0`), `bench/mix.exs`, `examples/threadline_phoenix/mix.exs`, `release-please-config.json`
- `CONTRIBUTING.md` — the "Dependency freshness policy" and supply-chain sections

### Tests to extend or update
- `test/threadline/deps_audit_gate_test.exs`, `deps_audit_contract_test.exs`, `deps_health_report_test.exs`, `deps_health_doc_contract_test.exs`, `ignore_advisories_contract_test.exs`, `cloak_advisory_reachability_contract_test.exs`, `optional_deps_contract_test.exs`
- `test/threadline/ci_action_runtime_contract_test.exs`, `ci_workflow_parity_contract_test.exs`, `ci_token_permissions_contract_test.exs`, `hex_pin_contract_test.exs`
- `test/fixtures/deps_audit/vulnerable_lock/` — the network self-test fixture

### External primary sources
- https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories — Hex security updates are not supported
- https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-alerts — no alerts for SHA-pinned actions
- https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference — cooldown, groups, commit-message, target-branch
- https://github.blog/changelog/2025-08-15-github-actions-policy-now-supports-blocking-and-sha-pinning-actions/ — the `sha_pinning_required` setting
- https://github.com/actions/setup-node/blob/main/docs/advanced-usage.md#node-version-file — `.tool-versions` support
- https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html and https://github.com/hexpm/hex/blob/v2.6.0/lib/mix/tasks/hex.audit.ex — SARIF output and exit codes
- https://github.com/hexpm/hex/blob/v2.6.0/lib/mix/tasks/hex.outdated.ex — exits 1 when anything is outdated
- https://hexdocs.pm/mix/Mix.Tasks.Deps.Tree.html — `--only prod`
- https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction-setup-gh-cve-2025-30154

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`MIX_BIN` fake-mix seam** (`bin/verify-deps-audit`, `bin/deps-health-report`): every new behaviour is tested offline through it. Copy the idiom for a fake-`gh` seam in `bin/verify-action-pins`.
- **`bin/upsert-ci-issue`:** marker- and label-based issue upsert and `--close`. Add a retitle-on-update step.
- **Max-rank classification idiom** (`bin/deps-health-report` around lines 91–114): reuse it with the new class set.
- **`read_global_hex_ignore` / ignore refusal:** stays as it is in both scripts.
- **`yaml_elixir`** (test dep) plus pure checker functions plus mutation controls: the contract-test idiom (`ci_token_permissions_contract_test.exs`, `ci_workflow_parity_contract_test.exs`).
- **`--self-test` network proof** in `verify-deps-audit`, with a committed vulnerable fixture. Extend it with case (e).

### Established Patterns
- Contracts parse YAML and never regex raw text alone. Phase 220 proved regex bypasses.
- Every guard has a negative or mutation control proving it goes red, for the right reason.
- Network-touching proofs run as CI steps, never as tagged ExUnit tests excluded from `mix test`.
- Required CI is `CI required` (integration_id 15368). release.yml `gate-ci-green` needs a fully successful push-to-main ci.yml run.
- `.planning/` is published on main. Planning prose must not spell out home-path shapes or usernames, or the repo-hygiene guard turns `ci.all` red.

### Integration Points
- The `ci.yml` `verify-deps-audit` job runs `mix verify.deps_audit` and the self-test.
- `deps-health.yml`: triggers, the classification output, the upsert, close and fail steps.
- `ci_action_runtime_contract_test.exs`'s allowlist is coupled to action refs. Re-key it in the same commit as the pins.

</code_context>

<specifics>
## Specific Ideas

- The maintainer prefers "another copy-paste is better than another dependency": no zizmor, pinact, mix_audit, Scorecard action or `erlef/mix-dependency-submission` as dependencies.
- Maintainer actions, all outside verification:
  - after the pins are on main, set `sha_pinning_required=true`
  - provide a push token with `workflow` scope
  - optionally, turn on Dependabot alerts for e2e npm visibility. Leave "Dependabot security updates" off.

</specifics>

<deferred>
## Deferred Ideas

- **Digest-pinning service images** (`postgres:16` ×9, `edoburu/pgbouncer:v1.25.2-p0` at ci.yml around line 292). Deferred or rejected: Dependabot doesn't update workflow `services:` images, so digests would go stale silently, and these images are test-only.
- **OpenSSF Scorecard.** Deferred to the 1.0 polish rung. It adds an action dependency and `security-events: write`.
- **A Dependabot npm entry for `examples/threadline_phoenix/e2e/package-lock.json`.** Not taken. It is a test harness, and alerts are optional visibility.
- **Running `bin/verify-action-pins` on PRs.** Not taken; PR CI stays hermetic.

### Reviewed Todos (not folded)
- `.planning/todos/pending/2026-10-25-local-gate-ephemeral-postgres-wrapper.md` (Run the local gate on its own ephemeral Postgres): local-gate DX, not supply chain. Routed to Phase 246 or 247. Phase 245's own gate still uses an ad-hoc postgres:16 container.

</deferred>

---

*Phase: 245-supply-chain*
*Context gathered: 2026-10-25*
