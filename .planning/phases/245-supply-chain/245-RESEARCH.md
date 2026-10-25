# Phase 245: Supply chain - Research

**Researched:** 2026-10-25
**Domain:** GitHub Actions supply chain (SHA pinning, Dependabot), Hex advisory gating (SARIF, `deps.tree`), CI issue lifecycle (bash + ExUnit contracts)
**Confidence:** HIGH. Every load-bearing claim about Hex was checked against Hex 2.6.0 source and real runs, and every action SHA was re-resolved with `gh api` this session. Dependabot behaviour that can only be seen after landing is MEDIUM.

## Summary

All 33 decisions in CONTEXT.md hold up against real evidence, with four corrections the planner must carry into the plans:

1. **The retirement SARIF fingerprint is `retired:hexpm/<pkg>`, not `retirement:…`, and it has no id segment.** Advisories are `advisory:hexpm/<pkg>:<id>`. A third kind, `denied:hexpm/<pkg>`, appears only in `--policy` modes. Source: `lib/hex/sarif.ex` at v2.6.0, lines 369, 389, 406. Confirmed by a real run that locked the retired `plug 1.20.0`.
2. **`mix deps.tree --only prod` exits 0 and prints only top-level deps when `deps/` is not fetched.** The closure must be read after a successful `deps.get --check-locked`, never before it.
3. **D-19's "empty closure fails closed" rule conflicts with D-23 self-test case (e).** With `{:plug, …, only: :test}` as the fixture's only dep, the real closure is empty. Fix: give case (e) a second, prod dep, `{:telemetry, "~> 1.4"}`. This was verified against real Hex: `--check-locked` and `--check-unused` both pass, the committed lock stays byte-identical, and the closure is `{telemetry}`.
4. **D-16 read literally ("blocking only if in the root `mix.lock`") would turn self-test case (a) green.** The self-test audits a throwaway project directory, not the repo root. Key the tier on directory role instead. `bench` and `examples/threadline_phoenix` are always non-blocking. Every other directory uses the closure rule: the root `.`, and any explicit `DIR` argument such as the self-test projects. This fails closed.

There is also one expectation the planner should record. Every pin today is already the latest release in its major, but newer majors exist for four actions: checkout v7, cache v6, setup-node v7 and github-script v9. All four are `node24`. Dependabot's grouped PR covers every semver level by default, so **the first monthly PR will be majors-only and will go red on the D-12 `{action, major}` allowlist, by design.** That PR is a real major-bump review, not noise. Record it as a deferred-to-landing observation.

**Primary recommendation:** Write one SARIF parser in a sourced `bin/deps-audit-tier` library, using `jq` (already a dependency of `bin/upsert-ci-issue`). Key it on the regex `^(advisory|retired|denied):([^/]+)/([a-z0-9_]+)(:(.+))?$`. Write each SARIF to a fresh path that was never created beforehand. Tier by directory role plus the post-fetch `--only prod` closure. Fail closed on a missing file, an empty `results` with a non-zero exit, an unknown kind, or an empty closure in a closure-rule directory.

## Architectural Responsibility Map

| Capability | Primary tier | Secondary tier | Rationale |
|---|---|---|---|
| Action immutability (pins, comments) | CI config (`.github/workflows/*.yml`) | ExUnit contract (`ci_action_pin_contract_test.exs`) | The workflow text is the artifact. An offline contract enforces its form. |
| Pin-to-tag provenance (impostor defence) | Scheduled lane (`bin/verify-action-pins` in `deps-health.yml`) | — | Needs network (`gh api`). PR CI stays hermetic (D-14). |
| Pin currency | GitHub Dependabot (`.github/dependabot.yml`) | ExUnit contract | Dependabot is GitHub-side state, driven by a committed config. |
| Advisory tiering (SUP-03) | Shell gate (`bin/verify-deps-audit` + `bin/deps-audit-tier`) | `ci.yml` `verify-deps-audit` job (required) | One parser shared by two consumers (D-18). |
| Issue lifecycle (SUP-04) | Shell classifier (`bin/deps-health-report`) + `bin/upsert-ci-issue` | `deps-health.yml` steps | Classification is in a script so it can be unit-tested. The workflow only routes on the value. |
| Repo setting `sha_pinning_required` | GitHub repo settings (maintainer) | — | A human action after landing (D-15). Currently `false`. |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Research method: five parallel researchers, one per SUP cluster plus an adversarial cross-cutting pass. The maintainer approved the synthesized set with a single confirm on 2026-10-25.

#### SUP-01 — Dependabot (requirement reworded)

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

#### SUP-02 — SHA-pinned actions

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

#### SUP-03 — Tiered dependency-audit gate

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

#### SUP-04 — Self-closing deps-health issue

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

#### Cross-cutting: sequencing, verification, landing

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

### Deferred Ideas (OUT OF SCOPE)

- **Digest-pinning service images** (`postgres:16` ×9, `edoburu/pgbouncer:v1.25.2-p0` at ci.yml around line 292). Deferred or rejected: Dependabot doesn't update workflow `services:` images, so digests would go stale silently, and these images are test-only.
- **OpenSSF Scorecard.** Deferred to the 1.0 polish rung. It adds an action dependency and `security-events: write`.
- **A Dependabot npm entry for `examples/threadline_phoenix/e2e/package-lock.json`.** Not taken. It is a test harness, and alerts are optional visibility.
- **Running `bin/verify-action-pins` on PRs.** Not taken; PR CI stays hermetic.
- Reviewed todo not folded: `.planning/todos/pending/2026-10-25-local-gate-ephemeral-postgres-wrapper.md` (local-gate DX, routed to Phase 246 or 247).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research support |
|---|---|---|
| SUP-01 | (Reworded per D-01.) Dependabot keeps SHA-pinned GitHub Actions current through one grouped monthly version-update PR with a 7-day cooldown. A contract test pins the config. | §Dependabot config (schema verified against the options reference). §Pitfall 5 (the first PR will be majors-only). §Validation map. |
| SUP-02 | Every `uses:` ref is a full SHA with a version comment, setup-node reads `.tool-versions`, and a contract rejects tag-only refs with a negative control. | §Action inventory (79 refs, file:line). §Re-resolved SHA table. §Blast radius. §setup-node parser source. |
| SUP-03 | Tiered gate: a shipped-runtime advisory fails required CI, while dev/test/bench/example advisories leave the release lane green and reach the issue. | §Hex 2.6.0 SARIF contract (source and real runs). §Closure recipe. §Directory-role tier rule. §Self-test case (e) fix. |
| SUP-04 | deps-health opens or updates the issue only for advisories, retirements or unknown, and closes it when clean. The classifier exit codes are tested. | §Script structure (functions and line numbers). §upsert retitle seam. §Live state: today all three locks audit clean, so #61 closes on the first post-merge run. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Use the named entrypoints `mix verify.*` and `mix ci.*` in CI and docs. Cite `mix verify.deps_audit`, `mix verify.credo` and `mix ci.all` verbatim.
- **Honest default tests:** never silently exclude suites from `mix test`. Network proofs stay as CI steps (`--self-test`), not tagged ExUnit tests.
- **Stable CI job ids:** `verify-deps-audit`, `deps-health`, `ci-required` and the rest keep their `id:`. Only `name:` may change, for example the deps-health job's "Weekly hex.audit + hex.outdated" name.
- **Doc contract tests:** CONTRIBUTING changes land together with their `*_doc_contract_test.exs` updates.
- **Zero human verification by default.** Hand the maintainer only secrets, spend, push/publish and scope. Here that means `sha_pinning_required` and the `workflow`-scope token.
- **No `git add .planning/` wholesale.** Planning prose must not contain home-directory path shapes or the username; the repo-hygiene guard scans tracked `.planning/`.
- **Never run `npx` for `@opengsd`.** The CONTRIBUTING release-please runbook uses `npx release-please@…`, which is unrelated and fine.
- Run the local gate on an ephemeral postgres:16. Run `mix verify.credo` after any code-fixer pass. A Dialyzer PLT miss means `mix dialyzer --plt`.

