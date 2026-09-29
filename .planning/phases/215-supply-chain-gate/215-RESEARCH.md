# Phase 215: Supply Chain Gate - Research

**Researched:** 2026-09-26
**Domain:** Elixir/Hex dependency auditing (`mix hex.audit`), CI gating, GitHub Actions issue-upsert automation
**Confidence:** HIGH (all core facts reproduced live in this session; two items — Hex `cooldown` and the negative-fixture network design — are MEDIUM/LOW and flagged)

## Summary

All four success criteria are directly buildable from patterns already in this repo. SUP-01's fixes were reproduced live this session: `mint` 1.10.0→1.10.1 and `lazy_html` 0.1.12→0.1.13 clear the root advisories lock-only; bench's `postgrex`/`plug`/`decimal` advisories require bumping `ecto`/`ecto_sql` to 3.14.x (which relaxes `decimal`'s own `~> 2.0` constraint to allow 3.x) — still lock-only, no `bench/mix.exs` edit. The example app's lockfile is already clean. SUP-02's alias should follow the exact `verify_bench`/`verify_example` private-function alias pattern in `mix.exs` (`Mix.shell().cmd("bash -lc '...cd bench && ...'")`), running `mix deps.unlock --check-unused` (confirmed real flag) plus `mix hex.audit` over all three lockfiles, and asserting `Hex.version() >= "2.5.1"` (Hex is already exactly 2.5.1 locally and via CI's `erlef/setup-beam@v1` default). SUP-03's `ignore_advisories`/`ignore_retirements` config key is a real, currently-installed Hex 2.5.1 feature (confirmed via `mix help hex.audit`), presently unused anywhere in the repo — the test to write is a static mix.exs-config parser, not a live audit check. SUP-04's issue-upsert should be a near copy of `flake-detection.yml`'s `bin/upsert-ci-issue` step with label `ci-deps` (distinct from `ci-flake`/`ci-browser-full`), which already exists as a generic reusable binary.

**Primary recommendation:** Reuse existing idioms verbatim — the `verify_bench` mix.exs alias shape for cross-directory `hex.audit` invocation, `bin/upsert-ci-issue` for the weekly issue, and `ci_topology_contract_test.exs`'s same-commit roster pattern for wiring `verify-deps-audit` into `ci-required`. Do not adopt Hex `cooldown` this phase — it exists (Hex ≥2.5.0) but is orthogonal to the four SUP requirements and not decided in scope; record it as a considered-and-declined option.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lockfile advisory remediation (mint, lazy_html, bench triad) | Build/Dependency (root `mix.lock`, `bench/mix.lock`) | — | Pure dependency-resolution fix, no runtime code change |
| `mix verify.deps_audit` alias + cross-project invocation | Build tooling (`mix.exs` aliases) | CI (`ci.yml` job) | Same shape as existing `verify.bench`/`verify.example` — a mix.exs private function shelling into subdirectories |
| `ignore_advisories` reason/reachability/review-by test | Test suite (`test/`) | — | Static parse of `mix.exs` `:hex` config, no runtime/network dependency |
| Weekly `deps-health.yml` + issue upsert | CI / GitHub Actions | Ops (`ci-deps` issue on GitHub) | Non-required, scheduled workflow reusing `bin/upsert-ci-issue` |
| CONTRIBUTING freshness policy doc | Docs | Doc-contract test | Same pattern as every other `*_doc_contract_test.exs` |

## Standard Stack

