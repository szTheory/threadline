---
phase: 217-repo-hygiene
plan: 01
subsystem: ci
tags: [bash, git-grep, perl, ci-guard, repo-hygiene, allowlist]

requires:
  - phase: 215-supply-chain-gate
    provides: "bin/verify-deps-audit's bin-script + --self-test + gitignored-tmp/ pattern, copied for this guard"
provides:
  - "bin/verify-repo-hygiene: a tracked-text-only machine-local-path guard (7 pattern families) with a scoped, reason-carrying allowlist"
  - ".github/repo-hygiene-allowlist.tsv: seeded allowlist covering the real tree's runner/cache/GSD-tool-install paths only"
  - "test/threadline/repo_hygiene_guard_test.exs: 37-test offline behavior matrix plus real-allowlist shape tests"
  - "A pre-scrub census confirming the guard's report is confined to .planning/ and two prompts/prior-art/ files"
affects: [217-04-forward-scrub, 217-05-wire-guard-into-ci]

actuals:
  tokens: 10362
  tasks: 3
  commits: 3
  plan_head_before: 93ebd32484d92ca4598cb4b15a7e7ee3ddbc4d03
  plan_head_after: 706b3835e081a5d5f2808ec7638064f53bffa87c

tech-stack:
  added: []
  patterns:
    - "bin/ guard script + --self-test runtime-fixture pattern, copied from bin/verify-deps-audit"
    - "Self-referential-safety: every fixture/pattern literal is assembled at runtime by string concatenation, so the guard's own source and tests never contain a literal it exists to catch"
    - "git grep -I tracked-only scan (never deps/_build/tmp/untracked scratch)"

key-files:
  created:
    - bin/verify-repo-hygiene
    - test/threadline/repo_hygiene_guard_test.exs
  modified:
    - .github/repo-hygiene-allowlist.tsv

key-decisions:
  - "Seeded 3 tilde-dot-claude tool-install allowlist entries (gsd-core/, get-shit-done/, skills/) scoped to .planning/ — these are home-relative but not machine-local (identical on every machine, no username); other tilde-dot-claude forms stay unallowlisted for plan 217-04 to scrub."
  - "Coarse git-grep pre-filter (alternation of trigger words) + precise perl per-line extraction with lookbehind boundaries, rather than one large ERE, to keep family-specific adjacency/boundary rules correct and testable in isolation."
  - "Structural allowlist errors (malformed line, duplicate, invalid scope, short reason) exit 2 before any tree scan runs; a comment/reason containing a pattern hit exits 1 as an ordinary finding — matching the plan's documented exit-code split."

requirements-completed: [HYG-02]

coverage:
  - id: D1
    description: "bin/verify-repo-hygiene detects all 7 machine-local-path pattern families in tracked text only, with correct boundary/adjacency rules"
    requirement: "HYG-02"
    verification:
      - kind: unit
        ref: "test/threadline/repo_hygiene_guard_test.exs (33 fixture-driven tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Scoped allowlist with used/unused/inert tracking and structural validation fails closed on a stale or malformed entry"
    requirement: "HYG-02"
    verification:
      - kind: unit
        ref: "test/threadline/repo_hygiene_guard_test.exs (allowlist coverage + validation tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "--self-test proves the guard goes red/green end-to-end and the real seeded allowlist covers only runner/cache/tool-install paths"
    requirement: "HYG-02"
    verification:
      - kind: integration
        ref: "bin/verify-repo-hygiene --self-test"
        status: pass
      - kind: unit
        ref: "test/threadline/repo_hygiene_guard_test.exs (real-allowlist shape tests, 4 tests)"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-09-27
status: complete
---

# Phase 217 Plan 1: Tracked-Text Local-Path Guard Summary

**A standalone `bin/verify-repo-hygiene` guard (7 pattern families, scoped allowlist, `--self-test`) proves red on the real tree confined to `.planning/` and two known files — ready for plan 217-04's scrub and plan 217-05's CI wiring.**

## Performance

- **Duration:** ~40 min
- **Tasks:** 3
- **Files:** 2 created, 1 modified

## Accomplishments

- `bin/verify-repo-hygiene`: a bash 3.2-compatible, git-grep-based guard detecting 7 machine-local-path pattern families (macOS home, Linux home, Windows home, home-relative tilde, macOS per-user temp root, Claude-encoded project dir, JSON-escaped home) in tracked, non-binary text only.
- Scoped allowlist semantics: `<scope>\t<literal>\t<reason>` entries with directory/file/repo-wide scope matching, prefix+adjacency token coverage, per-entry used/unused/inert tracking, and structural validation (malformed line, duplicate, invalid scope, short reason all exit 2 before any scan).
- `--self-test` mode: 5 runtime-built fixture cases (clean, three-family red, covered hit, unused entry, untracked-file exclusion), cleaned via an `EXIT` trap under the repo's gitignored `tmp/`.
- `.github/repo-hygiene-allowlist.tsv` seeded with exactly the runner/cache/GSD-tool-install paths the real tree needs — every entry proven used, none allowlisting a person's home directory.
- A pre-scrub census: the guard's report against the real tree is red on 317 tracked files, all under `.planning/` except the two known `prompts/prior-art/` files, with zero `UNUSED allowlist entry` lines — exactly the expected pre-scrub state for plan 217-04.

## Task Commits

1. **Task 1: Tracer — macOS-home family goes red end-to-end** - `14795e10` (feat)
2. **Task 2: All pattern families and scoped allowlist semantics** - `2d8e0f6d` (feat)
3. **Task 3: `--self-test`, seeded real allowlist, pre-scrub census** - `706b3835` (ci)

