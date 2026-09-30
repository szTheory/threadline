---
phase: 223-close-v1-43-audit-debt
reviewed: 2026-09-29T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/release.yml
  - CONTRIBUTING.md
  - bin/verify-repo-hygiene
  - test/threadline/release_control_plane_contract_test.exs
  - test/threadline/repo_hygiene_contract_test.exs
  - test/threadline/repo_hygiene_guard_test.exs
findings:
  critical: 0
  warning: 5
  info: 1
  total: 6
status: issues_found
---

# Phase 223: Code Review Report

**Reviewed:** 2026-09-29
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the phase 223 diff against `787da941..HEAD`: the `release.yml`
`persist-credentials: false` rollout plus its new per-step contract test
(`release_control_plane_contract_test.exs`), and the `bin/verify-repo-hygiene`
hardening (Linux-encoded family 8, family-6 left-anchor, `literal_too_broad`,
newline pre-scan, and their `--self-test`/ExUnit coverage).

The core logic checked out: I traced every regex family (6 and 8, including
the new left-anchor alternation and the drive-letter lookbehind) character by
character against the fixtures and against adversarial strings not in the
suite (mid-word forms, TitleCase kebab, drive-letter forms), and did not find
a false positive or false negative in the shipped patterns. I hand-verified
all nine `actions/checkout` steps in `release.yml` against the two-entry
`@persisted_checkout_jobs` allowlist and confirmed the flag is present on
every non-allowlisted checkout, and that both allowlisted jobs (`dispatch-bootstrap`,
`distribution-sync`) genuinely run no `mix` today — including the external
script `bin/post-publish-distribution-sync`, which the workflow-text-only
contract test cannot itself see into (a real blind spot, WR-03).

The findings below are about the safety net itself, not the behavior it
ships: one genuinely vacuous mutation control, a security-relevant detection
gap in the `mix` invocation matcher (real shell idioms it cannot see), an
undertested `literal_too_broad` allowlist (2/9 roots and a related case go
unexercised), and a same-shaped gap where the D-09 rule can't see mix calls
hiding in an externally-invoked script.

## Warnings

### WR-01: Vacuous mutation control — "positive control: flagging an allowlisted job's checkout stays green"

**File:** `test/threadline/release_control_plane_contract_test.exs:315-334`

**Issue:** This test mutates the `dispatch-bootstrap` job's checkout by
*adding* `persist-credentials: false` and asserts `persisted_checkout_errors(mutated) == []`.
But `checkout_credential_errors/1` (line ~426) explicitly filters out any
`job_id` that is a key of `@persisted_checkout_jobs` via
`not Map.has_key?(@persisted_checkout_jobs, &1)` — so `dispatch-bootstrap`'s
checkout step is *never inspected* by that rule, whether or not the flag is
present. `allowlisted_job_run_errors/1` only inspects `run:` scripts, and
`stale_allowlist_errors/1` only inspects job names — neither is touched by
adding a `with:` key. There is no mutation of this anchor block that could
ever make this assertion fail: the test cannot fail by construction, which is
exactly the "assertions that cannot fail" pattern the review is watching for.

**Fix:** Either delete this test (it adds no coverage beyond what the six
"mutation controls (D-11)" cases + `checkout_credential_errors` unit logic
already prove), or repurpose it to prove something it can actually catch —
e.g., assert that `checkout_credential_errors(mutated)` specifically excludes
`dispatch-bootstrap`'s checkout by checking a synthetic job *not* in the
allowlist behaves differently, using a job id that is NOT a
`@persisted_checkout_jobs` key as the mutation target instead.

### WR-02: `mix_command_position?/1` has gaps that would silently defeat the D-09 security check

**File:** `test/threadline/release_control_plane_contract_test.exs:553-575`

