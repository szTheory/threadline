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

---

## Ordering correction — protection is applied AFTER the push, not before

The plan sequences Task 2 (apply the ruleset) before Task 3 (push). **That order deadlocks its own push**, and the plan's own text shows why without drawing the conclusion:

- The ruleset carries a `pull_request` rule, which blocks every **direct push** to `main`.
- Its one required status check is `CI required`, which — see `## GREEN-07, honestly` below — is **red** and will stay red until the 79 test-side defects Plan 198-04 documented are fixed. So no pull request can merge either.
- Half (b) of `bin/verify-branch-protection` asserts `CI required` **has been emitted on `main`'s head**. Before the push, `main`'s head on origin is `67998e0b`, which predates the aggregate gate entirely. Task 2's `<verify>` (`bash bin/verify-branch-protection` exits 0) is therefore **unsatisfiable before Task 3 runs** — Task 3's own final step, "run it once now that a real run has reported there", concedes exactly this.

Applying an enforcing ruleset first would have left the repository unable to accept the very commits this phase exists to publish, and the only way out would have been to bypass or weaken the gate — which the plan forbids and this artifact will not do. The three files are therefore authored and committed in Task 2, and the **live** configuration is applied after the push lands.

This is recorded as an ordering correction rather than executed silently.

## Ruleset payload proof (create → verify → delete)

The committed `.github/rulesets/main.json` was **applied live and read back** before being removed again, so the payload is proven rather than asserted.

```
$ gh api --method POST /repos/szTheory/threadline/rulesets --input .github/rulesets/main.json
{ "id": 21701781, "name": "main-protection", "target": "branch",
  "enforcement": "active", "bypass_actors": [] }
```

Effective rules re-read from `GET repos/szTheory/threadline/rules/branches/main`, verbatim:

```json
[{"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":false,"do_not_enforce_on_create":false,"required_status_checks":[{"context":"CI required"}]},"ruleset_source_type":"Repository","ruleset_source":"szTheory/threadline","ruleset_id":21701781},{"type":"non_fast_forward","ruleset_source_type":"Repository","ruleset_source":"szTheory/threadline","ruleset_id":21701781},{"type":"deletion","ruleset_source_type":"Repository","ruleset_source":"szTheory/threadline","ruleset_id":21701781},{"type":"required_linear_history","ruleset_source_type":"Repository","ruleset_source":"szTheory/threadline","ruleset_id":21701781},{"type":"pull_request","parameters":{"required_approving_review_count":0,"dismiss_stale_reviews_on_push":false,"required_reviewers":[],"require_code_owner_review":false,"require_last_push_approval":false,"required_review_thread_resolution":true,"require_extra_approval_for_unattributed_changes":true,"allowed_merge_methods":["merge","squash","rebase"]},"ruleset_source_type":"Repository","ruleset_source":"szTheory/threadline","ruleset_id":21701781}]
```

**Exactly one required context, the string `CI required`.** `strict_required_status_checks_policy` is `false` — the D-14 trade, up-to-date requirement **OFF**. `bypass_actors` is `[]`, which is the other half of D-14: with no bypass actor, **administrators are enforced** (there is no one who can walk past it), and it is simultaneously the RESEARCH A3 empirical-first position — no bypass actor is configured, and one will be added only if a real release-please pull request is **observed** blocked. None has been observed, because no ruleset has yet been left in place.

Two fields GitHub added that the committed JSON did not specify — `do_not_enforce_on_create: false` and `allowed_merge_methods: ["merge","squash","rebase"]` — are platform defaults, recorded so a future reader diffing the committed JSON against the live rule set is not surprised.

The ruleset was then **deleted** (`gh api --method DELETE .../rulesets/21701781` → `DELETED`; `GET /rulesets` → `[]`), for the ordering reason above. `main` is left in its **pre-migration** state: classic protection only.

### D-14 before / after