_All three tasks were `type="auto"`/`type="tracer"` with no checkpoints; no separate plan-metadata commit is needed beyond this SUMMARY commit._

## Files Created/Modified

- `bin/verify-repo-hygiene` - the guard script: scan mode and `--self-test`, exit codes 0/1/2, env seams `REPO_HYGIENE_ROOT`/`REPO_HYGIENE_ALLOWLIST` (test-only)
- `test/threadline/repo_hygiene_guard_test.exs` - 37 ExUnit tests: fixture-driven behavior matrix (33) plus real-allowlist shape and self-test integration tests (4)
- `.github/repo-hygiene-allowlist.tsv` - scoped allowlist, 8 entries covering Playwright cache, the toolchain-pin contract test's cache fixtures, the runner account, Hex/general caches, and 3 GSD tool-install paths

## Decisions Made

- The 3 `~/.claude/gsd-core/`, `~/.claude/get-shit-done/`, `~/.claude/skills/` allowlist entries are a deliberate, reversible interpretation: these are home-relative but not machine-local (identical across machines, no username segment), and plan templates' `execution_context` includes require them. Other `<home>/.claude/...` forms (`plans/`, `projects/`, bare) are intentionally left unallowlisted for plan 217-04 to scrub.
- Chose a two-stage detection design (coarse `git grep` alternation pre-filter, then precise per-family perl regex with lookbehind boundary checks) over one large combined ERE, so each family's adjacency/boundary rule stays independently correct and testable.
- Structural allowlist validation (exit 2) runs completely before the tree scan; a pattern hit found only in an allowlist comment or reason (exit 1) is treated as an ordinary finding, matching the plan's exit-code contract exactly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `perl -ne` double-consumed stdin against an explicit inner `while (<STDIN>)` loop**
- **Found during:** Task 2 (writing the combined-family matcher)
- **Issue:** The reusable `MATCHER_PROGRAM` used `perl -ne` (which already wraps the script in an implicit `while (<>)` loop) together with its own explicit `while (my $l = <STDIN>)`, so the implicit loop consumed the single line of input before the explicit loop's body ever ran — the matcher silently produced zero hits for every candidate line.
- **Fix:** Invoke the matcher with plain `perl -e` (no `-n`) at both call sites, since the program supplies its own read loop.
- **Files modified:** bin/verify-repo-hygiene
- **Verification:** All 33 fixture tests pass; manual runs against a debug fixture confirm hits are reported.
- **Committed in:** 2d8e0f6d (Task 2 commit)

**2. [Rule 1 - Bug] Glob-character scope check used a broken bracket-expression regex**
- **Found during:** Task 2 (allowlist structural validation)
- **Issue:** `grep -q '[*?\[\]]'` does not reliably match `*`, `?`, `[`, `]` as a bracket expression (backslash has no special meaning inside `[...]` in POSIX BRE), so a scope containing `*` was silently accepted instead of failing as malformed.
- **Fix:** Replaced with a bash `case` glob pattern (`*['*?[]']*`) that correctly matches any of the four characters.
- **Files modified:** bin/verify-repo-hygiene
- **Verification:** The "a scope with a glob character exits 2" test passes.
- **Committed in:** 2d8e0f6d (Task 2 commit)

**3. [Rule 1 - Bug] The guard's own `--self-test` fixture literal `"<home>/self-test-cache"` and a test's `"~/.cache"` literal were self-matching hits**
- **Found during:** Task 3 (running the guard against the real tree for the pre-scrub census)
- **Issue:** Both literals are contiguous `<home>/` + name-char text written directly in committed source, so the guard's own family-4 (home-relative) pattern matched them, appearing as HIT lines in `bin/verify-repo-hygiene` and `test/threadline/repo_hygiene_guard_test.exs` themselves — violating this plan's own "no literal home path in any committed file" requirement.
- **Fix:** Rewrote both literals to break byte-contiguity via string concatenation (`"~""/""self-test-cache"` in bash; `"~" <> "/" <> ".cache"` in Elixir), which changes nothing at runtime but removes the contiguous pattern from the source bytes.
- **Files modified:** bin/verify-repo-hygiene, test/threadline/repo_hygiene_guard_test.exs
- **Verification:** Re-ran the guard against the real tree; `bin/verify-repo-hygiene` and the test file no longer appear in the HIT list.
- **Committed in:** 706b3835 (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (3 bugs, all Rule 1)
**Impact on plan:** All three fixes were required for the guard to function correctly and for this plan's own files to pass its own "no literal home path" requirement. No scope creep.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `bin/verify-repo-hygiene` is committed, tested, and self-proving. Plan 217-04 can use its own real-tree report (317 files, all `.planning/` plus the two `prompts/prior-art/` files) as the exact scrub list.
- Plan 217-05 wires the guard into `mix.exs`, `ci.yml`, and CONTRIBUTING — not touched by this plan, per the plan's stated boundary.
- No blockers.

---
*Phase: 217-repo-hygiene*
*Completed: 2026-09-27*

## Self-Check: PASSED

- `bin/verify-repo-hygiene`, `test/threadline/repo_hygiene_guard_test.exs`, `.github/repo-hygiene-allowlist.tsv` all found on disk.
- Commits `14795e10`, `2d8e0f6d`, `706b3835` all found in `git log --oneline --all`.
- `mix test test/threadline/repo_hygiene_guard_test.exs` — 37 tests, 0 failures.
- `bin/verify-repo-hygiene --self-test` — `self-test: ok (5 cases)`.
- `mix verify.format` and `mix verify.credo` — both exit 0.
- `commits: 3` measured via `git rev-list --count 93ebd324..706b3835` (ledger-based, matches `actuals.commits`).
