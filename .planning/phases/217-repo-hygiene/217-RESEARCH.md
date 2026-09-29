# Phase 217: Repo Hygiene - Research

**Researched:** 2026-09-27
**Domain:** Repo-hygiene tooling for a public Elixir Hex library — `git grep` PII/path scrubbing, a `bin/`-script CI guard wired through `mix.exs`/`ci.yml`, ExUnit `@tag :tmp_dir` migration, and an xref-cycle documentation disposition.
**Confidence:** HIGH. Every concrete fact below (file lists, counts, line numbers, alias names) was re-verified this session with `git grep`, `git log`, and direct file reads — not carried from memory. Milestone-level research (`STACK.md`/`FEATURES.md`/`PITFALLS.md`, written 2026-09-26 for the whole v1.43 milestone) already covers this phase in depth; this document narrows it to Phase 217's exact scope and re-confirms every number against the current tree (one day later, after Phase 216 landed more commits).

## Summary

Phase 217 has four requirements (HYG-01..04), and three of them are smaller than the milestone-level research implied, because two things already happened without a dedicated phase: (1) Phase 214's BASE-02 work **already corrected** `MILESTONE-GUIDE.txt` §9a and `PROJECT.md`'s xref disposition (commit `ed4cd161`), so HYG-04 is largely a verification task, not new-content work; (2) this session's fresh `git grep` confirms the exact scrub scope: **296 tracked files**, all under `.planning/`, contain the real home-directory path `/Users/<user>/`, plus **2 files outside `.planning`** (`prompts/prior-art/SOURCE-CANONICAL.md`, `prompts/prior-art/accrue-planning-notes.md`) contain a different machine's `<home>/projects/...` paths. No file outside `.planning/` and `prompts/prior-art/` needs scrubbing — `.github/workflows/*.yml` and the one contract test that mentions `~/.cache/ms-playwright` are legitimate CI cache paths, not PII.

The 7 leaking test files for HYG-03 are now identified exactly (not just counted): they are the 7 files among the 40 `System.tmp_dir`-using test files whose only cleanup, if any, runs inline in the test body rather than through `on_exit/1` — meaning a failed assertion mid-test skips cleanup and leaks a directory into the real system temp dir. Two of the seven (`getting_started_fixtures_test.exs`, `operator_surface/exports_mix_parity_test.exs`) have **no** cleanup at all.

**Primary recommendation:** Sequence the phase as scrub → guard → tmp_dir → xref-disposition-confirm, exactly as the cross-cutting invariant in ROADMAP.md requires ("scrub before the path guard"). Build the guard using the same `bin/` script + `MIX_BIN`-style-fake-binary + `--self-test` pattern already proven by `bin/verify-deps-audit` (Phase 215) — this repo has a working template for exactly this kind of gate, so don't invent a new shape.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Path scrub (rewrite tracked doc/receipt prefixes) | Repo content (docs/planning tier) | — | Pure content edit; no runtime code touched |
| Local-path CI guard (`bin/check-local-paths` + `verify-repo-hygiene` job) | CI / Build tooling tier | Test tier (self-test + contract test) | New `bin/` script wrapped by a `mix verify.*` alias and a CI job — the same tier as `bin/verify-deps-audit` |
| `@tag :tmp_dir` test migration | Test tier | — | ExUnit-internal; no production code changes |
| xref-cycle disposition record | Documentation tier (MILESTONE-GUIDE, PROJECT.md) | Architecture tier (no code change — `verify.xref_cycles` untouched) | A decision record, not a new gate |

This phase touches **no** Capture/Semantics/Exploration application code. Everything here is CI tooling, test hygiene, and documentation — confirm the plan does not accidentally introduce a `verify.xref_cycles_all` or any other runtime-cycle gate, which REQUIREMENTS.md's Out of Scope table explicitly forbids even though the milestone-level `STACK.md` inference section suggested it as a differentiator.

## User Constraints

No CONTEXT.md exists for this phase — the maintainer chose to plan directly from REQUIREMENTS.md (HYG-01..04 are "fully specified"). Treat REQUIREMENTS.md, ROADMAP.md's Phase 217 section, and the "Standing rules for every requirement" block in REQUIREMENTS.md as locked constraints; there is no separate discretion/deferred split to copy verbatim. The standing rules that bind every Phase 217 plan:

