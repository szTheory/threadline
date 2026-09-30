# Phase 223: Close v1.43 Audit Debt - Research

**Researched:** 2026-09-29
**Domain:** GitHub Actions release-pipeline hardening (release-please override mechanics,
`actions/checkout` credential hygiene) + a bash/Perl repo-hygiene guard script + Elixir
ExUnit contract-test authoring, in a mature Elixir/Phoenix/Ecto OSS repo.
**Confidence:** HIGH

## Summary

This phase closes three already-scoped, already-decided tech-debt items from the v1.43
audit. CONTEXT.md (D-01..D-23) carries nearly all the design detail already — this research
verifies that design against the live files (it holds, with a few line-number and detail
corrections noted below) and fills the specific gaps requested: exact live anchors in
`release.yml`, the exact current shape of the three test files the plan will extend, the
exact current shape of `bin/verify-repo-hygiene` and its self-test, the exact
`217-REVIEW.md`/`217-REVIEW-DISPOSITION.md` text, and the exact CONTRIBUTING.md anchors.

**Primary recommendation:** Do not relitigate any locked decision. Plan three roughly
independent workstreams that land in one `ci:` PR (per D-21): (B) `release.yml`
`persist-credentials: false` default-deny + contract-test extension, (C) six
`bin/verify-repo-hygiene` fixes with self-test/guard-test mutation controls, and the
217-REVIEW-DISPOSITION.md hand-edit. Workstream (A), the release itself, is a *separate*,
strictly sequential, mostly-maintainer-gated set of tasks that must run **after** B+C
lands and must be modeled as `checkpoint:human-verify`/non-autonomous steps — it cannot be
verified by CI, it requires a `gh pr edit` body change, a merge, and a `production-hex`
environment approval.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release triggering / versioning | CI/CD control plane (`.github/workflows/release.yml`) | Hex.pm (external) | release-please owns commit parsing and version bump; this workflow owns publish sequencing |
| Checkout credential hygiene | CI/CD control plane | — | `actions/checkout` `with:` is workflow-file-local; no app-tier involvement |
| Contract-test enforcement | Test suite (`test/threadline/*_contract_test.exs`) | CI (`mix ci.all`) | Elixir ExUnit text/YAML-parsing tests are the enforcement layer; CI runs them |
| Repo hygiene guard | Dev-tooling (`bin/verify-repo-hygiene`, bash+Perl) | CI (`verify-repo-hygiene` job) + docs (`CONTRIBUTING.md`) | Guard is a standalone script; CONTRIBUTING documents its contract for humans |
| Review-finding disposition bookkeeping | Planning artifacts (`.planning/phases/217-*`) | — | Pure hand-edited markdown/YAML frontmatter, no code path |

## Package Legitimacy Audit

Not applicable — this phase adds no new dependencies (no `mix.exs`, `package.json`, or
`Cargo.toml` changes are in scope). All work is on existing workflow YAML, an existing
bash/Perl script, existing Elixir test files, and existing markdown.

## User Constraints (from CONTEXT.md)

<user_constraints>
### Locked Decisions

See `.planning/phases/223-close-v1-43-audit-debt/223-CONTEXT.md` `<decisions>` D-01
through D-23 verbatim — they are reproduced in full there and are NOT re-derived or
paraphrased here. Highlights the planner must honor without alternative exploration:

- **D-01..D-06 (release vehicle):** `BEGIN_COMMIT_OVERRIDE` block appended to PR #60's body
  (merge commit `3c4ac9b14e6ca9ac9f9106e012f2bcae6acb9646`), verbatim block text given in
  D-01. Version is **0.11.2** (D-03). Sequence is fixed in D-04 (5 steps, each gated by a
  maintainer grant). D-05: use `origin/main`'s CHANGELOG text (three advisories), never
  `milestone/v1.43`'s (four advisories) — **verified by this research, see Findings**. D-06:
  one CONTRIBUTING sentence, no new CI guard.
- **D-07..D-12 (checkout credentials):** default-deny `persist-credentials: false` on every
  `actions/checkout` in `release.yml` except the two-entry allowlist
  (`dispatch-bootstrap`, `distribution-sync`). Per-step checking, not per-job (D-08). Rule
  names given in D-09. Extend (not replace-wholesale) `release_control_plane_contract_test.exs`
  at its existing per-job counting block (D-10). Mutation controls per D-11 (6 cases). YAML
  comment citing "216 CR-01" above each newly-flagged checkout (D-12).
- **D-13..D-20 (repo-hygiene round-2 fixes):** fix all six `R2-*` findings, none deferred.
  Exact fix shapes given in D-13 through D-19 (verified against the live script below).
  D-20: hand-edit `217-REVIEW-DISPOSITION.md` frontmatter + table, do NOT run the
  gsd-core code-review-disposition step (it would corrupt the hand-edit).
- **Cross-cutting:** D-21 (B+C in one PR, C internally unordered), D-22 (angle-bracket
  placeholders in ALL new prose — binding on this RESEARCH.md too), D-23 (name
  `bin/verify-repo-hygiene` and the contract-test files explicitly in any permission ask,
  since gate-file edits have been classifier-blocked before).

### Claude's Discretion

Exact regex spelling, test names, error-message wording, and the split of plans and tasks,
as long as D-07..D-20 hold (per CONTEXT.md).

### Deferred Ideas (OUT OF SCOPE)

- A CI guard for "releasable fix swallowed by a non-releasable squash subject."
- `persist-credentials: false` default-deny across ALL workflows (only `release.yml` is
  in scope).
