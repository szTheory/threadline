# Phase 198 — Branch protection migration and the D-34 step 5 push (Plan 198-07)

This artifact records the last irreversible actions of Phase 198: the authorization to publish
the repository's planning history, the migration of `main`'s protection from classic branch
protection to a committed repository ruleset, the measured post-push run on `main`, and the
archive-tag push that closes the single-copy durability exposure recorded in
`.planning/ARCHIVE-REGISTER.md`.

It is written to be read by someone who was not here. Where a thing did not happen, it says so.

---

## D-34 step 5 authorization

**Recorded:** 2026-08-28T02:13:21Z

D-34 sequences this phase's irreversible work in five ordered steps. Steps 1 through 4 each carried
their own abort branch and each produced an artifact. This section verifies those artifacts rather
than trusting a recollection, and then records the two one-way authorizations.

### Gate checklist — steps 1 through 4

| # | Step | Result | Evidence artifact / command, run at the timestamp above |
|---|---|---|---|
| 1 | Branch and worktree triage | **PASS** | `.planning/audits/198-phase166-diff.md` (868 lines, committed `7e2da68c`) and `.planning/ARCHIVE-REGISTER.md` (2 rows). Both `archive/*` tags resolve and are annotated: `git cat-file -t` → `tag` for each; `archive/gsd/phase-166-unfreeze-token-lane-mechanism` → `dd5b48be6f4c175f5dd7cecee19dbeb2f9a2934a`, `archive/backup/pre-release-cleanup-2026-05-08` → `50374eb71111f464154e99f1b6eb92d0067d5e97`. `git worktree list \| wc -l` → `1`. `git branch` → `main` only. |
| 2 | Paid critic workflow deleted | **PASS** | `grep -rl ANTHROPIC .github/` → no output. `.github/workflows/ui-critic.yml` absent. Guarded by `test/threadline/ci_topology_contract_test.exs` (GREEN-09 resurrection guard), demonstrated red against a scratch reintroduction in Plan 06. |
| 3 | Legacy publish workflow deleted, topology assertions added | **PASS** | `grep -rl 'hex.publish' .github/workflows/` → `.github/workflows/release.yml` **only**. `mix verify.release` exits 0 (19 tests, 0 failures) as recorded in `198-06-SUMMARY.md`. The single-publish-path guard asserts *list equality*, not a count. |
| 4 | Credential audit | **PASS** | `.planning/audits/198-credential-audit.md` reads `## VERDICT: PROCEED` (determined 2026-08-27T20:02:01Z). **Class A = 0 (rotated: 0), Class B = 0, Class C = 5.** The D-29 invariant "rotation before push" is vacuously satisfied — there is nothing to rotate, so there is no rotation timestamp to record and none is fabricated. Push protection verified live at the moment of this check: `gh api repos/:owner/:repo --jq .security_and_analysis` → `"secret_scanning":{"status":"enabled"}`, `"secret_scanning_push_protection":{"status":"enabled"}`. |

All four are green against their artifacts. No abort branch is taken.

### Authorization 1 — publish the local history to `origin/main`

**Confirmed:** 2026-08-28T02:13:21Z · **Decision: AUTHORIZED, in full.**

The maintainer was told explicitly, before answering, that:

- `szTheory/threadline` is a **public** repository;
- **2,190 tracked `.planning/` files** — the complete GSD planning history, including LLM spend
  figures down to `$0.015`, vendor and model names, internal quality assessments, and assessments
  that in places contradict the repository's own documentation — become permanently public and
  mirrorable with this push;
- the action is **one-way**: D-30's accepted posture forbids a history rewrite as the remedy.

The maintainer chose **"push everything, plan as written."**

This is an **intentional, informed reversal of the prior "milestone history stays local" policy.**
It is recorded here as an explicit decision, with that rationale, so the reversal is auditable
rather than silent. The prior convention existed solely because pushing would publish `.planning/`
history; the maintainer's position, consistent with D-30, is that an audit library showing its own
record is on-brand and is treated as an asset rather than a leak.

### Authorization 2 — push the archive tags to `origin`

**Confirmed:** 2026-08-28T02:13:21Z · **Decision: AUTHORIZED (option `authorize-both`, D-32 as locked).**

Both `archive/*` tags currently exist **only on this laptop**. `.planning/ARCHIVE-REGISTER.md`'s
Durability section names that as a known, time-boxed single-copy exposure, and GREEN-12 exists
precisely to close it. `archive/gsd/phase-166-…` pins real unmerged work that is **not** an
ancestor of `main`; losing the laptop would destroy the only copy of it.

The tags are pushed **explicitly by name**, never via `--tags`, so no unrelated tag is published as
a side effect.

### Deferred, and deliberately not decided here

**Whether *milestone* tags stay local is a separate question and is deferred to milestone close.**
It is noted, not answered. Nothing in this plan pushes a milestone tag, and the acceptance check
below confirms that none appeared on origin.

### One correction to the plan's own numbers

The plan, the objective, and several earlier artifacts say **587** unpushed commits. The measured
count at execution time is **636** (`git log origin/main..main --oneline | wc -l`). The figure grew
as Phase 198's own plans committed. Stated rather than repeated, because a published record that
carries a stale number teaches a future reader to distrust the rest of it.
