# Deferred items — Phase 202

## Intermittent: `Threadline.OperatorSurface.CriticTrustTest`

- **Test:** `critic.measure rejects bidirectional canonical overlap without prefix confusion`
  status: acknowledged
- **Observed during:** Plan 202-01 execution, 2026-09-22
  status: acknowledged
- **Frequency:** 2 failures in 6 consecutive `mix test test/threadline/` runs; passes at `--seed 0`.
  status: acknowledged
- **Why deferred:** Out of scope for 202-01. This plan touches
  `lib/threadline/storage_schema.ex`, `lib/mix/tasks/threadline.install.ex`,
  `guides/getting-started-saas.md`, `mix.exs`'s `verify_hex_evaluator/1`,
  `.gitignore`, `bin/with-rehearsal-registry`, the hex evaluator fixture, and two
  doc contract tests. None of them reach critic trust.
  status: acknowledged
- **Suspected mechanism (unverified):** the test builds scratch trees under
  `_build/critic-trust-path-tests/<label>-<random>/`; a collision or cleanup race
  across concurrent runs is the obvious candidate. Not investigated.
  status: acknowledged
- **Next step:** reproduce under `mix verify.flake` and record the failing seed
  before attempting a fix.
  status: acknowledged

### Orchestrator follow-up (2026-09-22, post-wave-1 gate)

- Full suite after Plan 01: `mix verify.test` → **1679 tests, 0 failures, 1 excluded**.
- `mix test test/threadline/operator_surface/critic_trust_test.exs --repeat-until-failure 25`
  → **25/25 green** (seeds 156679 … 850554). The file is NOT flaky in isolation.
- Therefore the suspected mechanism narrows to **cross-file interaction inside a full-suite
  run** — most likely concurrent scratch trees under `_build/critic-trust-path-tests/<label>-<random>/`
  racing with another test's `_build` access, not a collision within this file's own runs.
- Still unfixed and still out of 202-01's blast radius. **Re-check before the 202-05 publish
  gate** — "green by construction" cannot rest on a suite with an unexplained intermittent.
  status: acknowledged

## From 202-02 (2026-09-22)