- Converting `dispatch-bootstrap`/`distribution-sync` to explicit-URL pushes.
- HYG-03 continuous enforcement of `mix verify.temp_leaks`.
- 216 WR-01/WR-02, setup-node float/SHA pinning, 215 deferred-items, 218 items, 221
  BASH_ENV advisory, SUMMARY frontmatter bookkeeping.
</user_constraints>

<phase_requirements>
## Phase Requirements

No new requirement IDs. This is tech-debt closure; SUP-01 and HYG-02 (already satisfied,
per `.planning/REQUIREMENTS.md:29,57` and `:158,166`) must remain satisfied — i.e. `mix
hex.audit` stays clean and `bin/verify-repo-hygiene` stays wired into `ci.all` and green.

| ID | Description | Research Support |
|----|-------------|------------------|
| SUP-01 | `mix hex.audit` clean for root/examples/bench lockfiles | Untouched by this phase's file changes; re-verify with `mix ci.all` (runs `verify.repo_hygiene` early, `verify.test` includes hex.audit path per `mix.exs` alias chain) |
| HYG-02 | CI fails a PR adding a machine-local path via `bin/`, `verify.*` alias, `verify-repo-hygiene` job | Directly touched by workstream C; every self-test/guard-test change must keep `mix.exs`'s `"verify.repo_hygiene"` alias (line 191) and `ci.all`'s inclusion of it (line 229) intact |
</phase_requirements>

## Standard Stack

No new libraries. Existing stack in scope:

| Component | Version (verified live) | Purpose |
|-----------|---------------------------|---------|
| `actions/checkout` | v5 (all `release.yml` checkouts) [VERIFIED: .github/workflows/release.yml] | Workflow-repo checkout; v5's `persist-credentials` defaults to `true`, writing the token into `.git/config` |
| `googleapis/release-please-action` | v5 [VERIFIED: .github/workflows/release.yml:102] | Release PR automation, override mechanism |
| ExUnit | project pin (`mix test`) | Contract-test runtime for the three test files touched |
| Perl (system) | invoked by `bin/verify-repo-hygiene` via `perl -e "$MATCHER_PROGRAM"` [VERIFIED: bin/verify-repo-hygiene:274-303] | Regex engine for the guard; confirms lookbehind (`(?<!...)`, `(?<=...)`) support required by D-14/D-16 — the live matcher already uses `(?<![A-Za-z0-9._-])` lookbehind in families 1, 2, 4, 5, 7 [VERIFIED: bin/verify-repo-hygiene:276-282, quoted below] |
| Bash | 3.2-compatible (macOS ships 3.2) [VERIFIED: bin/verify-repo-hygiene:94-96, quoted: "Bash 3.2 compatible (macOS ships 3.2): no associative-array declarations; parallel indexed arrays are used instead where state is needed."] | Script host — no associative arrays in new code |

**No installation step** — everything is already vendored/present in the repo.

## release.yml — Verified Checkout Inventory

Every `actions/checkout` step in `.github/workflows/release.yml`, confirmed by reading the
live file this session [VERIFIED: .github/workflows/release.yml]:

