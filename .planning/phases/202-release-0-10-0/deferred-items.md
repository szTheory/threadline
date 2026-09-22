# Deferred items — Phase 202

## Intermittent: `Threadline.OperatorSurface.CriticTrustTest`

- **Test:** `critic.measure rejects bidirectional canonical overlap without prefix confusion`
- **Observed during:** Plan 202-01 execution, 2026-09-22
- **Frequency:** 2 failures in 6 consecutive `mix test test/threadline/` runs; passes at `--seed 0`.
- **Why deferred:** Out of scope for 202-01. This plan touches
  `lib/threadline/storage_schema.ex`, `lib/mix/tasks/threadline.install.ex`,
  `guides/getting-started-saas.md`, `mix.exs`'s `verify_hex_evaluator/1`,
  `.gitignore`, `bin/with-rehearsal-registry`, the hex evaluator fixture, and two
  doc contract tests. None of them reach critic trust.
- **Suspected mechanism (unverified):** the test builds scratch trees under
  `_build/critic-trust-path-tests/<label>-<random>/`; a collision or cleanup race
  across concurrent runs is the obvious candidate. Not investigated.
- **Next step:** reproduce under `mix verify.flake` and record the failing seed
  before attempting a fix.

### Orchestrator follow-up (2026-09-22, post-wave-1 gate)

- Full suite after Plan 01: `mix verify.test` → **1679 tests, 0 failures, 1 excluded**.
- `mix test test/threadline/operator_surface/critic_trust_test.exs --repeat-until-failure 25`
  → **25/25 green** (seeds 156679 … 850554). The file is NOT flaky in isolation.
- Therefore the suspected mechanism narrows to **cross-file interaction inside a full-suite
  run** — most likely concurrent scratch trees under `_build/critic-trust-path-tests/<label>-<random>/`
  racing with another test's `_build` access, not a collision within this file's own runs.
- Still unfixed and still out of 202-01's blast radius. **Re-check before the 202-05 publish
  gate** — "green by construction" cannot rest on a suite with an unexplained intermittent.

## From 202-02 (2026-09-22)

- **Stale hex-evaluator prose.** `guides/evaluating-threadline.md:41` and
  `guides/adoption-evidence-playbook.md:15` both claim `mix verify.hex_evaluator`
  depends on threadline "from hex.pm — not a path dep". Plan 01 changed the
  default to a local rehearsal registry built from this tree's own tarball, so
  the claim is now false. Out of scope for 202-02 (not a version-bearing line and
  not in that plan's file list). Owner: Plan 03's documentation pass.

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