### Core
| Tool | Version (verified) | Purpose | Why Standard |
|------|---------|---------|--------------|
| Hex | 2.5.1 (local `mix hex.info`, matches SUP-02's `>= 2.5.1` bar exactly) | `mix hex.audit`, `ignore_advisories`/`ignore_retirements` config | Bundled with Elixir 1.17.3-otp-27 via asdf; CI installs via `erlef/setup-beam@v1` (no explicit `mix local.hex` version pin found in any workflow — setup-beam ships a current Hex archive for the given OTP/Elixir combo) |
| `mix deps.unlock --check-unused` | Elixir 1.17.3 built-in | Fails if `mix.lock` has entries no longer referenced by `mix.exs` | `[VERIFIED: mix help deps.unlock, run this session]` — exact flag text: "`--check-unused` - checks that the `mix.lock` file has no unused dependencies. This is useful in pre-commit hooks and CI scripts" |
| `mix hex.outdated` | Hex 2.5.1 built-in | Weekly freshness report | Standard Hex task, no install needed |

### Package/version fix matrix (SUP-01) — all reproduced live this session, then reverted

| Lockfile | Advisory package(s) | Before | After | Command | `mix.exs` touched? |
|----------|---------------------|--------|-------|---------|---------------------|
| root `mix.lock` | mint (MEDIUM, response smuggling) | 1.10.0 | 1.10.1 | `mix deps.unlock mint && mix deps.get` | No — `mint` is not a direct dependency; it arrives transitively via `req` (optional) → `finch` → `mint ~> 1.8` |
| root `mix.lock` | lazy_html (LOW, mutation XSS, test-only) | 0.1.12 | 0.1.13 | `mix deps.unlock lazy_html && mix deps.get` | No — direct dep is `{:lazy_html, "~> 0.1.0", only: :test}` (mix.exs:104), constraint already permits 0.1.13 |
| `bench/mix.lock` | postgrex (1 HIGH, 1 MEDIUM, 1 LOW) | 0.22.0 | 0.22.4 | part of the combined bump below | No |
| `bench/mix.lock` | plug (2 HIGH, 1 MEDIUM, 1 LOW) | 1.19.1 | 1.20.3 | part of the combined bump below | No |
| `bench/mix.lock` | decimal (1 MEDIUM) | 2.3.0 | **3.1.1** (major!) | part of the combined bump below | No |

**Bench fix is a package group, not three independent bumps.** `mix deps.update postgrex plug decimal` alone still leaves `decimal` at 2.4.1, which `hex.audit` **still flags as VULNERABLE** for the same CVE (`EEF-CVE-2026-32686`) — confirmed live: `mix hex.audit` printed the advisory against 2.4.1 unchanged. The fix that actually clears it is `mix deps.update ecto ecto_sql decimal postgrex plug` — bench's own `ecto_sql "~> 3.10"` constraint currently locks `ecto` to 3.13.5, whose own dependency line pins `decimal "~> 2.0"` (verified: `bench/mix.lock:13`, `"ecto": {..., [{:decimal, "~> 2.0", ...}` — this is ecto's *own* transitive constraint on decimal, present in the currently-locked ecto 3.13.5, not something this repo declares). Ecto 3.14.2 (current on Hex, confirmed via `mix hex.info ecto`) relaxes that internal decimal bound enough for the resolver to land on decimal 3.1.1, which clears the advisory. `[VERIFIED: mix hex.audit output, run live this session]`:
```
$ cd bench && mix deps.update ecto ecto_sql decimal postgrex plug
Upgraded:
  decimal 2.3.0 => 3.1.1 (major)
  ecto 3.13.5 => 3.14.2
  ecto_sql 3.13.5 => 3.14.0
  plug 1.19.1 => 1.20.3
  postgrex 0.22.0 => 0.22.4
$ mix hex.audit
No retired or security advisory packages found
```
No `bench/mix.exs` edit was needed (`ecto_sql "~> 3.10"` still matches 3.14.0; `postgrex "~> 0.17"` still matches 0.22.4). `git diff --stat bench/mix.exs` was empty throughout. **All lockfile edits above were reverted (`git checkout -- mix.lock bench/mix.lock`) before returning — the executor must re-run and commit these for real.**

**Pitfall found live:** `bench` has a pre-existing, unrelated `mix compile --warnings-as-errors` failure (`Threadline.Test.NamingGenerators` / `ExUnitProperties` not loaded) that reproduces identically on the current `mix.lock` with no bench changes at all (`git stash` + `mix deps.get` + `mix compile` reproduced the same error). This is a `MIX_ENV`/`stream_data` visibility issue in how `bench`'s path-dependency on the root `threadline` app compiles its `test/support` helpers, **not caused by the dependency bump** and **not in scope for SUP-01**. Do not let the executor chase it as a regression; verify it exists on `git stash` before touching bench.

**lazy_html is a NIF with precompiled binaries** (declared `[:make, :mix]` build type via `elixir_make`/`cc_precompiler`/`fine` in `mix.lock`), but the 0.1.12→0.1.13 bump is a patch release on the same major/minor with no NIF-ABI-breaking change signaled in the lock (`elixir_make ~> 0.9`, `fine ~> 0.1.0` unchanged) — `[ASSUMED]` no toolchain change is needed; confirm both test lanes stay green post-bump (SUP-01 criterion 1 already requires this as a gate, not a research question).

**mint is an optional-chain dependency, not a direct one, and does affect Hex consumers.** `req` is declared `{:req, "~> 0.7", optional: true}` (mix.exs:99) and pulls `finch → mint ~> 1.8`. Because `req` ships as an *optional* dependency of the published `threadline` package, any adopter who also depends on `req` (directly or via another optional-consuming package) inherits whatever mint version their own resolver picks — this repo's lockfile bump does not change what adopters resolve, but the advisory is real for **this repo's own test suite / CI environment**, where `mint` is concretely locked at the vulnerable version. `fix(deps):` is the correct commit type per `release-please-config.json`'s `changelog-sections` (`fix` → "Bug Fixes"), and it **is releasable** — release-please's config lists `feat`/`fix`/`perf`/`deps`/`chore` as recognized types, with `chore` hidden; `fix` and `deps` both surface in `CHANGELOG-GENERATED.md`. `[VERIFIED: release-please-config.json, read this session]`.