| Setting | Before (classic — still live now) | After (ruleset — proven above, to be re-applied post-push) |
|---|---|---|
| Required contexts | 6: `Check formatting`, `Run Credo (strict)`, **`Run test suite`**, `Build ExDoc (dev)`, `Hex package tarball`, `Release metadata (version / changelog)` | 1: `CI required` |
| Up-to-date branch required (`strict`) | **`true`** | **`false`** (D-14) |
| Administrator enforcement (`enforce_admins`) | **`false`** — the owner could walk past the whole rule | **ON** — `bypass_actors: []`, nobody can |
| Linear history | `false` | `true` |
| Conversation resolution | `false` | `true` |

The `Run test suite` row is live proof that GREEN-08's hazard is not theoretical. Classic protection **requires a context named `Run test suite`, and CI no longer emits that name** — it emits `Run test suite (min)` and `Run test suite (current)`, as observed in `.planning/audits/198-matrix-name-observation.md`. That required context can never be satisfied again. It is exactly the configured-but-never-emitted deadlock half (b) of the verifier exists to catch, and it has been sitting on `main` unnoticed.

## Classic protection disposition

**Decision: DELETE the classic branch-protection rule for `main`, at the moment the ruleset is applied. The two are NOT deliberately kept.**

Rationale, recorded because the stacking behaviour is easy to get wrong:

1. **GitHub evaluates classic protection and rulesets and applies the UNION.** Keeping both means the classic rule's `strict: true` silently re-arms the up-to-date requirement D-14 deliberately turns off, and the classic rule's six contexts re-arm five names D-08 deliberately collapsed away — including the unsatisfiable `Run test suite`. The migration would achieve nothing while appearing to have succeeded.
2. **The `GET /rules/branches/main` endpoint reports ONLY ruleset rules.** Measured directly: with classic protection live and no ruleset present, that endpoint returned `[]`. So half (a) of the verifier, which reads that endpoint, is structurally blind to classic protection. A script that passed while a stale classic rule still applied would be worse than no script.

Because of (2), `bin/verify-branch-protection` carries a **third assertion block** that fails if classic protection exists at all. That is the executable form of this decision: the disposition cannot rot back to "both stack" without the verifier going red.

**Status: NOT YET APPLIED.** Classic protection is still live on `main` at the time of writing, and must not be deleted before the push — deleting it now would leave `main` momentarily unprotected for no benefit. The re-read of the effective-rules endpoint proving the outcome is therefore **not yet recorded**; see `## Not done`. Stating that plainly rather than pasting the pre-deletion read and calling it proof.

## Verifier teeth

| # | Edge | How it was induced | Result |
|---|---|---|---|
| 1 | **Half (a), empty-list edge** | Live state with no ruleset present (`GET /rules/branches/main` → `[]`) | **RED**, exit 1: `FAIL (a): szTheory/threadline@main has ZERO required status-check contexts. live: (empty) expected: [CI required] — An unprotected branch must not read as passing.` |
| 2 | **Half (a), singleton match** | Ruleset `21701781` live | **PASS** — execution proceeded past half (a) into half (b) |
| 3 | **Half (b), never-emitted edge** | Ruleset live; `main`'s head on origin is `67998e0b`, which predates the aggregate gate | **RED**, exit 1: `FAIL (b): no check run named "CI required" has ever been emitted on szTheory/threadline@main's head (67998e0b…)` |
| 4 | **Half (a), extra-context edge** | *(attempted — refused, see below)* | **NOT DEMONSTRATED** |

Edge 1 is the stronger of the two half-(a) failure modes and it fired on **real** live state, not a staged one. Edge 3 likewise fired against genuine live state: `main` really is protected-in-name against a check nothing has ever emitted.

**Edge 4 was attempted and could not be completed.** The temporary second-context mutation (`PUT /repos/.../rulesets/21701781`) was refused by the execution environment's own permission layer — not by GitHub. It is recorded as **not demonstrated** rather than assumed to work by symmetry with edge 1. The comparison it would exercise — sorted exact string equality over a unit-separator-joined list — is the same code path edges 1 and 2 already traverse, but "the same code path" is an argument, not a demonstration, and this artifact does not launder one into the other. **Outstanding: perform edge 4 when the ruleset is applied for real.**

## Archive tags on origin

**GREEN-12 durability: CLOSED.** Both tags pushed 2026-08-28, explicitly by name — never `git push --tags` — so no unrelated tag was published as a side effect.

```
$ git push origin refs/tags/archive/gsd/phase-166-unfreeze-token-lane-mechanism
 * [new tag]  archive/gsd/phase-166-unfreeze-token-lane-mechanism -> archive/gsd/phase-166-unfreeze-token-lane-mechanism

