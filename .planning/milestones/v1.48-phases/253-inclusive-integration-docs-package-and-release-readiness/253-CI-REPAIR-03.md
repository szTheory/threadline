# Third natural CI and focused runtime correction

[Third run](https://github.com/szTheory/threadline/actions/runs/43528462523) at `9e1aa79fadf2c2ee8a143966b4b1509860057f66`: all13 non-browser gates pass. Desktop192 passes/six skips and mobile187 passes/11 skips stop at the unchanged five-failure cap. All five failures per project are the Before/After axis ≥14px assertion observing12px. Receipt skips/aggregate fails; no required-CI or dedicated real2x acceptance. Original logs/diagnostic/timing ZIPs are retained privately with matching GitHub digests.

## Cause and correction

The previous source-only forward review missed inheritance. `06_layout_primitives.css:375–379` sets `.tl-change__field` to the approved monospace label12px; Before/After spans inherit it, while adjacent values override to dense13px. Reviewers explicitly withdrew the unsupported body16px assurance. One source line now checks exact12px and names its label role. Production CSS, runtime, targets and other action-text constraints remain unchanged.

The direct arrow remains present whenever Before is rendered, so the existing wide pairing/narrow stacking contract is preserved. No production selector or geometry assertion was relaxed.

## Changed approach: actual owner cases before another push

Parent ran20 selected whole cases across headless desktop/mobile with retries0, maxFailures1 and a fresh separately owned25315 database. All20 passed once, with zero skips/unexpected/flaky results. The full test bodies reached later selection, paired-wide/stacked-narrow values, focus, hit target and overflow checks. Raw report `ci3-scoped-browser-03-reporter-env.json`, exit0 receipt `ci3-scoped-browser-03.json`, source/harness hashes and exact names are bound by `ci-fix3-review-input-01.json` under `.planning/tmp/253-recovery/`. Private copies differ only in module resolution and a root hook installing both clipboard doubles before navigation; original test-body hashes match. This is selected runtime proof, not a full/default browser/root run, real2x or native clipboard proof.

Setup failures stay visible: first app stopped cleanly when sandbox PID inspection was denied; an ESM package boundary was added after discovery failed; basic Ecto setup had no demo user, so the named `mix demo.seed` populated only the fresh scoped database. The confirmed-user preflight succeeded. A supplementary SQL correlation query used a nonexistent transaction column and the shell continued after its assertion; no successful correlation SQL preflight is claimed. Actual named demo-seed success and complete browser cases establish the fixture. Future dependent setup/retests must fail fast; these failed receipts remain preserved, not relabeled as product failures or green runs.

The same independent code reviewer verifies the one frozen source hash, unchanged test bodies plus isolated harness differences and actual20 first-attempt passes; status clean/zero findings. Same security reviewer retains SECURED24/24, zero open/no accepted risks. UI reviewer confirms the12px ancestor cascade and keeps wide/narrow geometry requirements. No new pixels are warranted by a test-only correction. Both owned app and isolated PostgreSQL stopped cleanly after checks; original paired fixture was untouched.

Next: parent pushes the reviewed one-line correction and monitors existing required CI. No user action, renewed local full-repeat/realzoom/native/foreground authority, merge/publication/version/tag or risk acceptance is inferred. Phase253/milestone remain incomplete.