- **Stale hex-evaluator prose.** `guides/evaluating-threadline.md:41` and
  `guides/adoption-evidence-playbook.md:15` both claim `mix verify.hex_evaluator`
  depends on threadline "from hex.pm — not a path dep". Plan 01 changed the
  default to a local rehearsal registry built from this tree's own tarball, so
  the claim is now false. Out of scope for 202-02 (not a version-bearing line and
  not in that plan's file list). Owner: Plan 03's documentation pass.
  status: acknowledged

### Adjudicated by 202-03 (2026-09-22): still deferred, with a newly measured reason

Plan 03 read the stale hex-evaluator prose item above and declined to fix it.
The claim IS false — Plan 01 changed the default resolution to a local rehearsal
registry built from this tree's own tarball — but the two sentences carrying it
are **install-pin lines**, not ordinary prose:

```
guides/evaluating-threadline.md:41      {:threadline, "~> 0.9.0"} from hex.pm — not a path dep
guides/adoption-evidence-playbook.md:15 {:threadline, "~> 0.9.0"} from hex.pm, not a path dep
```

Both match `version_truth_doc_contract_test.exs`'s `@pin_regex` and are 2 of the
6 pin sites `mix release.pins` rewrites (confirmed this session: a simulated
`0.10.0` bump rewrote exactly these 6 files). Correcting the sentence truthfully
means deleting the pin literal from it, because the evaluator fixture no longer
carries a version literal at all — which would drop the pin inventory from 6 to
4 and make 202-02's measured "all six documented install pins" narrative stale.

That is a release-tooling change, not a documentation edit, and it is outside
this plan's file list and blast radius. Both files also render in the published
tarball, so the correction is worth making — just not as an unreviewed side
effect of a changelog plan.

- **Owner:** a follow-up with `mix release.pins` in scope (202-05 publish gate at
  the earliest, or its own maintenance item).
- **Next step:** decide whether the evaluator's install shape is still a
  pin-shaped claim at all. If it is not, remove the literal from both sentences
  and re-measure the pin inventory in the same change.
  status: acknowledged

### Flake re-check before the 202-05 publish gate (2026-09-22)

status: acknowledged

Status: **NOT REPRODUCIBLE. Mechanism unproven. Closed as unresolved, not as fixed.**

Evidence gathered:

- 3 consecutive full-suite runs post-Wave-3: 1692 tests, 0 failures each.
- Earlier: 25/25 green for `critic_trust_test.exs` in isolation under random seeds.
- Combined with the post-Plan-01 run, that is 4 consecutive full-suite greens since
  the original report (2 failures in 6 runs).

Hypotheses tested and rejected:

- **Timestamp/RNG in the writer** — rejected. `critic.measure` has no `utc_now`,
  no `:rand`, no shuffle; its only nondeterminism is a monotonic temp-file suffix,
  so the ledger write is deterministic given inputs.
- **Cross-file contention on the shared fixture** — rejected. The other two modules
  referencing `design-system-ledger` (`operator_surface_fixture_contract_test.exs`,
  `stress_router_test.exs`) write only into their own private temp repos.
- **Leftover scratch-tree accumulation** — rejected. Ran the suite with 517 leftover
  `_build/critic-trust-path-tests/` dirs present, growing to 535; green throughout.

Remaining unexercised suspect (documented, not proven): the test plants a
self-referential symlink inside its own scratch base (`File.ln_s!(base, alias_output)`),
a loop under the directory `critic.measure` walks. Filesystem read order over that loop
is the only candidate nondeterminism left standing.

Separate hygiene defect found while investigating: `_build/critic-trust-path-tests/` is
**never cleaned up** — 535 scratch trees and counting, one per test per run. Not a
correctness bug, not release-blocking, worth a cleanup task.

**Bearing on the release:** 202-05 may NOT claim the suite is "green by construction."
The honest claim is "green in 4/4 consecutive runs; one prior intermittent remains
unexplained."

### CORRECTION (2026-09-22, Task 1 rehearsal) — the flake mechanism IS proven

status: acknowledged (v1.41 close, 2026-09-24)

The entry above is **wrong** where it rejects the leftover-scratch-tree hypothesis and
concludes "not reproducible." Superseded by direct evidence.

Mechanism, proven:

- `critic_trust_test.exs:1142` names its scratch dir with a bare
  `System.unique_integer([:positive])`. That counter is unique **per BEAM instance**
  and **restarts on every `mix test`**.
- `_build/critic-trust-path-tests/` is never cleaned — 542 dirs, oldest Sep 13.
- Proof of reuse: `root-overlap-132290` (mtime Sep 22 09:50) and
  `interrupted-measure-132290` (mtime Sep 22 06:18) share integer 132290 across two
  different runs and two different labels. A reused counter range, not a race.
- On collision the scratch dir already contains `output-alias` from the earlier run,
  so `File.ln_s!` raises `File.LinkError`.

Why the earlier rejection was wrong: it tested whether the *volume* of leftovers was the
trigger (517 -> 535 dirs, green throughout). Volume is not the trigger; **counter reuse**
is. Three green runs simply did not draw a colliding integer. The symlink-loop
read-order suspect is also withdrawn — it was never the cause.

Consequences:

- Collision probability rises monotonically with every run until `_build` is cleaned.
  `mix clean` or deleting `_build/critic-trust-path-tests/` resets it.
- **CI is only safe here if its `_build` cache does not carry prior scratch trees.**
  Verify that before any "green by construction" claim.
- Real fix: seed the dir name from something run-unique (pid/timestamp/`mktemp`), and
  clean up the tree in an `on_exit`.

## 202-REVIEW disposition after #46 (recorded 2026-09-24, Phase 205)

This records the status of each `202-REVIEW.md` finding after PR #46 (`45532778`, v0.10.1). It does not change `202-REVIEW.md`. Each `resolved` line was checked against `git show 45532778` and the merged files on the milestone branch.

- **CR-01** resolved: #46 (45532778) moved the storage-schema advice to after generation. It now names the files just written, says to delete them and then re-run, and is withheld when nothing was written. 4 tests in `test/mix/tasks/threadline/install_test.exs` cover it.
  status: resolved
- **WR-01** resolved: #46 checks out `sync-release-pr-pins` with `persist-credentials: false`, binds `PUSH_TOKEN` only in the push step, and scopes the job to `contents: write`. This is now pinned by the 205-01 test in `test/threadline/release_control_plane_contract_test.exs`.
  status: resolved
- **WR-02** resolved: #46 gives the job its own concurrency group `sync-release-pr-pins` with `cancel-in-progress: true`, pinned by the same 205-01 contract test.
  status: resolved
- **WR-03** resolved: #46 starts `bootstrap-release-pr-ci`'s `if:` with `always()`, so a failed pin sync still produces a red CI run. Pinned by the same 205-01 contract test.
  status: resolved
- **WR-05** resolved: #46 changed the `guides/configuration-and-commands.md` default to `"public"`, and `test/threadline/storage_schema_test.exs` now ties the documented default to the resolved one.
  status: resolved
- **WR-04** open: `bin/with-rehearsal-registry:118` still picks the tarball with `ls -1 threadline-*.tar | head -n 1`, so a stale gitignored tarball can still be served locally.
  status: open
- **WR-06** open: `legacy_public_schema_test.exs` still reads through `Repo.aggregate/2` and `Repo.one!/1` with no prefix, so it never consults the storage schema.
  status: open
- **WR-07** open: `bin/verify-environment-protection` still does not check that `HEX_API_KEY` is an environment secret of `production-hex` rather than a repository secret.
  status: open
- **IN-01** open (info): the rehearsal's signal trap can exit 0 on INT/TERM, and a failure before the trap is set leaks the temp parent.
  status: open
- **IN-02** open (info): the rehearsal checks HEAD, not the working tree, and does not warn when the tree is dirty.
  status: open
- **IN-03** open (info): unknown `THREADLINE_BUMP_REHEARSAL_INJECT_DEFECT` values are silently ignored.
  status: open
- **IN-04** open (info): CHANGELOG-GENERATED.md keeps a placeholder that is now false, and its header claims hand edits are overwritten.
  status: open
- **IN-05** open (info): the version-marker ownership guards only recognise markers on the same line.
  status: open
- **IN-06** open (info): the rehearsal registry's port probe cannot tell its own server from a foreign listener.
  status: open
- **IN-07** open (info): the CHANGELOG's "Breaking changes: None" sits next to a raised dependency floor and a narrowed callback.
  status: open

All five resolved items reached the milestone branch in the 205-01 merge commit `0d8ced0c`. #46 is not an ancestor of the pre-merge HEAD `ca99ff7c`.