| Job | Line | `ref`/target | `persist-credentials: false` present? | Runs `mix`? | D-07 disposition |
|-----|------|--------------|----------------------------------------|-------------|-------------------|
| `release-please` | 63 | none (workflow's own ref) | **No** | No | **Needs the flag added.** Not allowlisted (allowlist is exactly `dispatch-bootstrap`, `distribution-sync` per D-07) — the flag must be added even though the job needs no git auth, exactly as D-07's prose says. |
| `sync-release-pr-pins` | 144 | `.toolchain-pin` sparse checkout | Yes (line 149) | — | Already compliant |
| `sync-release-pr-pins` | 161 | `ref: release-please--branches--main` | Yes (line 164) | Yes (`mix deps.get`, `mix release.pins`, `mix release.pins --check` at lines 167/170/173) | Already compliant — this is the exact pattern to replicate |
| `bootstrap-release-pr-ci` | — | no checkout step | — | No | N/A |
| `dispatch-bootstrap` | 247 | `token: secrets.RELEASE_PLEASE_TOKEN \|\| secrets.GITHUB_TOKEN`, no ref (default) | No | No (only `git fetch`/`git tag`/`git push` at lines 274-283) | **Allowlisted** — matches D-07's stated reason exactly |
| `release-ref` | — | no checkout step | — | No | N/A |
| `gate-ci-green` | — | no checkout step | — | No | N/A |
| `publish-hex` | 468 | `.toolchain-pin` sparse checkout | Yes (line 473) | — | Already compliant |
| `publish-hex` | **481** | `ref: needs.release-ref.outputs.checkout_ref` | **No** | Yes (`mix deps.get`, `mix hex.build`, `mix hex.info`, `mix hex.publish` at lines 486, 504, 510, 544/546) | **Needs the flag added** — CONTEXT's `~:481` anchor is exact |
| `smoke-published` | 633 | `.toolchain-pin` sparse checkout | Yes (line 638) | — | Already compliant |
| `smoke-published` | **646** | `ref: needs.release-ref.outputs.checkout_ref` | **No** | Yes (`mix verify.hex_evaluator` at line 657) | **Needs the flag added** — CONTEXT's `~:646` anchor is exact |
| `distribution-sync` | 681 | `ref: main`, `token: secrets.RELEASE_PLEASE_TOKEN \|\| secrets.GITHUB_TOKEN` | No | No — confirmed by reading the full job body (lines 680-737): `./bin/post-publish-distribution-sync`, `git commit`, `git push -u origin "$BRANCH"`, `gh pr create` only, no `mix` anywhere | **Allowlisted** — matches D-07's stated reason exactly |

**D-07's allowlist (`dispatch-bootstrap`, `distribution-sync`, exactly two entries) is
confirmed correct against the live file** — both are the only jobs whose checkout needs a
persisted token for a bare `git push`, and both run no `mix` command anywhere in their step
list (checked the full job body for each, not just a grep for the word `mix`).

**Total checkouts needing the flag added: 3** (`release-please` line 63, `publish-hex` line
481, `smoke-published` line 646). All three are target-ref or workflow-ref checkouts that
either run `mix` afterward or, per D-07, get the flag regardless.

## Architecture Patterns

### Recommended Task Structure (informs plan/wave split — not prescriptive on wave count)

```
Workstream B: release.yml credential hygiene
├── Add persist-credentials: false to 3 checkout steps (release.yml:63,481,646)
├── Add "citing 216 CR-01" comment above each (style of release.yml:157-160)
└── Extend release_control_plane_contract_test.exs:
    ├── New checkout-credential-free rule (every checkout flag-set unless allowlisted)
    ├── New allowlisted-job-runs-no-mix rule
    ├── New stale-allowlist-entry rule (borrow idiom from
    │   ci_token_permissions_contract_test.exs:356-372 stale_errors/2)
    └── 6 mutation-control cases (D-11), using job_steps/1 + yaml_value/2 from
        ci_workflow_parity_contract_test.exs:3153,3691

Workstream C: bin/verify-repo-hygiene round-2 fixes (six independent sub-fixes)
├── D-13 literal_too_broad structural check (exit 2) — insert in the allowlist
│   validation loop (bin/verify-repo-hygiene:340-374, alongside the existing
│   "empty scope"/"duplicate entry" problem checks)
├── D-14 family-6 left-anchor (bin/verify-repo-hygiene:280 regex)
├── D-15 newline pre-scan check (before the tree scan begins, ~line 375-386;
│   narrow header claim at lines 15-17)
├── D-16 Linux-encoded family-6b regex + CONTRIBUTING placeholder bullet
│   (insert among lines 122-134, after the existing `-Users-<user>-<project>` bullet)
├── D-17 tighten IN-01's assertion in repo_hygiene_contract_test.exs:403 to match
│   the literal printf line at bin/verify-repo-hygiene:537
├── D-18 CONTRIBUTING.md:141 wording change
└── D-19 self-test case count bump (6 → N) in bin/verify-repo-hygiene:234 and
    repo_hygiene_guard_test.exs:574-577

Workstream: 217-REVIEW-DISPOSITION.md hand-edit (D-20)
└── Single commit, done AFTER B+C's fix commits exist (so the Source cells can
    cite real <sha>s), before mix ci.all's final green run for the PR

Workstream A: the mint 1.11.0 release (sequential, maintainer-gated, AFTER B+C merges)
├── checkpoint:human-verify — gh pr edit 60 with BEGIN_COMMIT_OVERRIDE block (maintainer push)
├── checkpoint:human-verify — trigger/confirm release-please run, verify "chore(main):
│   release 0.11.2" PR opens
├── docs(release): date the 0.11.2 changelog entry PR (same shape as PR #58 precedent,
│   verified: merged 2026-09-27, title "docs(release): date the 0.11.1 changelog entry",
│   retitles Unreleased -> dated heading)
├── checkpoint:human-verify — merge release PR --match-head-commit
├── checkpoint:human-verify — production-hex environment approval
└── checkpoint:human-verify — publish/smoke verification, distribution-sync PR merge
```

### Pattern: contract-test mutation control (established in this repo)

```elixir
# Source: test/threadline/ci_token_permissions_contract_test.exs:378-450 (read this session)
defp mutate!(texts, path, from, to) do
  original = Map.fetch!(texts, path)
  assert String.contains?(original, from),
         "control anchor not found in #{path}: #{inspect(from)}"
  Map.put(texts, path, String.replace(original, from, to, global: false))
end

# each case: mutate!, refute mutated == texts, assert the named rule fired
test "#{label} fires rule=#{rule}", %{texts: texts} do
  mutated = mutate!(texts, unquote(path), unquote(from), unquote(to))
  refute mutated == texts, "the control did not change the input"
  errors = token_errors(mutated)
  assert rule_fired?(errors, unquote(rule)),
         "expected rule=#{unquote(rule)} to fire, got #{inspect(errors)}"
end
```

### Pattern: release_control_plane_contract_test.exs's per-checkout counting idiom (to extend, not replace)

```elixir
# Source: test/threadline/release_control_plane_contract_test.exs:143-161 (read this session)
checkout_count = fn job -> length(Regex.scan(~r/uses: actions\/checkout@/, job)) end
credential_free = fn job -> length(Regex.scan(~r/^\s+persist-credentials: false$/m, job)) end

assert checkout_count.(sync) == credential_free.(sync),
       "every checkout in sync-release-pr-pins must set persist-credentials: false. ..."

mutated =
  String.replace(
    sync,
    "ref: release-please--branches--main\n          persist-credentials: false\n",
    "ref: release-please--branches--main\n"
  )
refute mutated == sync, "the credential-free checkout control did not change the input"
refute checkout_count.(mutated) == credential_free.(mutated),
       "dropping the flag from the release-branch checkout must make the counts diverge"
```

D-10 directs extending this test file at exactly this block (retaining the
`sync-release-pr-pins`-specific asserts above it) to add a repo-wide (all `release.yml`
jobs, not just `sync-release-pr-pins`) allowlist-aware version, per D-09's three rules.

### Pattern: the live Perl matcher's existing lookbehind usage (grounds D-14/D-16 feasibility)

```perl
# Source: bin/verify-repo-hygiene:276-282 (read this session) — verbatim
qr{(?<![A-Za-z0-9._-])(/\Q$users\E/[A-Za-z0-9._-]+[A-Za-z0-9._/+-]*)},
qr{(?<![A-Za-z0-9._-])(/\Q$home\E/[A-Za-z0-9._-]+[A-Za-z0-9._/+-]*)},
qr{([A-Za-z]:\\+\Q$users\E\\+[A-Za-z0-9._-]+[A-Za-z0-9._\\+-]*)},
qr{(?<![A-Za-z0-9._-])(~/[A-Za-z0-9._-]+[A-Za-z0-9._/+-]*)},
qr{(?<![A-Za-z0-9._-])((?:/private)?/var/folders/[A-Za-z0-9_+-]{2}/)},
qr{(-\Q$users\E-[A-Za-z0-9._]+)},   # <-- family 6, no left boundary (WR-02/D-14 target)
qr{(?<![A-Za-z0-9._-])(\\/(?:\Q$users\E|\Q$home\E)\\/[A-Za-z0-9._-]+[A-Za-z0-9._\\/+-]*)},
```

Confirms: (1) the engine is Perl, which supports fixed-width lookbehind — D-14's
`(?:(?<![A-Za-z0-9._-])|(?<=[A-Za-z]-))` construction is syntactically valid Perl regex; (2)
family 6 (line 280, `qr{(-\Q$users\E-[A-Za-z0-9._]+)}`) genuinely has no left-boundary
lookbehind today, confirming WR-02/D-14's finding is current, not stale; (3) the review's own
proposed fix text (217-REVIEW.md:101) uses a **three**-branch alternation including
`(?<=[A-Za-z]--)` for a double-dash drive-prefix case, one branch more than D-14's
CONTEXT.md text — the planner should default to the review's three-branch form since it is
the more complete one already vetted against the R1-CR-01 positives, unless D-14's two-branch
form was a deliberate CONTEXT-time simplification (Claude's Discretion covers "exact regex
spelling," so either is compliant — flag this as a planner choice, not a blocker).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting every `actions/checkout` in a workflow and its steps | A new YAML-parsing helper | `job_steps/1` + `yaml_value/2` from `ci_workflow_parity_contract_test.exs:3153,3691` (read this session, confirmed present) | Already handles step-splitting on 6-space list markers and single-key YAML value extraction; reinventing it risks a different edge-case model than the rest of the CI contract-test suite |
| Allowlist-with-stale-entry-detection pattern | A new allowlist data structure | The `%{path => jobs}` allowlist + `stale_errors/2` idiom at `ci_token_permissions_contract_test.exs:354-372` (read this session) | Exact idiom D-09 asks to borrow; keeps error message shape (`rule=...`) consistent across the CI contract-test suite |
| Path-shape regex engine | A hand-rolled Bash string-matcher | The existing Perl `MATCHER_PROGRAM` in `bin/verify-repo-hygiene:274-303` | Bash 3.2 has no PCRE; the script already solved "concatenate literals so this script's own text stays clean" — new families must follow the same `\Q...\E` quoting convention |

**Key insight:** every piece of machinery this phase needs (mutation-control test idiom,
allowlist+stale-entry idiom, YAML step-parsing helpers, Perl lookbehind matcher) already
exists in the repo and was purpose-built for this exact kind of contract. The work is
additive extension, not new infrastructure.

## Common Pitfalls

### Pitfall 1: Editing `bin/verify-repo-hygiene`'s self-test block without keeping fixture
literals built by concatenation
**What goes wrong:** The script's own doc comment (line 94-96, and the self-test's own
comment at lines 122-124) states every fixture literal is built by string concatenation
(`st_word_users="Us""ers"`) specifically so the script's own source text never contains a
literal it exists to catch. A new self-test case (g)/(h)/(i) that writes `/Users/<user>/<path>` or
`-home-<user>-<project>` as a literal string will make the guard flag its own script file.
**Why it happens:** Natural to write a test fixture as a plain string.
**How to avoid:** Follow the exact pattern at lines 121-127: build every new fixture word
via `"pre""fix"` concatenation before use.
**Warning signs:** `bin/verify-repo-hygiene` itself starts failing `bin/verify-repo-hygiene`
(self-scan) after the edit.

### Pitfall 2: Treating `release-please` job's checkout (line 63) as out-of-scope because "it needs no git auth"
**What goes wrong:** It's tempting to skip line 63 since the job does nothing with git
after checkout (release-please-action handles its own auth via `token:`). But D-07 says
"EVERY checkout... unless its job is in the allowlist" and the allowlist is exactly two
named jobs, neither of which is `release-please`. Context's own text says this checkout
"needs no git auth" but still must get the flag.
**Why it happens:** The flag looks unnecessary for that job in isolation.
**How to avoid:** Follow D-07 literally — default-deny is unconditional except for the two
named allowlist entries.
**Warning signs:** A new mutation-control test for `checkout-credential-free` still passes
after the fix, because line 63 was skipped.

### Pitfall 3: Running the gsd-core code-review-disposition step on 217-REVIEW-DISPOSITION.md
**What goes wrong:** D-20 explicitly forbids this — the automated disposition step would
re-add bare ids as `open` rows and flag the `R2-*` rows, corrupting the hand-edit. CONTEXT
cites commit `f169cb91` as the hand-merge precedent for this exact failure mode.
**Why it happens:** It's the "normal" tool for updating a disposition file.
**How to avoid:** Hand-edit the frontmatter and table directly with `Edit`, per D-20's
literal instructions (`disposition: fixed`, `open: 0`, `total: 11`, refreshed
`recorded:` timestamp, Source cells with real `<phase>-<plan> Task <N> <sha>`).
**Warning signs:** `grep -c '| open |' 217-REVIEW-DISPOSITION.md` is nonzero after the edit.

### Pitfall 4: Landing the mint fix as a *new* `fix(deps):` commit
**What goes wrong:** D-01 is explicit that the lock/CHANGELOG changes are already on
`main` (inside squash `3c4ac9b1`), so any new commit that touches `mix.lock`/CHANGELOG
again would be either a fake no-op diff or an unrelated bump. The mechanism is a PR-body
edit to the *already-merged* PR #60, not a new commit.
**Why it happens:** "Ship a fix" instinctively reads as "write a fix commit."
**How to avoid:** Use `gh pr edit 60` to append the `BEGIN_COMMIT_OVERRIDE` block to the
existing PR body (verified this session: PR #60 merged as commit `3c4ac9b1` via squash,
confirmed by `gh pr view 60 --json mergeCommit` returning a single oid — squash-merge is
required for the override mechanism per release-please's own docs).
**Warning signs:** A release-please run after the edit still shows no releasable commit,
or opens a PR for the wrong version (0.12.0, if a stray `feat:` line crept into the
override block).

### Pitfall 5: Using `milestone/v1.43`'s (this branch's) CHANGELOG.md text as ground truth
**What goes wrong:** Verified directly this session: the local `milestone/v1.43` branch's
`CHANGELOG.md` "Unreleased" section says "four advisories" and lists
`EEF-CVE-2026-82672`, and `.release-please-manifest.json` on this branch reads `0.11.0` —
both are stale. `origin/main`'s CHANGELOG says "three advisories" (omitting
`EEF-CVE-2026-82672`, already fixed by 0.11.1/mint 1.10.1) and its manifest reads
`0.11.1`, `mix.exs` `@version` reads `0.11.1`.
**Why it happens:** This branch is the working branch; its committed files look
authoritative until diffed against `origin/main`.
**How to avoid:** Any release-adjacent doc edit (the 0.11.2 changelog-dating PR) must be
based on `origin/main`'s current state, not this branch's.
**Warning signs:** The 0.11.2 changelog entry double-counts an advisory already fixed in
0.11.1.

## Code Examples

### CONTRIBUTING.md anchors — verified line ranges (read this session)

```markdown
<!-- Source: CONTRIBUTING.md:122-134, verbatim, read this session -->
Use these forms:

<!-- repo-hygiene-placeholders:start -->
- `<home>/<path>`: any home directory, when the platform does not matter
- `/Users/<user>/<path>`: a macOS home directory
- `/home/<user>/<path>`: a Linux home directory
- `C:\Users\<user>\<path>`: a Windows home directory
- `~/<path>`: a home-relative path
- `/var/folders/<xx>/<path>`: the macOS per-user temp root
- `-Users-<user>-<project>`: a Claude-encoded project directory name
- `<claude-projects-dir>/<encoded-project>/`: the Claude projects directory
- `\/Users\/<user>\/<path>`: a JSON-escaped home directory
<!-- repo-hygiene-placeholders:end -->
```

D-16's new Linux-form bullet (`` `-home-<user>-<project>` ``) goes inside this
`<!-- repo-hygiene-placeholders:start -->`/`:end` block — the block is what
`repo_hygiene_contract_test.exs`'s `placeholder_forms/1` (lines 285-300) parses, and its
"concretized placeholder forms are HITs" test (lines 359-397, read this session) auto-picks
up any new bullet containing `<user>`, so no test-file edit is needed for D-16's
placeholder-concretization control — only the CONTRIBUTING bullet itself, worded with
`<user>` so it auto-concretizes.

```markdown
<!-- Source: CONTRIBUTING.md:139-141, verbatim, read this session -->
The allowlist (`.github/repo-hygiene-allowlist.tsv`) is only for runner, cache
and tool-install paths that carry no username. It is never for prose, and no
file or directory is exempt from the scan.
```

D-18 changes the final clause of line 141 to: "and no file or directory is exempt from the
scan other than the allowlist's own literal column."

```markdown
<!-- Source: CONTRIBUTING.md:985-988, the "Ongoing releases (0.6.1+)" section, read this session -->
### Ongoing releases (0.6.1+)

1. Merge conventional commits to **`main`** — Release Please opens/updates a Release PR
   (`release-please-config.json`, manifest `.release-please-manifest.json`). ...
2. Merge the Release PR when CI is green — Release Please tags, then the same publish +
   distribution sync chain runs.
```

D-06's new sentence goes in this section (the natural home for "how a commit becomes a
release" prose).

```markdown
<!-- Source: CONTRIBUTING.md:1065-1075, "Maintainer manual checklist (release)" —
     this IS "the release runbook" referenced throughout CONTEXT.md and this phase's
     ROADMAP entry; read this session, verbatim -->
## Maintainer manual checklist (release)

Use when preparing or debugging a release (no secrets in logs):

1. Clean tree: `git status --porcelain` empty (local preflight only).
2. Run `mix verify.release`.
3. Run `DB_PORT=5433 mix ci.all` (or `mix ci.all`) with Postgres up.
4. Ensure **`main`** CI is green on the commit to release.
5. **Release workflow:** dispatch **`release.yml`** or merge Release Please PR — do not
   rely on manual `mix hex.info` copy-paste; the workflow polls Hex.pm and opens the
   distribution sync PR.
6. Merge the distribution sync PR after doc contracts pass.
```

There is no separate "release runbook" file — every prior-phase reference to "the release
runbook" resolves to this CONTRIBUTING.md section. D-04's step 5 ("per the release
runbook") means: follow this checklist's items 4-6, plus the `production-hex` environment
approval that `release.yml`'s `publish-hex` job gates on (line 436: `environment:
production-hex`).

### `217-REVIEW.md` round-2 finding sources (verified this session, informs exact fix code)

```elixir
# Source: .planning/phases/217-repo-hygiene/217-REVIEW.md:71-79 (WR-01/D-13's own proposed fix)
roots = [
  "/" <> @users_word <> "/", "/" <> @home_word <> "/", "-" <> @users_word <> "-",
  "\\/" <> @users_word <> "\\/", "\\/" <> @home_word <> "\\/",
  "/var/folders/", "/private/var/folders/"
]
ancestor? = Enum.any?(roots, &(String.starts_with?(&1, literal <> "/") or String.starts_with?(&1, literal)))
```
This is illustrative Elixir pseudocode inside the review (the guard itself is bash/Perl);
the planner's bash implementation of `literal_too_broad` must reproduce this "is the
literal a prefix of any family root" logic in bash string comparisons, inserted into the
allowlist structural-validation loop at `bin/verify-repo-hygiene:340-364` (the existing
`problem="..."` checks for empty scope/literal/duplicate entry).

```perl
# Source: .planning/phases/217-repo-hygiene/217-REVIEW.md:101 (WR-02/D-14's own proposed fix,
# THREE-branch form — one branch more than D-14's CONTEXT.md text, see Pitfall/Pattern note above)
qr{(?:(?<![A-Za-z0-9._-])|(?<=[A-Za-z]-)|(?<=[A-Za-z]--))(-\Q$users\E-[A-Za-z0-9._]+)},
```

```perl
# Source: .planning/phases/217-repo-hygiene/217-REVIEW.md:138 (WR-04/D-16's own proposed fix)
-\Q$home\E-[A-Za-z0-9._]+   # anchored the same way as WR-02, per D-16
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `actions/checkout@v5` default (`persist-credentials: true`) | Explicit `persist-credentials: false` on every checkout that isn't proven to need the token | This phase (D-07) | Token no longer readable by third-party compile-time code (`mix deps.get`/`mix hex.build`/etc.) during `publish-hex` and `smoke-published`. Note (from CONTEXT's Specifics, unverified this session, `[ASSUMED]`): `actions/checkout@v6` reportedly moves the persisted credential to a file under `$RUNNER_TEMP` rather than `.git/config`, but same-user process readability is unchanged either way — the flag is needed regardless of checkout major version. |
| `217-REVIEW-DISPOSITION.md` with 6 `open` `R2-*` rows | All rows `fixed`, `open: 0` | This phase (D-20) | Closes the last audit gap blocking `/gsd-complete-milestone` for v1.43 |