### Supporting
| Item | Purpose | When to Use |
|------|---------|-------------|
| `bin/upsert-ci-issue` (existing) | Create-or-update one tracking issue, deduped by title marker + label | Reuse as-is for `deps-health.yml`; already generic (`--marker`, `--title`, `--body-file`, `--label`, `--label-description`, `--label-color`) `[VERIFIED: bin/upsert-ci-issue, read this session]` |
| `Hex.version/0` or `Application.spec(:hex, :vsn)` | Assert Hex ≥ 2.5.1 inside a mix task | `Hex.version()` returns a string (e.g. `"2.5.1"`); compare with `Version.compare/2` after coercing to a `Version.t()` — Hex versions are plain semver strings, no pre-release suffix seen locally |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled advisory DB / `mix_audit` (Dependabot-alerts-style) | `mix hex.audit` (built-in) | Already the chosen tool per REQUIREMENTS.md Out of Scope: "`mix_audit` / gitleaks / trufflehog — the audit DB misses current advisories" — do not introduce it |
| Dependabot version-update PRs | `deps-health.yml` weekly issue | Explicitly out of scope (REQUIREMENTS.md Out of Scope table); Dependabot **alerts** (not PRs) is a maintainer repo-setting hand-off, unrelated to this gate |
| Hex `cooldown` (delay resolving brand-new releases) | No action this phase | Real feature (Hex ≥2.5.0, confirmed via web search of hex.pm/docs/dependency-policies and the hexpm/hex PR #1160 that introduced it) but orthogonal to SUP-01..04's stated success criteria; not adopted — see Open Questions |

**Installation:** No new packages. This phase only bumps existing transitive lockfile entries (root: `mint`, `lazy_html`; bench: `ecto`, `ecto_sql`, `decimal`, `postgrex`, `plug`) and adds a mix.exs alias + CI workflow + test files.

**Version verification:** All versions in the table above were confirmed live via `mix hex.audit`, `mix deps.update`, and `git diff` in this session (2026-09-26), not from training data.

## Package Legitimacy Audit

No new external packages are installed in this phase — every package involved (`mint`, `lazy_html`, `ecto`, `ecto_sql`, `decimal`, `postgrex`, `plug`) is an existing, long-established transitive dependency already resolved from hexpm and already present in the committed lockfiles. The Package Legitimacy Gate does not apply; skipping per its own scope ("whenever this phase installs external packages").

## Architecture Patterns

### System Architecture Diagram

```
PR opened/pushed
      │
      ▼
ci.yml triggers (push/pull_request/workflow_dispatch)
      │
      ├─→ [existing jobs: verify-format, verify-credo, verify-test, ...]
      │
      └─→ verify-deps-audit  (NEW job, same-commit roster rule)
              │
              ├─→ mix verify.deps_audit   (NEW mix.exs alias)
              │      │
              │      ├─→ assert Hex.version() >= "2.5.1"          (pure, no network)
              │      ├─→ mix deps.unlock --check-unused           (root, pure)
              │      ├─→ mix hex.audit                            (root, network: Hex API)
              │      ├─→ cd bench && mix deps.get && mix hex.audit        (network)
              │      └─→ cd examples/threadline_phoenix && mix deps.get && mix hex.audit (network)
              │
              └─→ feeds into ci-required's needs: list (blocking)

Weekly (cron) — independent of PR flow
      │
      ▼
deps-health.yml (NEW workflow, non-required)
      │
      ├─→ mix hex.audit (root) + mix hex.outdated (root)
      │        (optionally also bench + example, per SUP-04 wording: "hex.audit + hex.outdated" — SUP-04 does not explicitly require all 3 lockfiles; recommend covering all 3 for consistency with SUP-02, but this is Claude's discretion since no CONTEXT.md locks it)
      │
      └─→ bin/upsert-ci-issue --label ci-deps
              │
              └─→ single "ci-deps" GitHub issue, created or updated (never duplicated)

Separately, gated at compile/test time —
mix.exs `hex: [ignore_advisories: [...]]` (if ever added)
      │
      ▼
NEW test: parses mix.exs `:hex` project config block, asserts every
ignore_advisories/ignore_retirements entry carries a reason + reachability
claim + unexpired review-by date (own convention — Hex itself does not
require or support structured metadata on ignore entries, so this must be
a repo-invented comment/annotation format, parsed by the test)
```

### Recommended Project Structure
```
mix.exs
  aliases()
    "verify.deps_audit": &verify_deps_audit/1   # NEW, private function like verify_bench/1

.github/workflows/
  ci.yml            # add verify-deps-audit job + add to ci-required needs: (same commit)
  deps-health.yml   # NEW workflow, weekly + workflow_dispatch, non-required

test/threadline/
  deps_audit_contract_test.exs        # NEW: same-commit roster + alias wiring (ci_topology_contract_test.exs pattern)
  ignore_advisories_contract_test.exs # NEW: parses mix.exs :hex config, asserts reason/reachability/review-by
  deps_health_doc_contract_test.exs   # NEW: CONTRIBUTING freshness-policy doc contract

CONTRIBUTING.md
  # NEW section: "Dependency freshness policy" — batched per release train, no Dependabot version-update PRs
  # NEW row in "### `ci-required` needs: roster" list + job table (SUP-02)

CHANGELOG.md
  ## Unreleased — highlights
  # NEW entry: fix(deps): mint 1.10.1 (response-smuggling advisory)
```

### Pattern 1: Cross-directory mix task invocation (existing precedent)
**What:** A private function in `mix.exs`'s `aliases()` that shells into a subdirectory, runs `mix deps.get` there, then runs the real command, raising on non-zero exit.
**When to use:** Any alias that must operate on `bench/` or `examples/threadline_phoenix/`, which are separate Mix projects with their own `mix.lock`.
**Example (verbatim precedent, `mix.exs:217-224`):**
```elixir
# Source: mix.exs, read this session
defp verify_bench(_args) do
  cmd =
    "bash -lc 'set -euo pipefail && cd bench && mix deps.get && MIX_ENV=test mix run scripts/seed_audit_changes.exs && ...'"

  case Mix.shell().cmd(cmd) do
    0 -> :ok
    status -> Mix.raise("verify.bench failed (#{status})")
  end
end
```
The new `verify_deps_audit/1` should follow this exact shape for the bench and example legs, e.g.:
```elixir
defp verify_deps_audit(_args) do
  assert_hex_version!()

  for dir <- [".", "bench", "examples/threadline_phoenix"] do
    cmd =
      "bash -lc 'set -euo pipefail && cd #{dir} && mix deps.get && mix hex.audit'"

    case Mix.shell().cmd(cmd) do
      0 -> :ok
      status -> Mix.raise("verify.deps_audit failed for #{dir} (#{status})")
    end
  end

  case Mix.shell().cmd("mix deps.unlock --check-unused") do
    0 -> :ok
    status -> Mix.raise("verify.deps_audit: unused-lock check failed (#{status})")
  end
end

defp assert_hex_version!() do
  unless Version.compare(Version.parse!(Hex.version()), Version.parse!("2.5.1")) != :lt do
    Mix.raise("verify.deps_audit requires Hex >= 2.5.1, found #{Hex.version()}")
  end
end
```
`[ASSUMED]` — `Hex.version/0` is the standard public API (used internally by `mix hex.info`'s own output header); not grepped from Hex's own source in this session, so tag accordingly. The executor should confirm `Hex.version/0` exists and returns a plain string before relying on it (fallback: `Application.spec(:hex, :vsn) |> to_string()`).

### Pattern 2: Issue upsert on a non-required scheduled lane (existing precedent)
**What:** `flake-detection.yml`'s "Open or update the flake tracking issue" step, reused near-verbatim for `deps-health.yml`.
**Example (verbatim precedent, `.github/workflows/flake-detection.yml`, read this session):**
```yaml
- name: Open or update the deps-health tracking issue
  if: always() && steps.audit.outputs.has_findings == 'true'
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    bin/upsert-ci-issue --marker "Dependency health" \
      --title "Dependency health: advisories or outdated packages found" \
      --body-file "$body_file" --label ci-deps \
      --label-description "Weekly hex.audit + hex.outdated findings" \
      --label-color FBCA04
```
`bin/upsert-ci-issue` signature (verified, `bin/upsert-ci-issue`, read this session): `--marker`, `--title`, `--body-file`, `--label` (required), `--label-description`, `--label-color`. It dedups on `"$marker in:title"` search against open issues carrying `--label`, and creates the label if missing (`gh label create ... || true`). This is directly reusable with zero modification — only the marker/title/label/body differ.

### Anti-Patterns to Avoid
- **Running `hex.audit` only on root:** SUP-01/SUP-02 explicitly require all three lockfiles (root, `bench`, `examples/threadline_phoenix`); the example app's lockfile is currently clean but must still be checked so a future regression there is caught.
- **Silently downgrading a `hex.audit` timeout/network failure to "pass":** follow the flake-detection idiom (`unknown`/inconclusive is a distinct, loud state, never silently mapped to green).
- **Editing `mix.exs` constraints to "fix" an advisory:** SUP-01 explicitly requires lock-only fixes; a constraint edit would need broader compatibility testing and is out of scope.
- **Bumping only `decimal` directly for the bench advisory:** as shown above, `decimal` alone stalls at 2.4.1 (still vulnerable) because of `ecto`'s own internal constraint; the real fix bumps `ecto`/`ecto_sql` too.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Advisory database / vulnerability feed | Custom CVE scraper | `mix hex.audit` (built-in, Hex 2.5.1) | Already the standing decision (REQUIREMENTS.md Out of Scope: `mix_audit`/gitleaks/trufflehog explicitly rejected) |
| Issue dedup logic | New upsert script | `bin/upsert-ci-issue` | Already generic, already tested by the flake-detection lane in production |
| Unused-dependency detection | Custom mix.lock diff | `mix deps.unlock --check-unused` | Built into Mix core, exact semantics documented via `mix help deps.unlock` |

**Key insight:** Every mechanism SUP-01..04 need already exists somewhere in this repo (Hex's own audit/ignore/version APIs, the `verify_bench` alias shape, `bin/upsert-ci-issue`, the `ci_topology_contract_test.exs` roster-drift pattern). This phase's actual novelty is (1) the three-lockfile fan-out and (2) the `ignore_advisories` reason/reachability/review-by convention, which is a repo-invented annotation format layered on top of Hex's real (but metadata-free) `ignore_advisories` list.

## Common Pitfalls

### Pitfall 1: Bumping `decimal` alone leaves it vulnerable
**What goes wrong:** `mix deps.update decimal` (or `postgrex`, `plug` alone) resolves `decimal` to 2.4.1, which `hex.audit` still flags for `EEF-CVE-2026-32686`.
**Why it happens:** `ecto` 3.13.5 (currently locked in `bench/mix.lock`) itself declares `{:decimal, "~> 2.0", ...}` in its own package metadata — a transitive ceiling this repo does not control until `ecto` itself is bumped.
**How to avoid:** Bump `ecto`/`ecto_sql` together with `decimal`/`postgrex`/`plug`: `mix deps.update ecto ecto_sql decimal postgrex plug`.
**Warning signs:** `hex.audit` still reports an advisory after an update that appeared to succeed with no error.

### Pitfall 2: `bench`'s pre-existing compile failure looks like a regression
**What goes wrong:** `cd bench && mix compile --warnings-as-errors` fails with `module ExUnitProperties is not loaded` regardless of any dependency bump.
**Why it happens:** Confirmed via `git stash` + fresh `deps.get` that this reproduces identically on the untouched lockfile — it is a pre-existing local environment/path-dependency quirk (the `threadline` path dependency's `test/support` helpers reference `stream_data`'s `ExUnitProperties`, which is a `:test`-only dep of the root project not necessarily visible when compiled as a path dependency under bench's own env), unrelated to SUP-01.
**How to avoid:** Do not use plain `mix compile --warnings-as-errors` as bench's "did the bump break anything" check; SUP-01 criterion 1's actual gate is "both test lanes are green" (root's own `verify-test`), not bench compiling standalone. If bench needs to build at all for the bump to be provable, reproduce the baseline failure state first (`git stash`) to confirm it's pre-existing before investigating further.
**Warning signs:** The identical error message before and after any dependency change.

### Pitfall 3: `hex.audit`'s network dependency inside a negative-fixture test
**What goes wrong:** A test that asserts `verify.deps_audit` "exits non-zero on a known-vulnerable lock" needs `mix hex.audit` to actually run and see real advisory data — which requires the Hex API/CDN to be reachable from the test runner.
**Why it happens:** `hex.audit` is not a purely-local check; it consults live/synced advisory data via the Hex client (evidenced by the "Your authentication session has expired..." warning printed even on an unauthenticated, read-only `hex.audit` call in this session — Hex is reaching out).
**How to avoid:** See Open Questions #1 below — recommend a fixture *directory* with its own tiny `mix.exs`/`mix.lock` pinning a package version known to carry a long-standing, stable advisory (e.g. an old `plug` or `postgrex` version already used in this exact bench fixture matrix), invoked as a subprocess from the test, tagged so it's excluded from the default fast `mix test` loop (mirroring `pgbouncer_topology: true`'s exclusion-tag pattern in `test/test_helper.exs`) and run explicitly in the `verify-deps-audit` CI job (which already has network).
**Warning signs:** Flaky CI failures on the negative-fixture test specifically when Hex's advisory endpoint is briefly unreachable — treat as a known limitation, not a discovered bug, if it recurs.

## Code Examples

### Same-commit roster contract pattern (adapt this exact shape for the new job)
```elixir
# Source: test/threadline/ci_topology_contract_test.exs, read this session (lines 336-363, 558-596)
defp ci_required_needs do
  block = ci_required_block()

  case Regex.run(~r/    needs:\n((?:      - .+\n)+)/, block) do
    [_, items] ->
      items
      |> String.split("\n", trim: true)
      |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

    nil ->
      []
  end
end

test "ci-required's needs: roster matches CONTRIBUTING.md in both drift directions" do
  actual = ci_required_needs()
  documented = documented_needs_roster()
  # symmetric diff both ways — this is the exact test to extend so that
  # verify-deps-audit landing in ci.yml but not CONTRIBUTING.md (or vice
  # versa) fails loudly
end
```

### Issue-upsert binary signature (reuse, don't reimplement)
```bash
# Source: bin/upsert-ci-issue, read this session
# usage: upsert-ci-issue --marker <title-prefix> --title <full-title> \
#          --body-file <path> --label <label> [--label-description <desc>] \
#          [--label-color <hex>]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Dependabot version-update PRs | Weekly `deps-health.yml` issue + batched release-train updates | Decided at v1.43 requirements definition (2026-09-26) | Fewer PRs, same signal, maintainer controls cadence |
| No audit gate in CI | `verify-deps-audit` job in `ci-required` | This phase | Advisories block merge instead of silently accumulating |
| `decimal` 2.x line | `decimal` 3.x now resolvable once `ecto` ≥ 3.14 | Ecto 3.14.0 (2026-05-19, per `mix hex.info ecto`) relaxed its internal `decimal` constraint | Unblocks the bench advisory fix without a manual `mix.exs` edit |

**Deprecated/outdated:** None identified specific to this phase's packages.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Hex.version/0` is the correct public API to assert Hex ≥ 2.5.1 inside a mix task | Pattern 1 code example | Task fails to compile/run; executor must find the actual accessor (fallback `Application.spec(:hex, :vsn)` noted) |
| A2 | lazy_html 0.1.12→0.1.13 needs no toolchain/NIF ABI change | SUP-01 stack table | If wrong, PLAT-03's OTP-26-NIF-on-ubuntu-24.04 concern (Phase 216) could interact; SUP-01 criterion 1 already gates on both test lanes green, which would catch this |
| A3 | The `ignore_advisories` reason/reachability/review-by metadata format is a repo-invented convention (no Hex-native support) | Architecture diagram, Don't Hand-Roll | If a maintainer expects Hex to natively support this metadata, the design needs re-scoping — but `mix help hex.audit` (read this session) shows `ignore_advisories` is a bare list of advisory IDs with no metadata fields, so this is fairly solid, not purely assumed |
| A4 | SUP-04's `deps-health.yml` should run `hex.audit`+`hex.outdated` over all three lockfiles (root, bench, example), not root-only | Architecture diagram | SUP-04's literal wording only says "runs `hex.audit` + `hex.outdated`" without specifying scope; Claude's-discretion call for consistency with SUP-02's three-lockfile scope |
| A5 | `erlef/setup-beam@v1` installs a Hex version ≥2.5.1 matching local, since no explicit `mix local.hex <version>` pin was found in any workflow | Standard Stack | If CI's setup-beam-bundled Hex is actually older than 2.5.1, `verify.deps_audit`'s own Hex-version assertion would correctly fail CI on the very first run — self-detecting, low risk |

**If this table is empty:** N/A — see above.

## Open Questions

1. **How should the negative-fixture test prove `verify.deps_audit` goes red on a known-vulnerable lock and an old Hex, without flaking on network?**
   - What we know: `hex.audit` reaches out to Hex's advisory data even for an unauthenticated read (observed live). `mix test.reset`-style fixture patterns and `test/fixtures/*` directories already exist for other checkers (dialyzer, style, operator_surface), but none currently spin up a full nested Mix project + `mix deps.get` + `mix hex.audit` from within `mix test`.
   - What's unclear: Whether a genuinely-network-dependent negative test belongs in the default `mix test` loop (against the "honest default tests" CLAUDE.md rule, which is about not silently excluding suites, not about forbidding tagged exclusions) or should be its own tagged/excluded test run only inside `verify-deps-audit`'s CI job (mirroring `pgbouncer_topology: true`).
   - Recommendation: Build a tiny fixture project under `test/fixtures/deps_audit/vulnerable_lock/` (own `mix.exs` + a `mix.lock` pinning e.g. an old `plug` or `postgrex` version already proven to carry a stable, long-lived advisory), assert via `System.cmd("mix", ["hex.audit"], cd: fixture_dir)` returns non-zero; tag this test (e.g. `@tag :deps_audit_network`) and exclude it from default `mix test` via `test/test_helper.exs` the same way `pgbouncer_topology: true` is excluded, then have the `verify-deps-audit` CI job run it explicitly (analogous to how `verify-pgbouncer-topology` sets `THREADLINE_PGBOUNCER_TOPOLOGY=1`). For "old Hex", since you cannot install a second Hex version in one job cheaply, consider instead unit-testing only the version-comparison *logic* (`Version.compare` against a stubbed/injected version string) rather than an actual old Hex binary — that's fully offline and equally load-bearing for the assertion itself.

2. **Should `deps-health.yml` run over all three lockfiles or root only?**
   - What we know: SUP-04's literal text is silent on scope; SUP-02 explicitly scopes to all three.
   - What's unclear: Cost/value tradeoff of running `hex.outdated` over bench and the example app weekly (low cost, non-required, non-blocking).
   - Recommendation: Match SUP-02's three-lockfile scope for consistency and because SUP-01 already establishes bench/example as maintained lockfiles worth watching.

3. **Hex `cooldown` — adopt or not?**
   - What we know: Real feature since Hex 2.5.0 (`[CITED: hex.pm/docs/dependency-policies, hexpm/hex PR #1160]`, confirmed via web search this session, not yet independently verified by reading Hex's own source in this environment). Configured via `hex: [cooldown: "..."]` in `mix.exs`, `HEX_COOLDOWN` env var, or `mix hex.config`. Filters out freshly-published releases from resolution; does not apply to already-locked versions or to versions needed to fix an active advisory/retirement.
   - What's unclear: Whether the maintainer wants this as part of the freshness policy (it would reduce the automatic-newest-release supply-chain window, complementary to but distinct from batched release-train updates).
   - Recommendation: **Do not adopt in Phase 215.** None of SUP-01..04's success criteria mention it, REQUIREMENTS.md's Out of Scope table doesn't list it either way (silent), and per the phase description's own instruction ("Research: Narrow, only if Hex cooldown is adopted") — since it is not being adopted, this satisfies the instruction by confirming where it *would* be configured (`mix.exs` `:hex` project key, same place as `ignore_advisories`) without implementing it. Revisit only if the maintainer explicitly wants it as a future freshness-policy layer.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Hex | `mix hex.audit`, `ignore_advisories` | ✓ | 2.5.1 (local, matches SUP-02's `>= 2.5.1` bar) | — |
| Network access to Hex API | `mix hex.audit` (all three lockfiles), `mix hex.outdated` | ✓ locally (session had network) | — | CI runners have outbound network by default; no fallback needed, but flag network-dependent tests as such (see Open Question 1) |
| `.tool-versions` | asdf-managed erlang/elixir pin | ✓ | erlang 27.3.4.15, elixir 1.17.3-otp-27, nodejs 22.14.0 | Already tracked (per CLAUDE.md gotcha, confirmed present and correctly populated this session — no dying-bare-mix issue encountered) |
| `bench/.tool-versions`, `examples/threadline_phoenix/.tool-versions` | Toolchain pin for nested projects | ✗ (none exist) | — | asdf falls back to the parent directory's `.tool-versions`; both subdirectory `mix deps.get`/`mix hex.audit` invocations in this session used the same root-pinned toolchain successfully — no fallback action needed |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None beyond the asdf parent-lookup noted above (which already worked, not merely theoretical).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir 1.17.3) |
| Config file | `test/test_helper.exs` (exclusion-tag pattern: `pgbouncer_topology: true`) |
| Quick run command | `mix test test/threadline/deps_audit_contract_test.exs` |
| Full suite command | `mix test` (offline parts) + `mix verify.deps_audit` (network parts, run directly, not via `mix test`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|--------------------|-------------|
| SUP-01 | All three lockfiles are `hex.audit`-clean, no `mix.exs` diff | integration (manual/CI verification, not a unit test — the fix IS the lockfile state) | `mix hex.audit && (cd bench && mix hex.audit) && (cd examples/threadline_phoenix && mix hex.audit)` + `git diff --stat mix.exs bench/mix.exs` (must be empty) | ❌ Wave 0 — no existing test asserts "lockfile has zero advisories"; this is asserted by the CI job itself (SUP-02) once it exists |
| SUP-02 | `verify.deps_audit` alias exists, runs unused-lock + hex.audit×3 + Hex-version assert; `verify-deps-audit` CI job wired into `ci-required` | contract (source-parsing, offline) | `mix test test/threadline/deps_audit_contract_test.exs` | ❌ Wave 0 |
| SUP-02 | Negative fixture: gate exits non-zero on vulnerable lock / old Hex | integration, network-tagged | `mix test --only deps_audit_network` (excluded from default `mix test`) | ❌ Wave 0 |
| SUP-03 | `ignore_advisories` entries carry reason/reachability/review-by, test fails on expired/missing | contract (source-parsing, offline) | `mix test test/threadline/ignore_advisories_contract_test.exs` | ❌ Wave 0 |
| SUP-04 | `deps-health.yml` upserts one `ci-deps` issue; CONTRIBUTING states the freshness policy | contract (YAML text assertions) + doc-contract | `mix test test/threadline/deps_health_doc_contract_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/deps_audit_contract_test.exs test/threadline/ignore_advisories_contract_test.exs test/threadline/deps_health_doc_contract_test.exs`
- **Per wave merge:** `mix ci.all` (does not include `verify.deps_audit` itself, per the `verify.bench`/`verify.release` precedent of release-lane checks staying out of `ci.all` — but `verify.deps_audit` is a per-PR CI gate, not a release-lane check, so it likely SHOULD be added to `ci.all` unlike those two; confirm during planning against `ci_topology_contract_test.exs`'s existing "ci.all alias does not include verify.bench/verify.release" tests, which would need a symmetric "ci.all DOES include verify.deps_audit" assertion if that's the intended shape)
- **Phase gate:** Full suite green before `/gsd-verify-work`, plus a live `mix hex.audit` run over all three lockfiles

### Wave 0 Gaps
- [ ] `test/threadline/deps_audit_contract_test.exs` — covers SUP-02 (roster wiring, alias structure, Hex-version assertion source)
- [ ] `test/fixtures/deps_audit/vulnerable_lock/` (fixture project) — covers SUP-02's negative fixture
- [ ] `test/threadline/ignore_advisories_contract_test.exs` — covers SUP-03
- [ ] `test/threadline/deps_health_doc_contract_test.exs` — covers SUP-04
- [ ] Framework install: none — ExUnit and Hex are already present

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|-------------------|
| V2 Authentication | No | N/A — this phase touches build tooling, not auth |
| V14 Configuration / Dependency Management | Yes | `mix hex.audit` gate (the standard Elixir-ecosystem control for known-vulnerable dependency versions) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Known-vulnerable transitive dependency shipped to production | Tampering / Information Disclosure (depends on the specific CVE) | `mix hex.audit` in CI, gated on `ci-required`, exactly as this phase implements |
| Advisory silently suppressed with no accountability | Repudiation | SUP-03's reason/reachability/review-by-date requirement on every `ignore_advisories` entry, test-enforced |
| Dependency-flood social-engineering / malicious-package-publish window | Spoofing (supply chain) | Hex `cooldown` (considered, not adopted this phase — see Open Questions #3); batched release-train review is the adopted mitigation instead |

## Sources

### Primary (HIGH confidence — reproduced live this session)
- `mix hex.audit` (root, bench, examples/threadline_phoenix) — run live, all advisory lists and fix commands verified
- `mix hex.info`, `mix help hex.audit`, `mix help deps.unlock` — local Hex 2.5.1 CLI output, read this session
- `mix.exs`, `bench/mix.exs`, `bench/mix.lock`, root `mix.lock` — read this session
- `.github/workflows/ci.yml`, `.github/workflows/flake-detection.yml`, `bin/upsert-ci-issue` — read this session
- `test/threadline/ci_topology_contract_test.exs`, `test/test_helper.exs` — read this session
- `release-please-config.json`, `CHANGELOG.md`, `CONTRIBUTING.md` — read this session
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md` — read this session

### Secondary (MEDIUM confidence)
- Hex `cooldown` feature — WebSearch this session, citing hex.pm/docs/dependency-policies and hexpm/hex GitHub PR #1160; not independently re-verified by reading Hex's own source in this environment

### Tertiary (LOW confidence)
- `Hex.version/0` as the exact public API call — plausible standard API, not grepped from Hex's own source this session; flagged `[ASSUMED]` in the Assumptions Log with a fallback

## Metadata

**Confidence breakdown:**
- Standard stack / package fix matrix: HIGH — every fix reproduced live and reverted this session
- Architecture (alias/CI wiring patterns): HIGH — directly copying existing, working precedents in this exact repo
- Pitfalls: HIGH for the decimal/ecto and bench-compile pitfalls (both reproduced live); MEDIUM for the negative-fixture network design (reasoned, not built)
- Hex `cooldown` disposition: MEDIUM (web-search-sourced, not locally verified against Hex source)

**Research date:** 2026-09-26
**Valid until:** ~14 days (advisory data and Hex/ecto/decimal/postgrex/plug versions move; re-run `mix hex.audit` fresh before executing if this research is more than 2 weeks old)