## Standard Stack

No new packages. The maintainer's rule is "another copy-paste is better than another dependency" (CONTEXT `<specifics>`).

| Tool | Version (verified) | Purpose | Where already used |
|---|---|---|---|
| Hex client | 2.6.0 (`mix hex.info` → `Hex: 2.6.0`, OTP 27.3.4.15) [VERIFIED: local run] | `hex.audit --format sarif --output` | `MIN_HEX="2.6.0"` at `bin/verify-deps-audit:66`; CI pin `mix local.hex 2.6.0 --force` at `ci.yml:188`, `deps-health.yml:48` |
| `jq` | 1.7.1 locally; preinstalled on ubuntu-24.04 runners [ASSUMED for runner] | SARIF parsing | `bin/upsert-ci-issue:47-48` already requires it |
| `yaml_elixir` | `~> 2.11.0`, test-only [VERIFIED: mix.exs:127] | Dependabot and pin contracts | `ci_token_permissions_contract_test.exs:123` (`YamlElixir.read_from_string!(text, merge_anchors: true)`) |
| `gh` CLI | 2.101.0 locally; preinstalled on runners | `bin/verify-action-pins`, `bin/upsert-ci-issue` | `GH_BIN=${GH_BIN:-gh}` seam at `bin/upsert-ci-issue:24` |
| `actionlint` | 1.7.12 locally | Optional local lint after editing workflows | (not a CI dependency) |

## Package Legitimacy Audit

No external packages are installed by this phase. The only artifacts adopted are GitHub Actions, which are already in use at the same commits; pinning changes the ref form only.

| Package | Registry | Verdict | Disposition |
|---|---|---|---|
| (none) | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Hex 2.6.0 SARIF contract (open item 1, resolved)

### Source of truth: `lib/hex/sarif.ex` at tag v2.6.0 (fetched with `gh api repos/hexpm/hex/contents/...?ref=v2.6.0`)

[VERIFIED: hexpm/hex v2.6.0 lib/hex/sarif.ex:369, :389, :406-407] Verbatim:

```elixir
      "partialFingerprints" => %{"hexAudit/v1" => "denied:#{repo}/#{package}"}
...
      "partialFingerprints" => %{"hexAudit/v1" => "retired:#{repo}/#{package}"}
...
      "partialFingerprints" => %{
        "hexAudit/v1" => "advisory:#{repo}/#{package}:#{advisory.id}"
```

- **Kinds:** `advisory`, `retired` and `denied`. **The retirement prefix is `retired:`, not `retirement:`, and a retirement fingerprint has no `:<id>` suffix.** `denied` is produced only under `--policy` or `--policy-overrides` (`hex.audit.ex:271-275` builds findings from `result.denied`, which is populated only in policy modes); the gate never passes those flags.
- **Retirement rule ids** [VERIFIED: sarif.ex:24-31]: `RETIRED_OTHER: {"HEX0001", …}`, `RETIRED_INVALID: {"HEX0002", …}`, `RETIRED_SECURITY: {"HEX0003", …}`, `RETIRED_DEPRECATED: {"HEX0004", …}`, `RETIRED_RENAMED: {"HEX0005", …}`. Denied is `"HEX0006"`. For a retirement, use `.ruleId` (for example `HEX0002`) as the `id=` value in the machine line.
- **`repo`** is the lock's repository, `"hexpm"` for every public package (`lock_repo(_missing), do: "hexpm"`, sarif.ex:602-603). An organization repo would contain `:` (`hexpm:org`), so split on the first `/`, not on `:`.
- **Package** is the Hex package name, the second element of the `{:hex, :pkg, …}` lock tuple, not the lock map key. In all three locks today the key equals the package name for every `:hex` entry (awk scan, 0 mismatches). Map through the lock tuple anyway, or add a fail-closed contract asserting key == package.

### Exit codes and failure shapes (real runs this session, Hex 2.6.0, OTP 27.3.4.15)

| Scenario | Exit | SARIF file | Evidence |
|---|---|---|---|
| Vulnerable fixture (`test/fixtures/deps_audit/vulnerable_lock`) | 1 | written, 5 results | stderr `Found packages with security advisories` |
| `plug == 1.20.0` (retired and vulnerable) | 1 | written, 3 results (1 `retired:`, 2 `advisory:`) | stderr `Found retired packages` / `Found packages with security advisories` |
| The same, with every finding in `hex: [ignore_advisories: [...], ignore_retirements: [:plug]]` | **0** | written, `"results": []` and `"rules": []` | Human format lists them under `Ignored retired:` / `Ignored advisories:` and exits 0. **Ignored findings are absent from SARIF** [VERIFIED: real run; also hex.audit.ex:87-89 moduledoc]. An alias id (`CVE-2026-56814`) ignores its `EEF-CVE-…` primary. |
| Registry unreachable (`HEX_MIRROR=http://127.0.0.1:9`) | 1 | **not written**; a pre-existing file at that path is **left untouched** | stdout/stderr `Failed to fetch record for plug from registry` … `** (Mix) Could not audit these locked packages:` |
| All three repo locks, today | 0 | written, `[]` each | Root, bench and example are all clean. The example's cloak ignores are applied. |
| OTP < 27 | non-zero (Mix.raise) | not written | [VERIFIED: sarif.ex:605-611] `Mix.raise(":json module is not available, upgrade OTP to use this feature")` |

Consequences for the parser (fail-closed rules from D-19, made concrete):

1. Create a fresh directory with `mktemp -d "$ROOT/tmp/deps-audit-sarif.XXXXXX"`. Pass `--output "$dir/audit.sarif"` and **never pre-create the file**. If the file is missing after the run, that is a FAIL, whatever the exit status.
2. Exit 0 with `results != []` is impossible in Hex 2.6.0, so treat it as unclassifiable and FAIL.
3. Exit non-zero with `results == []` means a registry, policy or raise failure: FAIL (or `unknown` in deps-health).
4. A result whose fingerprint does not match the regex, or whose kind is not `advisory` or `retired`, is a FAIL.
5. `jq` failing to parse the file is a FAIL.
6. Do not wrap the call in `bin/retry-network`, as D-19 says.

### Real fixture snippet (trimmed of `contextRegion` and snippets; copy for the fake-`MIX_BIN` SARIF fixtures)

```json
{
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "version": "2.1.0",
  "runs": [{
    "automationDetails": {"description": {"text": "Hex dependency audit (mix hex.audit)"}, "id": "hex-audit/"},
    "tool": {"driver": {"name": "mix hex.audit", "version": "2.6.0",
      "rules": [{"id": "HEX0002", "name": "RetiredPackageInvalid"},
                {"id": "EEF-CVE-2026-56813", "name": "EefCve202656813"}]}},
    "results": [
      {"ruleId": "HEX0002", "ruleIndex": 0, "level": "warning",
       "message": {"text": "Dependency 'plug' '1.20.0' is retired: '(invalid) Accidental breaking change on Plug.Conn.inform'."},
       "locations": [{"physicalLocation": {"artifactLocation": {"uri": "mix.lock"}, "region": {"startLine": 3}}}],
       "partialFingerprints": {"hexAudit/v1": "retired:hexpm/plug"}},
      {"ruleId": "EEF-CVE-2026-56813", "ruleIndex": 1, "level": "note",
       "message": {"text": "Dependency 'plug' '1.20.0' is affected by security advisory 'EEF-CVE-2026-56813 (aka CVE-2026-56813, GHSA-wpmj-jh88-rpgm)': 'Cookie attribute injection in Plug.Conn.Cookies.encode/2'. See 'https://osv.dev/vulnerability/EEF-CVE-2026-56813'."},
       "locations": [{"physicalLocation": {"artifactLocation": {"uri": "mix.lock"}, "region": {"startLine": 3}}}],
       "partialFingerprints": {"hexAudit/v1": "advisory:hexpm/plug:EEF-CVE-2026-56813"}}
    ]
  }]
}
```