**Deprecated/outdated:** None — no library/tool deprecations in scope.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `actions/checkout@v6` moves the persisted credential to a `$RUNNER_TEMP` file instead of `.git/config`, but same-user readability is unchanged | State of the Art | Low — this is background color from CONTEXT.md's Specifics, not load-bearing for any task; the repo is on v5 either way, confirmed live |
| A2 | The `production-hex` GitHub Environment id remembered in prior-phase memory (`20753768806`, from 213-03-SUMMARY, not re-verified this session) is still current | Workstream A sequencing | Low-medium — if stale, the maintainer's approval step in the GitHub UI still works by clicking the pending deployment; no automation depends on the numeric id in this phase's plan |

**If this table is empty:** N/A — two low-risk items above; nothing here blocks planning.
Every load-bearing claim (checkout line numbers, test file shapes, CONTRIBUTING anchors,
CHANGELOG/manifest branch divergence, PR #60/#58 states, self-test case count, Perl
lookbehind support) was verified by reading the live file or running a live command this
session.

## Open Questions (RESOLVED)

1. **Two-branch vs three-branch left-anchor regex for D-14 (family 6)**
   - What we know: CONTEXT.md D-14 gives a two-branch alternation
     `(?:(?<![A-Za-z0-9._-])|(?<=[A-Za-z]-))`; the underlying `217-REVIEW.md:101` (the
     source D-14 was distilled from) gives a three-branch form adding
     `(?<=[A-Za-z]--)` for a double-dash drive-prefix case.
   - What's unclear: whether the double-dash case was intentionally dropped as
     unnecessary, or simply summarized away.
   - Recommendation: default to the three-branch form from `217-REVIEW.md` (the more
     complete, already-reasoned-through one) unless the planner has a specific reason to
     prefer the simpler two-branch form; this is within Claude's Discretion per CONTEXT.md
     ("exact regex spelling... as long as D-07..D-20 hold"), so either choice is compliant —
     flag whichever is chosen in the plan's verification notes so it's traceable.

