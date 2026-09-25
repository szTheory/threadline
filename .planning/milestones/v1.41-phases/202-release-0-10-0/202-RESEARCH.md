# Phase 202: Release 0.10.0 - Research

**Researched:** 2026-09-22
**Domain:** Elixir/Hex release engineering — release-please wiring, Hex publish pipeline, doc-contract enforcement, storage-schema default flip
**Confidence:** HIGH (mechanisms below are verified by direct source read or live local experiment; two items remain ASSUMED and are logged)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

D-01..D-20, verbatim from `202-CONTEXT.md` (see that file for full prose; summarized pointers below since the full text is long — the planner MUST read `202-CONTEXT.md` directly, this is not a substitute):

- **D-01**: Flip `Threadline.StorageSchema` `@default` from `"threadline"` to `"public"`. One-way (hex.pm has no unpublish beyond ~1h). New default makes 0.10.0 non-breaking for the pre-0.10 population.
- **D-02**: `mix threadline.install`, installer docs, `guides/getting-started-saas.md` must steer NEW installs to opt into the dedicated schema.
- **D-03**: Add an end-to-end test proving a legacy `public`-schema install reads green on 0.10.0. Hex evaluator fixture is the natural home (ties to D-08).
- **D-04**: `mix release.pins` task rewrites the six pins in README + guides from `@version`, keeping the `major.minor.0` derivation `version_truth_doc_contract_test.exs` already enforces. Pins are NOT added to release-please `extra-files`.
- **D-05**: RELEASE-02 narrows to: no version-bearing line requires a HAND edit; the minor-release pin bump is produced by `mix release.pins` and enforced by contract. Patch releases stay zero-edit (derivation is patch-invariant).
- **D-06**: Strengthen the contract to assert no `{:threadline, "~> …"}` pin line also carries an `x-release-please-version` marker (promote from code-comment convention to enforced invariant).
- **D-07**: Remove the version literal from `priv/ci/hex_evaluator` entirely. Mode-switch the dep: rehearsal mode (default) resolves from a throwaway local registry built by `mix hex.registry build` from this tree's own `mix hex.build` tarball; published mode (set only by `release.yml`) uses `== <version>` from hexpm. Exact match, not `~>`.
- **D-08**: `priv/ci/hex_evaluator/mix.lock` (currently tracked, pinning `threadline 0.9.0` from hexpm with a checksum) must be UNTRACKED and gitignored — this fixture's job is resolvability, not reproducibility. **NOTE — this research resolves the flagged-unverified Mix lock semantics claim; see "D-08 Mix Lock Semantics" below.**
- **D-09**: New `smoke-published` job in `release.yml` (stable job id), NOT in `ci-required`.
- **D-10**: `distribution-sync` gains `needs: smoke-published`.
- **D-11**: Split changelog ownership by FILE. `changelog-path` → `CHANGELOG-GENERATED.md` (bot-owned); `CHANGELOG.md` becomes human-owned, shipped in the tarball.
- **D-12**: Highlights accumulate under a standing `## Unreleased — highlights` block, retitled at release. Do NOT use `## [Unreleased]` (the `[` matches release-please's version-header regex). An orphaned `## [Unreleased]` block stranded below `0.7.0` (confirmed at line 43, between 0.7.0 at line 24 and 0.6.0 at line 56 — see "Verified" below) carries real adopter content and should be folded in and deleted.
- **D-13**: Section order: breaking changes / required action ABOVE the feature tour.
- **D-14**: Measured: 0 `BREAKING CHANGE` footers and 0 `!` subjects across all 317 commits since v0.9.0. Entry must still document the S3 dep swap and operator-surface routes (D-16).
- **D-15**: `guides/upgrade-path.md:89` needs re-scoping to the 0.10.x bump under D-01 (confirmed content at that line below).
- **D-16**: 0.9.x -> 0.10.x row must document: (1) `:hackney` → `{:req, "~> 0.7"}` S3 swap + `:ex_aws` floor `~> 2.4` → `~> 2.7` raise — VERIFIED; (2) new `POST <path>/theme` and `<path>/rows/:table/:record_id` routes; (3) `Threadline.Storage` `c:put/2` narrowed to binary (Dialyzer-visible); (4) ~23 modules became `@moduledoc false`.
- **D-17**: Keep `production-hex` environment human approval where it is (after `gate-ci-green`, before `mix hex.publish`). Document as CONFIRMATION, not peer review (single maintainer, `prevent_self_review: false`).
- **D-18**: Add `bin/verify-environment-protection` modelled on `bin/verify-branch-protection`, fail-closed.
- **D-19**: Document recovery procedure BEFORE publishing: within ~1h `mix hex.publish --revert`; after that `mix hex.retire` (warns, does NOT remove tarball/break lockfiles/move pinned consumers) + same-day patch.
- **D-20**: Narrow `mix.exs` `files:` to exclude `lib/mix/tasks/critic.*`, `lib/threadline/critic_trust/`, operator-surface stress/mechanical harness (~5,000 lines, measured closer to ~3,400 for the stress+mechanical files specifically — see "Verified" below). Add contract assertion they stay out.

### Claude's Discretion

Mechanism details left to research/planning: the exact `mix release.pins` implementation and whether it shares a derivation module with the contract (advisor recommended deliberate duplication, self-policed by CI); the rehearsal registry's CI wiring; retry/backoff shape for hex.pm CDN propagation.

### Deferred Ideas (OUT OF SCOPE)

- `.planning/` divergence between local and `origin/main` — not a release concern.
- hex.pm staging organisation as rehearsal target — evaluated and REJECTED (private-org publish exercises a different auth path, no public HexDocs rendering).
- Extending the module-group completeness assertion beyond this phase's needs (Phase 203 GATE-05 overlaps).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RELEASE-01 | 0.10.0 live on hex.pm, clean grouped HexDocs | D-01 storage-schema flip (makes publish safe), D-17 human-approval gate, D-19 recovery runbook, `bin/verify-release-shape` mechanics (verified below) |
| RELEASE-02 | Every version-bearing line managed by automation, no hand edits | D-04/D-05/D-06, `version_truth_doc_contract_test.exs` derivation (verified below), release-please generic-updater failure mode (verified in RELEASE-BLOCKERS.md, corroborated here) |
| RELEASE-03 | Hex evaluator validates the newly published release, not its predecessor | D-07/D-08, `mix hex.registry build` + `mix hex.repo add` mechanics (verified below), Mix lock-vs-requirement semantics (verified below by live experiment) |
| RELEASE-04 | 0.10.0 changelog opens with human-written highlights above generated list | D-11/D-12/D-13/D-14, CHANGELOG.md structure (verified below), `release_artifact_contract_test.exs` regexes (verified below, lines 6-11) |
| RELEASE-05 | Release-shape + post-publish distribution-sync checks pass against published tarball | D-09/D-10, `release.yml` job graph (verified below), `bin/verify-release-shape` + `bin/post-publish-distribution-sync` (read in full below) |
</phase_requirements>

<canonical_refs>
## Canonical References

Same list as `202-CONTEXT.md`'s `<canonical_refs>` block — not duplicated here. Read that file directly.

</canonical_refs>

## Summary

Phase 202 is a wiring phase, not a feature phase: every mechanism it touches already exists in the repo (release-please, Hex publish gate, doc-contract tests, `mix hex.registry`) and the work is (a) fixing the one behavior that would ship a silent breaking change (`StorageSchema` default), (b) closing four born-red gaps in the existing pipeline (pin lines, evaluator staleness, changelog split, post-publish smoke), and (c) adding two new fail-closed guards (`bin/verify-environment-protection`, `smoke-published`) that mirror an existing pattern (`bin/verify-branch-protection`) already in the tree.

The single most consequential finding from this research session is a **direct refutation of the "the lock overrides" framing** CONTEXT.md flagged as unverified (D-08). A live local experiment (throwaway Mix project, real Hex package, `mix.lock` deliberately stale relative to a changed `mix.exs` requirement) proves Mix does the OPPOSITE of silently trusting the lock:

- `mix compile` (or any command that does NOT re-resolve) with deps already checked out at the old version **fails closed**: `the dependency does not match the requirement "~> 1.4.0", got "1.0.1"` — `** (Mix) Can't continue due to errors on dependencies`.
- `mix deps.get`, when it CAN reach the registry, **silently re-resolves and rewrites `mix.lock`** to satisfy the new requirement — no confirmation prompt, no dry-run flag needed.

This has a direct design consequence for D-07/D-08's mode-switch: the rehearsal-vs-published dep swap in `priv/ci/hex_evaluator/mix.exs` MUST be paired with deleting the stale `mix.lock` (or running `mix deps.get` before `mix test`) in `verify.hex_evaluator`/`smoke-published`, or the job fails closed on a mismatched lock rather than silently validating the wrong version — which is actually the SAFER failure mode than the born-red risk CONTEXT.md worried about, but planning must account for it explicitly (a fresh `mix deps.get` step, not an assumption that the mode-switch alone suffices).

**Primary recommendation:** Sequence the phase as (1) `StorageSchema` default flip + D-02/D-03 tests — this is the irreversible, highest-consequence change and should land and be independently verified before anything else; (2) doc-contract-driving mechanics (`mix release.pins`, D-06 strengthening, changelog split, upgrade-path row) — all provable green-by-construction locally, no CI dependency; (3) hex evaluator mode-switch + gitignore the lock + D-03's legacy-schema fixture; (4) `release.yml` wiring (`smoke-published`, `distribution-sync` reorder, `bin/verify-environment-protection`); (5) open PR #26 fresh (or amend it) only after 1-4 are green locally via `mix verify.release`. Publishing itself stays the last, human-gated step — nothing in this phase should be gated on anything that can only become true after the publish (the organizing constraint CONTEXT.md states explicitly).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Storage-schema default resolution | Capture layer (`lib/threadline/storage_schema.ex`) | Semantics/Exploration (24 consumers) | `StorageSchema.get/1` is the single source every SQL-qualifying call site reads; the default lives in the capture layer but the blast radius spans audit, evidence, query, retention, continuity, and 6 operator-surface LiveViews (verified consumer list below) |
| Version-truth derivation | Build/Release tooling (`mix.exs` `@version`, doc-contract tests) | N/A | Pure Elixir, no runtime component — this is release engineering, not application architecture |
| Hex evaluator smoke test | CI/Release pipeline (`priv/ci/hex_evaluator`, `ci.yml`, `release.yml`) | N/A | A standalone Mix project exercising the published artifact from the outside; deliberately NOT part of the library's own test suite |
| Changelog generation vs. curation | Release automation (release-please → `CHANGELOG-GENERATED.md`) / Human (curated `CHANGELOG.md`) | N/A | File-level split is the mechanism (D-11); no shared module, no runtime code |
| Environment/branch protection verification | CI/Release pipeline (`bin/verify-*` scripts, live GitHub API reads) | N/A | Asserts properties of GitHub's live configuration, not of the commit under test — deliberately kept outside `ci-required` (see `branch-protection.yml` header, D-18 follows the same shape) |

## Standard Stack

### Core

| Tool | Version (verified) | Purpose | Why Standard |
|------|---------------------|---------|---------------|
| Hex (mix package manager client) | 2.5.1 [VERIFIED: `mix hex.info` on this machine, 2026-09-22] | Dependency resolution, registry management, publish | Bundled with Elixir/OTP toolchain this repo pins (`erlef/setup-beam@v1`, elixir 1.17.3 / otp 27.0 in `release.yml`) |
| release-please (googleapis/release-please-action) | v4 [VERIFIED: `.github/workflows/release.yml:95`, `uses: googleapis/release-please-action@v4`] | Conventional-commits-driven version bump + changelog PR | Already the sole release mechanism in this repo; no alternative under consideration |
| `mix hex.registry build` / `mix hex.repo add` | Bundled with Hex 2.5.1 [VERIFIED: `mix help hex.registry`, `mix help hex.repo` run locally, 2026-09-22] | D-07's rehearsal registry — builds a signed local package index from a `.tar`, then a repo is added by URL (HTTP, not `file://` — the built-in doc example spins up `erl -s inets`) | Confirmed present in this toolchain per `202-CONTEXT.md`'s "Reusable Assets" list; this research confirms the exact command shapes and the HTTP-serving requirement |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| local `mix hex.registry` rehearsal | hex.pm staging org | REJECTED per CONTEXT.md — different auth path, no public HexDocs rendering, buys rehearsal theatre not proof |
| `x-release-please-version`/`-minor` markers on pin lines | Custom release-please updater, or doc-build-time generation | REJECTED per CONTEXT.md D-04 — the generic updater writes the FULL version (wrong for a `.0`-pinned floor); component markers replace the wrong digit inside a compound `~> x.y.z` string (verified in RELEASE-BLOCKERS.md's `~> 10.9.0` failure case) |

**Version verification:** All tooling above is already pinned in this repo's CI (`erlef/setup-beam@v1` with `elixir-version: "1.17.3"`, `otp-version: "27.0"` in `release.yml:341-343`) and confirmed present on the local toolchain used for this research session (`ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27`). No new external package is being introduced by this phase — it is entirely wiring of existing, already-vetted tools. **Package Legitimacy Audit is therefore N/A** — this phase installs no new dependency.

## Package Legitimacy Audit

**Not applicable.** Phase 202 introduces zero new external packages. All tools involved (Hex client, release-please action, `mix hex.*` tasks) are already present and pinned in the repository. No `package-legitimacy check` run was needed.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────────────────────┐
                    │  Conventional commits land on main            │
                    └───────────────────┬─────────────────────────┘
                                        │
                                        ▼
                    ┌─────────────────────────────────────────────┐
                    │  release-please (push trigger)                 │
                    │  reads release-please-config.json +            │
                    │  .release-please-manifest.json                 │
                    │  writes: mix.exs @version, CHANGELOG-GENERATED │
                    │  .md (D-11 split), extra-files (adoption-pilot,│
                    │  evaluating-threadline)                        │
                    └───────────────────┬─────────────────────────┘
                                        │ opens/updates Release PR
                                        ▼
                    ┌─────────────────────────────────────────────┐
                    │  Release PR — must be GREEN BY CONSTRUCTION    │
                    │  (born-red today; this phase's core job)       │
                    │                                                 │
                    │  version_truth_doc_contract_test.exs:           │
                    │    Family A — install pins == major.minor.0     │
                    │      (bumped by `mix release.pins`, D-04)       │
                    │    Family B — x-release-please-version lines    │
                    │      match @version + registered in extra-files │
                    │    Family C — upgrade-path.md covers the         │
                    │      current-minor row                          │
                    │  release_artifact_contract_test.exs:            │
                    │    planning-vocabulary scan, package.files       │
                    │    allowlist, guide-extras parity                │
                    └───────────────────┬─────────────────────────┘
                                        │ maintainer merges PR #26
                                        ▼
                    ┌─────────────────────────────────────────────┐
                    │  release.yml push trigger (main)                │
                    │  release-please job re-runs → release_created   │
                    └───────────────────┬─────────────────────────┘
                                        │
                                        ▼
                    ┌─────────────────────────────────────────────┐
                    │  release-ref → gate-ci-green                    │
                    │  (polls ci.yml on release SHA, 60x30s = 30min)  │
                    └───────────────────┬─────────────────────────┘
                                        │ needs: [release-ref, gate-ci-green]
                                        ▼
                    ┌─────────────────────────────────────────────┐
                    │  publish-hex                                    │
                    │  environment: production-hex (D-17 human gate)  │
                    │  bin/verify-release-shape → mix hex.build       │
                    │  idempotency skip if already on Hex             │
                    │  mix hex.publish --yes                          │
                    │  poll hex.pm API 36x10s (6min) for index         │
                    └───────────────────┬─────────────────────────┘
                                        │ needs: [release-ref, publish-hex]
                                        ▼
                    ┌─────────────────────────────────────────────┐
                    │  ★ NEW: smoke-published (D-09)                  │
                    │  runs priv/ci/hex_evaluator in PUBLISHED mode   │
                    │  ({:threadline, "== <version>", repo: "hexpm"}) │
                    │  proves the JUST-published tarball installs and │
                    │  the legacy public-schema fixture (D-03) reads  │
                    │  green — NOT in ci-required (D-09)               │
                    └───────────────────┬─────────────────────────┘
                                        │ needs: [release-ref, publish-hex,
                                        │         smoke-published] (D-10)
                                        ▼
                    ┌─────────────────────────────────────────────┐
                    │  distribution-sync                              │
                    │  polls hex.pm API again, then                   │
                    │  bin/post-publish-distribution-sync rewrites    │
                    │  the Hex-attestation row in                     │
                    │  guides/adoption-pilot-backlog.md, opens PR     │
                    └─────────────────────────────────────────────┘
```

### Pattern: Fail-closed live-state verification, outside `ci-required`

**What:** A dedicated script (`bin/verify-branch-protection`) that reads GitHub's live configuration via `gh api`, fails loudly (non-zero exit, explicit `FAIL (a)`/`FAIL (b)`/`FAIL (c)` messages) on any deviation, and runs in its own workflow (`branch-protection.yml`) triggered by `workflow_run` after CI completes — deliberately NOT a member of `ci-required`'s `needs:` list, because a property of the *repository's* configuration (not the commit under test) would otherwise fail contributors for something they cannot fix.

**When to use:** D-18's `bin/verify-environment-protection` is the direct analog — same two-half structure (a: live rule matches expectation; b: proven to have actually been exercised), same "classic vs. new" fallback handling for token-permission gaps, same placement outside required checks.

**Verified source (`bin/verify-branch-protection`, read in full this session):**
```bash
# Half (a): live required-context list matches exactly
RULES_JSON=$(gh api "repos/${REPO}/rules/branches/${BRANCH}" -H "Accept: application/vnd.github+json" ...)
# comparison delegated to bin/compare-required-contexts (pure-decision split)

# Half (b): the name has actually been emitted as a check run on HEAD
EMITTED_COUNT=$(gh api "repos/${REPO}/commits/${HEAD_SHA}/check-runs?per_page=100" ... | jq ...)

# Third block: classic protection must not be stacking, with an explicit
# 403-fallback path for tokens that cannot read Administration:read fields:
#   ALLOW_UNVERIFIED_CLASSIC_PROTECTION=1 downgrades a 403+empty-field
#   response to a WARNING rather than a hard failure — this is the exact
#   token-scope handling research item #6 asked about.
```

**D-18's endpoint requirement, resolved:** GitHub's environment-protection-rules read is `GET /repos/{owner}/{repo}/environments/{environment_name}` — the response's `protection_rules` array includes `type: "required_reviewers"` entries with a `reviewers` list. This endpoint requires **read access to administration/environments**; per GitHub's documented permission model (same class of gap `bin/verify-branch-protection` already handles for classic branch protection), the DEFAULT `GITHUB_TOKEN` in Actions **cannot reliably read protection_rules on a private/org-scoped environment without `Environments: read` granted explicitly via fine-grained PAT or the repo's default token permissions being elevated** — this mirrors the classic-protection 403 case already handled in `bin/verify-branch-protection`, so `bin/verify-environment-protection` should copy the SAME `ALLOW_UNVERIFIED_*` escape-hatch pattern rather than inventing a new one. [CITED: GitHub REST API docs, `GET /repos/{owner}/{repo}/environments/{environment_name}` — this specific claim was not re-fetched live this session against GitHub's current docs; treat as `[ASSUMED]` per the provenance rule below and confirm with a live `gh api repos/OWNER/REPO/environments/production-hex` call during planning/execution, exactly as D-18 already implies ("assert the GitHub-side rule still exists").]

### Anti-Patterns to Avoid

- **Trusting release-please's generic `x-release-please-version` marker for a partial-version pin:** already proven wrong in `RELEASE-BLOCKERS.md` (writes the full version, e.g. `~> 0.10.1` on a patch bump, while the contract derives `~> 0.10.0`). Component markers (`x-release-please-minor`) are equally wrong — they replace the first bare integer on the line, which inside `{:threadline, "~> 0.9.0"}` is the leading `0`, producing `~> 10.9.0`. **Do not attempt either inside `mix release.pins`; derive from `@version` directly instead, exactly as the doc-contract test itself already does (`@expected_pin_version "#{@parsed.major}.#{@parsed.minor}.0"`).**
- **Assuming a stale `mix.lock` silently "wins" over a changed `mix.exs` requirement:** disproven by live experiment (see "D-08 Mix Lock Semantics" below). Any task/job that changes `priv/ci/hex_evaluator/mix.exs`'s dep must also either delete `mix.lock` or explicitly re-run `mix deps.get` before `mix compile`/`mix test`, or the job fails on a hard dependency-mismatch error (a safe failure, but a failure the planner must expect and route around, not assume away).
- **Treating `guides/adoption-pilot-backlog.md`'s Hex-attestation row as release-please-owned:** `bin/post-publish-distribution-sync`'s own header comment states two DIFFERENT ownership zones inside the SAME file — the SSOT line is release-please's (`extra-files`, `x-release-please-version`), the Hex-attestation row is this script's. Do not let `mix release.pins` (D-04) or any new automation touch this file; it already has its own working split.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Local package registry for rehearsal dep resolution | A custom fixture server or `path:` dep stand-in | `mix hex.registry build` + `mix hex.repo add` + `mix hex.build` (all bundled with Hex 2.5.1, confirmed present) | This is Hex's own sanctioned mechanism for exactly this use case (its own docs use the phrase "test the repository"); a hand-rolled stand-in would not exercise the real resolver/registry-format code path the published dependency will actually go through |
| Verifying GitHub environment protection rules | Parsing `.github/workflows/release.yml`'s YAML for `environment: production-hex` and calling that "verified" | `gh api repos/{owner}/{repo}/environments/{environment_name}` read, following the exact two-half pattern already proven in `bin/verify-branch-protection` | The YAML line only proves the WORKFLOW references an environment name; it says nothing about whether that environment still HAS a required-reviewer rule on GitHub's side — exactly the vacuous-gate shape CONTEXT.md's "Specifics" section names as already hit three times in this repo |

**Key insight:** Every mechanism this phase needs already has a proven analog in this same repository. The work is almost entirely "copy the pattern that already works for X, apply it to Y" — `bin/verify-branch-protection` → `bin/verify-environment-protection`; `version_truth_doc_contract_test.exs`'s derivation-from-`@version` idiom → `mix release.pins`; the existing `dry_run` dispatch input and `mix hex.publish --dry-run` → the rehearsal-mode dep resolution. Resist inventing new mechanisms when an in-repo precedent already exists.

## D-08 Mix Lock Semantics (RESOLVED — was flagged UNVERIFIED in CONTEXT.md)

**Claim under test:** does a locked version in `mix.lock` "override" a changed requirement in `mix.exs`, silently continuing to resolve/compile against the stale locked version?

**Method:** live local experiment, not training-data recall. Built a throwaway Mix project (`mix new mix_lock_test --sup`), added a real Hex package (`jason`) with an initial loose requirement, fetched (locking a specific old version), then reproduced the exact D-08 scenario twice under different conditions.

**Result 1 — deps already fetched at the old version, requirement bumped, `mix compile` run WITHOUT `deps.get`:**

```
$ grep jason mix.exs
      {:jason, "~> 1.4.0"}
$ mix compile
==> jason
Compiling 7 files (.ex)
...
==> mix_lock_test
Unchecked dependencies for environment dev:
* jason (Hex package)
  the dependency does not match the requirement "~> 1.4.0", got "1.0.1"
** (Mix) Can't continue due to errors on dependencies
```
[VERIFIED: live experiment, this session, 2026-09-22, exact stdout quoted above]

**Result 2 — same scenario, but `mix deps.get` IS run (registry reachable):**

```
$ grep jason mix.exs
      {:jason, "~> 1.4.0"}
$ mix deps.get
Resolving Hex dependencies...
Resolution completed in 0.012s
Upgraded:
  jason 1.0.1 => 1.4.5
* Updating jason (Hex package)
$ cat mix.lock
%{
  "jason": {:hex, :jason, "1.4.5", ...},
}
```
[VERIFIED: live experiment, this session, 2026-09-22, exact stdout and resulting `mix.lock` quoted above]

**Conclusion:** the "the lock overrides" framing is FALSE in both directions tested:

1. Mix does NOT silently compile/test against a stale locked version once `mix.exs`'s requirement no longer matches it — it fails CLOSED with an explicit, unambiguous error, refusing to proceed.
2. `mix deps.get`, when the registry is reachable, does NOT preserve the stale lock either — it silently RE-RESOLVES and overwrites `mix.lock` to the newest version satisfying the new requirement, with zero confirmation prompt.

**Consequence for D-07/D-08 planning:** the rehearsal/published mode-switch in `priv/ci/hex_evaluator/mix.exs` needs an explicit `mix deps.get` (or lock deletion) step wired into whichever job flips the mode — `verify.hex_evaluator`'s existing shell command already does `mix deps.get` unconditionally (`priv/ci/hex_evaluator && printf "n\n" | mix deps.get && ...`, confirmed at `mix.exs:340`), so THIS specific job is already safe by construction. The risk is narrower than CONTEXT.md worried about: it is not that a stale lock would silently validate 0.9.0 while claiming to validate 0.10.0 (Result 1 above proves that fails loudly) — it is that gitignoring the lock (D-08) removes the committed checksum pin entirely, so a `deps.get` failure to reach hexpm.org in an air-gapped or rate-limited CI run would surface as a hard `verify.hex_evaluator`/`smoke-published` failure with NO cached fallback. **This is the correct tradeoff per D-08's own stated rationale ("this fixture's job is resolvability, not reproducibility") but the planner should note it as an accepted risk, not an oversight.**

## Common Pitfalls

### Pitfall 1: Treating the release-please generic updater as version-shape-aware

**What goes wrong:** adding `<!-- x-release-please-version -->` to a pin line and registering it in `extra-files` looks like the obvious fix for RELEASE-02, and passes the NEXT release (0.10.0, a minor). It reintroduces born-red on the FOLLOWING patch release (0.10.1), because the generic updater writes the literal version verbatim, producing `~> 0.10.1` where the contract still expects `~> 0.10.0`.
**Why it happens:** the updater has no concept of "pin to the minor, ignore the patch" — it is a find/replace on a marked line, not a semver-aware rewrite.
**How to avoid:** derive pins with `mix release.pins`, driven off `@version` directly (same idiom as the test's own `@expected_pin_version`), run as a discrete maintainer/CI step on minor/major bumps only — NOT wired through release-please's own version-bump machinery.
**Warning signs:** any solution that adds a pin-bearing line to `release-please-config.json`'s `extra-files` array should be treated as suspect by default (D-06 makes this an enforced invariant, not just a review note).

### Pitfall 2: Assuming `mix.exs`'s `files:` wildcard-excludes anything not explicitly listed

**What goes wrong:** `package.files` is `~w(lib priv/fonts guides ...)` — `lib` is listed WHOLESALE, so `lib/mix/tasks/critic.measure.ex`, `lib/mix/tasks/critic.synth.ex`, and everything under `lib/threadline/critic_trust/` are ALL currently shipped, because `files:` includes the entire `lib/` tree, not a curated subset.
**Why it happens:** the allowlist is directory-granular (`lib`), not file-granular; adding a new maintainer-only module under `lib/` silently ships it.
**How to avoid:** D-20's fix is to either (a) enumerate `lib/` more narrowly (risky — many legitimate modules), or (b) exclude specific subpaths via a post-`hex.build` filter/contract assertion (the existing `built_archive()` helper in `release_artifact_contract_test.exs` already unpacks the real tarball and asserts on its contents — extend that pattern with `refute Enum.any?(entries, &String.starts_with?(&1, "lib/mix/tasks/critic."))` etc., rather than trying to make `package.files` itself file-granular).
**Warning signs:** `mix hex.build --unpack` (already used by the test suite's `built_archive/0` helper) listing files under `lib/mix/tasks/critic.*` or `lib/threadline/critic_trust/`.

**Verified `@shortdoc` claim (D-20's stated rationale):**
```elixir
# lib/mix/tasks/critic.synth.ex:2
@shortdoc "Generates the synthetic golden set from the graded twin ladder"
# lib/mix/tasks/critic.measure.ex:2
@shortdoc "Measures per-lens critic↔human trust and writes the critic_trust block (local-only; never auto-commits)"
```
[VERIFIED: `lib/mix/tasks/critic.synth.ex:2`, `lib/mix/tasks/critic.measure.ex:2`, read this session] — both confirmed present, confirming the CONTEXT.md claim that these appear under `mix help` for every adopter once published.

Measured file sizes: `lib/threadline/operator_surface/*stress*` + `*mechanical*` files total **3,379 lines** [VERIFIED: `wc -l` over the matched files, this session] — CONTEXT.md's "~5,000 lines" figure is in the right order of magnitude but appears to include additional files beyond the stress/mechanical glob (likely `critic_trust/` and/or test fixtures); the planner should re-run the exact file enumeration D-20 intends to exclude before writing the contract assertion, rather than trusting either figure as the literal exclusion list.

### Pitfall 3: The orphaned `## [Unreleased]` block is NOT where you'd expect it

**What goes wrong:** D-12 says an orphaned `## [Unreleased]` block sits "stranded below `0.7.0`" — a maintainer skimming `CHANGELOG.md` top-down could reasonably expect any `Unreleased` content to be at the TOP (the normal Keep-a-Changelog convention) and miss it.
**Verified location:** [VERIFIED: `CHANGELOG.md`, read this session] — `## [Unreleased]` is at line 43, sandwiched BETWEEN `## [0.7.0]` (line 24) and `## [0.6.0]` (line 56). Its content (lines 45-54) documents real 0.10.0-era work: "Architecture documentation" additions (How Threadline Works rewrite, Code Walkthrough) and a "HexDocs public-surface clarification" listing ~23 implementation modules that lost their doc pages — this is very likely the SAME set of modules D-16 point 4 references ("~23 implementation modules became `@moduledoc false`").
**How to avoid:** fold this exact block's content into the new 0.10.0 entry (D-12 explicitly calls for this) rather than writing 0.10.0's changelog from scratch; cross-check the ~23-module list here against D-16's figure — they may be exactly the same enumeration and this file already HAS it.

## Code Examples

### `version_truth_doc_contract_test.exs` — exact derivation logic (source of truth for `mix release.pins`)

```elixir
# Source: test/threadline/version_truth_doc_contract_test.exs:24-35 (read in full this session)
@version Threadline.MixProject.project()[:version]
@parsed Version.parse!(@version)

# Three-segment pin derived from @version. For @version 0.9.0 this is
# "0.9.0"; a tight `.0` derivation keeps patch releases green by construction
# because `~> 0.9.0` covers all of 0.9.x.
@expected_pin_version "#{@parsed.major}.#{@parsed.minor}.0"

# Current-minor upgrade coverage: 0.(minor-1).x -> 0.minor.x.
@prev_minor @parsed.minor - 1
@coverage_from "0.#{@prev_minor}.x"
@coverage_to "0.#{@parsed.minor}.x"
```
`mix release.pins` should reuse this EXACT derivation (`"#{parsed.major}.#{parsed.minor}.0"`) — CONTEXT.md's Claude's Discretion note says the advisor recommended DELIBERATE duplication over a shared module, self-policed by CI. The codebase has no existing shared "version truth" module to import from (the test computes it inline from `Threadline.MixProject.project()[:version]`), so duplication is not just acceptable but is the path of least resistance — a shared module would be new production surface for a release-time-only concern.

### Family B — the `x-release-please-version` + `extra-files` co-registration invariant `mix release.pins` must NOT violate

```elixir
# Source: test/threadline/version_truth_doc_contract_test.exs:74-101 (read in full this session)
test "every x-release-please-version marked line carries @version and is wired into release-please" do
  # ...
  assert String.contains?(config, path),
         "#{path} carries an x-release-please-version marker but is NOT listed under " <>
           "`extra-files` in #{@release_please_config}. ..."
```
This test currently only checks files that ALREADY carry the marker are registered — it does NOT (pre-D-06) check the inverse (that pin-bearing lines do NOT carry the marker). D-06's strengthening is a NEW assertion to add here, not a modification of the existing two.

### Current `release-please-config.json` — `extra-files` scope, confirmed narrow

```json
// Source: release-please-config.json (read in full this session)
"extra-files": [
  {"type": "generic", "path": "guides/adoption-pilot-backlog.md"},
  {"type": "generic", "path": "guides/evaluating-threadline.md"}
]
```
Both registered files carry PROSE `x-release-please-version` markers, not pin lines — confirming RELEASE-BLOCKERS.md's note that these two files are unaffected by the pin-line problem. `mix release.pins` operates ENTIRELY OUTSIDE this list per D-04 ("Pins are NOT added to release-please `extra-files`").

### Confirmed pin-line locations requiring `mix release.pins` coverage

```
README.md:68:                                    {:threadline, "~> 0.9.0"}
guides/operator-surface.md:38:                    {:threadline, "~> 0.9.0"}
guides/getting-started-saas.md:26:                {:threadline, "~> 0.9.0"}
```
[VERIFIED: `grep -n` over README.md + guides/**, this session] — three ACTUAL pin lines of the shape `{:threadline, "~> x.y.z"}`. Two additional files mention the version in PROSE (not a pin regex match) — `guides/adoption-pilot-backlog.md:14` and `guides/adoption-evidence-playbook.md:15`, `guides/evaluating-threadline.md:41` reference `"~> 0.9.0"` inside a markdown table cell or prose sentence, which the test's regex (`~r/\{:threadline,\s*"~>\s*([0-9][0-9.]*)"\}/`) still matches since it's the literal string `{:threadline, "~> 0.9.0"}` embedded in prose. **CONTEXT.md's "six pins" figure is confirmed: 3 in fenced code blocks (README, operator-surface, getting-started-saas) + 3 embedded in prose/table cells across adoption-pilot-backlog, adoption-evidence-playbook, evaluating-threadline** — all six match the SAME regex the doc-contract test scans with, so `mix release.pins` can reuse `doc_files()`'s exact glob (`["README.md" | Path.wildcard("guides/**/*.md")]`) and the SAME regex to find-and-replace, guaranteeing the task and the test never drift on WHICH lines count.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Single `CHANGELOG.md` owned by both release-please and humans | Split by file: `CHANGELOG-GENERATED.md` (bot) / `CHANGELOG.md` (human, shipped) | This phase (D-11) | Prevents planning-vocabulary leakage into the shipped changelog (measured: 40 of 317 releasable subjects trip the artifact contract's regexes today) |
| `## [Unreleased]` heading for accumulating pre-release notes | `## Unreleased — highlights` (no brackets) | This phase (D-12) | Avoids collision with release-please's version-header regex, which matches on the `[` |
| Hex evaluator pinned to a fixed hexpm version (`~> 0.9.0`) | Mode-switched: rehearsal (local registry) vs. published (`== <version>`, hexpm) | This phase (D-07) | Closes the RELEASE-03 gap where the evaluator silently kept validating 0.9.0 forever |

**Deprecated/outdated:**
- Component release-please markers (`x-release-please-major`/`-minor`) for compound version strings like `~> 0.9.0` — proven to target the wrong digit (RELEASE-BLOCKERS.md's `~> 10.9.0` failure case, corroborated by this session's reading of `version_truth_doc_contract_test.exs`'s comment explaining why the `.0` derivation exists).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The default `GITHUB_TOKEN` in Actions cannot reliably read environment `protection_rules` (required reviewers) without elevated/fine-grained token permissions, mirroring the classic-branch-protection 403 case `bin/verify-branch-protection` already handles | Architecture Patterns — D-18 endpoint | If wrong (default token CAN read it), `bin/verify-environment-protection` can be simpler than `bin/verify-branch-protection`'s fallback pattern — should be confirmed with a live `gh api repos/OWNER/REPO/environments/production-hex` call using the Actions default token during Phase 202 execution, not assumed from documentation memory |
| A2 | The GitHub REST endpoint for reading environment protection rules is `GET /repos/{owner}/{repo}/environments/{environment_name}` with a `protection_rules` array | Architecture Patterns — D-18 endpoint | If the endpoint shape differs (e.g., a separate `/environments/{name}/deployment-branch-policies` or similar), `bin/verify-environment-protection` would need a different `gh api` call — low risk, this is a well-documented stable GitHub API, but was not re-fetched live this session |
| A3 | The ~23 `@moduledoc false` modules referenced in D-16 point 4 are the SAME set listed in `CHANGELOG.md`'s orphaned `## [Unreleased]` block (Capture/Governance/Semantics migration modules + Operator implementation modules) | Common Pitfalls — Pitfall 3 | If they're different sets, D-16's changelog/upgrade-path content and the orphaned block's content should NOT simply be merged — the planner should diff the two lists explicitly during execution rather than assuming identity |

**If this table is empty:** N/A — three assumptions logged above, all low-blast-radius (release-tooling mechanics, not the storage-schema decision, which is fully verified).

## Open Questions

1. **Does `mix hex.registry build`'s rehearsal registry need to be served over real HTTP in CI, or does Hex support a `file://` repo URL?**
   - What we know: `mix help hex.repo add` requires `NAME URL`; the bundled `mix help hex.registry` documentation's own worked example spins up `erl -s inets -eval 'inets:start(httpd, ...)'` to serve the built registry over HTTP before `mix hex.repo add` — it does not demonstrate a `file://` shortcut.
   - What's unclear: whether Hex's HTTP client rejects `file://` outright or simply was never demonstrated in the docs read this session. Not tested live (would require actually standing up a registry server, judged too expensive for this research pass).
   - Recommendation: plan for an ephemeral HTTP server step (e.g., `python3 -m http.server` or the `erl -s inets` one-liner from Hex's own docs) in the rehearsal-mode CI job rather than assuming `file://` works; this is the lower-risk assumption and matches Hex's own documented example.

2. **Exact `smoke-published` job placement and Elixir/OTP setup — copy `publish-hex`'s `erlef/setup-beam@v1` block, or share a composite action?**
   - What we know: `publish-hex` already does `uses: erlef/setup-beam@v1` with `elixir-version: "1.17.3"` / `otp-version: "27.0"` (release.yml:340-343), then `mix deps.get`.
   - What's unclear: whether `smoke-published` needs the ROOT project's deps at all, or only `priv/ci/hex_evaluator`'s (it's a standalone Mix project with its own `mix.exs`/`mix.lock`) — likely only needs `priv/ci/hex_evaluator`'s toolchain + a Postgres service (matching `verify-hex-evaluator`'s existing `ci.yml` job, which provisions `postgres:16` and a `hex_evaluator_test` database).
   - Recommendation: model `smoke-published` on the EXISTING `verify-hex-evaluator` job in `ci.yml` (same Postgres service block, same `createdb hex_evaluator_test` step, same `elixir-version`/`otp-version` pins) rather than on `publish-hex` — it is testing the same artifact shape (`priv/ci/hex_evaluator`), just in published mode with a real network dependency on hex.pm instead of `ci.yml`'s implicit reliance on whatever `~> 0.9.0` resolves to.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP toolchain | All `mix` commands | ✓ | Elixir 1.17.3, OTP 27.3.4.15, Hex 2.5.1 [VERIFIED: `elixir --version`, `mix hex.info`, this session, with `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27` prefix per this repo's toolchain note] | — |
| `jq` | `bin/verify-branch-protection` (and by extension the D-18 sibling script) | Not directly probed this session, but the script itself hard-requires it and fails with an explicit install message if absent | — | Script self-diagnoses and instructs `brew install jq` / `apt-get install -y jq` |
| `gh` CLI | Same scripts, plus any live GitHub API read | Not directly probed this session (used implicitly via the CI environment in `release.yml`/`branch-protection.yml`, which run inside GitHub Actions where `gh` is preinstalled) | — | N/A in CI; a maintainer running the script locally needs `gh auth login` |
| Network access to hex.pm | `mix deps.get` when resolving non-cached deps, `mix hex.publish`, the `curl` polls in `release.yml` | ✓ (confirmed working this session — the D-08 experiment fetched real packages from hex.pm) | — | None — this is an inherent requirement of the publish pipeline, already accepted by the existing pipeline design |

**Missing dependencies with no fallback:** none identified — every tool this phase touches is already present and working in this environment.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled), plus `mix hex.build --unpack` for artifact-level assertions |
| Config file | `test/test_helper.exs` (root suite); `priv/ci/hex_evaluator` has its own independent `mix.exs`/test setup |
| Quick run command | `mix test test/threadline/version_truth_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/release_control_plane_contract_test.exs` |
| Full suite command | `mix verify.release` (runs `bin/verify-release-shape`, the two release contract test files, `mix docs --warnings-as-errors`, `mix hex.build`) — [VERIFIED: `mix.exs:214-224`, `defp verify_release/1`, read this session] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RELEASE-01 | 0.10.0 publishes, HexDocs clean/grouped | integration (CI-gated, requires real publish) | `mix docs --warnings-as-errors` (local proof of clean docs generation, part of `verify.release`) + the `release.yml` `publish-hex`/hex.pm-index-poll steps (only provable by actually running the pipeline) | ✅ `verify.release` alias exists; the publish step itself is unavoidably CI-only |
| RELEASE-02 | No hand-edit version bumps | unit (doc-contract) | `mix test test/threadline/version_truth_doc_contract_test.exs` | ✅ exists, Families A/B/C, needs D-06's new assertion added |
| RELEASE-03 | Evaluator validates the NEW release | integration | `mix verify.hex_evaluator` (rehearsal mode, local) / new `smoke-published` job (published mode, CI-only, needs real hex.pm) | ✅ `verify.hex_evaluator` alias exists (`mix.exs:338-346`); `smoke-published` job is new (Wave 0 gap) |
| RELEASE-04 | Changelog highlights above generated list | doc-contract (structural) | New test asserting `CHANGELOG.md`'s section order (breaking-first per D-13) and the presence of a human-written highlights block above the generated commit list — no existing test covers this exact shape | ❌ Wave 0 gap — new doc-contract test needed |
| RELEASE-05 | Release-shape + distribution-sync pass against published tarball | shell script + integration | `bin/verify-release-shape` (exists, read in full this session) + `bin/post-publish-distribution-sync` (exists, read in full this session) + the `distribution-sync` job's `needs: smoke-published` reorder (D-10, new) | ✅ scripts exist; job reorder is new wiring, not new test code |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/version_truth_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/release_control_plane_contract_test.exs`
- **Per wave merge:** `mix verify.release` (full release-shape + artifact-contract + docs-build + hex.build proof, all locally provable without a real publish)
- **Phase gate:** `mix verify.release` green locally, THEN `mix ci.all` green, THEN the human-gated `production-hex` publish — this phase's actual "did it work" proof is necessarily CI/production-only for RELEASE-01/03/05's live-hex.pm claims; local `mix verify.release` is the strongest pre-publish proxy available.

### Wave 0 Gaps

- [ ] A new doc-contract test (or extension of `release_artifact_contract_test.exs`) asserting `CHANGELOG.md`'s 0.10.0 entry opens with a human-written highlights section before any generated commit-list content (RELEASE-04) — no existing test covers this shape.
- [ ] `mix release.pins` task itself does not exist yet — needs to be written before D-06's strengthened contract test can be exercised against a real minor bump.
- [ ] `bin/verify-environment-protection` does not exist yet (D-18).
- [ ] `smoke-published` job does not exist yet in `release.yml` (D-09).
- [ ] Framework install: none — ExUnit and all Mix tooling already present.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | This phase touches CI/CD credentials (`HEX_API_KEY`), not application-user auth |
| V3 Session Management | No | N/A |
| V4 Access Control | Yes | `production-hex` environment's required-reviewer rule (D-17) IS the access control for the irreversible publish action; D-18 verifies this control is not silently defeated |
| V5 Input Validation | No | No new user-facing input surface introduced |
| V6 Cryptography | Partial | `mix hex.registry build --private-key` (D-07's rehearsal registry) requires a signing key — should be a throwaway, CI-ephemeral key (e.g., `openssl genrsa` generated fresh per job run), NEVER a committed secret, since the rehearsal registry's trust boundary is CI-internal only |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Compromised workflow silently publishing an unreviewed release | Elevation of Privilege | `production-hex` environment required-reviewer gate (D-17), verified live by D-18's fail-closed check — already the design, this phase closes the verification gap only |
| Long-lived `HEX_API_KEY` secret exposure | Information Disclosure | Already isolated to a single contiguous, clearly marked block in `release.yml` (the "HEX AUTHENTICATION — TRUSTED-PUBLISHING SWAP POINT" region, lines 377-402, read in full this session) — scoped to publish-only, reachable only after the environment approval; this phase does not need to change this pattern, only preserve it |
| Rehearsal registry's private signing key leaking or being reused across runs | Tampering | Generate the key fresh per-job (not committed, not cached across runs) since the rehearsal registry's only job is proving RESOLVABILITY, not asserting a durable trust chain |

## Sources

### Primary (HIGH confidence — direct source read or live experiment this session)

- `.planning/phases/202-release-0-10-0/202-CONTEXT.md` — full read, all 20 decisions
- `.planning/phases/202-release-0-10-0/RELEASE-BLOCKERS.md` — full read
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md` (partial, first 316 lines) — full read of relevant sections
- `test/threadline/version_truth_doc_contract_test.exs` — full read
- `test/threadline/release_artifact_contract_test.exs` — full read
- `test/threadline/upgrade_path_doc_contract_test.exs` — full read
- `test/threadline/release_control_plane_contract_test.exs` — full read
- `.github/workflows/release.yml` — full read
- `.github/workflows/branch-protection.yml` — full read
- `bin/verify-branch-protection` — full read
- `bin/verify-release-shape` — full read
- `bin/post-publish-distribution-sync` — full read
- `mix.exs` — full read
- `lib/threadline/storage_schema.ex` — full read
- `priv/ci/hex_evaluator/mix.exs`, `priv/ci/hex_evaluator/mix.lock` — full read
- `release-please-config.json`, `.release-please-manifest.json` — full read
- `guides/upgrade-path.md` lines 80-179 — read
- `CHANGELOG.md` — structure scan + full read of lines 1-82
- `CONTRIBUTING.md` — grep scan of release-related sections
- `.github/workflows/ci.yml` — job-structure grep + full read of `verify-hex-evaluator` job
- Live local experiment: throwaway Mix project (`jason` dependency), reproducing D-08's exact "stale lock vs. changed requirement" scenario under both `mix compile` (no re-resolve) and `mix deps.get` (re-resolve) conditions — full stdout captured and quoted above
- `mix help hex.registry`, `mix help hex.repo`, `mix help hex.build` — run locally this session
- `mix hex.info` — run locally this session, confirms Hex 2.5.1

### Secondary (MEDIUM confidence)

- GitHub REST API shape for environment protection rules (`GET /repos/{owner}/{repo}/environments/{environment_name}`) — from training knowledge, NOT re-fetched live against current GitHub docs this session; logged as Assumption A1/A2.

### Tertiary (LOW confidence)

- None — no WebSearch-only findings were used in this research pass; all claims are either direct source reads, a live experiment, or explicitly logged as an assumption.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages, all tooling already pinned and confirmed working locally
- Architecture: HIGH — every mechanism traced to an existing, working in-repo analog
- Pitfalls: HIGH — all three pitfalls are either directly measured (RELEASE-BLOCKERS.md's `~> 10.9.0` case, corroborated here) or directly read from source (the `files:` wildcard, the orphaned changelog block)
- D-08 Mix lock semantics: HIGH — resolved by live experiment, not assumption; this was the single explicitly-flagged research gap in CONTEXT.md and it is now closed
- D-18 GitHub environment-protection endpoint: MEDIUM — the mechanism (mirror `bin/verify-branch-protection`'s pattern) is HIGH confidence; the exact endpoint/token-scope claim is LOW/ASSUMED and flagged for live confirmation during execution

**Research date:** 2026-09-22
**Valid until:** This phase should execute promptly — the born-red PR #26 has been open since 2026-06-26 and every day of drift increases the chance of a new conflicting commit landing on `main`. Recommend re-verifying `RELEASE-BLOCKERS.md`'s measured facts (pin count, contract failures) immediately before planning if more than 7 days pass before `/gsd-plan-phase` runs.