Real vulnerable-fixture fingerprints, used by self-test (a) and (e):

```
advisory:hexpm/plug:EEF-CVE-2026-54892       (level error)
advisory:hexpm/plug:EEF-CVE-2026-8468        (level error)
advisory:hexpm/plug:EEF-CVE-2026-56813       (level note)
advisory:hexpm/plug:EEF-CVE-2026-56814       (level warning)
advisory:hexpm/plug_crypto:EEF-CVE-2026-105963 (level warning)
```

Inside a git work tree, `artifactLocation` gains `"uriBaseId": "SRCROOT"` and a repo-relative `uri` (for example `bench/mix.lock`), and the run gains `versionControlProvenance` (sarif.ex:125-132, 97-101). The scratch runs here were outside a git tree, so the fixture shows the plain `"uri": "mix.lock"` form. Never key on `uri`.

### Parsing recipe (jq, bash 3.2-safe)

```bash
# One finding per line: <kind>\t<package>\t<id>\t<message>
jq -r '.runs[0].results[]
  | (.partialFingerprints["hexAudit/v1"] // "") as $fp
  | ($fp | capture("^(?<kind>advisory|retired|denied):(?<repo>[^/]+)/(?<pkg>[a-z][a-z0-9_]*)(:(?<id>.+))?$")?) as $m
  | if $m == null then "UNPARSEABLE\t\t\t\($fp)"
    else [$m.kind, $m.pkg, ($m.id // .ruleId), .message.text] | @tsv end' "$sarif"
```

`capture(...)?` yields `null` on a non-match, so an unparseable fingerprint becomes an explicit `UNPARSEABLE` row the caller turns into a FAIL. Map `retired` to `kind=retirement` in the D-18 machine line. Treat `denied`, or any other kind, as a FAIL.

## `mix deps.tree --only prod --format plain` (open item 2, resolved)

Real root output today: exit 0, 74 lines. The first lines are:

```
threadline
|-- ecto_sql ~> 3.10 (Hex package)
|   |-- db_connection ~> 2.9 (Hex package)
|   |   `-- telemetry ~> 0.4 or ~> 1.0 (Hex package)
...
`-- telemetry ~> 1.2 (Hex package)
```

**Recipe:** `tail -n +2 | sed -E 's/^[|\` -]*//; s/ .*//' | sort -u`. That drops the project line, strips the tree glyphs, and keeps the first token (the app name).

**Today's root runtime closure (28)** [VERIFIED: real run, identical under `MIX_ENV=test`]:
`db_connection decimal ecto ecto_sql ex_aws ex_aws_s3 finch hpax jason mime mint nimble_csv nimble_options nimble_pool oban phoenix phoenix_html phoenix_live_view phoenix_pubsub phoenix_template plug plug_crypto postgrex req sweet_xml telemetry websock websock_adapter`

- Optional deps are included (oban, phoenix, phoenix_live_view, ex_aws, req, sweet_xml and others), as are transitive deps (plug_crypto, mint, hpax, websock_adapter).
- **Root lock packages not in the closure (18), all non-blocking:** `bunt cc_precompiler credo dialyxir earmark_parser elixir_make erlex ex_doc file_system fine lazy_html makeup makeup_elixir makeup_erlang nimble_parsec stream_data yamerl yaml_elixir`.
- The root lock has 46 `:hex` entries. The full tree (no `--only`) is also 46, so closure plus non-closure covers the lock with no gaps.
- **Pitfall [VERIFIED: real run]:** with `deps/` removed, the vulnerable fixture's `deps.tree --only prod` still **exits 0** but prints only `plug == 1.19.1`, with no transitives. The closure is only correct after a successful `deps.get --check-locked`. In `bin/verify-deps-audit` the per-directory order already fetches first (`:353`). Call `deps.tree` after the `deps_get_status` check (`:357-363`) and before or alongside `hex.audit` (`:375-383`).
- `deps.tree` exits 0 even when the closure is legitimately empty (a project whose deps are all `only: :test`). See the self-test fix below.

### The directory-role tier rule (needed so the self-test keeps its teeth)

D-16's literal "in the root `mix.lock`" would classify every finding in the self-test's throwaway project as non-blocking, because that project is not the repo root. Case (a), which must go red, would then exit 0. Use this rule, which is consistent with D-16's intent and fails closed:

| Directory (relative to `$ROOT` after `resolve_dir`) | Tier rule |
|---|---|
| `bench`, `examples/threadline_phoenix` | every finding non-blocking (never shipped) |
| everything else (`.`, and any explicit `DIR` argument, such as self-test projects) | blocking if and only if the package is in that directory's `--only prod` closure; an empty closure is a FAIL |

### Self-test case (e): use a two-dep fixture [VERIFIED: real run]

`mix.exs` deps: `[{:plug, "== 1.19.1", only: :test}, {:telemetry, "~> 1.4"}]`, applied to a copy of `test/fixtures/deps_audit/vulnerable_lock/mix.lock`. Observed:

- `deps.get --check-locked` → exit 0, and the committed lock is byte-identical
- `deps.unlock --check-unused` → exit 0
- `deps.tree --only prod` → `` `-- telemetry ~> 1.4 `` (closure = {telemetry})
- `hex.audit --format sarif` → exit 1, with the same 5 fingerprints as above (plug ×4, plug_crypto ×1)
- Expected gate result: exit 0, five `tier=non-blocking` lines, including `package=plug id=EEF-CVE-2026-54892`. plug_crypto is non-blocking too, because it is reached only through the test-only plug.

Derive the drifted `mix.exs` with the same string-substitution idiom case (d) uses (`bin/verify-deps-audit:188-190`).

## Action inventory (open item 3, resolved)

`.github/actions/` does not exist, and there is no `action.yml` anywhere in the repo (`git ls-files`). All 79 refs are step-level `uses:`. There are no job-level `uses:` (reusable workflows) and no `./` or `docker://` refs.

| Ref today | Count | Files:lines |
|---|---|---|
| `actions/checkout@v5` | 28 | ci.yml:70,84,101,174,206,249,302,377,434,486,674,875,1038; release.yml:65,152,185,279,500,531,698,729,765; branch-protection.yml:46; browser-full.yml:75; community-health.yml:58; deps-health.yml:38; environment-protection.yml:52; flake-detection.yml:96 |
| `erlef/setup-beam@v1` | 17 | ci.yml:103,176,208,251,304,379,438,488,692,877,1040; release.yml:159,507,705; browser-full.yml:88; deps-health.yml:40; flake-detection.yml:109 |
| `actions/cache@v5` | 12 | ci.yml:153,322,390,499,722,894,901,1057,1064; browser-full.yml:109,117; flake-detection.yml:124 |
| `actions/cache/restore@v5` | 6 | ci.yml:316,507,706,800,923,1086 |
| `actions/cache/save@v5` | 5 | ci.yml:560,746,831,953,1116 |
| `actions/setup-node@v5` | 4 | ci.yml:682,887,1050; browser-full.yml:100 |
| `actions/upload-artifact@v7` | 4 | ci.yml:1161,1176; browser-full.yml:159; flake-detection.yml:214 |
| `googleapis/release-please-action@v5` | 1 | release.yml:105 |
| `actions/github-script@v8` | 1 | release.yml:392 |
| `re-actors/alls-green@b5b5b375…` | 1 | ci.yml:1221 (wrong comment at ci.yml:1219-1220) |

`node-version: "22"` occurs at ci.yml:684, 889, 1052 and browser-full.yml:103. `.tool-versions` reads `nodejs 22.14.0` / `erlang 27.3.4.15` / `elixir 1.17.3-otp-27` [VERIFIED: file read].