$ git push origin refs/tags/archive/backup/pre-release-cleanup-2026-05-08
 * [new tag]  archive/backup/pre-release-cleanup-2026-05-08 -> archive/backup/pre-release-cleanup-2026-05-08

$ git ls-remote --tags origin 'refs/tags/archive/*'
8bc69d937cf089c8c3e81a429380d39cc7189290  refs/tags/archive/backup/pre-release-cleanup-2026-05-08
50374eb71111f464154e99f1b6eb92d0067d5e97  refs/tags/archive/backup/pre-release-cleanup-2026-05-08^{}
795f7a859878b1b99fc5dd07c0cd5bef166d388e  refs/tags/archive/gsd/phase-166-unfreeze-token-lane-mechanism
dd5b48be6f4c175f5dd7cecee19dbeb2f9a2934a  refs/tags/archive/gsd/phase-166-unfreeze-token-lane-mechanism^{}
```

Both dereference (`^{}`) to the commits recorded in `.planning/ARCHIVE-REGISTER.md`: `50374eb7…` and `dd5b48be…`. Both remote objects are annotated tags — the tag object SHA differs from the commit SHA — so the full D-31 archive messages travelled with them.

**No milestone tag was published as a side effect.** `git ls-remote --tags origin` lists `v0.1.0`–`v0.9.0`, `v1.8`, `v1.13`, `v1.22`, `v1.30` — every one of which was already on origin before this plan ran — plus the two `archive/*` tags. `v1.35`, `v1.40` and `v1.41` remain local, so the deferred milestone-tag question is still genuinely open rather than pre-empted.

The ordering constraint was honoured: the credential verdict was confirmed `PROCEED` and both tag objects were resolved locally (`git cat-file -t` → `tag`) **before** either push, and neither was pushed as a convenience alongside anything else.

## GREEN-07, honestly

GREEN-07 has two halves. They are reported separately because they have different answers.

### Half 1 — "`origin/main` contains every local commit": **NOT DONE** (blocked — see `## Not done`)

### Half 2 — "the latest CI run on `main` concludes `success` in ≤ 20 minutes": **NOT MET**

This is not a scheduling problem and it will not be fixed by waiting for a run. **The suite is red**, measured on this tree at this commit immediately before execution:

| Check | Result |
|---|---|
| `mix compile --warnings-as-errors` | exit 0 |
| `mix format --check-formatted` | exit 0 |
| `mix test test/threadline/ci_topology_contract_test.exs` | 12 tests, 0 failures |
| **`mix test` (full suite)** | **1380 tests, 80 failures (1 excluded), exit 2** |

Those 80 are the honest baseline Plan 198-04 established and deliberately refused to manufacture away: **79** real test-side defects in the unprefixed-query / `search_path` family spanning 15 files, plus **1** `CONTRIBUTING.md` List 1 drift (`only-in-jobs=["verify-capture", "verify-mechanical"]`), which remains **unowned**. Nothing in Phase 198 fixes them; 198-04 recorded that fixing them is "a plan of its own, and outside this plan's declared files_modified". Wave 4 did not move the number, and this plan re-measured the List 1 drift as still red.

`CI required` aggregates twelve jobs including `verify-test`. With `verify-test` red on both lanes, `CI required` is red. Therefore **the latest run on `main` cannot conclude `success`**, whatever its wall clock.

**This half is recorded as NOT MET. It was not worked around.** No test was skipped, excluded, tagged out, or asserted away; no lane was downgraded to `continue-on-error`; the required-check definition was not loosened so that a red suite would score as passing. A manufactured green is a failure of this plan even if CI reports success.

**The plan's `<objective>` claim that "every gate that precedes it is already green" is false**, and is corrected here rather than inherited.

**No wall-clock measurement is recorded**, because the push that would have produced a run to measure did not happen. The measurement is still worth taking when the push lands — the conclusion will be `failure`, and the elapsed time is evidence about post-surgery CI cost regardless of the conclusion. Boundary convention, stated now so it is not decided after the fact: **exactly twenty minutes is within budget.**

The sharding fallback is **not evaluated**, because the number that would settle it — the measured post-surgery wall clock on `main` — does not exist yet. Recording "sharding not needed" without that number would be a guess wearing a verdict's clothes.

## Not done

Recorded plainly so a later reader does not mistake this artifact for a completed migration.

| Item | Status | Why |
|---|---|---|
| Push 636 commits to `origin/main` | **BLOCKED** | The execution environment's permission layer refused `git push origin main`. **Not** GitHub, **not** secret-scanning push protection, **not** branch protection — a local harness gate. Nothing was bypassed and nothing was worked around. `git log origin/main..main` still lists 636 commits. |
| Post-push run on `main`, measured | **NOT DONE** | Depends on the push. |
| Apply the ruleset live and leave it | **NOT DONE** | Proven and deleted (above); must follow the push, per the ordering correction. |
| Delete classic protection + paste the re-read | **NOT DONE** | Must accompany the ruleset application. |
| Verifier edge 4 (extra-context teeth) | **NOT DONE** | Environment refused the temporary ruleset mutation. |
| `bin/verify-branch-protection` exiting 0 | **NOT POSSIBLE YET** | Half (b) requires a `CI required` check run on `main`'s head, which requires the push. |

### Exact commands to finish, in order

```bash
# 1. Publish. Fast-forward — origin/main (67998e0b) is a strict ancestor of local main.
git push origin main

# 2. Watch and MEASURE the run. It will conclude `failure`; record it anyway.
gh run list --branch main --limit 5
gh run view <id> --json conclusion,startedAt,updatedAt,jobs

# 3. Apply the protection migration, in this order.
gh api --method POST -H "Accept: application/vnd.github+json" \
  /repos/szTheory/threadline/rulesets --input .github/rulesets/main.json
gh api --method DELETE /repos/szTheory/threadline/branches/main/protection
gh api repos/szTheory/threadline/rules/branches/main   # paste this response into this artifact

# 4. Prove it.
bash bin/verify-branch-protection
```

**Step 3 has a consequence that must be accepted with open eyes rather than discovered later:** once the ruleset is active with `bypass_actors: []` and `CI required` red, **nothing can merge into `main`** — not a pull request, not an administrator, not release-please's PR #26. That is GREEN-08 working as designed, and it is simultaneously a hard operational lock until the 79 test-side defects are retired. The honest remedies are (a) fix the 79, or (b) add a bypass actor as an explicit, recorded, temporary decision. Silently relaxing the required check is not a remedy.

### A note on the merge route

The plan says to land the commits by merging staging pull request #27. **That route cannot satisfy the plan's own must-have truth.** Measured: PR #27's head `2d7abc4a` is an ancestor of local `main` but **22 commits behind it**, so merging it as-is leaves 22 commits unpushed and `git log origin/main..main` non-empty. Worse, the ruleset's `required_linear_history` rule forbids a merge commit, leaving only squash — which collapses 636 commits of planning history into one, destroying the very record this phase authorised publishing — or rebase, which rewrites every SHA.

A plain fast-forward `git push origin main` is the only route that lands **every** commit with its history intact, and it is what step 1 above does. Recorded as a deliberate deviation from the plan's stated mechanism, in service of the plan's stated truth.

---
*Phase: 198-green-bringup · Plan 07*