- Same-commit roster rule for any `verify-*` job add/remove/rename (`ci.yml`, CONTRIBUTING roster + `## CI Coverage` table, `ci-required` `needs:`, `ci_topology_contract_test.exs`, all in one commit).
- No trigger-level `paths:` filters, no static `allowed-skips`, no `continue-on-error` on a voting job.
- Never `git add .planning/` wholesale — stage explicit file lists only.
- Zero human verification; push/merge/`production-hex` approval stay with the maintainer.
- Out of scope (REQUIREMENTS.md): a runtime xref-cycle gate — "the 5 runtime cycles are Ecto association edges by design and the compile-connected gate already exists."

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HYG-01 | No tracked file contains an absolute machine-local path; forward scrub only, stages exactly the `git grep -l -I` list, covers `prompts/prior-art/` | Exact file list, counts, and prefixes captured below (§ Scrub scope) |
| HYG-02 | `bin/` guard + `verify.*` alias + `verify-repo-hygiene` job in CI, allowlists runner/cache paths, fails on unused allowlist entry, runtime-built negative-test fixtures, no real username anywhere | `bin/verify-deps-audit` gives a proven template (§ Guard implementation pattern) |
| HYG-03 | The 7 leaking test files (+ any async collisions) use `@tag :tmp_dir`; out-of-repo tests keep `System.tmp_dir!()`; tree-walkers ignore `tmp/`; full `mix test` leaves no new temp-dir entries | 7 files identified by name below (§ tmp_dir migration) |
| HYG-04 | MILESTONE-GUIDE §9a names `compile-connected`; `verify.xref_cycles` unchanged; no runtime-cycle gate; Capture↔Semantics edge logged as v1.45 observation | Already substantially done by Phase 214 (commit `ed4cd161`) — verification task, see § xref disposition |

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|---------------|
| `git grep -I` | git (runner-provided, no install) | Scans tracked, non-binary files only; never sees `deps/`, `_build/`, or untracked critic scratch files | Already the tool used by the milestone-level research to derive every number in this document; zero new dependency |
| ExUnit `@tag :tmp_dir` | Elixir >= 1.11 (repo pins 1.17.3, min lane 1.15.x) [VERIFIED: `.tool-versions` — `erlang 27.3.4.15` / `elixir 1.17.3-otp-27`, read this session] | Per-test, per-module unique temp dir, wiped at test *start*, async-safe by construction | Built into ExUnit; this repo's Elixir floor (1.15.x per REQUIREMENTS.md PLAT scope) already supports it |
| bash + `git grep` inside `bin/check-local-paths` | n/a | The guard script itself | Matches the existing `bin/verify-deps-audit` shape (bash script, `--self-test` flag, `MIX_BIN`/similar env seam for offline fixture tests) |

**No new package dependency is introduced by this phase.** There is nothing to run through the Package Legitimacy Gate — skip that section below with an explicit "none" per the template's own instruction.

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| `git grep`-based guard | `gitleaks` / `trufflehog` | Rejected in REQUIREMENTS.md Out of Scope: "audit DB misses current advisories... history mode would flag the deliberately unrewritten past." A custom regex guard is the only tool that (a) scans tracked-only, (b) never touches git history, (c) needs no binary download. |
| Forward scrub only | `git filter-repo` / BFG history rewrite | Explicitly out of scope — "Maintainer decision (2026-09-25): forward scrub only." Never propose this. |

## Package Legitimacy Audit

**Not applicable.** This phase installs no new external package (no `mix.exs` dependency, no npm package). The guard is a bash script under `bin/`, and the tmp_dir work only touches test code already using ExUnit, which is already a dependency of the project. Skip the audit table.

## Architecture Patterns

### System Architecture Diagram

```
                         Phase 217 data flow
                         ====================

  [tracked git files]                     [CI pull_request / push]
         |                                          |
         v                                          v
  git grep -l -I <patterns>            .github/workflows/ci.yml
   (scrub script, one-time,             job: verify-repo-hygiene
    run by a human/agent locally,               |
    NOT part of CI)                             v
         |                             bin/check-local-paths
         v                              (git grep -I -n over
  edit matched files:                   git ls-files, allowlist
   prefix-only rewrite                   filtered, exit 1 on hit
   (repo-relative or <home>/...)         or on unused allowlist
         |                               entry)
         v                                      |
  git add -- <exact grep -l list>                v
  git commit (scrub commit)              mix verify.no_local_paths
                                          (alias wrapping the script)
                                                  |
                                                  v
                                          part of `mix ci.all`
                                          and the CI job above
                                                  |
                                                  v
                                          ci-required needs: [...,
                                            verify-repo-hygiene]

  Separately, unconnected to the above:

  [test/**/*_test.exs using System.tmp_dir!()]
         |
         v
   7 files (no on_exit cleanup) ---> migrate to @tag :tmp_dir
   33 files (already have on_exit/rm_rf) ---> leave as-is
   git-isolation / walk-the-repo tests ---> leave on System.tmp_dir!()
                                             (never migrate: :tmp_dir
                                             lands inside <repo>/tmp/)
```

### Recommended Project Structure

No new directories. Additions land in existing locations:

```
bin/
├── check-local-paths        # NEW — the guard script (name from STACK.md; final name is planner's call)
├── verify-deps-audit         # EXISTING — template to copy the --self-test / fake-binary pattern from
test/threadline/
├── local_paths_guard_test.exs   # NEW (name illustrative) — offline contract test, runtime-built fixtures
├── <7 migrated test files>      # EDITED — @tag :tmp_dir added, on_exit removed where redundant
.planning/
├── <296 scrubbed files>          # EDITED — path-prefix-only rewrite
prompts/prior-art/
├── SOURCE-CANONICAL.md           # EDITED — same
├── accrue-planning-notes.md      # EDITED — same
.planning/MILESTONE-GUIDE.txt     # VERIFY ONLY — already corrected 2026-09-26 (commit ed4cd161); confirm, do not re-edit unless a gap is found
```

### Pattern 1: The `bin/` guard + `mix verify.*` alias + CI job template (from `bin/verify-deps-audit`)