### Re-resolved SHAs (read-only `gh api`, 2026-10-25) — D-09's table is confirmed unchanged

| Action | Floating ref type | Pin tag | Commit SHA (dereferenced) | Newer major available | Next major `runs.using` |
|---|---|---|---|---|---|
| actions/checkout | v5 = commit | v5.1.0 | `fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09` | v7.0.1 | node24 |
| erlef/setup-beam | v1 = **annotated tag** | v1.24.1 | `54075bcc5e249e4758d363f27d099f55d843f124` | — | — |
| actions/cache (+/restore, /save) | v5 = commit | v5.1.0 | `caa296126883cff596d87d8935842f9db880ef25` | v6.1.0 | node24 |
| actions/upload-artifact | v7 = commit | v7.0.2 | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` | — (latest) | — |
| actions/setup-node | v5 = commit | v5.0.0 | `a0853c24544627f65ddf259abe73b1d18a591444` | v7.1.0 | node24 |
| googleapis/release-please-action | v5 = **annotated tag** | v5.0.0 | `45996ed1f6d02564a971a2fa1b5860e934307cf7` | — (latest) | — |
| actions/github-script | v8 = commit | v8.0.0 | `ed597411d8f924073f98dfc5c65a23a2325f34cd` | v9.0.0 | node24 |
| re-actors/alls-green | **no `v1` tag** (404); v1.3.0 = annotated tag | v1.3.0 | `b5b5b37504aa4183270bd3d855c52a67f212be35` | — | — |

Every current pin target's `action.yml` reads `node24`, except alls-green, which is `composite` [VERIFIED: `gh api .../contents/action.yml?ref=<tag>`].

Dereference recipe for `bin/verify-action-pins` (this is the same logic the session ran):

```bash
r=$("$GH_BIN" api "repos/$repo/git/ref/tags/$tag" --jq '.object.type+" "+.object.sha')
typ=${r%% *}; sha=${r##* }
[ "$typ" = tag ] && sha=$("$GH_BIN" api "repos/$repo/git/tags/$sha" --jq .object.sha)
# compare $sha to the pinned 40-hex; repo = first two path segments of the action (actions/cache/restore -> actions/cache)
```

Distinct `(repo, tag)` pairs: 8, so at most 16 API calls per run, well inside `GITHUB_TOKEN` limits. The deps-health report step currently has no `GH_TOKEN` env (`deps-health.yml:50-52`); add one when `bin/verify-action-pins` is wired in.

## Blast radius inventory (open item 4)

### Tests that read the live workflows and will break on the pin commit (must change in the D-13 atomic commit)

| File:line | What it matches | Why it breaks |
|---|---|---|
| `ci_action_runtime_contract_test.exs:13-24` | `@node24_or_non_js` keyed `{action, ref}` | D-12 re-key to `{action, major}`, with the major read from the `# vX.Y.Z` comment. alls-green becomes `{"re-actors/alls-green", "v1"}`. |
| `ci_action_runtime_contract_test.exs:65-70` (`uses_refs/1`) | `~r/^\s*(?:-\s+)?uses:\s*["']?([^\s"'#]+)/m` | Captures `owner/repo@<sha>` with no comment. It needs a second capture for `#\s*(v\d+)\.` to derive the major. |
| `ci_action_runtime_contract_test.exs:124-131` | `~r/googleapis\/release-please-action@v(\d+)\b/` on comment-stripped release.yml | It will not match `@<sha> # v5.0.0`. Read the major from the comment (D-12). The mutation at `:172-183` (replace `@v\d+`) must be rewritten to mutate the comment major. |
| `ci_workflow_parity_contract_test.exs:713, 722, 730` | `~r/^        uses: re-actors\/alls-green@[0-9a-f]{40}\n/m` | Adding ` # v1.3.0` puts the comment before `\n`. Change to `@[0-9a-f]{40}[^\n]*\n` or anchor on the parsed value. `:1894` checks the **parsed** value (`^re-actors\/alls-green@[0-9a-f]{40}$`) and stays green, because YAML strips comments. |
| `ci_topology_contract_test.exs:246` | `~r\|uses: re-actors/alls-green@[0-9a-f]{40}$\|m` | `$` breaks on the trailing comment. |
| `ci_workflow_parity_contract_test.exs:2336` | `String.contains?(yaml, "actions/cache@v5")` | Tag text disappears. |
| `ci_workflow_parity_contract_test.exs:4204, 4296-4299, 4106` | `"uses: actions/cache/restore@v5"`, `"uses: actions/cache/save@v5"` (the rule=combined-action logic and its remedy text) | Exact-string checks on live job text. |
| `ci_workflow_parity_contract_test.exs:5258-5266` | mutation `replace_in_step(..., "actions/cache/restore@v5", "actions/cache@v5")` | Becomes a no-op, so the control stops going red. Mutate the action path before `@`. |
| `ci_workflow_parity_contract_test.exs:2802, 2841` | `setup_line = "      - uses: erlef/setup-beam@v1"`, used as a replace anchor in live-job mutations | The anchor vanishes, so the mutations become no-ops. |
| `ci_topology_contract_test.exs:814, 824` | `"uses: actions/cache/restore@v5"` / `"…/save@v5"` in the live verify-dialyzer job | Exact-string. |
| `browser_journey_evidence_contract_test.exs:80, 103` | `test_job =~ "uses: actions/setup-node@v5"`, `browser_job =~ "actions/upload-artifact@v7"` | Exact-string. |
| `flake_classifier_contract_test.exs:538` | `@heavy_steps` marker `"- uses: erlef/setup-beam@v1"`, split against live flake-detection.yml (`:545-548`) | `String.split` returns one element, so the 2-element match raises. |
| `ci_workflow_parity_contract_test.exs:5820-5842, 5882` | Synthetic fixture with `node-version: "22"` and tag refs | Not live. Update it so fixtures model the canonical form (the D-13 list). |

These are already pin-safe (prefix-only matching): `step_uses/1` at `:4571-4576` and the `uses |> String.split("@") |> hd()` at `:4516`; `setup_node_step?/1` at `:4677` (`actions\/setup-node@`); `browser_full_projects_contract_test.exs:526` (`"uses: actions/setup-node@"`).

Synthetic-only fixtures that are not scanned against live files (leave them, or modernize them for consistency): `hex_pin_contract_test.exs:371-430`, `repo_hygiene_contract_test.exs:159-160`, `retry_network_contract_test.exs:688, 922` (`nick-fields/retry@v3`, a negative fixture), `ci_workflow_parity_contract_test.exs:2904-2907, 3118-3120, 4909-4967, 5525-5663, 5725-5782`.

**Executor recipe:** after pinning, run `git grep -nE '@v[0-9]+|alls-green@\[0-9a-f\]\{40\}(\\\\n|\$)' -- test/` and then the full `mix test` on an ephemeral Postgres. The list above is complete for live-file coupling as of `ddf3cb88`, but a grep is cheaper than trusting it.

### Docs and prose that change

- `CONTRIBUTING.md:656-662`: the Dependabot sentence (D-06) and the "batched per release train … `mix hex.outdated`" text.
- `CONTRIBUTING.md:677-689`: the weekly or Monday cron, the `outdated` phrasing ("an `outdated` result alone stays green") and the classes.
- `CONTRIBUTING.md:885-886`: `actions/cache/restore@v5` prose. It is not a live `uses:` line and can stay as prose.
- `CONTRIBUTING.md:1126-1149`: the release-please runbook. It must still contain `googleapis/release-please-action@v5` (the `:148` check). **Step 5 (`:1147`) says the log shows `Download action repository 'googleapis/release-please-action@vN'`; after pinning, the runner log shows the SHA. Update it.**
- `test/threadline/deps_health_doc_contract_test.exs:157-171`: the Dependabot sentence and the `refute File.exists?` on `dependabot.yml` (D-06), plus `assert section =~ "hex.outdated"` at `:162` (D-24).
- `.github/workflows/deps-health.yml` comments at `:1-12, :54-59, :97-102, :117-122`, the step names at `:31, :50`, `label-description` at `:94`, and the fail-step `if:` at `:124`.

### `outdated` and `hex.outdated` occurrences (D-24, D-29)

- `bin/deps-health-report`: `:12, :19-33` (header), `:49`, `:91-106` (`RANK_NAMES=(clean outdated unknown advisory)`, `rank_of`), `:222, :232, :259` (skipped lines), `:279-291` (invocation and bump).
- `test/threadline/deps_health_report_test.exs`: `:9` (moduledoc precedence), `:88-94` (fake `hex.outdated` arm), `:171-179`, `:181`, `:194-203`, `:262`, `:319, :341, :356, :371, :423-431` (refutes, which stay valid), `:500-508` (`fail step exempts only 'clean' and 'outdated'`).
- `test/threadline/deps_health_doc_contract_test.exs:162, :220`.

## Script structure (open item 5)

### `bin/verify-deps-audit` (392 lines, `set -euo pipefail`)

| Lines | Element | Phase 245 change |
|---|---|---|
| 53-56 | `die()` exits **2** | Keep. Unclassifiable cases use `FAILURES+=` (exit 1), not `die`, so per-directory aggregation stays. |
| 58-60 | `SCRIPT_DIR`, `ROOT`, `MIX_BIN="${MIX_BIN:-mix}"` seam | `source "$SCRIPT_DIR/deps-audit-tier"` goes here. Precedent: `bin/verify-clean-checkout:6-7` (`# shellcheck source=bin/safe-temp-tree` + `source "$SCRIPT_DIR/safe-temp-tree"`). |
| 66 | `MIN_HEX="2.6.0"` | Unchanged (`hex_pin_contract_test.exs` couples to it). |
| 99-205 | `--self-test` cases (a)-(d) | (a) `:124-126` greps human output (`Advisories:`, `plug 1.19.1`). Switch it to the machine line `deps-audit-finding tier=blocking … package=plug id=EEF-CVE-2026-54892`. Add (e) after (d), and update the summary line at `:203`. |
| 210 | `CANONICAL_DIRS=(. bench examples/threadline_phoenix)` | `deps_health_doc_contract_test.exs:120` asserts both scripts declare an identical literal. Keep it byte-identical. |
| 262-316 | `read_global_hex_ignore`, `refuse_global_hex_ignores` | Unchanged (D-20). Note `:294` sets `trap … EXIT` and `:313` clears it. A new SARIF temp trap must compose with this rather than overwrite it later. Prefer one cleanup function registered once. |
| 334-342 | lock hygiene, with the FAIL text that always blames "an empty build-manager list" | R2-IN-01: branch on `hygiene_status`. `bin/verify-lock-hygiene` exits 1 for a `[]` manager list and 2 for usage, missing file, parse error or a malformed entry (`bin/verify-lock-hygiene:21-26`). |
| 352-363 | `deps.get --check-locked` via `retry-network`; `continue` on failure | Run `deps.tree` only after this succeeds (closure-rule directories only). |
| 365-373 | `deps.unlock --check-unused` | Unchanged. |
| 375-383 | `"$MIX_BIN" hex.audit` → FAIL on non-zero | Replace with the SARIF call plus tier classification. Blocking findings go to `FAILURES`; non-blocking findings print `::warning::` and machine lines and leave status 0. |
| 386-392 | aggregate exit / success line | Success line gains the non-blocking count (D-23 case 11). |

### `bin/deps-health-report` (337 lines, `set -uo pipefail`, always exits 0)

| Lines | Element | Phase 245 change |
|---|---|---|
| 2-58 | header | Rewrite `:9-33` (precedence) and `:49` (class list), per D-29. |
| 74 | `CANONICAL_DIRS` | Keep byte-identical to verify-deps-audit. |
| 87-89 | `strip_ansi()` | Reuse. |
| 91-114 | `RANK_NAMES=(clean outdated unknown advisory)`, `rank_of`, `bump` | Becomes `RANK_NAMES=(clean unknown retirement advisory)` with ranks 0-3. D-29 requires CONTRIBUTING's class set to equal `RANK_NAMES`. |
| 137-209 | suppression check → `unknown` | Unchanged. |
| 211-292 | per-directory loop | `:250-253`: emit the `deps.get` output only when fetch fails (D-26). `:265-277`: replace with the shared SARIF helper and bump `advisory` / `retirement` / `unknown`. `:279-291`: delete `hex.outdated`. |
| 300-326 | body assembly, 60000-byte cap | Add the two tier sections (D-27). The title line `# Dependency health: <class>` at `:310` stays. |
| 328-337 | `classification=` to stdout and `$GITHUB_OUTPUT` | Values become {clean, retirement, advisory, unknown} only (D-29). |

For `bin/verify-action-pins` in this lane, add a seam such as `VERIFY_ACTION_PINS_BIN="${VERIFY_ACTION_PINS_BIN:-$SCRIPT_DIR/verify-action-pins}"`. **Every existing `deps_health_report_test.exs` run must set it to a fake that exits 0.** Otherwise the offline suite calls real `gh` through the `run_report/2` base env (test:122-131). An alternative is a separate workflow step whose result is passed in as an env var. The seam keeps D-25's "reason at top of report" inside the unit-tested script.

### `bin/upsert-ci-issue` (61 lines)

- `:46` lists `--json number,title`, so the current title is already in `$matches`.
- The update arm is `:59`. Add the following before `issue comment`: `cur=$(jq -r '.[0].title')` and, if it differs, `"$GH_BIN" issue edit "$number" --title "$title" >/dev/null`. The number is already validated against `^[0-9]+$`, and the title travels only as argv.
- **The test fake gh exits 9 on any unknown subcommand** (`ci_issue_upsert_contract_test.exs:19-28`). Add an `issue edit` arm to it, plus rows for "same title → no edit call" and "different title → `issue edit 41 --title …` before the comment".
- Callers: `deps-health.yml:91`, `flake-detection.yml:297`, `browser-full.yml:194`. The retitle applies to all three. `browser-full.yml` passes `--title "$TITLE_PREFIX"` (equal to the marker), so it never retitles. Flake's #36 is CLOSED today ("Flake Detection: test suite reported unknown").

### Live state (read-only)

- Issue #61: OPEN, title `Dependency health: outdated`, label `ci-deps` [VERIFIED: `gh issue view 61`].
- All three locks audit clean today via SARIF (`results: []`), so the first post-merge clean run retitles #61, comments and closes it (D-28) [VERIFIED: real runs].
- `sha_pinning_required: false`, `allowed_actions: all` [VERIFIED: `gh api .../actions/permissions`].
- `dependabot_security_updates: disabled`, vulnerability alerts off (404), automated security fixes `enabled:false` [VERIFIED: `gh api`]. This matches CONTEXT `<specifics>` ("Leave 'Dependabot security updates' off").
- `ci.yml` references no `secrets.` (grep), so Dependabot-authored PRs, which get a read-only token and no Actions secrets, can run required CI unchanged.

## Dependabot config (open item 6)

Schema checked against the [Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) [CITED]:

- `cooldown.default-days` is valid for every ecosystem. The `semver-*-days` keys apply only to SemVer package managers, and github-actions was not in that list as read. **Cooldown does not apply to security updates.** There is a default 3-day cooldown for version updates even when unset.
- `groups.<name>.applies-to`: `version-updates` | `security-updates` (the default is version-updates). `patterns` supports `*`. Groups include **all semver levels by default**. "Any outdated dependencies that do not match a rule are updated in individual pull requests."
- `commit-message.prefix` can be up to 50 characters; a colon is auto-inserted after an alphanumeric prefix. `include: scope` appends `(deps)` / `(deps-dev)`.
- `schedule.interval: monthly` is valid.
- `open-pull-requests-limit` defaults to 5; setting it to 0 disables version updates.
- For github-actions, `directory: "/"` scans `/.github/workflows`.

Recommended file (meets D-02, D-03 and D-05):

```yaml
# Keeps SHA-pinned GitHub Actions current (SUP-01). Hex is not served by
# Dependabot; Hex advisories come from mix verify.deps_audit and the
# deps-health issue. Contract: test/threadline/dependabot_config_contract_test.exs
version: 2
updates:
  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: monthly
    cooldown:
      default-days: 7
    groups:
      github-actions:
        applies-to: version-updates
        patterns:
          - "*"
    commit-message:
      prefix: ci
      include: scope
```

D-04/D-05 releasability derivation [VERIFIED: release-please-config.json read]: the non-hidden `changelog-sections` types are `feat`, `fix`, `perf`, `deps`, and `chore` is `"hidden": true`. `ci` is absent, so it is not releasable. The contract derives the set as `for %{"type" => t} = s <- sections, s["hidden"] != true, do: t` and asserts the prefix is not a member.

The workflow `LABEL:` values are `ci-browser-full` (browser-full.yml:177, 208), `ci-deps` (deps-health.yml:65, 108) and `ci-flake` (flake-detection.yml:244, 312). The config has no `labels:` key, so the disjointness check passes trivially.

## Architecture Patterns

### Data flow

```
PR / push-to-main                      daily cron / push(lockfiles) / dispatch
      |                                              |
ci.yml verify-deps-audit (required)        deps-health.yml deps-health
      |                                              |
bin/verify-deps-audit                     bin/deps-health-report ----> bin/verify-action-pins (gh api)
  floor -> ignore refusal                   suppression check               | mismatch -> unknown
  per dir: hygiene -> deps.get --check-locked -> deps.unlock --check-unused
      |                                              |
      +----------- source bin/deps-audit-tier -------+
                    | hex.audit --format sarif --output <fresh>
                    | deps.tree --only prod (closure-rule dirs only)
                    | classify(dir role, closure, fingerprint)
                    v
   blocking -> FAILURES (exit 1)       advisory > retirement > unknown > clean
   non-blocking -> ::warning:: (exit 0)          |
                                       != clean -> upsert-ci-issue (retitle, comment) + fail job
                                       == clean -> upsert-ci-issue --close
```

### `bin/deps-audit-tier` shape (recommended: sourced library, bash 3.2-safe)

- Functions:
  - `dat_closure DIR OUTFILE`: runs `"$MIX_BIN" deps.tree --only prod --format plain` and writes one sorted name per line. Returns non-zero if the command fails, or if the closure is empty for a closure-rule directory.
  - `dat_audit DIR SARIF_PATH`: runs the audit and returns its status.
  - `dat_findings SARIF_PATH`: the jq TSV above.
  - `dat_tier DIR_REL PACKAGE CLOSURE_FILE`: echoes `blocking` or `non-blocking`, using `grep -Fxq` against the closure file.
- No `declare -A`. The scripts use `#!/usr/bin/env bash`, and macOS `/bin/bash` is 3.2. The existing scripts already avoid bash 4 features (see `SEEN_DIRS` loops at `bin/verify-deps-audit:217-225`).
- Temp files go under `$ROOT/tmp/` (gitignored, `.gitignore:45`). Cleanup goes through the caller's single EXIT trap.

### Anti-patterns

- **Reading `hex.audit` exit status as the tier signal.** Exit 1 means "some finding exists"; it says nothing about which tier.
- **Parsing human `hex.audit` output** for classification. It is display only (D-18).
- **Parsing `deps.get` output.** It prints advisories and exits 0 (observed this session: "Found packages with security advisories, see above for details", with deps.get exit 0).
- **Pre-creating or reusing the SARIF path.** A failed audit leaves a stale file intact (verified).
- **Regex-only workflow contracts.** Phase 220 showed they can be bypassed. Pair the raw scan with a YamlElixir parse (`merge_anchors: true`, the `ci_token_permissions_contract_test.exs:123` idiom) for PIN-PARITY.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Hex advisory data | A custom OSV or advisory fetcher; mix_audit | `mix hex.audit --format sarif` | Ignores, aliases and registry freshness are already handled. A versioned `hexAudit/v1` fingerprint is the documented contract. |
| Runtime closure | Walking `mix.lock` dep lists by hand | `mix deps.tree --only prod --format plain` | Honours `only:`, `optional:` and transitive edges exactly as Mix resolves them. |
| JSON parsing in bash | sed/grep over SARIF | `jq` (already required by `bin/upsert-ci-issue`) | SARIF messages contain quotes, parentheses and URLs. |
| YAML parsing in contracts | Regex-only scans | `YamlElixir.read_from_string!(…, merge_anchors: true)` plus the raw scan (PIN-PARITY) | Anchors, aliases, flow style and quoted keys (phase 220). |
| Pin currency | A scheduled script that bumps SHAs | Dependabot github-actions | It rewrites the SHA and the exact-tag comment together. |
| Tag → commit dereference | Trusting `git/ref/tags` | `git/ref/tags/T`, then `git/tags/<sha>` when `.object.type == "tag"` | setup-beam, release-please and alls-green use annotated tags. |

## Common Pitfalls

### Pitfall 1: Wrong retirement fingerprint prefix
**What goes wrong:** a parser keyed on `retirement:` or on `:<id>` silently drops every retirement, or treats it as unparseable.
**How to avoid:** use the regex from §Parsing recipe; `retired:hexpm/<pkg>` has no id. Build fixtures from the real snippet above.
**Warning signs:** a retirement fixture classifies as `unknown`, or as clean.

### Pitfall 2: Stale or missing SARIF file read as clean
**What goes wrong:** on a registry failure, Hex raises before writing anything. A reused path still holds the previous clean `[]`.
**How to avoid:** use a fresh `mktemp -d` per call, never pre-create the file, and FAIL if the file is absent.

### Pitfall 3: `deps.tree` before fetch, or a legitimately empty closure
**What goes wrong:** run before `deps.get`, the tree exits 0 with only top-level deps. A test-only fixture also yields an empty closure.
**How to avoid:** call `deps.tree` after a successful `--check-locked`. Use the two-dep case (e) fixture.

### Pitfall 4: Self-test project dirs classified as non-root
**What goes wrong:** case (a) goes green, because "not the root lock" means non-blocking.
**How to avoid:** use the directory-role rule. Only `bench` and `examples/threadline_phoenix` are always non-blocking.

### Pitfall 5: The first Dependabot PR is majors-only and goes red
**What goes wrong:** every pin is already at its latest release within its major. Pending updates are only checkout v7, cache v6 (with restore and save), setup-node v7 and github-script v9. Dependabot groups include majors by default [CITED: options reference], and Dependabot proposes the newest tag for a SHA plus version-comment pin [ASSUMED]. So the first monthly grouped PR is majors-only. The `{action, major}` allowlist fails closed on it (D-12), and 216 had deferred these majors.
**How to avoid:** do not add `ignore` or `update-types` (D-03 and D-05 lock the shape). Record it as a deferred-to-landing expectation. Handle that PR as a normal major review: `runs.using` is already confirmed as node24 for all four, and you add allowlist entries. Per D-07, if it touches `release.yml` (github-script), run release-shape and bump-rehearsal first.
**Warning signs:** someone loosens the runtime allowlist to make the Dependabot PR green. That is forbidden by the D-32 halt clause.

### Pitfall 6: Trailing-comment anchors in existing tests
**What goes wrong:** `@[0-9a-f]{40}\n` and `@[0-9a-f]{40}$` stop matching once `# v1.3.0` is appended.
**How to avoid:** see the §Blast radius table. Fix the anchors in the same atomic commit.

### Pitfall 7: setup-node's `.tool-versions` regex
**What goes wrong:** setup-node v5.0.0 uses `contents.match(/^(?:node(js)?\s+)?v?(?<version>[^\s]+)$/m)` and falls back to `contents.trim()` [VERIFIED: actions/setup-node@a0853c24 src/util.ts]. The `node(js)?` prefix is **optional**, so the **first single-token line** anywhere in the file wins, and that includes a bare comment line such as `#pinned`. Multi-token lines (`erlang 27.3.4.15`) never match.
**How to avoid:** besides NODE-PIN, have the contract assert that no other line of `.tool-versions` is a single token. Docs: "If both the `node-version` and the `node-version-file` inputs are provided then the `node-version` input is used" [CITED: setup-node advanced-usage.md]. That is why NODE-FILE must forbid `node-version`.

### Pitfall 8: New test files missing from the partition inventory
**What goes wrong:** `test/partition_weights.txt` says "The committed-inventory CI contract rejects either condition" (stale or missing weights).
**How to avoid:** add `ci_action_pin_contract_test.exs` and the Dependabot contract file to `test/partition_weights.txt` (sorted by path; regenerate with `bin/ci-test-partitions --write-weights`, or add a measured line by hand).

### Pitfall 9: The offline suite calling real `gh`
**What goes wrong:** wiring `bin/verify-action-pins` into `bin/deps-health-report` without a seam makes `deps_health_report_test.exs` do network work.
**How to avoid:** add the `VERIFY_ACTION_PINS_BIN` seam and default it to a fake in `run_report/2`.

### Pitfall 10: Two EXIT traps in one script
**What goes wrong:** `refuse_global_hex_ignores` sets and clears its own EXIT trap (`:294`, `:313`), and the self-test sets another (`:109`). Adding a third `trap … EXIT` silently replaces the earlier one.
**How to avoid:** use one cleanup function that removes a list of registered paths.

## Code Examples

### Pin form (canonical, D-08)

```yaml
      - uses: actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5.1.0
      - uses: erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124 # v1.24.1
        uses: re-actors/alls-green@b5b5b37504aa4183270bd3d855c52a67f212be35 # v1.3.0
      - uses: actions/setup-node@a0853c24544627f65ddf259abe73b1d18a591444 # v5.0.0
        with:
          node-version-file: .tool-versions
          cache: npm
          cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json
```

PIN-FORM regex (raw line, comment lines stripped first):
`~r/^\s*(?:-\s+)?uses: ([a-z0-9][a-z0-9-]*\/[A-Za-z0-9._-]+(?:\/[A-Za-z0-9._\/-]+)?)@([0-9a-f]{40}) # (v\d+\.\d+\.\d+)\s*$/`

### Major from the comment (D-12 re-key)

```elixir
# {action, major} from "owner/repo@<40hex> # vX.Y.Z"
~r/uses:\s*([^\s@"']+)@[0-9a-f]{40}\s+#\s*(v\d+)\.\d+\.\d+/
```

### D-33 (optional)

```yaml
      - name: Wait for ci.yml success on release SHA
        uses: actions/github-script@ed597411d8f924073f98dfc5c65a23a2325f34cd # v8.0.0
        env:
          RELEASE_SHA: ${{ needs.release-ref.outputs.release_sha }}
        with:
          script: |
            const sha = process.env.RELEASE_SHA;
```

No test pins the current `const sha = '${{` text (grep over `test/`).

## State of the Art

| Old approach | Current approach | When changed | Impact |
|---|---|---|---|
| Floating `@vN` tags | Full SHA plus exact-tag comment, kept current by Dependabot | tj-actions CVE-2025-30066 (2025-03) | Tags can be moved; SHAs cannot. |
| Repo-level "allowed actions" only | `sha_pinning_required` policy | GitHub changelog 2025-08-15 | The field exists on this repo's API response and is `false` [VERIFIED]. |
| Parsing human `hex.audit` output | `--format sarif` with the `hexAudit/v1` fingerprint | Hex 2.6.0 | Machine contract; requires OTP 27. |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | Dependabot, for a SHA plus `# vX.Y.Z` pin, proposes the newest tag (including a new major) and rewrites the comment | Pitfall 5 | Low. If it proposed only within the major, the first PR would be empty, which is better. |
| A2 | `jq` and `gh` are preinstalled on `ubuntu-24.04` runners | Standard Stack | Low. `bin/upsert-ci-issue` already depends on both in three workflows that run green. |
| A3 | A Dependabot config error, or the accepted run, is observable read-only through the "Dependabot Updates" workflow runs (`gh run list --event dynamic`) or the repo's Insights → Dependency graph → Dependabot tab | Validation (D-31) | Medium. If no API shows it, the D-31 post-landing check becomes "the first grouped PR appears or no error banner"; record it as deferred-to-landing either way. |
| A4 | Hex organization repos appear as `hexpm:<org>` in the fingerprint repo segment | §Parsing recipe | Low. Not used here, and the regex tolerates it. |

## Open Questions (RESOLVED)

1. **RESOLVED: What does the first Dependabot PR mean for D-31's "first grouped PR" check?**
   - What we know: it will be majors-only (Pitfall 5).
   - Recommendation: the D-31 check is "Dependabot accepted the config and opened a grouped PR, or reported no updates". The PR going red on the runtime allowlist is the expected behaviour, not a phase failure. Record this in the VERIFICATION deferred-to-landing list.
   - RESOLVED: adopted by plan 245-05 Task 3, which records the D-31 config-accepted / first-grouped-PR observation (a red PR on the runtime allowlist is expected) as deferred-to-landing.
2. **RESOLVED: D-18 says human output is "printed for display only". Should it be one `hex.audit` call or two?**
   - Recommendation: one SARIF call, displaying each result's `.message.text`. That avoids a second registry fetch and any chance the two outputs disagree, and stays within Claude's discretion over the helper's shape. If the planner keeps a human call for display, it must never feed classification.
   - RESOLVED: adopted by plan 245-01 Task 1 (`dat_audit` makes the single `hex.audit --format sarif --output` call; no second human-format call) and reused by plan 245-02.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|---|---|---|---|---|
| Hex client | SARIF audit | yes | 2.6.0 | — |
| Erlang/OTP | SARIF (`:json`) | yes | 27.3.4.15 | none; OTP<27 fails closed (D-19) |
| jq | SARIF parsing | yes | 1.7.1 | — |
| gh (authenticated) | pin resolution and verify-action-pins evidence | yes | 2.101.0 | — |
| Docker | ephemeral postgres:16 for the phase gate | yes | 29.5.2 | — |
| actionlint | optional local workflow lint | yes | 1.7.12 | skip |
| zizmor / pinact | not used (D-11) | no | — | not needed |
| Network to hex.pm | `--self-test`, `verify.deps_audit` in `ci.all` | yes (observed) | — | none; those steps are network-bound by design |

Gotcha: running `mix` in a directory outside the repo with no `.tool-versions` fails under asdf ("No version is set for command mix"). Self-test temp projects live under `$ROOT/tmp/`, which inherits the repo's `.tool-versions`, so this does not apply to them.

## Validation Architecture

### Test framework

| Property | Value |
|---|---|
| Framework | ExUnit (Elixir 1.17.3, OTP 27). `test_helper.exs` needs Postgres. |
| Config file | `test/test_helper.exs`; partition inventory in `test/partition_weights.txt` |
| Quick run command | `mix test test/threadline/<file>_test.exs` (an ephemeral postgres:16 is needed for the helper's migrations) |
| Full suite command | `CI=true mix ci.all` on an ephemeral postgres:16; also `bin/verify-repo-hygiene` and `mix verify.credo` |

### Phase requirements → test map

| Req | Behavior | Type | Automated command | File exists? |
|---|---|---|---|---|
| SUP-01 | Config shape (one github-actions entry, monthly, cooldown ≥7, one `*` group, non-releasable prefix, no target-branch, limit ≠ 0) plus 4 mutation controls | unit contract | `mix test test/threadline/dependabot_config_contract_test.exs` | ❌ Wave 0 |
| SUP-01 | The doc sentence is replaced and the `refute dependabot.yml` is inverted | doc contract | `mix test test/threadline/deps_health_doc_contract_test.exs` | ✅ (edit) |
| SUP-01 | GitHub accepted the config | post-landing observation | `gh run list --repo szTheory/threadline --event dynamic --limit 5` [A3] | deferred-to-landing |
| SUP-02 | Every live ref is SHA plus exact tag; PIN-SCAN/PARITY/FORM/LOCAL/DOCKER/CONSISTENT/NODE-FILE/NODE-PIN, each with its mutation control, including tag-only `actions/checkout@v5` | unit contract | `mix test test/threadline/ci_action_pin_contract_test.exs` | ❌ Wave 0 |
| SUP-02 | Runtime allowlist keyed `{action, major}`; runbook major read from the comment | unit contract | `mix test test/threadline/ci_action_runtime_contract_test.exs` | ✅ (edit) |
| SUP-02 | Existing live-workflow contracts still green after pinning | unit contracts | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/browser_journey_evidence_contract_test.exs test/threadline/flake_classifier_contract_test.exs test/threadline/browser_full_projects_contract_test.exs` | ✅ (edit) |
| SUP-02 | `bin/verify-action-pins` match, mismatch, annotated-tag deref and gh failure, via a fake `GH_BIN` | unit (script) | `mix test test/threadline/verify_action_pins_test.exs` | ❌ Wave 0 |
| SUP-02 | Every pin is real against its tag | network evidence | `bin/verify-action-pins` (run at pin time; output pasted into the SUMMARY) | ❌ Wave 0 |
| SUP-03 | D-23 cases 1-12 through a fake `MIX_BIN` with SARIF and deps.tree fixtures | unit (script) | `mix test test/threadline/deps_audit_gate_test.exs` | ✅ (extend) |
| SUP-03 | Live closure contains every root dep without `only:` and none of credo/dialyxir/ex_doc/lazy_html/stream_data/yaml_elixir | live-tree contract | `mix test test/threadline/deps_audit_gate_test.exs` (new describe) | ✅ (extend) |
| SUP-03 | Real-Hex downgrade proof (case e) and red proof (case a) | network CI step | `bin/verify-deps-audit --self-test` | ✅ (extend) |
| SUP-03 | The job keeps no `issues: write`; the self-test step stays unconditional | unit contract | `mix test test/threadline/ci_token_permissions_contract_test.exs test/threadline/deps_audit_contract_test.exs` | ✅ |
| SUP-04 | Class arms, precedence, `hex.outdated` never invoked, `GITHUB_OUTPUT` value set, tier sections | unit (script) | `mix test test/threadline/deps_health_report_test.exs` | ✅ (rewrite) |
| SUP-04 | Workflow shape: fail exempts only `clean`; upsert `!= 'clean'`; close `== 'clean'`; push path filter = the 3 dirs × {mix.exs, mix.lock}; daily cron in CONTRIBUTING | unit contract | `mix test test/threadline/deps_health_report_test.exs test/threadline/deps_health_doc_contract_test.exs` | ✅ (edit) |
| SUP-04 | Update mode retitles only when the title differs | unit (script) | `mix test test/threadline/ci_issue_upsert_contract_test.exs` | ✅ (extend) |
| SUP-04 | #61 retitles and closes itself | post-landing observation | `gh issue view 61 --json state,title` | deferred-to-landing |

### Sampling rate

- **Per task commit:** the touched test files (the quick run commands above).
- **Per wave merge:** `mix test` (full default suite) on an ephemeral postgres:16.
- **Phase gate:** `CI=true mix ci.all`, `bin/verify-repo-hygiene` and `mix verify.credo`, then an observed PR CI run (D-30, D-31).

### Wave 0 gaps

- [ ] `test/threadline/dependabot_config_contract_test.exs`, covering SUP-01 (and register it in `test/partition_weights.txt`)
- [ ] `test/threadline/ci_action_pin_contract_test.exs`, covering SUP-02 (register it)
- [ ] `test/threadline/verify_action_pins_test.exs`, or a describe in an existing file, covering D-14 (register it if new)
- [ ] SARIF and `deps.tree` fixtures for the fake `MIX_BIN`: inline heredocs or files under `test/fixtures/deps_audit/sarif/`, built from the real snippet above
- [ ] `ci_issue_upsert_contract_test.exs` fake-gh `issue edit` arm

## Security Domain

| ASVS category | Applies | Standard control |
|---|---|---|
| V1/V14 Build & deploy (supply chain) | yes | SHA-pinned actions, pin provenance check, Dependabot cooldown, required tiered audit |
| V5 Input validation | yes | SARIF and fingerprints from Hex are untrusted text: parse with jq, use a strict regex, never `eval`. Issue titles and markers travel only as argv (`bin/upsert-ci-issue:18-20`). |
| V2/V3/V4 AuthN/session/access | partly | Token least privilege: `verify-deps-audit` has no `issues: write` (D-21); deps-health keeps `contents: read` + `issues: write`; Dependabot PRs get a read-only token |
| V6 Cryptography | no | — |

| Threat pattern | STRIDE | Mitigation |
|---|---|---|
| Moved or compromised tag (tj-actions) | Tampering | SHA pins, `bin/verify-action-pins`, 7-day cooldown, later `sha_pinning_required` |
| Impostor commit from the fork network | Spoofing | Dereference the tag through `gh api` and compare (D-14) |
| Advisory suppressed via env or global config | Repudiation | Existing refusal, kept (D-20) |
| A registry outage masquerading as clean | Tampering/DoS | Fresh SARIF path; a missing file or empty-on-nonzero result is a FAIL (Pitfall 2) |
| Expression injection in github-script | Elevation | D-33 `env:` indirection |
| Malicious YAML defeating regex contracts | Tampering | PIN-PARITY (YAML parse vs raw scan) |

## Sources

### Primary (HIGH)
- hexpm/hex v2.6.0 `lib/mix/tasks/hex.audit.ex` and `lib/hex/sarif.ex`, read in full through `gh api repos/hexpm/hex/contents/...?ref=v2.6.0`
- Real `mix hex.audit --format sarif` runs: the vulnerable fixture, retired `plug 1.20.0`, all-ignored, registry-unreachable, and the three repo locks
- Real `mix deps.tree --only prod --format plain` runs: root (dev and test env), the fixture with and without `deps/`, and case (e)
- `gh api` tag dereference for all 8 actions; `action.yml` `runs.using` at the current and next majors
- actions/setup-node `src/util.ts` at `a0853c24…` (v5.0.0)
- Repo files read this session: bin/verify-deps-audit, bin/deps-health-report, bin/upsert-ci-issue, bin/verify-lock-hygiene (header), deps-health.yml, ci.yml (verify-deps-audit job, setup-node steps, alls-green), release.yml:385-410, release-please-config.json, mix.exs deps and ci.all, ci_action_runtime_contract_test.exs, the listed test line ranges, CONTRIBUTING.md:640-720 and :1126-1149, test/partition_weights.txt header

### Secondary (MEDIUM)
- [Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference): cooldown, groups, commit-message, limits, directory
- [setup-node advanced usage](https://github.com/actions/setup-node/blob/main/docs/advanced-usage.md): `.tool-versions` listed; `node-version` wins over `node-version-file`

### Tertiary (LOW)
- Web search on Dependabot "dynamic" runs. It confirmed only that such runs exist, so A3 stays ASSUMED.

## Metadata

**Confidence breakdown:**
- Hex SARIF / tiering: HIGH. Source plus real runs cover every branch the parser needs.
- Pins / blast radius: HIGH. Re-resolved live; test coupling read line by line.
- Dependabot behaviour after landing: MEDIUM. The schema is cited; the first PR's content is inferred (A1).

**Research date:** 2026-10-25
**Valid until:** 2026-11-24. Re-resolve SHAs at execution time anyway (D-09), and re-check if Hex releases 2.7.
