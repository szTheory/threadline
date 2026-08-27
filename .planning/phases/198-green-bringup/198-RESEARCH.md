# Phase 198: Green Bringup - Research

**Researched:** 2026-08-27
**Domain:** GitHub Actions CI/CD topology, branch protection/rulesets, Elixir/ExUnit test hygiene, secret scanning, git branch archival
**Confidence:** MEDIUM-HIGH — the repo-internal claims are `[VERIFIED]` (files read this session); the GitHub-platform behavior claims (matrix name emission, ruleset payload shape, `alls-green` semantics) are `[CITED]`/`[ASSUMED]` because they depend on live GitHub API/UI behavior that can only be fully confirmed by observing a real run (which is D-11's explicit deliverable — Plan 03/04 territory, not this research pass).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
D-01..D-38 as defined in `198-CONTEXT.md` `<decisions>`. This RESEARCH.md does not restate them; the planner reads `198-CONTEXT.md` directly as the decision record. Where this research surfaces evidence that sharpens, confirms, or (rarely) complicates a decision, it is called out inline and cross-referenced by decision ID.

### Claude's Discretion
- Exact `timeout-minutes` values within the D-16 budget, once p95s are observable.
- Whether the shard fallback (D-15 step 5) is needed, judged against measured post-surgery wall clock.
- Wording of the stale-DB tripwire message and `@ui_form_policy` failure messages.
- `198-TRIAGE.md` table formatting.
- Number of plans (roadmap estimate: 5).

### Deferred Ideas (OUT OF SCOPE)
`.planning/milestone.lock` cleanup (→199/DECOUPLE-05); `@moduledoc false` on critic mix tasks (→200/SURFACE-03); example-app `ALTER DATABASE` search_path wart (register row, revisit later); two duplicated `~> 0.9.0` doc literals (→202/RELEASE-02); "milestone tags stay local" convention re-litigation (milestone-close decision); Hex OIDC migration (revisit when GA); `stress_live.ex` relocation (resolve inside D-07, note only).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GREEN-01 | Preserve last red run's failing logs before 90-day purge | `gh run view --log-failed` + artifact/commit pattern below |
| GREEN-02 | Credo per-check histogram + per-file concentration, `.credo.exs` untouched | `--config-file` replace semantics verified via Credo docs; `--format json` |
| GREEN-03 | Evidence-based `verify.mechanical` sensitivity probe | `mechanical_checker.ex` read pattern below; probe design |
| GREEN-04 | `mix test` zero deterministic failures, no skips laundered | D-01..D-07 triage taxonomy (CONTEXT.md); confirmed single failure |
| GREEN-05 | Formless-page guard self-declares, fails loudly on new form | `@ui_form_policy` persisted-attribute pattern below |
| GREEN-06 | Every job `timeout-minutes`; broken browser suite aborts early | D-16/D-18; `--max-failures` flag confirmed in playwright.config.ts |
| GREEN-07 | `origin/main` == local `main`; CI ≤20min (≤12 target) | D-15/D-17/D-19 cost-surgery ordering |
| GREEN-08 | Branch protection == exactly emitted check names | Matrix-name-emission research below; aggregate-gate (D-08/D-09) sidesteps it |
| GREEN-09 | Paid critic structurally untriggerable | `ui-critic.yml` read in full — confirms D-24 deletion scope |
| GREEN-10 | Exactly one Hex publish path | `hex-publish.yml` + `release.yml` read in full — confirms D-26 |
| GREEN-11 | Flake Detection: broken vs flaky, time-bounded, deduped issue | `flake-detection.yml` read; dedup-issue pattern below |
| GREEN-12 | One worktree, no stale branches, archive-tag or land | git archive-tag command sequence below |
</phase_requirements>

## Summary

Phase 198 is almost entirely **verification and gate-wiring against a repo whose actual state was already read in the preceding `/gsd-discuss-phase` session** — `198-CONTEXT.md`'s `<ground_truth>` and 38 decisions are `[VERIFIED]`-grade research in their own right. This research pass re-confirms the highest-leverage file contents by reading them directly this session (not re-deriving conclusions CONTEXT.md already reached), and closes the ten open questions the orchestrator flagged: the `alls-green` YAML shape, the matrix-static-name emission question, the ruleset write-API payload, `bin/verify-branch-protection`'s two `gh api` halves, Credo's `--config-file` replace semantics, the `@ui_form_policy` persisted-attribute idiom, the Playwright `--max-failures` + chromium-baseline orphan risk (now settled with a concrete answer — see below), `gitleaks`/`trufflehog` invocation flags, and the deduplicated-issue pattern.

**One correction to a stated assumption in the orchestrator's critical_constraints:** open question 8 asked "is any baseline actually on disk for [the `chromium` project]?" — it is. `git grep`/`find` for `-chromium.png` snapshot files found **13 committed baselines** across `operator-stress.spec.ts` and `operator-screenshot-regression.spec.ts` that resolve to the `chromium` project name (not `desktop-chromium`). D-15 step 1 (delete the `chromium` project) will orphan these 13 files unless those tests are also re-pointed at `desktop-chromium` or the baselines are regenerated/deleted in the same commit. This is a **new, concrete pre-condition for D-15 step 1** that CONTEXT.md flagged as a risk to check but did not resolve with a number.

**Primary recommendation:** Do not deviate from the CONTEXT.md decision record. Use this document to (a) execute D-15 step 1 with the 13-file baseline list in hand, (b) implement `alls-green` and the ruleset payload from the verified shapes below, (c) treat the matrix-static-name question as **empirically unverified until the matrix is pushed and observed** (do not hard-code an assumption about GitHub's behavior into any committed doc beyond "TBD, see D-11 observation record"), and (d) use the Credo/gitleaks/trufflehog CLI flag shapes below directly in Plan 01/05 scripts.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Branch protection / required checks | GitHub platform (repo config) | CI workflow (`ci.yml`) | The check *names* are emitted by CI; the *requirement* is platform config. Both must agree — this is the whole GREEN-08 problem. |
| Aggregate gate (`ci-required`) | CI workflow (`ci.yml`) | — | A new job inside the existing workflow; no new tier. |
| Test suite green / stale-DB tripwire | Application test tier (`test/`) | — | Elixir/ExUnit, not infra. |
| Formless-page guard | Application test tier (`test/`) + `lib/` module attributes | — | Self-describing contract co-located with the LiveView module it guards. |
| CI cost surgery (timeouts, sharding, cache keys) | CI workflow (`ci.yml`, `playwright.config.ts`) | — | Infra/pipeline tier only; no application code changes. |
| Credo histogram / mechanical sensitivity probe | Local tooling invocation (`mix credo`, `mix verify.mechanical`) | — | Read-only measurement; writes to `.planning/audits/`, never to `lib/`. |
| Paid-critic untriggerability / publish-path singularity | CI workflow (deletion) + `test/` (`ci_topology_contract_test.exs` guard) | — | Deletion is infra; the guard that prevents resurrection is application-test tier. |
| Credential audit + secret scanning | External tool (gitleaks/trufflehog) + GitHub platform (push protection) | `.planning/audits/` (artifact) | Runs against git history, not application code. |
| Branch/worktree triage | git tier (local + `origin`) | `.planning/ARCHIVE-REGISTER.md` (artifact) | Pure git operations; the register is documentation of them. |

## Package Legitimacy Audit

**Not applicable.** Phase 198 installs no new Elixir/Hex, npm, or other ecosystem packages. It adds two external CLI tools (`gitleaks`, `trufflehog`) as one-shot audit invocations (D-28), not as project dependencies — they are not added to `mix.exs`, `package.json`, or any lockfile, and do not ship in the Hex tarball. Verification of these two binaries is an environment-availability concern (see below), not a supply-chain legitimacy concern, since they never enter the built artifact.

| Tool | Distribution | Verdict | Disposition |
|------|--------------|---------|-------------|
| `gitleaks` | Homebrew/GitHub Releases binary, run ad hoc via `gitleaks detect` | N/A — not a project dependency | Approved for one-shot audit use; not installed via any package manager the tarball ships |
| `trufflehog` | Homebrew/GitHub Releases binary, run ad hoc | N/A — not a project dependency | Approved for one-shot audit use |

## Standard Stack

No new libraries. Phase 198 is entirely: (a) YAML/workflow edits to five existing `.github/workflows/*.yml` files, (b) Elixir test/mix.exs edits, (c) two ad-hoc external security-scanner CLI invocations, (d) `gh api`/`gh` CLI calls for branch protection and issue management, (e) git branch/tag operations.

### Core (existing, already in the project)
| Tool | Version (verified) | Purpose | Evidence |
|------|---------------------|---------|----------|
| `re-actors/alls-green` | `@release/v1` (a moving tag, not pinned to a SHA) | Aggregate-gate action for D-08/D-09 | `[CITED: github.com/re-actors/alls-green]` — this is a NEW addition to `ci.yml`, not currently present. |
| `mix credo` | whatever `.credo.exs`/`mix.lock` pins today | GREEN-02 histogram source | `[VERIFIED: .credo.exs read this session]` — current config only enables `Readability.ModuleDoc` and `Design.TagTODO`; full-default histogram requires an **external** config file per D-37, not this one. |
| Playwright | pinned via `examples/threadline_phoenix/e2e/package-lock.json` | Browser E2E, GREEN-06/GREEN-07 cost surgery | `[VERIFIED: playwright.config.ts read this session]` |

### Supporting (new invocations, not new dependencies)
| Tool | Install method | Purpose | When to Use |
|------|-----------------|---------|-------------|
| `gitleaks` | GitHub Releases binary or `brew install gitleaks` | Full-history secret scan (D-28) | Once, in the credential-audit plan, before push |
| `trufflehog` | GitHub Releases binary or `brew install trufflehog` | Verified-live-credential scan (D-28) | Once, alongside gitleaks — different detection engine and a *verification* step gitleaks lacks |
| `gh api` | Already available (`gh` CLI) | Ruleset write, branch-protection read, check-runs read, dedup issue create/update | `bin/verify-branch-protection`, D-13 migration, D-23/D-35 issue dedup |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `re-actors/alls-green` | Hand-rolled `if: contains(needs.*.result, 'failure')` | **Rejected by D-09** — skipped-dependency jobs register as passing under the hand-rolled idiom; `alls-green`'s `toJSON(needs)` inspection catches this. Do not reconsider. |
| `gitleaks` alone | `trufflehog` alone | Different detection engines and false-positive profiles; D-28 already locks running **both**. `trufflehog`'s verified mode (live API call against the provider) is the one thing `gitleaks` cannot do — it is a distinguishing capability, not redundant coverage. |
| Repository ruleset (D-13) | Keep classic branch protection only | **Rejected by D-13** — classic protection lacks the bypass-actor-scoped-to-an-app primitive cleanly; ruleset is the modern GitHub-recommended primitive and is exportable as committed JSON (`git`-tracked, auditable), which classic protection settings are not. |

**Installation:** No `mix.exs`/`package.json` changes. `gitleaks`/`trufflehog` are local/CI-runner binary installs, invoked once per D-34 step 4:
```bash
# CI runner or local — one-shot, not a project dependency
brew install gitleaks trufflehog   # or: use gitleaks/trufflehog GitHub Releases binaries directly
```

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────────────────┐
                    │  Contributor / Maintainer push or PR      │
                    └───────────────────┬───────────────────────┘
                                        │
                    ┌───────────────────▼───────────────────────┐
                    │  ci.yml  (on: push main | pull_request)     │
                    │                                             │
                    │  verify-format ──┐                          │
                    │  verify-credo ───┤                          │
                    │  verify-compile-no-optional ─┤              │
                    │  verify-test [matrix: min, current] ────┐   │
                    │  verify-hex-evaluator ───┤               │  │
                    │  verify-example-browser (reduced, PR) ───┤  │
                    │  verify-mechanical ───┤                  │  │
                    │  verify-capture ───┤                      │  │
                    │  verify-pgbouncer-topology ───┤            │  │
                    │  verify-docs ───┤                          │  │
                    │  verify-hex-package ───┤                   │  │
                    │  verify-release-shape ───┤                 │  │
                    │                          │                 │  │
                    │                          ▼                 ▼  │
                    │              ┌─────────────────────────────┐ │
                    │              │  ci-required (NEW, D-08)      │ │
                    │              │  if: always()                │ │
                    │              │  needs: [every job above]     │ │
                    │              │  uses: re-actors/alls-green  │ │
                    │              └───────────────┬──────────────┘ │
                    └──────────────────────────────┼─────────────────┘
                                                     │ single status
                    ┌────────────────────────────────▼──────────────┐
                    │  Repository Ruleset  main.json (D-13)          │
                    │  required_status_checks: ["CI required"]        │
                    │  non_fast_forward, deletion,                    │
                    │  required_linear_history, pull_request rule     │
                    └────────────────────────────────┬──────────────┘
                                                        │ gate satisfied
                    ┌────────────────────────────────▼──────────────┐
                    │  Merge to main → release.yml                    │
                    │  release-please → gate-ci-green (poll) →         │
                    │  publish-hex (Environment-gated, human click) →  │
                    │  distribution-sync                                │
                    └───────────────────────────────────────────────┘

              ┌─────────────────────────────────────────────────┐
              │  Nightly / manual: flake-detection.yml            │
              │  mix verify.flake ──→ broken-vs-flaky classify ──→│
              │  dedup gh issue create-or-update                   │
              └─────────────────────────────────────────────────┘

              ┌─────────────────────────────────────────────────┐
              │  DELETED this phase: ui-critic.yml, hex-publish.yml│
              │  (D-24, D-26 — before the 587-commit push, D-34)  │
              └─────────────────────────────────────────────────┘
```

### Pattern 1: Aggregate required-check gate (`alls-green`)
**What:** A single terminal job whose only purpose is to reduce N job results to one pass/fail signal that branch protection can point at.
**When to use:** Any CI topology with more than a handful of jobs, or any matrix — matches D-08's rationale exactly.
**Example (verified shape from `re-actors/alls-green` README, `[CITED: github.com/re-actors/alls-green]`):**
```yaml
jobs:
  # ... all existing verify-* jobs unchanged ...

  ci-required:
    name: CI required
    if: always()
    needs:
      - verify-format
      - verify-credo
      - verify-compile-no-optional
      - verify-test
      - verify-hex-evaluator
      - verify-example-browser
      - verify-mechanical
      - verify-capture
      - verify-pgbouncer-topology
      - verify-docs
      - verify-hex-package
      - verify-release-shape
    runs-on: ubuntu-24.04
    steps:
      - name: Decide whether all needed jobs succeeded
        uses: re-actors/alls-green@release/v1
        with:
          jobs: ${{ toJSON(needs) }}
          # allowed-skips: <comma-separated job ids> — only if a job is
          # intentionally conditional (e.g. verify-example-browser-full is
          # NOT in `needs:` at all, so allowed-skips is not needed for it).
```
Three named inputs exist: `jobs` (mandatory — the `toJSON(needs)` context object), `allowed-failures` (optional, comma-separated job ids permitted to fail without failing the gate), `allowed-skips` (optional, comma-separated job ids permitted to be `skipped` without failing the gate). `[CITED: github.com/re-actors/alls-green]` — the exact input syntax (comma-separated string vs YAML list) should be confirmed against the README at implementation time; both are documented in different alls-green versions historically.

**Note on the matrix `verify-test` job in `needs:`:** GitHub Actions treats a matrixed job as a single `needs:` entry regardless of how many matrix legs it fans out into — `needs: verify-test` waits for **all** matrix legs (this is standard, well-documented GHA behavior, not the disputed static-name question). `fail-fast: false` (already set, `ci.yml:108`) ensures one leg failing doesn't cancel the other before `ci-required` can observe both results.

### Pattern 2: The matrix-static-name question (D-11) — **UNVERIFIED, evidence and recommended handling**
**What:** `ci.yml:106` sets `name: Run test suite` (no `${{ matrix.lane }}` interpolation) over a matrix with axis `lane: [min, current]`. The `ci.yml:100-106` comment asserts this yields two distinct required-check names, `Run test suite (min)` and `Run test suite (current)`, because GitHub Actions appends the varying matrix value to a static job `name:` when rendering the Checks UI / commit status API.

**What research found:** This IS accurate, mainstream GitHub Actions behavior — GitHub appends matrix-varying parameters to a job's displayed name automatically when the job doesn't already interpolate `${{ matrix.* }}` into `name:` itself, UNLESS `include:`/`exclude:` keys are used and the varying value comes only from `include`, in which case behavior has historically been inconsistent and is the subject of open GitHub Community discussions (#26822, #60792) that remain unresolved as of research date. `[CITED: github.com/orgs/community/discussions/26822, #60792]` — these are community reports, not official GitHub documentation, and no authoritative doc page states the exact append algorithm for a base-axis-plus-`include` matrix shape like this repo's (`lane: [min, current]` with `include:` carrying `elixir`/`otp`/`pg`/`runner`).

**Why it doesn't block planning:** D-08/D-09/D-11 already made this moot for protection purposes — the aggregate gate `ci-required` is the only required check, and it `needs: verify-test`, which is satisfied by matrix completion regardless of what suffix GitHub appends to the per-leg name. The **only** remaining obligation is D-11's own: observe and record what GitHub actually renders, once, after the matrix has run on `origin`. This is an execution-time observation task (fits naturally in the "staging-PR bringup" plan), not a research-answerable question — no amount of documentation reading substitutes for watching the real Checks UI after a real push.

**Recommendation for the planner:** Add an explicit task step: "After the `min`/`current` matrix first reports (e.g., via the staging-branch `workflow_dispatch` rehearsal, D-21), capture a screenshot or `gh api repos/:owner/:repo/commits/:sha/check-runs` JSON dump of the emitted names and commit it as `.planning/audits/198-matrix-name-observation.md` (or fold into the existing measurement-sweep artifact)." This satisfies "verified after the matrix has reported once" from the roadmap's Success Criteria #4 with an artifact, not a memory.

### Pattern 3: Repository ruleset write payload (D-13)
**What:** `gh ruleset` CLI is read-only (list/view/check); the *write* path is the raw REST API via `gh api`.
**Verified shape** `[CITED: docs.github.com/en/rest/repos/rules]`:
```bash
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/:owner/:repo/rulesets \
  --input .github/rulesets/main.json
```
`.github/rulesets/main.json` (shape per D-13's settings list, cross-checked against the docs-fetched schema):
```json
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [
    {
      "actor_type": "Integration",
      "actor_id": "<release-please app's installation/integration id — must be looked up via gh api /repos/:owner/:repo/installations or the org's installed-apps list>",
      "bypass_mode": "always"
    }
  ],
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [
          { "context": "CI required" }
        ],
        "strict_required_status_checks_policy": false
      }
    },
    { "type": "non_fast_forward" },
    { "type": "deletion" },
    { "type": "required_linear_history" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "required_review_thread_resolution": true,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false
      }
    }
  ]
}
```
**Open gap `[ASSUMED]`:** the exact `actor_id` for "release-please app only" bypass (D-13) requires a live lookup — `gh api /repos/:owner/:repo/installations` (or, if release-please runs via a fine-grained PAT rather than a GitHub App installation, the bypass-actor model may need to be `"actor_type": "OrganizationAdmin"` or similar instead of `"Integration"`, depending on how `RELEASE_PLEASE_TOKEN` is actually authenticated — `release.yml:96` uses `secrets.RELEASE_PLEASE_TOKEN` which the repo's own comment calls "a fine-grained PAT," not a GitHub App token). **This is a planner-level open question, not resolvable from static file reading — it needs one live `gh api` call at execution time to confirm whether a bypass actor is even the correct primitive for a PAT-authenticated bot, or whether the PAT's own permissions already bypass rulesets by virtue of running as a repo-scoped token with `contents: write` outside the ruleset's `pull_request`-target enforcement.** Flag this for a `checkpoint:human-verify` or execution-time `gh api` probe in Plan 03/04.

**Classic branch protection coexistence with rulesets `[CITED: GitHub Docs — rulesets and branch protection]`:** GitHub evaluates **both** classic branch protection rules and any applicable rulesets, and a push/PR must satisfy the union (most restrictive wins) if both target the same ref. This means during migration the maintainer likely wants to **either** (a) delete/relax the classic branch protection rule for `main` once the ruleset is verified live and enforcing correctly, or (b) accept a strict transitional period where both rules stack. D-13/D-14 do not explicitly state whether classic protection is deleted after the ruleset lands — **this is a gap the planner should close**: either add an explicit "delete classic protection rule for `main` once ruleset confirmed active" step, or document why both are intentionally kept.

### Pattern 4: `bin/verify-branch-protection` (D-12) — sibling shape and two required `gh api` halves
**What `bin/verify-release-shape` establishes as the sibling pattern** `[VERIFIED: bin/verify-release-shape:1-52, read this session]`: `#!/usr/bin/env bash`, `set -euo pipefail`, `cd` to repo root via `$(dirname "${BASH_SOURCE[0]}")/..`, early-exit checks with `echo "..." >&2; exit 1` on missing preconditions, and a final unconditional success `echo` with no trailing newline weirdness. No JSON parsing library — pure `grep`/`sed`.

**`bin/verify-branch-protection` needs `jq` (not used in `verify-release-shape`) because it must parse `gh api` JSON output — confirm `jq` is available on the CI runner image (`ubuntu-24.04` ships `jq` by default `[ASSUMED]` — standard on GitHub-hosted runners, verify with `jq --version` in the script itself as a guard, matching this repo's existing defensive style).**

Half (a) — diff live required contexts against the expected singleton:
```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
EXPECTED_CHECK="CI required"

# Half (a): read live protection/ruleset required contexts.
# For a repository ruleset (D-13), the endpoint differs from classic protection:
#   classic: gh api repos/:owner/:repo/branches/main/protection
#   ruleset: gh api repos/:owner/:repo/rules/branches/main   (effective rules for a ref)
live_contexts=$(gh api "repos/${REPO}/rules/branches/main" \
  --jq '[.[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context]')

if [[ "$(jq -c 'sort' <<<"$live_contexts")" != "$(jq -cn --arg c "$EXPECTED_CHECK" '[$c] | sort')" ]]; then
  echo "::error::Live required status checks are ${live_contexts}, expected exactly [\"${EXPECTED_CHECK}\"]" >&2
  exit 1
fi

# Half (b): assert the check has actually been emitted on a real run.
recent_check=$(gh api "repos/${REPO}/commits/main/check-runs" \
  --jq --arg name "$EXPECTED_CHECK" '[.check_runs[] | select(.name == $name)] | length')

if [[ "$recent_check" -lt 1 ]]; then
  echo "::error::\"${EXPECTED_CHECK}\" has never been emitted as a check-run on main HEAD" >&2
  exit 1
fi

echo "Branch protection OK: exactly [\"${EXPECTED_CHECK}\"] required, confirmed emitted on main HEAD."
```
`GET /repos/:owner/:repo/rules/branches/:branch` `[CITED: docs.github.com/en/rest/repos/rules — get-rules-for-a-branch]` returns the **effective** rule set for a branch (merging any applicable rulesets), which is the right endpoint for a rulesets-based world — do not use the classic `branches/:branch/protection` endpoint once migrated off classic protection, since it will 404 or return stale data if classic protection was removed.
`GET /repos/:owner/:repo/commits/:ref/check-runs` `[CITED: docs.github.com/en/rest/checks/runs — list-check-runs-for-a-git-reference]` is the correct endpoint for half (b) — confirmed to exist and take a `ref` (SHA or branch name).

### Pattern 5: Credo full-default histogram from an out-of-repo config (D-37)
**What:** `--config-file <path>` on `mix credo` **replaces** the discovered `.credo.exs` entirely rather than merging with it `[CITED: hexdocs.pm/credo — Credo.CLI / config resolution docs]` — Credo's config resolution walks up from cwd looking for `.credo.exs` and stops at the first one found OR uses the explicitly passed `--config-file`, and does not merge multiple config sources. This confirms D-37's premise is correct.

**Concrete command:**
```bash
# Full-default config held OUTSIDE the repo (never committed to .credo.exs)
mix credo /path/to/full-default.credo.exs --config-file /path/to/full-default.credo.exs \
  --format json > .planning/audits/198-credo-full-default.json
```
Actually the correct invocation form is `mix credo --config-file <path>` (the path is a flag argument, not a positional) — `mix credo --config-file priv/audit/full-default.credo.exs --format json`. The `full-default.credo.exs` content should be Credo's stock generated config (`mix credo.gen.config` output, or simply omit the `checks:` key entirely, which makes Credo fall back to its built-in complete default check set) with `strict: true` and `included`/`excluded` matching this repo's `lib/`/`test/` scope. `[ASSUMED]` — verify the exact generated shape with `mix credo.gen.config` at execution time rather than hand-writing it, since Credo's default check list changes across releases and hand-transcribing risks staleness.

**Per-check histogram + per-file concentration from `--format json`:** Credo's JSON output (`--format json`) emits an `"issues"` array where each issue has `"check"` (module name, e.g. `"Elixir.Credo.Check.Readability.Specs"`) and `"filename"`. A per-check histogram is `jq '.issues | group_by(.check) | map({check: .[0].check, count: length}) | sort_by(-.count)'`; per-file concentration is the same with `.filename`. `[CITED: hexdocs.pm/credo — JSON output format]`.

**`.credo.exs` stays untouched** — the histogram-producing config lives at a path like `priv/audit/` or `/tmp/`, never overwrites `.credo.exs`, and the measurement script is throwaway/local, not wired into `ci.all`.

### Pattern 6: `verify.mechanical` sensitivity probe design (D-38)
**What was read this session:** `ci.yml:286` documents that `mix verify.mechanical` runs `mechanical_checker_test.exs`, which calls `MechanicalChecker.run/1` over the committed `.planning/scorecards/*.json` Tier-A evidence, gating on WCAG/token conformance (MODE-A) and ratchet-floor (MODE-B) rules — `route.*` is explicitly excluded (`mechanical_checker.ex:155` per CONTEXT.md's canonical_refs, not independently re-read this session — flag as `[CITED: 198-CONTEXT.md canonical_refs, itself sourced from a prior session's file read]` rather than `[VERIFIED]` since this research pass did not re-open `mechanical_checker.ex` directly).

**Recommended probe design (evidence-based, no scorecard touched):**
1. Read `lib/threadline/operator_surface/mechanical_checker.ex` (or wherever `MechanicalChecker.run/1` is implemented) directly and enumerate every distinct signal it extracts from a scorecard JSON/ARIA-YAML pair — e.g., does it read `.text` / `.textContent` fields, `.boundingBox` geometry, computed-style token values (`color`, `background-color`, `font-size` etc.), or only class-name/token-attribute presence?
2. Cross-reference against the scorecard JSON schema itself (open one `.planning/scorecards/*.json` file and one `.aria.yml` and see which fields are actually populated per cell).
3. The **evidence** GREEN-03 wants is not "we read the source and it looks like X" (that's inference) — it wants a **constructed test case**: take one committed scorecard, produce a duplicate with ONLY rendered text content changed (same tokens, same geometry, same contrast) and ONLY width changed (same everything else), run `MechanicalChecker.run/1` against each synthetic variant **without touching the real committed scorecards** (write to a tmp/scratch path, run the checker function directly in an `iex -S mix` session or a throwaway script, not via the `mix verify.mechanical` alias which only reads the committed set), and observe whether it flags or is silent. This is the only design that satisfies "from evidence, not inference" — reading the implementation tells you what fields exist; only executing the checker against a controlled synthetic diff tells you what it is *sensitive to* in practice (e.g., a checker could technically read a `.text` field but never diff it).
4. **"Without touching any scorecard"** (D-38) means: the synthetic variants live in a scratch directory outside `.planning/scorecards/`, and `MechanicalChecker.run/1` is invoked directly against that scratch path (assuming the function takes a path/data argument rather than hard-coding `.planning/scorecards/`) — confirm this at execution time by reading the function signature; if it hard-codes the path, the probe needs a temp-copy-and-restore wrapper instead, which must restore `git status --porcelain .planning/scorecards/` to clean before finishing (mirroring `ci.yml:390-399`'s own byte-stability assertion).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Aggregate CI required-check gate | Custom `if: contains(needs.*.result, 'failure')` job | `re-actors/alls-green@release/v1` | D-09: hand-rolled `contains()` scores a skipped-due-to-dependency-failure job as passing; `alls-green` inspects every result value via `toJSON(needs)`. |
| Branch-protection JSON diffing | Hand-parsed `gh api` output with `grep`/`awk` | `jq` filters over `gh api ... --jq` | JSON structure (nested arrays of objects) is exactly what `jq` exists for; `bin/verify-release-shape`'s pure-grep style works because it parses flat text (mix.exs, CHANGELOG), not nested JSON. |
| Secret detection | A hand-rolled regex grep for `sk-`, `ghp_`, etc. | `gitleaks` + `trufflehog` (D-28) | Both tools carry maintained, continuously-updated detection-rule databases across dozens of providers; a hand-rolled grep (already run once per the ground_truth table) only catches patterns someone thought to add and misses provider-specific formats and entropy-based unknown-secret detection. |
| Deduplicated tracking issue | A `gh issue create` on every scheduled failure | `gh issue list --search` + conditional `create`/`comment` | Prevents issue-per-run spam; standard idiom used by numerous GitHub Actions maintenance workflows. |
| Credo default check enumeration | Hand-transcribing Credo's "full default" check list into a config file | `mix credo.gen.config` output, or an empty `checks:` key (falls back to built-in defaults) | Credo's shipped default check set changes across releases; hand-transcribing risks silent staleness — the exact failure mode this milestone's memory note already flagged for the *current* vacuous `.credo.exs` (`enabled:` replaces rather than extends defaults). |

**Key insight:** Every "don't hand-roll" here is really the same lesson stated in D-09/D-25/D-37's own rationale — CI gating logic that looks correct by inspection (a `contains()` check, a hand-copied Credo check list, a grep for known secret prefixes) silently degrades to a false-pass the moment the underlying assumption shifts (a skipped job, a new Credo release, an unanticipated credential format). The maintained-tool alternative bakes in continuous updates the hand-rolled version cannot get for free.

## Runtime State Inventory

**Trigger check:** Phase 198 involves deletion (`ui-critic.yml`, `hex-publish.yml`), branch-protection migration, and branch/worktree archival — not a rename/rebrand, but it does retire runtime-registered state (workflow triggers, branch-protection rules) and deserves the same explicit inventory discipline.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no database schema, collection name, or stored-record key changes in this phase. `[VERIFIED: reviewed 198-CONTEXT.md ground_truth + this session's file reads — no migration or data-shape change is in scope]` | None |
| Live service config | **Branch protection settings on `origin`, live and NOT in git.** `[VERIFIED: 198-CONTEXT.md ground_truth table — "Live protection settings: strict: true, enforce_admins: false, required_linear_history: false, required_conversation_resolution: false, rulesets: []"]`. This is exactly the "live service config not exported to git" hazard pattern — the ruleset JSON this phase creates (`.github/rulesets/main.json`) is the fix: it makes the config git-tracked going forward. Until D-13 lands, classic protection is the only source of truth and lives entirely on GitHub's servers. | Code edit (create `.github/rulesets/main.json`) + live `gh api` write, in that order (create ruleset, verify, then optionally relax classic protection) |
| OS-registered state | None found — no Task Scheduler / launchd / systemd / pm2 involvement; this is a hosted-CI, no-daemon repo. | None |
| Secrets/env vars | `HEX_API_KEY`, `ANTHROPIC_API_KEY`, `RELEASE_PLEASE_TOKEN`, `GITHUB_TOKEN` — all `[VERIFIED: grepped across .github/workflows this session]`. `ANTHROPIC_API_KEY` reference is deleted along with `ui-critic.yml` (D-24) — the **secret itself** (if configured in repo settings) is NOT deleted by removing the workflow reference; if the maintainer wants it fully gone from the repo's secret store, that's a separate GitHub Settings action outside any file this research reviewed. Flag as a planner checklist item: "confirm whether to also revoke the `ANTHROPIC_API_KEY` repo secret in GitHub Settings, not just remove its workflow reference." | Code edit (workflow deletion) + optional manual GitHub Settings step (secret revocation) — not resolvable from repo files alone |
| Build artifacts / installed packages | None — this phase produces no compiled/installed artifact changes; `mix hex.build` tarball composition is untouched by this phase (that's Phase 200/SURFACE-02's job). | None |

**Nothing found in category "Stored data" and "OS-registered state"** — verified by direct review of `198-CONTEXT.md`'s ground_truth and this session's own file reads; no database migration, external stateful service (n8n/mem0/etc.), or OS-level task registration exists anywhere in this repo's toolchain.

## Common Pitfalls

### Pitfall 1: Deleting the `chromium` Playwright project orphans 13 committed baselines
**What goes wrong:** D-15 step 1 deletes the `chromium` project at `playwright.config.ts:16`. `snapshotPathTemplate: "{testDir}/{testFilePath}-snapshots/{arg}-{projectName}{ext}"` (`playwright.config.ts:123`) means every committed `*-chromium.png` baseline is keyed to that exact project name.
**Why it happens:** The three unscoped projects (`chromium`, `desktop-chromium`, `mobile-chromium`) look redundant by viewport diff alone (1280×720 vs 1280×900), but two spec files (`operator-stress.spec.ts`, `operator-screenshot-regression.spec.ts`) currently run against `chromium` specifically and have committed golden images for it.
**How to avoid:** Before deleting the project, `find examples/threadline_phoenix/e2e/tests -iname "*-chromium.png"` (this research ran that exact command — **13 files found**, all under `operator-stress.spec.ts-snapshots/` and `operator-screenshot-regression.spec.ts-snapshots/`). Either (a) `git rm` those 13 files in the same commit that deletes the project, accepting the coverage gap is absorbed by `desktop-chromium`'s equivalent tests running the same assertions at a near-identical viewport, or (b) confirm those two spec files also run under `desktop-chromium`/`mobile-chromium` (if so, the `chromium`-suffixed baselines are pure redundant coverage and safe to delete) — check via `grep -n "projects\|test(" operator-stress.spec.ts operator-screenshot-regression.spec.ts` for any `test.describe.configure` or per-file `use.testMatch` restricting them to `chromium` only. This is a **new, execution-time-checkable pre-condition** the planner should encode as an explicit verification step in the D-15-step-1 task, not left implicit.
**Warning signs:** `mix verify.example_browser` (or the browser CI job) reporting "missing snapshot" errors for `*-chromium.png` paths after the project is removed, if the `git rm` isn't done atomically with the config change.

### Pitfall 2: Classic branch protection and repository rulesets stack, not replace
**What goes wrong:** Migrating to a ruleset (D-13) without also addressing the existing classic protection rule can leave the *union* of both rule sets active, which may re-armor requirements the ruleset was meant to relax (D-14 explicitly wants `strict` turned OFF — but if classic protection's `strict: true` is still live alongside the new ruleset, the effective behavior may remain strict depending on how GitHub merges the two).
**Why it happens:** GitHub introduced rulesets as an additive layer on top of, not a replacement for, classic branch protection; there is no automatic migration or mutual exclusivity.
**How to avoid:** After creating and verifying the ruleset is `enforcement: active` and enforcing correctly (`bin/verify-branch-protection` half (a)+(b) both green), explicitly decide and document whether to delete/disable the classic protection rule for `main`, via `gh api --method DELETE repos/:owner/:repo/branches/main/protection`. Add this as an explicit D-13-adjacent task rather than assuming the ruleset alone settles GREEN-08.
**Warning signs:** `bin/verify-branch-protection` half (a) reading `rules/branches/main` shows the expected singleton, but a PR still shows extra checks or a "must be up to date" requirement in the merge box — signals classic protection is still contributing rules.

### Pitfall 3: `alls-green`'s `allowed-skips` needed for intentionally-conditional jobs
**What goes wrong:** If any job in `ci-required`'s `needs:` list is conditionally skipped by design (e.g., a future `dialyzer` job gated `if: matrix.lane == 'current'`), `alls-green` without `allowed-skips` will fail the aggregate even though the skip was intentional and not a dependency-failure skip.
**Why it happens:** `alls-green` cannot distinguish "skipped because a needed job failed" from "skipped because its own `if:` condition was false" purely from the `needs` context object — both render as `"skipped"`.
**How to avoid:** For 198's initial `ci-required` wiring, every job in `needs:` runs unconditionally on every push/PR (verified by reading `ci.yml` — none of the current jobs carry job-level `if:` conditions), so `allowed-skips` is not needed yet. **Note for the planner:** this becomes relevant the moment Phase 199 adds a conditionally-skipped dialyzer job or Phase 203/204 add conditional lanes — the `ci-required` job's `needs:`/`allowed-skips` pair is the durable extension point (per CONTEXT.md's Integration Points section) and should be documented as such in the `ci.yml` header comment update D-08 already calls for.
**Warning signs:** A PR shows `ci-required` red even though every job that ran passed, with the failure message pointing at a job that shows "skipped" in the Actions UI.

### Pitfall 4: `--config-file` passed as a positional Credo argument silently ignored
**What goes wrong:** `mix credo <path>` (positional) means "only analyze this path," not "use this config file" — an easy transcription slip from `mix credo --config-file <path>`.
**Why it happens:** Credo's CLI accepts both a positional path-to-analyze argument and the `--config-file` flag; conflating them either analyzes the wrong (single-file) scope or silently ignores the intended external config.
**How to avoid:** Always pass `--config-file` explicitly as a named flag: `mix credo --config-file /absolute/or/relative/path/to/full-default.credo.exs --format json`. Verify by checking the JSON output's issue count changes meaningfully vs. the current `.credo.exs`-driven run (current config enables only 2 checks; full-default should surface far more findings — if the count is suspiciously similar, the flag likely wasn't honored).
**Warning signs:** Histogram issue count matches (or is close to) the current 2-check-only baseline instead of showing Credo's full default surface area.

## Code Examples

### Deduplicated GitHub issue create-or-update (D-23/D-35)
```bash
# Source: idiomatic gh CLI pattern, cross-referenced against multiple
# maintenance-workflow examples [CITED: gh-cli docs + community pattern,
# no single canonical source — this is a well-established idiom, not a
# documented gh-cli built-in feature]
LABEL="flake-detection"
TITLE_PREFIX="[Flake Detection]"
EXISTING=$(gh issue list --search "in:title \"${TITLE_PREFIX}\"" --label "$LABEL" --state open --json number --jq '.[0].number // empty')

BODY="Run: ${GITHUB_RUN_ID}\nWorkflow: ${GITHUB_WORKFLOW}\nDetail: ..."

if [[ -n "$EXISTING" ]]; then
  gh issue comment "$EXISTING" --body "$BODY"
else
  gh issue create --title "${TITLE_PREFIX} suite is flaky/broken" --label "$LABEL" --body "$BODY"
fi
```
Apply the same pattern for GREEN-11 (flake) and D-23(d) (nightly browser-lane failure). Use a **distinct label per source** (`flake-detection` vs. `nightly-browser-lane`) so the two dedup streams don't collide into one issue.

### Broken-vs-flaky classification (GREEN-11)
```elixir
# mix verify.flake runs `mix test --repeat-until-failure 50` (confirmed:
# mix.exs alias "verify.flake": ["test --repeat-until-failure 50"]).
# "Broken" = fails on iteration 1 (deterministic). "Flaky" = passes iteration 1,
# fails on a later iteration (non-deterministic). ExUnit's own exit code and
# output do not natively separate these — the workflow step must capture
# which repeat iteration first failed and branch the issue title accordingly.
```
```bash
# flake-detection.yml step, replacing the bare `mix verify.flake` run:
set +e
mix verify.flake 2>&1 | tee /tmp/flake-output.log
STATUS=$?
set -e

if [ $STATUS -ne 0 ]; then
  if grep -q "1) " /tmp/flake-output.log && ! grep -qE "iteration 2|iteration 3" /tmp/flake-output.log; then
    CLASSIFICATION="broken"
  else
    CLASSIFICATION="flaky"
  fi
  echo "classification=${CLASSIFICATION}" >> "$GITHUB_OUTPUT"
fi
```
`[ASSUMED]` — the exact log-parsing heuristic for "which repeat iteration failed" depends on `--repeat-until-failure`'s actual stdout format, which was not independently re-verified this session (ExUnit's repeat-until-failure output format should be confirmed by running it locally once before committing to a parsing strategy — a fragile regex against ExUnit's exact wording is itself a pitfall this phase should avoid, per the "test, not a comment" principle already established for other guards).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Enumerate every matrix leg's check name in branch protection | Aggregate gate job (`alls-green` or hand-rolled) as the sole required check | Long-standing GHA community best practice (no single "changed" date — this is the standard answer to GH community discussions #26733/#60792, both multi-year-old and still open, meaning GitHub has never shipped a first-class fix) | Eliminates the matrix-rename deadlock class of bug entirely; this repo's own `ci.yml:100-106` comment is itself evidence the maintainer already knows this pattern — D-08 formalizes it. |
| Classic branch protection only | Repository rulesets (JSON-exportable, git-trackable) | GitHub GA'd rulesets in 2023-2024; still coexists with classic protection as of 2026 | Rulesets are the forward path GitHub is investing in; classic protection is not deprecated but is the "legacy" primitive going forward. |
| Hex publish via `HEX_API_KEY` only | Hex trusted publishing / OIDC (like npm/PyPI trusted publishing) | Announced but **not GA** as of 2026 per CONTEXT.md ground_truth (Hex 2.4 shipped OAuth device flow + CLI 2FA as an intermediate step, not full OIDC) | `HEX_API_KEY` stays; D-27's Environment-gated human-approval step is the interim mitigation, not a stopgap to be embarrassed about — it's the current state of the art for this specific ecosystem. |

**Deprecated/outdated:** Nothing in this phase touches deprecated APIs — `actions/checkout@v5`, `erlef/setup-beam@v1`, `actions/cache@v4`, `actions/setup-node@v5` are all current major versions per this session's file reads.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `alls-green`'s `allowed-skips`/`allowed-failures` inputs accept comma-separated strings (vs. a YAML list) | Pattern 1 | Low — wrong syntax fails loudly at workflow-parse or first-run time, not silently; easy to fix in the same PR. |
| A2 | GitHub's matrix-static-name append behavior for a base-axis + `include` shape matches the repo's own `ci.yml:100-106` comment's claim | Pattern 2 | Low for THIS phase (aggregate gate makes it moot for protection), but the D-11 observation record could turn out to contradict the comment — if so, update the `ci.yml` comment as part of that same task, don't leave it stale. |
| A3 | The release-please bypass actor in the ruleset should be `actor_type: "Integration"` | Pattern 3 | Medium — if `RELEASE_PLEASE_TOKEN` is a fine-grained PAT rather than a GitHub App install token, the whole bypass-actor premise may be moot (a PAT-authenticated push already carries the token owner's permissions and isn't blocked by a ruleset the same way an App would need explicit bypass). Needs a live `gh api` check before implementation, flagged explicitly above. |
| A4 | `ubuntu-24.04` GitHub-hosted runners ship `jq` by default | Pattern 4 | Low — trivially guarded with a `command -v jq` check at the top of `bin/verify-branch-protection`, matching the repo's existing defensive-script style. |
| A5 | `mix verify.flake`'s `--repeat-until-failure 50` stdout format is parseable for "which iteration failed first" via simple `grep` | Code Examples | Medium — a fragile parser here would violate the phase's own "test, not a comment" / "prove new assertions have teeth" principles; recommend running the command locally once during planning to confirm actual output shape before committing to a parsing strategy. |
| A6 | `MechanicalChecker.run/1`'s function signature accepts an arbitrary path/data argument (not hard-coded to `.planning/scorecards/`) | Pattern 6 | Medium — if hard-coded, the GREEN-03 probe design needs a temp-copy-and-restore wrapper instead of a direct scratch-path call; this session did not re-open `mechanical_checker.ex` to confirm the signature (relied on CONTEXT.md's canonical_refs citation of `mechanical_checker.ex:155`). **Recommend the planner's Plan 01 task explicitly opens this file first**, before designing the probe script. |
| A7 | `release-please-config.json`'s `extra-files` mechanism (referenced in canonical_refs, not re-read this session) is unaffected by any Phase 198 change | (not directly researched — noted as an assumption of non-interference) | Low — Phase 198 touches no version-bearing files; flagged only for completeness. |

## Open Questions

1. **Is `RELEASE_PLEASE_TOKEN` a GitHub App install token or a classic/fine-grained PAT, and does that change the ruleset bypass-actor model entirely?**
   - What we know: `release.yml:96` comment self-describes it as "a fine-grained PAT."
   - What's unclear: Whether a fine-grained PAT's pushes are even subject to ruleset enforcement the same way a GitHub App's are, and whether `bypass_actors` with `actor_type: "Integration"` is the right primitive at all versus e.g. `actor_type: "OrganizationAdmin"` or simply not needing a bypass actor if the PAT's repo permissions already satisfy the ruleset's `pull_request`-target rules (rulesets typically target PR merges, and release-please's own commits are typically made via a PR that then gets merged like any other, in which case NO bypass may be needed at all — the "release-please app only" bypass may be solving a problem that doesn't exist if release-please's workflow already goes through a normal PR+merge).
   - Recommendation: Verify empirically in Plan 03/04 execution — attempt the ruleset without a bypass actor first, and only add one if a real release-please PR is observed being blocked.

2. **Does the reduced PR-lane browser job (D-17, `desktop-chromium` + `mobile-chromium` only) still exercise `operator-stress.spec.ts` and `operator-screenshot-regression.spec.ts`'s `chromium`-only assertions, or do those specs need updating to run under the retained projects?**
   - What we know: 13 `*-chromium.png` baselines exist; the two spec files were not opened this session to check if they restrict themselves to the `chromium` project via `test.describe.configure({ mode: ... })` or per-file project scoping.
   - What's unclear: Whether removing `chromium` silently drops real test coverage (if those specs run ONLY under `chromium` today) or is purely redundant (if they already run under all three/two remaining projects and the `chromium`-suffixed baseline is an accidental extra).
   - Recommendation: Open both spec files as a first sub-step of the D-15-step-1 task, before touching `playwright.config.ts`.

3. **What does `MechanicalChecker.run/1`'s actual function signature look like, and does it hard-code `.planning/scorecards/`?**
   - What we know: `ci.yml:280-286` comments describe its role; `mechanical_checker_test.exs` invokes it via the `mix verify.mechanical` alias.
   - What's unclear: The exact input contract needed to design a non-scorecard-touching synthetic probe (Pattern 6 above).
   - Recommendation: Open `lib/threadline/operator_surface/mechanical_checker.ex` directly in Plan 01 before writing probe code.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| `gh` CLI | branch-protection scripts, ruleset write, dedup issue creation | assumed ✓ (used already by `release.yml`) | — | None needed — repo already depends on `gh` in CI (`GH_TOKEN` env pattern throughout `release.yml`) |
| `jq` | `bin/verify-branch-protection` JSON parsing | ✓ (standard on `ubuntu-24.04` GitHub-hosted runners) `[ASSUMED]` | — | Guard with `command -v jq` at script start; GitHub-hosted runners ship it by default per GitHub's runner image documentation |
| `gitleaks` | D-28 credential audit | ✗ locally (not verified installed) `[ASSUMED — not probed this session]` | — | Install via `brew install gitleaks` or GitHub Releases binary; one-shot, not added to CI permanently unless the maintainer wants ongoing scanning (D-28 describes a one-time audit, not a recurring gate) |
| `trufflehog` | D-28 credential audit (verified mode) | ✗ locally (not verified installed) `[ASSUMED — not probed this session]` | — | Same as above |
| GitHub Actions runner images (`ubuntu-24.04`, `ubuntu-22.04`) | `min`/`current` matrix lanes | ✓ (GitHub-hosted, standard images) | — | None needed |

**Missing dependencies with no fallback:** None — every dependency has a documented install path or is already present in the toolchain.

**Missing dependencies with fallback:** `gitleaks`/`trufflehog` — install once, ad hoc, per D-28's one-shot audit framing; not a blocking CI dependency this phase.

## Validation Architecture

`workflow.nyquist_validation` is explicitly `true` in `.planning/config.json:53` `[VERIFIED: .planning/config.json:53 read this session, value "nyquist_validation": true]` — this section is required.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir), `mix test` |
| Config file | `test/test_helper.exs` (read this session — `ExUnit.start()`, storage bootstrap, migration run, `pgbouncer_topology` tag exclusion) |
| Quick run command | `mix test test/threadline/<specific_test>.exs` |
| Full suite command | `mix verify.test` (alias for `mix test`), or `mix ci.all` for the complete gate chain |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|---------------------|--------------|
| GREEN-01 | Red-run log preserved in-repo | artifact/script check | `test -f .planning/audits/198-ci-run-28214113903-logs.md` (or equivalent artifact path, planner-defined) | ❌ Wave 0 — artifact doesn't exist yet, this is the plan's own deliverable |
| GREEN-02 | Credo histogram produced, `.credo.exs` unmodified | script + `git diff --exit-code .credo.exs` | `git diff --exit-code .credo.exs && test -f .planning/audits/198-credo-histogram.json` | ❌ Wave 0 |
| GREEN-03 | Mechanical sensitivity probe answered from evidence | scratch-script + documented finding | one-off script, output committed as `.planning/audits/198-mechanical-sensitivity.md` | ❌ Wave 0 |
| GREEN-04 | `mix test` zero deterministic failures | full-suite run | `mix test` exit code 0, plus a mechanical zero-skips assertion test (D-05 hard cap) | ❌ Wave 0 (the zero-skips assertion test itself is new) |
| GREEN-05 | Formless-page guard self-declares, exhaustive scan | unit test | `mix test test/threadline/operator_surface/ui_form_policy_test.exs` (new file, replaces `formless_pages_test.exs`) | ❌ Wave 0 (rewrite of existing `formless_pages_test.exs`, read this session) |
| GREEN-06 | Every job has `timeout-minutes`; browser suite aborts early | static YAML check | `grep -c "timeout-minutes:" .github/workflows/ci.yml` vs. job count; `grep "max-failures" playwright.config.ts` or `run-e2e.sh` | ❌ Wave 0 (no existing contract test for this — consider a new `ci_topology_contract_test.exs` assertion) |
| GREEN-07 | `origin/main` == local; CI green ≤20min | git + `gh run view` | `git log origin/main..main` empty; `gh run view <run-id> --json conclusion,startedAt,updatedAt` | ❌ Wave 0 — requires the actual push (D-34 step 5), verification is post-push |
| GREEN-08 | Branch protection == exactly emitted checks | `bin/verify-branch-protection` (new script) | `bin/verify-branch-protection` | ❌ Wave 0 (script doesn't exist yet — D-12's deliverable) |
| GREEN-09 | Paid critic structurally untriggerable | contract test | `test/threadline/ci_topology_contract_test.exs` new assertions (D-25) — `refute String.contains?(File.read!(...), "ANTHROPIC_API_KEY")` across all workflow files | ⚠️ Partial — `ci_topology_contract_test.exs` exists and was read this session; new assertions are additive |
| GREEN-10 | Exactly one Hex publish path | contract test | same file, D-25 — count of `mix hex.publish` occurrences across `.github/workflows/*.yml` == 1 | ⚠️ Partial — same file, additive |
| GREEN-11 | Flake Detection distinguishes broken/flaky, deduped issue | workflow-level (not unit-testable without a live scheduled run) | manual/staged dry-run via `workflow_dispatch`; no automated assertion possible pre-merge | N/A — inherently requires a live GitHub Actions execution to validate the classification heuristic |
| GREEN-12 | One worktree, no stale branches, archived or landed | git command + register check | `git worktree list \| wc -l` == 1; `git branch -a` shows no non-`main`/`archive/*` branches; `test -f .planning/ARCHIVE-REGISTER.md` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** targeted `mix test test/threadline/<touched_test>.exs` for test/triage tasks; `git diff --exit-code .credo.exs` for the measurement plan; `bin/verify-branch-protection` (once it exists) for protection tasks.
- **Per wave merge:** `mix ci.all` (full gate chain) — this is itself Success Criterion #3's own target (≤20min).
- **Phase gate:** `mix ci.all` green on `origin/main` post-push, `bin/verify-branch-protection` green, `gh pr checks 26` (or its resolution) green, is the terminal phase-gate condition per the roadmap's Success Criteria.

### Wave 0 Gaps
- [ ] `test/threadline/operator_surface/ui_form_policy_test.exs` (or wherever D-07's replacement for `formless_pages_test.exs` lands) — new self-declaring-attribute + exhaustive-scan test
- [ ] A zero-skips mechanical assertion test (D-05 hard cap) — new
- [ ] `bin/verify-branch-protection` — new script (D-12), no existing sibling beyond `bin/verify-release-shape`'s pattern
- [ ] New assertions inside the existing `test/threadline/ci_topology_contract_test.exs` (D-25) — additive, not a new file
- [ ] `198-TRIAGE.md`, `.planning/ARCHIVE-REGISTER.md`, `.planning/audits/*` — new tracked planning artifacts, not test files, but are the mechanical evidence GREEN-01/02/03/12 point at
- [ ] A CI-Coverage doc-contract test for D-23(c) (which Playwright projects run PR vs. main vs. nightly, cross-checked against `CONTRIBUTING.md`) — new, reusing the `verify.doc_contract` idiom per D-23

## Security Domain

`security_enforcement` was not found as an explicit key in `.planning/config.json`'s visible excerpt this session — treating as enabled (absent = enabled) per instructions.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|-------------------|
| V2 Authentication | No | This phase makes no auth-flow changes — out of scope per the domain boundary ("no capture/query/auth semantic change"). |
| V3 Session Management | No | Same as above. |
| V4 Access Control | Yes (narrowly) | Branch-protection/ruleset `bypass_actors` scoping (D-13) IS an access-control artifact — the bypass actor must be scoped as narrowly as possible (release-please app only, per D-13's explicit rejection of a broader bypass). |
| V5 Input Validation | N/A | No user-facing input surface touched. |
| V6 Cryptography | N/A | No cryptographic code touched — `HEX_API_KEY`/`RELEASE_PLEASE_TOKEN`/`ANTHROPIC_API_KEY` are credential-*handling* concerns (below), not cryptographic implementation. |
| V14 Configuration | Yes | This entire phase IS a configuration-hardening exercise: CI job timeouts (resource exhaustion prevention), branch-protection tightening (`enforce_admins` ON per D-14), secret-scanning enablement (D-28), and eliminating an ungated publish path (D-26) are all V14-class controls. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Ungated `mix hex.publish` firing from any tag push (current `hex-publish.yml` state) | Tampering / Elevation of Privilege | D-26: delete the ungated path; keep only the CI-green + release-shape-gated `release.yml` path, with `HEX_API_KEY` further gated behind a GitHub Environment reviewer approval (D-27). |
| Paid-API credential (`ANTHROPIC_API_KEY`) reachable from a `push: main` trigger with a broad path filter (587 commits will match) | Denial of Service (financial) / Information Disclosure (via billing) | D-24: delete the workflow trigger entirely, not just default the input off — matches this session's `[VERIFIED]` read of `ui-critic.yml` showing the `push` trigger + `secrets.ANTHROPIC_API_KEY` binding at lines 14-21 and 48. |
| Secrets committed and later removed from HEAD but still present in git history (587-commit publish window) | Information Disclosure | D-28/D-29: full-history `gitleaks`/`trufflehog` scan before push, GitHub secret scanning + push protection enabled BEFORE push as a third net, binding rotate-vs-abort decision rule by credential class. |
| Branch-protection required-check name becoming permanently unsatisfiable after a matrix rename (self-inflicted DoS on the merge pipeline) | Denial of Service | D-08/D-09: aggregate gate dissolves the class of bug entirely — this is itself the mitigation for a threat pattern unique to matrix-based CI branch protection. |
| A skipped-due-to-dependency-failure job silently registering as a passing required check | Tampering (of the CI trust signal) | D-09: `if: always()` + `toJSON(needs)` inspection via `alls-green`, never a hand-rolled `contains()` check. |

## Sources

### Primary (HIGH confidence)
- `.github/workflows/ci.yml` (573 lines, read in full this session) — job topology, matrix shape, cache keys, timeouts (absence confirmed), byte-stability assertions
- `.github/workflows/release.yml` (first 120 lines read this session) — release-please gating, dispatch, concurrency scoping
- `.github/workflows/hex-publish.yml` (61 lines, read in full) — confirms "legacy fallback," ungated `mix hex.publish --yes`
- `.github/workflows/ui-critic.yml` (130 lines, read in full) — confirms push trigger + path filter + `ANTHROPIC_API_KEY` binding + capture-only degradation logic
- `.github/workflows/flake-detection.yml` (61 lines, read in full) — confirms no `timeout-minutes`, no dedup-issue logic currently present
- `examples/threadline_phoenix/e2e/playwright.config.ts` (138 lines, read in full) — confirms three unscoped chromium-family projects, `snapshotPathTemplate`, `workers: 1`, `retries`, `trace`
- `bin/verify-release-shape` (52 lines, read in full) — sibling-script shape for `bin/verify-branch-protection`
- `test/test_helper.exs` (39 lines, read in full) — `pgbouncer_topology` tag exclusion, storage bootstrap, migration-run insertion point for D-03's tripwire
- `test/threadline/ci_topology_contract_test.exs` (first ~60 lines read) — home for D-25 assertions, existing pattern style
- `test/threadline/version_truth_doc_contract_test.exs` (first ~65 lines read) — confirms the derive-from-SSOT idiom D-06/D-07 copy from, including the non-empty-glob assertion pattern
- `test/**/formless_pages_test.exs` (read in full) — confirms the exact allowlist D-07 replaces, and the three already-excluded pages (`retention_history_live`, `coverage_live`, `surface_header`) with their documented rationale
- `lib/threadline/operator_surface/live/` directory listing (`ls`, this session) — confirms `stress_live.ex` exists alongside the 6 formless-guarded pages, matching the deferred-item note
- `.planning/config.json` (`nyquist_validation` key grepped this session) — confirms `true`, Validation Architecture section is required
- `find .../tests -iname "*-chromium.png"` (run this session) — **13 files found**, the concrete answer to open question 8 in the orchestrator's critical_constraints

### Secondary (MEDIUM confidence — CITED, official/authoritative docs or well-established community patterns)
- [re-actors/alls-green README](https://github.com/re-actors/alls-green) — `if: always()`, `jobs: ${{ toJSON(needs) }}`, `allowed-failures`/`allowed-skips` inputs
- [GitHub REST API — Repository Rules docs](https://docs.github.com/en/rest/repos/rules) — ruleset POST payload shape, `rules/branches/:branch` effective-rules GET endpoint
- [GitHub REST API — Checks, list-check-runs-for-a-git-reference](https://docs.github.com/en/rest/checks/runs) — `commits/:ref/check-runs` endpoint for `bin/verify-branch-protection` half (b)
- [Credo hexdocs — CLI/config resolution and JSON output](https://hexdocs.pm/credo) — `--config-file` replace semantics, `--format json` issue shape
- [gitleaks GitHub repo + issue #1729](https://github.com/gitleaks/gitleaks) — `--log-opts="--all --full-history"`, `--no-git` flag
- [trufflehog GitHub repo](https://github.com/trufflesecurity/trufflehog) — `filesystem` subcommand, `--results=verified` flag

### Tertiary (LOW confidence — community discussion, not authoritative; the matrix-static-name question specifically)
- [GitHub Community Discussion #26822 — Status check for matrix jobs](https://github.com/orgs/community/discussions/26822)
- [GitHub Community Discussion #60792 — Conditional Jobs and matrix make it impossible to require correct statuses](https://github.com/orgs/community/discussions/60792)
- [GitHub Community Discussion #26733 — require-all-without-enumerating](https://github.com/orgs/community/discussions) (referenced in CONTEXT.md canonical_refs; not independently re-fetched this session)

## Metadata

**Confidence breakdown:**
- Repo-internal facts (file contents, existing job topology, existing test contracts): HIGH — every claim in this category was read directly this session with `Read`/`Bash grep`/`find`, not inferred from CONTEXT.md's prior citations.
- GitHub-platform behavior (ruleset payload shape, `alls-green` input syntax, check-runs endpoint): MEDIUM — sourced from official docs/README via WebFetch/WebSearch, not independently executed against a live repo this session (the ruleset write and `alls-green` wiring are themselves this phase's execution work).
- Matrix static-name emission behavior: LOW — genuinely unresolved by any authoritative source; correctly scoped by D-11 as an observe-and-record task, not a research-answerable question. This research pass confirms it stays that way rather than manufacturing false certainty.
- Credo/gitleaks/trufflehog CLI flag shapes: MEDIUM — sourced from official docs/README, standard and stable flags, low volatility risk.

**Research date:** 2026-08-27
**Valid until:** 14 days for the GitHub-platform-behavior claims (fast-moving product area, rulesets are actively evolving); 30 days for the repo-internal facts (stable until the phase itself changes them, at which point this document is superseded by the phase's own commits).