**What:** A bash script under `bin/` that (a) does the real work via `git grep`/similar, (b) exits non-zero with actionable `file:line` output, and (c) supports a `--self-test` mode that builds its own positive/negative fixtures at runtime (never committing a real-looking hit) and asserts the script goes red on them. `mix.exs` wraps it in a `verify.*` alias; `ci.yml` runs the alias plus the `--self-test` step in its own job; `ci-required`'s `needs:` gains the new job id in the same commit as the roster/CONTRIBUTING/topology-contract-test edits.

**When to use:** Any new required CI gate in this repo — this is the established, working shape, not a one-off design choice for this phase.

**Example (existing code, read this session):**
```bash
# Source: bin/verify-deps-audit (this repo, read 2026-09-27)
# ... (lines 1-40, header comment)
# `--self-test` proves the gate actually has teeth against real Hex, in four
# cases: (a) it copies a committed, deliberately vulnerable lock ... and runs
# this gate on it (must go red, and go red FOR AN ADVISORY, not vacuously);
# ...
set -euo pipefail
die() {
  printf 'verify-deps-audit: %s\n' "$*" >&2
  exit 2
}
```
```elixir
# Source: mix.exs (this repo, read 2026-09-27)
"verify.deps_audit": &verify_deps_audit/1,
```
```yaml
# Source: .github/workflows/ci.yml:933-960 (this repo, read 2026-09-27)
verify-deps-audit:
  name: Dependency audit (all lockfiles)
  runs-on: ubuntu-24.04
  timeout-minutes: 10
  steps:
    - uses: actions/checkout@v5
    - uses: erlef/setup-beam@v1
      id: beam
      with:
        version-file: .tool-versions
        version-type: strict
    - name: Audit root, bench and example lockfiles
      run: mix verify.deps_audit
    - name: Prove the gate goes red (vulnerable lock, old Hex)
      run: bin/verify-deps-audit --self-test
```
The `ci-required` `needs:` list (`.github/workflows/ci.yml`, the block immediately following) then has `verify-deps-audit` as its final entry — `verify-repo-hygiene` follows the identical shape.

### Pattern 2: Self-referential-safety in the guard's own test file

**What:** A guard whose test fixture contains a real-looking home path defeats its own purpose. This repo already has the convention for this, applied to a different guard.
**When to use:** The new `local_paths_guard_test.exs` (or whatever it is named) and the guard script itself.
**Example:**
```elixir
# Source: test/threadline/ci_workflow_parity_contract_test.exs:419-420 (read 2026-09-27)
# "Assembled so this file's own text never contains the needles it forbids."
@os_family_context "runner" <> ".os"
@deprecated_runner_image "ubuntu-" <> "22.04"
```
Apply the same string-concatenation trick for any positive-case fixture path the new guard's test builds (e.g. `"/" <> "Users" <> "/" <> "fakeuser" <> "/x"` rather than a literal that a future scrub of *this* file would itself need to catch).

### Pattern 3: Roster/contract-test derivation, not hand-maintained duplication

**What:** `ci_topology_contract_test.exs` derives the required roster from `CONTRIBUTING.md`'s `### \`ci-required\` needs: roster` heading and diffs it against `ci.yml`'s actual `needs:` list, in both directions (`test/threadline/ci_topology_contract_test.exs:583-623`, read this session). Nothing hand-maintains two independent lists that could silently drift.
**When to use:** Adding `verify-repo-hygiene` to the roster — add it to the CONTRIBUTING roster bullet list (`CONTRIBUTING.md:470-484`, currently 15 bullets ending in `` `verify-deps-audit` ``) and to `ci.yml`'s `needs:` in the same commit; the contract test enforces the rest.

### Anti-Patterns to Avoid