2. **`bootstrap_guard_errors/1` style for the new B rules**
   - What we know: D-09 says "each returned as a tagged error in the style of
     `bootstrap_guard_errors/1`" — that function (verified,
     `release_control_plane_contract_test.exs:236-255`) returns a list of `{condition,
     message}` tuples filtered by `Enum.reject(fn {ok, _} -> ok end)`.
   - What's unclear: nothing structurally — this is a clear, copyable pattern. Flagging
     only because the plan should literally copy this function's shape (not the
     rule-string style of `ci_token_permissions_contract_test.exs`'s `"...rule=name"`
     strings), since D-09 names `bootstrap_guard_errors/1` specifically, not the other
     file's convention.
   - Recommendation: implement the three D-09 rules as `{condition, message}` tuples in a
     new private function following `bootstrap_guard_errors/1`'s exact shape.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `git` | `bin/verify-repo-hygiene`, all contract tests | ✓ | present (die-check exists in script itself) | — |
| `perl` | `bin/verify-repo-hygiene` matcher | ✓ | system perl, confirmed by successful `bin/verify-repo-hygiene` run this session (exit 0, "4231 tracked text file(s) clean") | — |
| `gh` CLI | workstream A (`gh pr edit 60`, `gh pr view`), used this session | ✓ | confirmed working this session (`gh pr view 58/60` succeeded) | — |
| Elixir/Mix toolchain | `mix ci.all`, `mix test` | Not directly probed this session (no test run executed to conserve time/tokens) | — per `.tool-versions` (project memory: "must pin erlang+elixir or bare `mix` dies") | Planner/executor must confirm `.tool-versions` is respected per project memory before relying on bare `mix` |