**Issue:** The D-09 invariant ("a job that keeps a persisted token must never
run mix") is enforced entirely through `mix_invocation?/1`, which only
recognizes `mix` as a command when the preceding (trimmed) text is empty, a
separator (`;`, `&&`, `||`, `|`, `$(`, `:`), an unescaped backtick, one of a
fixed keyword list (`if|then|elif|else|do|while|until|!|exec|time|env`), or an
`NAME=value` assignment prefix. Several common real-world shell idioms that
also put `mix` at a genuine command position are not recognized, so
`mix_invocation?/1` returns `false` for them — a false negative that would
let a future PR add exactly the kind of dependency-compiling code this rule
exists to prevent, without the contract test ever turning red:

- `timeout 300 mix hex.publish` — prefix `"timeout 300"` matches none of the
  recognized forms (`"timeout"` is not `"time"`).
- `sudo mix compile` — `"sudo"` is not a recognized keyword.
- `nohup mix test &` / `nice mix test` / `xargs -I{} mix build` — none of
  these command wrappers are recognized.
- `x) mix compile ;;` inside a `case` branch — `)` is not in the separator
  list.

Since this helper is the *only* thing standing between a future edit and a
silent CR-01/D-07 regression on the two credential-persisting jobs, its
coverage gaps are a real weakening of the safety net, not merely a style
nit — even though nothing in the current `release.yml` exploits it.

**Fix:** Either broaden the recognized-prefix set (add a denylist-style
fallback: treat *any* word immediately before `mix` as a potential wrapper
unless it's a known-safe token) or, more robustly, invert the check to scan
for the bare substring `mix` anywhere in a `run:` script for allowlisted jobs
and require an explicit, reviewed exemption comment for any legitimate
non-invocation false positive (fail closed instead of fail open, matching the
guard script's own philosophy elsewhere in this phase).

### WR-03: `allowlisted-job-runs-no-mix` cannot see into externally-invoked scripts

**File:** `test/threadline/release_control_plane_contract_test.exs:452-465`; `.github/workflows/release.yml:709-720` (`distribution-sync` → `./bin/post-publish-distribution-sync`)

**Issue:** `allowlisted_job_run_errors/1` only scans the literal `run:` text
inside `release.yml` for a `mix` invocation. `distribution-sync` (one of the
two persisted-credential jobs) calls `./bin/post-publish-distribution-sync`,
an external script. I verified this script is mix-free today (it shells out
to `python3` only), so there is no live vulnerability — but the contract test
provides zero protection against that script (or a future replacement) later
gaining a `mix` call. The D-07 guarantee ("this job compiles no dependency
code") is asserted by a test that structurally cannot observe the one thing
that would violate it if it lived one level of indirection away.

**Fix:** Either add a companion assertion that greps
`bin/post-publish-distribution-sync` (and any other script invoked from an
allowlisted job) for a `mix` invocation using the same `mix_invocation?/1`
matcher, or add a code comment at both ends (the job step and the top of the
script) making the invariant explicit so a future editor of the script sees
the constraint before adding a mix call.

### WR-04: `literal_too_broad`'s guard-test coverage misses 3 of its 9 documented roots

**File:** `test/threadline/repo_hygiene_guard_test.exs:483-495`; `bin/verify-repo-hygiene:348-367`

**Issue:** `literal_too_broad()` checks a candidate literal against nine
hard-coded family roots (macOS home, Linux home, both JSON-escaped forms,
both dash forms, `~/`, `/var/folders/`, `/private/var/folders/`). The
`@too_broad_literals` table in the guard test exercises only six of them:
`/`, `\`, `~`, `~/`, `/var/folders`, `/Users` (both forms), `/home` (both
forms), the JSON-escaped **Users** form, and the dash-**Users** form. It never
exercises:

- the JSON-escaped **home** root (`\/home\/`)
- the dash-**home** root (`-home-`) — notable because this is the exact new
  root D-16/family-8 of this same phase added
- `/private/var/folders/`

A future edit that accidentally dropped any of these three lines from the
`for root in ...` list in `literal_too_broad()` would pass every test in the
suite (self-test included — the self-test's own case (h) only exercises the
lone-`/` root) while silently reopening exactly the too-broad-allowlist-literal
hole D-13 was written to close, specifically for the family this phase
introduced.

**Fix:** Add the three missing cases to `@too_broad_literals` (JSON-escaped
home, dash-home, and `/private/var/folders/` without its trailing slash), the
same pattern already used for the other six.

### WR-05: `newline_status` capture ignores a `git ls-files` failure

**File:** `bin/verify-repo-hygiene:490-497`

**Issue:**
```sh
set +e
git -C "$root" ls-files -z | perl -0 -ne 'exit 1 if /\n/' >/dev/null 2>&1
newline_status=$?
set -e
```
`$?` after a pipeline reflects only the last command (`perl`), not `git`. If
`git ls-files -z` itself fails (e.g. a corrupted index, or the root becomes
unreadable mid-run), `perl` simply sees an empty or truncated stream, exits 0
(no newline found), and the guard proceeds as if the tree were clean of
newline-containing paths — silently skipping the very enumeration this
pre-scan exists to make exhaustive. This is a narrow failure mode (the
preceding `git rev-parse --is-inside-work-tree` check already rules out the
common "not a repo" case), but it is a real fail-open path in a check whose
entire design intent (per its own comment block) is to fail closed before any
scan runs.

**Fix:** Use `PIPESTATUS` (as the tree-scan block below it already does at
line ~504-507) to check the `git` exit code independently of `perl`'s, and
`die` on a nonzero `git` status distinctly from a detected newline.

## Info

### IN-01: D-18/D-06 CONTRIBUTING.md wording changes have no contract test

**File:** `CONTRIBUTING.md:142` (D-18 wording), `CONTRIBUTING.md:990-991` (D-06 sentence)

**Issue:** Neither the "no file or directory is exempt from the scan other
than the allowlist's own literal column" sentence (D-18) nor the new
"releasable squash subject / `BEGIN_COMMIT_OVERRIDE`" sentence (D-06) is
asserted by any test — unlike almost every other CONTRIBUTING.md claim this
phase and its predecessors touch, which are pinned by
`repo_hygiene_contract_test.exs` or similar doc-contract tests. Per the
223-CONTEXT.md decisions, neither was required to have a test (D-06 is
explicitly "no new CI guard," and D-18 is a pure wording fix), so this is not
a defect against the phase's own scope — flagging only because it's the one
place in this diff where a doc claim can silently drift without any test
noticing, unlike its neighbors.

**Fix:** None required by phase scope; optional follow-up would be a plain
`String.contains?` assertion if a future phase wants this wording pinned.

---

_Reviewed: 2026-09-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