- **Allowlisting instead of scrubbing.** PITFALLS.md (this repo's own milestone research) names this explicitly: "Allowlisting the 295 files in the path guard instead of scrubbing... Never." The guard must launch on a scrubbed, clean baseline — scrub lands first, in its own commit, before the guard's job is added.
- **`git add .planning/` or any wildcard stage.** 1,066+ untracked machine-local critic files live under `.planning/` (per CLAUDE.md memory and confirmed present via `.gitignore` entries for `.planning/critic-scores/`, `.planning/critic-verdict-cache/`, etc.). The scrub commit's `git add` must take the **exact** `git grep -l -I` file list as arguments, never a directory.
- **Adding a runtime-cycle xref gate.** REQUIREMENTS.md Out of Scope forbids this outright; `STACK.md`'s own "Supporting" table lists `verify.xref_cycles_all` as an *inference*-tagged suggestion the milestone requirements later overrode. Do not implement it.
- **A `_build` or `deps` cache in the new `verify-repo-hygiene` job.** The job needs no compile step at all (pure `git grep` + `mix test` for the contract test) — don't copy a cache block from another job "for consistency."

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Detecting a machine-local absolute path | A custom multi-language path-detection library | `git grep -I` with a small, explicit regex set (`/Users/[A-Za-z0-9._-]+/`, `/home/(?!runner/)[A-Za-z0-9._-]+/`, `<home>/(projects|Documents|Desktop|\.[a-z])`, `C:\\Users\\`) | The pattern only needs to catch *this repo's* observed shapes (verified below); a generic PII-scanning library would both over- and under-match and add a dependency |
| Proving the guard has teeth | A tagged ExUnit test requiring network/fixtures committed to the repo | A `--self-test` mode that builds fixtures at runtime (same shape as `bin/verify-deps-audit --self-test`) | Keeps the negative-test fixture out of the default `mix test` lane (no network dependency) while still running in CI as a job step, and — critically — never commits a real-looking home path as a test literal |
| Test temp-dir isolation | Hand-rolled `System.tmp_dir!() <> unique_integer` pattern (already used in 40 files) | ExUnit's built-in `@tag :tmp_dir` for the 7 leaking files | ExUnit already solves "unique per test, async-safe, wiped before use" — re-deriving it by hand for 7 files that lack `on_exit` cleanup is exactly the failure mode being fixed |

**Key insight:** every piece of this phase has a working precedent already in the repo (the deps-audit guard shape, the `:tmp_dir` contract-test self-referential-safety trick, the roster-derivation contract test). The research task was locating exact facts, not searching for new tools.

## Runtime State Inventory

This is not a rename/refactor/migration phase in the sense the template's inventory targets (no renamed identifiers, no database schema, no external service config). It is, however, a repo-content scrub with real state-inventory risk, so the five categories are answered explicitly:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — the scrub touches only tracked `.planning/*.md`/`.json` doc files and two `prompts/prior-art/*.md` files. No database, no ChromaDB/Mem0-style store holds these paths. | None |
| Live service config | None — GitHub Actions workflow files (`ci.yml`, `browser-full.yml`) already use only legitimate runner paths (`~/.cache/ms-playwright`); no service config elsewhere references a machine-local path. | None |
| OS-registered state | None — no Task Scheduler / launchd / pm2 involvement in this repo's CI or test tooling. | None |
| Secrets/env vars | None — no secret or env var name embeds a machine-local path. | None |
| Build artifacts | None — `tmp/` is already `.gitignore`d (`.gitignore:45`); no stale build artifact carries a scrubbed path. | None |

**The one genuinely stateful risk:** `.planning/` contains **1,066 untracked** machine-local critic/scratch files (per `.gitignore` entries for `critic-scores/`, `critic-verdict-cache/`, `critic-report.html`, `scorecards/`, `refute/`, `state.json`, `milestone.lock`, `agent-history.json` — confirmed present in `.gitignore` this session) that must **never** be staged. The scrub's `git add` command must take the exact file list from `git grep -l -I`, and the plan should include an explicit post-stage assertion (`git status --porcelain` shows no new `A` entries outside the list) before committing.

## Common Pitfalls

### Pitfall 1: Scrub scope creep into content, not just prefixes

**What goes wrong:** A blanket find-and-replace regex rewrites more than the path prefix — e.g. it also touches escaped-JSON forms (`\/Users\/<user>`) inside `.planning/audits/*.json` audit logs, altering a byte-for-byte historical receipt.
**Why it happens:** A single global regex is easier to write than a scoped one.
**How to avoid:** Replace only the path prefix (repo root portion or other machine's home directory) with a repo-relative or `<home>/`-style placeholder; leave everything else in the line untouched. Verify with a diff review that every changed line's diff is a pure substring substitution, not a reflow.
**Warning signs:** A diff hunk that changes line length by more than the prefix-length delta, or touches a `.json` file's structure.

### Pitfall 2: Allowlist that isn't provably minimal

**What goes wrong:** The guard's allowlist accumulates entries "just in case," and HYG-02 explicitly requires the guard to **fail on an unused allowlist entry** — so a stale entry breaks the build the moment its match disappears (e.g., after the Playwright cache path changes).
**Why it happens:** Allowlists are additive by habit; nobody removes entries.
**How to avoid:** Track a "matched" flag per allowlist entry during the scan; after scanning all tracked files, assert every entry matched at least once. This mirrors the existing `@beam_independent_cache_paths` map pattern in `ci_workflow_parity_contract_test.exs`, which documents *why* each cache path is exempt (not just *that* it is).
**Warning signs:** An allowlist entry with no comment explaining what legitimate path it exists for.

### Pitfall 3: `@tag :tmp_dir` migration breaking a test that needs to be genuinely outside the repo

**What goes wrong:** `:tmp_dir` creates `<project>/tmp/<module>/<test-name>-<hash>/`, which is **inside** the git worktree. A test that shells into the temp dir and runs `git status` or `git init` before creating its own `.git` would now see the Threadline repo's own git state, because it is nested inside it.
**Why it happens:** The tag's semantics ("temp dir") sound identical to "outside the repo," but they are not — this is called out explicitly in this repo's own `PITFALLS.md` (Pitfall 13) and `STACK.md` §4.
**How to avoid:** Only migrate the 7 identified leaking files (none of which shell out to `git`/`mix` with the temp dir as CWD before their own init — verify this per file during planning). Explicitly leave `clean_checkout_contract_test.exs`, `planning_independence_contract_test.exs`'s outer isolation logic, and any `git worktree`-based test on `System.tmp_dir!()`.
**Warning signs:** A migrated test passes alone but fails inside `mix test` (`ci.all`) — a classic symptom of tree-walking code now seeing `tmp/`.

### Pitfall 4: Tree-walking tests seeing `tmp/` after migration

**What goes wrong:** Any test that walks the working tree (`planning_independence_contract_test.exs`, doc-contract tests that `File.ls!` the repo root, the new local-path guard itself if it ever falls back to a working-tree scan) will see the newly-created `tmp/<module>/...` directories once `@tag :tmp_dir` is added to any test.
**Why it happens:** `tmp/` is gitignored but not automatically excluded from a manual directory walk.
**How to avoid:** Confirm every tree-walking test either (a) already restricts itself to `git ls-files`/tracked content (like the new guard must), or (b) explicitly excludes `tmp/`. `git grep -I` naturally excludes it because `tmp/` is untracked — this is the strongest argument for implementing the guard via `git grep`, not `File.ls!`.
**Warning signs:** A previously-passing planning-independence or doc-contract test starts failing only after the tmp_dir migration lands, listing an unexpected `tmp/...` path.

### Pitfall 5: HYG-04 treated as new work instead of a verification pass

**What goes wrong:** A plan re-derives xref cycle counts and rewrites `MILESTONE-GUIDE.txt` §9a and `PROJECT.md`'s xref paragraph from scratch, duplicating work Phase 214 already did and risking introducing a divergent wording.
**Why it happens:** The phase's own success criteria read as if this were greenfield ("names the label correctly," "logged as a v1.45 architecture observation") without noting it may already be done.
**How to avoid:** Read `.planning/MILESTONE-GUIDE.txt` §9a and `.planning/PROJECT.md`'s "## Current Milestone" xref bullet (line ~32, ~41) **before** planning any edit. As of this session both already state: `verify.xref_cycles` is `--label compile-connected`, is clean, and is the only gate; the 5 unlabelled runtime cycles are enumerated with an explicit note that `Capture.AuditTransaction`↔`Semantics.AuditAction` "is logged for the v1.45 API/architecture review." This was committed 2026-09-26 in `ed4cd161` (`docs(v1.43): correct baseline — mint advisory, xref cycle labels`). The remaining Phase 217 work is: (a) confirm this is still true by re-running `mix xref graph --format cycles` with and without `--label compile-connected` and diffing against the recorded counts, (b) confirm `verify.xref_cycles`'s alias definition (`mix.exs`, `"xref graph --format cycles --label compile-connected --fail-above 0"`) is byte-unchanged, (c) confirm no new xref alias or CI step was added, and (d) consider whether the v1.45 rung bullet list in MILESTONE-GUIDE §7 should gain an explicit line item for the AuditTransaction/AuditAction review (today it is only in the §9a parenthetical) — a small traceability improvement, not a requirement gap.
**Warning signs:** A diff to `MILESTONE-GUIDE.txt` or `PROJECT.md` in this phase that doesn't match the language already committed in `ed4cd161`.

## Code Examples

### Verified `git grep` scope for the scrub (run this session, exact output)

```bash
# Files with the real, machine-local home path (must be scrubbed):
git grep -l -I '/Users/<user>' -- .
# => 296 files, ALL under .planning/ (0 outside .planning/)

# Files with a different machine's home-relative path (must be scrubbed,
# explicitly named by HYG-01's "covers prompts/prior-art/" clause):
git grep -l -I -E '<home>/(projects|Documents|Desktop)' -- prompts/prior-art/
# => prompts/prior-art/SOURCE-CANONICAL.md   (1 hit: "<home>/projects/scrypath/prompts/")
# => prompts/prior-art/accrue-planning-notes.md (5 hits: "<home>/projects/accrue/...")

# Legitimate runner/cache paths found — MUST be allowlisted, not scrubbed:
git grep -n -I -E '<home>/\.cache' -- .github/workflows/*.yml test/threadline/ci_workflow_parity_contract_test.exs
# .github/workflows/browser-full.yml:87:  path: ~/.cache/ms-playwright
# .github/workflows/ci.yml:484,640:      path: ~/.cache/ms-playwright
# test/threadline/ci_workflow_parity_contract_test.exs:414,585,765,774 (the path appears
#   as fixture/allowlist text inside the existing toolchain-pin contract test — not PII)

# Distinct prefix census (git grep -o, this session):
#   503  /Users/<user>/projects       (real, must scrub)
#   371  /Users/<user>/.codex         (real, must scrub)
#   340  /home/runner/work         (legitimate — CI log excerpts under .planning/audits/)
#   213  <home>/.claude                 (real, must scrub — agent-tooling paths in planning docs)
#   100  /Users/<user>/.claude        (real, must scrub)
#    22  ~/.cache                  (mixed — ms-playwright legit; some in .planning/ audit logs, still just receipts)
#     8  <home>/projects                (real — includes the 2 prompts/prior-art hits, others in .planning/)
#     8  /home/runner/.cache       (legitimate)
#     6  /home/runner/.mix         (legitimate)
#     4  /Users/<user>/.config        (real, must scrub)
#     3  ~/.hex                    (legitimate — Hex cache path mentioned in research docs)
#     3  /var/folders/...          (real macOS temp path from a historical walkthrough log, must scrub)
#     2  /private/tmp              (real, must scrub)
#     1  /Users/<user>/.credo.exs     (real, must scrub)
#     1  /home/<user>/coverage   (FALSE POSITIVE — regex artifact of "shell/home/timeline/coverage" prose;
#                                    not an actual path. A precise guard regex must not fire on this. See Pitfall
#                                    note: match on a preceding path-boundary character, e.g. start-of-line,
#                                    whitespace, or a shell-quote/backtick — not merely "/home/" mid-word.)
```

**Total confirmed scrub scope: 298 tracked files** (296 with `/Users/<user>/`, 2 with `<home>/projects/...` in `prompts/prior-art/`; some files may appear in both counts — verify exact union with a single combined `git grep -l -I -E` pattern during planning, not by adding the two counts). This is consistent with `STACK.md`'s own count of "298 files... all under `.planning/`" from one day earlier — the +2/+1 delta between this session's 296 and yesterday's 295 is the phase-216 evidence docs added since (`216-EVIDENCE.md`, `216-RESEARCH.md`), confirming the count is a moving target that must be re-derived by the scrub script itself at execution time, not hard-coded from this document.

### The 7 leaking test files (HYG-03), confirmed by name

Found by cross-referencing all 40 files using `System.tmp_dir` against which ones call `on_exit/1` (0 occurrences = leaking on assertion failure):

```
test/threadline/branch_protection_comparison_contract_test.exs   # on_exit: 0, inline File.rm_rf! for a DIFFERENT path (fake_bin), not for the `path` json fixture created at line 51 — that one is never removed at all
test/threadline/getting_started_fixtures_test.exs                # on_exit: 0, rm_rf: 0 — no cleanup whatsoever
test/threadline/planning_independence_contract_test.exs          # on_exit: 0, inline File.rm_rf! at end of test body — skipped if an earlier assertion raises
test/threadline/ci_attestation_contract_test.exs                 # on_exit: 0, inline File.rm_rf!(root) at end of test body — same risk
test/threadline/e2e_preflight_contract_test.exs                  # on_exit: 0, inline File.rm_rf!(fixture_dir) at end of test body — same risk
test/threadline/operator_surface/refute_partition_test.exs       # on_exit: 0, inline File.rm_rf!(tmp_dir) at end of test body — same risk
test/threadline/operator_surface/exports_mix_parity_test.exs     # on_exit: 0, rm_rf: 0 — setup block hands back the bare System.tmp_dir!() itself (async: false)
```

Verified command (this session):
```bash
for f in $(grep -rl 'System.tmp_dir' test/); do
  echo "$f | on_exit=$(grep -c 'on_exit' "$f") rm_rf=$(grep -c 'File.rm_rf\|rm_rf!' "$f")"
done
# 40 files total match System.tmp_dir; exactly 7 have on_exit=0
```

The remaining 33 files already call `on_exit(fn -> File.rm_rf!(...) end)` and should be left untouched — migrating them too would be unnecessary churn per Pitfall 13 ("Migrate only tests the flake lane or CI history names as flaky, or that collide under `async: true`").

### Async-collision candidate to review during planning

`test/threadline/operator_surface/critic_trust_test.exs` is named in STATE.md's deferred-items ledger ("Phase 202 (v1.41 archive) deferred-items: flake mechanism CORRECTION (critic_trust_test unique_integer scratch-dir reuse)") as a known scratch-dir reuse issue under async execution. It already has 3 `on_exit` and 3 `rm_rf` calls (not one of the 7 leaking files), but the planner should re-read that deferred-items entry and decide whether its scratch-dir naming needs a `@tag :tmp_dir` fix as the "any async-colliding tests" clause of HYG-03, or whether it was already resolved and the ledger entry is stale — `git log` the file's history before deciding.

### Roster addition template (copy exactly, substituting names)

```yaml
# .github/workflows/ci.yml — new job, same shape as verify-deps-audit (ci.yml:933-960)
verify-repo-hygiene:
  name: <name TBD by planner — must say what it proves, e.g. "No machine-local paths (repo hygiene)">
  runs-on: ubuntu-24.04
  timeout-minutes: <measure locally first; git grep over ~2700 tracked files runs in well under 1s per STACK.md's own measurement of "about 0.15 s across the whole repo">
  steps:
    - uses: actions/checkout@v5
    - name: Guard against machine-local paths
      run: mix verify.no_local_paths   # alias name illustrative; planner's call
    - name: Prove the guard goes red
      run: bin/check-local-paths --self-test   # or an ExUnit contract test, per HYG-02's "negative test" wording — either satisfies it; STACK.md recommends the bin/ shape for parity with verify-deps-audit, but the requirement text doesn't mandate a specific mechanism, so ExUnit-only is also compliant as long as fixtures are runtime-built
```
Add `verify-repo-hygiene` as the final entry of `ci-required`'s `needs:` list (`.github/workflows/ci.yml`, immediately after `verify-deps-audit`), and as the final bullet of CONTRIBUTING.md's `### \`ci-required\` needs: roster` list (`CONTRIBUTING.md:484`), in the same commit.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Hand-rolled `System.tmp_dir!() <> unique_integer()` in every test | ExUnit `@tag :tmp_dir` (available since 1.11) | Long-standing; this repo simply hadn't adopted it broadly (only 1 of 41 files uses it before this phase) | Async-safe by construction, no manual uniqueness math, automatic pre-test cleanup |
| No local-path guard | `git grep`-based CI gate | New in this phase | Closes the recurrence risk PITFALLS.md names explicitly: "Agent tooling requires absolute paths... a scrub without a local gate regresses within one phase." |

**Deprecated/outdated:** None specific to this phase — no library versions are involved.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The guard script's exact filename (`bin/check-local-paths`) and alias name (`verify.no_local_paths`) are illustrative, carried from `STACK.md`'s inference, not independently re-derived as a requirement | Code Examples, Architecture Patterns | Low — these are naming choices the planner/executor can finalize; no behavior depends on the exact string, only that the roster/CONTRIBUTING/topology-test edits stay in sync with whatever name is chosen |
| A2 | The negative-test mechanism can be either a `--self-test` bash-script flag (deps-audit shape) or a pure ExUnit contract test with runtime-built fixtures — HYG-02's text ("a negative test with runtime-built fixtures proves it goes red") does not mandate the bash `--self-test` shape specifically | Code Examples | Low — either satisfies the letter of the requirement; picking the ExUnit-only route saves one bash-script layer but loses the "no network test excluded from default `mix test`" property that made `--self-test` necessary for deps-audit (this guard needs no network, so that property doesn't apply here) |
| A3 | No file outside `.planning/` and `prompts/prior-art/` needs scrubbing, based on this session's exhaustive `git grep -l -I` run over the full pattern set | Scrub scope | Medium if wrong — re-run the exact same `git grep` command immediately before the scrub commit lands (the repo changes daily), since a new phase-217 planning artifact itself will introduce fresh `/Users/<user>/` hits the moment this RESEARCH.md or its PLAN.md files are written into `.planning/` |
| A4 | HYG-04 requires no new code or doc change beyond confirmation, based on reading the already-committed `ed4cd161` diff to MILESTONE-GUIDE.txt and PROJECT.md | Pitfall 5, Phase Requirements | Medium — if the maintainer wants the v1.45 rung bullet list (§7) to also gain an explicit line, that is additional (small) scope the planner should make an explicit task rather than silently add or silently skip |

## Open Questions (RESOLVED)

1. **Exact guard script/alias naming.**
   - What we know: `STACK.md` suggests `bin/check-local-paths` / `mix verify.no_local_paths`.
   - What's unclear: whether the planner prefers a name matching this repo's existing `verify-deps-audit` / `verify.deps_audit` convention more closely, e.g. `bin/check-repo-hygiene` / `mix verify.repo_hygiene` (matching the phase and job name `verify-repo-hygiene` exactly).
   - Recommendation: name the alias to match the CI job id (`verify-repo-hygiene` -> `mix verify.repo_hygiene` -> `bin/check-repo-hygiene`), for the same self-evident-naming reason DX-01 (a later phase) cares about job names.

2. **Whether `critic_trust_test.exs`'s scratch-dir reuse (STATE.md deferred item) is still live or already fixed.**
   - What we know: STATE.md's deferred-items ledger names it from the v1.41 archive close, without a resolution date visible in this file.
   - What's unclear: whether a later phase (198-207, or 216) already fixed it as a side effect.
   - Recommendation: `git log -p --follow test/threadline/operator_surface/critic_trust_test.exs` for the scratch-dir handling before deciding whether it's in scope for HYG-03's "any async-colliding tests" clause.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| `git` (with `grep`, `ls-files`, `status --porcelain`) | Scrub + guard | Yes | Runner-provided; local repo already relies on it extensively | None needed |
| Elixir/OTP (`.tool-versions`) | tmp_dir migration, contract tests | Yes | `erlang 27.3.4.15` / `elixir 1.17.3-otp-27` [VERIFIED: `.tool-versions`, read this session] | None needed |
| No network access | Guard's negative test (unlike `verify-deps-audit`, which needs hex.pm) | N/A | N/A | The guard's fixtures are pure filesystem/text, so this phase's negative test can run fully offline, unlike the deps-audit self-test |

No missing dependencies. Skip is not applicable — nothing here is optional.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir 1.17.3) |
| Config file | `test/test_helper.exs` — `ExUnit.configure(exclude: exclude)`, currently excludes only `pgbouncer_topology` by default (`live_dialyzer` is untagged/unexcluded per this milestone's own `PITFALLS.md` finding, out of scope for this phase, owned by Phase 218) |
| Quick run command | `mix test test/threadline/local_paths_guard_test.exs` (or whatever the new guard's test file is named) plus `mix test <the 7 migrated files>` |
| Full suite command | `mix ci.all` (runs `verify.format`, `verify.credo`, `verify.deps_audit`, `verify.xref_cycles`, `verify.compile_no_optional`, `verify.test`, `verify.threadline`, `verify.example`, per `mix.exs:196-208`, read this session) |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| HYG-01 | No tracked file contains a machine-local path | contract/negative | `git grep -I -E '<pattern>' -- .` exits non-zero *before* the scrub, zero *after* | ✅ (the check IS the guard from HYG-02, reused as the scrub's own acceptance test) |
| HYG-02 | Guard scans tracked text only, allowlists runner paths, fails on unused allowlist entry, runtime-built negative fixture | unit/contract | `mix test test/threadline/<new guard test file>.exs` | ❌ — Wave 0: new test file needed |
| HYG-03 | 7 files use `@tag :tmp_dir`; no new temp-dir entries after full suite | integration + manual verification step | `mix test` then `diff <(ls /tmp before) <(ls /tmp after)` — or, more robustly, snapshot `System.tmp_dir!()` contents before/after `mix ci.all` in a wrapper script | ❌ — Wave 0: a "no leaked temp entries" assertion script needs writing (this is the one part of the phase without an obvious existing pattern to copy — plan it as its own small task) |
| HYG-04 | `verify.xref_cycles` unchanged, no runtime-cycle gate, guide/PROJECT.md disposition correct | verification/diff | `git diff ed4cd161..HEAD -- .planning/MILESTONE-GUIDE.txt .planning/PROJECT.md mix.exs` shows no unintended change; `mix xref graph --format cycles --label compile-connected` and unlabelled, diffed against the committed counts (0 and 5) | ✅ (the commands exist; this is a verification task, no new test file) |

### Sampling Rate

- **Per task commit:** `mix test <changed file>` for tmp_dir migrations; `mix test test/threadline/<new guard test>.exs` for the guard; `git grep -I ...` directly for scrub-commit verification.
- **Per wave merge:** `mix ci.all`.
- **Phase gate:** `mix ci.all` green, plus the HYG-03 "no new temp-dir entries" check, before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] A new guard contract test file (name TBD) — covers HYG-02.
- [ ] A "no leaked temp-dir entries after full `mix test`" verification script/task — covers HYG-03's fourth clause; no existing script in `bin/` does this today (`bin/safe-temp-tree` exists but serves a different purpose — read it during planning to confirm it isn't already the tool for this).
- [ ] No framework install needed — ExUnit and `git` are already present.

## Security Domain

`security_enforcement` is not disabled in `.planning/config.json` per this session's read of the file (only `workflow.nyquist_validation`-style keys were inspected; absence of an explicit `security_enforcement: false` means treat as enabled per the template's own instruction). This phase is CI-tooling and documentation, not application code, so most ASVS categories are not applicable — but the guard is a security control (PII/secrets-adjacent hygiene) and gets its own row.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | N/A — no auth code touched |
| V3 Session Management | No | N/A |
| V4 Access Control | No | N/A |
| V5 Input Validation | Partial | The guard's own regex must be validated against the false-positive shapes found this session (`home/timeline` mid-word match) — treat this as an input-validation concern for the guard's pattern set, not the product |
| V6 Cryptography | No | N/A |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| PII/machine-local path disclosure in a public repo | Information Disclosure | The scrub + guard combination this phase builds; `git grep -I` tracked-only scope so the guard cannot itself leak by reading untracked local files into an error message |
| Guard test fixture containing a real-looking home path | Information Disclosure (self-inflicted) | Build all fixtures at runtime via string concatenation, per Pattern 2 above; never a literal in committed test source |
| `_build`/cache poisoning into a release artifact | Tampering | Not touched by this phase — `release.yml`'s publish path is already cache-free per `PITFALLS.md`; the new `verify-repo-hygiene` job must not introduce a cache step, consistent with the Anti-Patterns section above |