**Missing dependencies with no fallback:** None identified.

**Missing dependencies with fallback:** None — all tooling is already present and was
exercised directly in this research session (`bin/verify-repo-hygiene`, `gh pr view`, `git
show origin/main:...`).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (`mix test`), plus a standalone bash self-test (`bin/verify-repo-hygiene --self-test`) |
| Config file | `mix.exs` aliases (verified: `"verify.test": ["test"]` line 143, `"verify.repo_hygiene"` custom alias line 191, both members of `"ci.all"` at lines 222-233) |
| Quick run command | `mix test test/threadline/release_control_plane_contract_test.exs test/threadline/repo_hygiene_guard_test.exs test/threadline/repo_hygiene_contract_test.exs` |
| Full suite command | `mix ci.all` (verified alias chain includes `verify.format`, `verify.credo`, `verify.repo_hygiene`, `verify.test`, per `mix.exs:222-233`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| (B) checkout-credential-free | Every `release.yml` checkout sets the flag unless allowlisted | unit (text-parse) | `mix test test/threadline/release_control_plane_contract_test.exs` | ✅ (extend existing file) |
| (B) allowlisted-job-runs-no-mix | No allowlisted job's `run:` contains `mix ` | unit (text-parse) | same file | ✅ (extend) |
| (B) stale-allowlist-entry | Allowlist names only real jobs | unit (text-parse) | same file | ✅ (extend) |
| (C) D-13 literal_too_broad | Broad allowlist literal is a config error (exit 2) | shell self-test + unit | `bin/verify-repo-hygiene --self-test`; `mix test test/threadline/repo_hygiene_guard_test.exs` | ✅ (extend both) |
| (C) D-14 family-6 left anchor | TitleCase kebab word is not a HIT; R1-CR-01 positives still HIT | shell self-test + unit | same two commands | ✅ (extend both) |
| (C) D-15 newline pre-scan | Newline-containing tracked filename exits 2 | shell self-test | `bin/verify-repo-hygiene --self-test` | ✅ (extend) |
| (C) D-16 Linux family-6b | Linux-encoded project dir is a HIT when anchored | shell self-test + unit + doc-contract | both above + `mix test test/threadline/repo_hygiene_contract_test.exs` (auto-covers via placeholder_forms) | ✅ (extend) |
| (C) D-17 IN-01 hint assertion | Deleting the `printf` hint line fails the test | unit | `mix test test/threadline/repo_hygiene_contract_test.exs` | ✅ (extend) |
| (C) D-19 self-test count | `--self-test` prints `ok (N cases)` matching actual case count | shell self-test + unit | both | ✅ (extend) |
| SUP-01/HYG-02 regression | Nothing broke `mix hex.audit` or the repo-hygiene guard's real-tree pass | integration | `mix ci.all` | ✅ |

### Sampling Rate

- **Per task commit:** the specific test file(s) touched (`mix test <file>` or
  `bin/verify-repo-hygiene --self-test`) plus a live `bin/verify-repo-hygiene` run against
  the real tree (must stay exit 0, per the phase's Success Criteria 4).
- **Per wave merge:** `mix ci.all`.
- **Phase gate:** `mix ci.all` green AND `bin/verify-repo-hygiene` green AND `grep -c '|
  open |' .planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` returns `0`, before
  `/gsd-verify-work`. Workstream A's release steps are verified separately by the release
  runbook checklist (CONTRIBUTING.md:1065-1075) and are NOT part of `mix ci.all`.

### Wave 0 Gaps

None — existing test infrastructure (`release_control_plane_contract_test.exs`,
`repo_hygiene_guard_test.exs`, `repo_hygiene_contract_test.exs`,
`ci_token_permissions_contract_test.exs`, `ci_workflow_parity_contract_test.exs`) already
covers every behavior this phase changes; the phase's task is to extend these files, not
create new ones.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | No auth surface touched |
| V3 Session Management | No | N/A |
| V4 Access Control | Yes | GitHub Environment required-reviewer gate (`production-hex`) already governs the irreversible publish step; this phase does not weaken it — D-04 explicitly requires the maintainer's own approval, not an automated one |
| V5 Input Validation | Yes (indirectly) | `bin/verify-repo-hygiene`'s allowlist structural validation (D-13's `literal_too_broad`) is itself an input-validation hardening of a security-adjacent gate (prevents an overly-broad allowlist entry from silently defeating the secret-leak scanner) |
| V6 Cryptography | No | No crypto surface touched |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Persisted `GITHUB_TOKEN`/PAT readable by third-party compile-time code during `mix deps.get`/`mix hex.build` | Information Disclosure | `persist-credentials: false` on every checkout preceding a `mix` invocation (this phase's Workstream B, closing 216 CR-01) |
| Overly-broad repo-hygiene allowlist entry silently exempting real home-path leaks | Tampering (of the guard's own trust boundary) | D-13's `literal_too_broad` structural check, exit 2 on any ancestor-prefix literal |
| A tracked filename containing a newline byte mis-scoping a HIT to the wrong (possibly nonexistent) path, letting a phantom allowlist entry cover a real leak | Tampering / Repudiation | D-15's pre-scan `git ls-files -z` newline check, exit 2 before any scan runs |
| Merged-PR override block accidentally containing a `feat:` line, bumping the release to the wrong (0.12.0) version | Tampering (of release semantics) | D-01's verbatim, reviewed block text — the planner/executor must not paraphrase it |

## Sources

### Primary (HIGH confidence — read/run directly this session)

- `.planning/phases/223-close-v1-43-audit-debt/223-CONTEXT.md` — full D-01..D-23 read
- `.planning/v1.43-MILESTONE-AUDIT.md` — full frontmatter + body read
- `.planning/STATE.md`, `.planning/REQUIREMENTS.md` (SUP-01/HYG-02 rows) — read
- `.github/workflows/release.yml` — read in full (lines 1-737), every checkout and job
  inventoried
- `test/threadline/release_control_plane_contract_test.exs` — read in full (272 lines)
- `test/threadline/ci_token_permissions_contract_test.exs` — read (lines 330-460, the
  allowlist/stale/mutation-control idiom)
- `test/threadline/ci_workflow_parity_contract_test.exs` — read (`job_steps/1` at 3153,
  `yaml_value/2` at 3691, and surrounding context)
- `bin/verify-repo-hygiene` — read in full (562 lines)
- `.planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` — read in full
- `.planning/phases/217-repo-hygiene/217-REVIEW.md` — read the full Warnings + Info
  sections (lines 48-165), including each finding's proposed fix code
- `test/threadline/repo_hygiene_contract_test.exs` — read (placeholder-parsing and
  concretization-control sections, lines 270-410)
- `test/threadline/repo_hygiene_guard_test.exs` — grepped for the "six cases" assertion
  (lines 574-577)
- `CONTRIBUTING.md` — read the "Writing about machine-local paths" (108-144), "Ongoing
  releases" (985-988), and "Maintainer manual checklist (release)" (1065-1075) sections
- `CHANGELOG.md` (local `milestone/v1.43` branch) vs. `origin/main`'s `CHANGELOG.md` and
  `.release-please-manifest.json` and `mix.exs` — diffed live via `git show origin/main:...`
- `gh pr view 58` and `gh pr view 60` — run live, confirmed merge state/commit shape
- `bin/verify-repo-hygiene` (no args) — run live against the real tree, confirmed exit 0,
  "4231 tracked text file(s) clean; 8 allowlist entries used, 0 inert"
- `mix.exs` — grepped for the `ci.all`/`verify.*` alias chain (lines 12-233)

### Secondary (MEDIUM confidence)

- WebSearch on release-please's `BEGIN_COMMIT_OVERRIDE`/`END_COMMIT_OVERRIDE` mechanism —
  confirmed the mechanism reads from the PR body (not commit message), requires squash
  merge, and is documented at googleapis/release-please's own README/wiki. [CITED:
  googleapis/release-please documentation, via WebSearch summary]

### Tertiary (LOW confidence / carried over from CONTEXT, not independently re-verified)

- CONTEXT's claim about `actions/checkout@v6`'s `$RUNNER_TEMP` credential-file behavior —
  not independently verified this session (repo is on v5; not load-bearing for any task).
  [ASSUMED]
- The `production-hex` environment numeric id (`20753768806`) from prior-phase memory — not
  re-queried via the GitHub API this session. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; every tool/version claim verified live
- Architecture: HIGH — every line-number anchor for `release.yml`, the three test files,
  `bin/verify-repo-hygiene`, and `CONTRIBUTING.md` was confirmed by reading the live file
  this session (not inherited unverified from CONTEXT.md)
- Pitfalls: HIGH — five pitfalls, each grounded in a specific verified file/line or a live
  command run this session (the CHANGELOG/manifest branch-divergence pitfall was directly
  reproduced via `git show origin/main:...`)

**Research date:** 2026-09-29
**Valid until:** 14 days (release-adjacent workflow files and a live PR #60/#65 state are
fast-moving; re-verify `release.yml` line numbers and PR states before executing if this
research is more than ~2 weeks old, or if any other PR touches `release.yml` in the
interim)
