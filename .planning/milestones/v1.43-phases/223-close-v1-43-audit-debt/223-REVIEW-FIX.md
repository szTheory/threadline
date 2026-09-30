---
phase: 223-close-v1-43-audit-debt
fixed_at: 2026-09-29T22:30:00Z
review_path: .planning/phases/223-close-v1-43-audit-debt/223-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 223: Code Review Fix Report

**Fixed at:** 2026-09-29T22:30:00Z
**Source review:** .planning/phases/223-close-v1-43-audit-debt/223-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (WR-01..WR-05; IN-01 is Info, out of `critical_warning` scope)
- Fixed: 5
- Skipped: 0

Verification was run inside an isolated git worktree
(`.claude/worktrees/rf-223-*`, branch `gsd-reviewfix/223-*`) created for
this fixer run, with `deps/` and `_build/` symlinked in from the main
checkout so `mix compile`/`mix test` could run without a full
recompile. All commits below were made on that branch and then
fast-forward-merged onto `milestone/v1.43`; the worktree and temp
branch were removed after merge. The numbers below (mix test / bin/
verify-repo-hygiene runs) are reproducible identically from the main
checkout on `milestone/v1.43` post-merge, since the worktree only ever
symlinked build artifacts, never diverged source.

## Fixed Issues

### WR-01: Vacuous mutation control — "positive control: flagging an allowlisted job's checkout stays green"

**Files modified:** `test/threadline/release_control_plane_contract_test.exs`
**Commit:** `b59bb704`
**Applied fix:** Rewrote the test. Instead of adding a `with:` key that none
of `checkout_credential_errors/1`, `allowlisted_job_run_errors/1`, or
`stale_allowlist_errors/1` inspect, the mutation now renames
`dispatch-bootstrap`'s job header (leaving its bare, flag-less checkout
step untouched). This removes the job from `@persisted_checkout_jobs`
while keeping the same checkout content, so `checkout-credential-free`
must now fire — proving the exclusion is genuinely keyed on job id and
is reachable by construction (not vacuously green).
**Verified:** `mix test test/threadline/release_control_plane_contract_test.exs` — 16 tests, 0 failures.

### WR-02: `mix_command_position?/1` has gaps that would silently defeat the D-09 security check

**Files modified:** `test/threadline/release_control_plane_contract_test.exs`
**Commit:** `ac8b021b`
**Applied fix:** Chose the "broaden the recognized-prefix set" option (cheap,
correct, and keeps the fail-open design intentional rather than
inverting the whole matcher). Added `sudo`/`nohup`/`nice` to the keyword
list, a `timeout <N>` prefix pattern, an `xargs` prefix pattern, and `)`
to the separator list (for `case` branches like `x) mix compile ;;`).
Pinned each new form (`timeout 300 mix hex.publish`, `sudo mix compile`,
`nohup mix test &`, `nice mix test`, `xargs -I{} mix build`,
`x) mix compile ;;`) as a positive case in the existing
`mix_invocation?/1` test.
**Verified:** `mix test test/threadline/release_control_plane_contract_test.exs` — 16 tests, 0 failures.

### WR-03: `allowlisted-job-runs-no-mix` cannot see into externally-invoked scripts

**Files modified:** `.github/workflows/release.yml`,
`bin/post-publish-distribution-sync`,
`test/threadline/release_control_plane_contract_test.exs`
**Commit:** `6b26b330`
**Applied fix:** Chose the "real check, cheap and correct" branch rather than
the documentation-only fallback, since a narrow check was achievable
without false-positiving on the real script. Added
`allowlisted_job_external_script_errors/2` (folded into
`persisted_checkout_errors/1`) which extracts every `./bin/...` path an
allowlisted job's `run:` text invokes, reads that script from disk, and
flags a subprocess-shaped `mix` invocation — a quote character
immediately followed by `mix` and a word boundary (`(["']mix(?=\s|\1)`).
This is deliberately narrower than `mix_invocation?/1` (which was
tuned for shell `run:` text): applying that matcher directly to the
real script's source produces a **false positive**, confirmed by hand,
because the script's generated markdown documentation contains the
backtick-quoted prose `` `mix hex.info threadline` `` — its backtick
delimiter (not a quote character) does not match the narrower pattern.
Also added matching D-07/WR-03 invariant comments at both ends (the
`release.yml` step and the top of the script) per the review's
alternative suggestion, combining both options rather than choosing
just one. Added a pin test (current script is clean + carries the
comment) and a positive control (an injected `mix_cmd="mix"` line is
caught via an in-memory content override, no disk mutation needed).
**Verified:** `mix test test/threadline/release_control_plane_contract_test.exs` — 18 tests, 0 failures. Also re-ran `ci_topology_contract_test.exs`, `ci_workflow_parity_contract_test.exs`, `ci_token_permissions_contract_test.exs`, `release_ci_gate_contract_test.exs`, `release_artifact_contract_test.exs`, `ci_action_runtime_contract_test.exs` (126 tests, 0 failures) since they also parse `release.yml`, to catch any incidental format/step-shape regression from the comment additions.

### WR-04: `literal_too_broad`'s guard-test coverage misses 3 of its 9 documented roots

**Files modified:** `test/threadline/repo_hygiene_guard_test.exs`
**Commit:** `6bada9ca`
**Applied fix:** Added the three missing `@too_broad_literals` cases —
JSON-escaped home root (`\/home\/`), dash-home root (`-home-`, the
exact root family-8 of this phase added), and
`/private/var/folders` (no trailing slash) — using the same
concatenation-built-literal pattern (`"/" <> "home"`, etc.) already used
for the other six, so the guard's own repo-hygiene scan of its test
file never sees a raw matchable literal.
**Verified:** `mix test test/threadline/repo_hygiene_guard_test.exs test/threadline/repo_hygiene_contract_test.exs` — 83 tests, 0 failures. `bin/verify-repo-hygiene --self-test` — ok (10 cases).

### WR-05: `newline_status` capture ignores a `git ls-files` failure

**Files modified:** `bin/verify-repo-hygiene`
**Commit:** `5a9cc931`
**Applied fix:** `$?` after a two-stage pipeline only reflects the last
command (`perl`). Captured the full `PIPESTATUS` array in one
assignment (`newline_pipestatus=("${PIPESTATUS[@]}")`) — confirmed by
hand that a *second* separate assignment resets `PIPESTATUS` before it
can be read a second time, so both exit codes must be saved together in
a single statement — then read `git_ls_status`/`newline_status` from
that saved array and `die` distinctly on a nonzero `git` status vs. a
detected newline, matching the `PIPESTATUS`-based pattern the tree-scan
block below it already uses.
**Verified:** `bash -n bin/verify-repo-hygiene` (syntax), `bin/verify-repo-hygiene --self-test` — ok (10 cases), `bin/verify-repo-hygiene` (dogfooded against the live repo) — "4250 tracked text file(s) clean; 8 allowlist entries used, 0 inert", exit 0. `mix test test/threadline/repo_hygiene_guard_test.exs test/threadline/repo_hygiene_contract_test.exs` — 83 tests, 0 failures.

## Skipped Issues

None — all in-scope findings were fixed.

---

_Fixed: 2026-09-29T22:30:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