## Sources

### Primary (HIGH confidence — verified this session, 2026-09-27)
- `git grep -l -I` / `-n -I` / `-o -I` over the full tracked tree — exact scrub file list, counts, and false-positive (`home/timeline`) confirmed
- `git ls-files .planning | wc -l` (2,672 tracked files under `.planning/`) and `.gitignore` (lines 45, 66-76) — confirms `.planning/` is tracked but has explicit untracked-scratch carve-outs
- `for f in $(grep -rl 'System.tmp_dir' test/); do ...; done` — the 40-file `System.tmp_dir` census and the 7-file `on_exit`-absent subset
- `.tool-versions` (read directly) — `erlang 27.3.4.15` / `elixir 1.17.3-otp-27` / `nodejs 22.14.0`
- `bin/verify-deps-audit` (full header comment read), `.github/workflows/ci.yml:933-995`, `CONTRIBUTING.md:470-580`, `test/threadline/ci_topology_contract_test.exs:343-674`, `test/threadline/ci_workflow_parity_contract_test.exs:400-780`, `mix.exs:170-208` — the roster/alias/job template
- `git log --oneline -- .planning/MILESTONE-GUIDE.txt` and `git log -p -1 --follow` — confirms commit `ed4cd161` already corrected the §9a xref text; `.planning/PROJECT.md` lines 32/41 read directly confirm current wording
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md` (lines 1-303), `.planning/ROADMAP.md`, `.planning/MILESTONE-GUIDE.txt` — full reads this session

### Secondary (MEDIUM confidence)
- `.planning/research/STACK.md`, `.planning/research/FEATURES.md`, `.planning/research/PITFALLS.md` (all dated 2026-09-26, one day before this session) — comprehensive milestone-level research; every number in them was independently re-verified this session and found either identical (within the expected daily drift of +1-3 files) or already actioned (the MILESTONE-GUIDE.txt correction)

### Tertiary (LOW confidence)
- None used — every claim in this document traces to a command run or a file read in this session, or to the dated milestone-level research files which are themselves primary-sourced.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new tools, everything is an existing repo pattern
- Architecture: HIGH — the guard/roster shape is copied from working code (`bin/verify-deps-audit`), not designed from scratch
- Pitfalls: HIGH — sourced from this repo's own dated `PITFALLS.md` plus this session's independent re-verification of every cited fact
- HYG-03 file list: HIGH — derived by direct grep census this session, cross-checked against the milestone research's "7 lack `on_exit` cleanup" count (X8) and found to match exactly
- HYG-04 disposition: HIGH — confirmed via `git log` that the correcting commit already landed

**Research date:** 2026-09-27
**Valid until:** ~7 days (the tracked-file scrub count is a moving target — re-run the `git grep -l -I` command immediately before the scrub commit, not from this document's cached numbers)
