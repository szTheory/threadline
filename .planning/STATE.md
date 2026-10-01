---
gsd_state_version: "1.0"
milestone: v1.44
milestone_name: "Behavioral Depth: Properties, Twins, Telemetry"
current_phase: 226
current_phase_name: Pure Property Tests and Run Budget
status: planning
stopped_at: Completed 225-04-PLAN.md
last_updated: "2026-10-01T05:09:14.287Z"
last_activity: 2026-10-01
last_activity_desc: Phase 225 complete, transitioned to Phase 226
progress:
  total_phases: 7
  completed_phases: 2
  total_plans: 8
  completed_plans: 8
  percent: 29
state_head: 9b5dd58bf0d3c3329f3b18ab34f0f6220e2a9db6
---

# Project State: Threadline

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-09-30 after v1.44 milestone start)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current focus:** Phase 225 — Suite Baseline and Partitioned CI

## Current Position

Phase: 226 — Pure Property Tests and Run Budget
Plan: Not started
Status: Ready to plan
Last activity: 2026-10-01 — Phase 225 complete, transitioned to Phase 226

Progress: [███░░░░░░░] 2 of 7 v1.44 phases complete ([███░░░░░░░] 29%). Phase 224 verified passed 9/9 (2026-09-30). Phase 225 verified passed 5/5 (2026-10-01): partitioned CI test step (bin/ci-test-partitions, weighted file assignment, N=4, colocation groups), Run tests 37.5-65.3% faster with runner-minute proxy down 12.5-50% over CI runs 36808706517 and 36810081717 vs baseline 36730596489; telemetry auth tests async via attach_telemetry!/1; Flake Detection run 36810083586 pass (resized to 11 repeats); review 0 critical/3 warning/1 info, warnings fixed cd20d3fa; landing via PR #71. Phases: 224 Capture and Bench Fixes, 225 Suite Baseline and Partitioned CI, 226 Pure Property Tests and Run Budget, 227 DB-Backed Property Tests, 228 Telemetry, 229 Adopter API and Health Additions, 230 Rebalance, Net-Suite Check and 0.12.0. Next: /gsd-discuss-phase 226. SUITE-01's baseline is pinned to the milestone base `dd780e68`.

**v1.44 start (2026-09-30):**

- Branch `milestone/v1.44` was cut from origin/main `dd780e68` (the v1.43 landing, #70). It has no upstream, and the milestone tag `v1.43` is local only.
- Carried from the v1.43 closeout: re-check the `latest` lane pins (Elixir 1.20.4 / OTP 29.1.1 / PG 18.6, set 2026-09-28 in phase 220) against builds.hex.pm and Docker Hub in this milestone's landing PR.

## PROOF-01 outcome (2026-08-26, maintainer-ratified in-session)

- **REJECT (evidence + density)**: three edit variants never beat the noise floor (Δ −1/−2; v3 targeted verdict unstable = VOID per [196-D1]). Edits kept as ordinary unratified UI cleanup (2eca4208) — no signoff claim.
- **ACCEPT (retention + density, pivot)**: duplicated status banner + destructive self-label removed (c6f9355e) → Δ +7 > noise 4.5, no blocking regression, page.retention.happy floor green, oracle stable. First `ratchet.signoffs` forward_only_accept entry + append-only pin (f1610d87).
- Loop hardening: ROUTE_PAGE_TWIN all five routes, dark route-lane maskColor (83db3918).
- Deferred to 197 debt register: verdict cache not screenshot-keyed; score-after-edit overwrites the before pole; Tier-A recapture drift (36k-px fullPage shots vs clipped refute poles); evidence structural density (IA pass).
        Final trust panel (`design-system-ledger.json → critic_trust`): brand_fidelity ρ0.93, density
        ρ0.84, typography ρ0.77, rhythm ρ0.76 = 4 VALIDATED (the blocking panel); color_contrast ρ0.698

        + hierarchy ρ0.42 = advisory (never block; verify vs ground truth — they hallucinate specifics).
        Phase 196 = forward-only net-positive gate, ratified as: GATE-01 RELATIVE/ranking gate on the
        4-lens panel; MechanicalChecker (`verify.mechanical`) = deterministic hard floor, gates on the
        `page.*` Tier-A twin (route.* excluded, mechanical_checker.ex:155); synthetic oracle = held-out
        true-north (GATE-03 divergence halt); GATE-04 guard-the-guards in critic_trust_test.exs
        (`ratchet.signoffs` append-only); GATE-02 mechanical fixes = surface-a-diff this phase (true
        auto-write → 197); PROOF-01 = wire loop + CONTRIBUTING.md runbook + ONE real human-ratified
        improvement on the weakest /audit page (mid-phase checkpoint:decision). Deferred to 197:
        PROOF-02 (2-3 pages), PROOF-03 (adversarial closeout), PROOF-04 (debt register). Locked
        decisions in `196-CONTEXT.md` [196-D1..D9]. ~85% of the phase is WIRING existing machinery.
Last activity: 2026-08-27

v1.43 closing progress record (superseded by the v1.44 Progress line under Current Position): [██████████] 10 of 10 v1.43 phases complete ([██████████] 100%) (214–223; 223 verified passed 4/4 2026-09-29: B+C landed #66, 0.11.2 published to Hex via #60 override + #67 + sync #69; phase-223 code review 0/5/1 recorded open in 223-REVIEW-DISPOSITION.md): 214 Baseline Measurement verified passed 32/32 on re-verification after gap closure 214-04; 215 Supply Chain Gate verified passed 7/7 on re-verification after gap closure 215-05/215-06 (CR-01 global hex.config refusal, WR-02 deps.get --check-locked); 216 CI Platform Currency verified passed 3/3 (43/43 truths) 2026-09-27 after gap closure 216-08 (release sparse-checkout regression), landed via squash #55 + #57, 0.11.1 released (#56, run 36323594205); OPEN: 216 review CR-01 (smoke-published write token + persisted credentials, pre-existing) awaiting maintainer decision, distribution-sync PR #59 unmerged; 217 Repo Hygiene verified passed 5/5 on re-verification 2026-09-27 after gap closure 217-06 (CR-01 family-6 single-segment encoded path, WR-01/WR-03/IN-01) + 217-07 (CONTRIBUTING machine-local path placeholder convention + guard hint, WR-02 colon-safe parsing); HYG-01..04 Complete; round-2 review 0 critical/4 warning/2 info recorded open in 217-REVIEW-DISPOSITION.md (triage before milestone close; R2-WR-04 Linux-encoded dirs vs CONTRIBUTING claim is the one to act on); 218 planned 2026-09-27 (8 plans, serialized waves 1–8; plan-check passed after 3 revision rounds + 1 targeted fix); 218 execution started 2026-09-27 (sequential, main tree); 218-01 complete 2026-09-27 (ECON-03 PAT-absence guard on bootstrap-release-pr-ci + contract mutation controls, 26/33 plans); 218-02 complete 2026-09-27 (ECON-02 script half: bin/upsert-ci-issue --close + deps-health close-on-clean; #28/#36 close refused by classifier, handed off to maintainer / 218-06/07 wiring, 27/33 plans); 218-03 complete 2026-09-27 (ECON-05: fail-closed Dialyzer slice verifier, :live_dialyzer excluded by default and run only in verify-dialyzer via mix verify.dialyzer_slice, ci.all dedup exemption, timeout 12; 28/33 plans); 218-04 complete 2026-09-27 (ECON-06: verify-mechanical, verify-docs and verify-hex-package removed plus verify-capture's duplicate mechanical step, ci-required 16 -> 13, still-caught-by bullets + dominance pins with mutation controls, branch protection read-only confirmed CI required only; 29/33 plans); 218-05 complete 2026-09-27 (ECON-01 core: Flake Detection weekly Monday 07:00 UTC + dispatch, 15 repeats under timeout(1) 55m / step 58 / job 70, inconclusive on budget expiry, bin/ci-sha-gate green-SHA skip (schedule only) + broken-upstream, fail open to run; issue text + close-on-pass follow in 218-06; 30/33 plans); 218-06 complete 2026-09-27 (ECON-01 closed + ECON-02 flake wiring: per-classification issue text driven by the classifier reason, inconclusive/broken-upstream arms, close-on-pass via upsert-ci-issue --close, OS-family cache-key guard over every workflow; 31/33 plans); 218-07 complete 2026-09-27 (ECON-04 + ECON-02 Browser-full wiring: bin/browser-full-projects derives config minus ci.yml projects, Browser-full runs only graded/refute/route/storybook-capture, partition contract + mutation/comment controls, nightly green-SHA skip via bin/ci-sha-gate, close-on-green via upsert-ci-issue --close; #28/#36 still open pending first green runs; 32/33 plans); 218-08 complete 2026-09-28 (ECON-07: copied 214 tools, phase gate green, maintainer landed branch land/v1.43-217-218 as draft PR #60 with 3 Rule-1 landing fixes (refute-capture declares tier-a-capture, published .planning snapshot scrubbed, flake lane resized 15 -> 12 repeats); 218-REMEASURE.md cites 39 run IDs: per ci.yml run p50 46.3 -> 44.4 unrounded / 55 -> 53 billed (attributable 43.7 / 51), critical path 623 -> 643 s not credited, verify-dialyzer +74 s from PLT-hit samples only, flake pass 45.7 min (run 36364688861), Browser-full 6.4 min (run 36363979144); #28 and #36 CLOSED by those green dispatch runs; ECON-05 literal slice line not in CI log (deferred); 33/33 plans); v1.42 closed at 153/153 plans (198–207) 218 CI Economy: Remove Waste verified passed 12/12 2026-09-28 (ECON-01..07 Complete; landing draft PR #60 green incl. 3 landing deviations — refute-capture tier-a dependency, published .planning scrub+sync, flake 15->12 repeat resize — and review WR-01..06 fixed, WR-03 partial per D-04; next /gsd-plan-phase 219); 219 context gathered 2026-09-28 (research-then-recommend, 4 researchers, D-01..D-26 in 219-CONTEXT.md; maintainer approved measurement dispatch top-ups up to ~7 runner-h; 219 planned 2026-09-28 (3 plans, serialized waves 1–3: 01 contract-first build_cache_errors/2 + mutation controls, 02 atomic ci.yml/CONTRIBUTING/live-contract commit, 03 measurement with maintainer push/dispatch checkpoint; plan-check 3 revision rounds + 1 targeted fix, decision coverage 26/26; next /gsd-execute-phase 219); 219 execution started 2026-09-28 (sequential, main tree); 219-01 complete 2026-09-28 (CACHE-01 contract first: build_cache_errors/2 in ci_workflow_parity_contract_test.exs, D-17 security subset asserted live, fixture + hybrid proven clean, 65 mutation controls over 30 rule fragments, live-needle controls, docs parity; old _build refute untouched for plan 02; 4 test commits; 34/36 plans); 219-02 complete 2026-09-28 (CACHE-01 static half live: exact-keyed deps-only root and example _build caches in verify-test, verify-pgbouncer-topology (restore-only), verify-example-browser and verify-capture, no-optional deps cache removed, CONTRIBUTING ### Dependency build cache + runbook, build_cache_errors/2 + all controls + YamlElixir anti-drift asserted on the live tree; one ci commit cfa615a9; 35/36 plans; next 219-03 measurement behind a maintainer push/dispatch grant); 219 landing 2026-09-28: mint 1.11.0 advisory fix (1ee0e352, CHANGELOG Unreleased), 219 commits cherry-picked onto land/v1.43-217-218 / PR #60 (option a, maintainer-authorized push/PR/dispatch); first PR run 36446346094 green, cold (all root/example misses, current-lane example in-run hit); plan 03 collection pending. 219-03 complete 2026-09-28 (CACHE-01 measured: 10 ci.yml runs of the 219 code on PR #60 / land branch, 2 cold + 8 warm labelled from committed JSON; warm run 39.3 unrounded / 49 billed runner-min vs 44.4 / 53 post-218 and 46.3 / 55 BASE-01; critical path 643 -> 547 s; Test (current) -116 s, PgBouncer -42 s, Browser E2E -96 s, Capture noise-level, Test (min) job saving not demonstrated (suite slowdown); miss overhead <= 3 s; build-v1 78.8 MB; 219-REMEASURE.md cites 30 run IDs; 36/36 plans; next phase 219 verification); 219 Deps-Only Build Cache verified passed 4/4 2026-09-28 (CACHE-01 Complete; landed on PR #60 via option (a) with mint 1.11.0 advisory fix; 2 cold + 8 warm CI samples, critical path −76 s vs BASE-01 / −96 s vs 218, −6 billed runner-min/run vs BASE-01; review WR-01..03 + IN-01..04 all fixed, CI run 36465241600 green; next /gsd-discuss-phase 220); 220 context gathered 2026-09-28 (research-then-recommend, 3 researchers, D-01..D-18 in 220-CONTEXT.md; exact pins Elixir 1.20.4 / OTP 29.1.1 / PG 18.6; 6 known 1.20 lib warnings fixed pre-spike; spike = real landing commit on spike/220-latest via ci.yml dispatch; maintainer accepted +~6 billed runner-min/run, trim in 222; next /gsd-plan-phase 220).; 220 planned 2026-09-28 (4 plans, serialized waves 1–4: 01 tracer D-08 warning fixes + local 1.20.4/29.1.1/PG 18.6 pre-spike, 02 lane: latest row + latest_row_errors/2 + D-15 voting_lane_errors/1 + D-16 postgres_image_errors/1 + docs, 03 spike dispatch behind maintainer push/dispatch grant → 220-SPIKE.md GREEN|NOT YET, 04 land outcome behind landing grant; plan-check passed first pass, decision coverage 18/18; next /gsd-execute-phase 220). 220 execution started 2026-09-28 (sequential, main tree); 220-01 complete 2026-09-28 (six Elixir 1.20 dead-code warnings removed in 17a7faa5; pins re-checked live, still Elixir 1.20.4 / OTP 29.1.1 / PG 18.6; local pre-spike on 1.20.4/29.1.1 vs PG 18.6: 2509 passed, 0 failures; committed toolchain green); 220-02 complete 2026-09-28 (voting lane: latest row 1.20.4/29.1.1/PG 18.6 + latest_row_errors/2, voting_lane_errors/1, postgres_image_errors/1 with mutation controls + tested-on docs in commit A 77ff2392; re-pin closeout line in 5a037db2; ci.all green on re-run after environmental too_many_connections; next 220-03 spike under maintainer grant); 220-03 complete 2026-09-28 (spike GREEN: one dispatch, run 36484105399 on spike/220-latest tip 4a32cbf6, min/current/latest + CI required all success; latest lane OTP-29.1.1 / v1.20.4-otp-29 / postgres:18.6, 2513 passed; cold run 58 billed min, latest job 7; 1/2 pushes, 1/3 dispatches used; next 220-04 landing on PR #60 under maintainer grant); 220-04 complete 2026-09-28 (GREEN landed: land/v1.43-217-218 fast-forwarded fcb22e00 -> 4a32cbf6 by the orchestrator under maintainer authorization after the classifier blocked the delegated push; PR #60 run 36487483472 all 16 jobs success incl. CI required + Run test suite (latest), 53 billed min cold; remote spike branch deleted, worktree cleaned; 220-03 tree-equality proof corrected (zsh word-splitting made it vacuous; re-run under bash: only mix.exs @version differs, pre-existing 0.11.1 release bump); next phase 220 verification); 220 verification 2026-09-28: gaps_found 8/12 (SC1 + SC2 met, landed green on PR #60; SC3/D-15/D-16 fail-closed contracts bypassable per review WR-01..03 + IN-01, WR-04 CONTRIBUTING contradicts single CI required context; next /gsd-code-review 220 --fix then a landing push to PR #60 under a fresh maintainer grant, then re-verify). 220 Newest-Toolchain Lane verified passed 12/12 2026-09-28 on round-3 re-verification (LANE-01 Complete): review WR-01..04 + IN-01..03 fixed and landed on PR #60, squash-merged to main as 3c4ac9b1 (main CI green); re-verify round 2 found new header/quoted-key/prefixed-image bypasses, closed by reading ci.yml from parsed YAML in d7d44fd1 (not yet on main; needs the next landing); automated UAT 6/6; advisory routed to 221: ci-required gate wiring (if: always(), alls-green jobs, quoted allowed-skips) is not contract-pinned; next /gsd-discuss-phase 221. 221 context gathered 2026-09-29 (research-then-recommend, 3 researchers, D-01..D-15 in 221-CONTEXT.md: subject-first names incl. false Hex evaluator name, p50 time-to-red order as readability-only with order-only move commit before one-pass rename, required_gate_errors/1 with with-keys allowlist + frozen @ci_job_ids, NAME_HISTORY for measurement continuity; next /gsd-plan-phase 221). 221 planned 2026-09-29 (4 plans, serialized waves 1–4: 01 required_gate_errors/1 + @ci_job_ids + time-to-red.py/NAME_HISTORY + 10 run JSONs, 02 red-first ci_order_errors/1 then order-only move with 3-part proof, 03 one-pass rename incl. 3 false evaluator doc lines + evaluator-hexpm rule, 04 ci.all + land/v1.43-221 then maintainer-granted push/PR; plan-check 2 rounds + orchestrator fix of round-2 warning; next /gsd-execute-phase 221). 221 execution started 2026-09-29 (sequential, main tree); 221-01 complete 2026-09-29 (SC-4 + SC-3 id pin: required_gate_errors/1 with rules gate-if/gate-step/gate-inputs/gate-jobs-input/gate-name/job-ids, frozen 14-id @ci_job_ids, mutation control per rule + comment/expression positive controls + fail-closed yaml-parse, commits c005baa8/a8a53c3f; time-to-red.py collect/order/check + frozen NAME_HISTORY + 10 run JSONs (d98b68c9), order reproduces D-06 offline (format p50 17, browser 565); DX-01 stays Pending until 221-04; deferred: mix verify.credo red at base on 2 pre-existing nesting findings from unlanded 220 commits, fix before landing; 1/4 plans; next 221-02). 221-02 complete 2026-09-29 (SC-2: red-first ci_order_errors/1 over parsed_job_order/1 (yaml_elixir keyword mode, reversed; a,b,c fixture) with rules order/order-last/order-unknown/order-needs + order-reader/order-merge-key guards and @time_to_red_order provenance comment; order-only move c72e13a7 touches ci.yml alone, proven parsed ==, line multiset (roster line only), 14-chunk multiset; mover reorder-ci-jobs.py d43dc728; contract + 7 mutation controls 24b7a2b2; time-to-red.py check matches; credo clean; readability only, D-05; DX-01 stays Pending until 221-04; 2/4 plans; next 221-03). 221-03 complete 2026-09-29 (SC-1: one rename commit 194eee6a with exactly 7 paths: D-02 names on all 14 jobs, verify-test posts Build and test (min/current/latest), false hex.pm evaluator name and step replaced (ci.yml never sets THREADLINE_HEX_EVALUATOR_MODE, mix.exs defaults to rehearsal), 3 evaluator doc lines truthful, CONTRIBUTING 15-check roster in ci.yml order; check_name_errors/2 with 8 rules + 9 mutation controls, evaluator_doc_errors/1 with rule=evaluator-hexpm + control; mix verify.test 2515/0, credo + format clean, time-to-red check matches; DX-01 stays Pending until 221-04; 3/4 plans; next 221-04). 221 CI Names and Order verified passed 7/7 2026-09-29 on round-2 re-verification (DX-01 Complete): subject-first check names + truthful evaluator (docs too), p50 time-to-red order (readability only), required_gate_errors/1 shape allowlists incl. BASH_ENV + expression-name bans; landed via squash PR #63 (67572c12, run 36586103573 green 16/16); review WR-01..06/IN-01..07 + VG-01/02 fixed on milestone (not yet on main, needs a follow-up landing; sets DEPS_AUDIT_RENAME_ERA_RUN); advisory: pin ruleset CI required to integration_id 15368 (maintainer); next /gsd-discuss-phase 222. Post-221 (2026-09-29): review fixes landed via PR #64 (b14b4345; DEPS_AUDIT_RENAME_ERA_RUN 36596785874); 0.11.1 distribution-sync PR #59 merged (496ba6ab); live ruleset CI required pinned to GitHub Actions integration_id 15368 (snapshot/diff: only that field) + least-privilege token contract (ci_token_permissions_contract_test.exs) + release.yml job-scoped writes landed via PR #65 (d41cec08), main CI 36603619026 and Branch Protection 36604679871 green; milestone code == main except the 6 release files; next /gsd-discuss-phase 222. 222 context gathered 2026-09-29 (research-then-recommend, 3 researchers, D-01..D-09 in 222-CONTEXT.md: expected CLOSE, scratch re-measure 0 of 28 strict inert in rolling 30d, docs-only ceiling 7-8% billed; two-part gate recorded with honesty note; latest lane kept every-run, supersedes 220 D-07 trim (maintainer-accepted); seed status closed + numeric reopen_when; no new test, no ci.yml edit; next /gsd-plan-phase 222). 222 planned 2026-09-29 (2 plans, serialized waves 1-2: 01 tracer re-measure + conditional halt, 02 decision record + closure; next /gsd-execute-phase 222). 222-01 complete 2026-09-29 (D1-D3: 222 copy of inert-share.py reproduces 214 exactly on a fresh 49-PR snapshot, remeasure-222.py minute-gate/ceiling self-tested and deterministic, verdict CLOSE (0 of 28 strict-inert in 30d-now, denominator 1553 billed min, both gate parts FAIL at 0.0%); 45/46 plans; conditional halt not triggered, proceeds to 222-02). 222-02 complete 2026-09-29 (SCOPE-01 otherwise branch: 222-DECISION.md cited with the honesty note, ceiling row and D-05/D-06 latest-lane supersession; SEED-006 closed with numeric reopen_when (>=5 of last 20 merged PRs strict-inert, or a new lane past the Browser E2E bound), SCOPE-01 [x] + Outcome, PROJECT.md past-tense bullet + Key Decisions row, 220-CONTEXT.md D-07 one-line pointer; verify-phase.sh --close extended (8 new checks) and green; contract-test pins re-run unchanged (78/0); mix ci.all green (318 passed/26 skipped, CI=true); bin/verify-repo-hygiene clean; 46/46 plans; v1.43 all 9 phases executed, next phase verification then milestone close). 222 verified passed 12/12 (d2172db9); code review 0 critical/3 warning/1 info ALL fixed (WR-01..03 iteration 1: 763be9f8/c5030688/45a34847; IN-01 iteration 2: 2b5c2272), 222-REVIEW-DISPOSITION.md 4/4 fixed, 0 open; no product code changed in 222 (milestone vs origin/main differs only in the 6 release-please files). Milestone audit 2026-09-29 (426d67c8): tech_debt, requirements 24/24, integration 15/15, flows 8/8; three decision items routed to Phase 223 (unreleased mint 1.11.0 fix stranded in `ci:` squash #60, 216 CR-01 persist-credentials remainder, six open 217 round-2 findings). 223 planned 2026-09-29 (6 plans, serialized waves 1-6); 223 execution started 2026-09-29 (sequential, main tree); 223-01 complete 2026-09-29 (216 CR-01 closed: persist-credentials: false added to release-please, publish-hex target and smoke-published target checkouts (7 total, 3 new + 3 comments), @persisted_checkout_jobs 2-entry allowlist, per-step checkout-credential-free / allowlisted-job-runs-no-mix / stale-allowlist-entry contract rules with 6 mutation/positive controls, vacuous per-job counting block removed; commits 3f2dd472/e61bc12e; mix test 16/0, credo clean, bin/verify-repo-hygiene clean; 47/52 plans; next 223-02). 223-02 complete 2026-09-29 (217 round-2 findings R2-WR-01..04 fixed in bin/verify-repo-hygiene itself: anchored family 8 for Linux-encoded Claude project dirs (0 real-tree hits), left-anchored family 6 (TitleCase kebab no longer false-positives, R1-CR-01 positives retained), literal_too_broad structural check (9 family roots), newline pre-scan exits 2 before any tree scan; self-test ok (10 cases); CONTRIBUTING -home-<user>-<project> bullet; commits 354dde9a/e99e172c/635de447; mix test 80/0, credo clean, bin/verify-repo-hygiene clean, no allowlist entry added; 48/52 plans; next 223-03). 223-03 complete 2026-09-29 (R2-IN-01/D-17: exact printf hint-line assertion + deletion mutation control in repo_hygiene_contract_test.exs; R2-IN-02/D-18: CONTRIBUTING allowlist-exemption wording scoped to the allowlist's own literal column; D-06: releasable-squash-subject-or-BEGIN_COMMIT_OVERRIDE sentence added to Ongoing releases, no new CI guard per deferral; D-20: 217-REVIEW-DISPOSITION.md hand-edited, all 11 findings fixed/0 open, Source cells cite 223-02/223-03 commit SHAs (354dde9a/e99e172c/635de447/f005358f/265d0624), gsd-core disposition step never run; phase gate green on milestone/v1.43 at 3d2c555e: mix ci.all exit 0 (2573 ExUnit tests/0 failures, credo clean, 318 Playwright passed/26 skipped), bin/verify-repo-hygiene --self-test ok (10 cases); commits f005358f/265d0624/3d2c555e; 49/52 plans; next 223-04 mint 1.11.0 release vehicle behind maintainer push/dispatch grant). 223-04 complete 2026-09-29 (D-01..D-04: land/v1.43-223 built in a worktree from origin/main d41cec08, cherry-picks 3f2dd472->a06588da/e61bc12e->65bd5617/354dde9a->c474ebc3/e99e172c->9fbc9520/635de447->e5e432bb/f005358f->1cdc3383/265d0624->410e33e8 + planning sync 53c2829e, proofs (a)-(e) green (only 6 release files differ, .planning identical, CHANGELOG 3-advisory byte-identical to origin/main, no releasable line, hygiene guard ok (10 cases)); maintainer grant received, orchestrator pushed + opened PR #66, edited #60 with the byte-verbatim D-01 override before merge, squash-merged db8d5373 (ci: subject, 16/16 CI required green), remote branch + worktree cleaned; release run 36646719031 (headSha db8d5373) success opened PR #67 chore(main): release 0.11.2, manifest 0.11.2, body cites mint fix, no Features section; 50/52 plans; next 223-05 date the 0.11.2 CHANGELOG entry via docs(release): PR, maintainer grant needed). 223-05 complete 2026-09-29 (D-04/D-05: dating branch docs/date-0.11.2-changelog built from origin/main, dated ## [0.11.2] - 2026-09-29 heading with three-advisory Security text preserved verbatim, release-shape OK at simulated 0.11.2 and at 0.11.1, changelog_contract_test 9/0; maintainer grant landed PR #68 squash-merged bbfc0d1e, release-please regenerated PR #67 on the new main by itself (ahead_by=1/behind_by=0), so the granted update-branch --rebase was correctly skipped as a no-op; release PR #67 head e9f96e05 confirmed green: CHANGELOG matches version = success, CI required = success (ci.yml run 36653155469); 51/52 plans; next 223-06 publish decision, maintainer one-way-door checkpoint). 223-06 complete 2026-09-30 (0.11.2 published to Hex 2026-09-30, run 36654382663; sync #69): release PR #67 merged --match-head-commit e9f96e05 -> 4d7661b9, production-hex approved under the maintainer's in-session authorization, publish-hex/smoke-published/distribution-sync all success, hex.pm serves 0.11.2 (inserted_at 2026-09-30T01:27:20Z), GitHub release v0.11.2 live, distribution-sync PR #69 merged fbfa8f1e; 52/52 plans; phase 223 awaiting orchestrator verification. Next: phase 223 verification. Post-223 review fix (2026-09-30): WR-01..05 fixed on milestone/v1.43 (b59bb704/ac8b021b/6b26b330/6bada9ca/5a9cc931; fix report 9363f0ac; disposition 5 fixed, IN-01 info open); cited tests 101/0, hygiene guard clean. NOT on main: these 5 commits (test/ci-shaped, non-releasable) need one landing PR under a maintainer push/PR/merge grant during milestone close; the rest of milestone vs origin/main differs only in release files main already has. Close inputs: audit-open shows 10 items (1 todo, 9 deferred-item groups) to acknowledge or route; stale remote land/* and release branches to prune under grant. Next: /gsd-complete-milestone v1.43.

Addendum (2026-09-27, post-217-04, post-217-05, post-218-04, post-218-05, post-218-06 and post-218-07): the `state.update-progress` handler overwrote this narrative line with a bare `[███░░░░░░░] 33%` on both occasions; restored per CLAUDE.md's documented handler-clobber caveat, with plan 217-04's and 217-05's completions folded into the narrative above (percent 33% is correct — 23/23 plans complete, unaffected by the restore).

## Performance Metrics

- **Active Milestone**: v1.44 Behavioral Depth: Properties, Twins, Telemetry (7 phases, 224-230, 27 requirements)
- **Last Milestone Shipped**: v1.43 — Supply Chain, CI Economy and Repo Hygiene (2026-09-30, Phases 214-223, 52 plans, 24/24, released 0.11.1 + 0.11.2)
- **Prior Milestone Shipped**: v1.42 — Capture Correctness for Real Table Shapes (2026-09-26, Phases 208-213, 28/28, released 0.11.0)
- **Scope completion (assessment)**: **~92–95%** for stated narrow audit-platform scope (band: near-done)
- **Hex distribution**: in-repo and hex.pm latest **0.11.2** (published 2026-09-30; 0.11.1 2026-09-27; 0.11.0 2026-09-26)
- **Path-to-done thread**: `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`
- **Posture thread**: `.planning/threads/2026-05-29-post-v1.29-posture.md`
- **v1.28 pilot readiness**: `.planning/threads/2026-05-29-v1.28-pilot-readiness.md`

**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 198 P06 | 4h 15m | 4 tasks | 7 files |
| Phase 198 P07 | 1h 20m | 3 tasks | 4 files |
| Phase 198 P38 | 45min | 3 tasks | 5 files |
| Phase 198 P41 | 7min | 2 tasks | 2 files |
| Phase 198 P42 | 6min | 2 tasks | 5 files |
| Phase 198 P47 | 9 min | 2 tasks | 3 files |
| Phase 198 P48 | 18 min | 3 tasks | 8 files |
| Phase 198 P49 | 15 min | 2 tasks | 5 files |
| Phase 198 P50 | 15 min | 2 tasks | 4 files |
| Phase 198 P51 | 30 min | 2 tasks | 5 files |
| Phase 198 P53 | 24 min | 2 tasks | 4 files |
| Phase 198 P54 | 3 min | 1 tasks | 3 files |
| Phase 198 P55 | 27 min | 2 tasks | 5 files |
| Phase 198 P56 | 4 min | 2 tasks | 2 files |
| Phase 198 P57 | 18 min | 2 tasks | 3 files |
| Phase 198 P58 | 9 min | 2 tasks | 4 files |
| Phase 198 P59 | 6 min | 2 tasks | 4 files |
| Phase 198 P60 | 18 min | 2 tasks | 3 files |
| Phase 198 P61 | 24 min | 3 tasks | 7 files |
| Phase 198 P62 | 33 min | 3 tasks | 7 files |
| Phase 198 P64 | 3 min | 2 tasks | 3 files |
| Phase 198 P66 | 9 min | 2 tasks | 3 files |
| Phase 199 P01 | 11 min | 2 tasks | 2 files |
| Phase 199 P03 | 16 min | 2 tasks | 3 files |
| Phase 199 P04 | 10 min | 2 tasks | 4 files |
| Phase 199 P07 | 6 min | 2 tasks | 1 files |
| Phase 199 P09 | 7 min | 2 tasks | 8 files |
| Phase 199 P10 | 7min | 2 tasks | 9 files |
| Phase 199 P12 | 3h 32min | 2 tasks | 18 files |
| Phase 199 P02 | 2h52m | 2 tasks | 10 files |
| Phase 199 P05 | 14 min | 2 tasks | 17 files |
| Phase 199 P06 | 6 min | 2 tasks | 6 files |
| Phase 199 P11 | 11min | 2 tasks | 4 files |
| Phase 199 P08 | 20 min | 2 tasks | 446 files |
| Phase 199 P13 | 8 min | 0 tasks | 5 files |
| Phase 199 P15 | 16 min | 2 tasks | 6 files |
| Phase 199 P16 | 13 min | 2 tasks | 6 files |
| Phase 199 P17 | 15 min | 2 tasks | 6 files |
| Phase 199 P18 | 6 min | 2 tasks | 6 files |
| Phase 199 P19 | 15 min | 3 tasks | 6 files |
| Phase 199 P20 | 17 min | 2 tasks | 2 files |
| Phase 199 P14 | 34min | 3 tasks | 4 files |
| Phase 199 P21 | 1h 8m | 2 tasks | 10 files |
| Phase 200 P01 | 12min | 3 tasks | 5 files |
| Phase 200 P02 | 25min | 2 tasks | 2 files |
| Phase 200 P03 | 4min | 3 tasks | 8 files |
| Phase 200 P04 | 36min | 2 tasks | 14 files |
| Phase 200 P05 | 12min | 2 tasks | 9 files |
| Phase 200 P06 | 7min | 2 tasks | 9 files |
| Phase 200 P07 | 4min | 2 tasks | 6 files |
| Phase 200 P08 | 33min | 2 tasks | 9 files |
| Phase 200 P16 | 32min | 2 tasks | 9 files |
| Phase 200 P17 | 12min | 2 tasks | 10 files |
| Phase 200 P12 | 41min | 2 tasks | 8 files |
| Phase 200 P13 | 5min | 2 tasks | 2 files |
| Phase 201-rendered-output P01 | 13min | 3 tasks | 4 files |
| Phase 201-rendered-output P02 | 11min | 1 tasks | 5 files |
| Phase 201-rendered-output P03 | 7min | 1 tasks | 5 files |
| Phase 201-rendered-output P04 | 8min | 1 tasks | 5 files |
| Phase 202 P01 | 26 min | 3 tasks | 13 files |
| Phase 202 P02 | 12 min | 4 tasks | 5 files |
| Phase 202 P03 | 40 min | 3 tasks | 5 files |
| Phase 202 P08 | 22 min | 1 tasks | 1 files |
| Phase 203 P01 | 6min | 2 tasks | 15 files |
| Phase 203 P02 | 4min | 2 tasks | 9 files |
| Phase 203 P03 | 15min | 2 tasks | 22 files |
| Phase 203 P04 | 3min | 2 tasks | 14 files |
| Phase 203 P05 | 7min | 2 tasks | 20 files |
| Phase 203 P06 | 8min | 2 tasks | 28 files |
| Phase 203 P07 | 6min | 2 tasks | 23 files |
| Phase 203 P08 | 45min | 2 tasks | 28 files |
| Phase 203 P09 | 25min | 3 tasks | 9 files |
| Phase 203 P10 | 40min | 2 tasks | 2 files |
| Phase 204 P01 | 8 min | 3 tasks | 6 files |
| Phase 204 P02 | 35 min | 3 tasks | 16 files |
| Phase 204 P03 | 2h 8m | 3 tasks | 24 files |
| Phase 204 P04 | 26 min | 3 tasks | 17 files |
| Phase 204 P05 | 63 min | 3 tasks | 9 files |
| Phase 204 P06 | 36 min | 3 tasks | 41 files |
| Phase 204 P07 | 12min | 3 tasks | 15 files |
| Phase 204 P08 | 47min | 3 tasks | 10 files |
| Phase 204 P09 | 109min | 2 tasks | 10 files |
| Phase 204 P10 | 37 min | 3 tasks | 9 files |
| Phase 204 P11 | 37min | 2 tasks | 5 files |
| Phase 204 P12 | 33min | 2 tasks | 11 files |
| Phase 204 P13 | 7min | 3 tasks | 10 files |
| Phase 204 P14 | 6min | 3 tasks | 10 files |
| Phase 204 P15 | 20min | 3 tasks | 9 files |
| Phase 204 P16 | 17 | 3 tasks | 11 files |
| Phase 205 P01 | 11min | 3 tasks | 19 files |
| Phase 205 P02 | 12 min | 2 tasks | 5 files |
| Phase 206 P01 | 4min | 3 tasks | 5 files |
| Phase 206 P02 | 12 min | 2 tasks | 1 files |
| Phase 207 P01 | 4min | 2 tasks | 3 files |
| Phase 207 P02 | 6 min | 3 tasks | 5 files |
| Phase 207 P03 | 7min | 3 tasks | 7 files |
| Phase 208 P01 | 2 min | 2 tasks | 4 files |
| Phase 208 P02 | 5min | 2 tasks | 4 files |
| Phase 208 P03 | 5 min | 2 tasks | 6 files |
| Phase 208 P04 | 6 min | 3 tasks | 3 files |
| Phase 208 P05 | 12 min | 3 tasks | 6 files |
| Phase 210 P01 | 19min | 3 tasks | 8 files |
| Phase 210 P02 | 22min | 2 tasks | 2 files |
| Phase 210 P03 | 30min | 3 tasks | 8 files |
| Phase 210 P04 | 21min | 3 tasks | 8 files |
| Phase 210 P05 | 30min | 3 tasks | 13 files |
| Phase 211 P01 | 13min | 3 tasks | 5 files |
| Phase 211 P02 | 55min | 3 tasks | 6 files |
| Phase 211 P03 | 45min | 3 tasks | 11 files |
| Phase 211 P04 | 55min | 3 tasks | 8 files |
| Phase 212 P01 | ~1h | 3 tasks | 9 files |
| Phase 212 P02 | ~1h30m | 3 tasks | 5 files |
| Phase 212 P03 | ~1h | 3 tasks | 6 files |
| Phase 212 P05 | 55min | 3 tasks | 8 files |
| Phase 212 P04 | 45min | 2 tasks | 7 files |
| Phase 212 P06 | ~10min | 2 tasks | 5 files |
| Phase 213 P01 | 1h5min | 3 tasks | 11 files |
| Phase 213 P02 | 55min | 3 tasks | 4 files |
| Phase 213 P03 | 1h25min | 3 tasks | 3 files |
| Phase 214 P01 | 14 min | 3 tasks | 242 files |
| Phase 214 P02 | 17min | 3 tasks | 26 files |
| Phase 214 P03 | 12 min | 3 tasks | 49 files |
| Phase 215 P01 | 25min | 2 tasks | 4 files |
| Phase 215 P03 | 20min | 2 tasks | 1 files |
| Phase 215 P02 | 35min | 2 tasks | 9 files |
| Phase 215 P04 | ~50min | 3 tasks | 5 files |
| Phase 215 P05 | ~55min | 3 tasks | 5 files |
| Phase 217 P01 | ~40min | 3 tasks | 3 files |
| Phase 217 P02 | ~70min | 3 tasks | 13 files |
| Phase 217 P03 | 12min | 2 tasks | 1 files |
| Phase 217 P04 | ~35min | 2 tasks | 319 files |
| Phase 217 P05 | ~50min | 2 tasks | 4 files |
| Phase 217 P06 | ~10min | 2 tasks | 3 files |
| Phase 217 P07 | ~25min | 3 tasks | 5 files |
| Phase 218 P01 | 4min | 2 tasks | 2 files |
| Phase 218 P02 | 5min | 2 tasks | 4 files |
| Phase 218 P03 | 10 min | 2 tasks | 9 files |
| Phase 218 P04 | 8 min | 3 tasks | 8 files |
| Phase 218 P05 | 15min | 2 tasks | 9 files |
| Phase 218 P06 | 10 min | 2 tasks | 3 files |
| Phase 218 P07 | 10 min | 2 tasks | 5 files |
| Phase 219 P01 | 36min | 4 tasks | 1 files |
| Phase 219 P02 | 17min | 4 tasks | 3 files |
| Phase 219 P03 | 160min | 4 tasks | 27 files |
| Phase 221 P01 | 30min | 3 tasks | 13 files |
| Phase 221 P03 | 25min | 3 tasks | 7 files |
| Phase 222 P01 | ~15min | 3 tasks | 95 files |
| Phase 223 P01 | ~35min | 2 tasks | 2 files |
| Phase 223 P02 | ~50min | 3 tasks | 3 files |
| Phase 223 P03 | ~20min | 3 tasks | 3 files |
| Phase 223 P04 | ~15min | 3 tasks | 0 files |
| Phase 223 P06 | ~10min | 3 tasks | 0 files |
| Phase 224 P01 | ~40min | 2 tasks | 5 files |
| Phase 224 P03 | ~35min | 2 tasks | 6 files |
| Phase 224 P02 | ~30min | 2 tasks | 3 files |
| Phase 224 P04 | ~50min | 2 tasks | 3 files |
| Phase 225 P01 | ~45min | 2 tasks | 5 files |
| Phase 225 P02 | ~50min | 2 tasks | 7 files |
| Phase 225 P03 | ~2h | 3 tasks | 11 files |
| Phase 225 P04 | ~50min | 2 tasks | 4 files |

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| todos (v1.43 close, 2026-09-30) | 2026-09-28-ci-suite-sync-bound-parallelism | Acknowledged, still pending (v1.44 candidate) |
| deferred_items (v1.43 close, 2026-09-30) | 214/deferred-items.md: from 214-02, vacuous :live_dialyzer without a PLT; runner cache path in the local-path regex | Acknowledged; resolved (verifier fails closed since 218-03; the guard shipped in 217) |
| deferred_items (v1.43 close, 2026-09-30) | 214/deferred-items.md: from 214-03, CI test lanes take the vacuous :live_dialyzer path | Acknowledged; resolved (:live_dialyzer runs only in verify-dialyzer, fail-closed, 218-03) |
| deferred_items (v1.43 close, 2026-09-30) | 215/deferred-items.md: bench ExUnitProperties compile; review WR-01/03/04/05/06/07/08, IN-01..04; runtime MIX_EXS/MIX_HOME | Acknowledged, carried (WR-03 mitigated) |
| deferred_items (v1.43 close, 2026-09-30) | 216/deferred-items.md: from 216-06, setup-node floats 22; third-party actions not SHA-pinned | Acknowledged, carried |
| deferred_items (v1.43 close, 2026-09-30) | 216/deferred-items.md: 216 review CR-01, WR-01, WR-02 | Acknowledged; CR-01 resolved in 223-01; WR-01/WR-02 carried |
| deferred_items (v1.43 close, 2026-09-30) | 218/deferred-items.md: from 218-04, CONTRIBUTING branch-protection list | Acknowledged; resolved (rewritten in 221) |
| deferred_items (v1.43 close, 2026-09-30) | 218/deferred-items.md: from 218-08, live Dialyzer slice line not in the CI log; Browser-full push unit is an inference | Acknowledged, carried |
| deferred_items (v1.43 close, 2026-09-30) | 218/deferred-items.md: from 218 verification, clean_checkout temp-dir collision; tier-a-capture dependency; WR-03 locked | Acknowledged, carried |
| deferred_items (v1.43 close, 2026-09-30) | 221/deferred-items.md: from 221-01, verify.credo red at base | Acknowledged; resolved (7ebb66ad) |
| deferred_items (v1.42 close, 2026-09-26) | Phase 210 deferred-items: 210-04 format drift in legacy_trigger_pk_fallback_test (resolved in 210-05) | Acknowledged |
| deferred_items (v1.42 close, 2026-09-26) | Phase 202 (v1.41 archive) deferred-items: flake mechanism CORRECTION (critic_trust_test unique_integer scratch-dir reuse) | Acknowledged, carried |
| external-pilot | v1.28 pilot unblockers | **Deferred** until sustained real-adopter signal |
| post-v1.29 | Hold mode | **Superseded** by v1.31 polish milestone (2026-06-03) |
| v1.22 DEFER | COMPLIANCE-PACK, LEGAL-HOLD, IMMUTABLE-ARCHIVE | Deferred until procurement pressure |
| host-class | STG-01 host staging depth | Integrator-owned; v1.28 when signal |
| Pow / bearer auth lane | On explicit demand only | Not planned |
| Phase 135-seed-enrichment-ia-lock-in P01 | 3m | 3 tasks | 4 files |
| Phase 135 P02 | 2m | 2 tasks | 3 files |
| Phase 135 P03 | 8m | 3 tasks | 4 files |
| Phase 135 P04 | 5m | 2 tasks | 2 files |
| Phase 144 P02 | 2m16s | 2 tasks | 5 files |
| Phase 144 P03 | 3m47s | 2 tasks | 4 files |
| Phase 144 P04 | 15min | 3 tasks | 8 files |
| Phase 160 P01 | 45min | 4 tasks | 10 files |
| Phase 159 P02 | 35min | 3 tasks | 1 files |
| Phase 159 P03 | 9min | 2 tasks | 1 files |
| Phase 161 P01 | 68min | 4 tasks | 29 files |
| Phase 162 P01 | 17min | 3 tasks | 16 files |
| Phase 162 P02 | 16min | 2 tasks | 5 files |
| Phase 162 P03 | 16min | 3 tasks | 10 files |
| Phase 164 P01 | 10min | 2 tasks | 3 files |
| Phase 163 P01 | 25min | 5 tasks | 6 files |
| Phase 166 P01 | 65min | 5 tasks | 17 files |
| Phase 168 P01 | 25min | 3 tasks | 1 files |
| Phase 170 P01 | 18m | 3 tasks | 5 files |
| Phase 170 P02 | ~9m | 2 tasks | 2 files |
| uat_gap (v1.36 close 2026-06-14) | 169-HUMAN-UAT.md — 1 pending scenario | partial — acknowledged & deferred |
| uat_gap (v1.36 close 2026-06-14) | 170-HUMAN-UAT.md — 1 pending scenario | partial — acknowledged & deferred |
| verification_gap (v1.36 close 2026-06-14) | 170-VERIFICATION.md | human_needed — acknowledged & deferred |
| todo (v1.36 close 2026-06-14) | transaction-page-left-push-desktop (operator-surface layout bug) | resolved by Phase 178 |
| todo (v1.36 close 2026-06-14; reframed 2026-06-20) | coverage-schema-card-declutter (operator-surface Coverage IA/schema workflow) | completed as standalone todo; broader Coverage audit-readiness polish now scoped to v1.38 Phase 185 |
| todo (v1.36 close 2026-06-14) | theme-picker-idiomatic-ui (THEME-TOGGLE-01, out of v1 scope per [165-01]) | completed in v1.37 runtime theme picker work |
| deferred [176-05] | T3 redact destructive flow — no runtime redaction backend (codegen-time only); building one would touch the capture layer (v1.37 invariant). Revisit only if a runtime "redact a stored value" op is explicitly scoped without editing capture. | deferred per Task-1 checkpoint (option 1) |
| Phase 174 P06 | 6min | 2 tasks | 2 files |
| Phase 175 P01 | 14min | 2 tasks | 5 files |
| Phase 175 P02 | ~15min | 2 tasks | 4 files |
| Phase 175 P03 | ~30min | 2 tasks | 11 files |
| Phase 175 P04 | ~12min | 2 tasks | 7 files |
| Phase 176 P01 | ~30min | 3 tasks | 9 files |
| Phase 176 P02 | ~40min | 3 tasks | 7 files |
| Phase 176 P03 | ~75min | 3 tasks | 12 files |
| Phase 176 P04 | ~25min | 2 tasks | 5 files |
| Phase 177 P03 | ~5min | 3 tasks | 2 files |
| Phase 177 P04 | ~12min | 2 tasks | 2 files |
| Phase 177 P05 | ~17min | 3 tasks | 7 files |
| Phase 178 P06 | 10m 23s | 3 tasks | 7 files |
| Phase 178 P07 | 8 min | 2 tasks | 1 files |
| Phase 179 P01 | 11m 53s | 3 tasks | 8 files |
| Phase 179 P02 | 8m 9s | 1 tasks | 12 files |
| Phase 179 P03 | 13m 39s | 1 tasks | 12 files |
| Phase 179 P04 | 25min | 1 tasks | 4 files |
| Phase 179 P05 | 28min | 1 tasks | 17 files |
| Phase 179 P06 | 8m | 1 tasks | 5 files |
| Phase 180 P01 | 178m | 2 tasks | 6 files |
| Phase 180 P02 | 10m 27s | 2 tasks | 6 files |
| Phase 180 P03 | 21m 49s | 2 tasks | 5 files |
| Phase 180 P04 | closeout | 3 tasks | guardrail tests + closeout artifacts |
| todo (v1.37 close 2026-06-20) | coverage-schema-card-declutter (functional outcome resolved by Phase 176 and regression-guarded by Phase 180; todo artifact cleanup remains) | completed as todo artifact cleanup; broader Coverage flow polish now scoped to v1.38 Phase 185 |
| todo (v1.37 close 2026-06-20) | operator-shell-nav-ia-and-visibility | completed as post-close todo; broader shell/home polish now scoped to v1.38 Phase 183 |
| todo (v1.37 close 2026-06-20) | demo-login-copy-credentials | completed as post-close demo-login polish |
| Phase 181 P01 | 32 min | 2 tasks | 12 files |
| Phase 181 P02 | 4 min | 1 tasks | 1 files |
| Phase 181-baseline-audit-and-guard-repair P03 | 1028 | 1 tasks | 3 files |
| Phase 181-baseline-audit-and-guard-repair P04 | 7 min | 1 tasks | 8 files |
| Phase 181-baseline-audit-and-guard-repair P05 | 8 min | 1 tasks | 5 files |
| Phase 181-baseline-audit-and-guard-repair P06 | 1h 1m | 1 tasks | 1 files |
| Phase 181-baseline-audit-and-guard-repair P07 | 6 min | 1 tasks | 7 files |
| Phase 181-baseline-audit-and-guard-repair P08 | 4 min | 1 tasks | 2 files |
| Phase 181-baseline-audit-and-guard-repair P09 | 3 min | 1 tasks | 2 files |
| Phase 181-baseline-audit-and-guard-repair P10 | 3 min | 1 tasks | 2 files |
| Phase 181-baseline-audit-and-guard-repair P11 | 29m24s | 2 tasks | 37 files |
| Phase 182 P01 | 7 min | 3 tasks | 6 files |
| Phase 182-phoenixstorybook-example-dev-lane P02 | 7 min | 2 tasks | 5 files |
| Phase 182 P03 | 9 min | 2 tasks | 15 files |
| Phase 182 P04 | 18 min | 3 tasks | 9 files |
| Phase 182 P05 | 7 min | 2 tasks | 4 files |
| Phase 183 P01 | 15 min | 2 tasks | 2 files |
| Phase 183 P02 | 68m | 2 tasks | 9 files |
| Phase 183 P03 | 36m | 1 tasks | 3 files |
| Phase 184 P01 | 10 min | 2 tasks | 6 files |
| Phase 184 P02 | 9 min | 2 tasks | 5 files |
| Phase 184 P03 | 49 min | 2 tasks | 5 files |
| Phase 185 P01 | 19m | 3 tasks | 13 files |
| Phase 187 P01 | 5 min | 2 tasks | 3 files |
| Phase 187 P02 | 35min | 2 tasks | 2 files |
| Phase 187 P03 | 28 min | 2 tasks | 3 files |
| Phase 188 P01 | 5min | 2 tasks | 3 files |
| Phase 188 P02 | 3min | 2 tasks | 2 files |
| Phase 188 P03 | 8 min | 2 tasks | 6 files |
| Phase 189 P01 | 6 min | 3 tasks | 2 files |
| Phase 190 P01 | 8m31s | 3 tasks | 9 files |
| Phase 190 P02 | 8min | 2 tasks | 11 files |
| Phase 190 P03 | 7m17s | 2 tasks | 8 files |
| Phase 190 P04 | 15 min | 2 tasks | 6 files |
| Phase 190 P05 | 9 min | 2 tasks | 5 files |
| Phase 190 P07 | 8 min | 2 tasks | 6 files |
| Phase 190 P08 | 9 min | 2 tasks | 8 files |
| Phase 190 P09 | 9m17s | 2 tasks | 6 files |
| Phase 190 P10 | 7m23s | 3 tasks | 3 files |
| Phase 191 P01 | 12min | 3 tasks | 3 files |
| Phase 191 P02 | ~14min | 3 tasks | 4 files |
| Phase 191 P03 | 22min | 3 tasks | 15 files |
| Phase 192 P02 | 15m | 2 tasks | 2 files |
| Phase 192 P03 | 8min | 3 tasks | 4 files |
| Phase 195 P01 | 4m | 3 tasks | 11 files |
| Phase 195 P02 | 4m | 2 tasks | 6 files |
| Phase 195 P3 | multi-session | 2 tasks | 205 files |
| Phase 195 P04 | 11m | 2 tasks | 7 files |
| Phase 195 P06 | 13m | 2 tasks | 2 files |
| Phase 197 P05 | ~50min | 3 tasks | 4 files |
| uat_gap (v1.40 close 2026-08-27) | 169-HUMAN-UAT.md — 1 pending scenario (archived v1.36) | partial — acknowledged & deferred |
| uat_gap (v1.40 close 2026-08-27) | 170-HUMAN-UAT.md — 1 pending scenario (archived v1.36) | partial — acknowledged & deferred |
| uat_gap (v1.40 close 2026-08-27) | 30-HUMAN-UAT.md — 0 pending scenarios (archived v1.9) | partial — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 197-VERIFICATION.md — PROOF-02 shortfall ratified at phase seal (achieved-with-ratified-gap) | gaps_found — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 170-VERIFICATION.md (archived v1.36) | human_needed — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 109-VERIFICATION.md (archived v1.23) | gaps_found — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 30-VERIFICATION.md (archived v1.9) | human_needed — acknowledged & deferred |
| deferred_items (v1.40 close 2026-08-27) | Phase 196 deferred-items.md — 1 entry (pre-existing full-suite failures: StressLedgerTest fixture-registry gap, LedgerSplice, FormlessPages, Phase06Nyquist, V123Charter) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 197 deferred-items.md — 1 entry (copy_contract eyebrow red from 197-02 = debt rank 2; 3-module doc-contract baseline = debt rank 8; search_path fix confirmed) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 191 deferred-items.md (archived v1.39) — 3 entries (v1_23_charter_doc_contract_test milestone-literal drift) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 181 deferred-items.md (archived v1.38) — 1 entry (root CI residuals: formless coverage, charter drift, example demo-seed) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 182 deferred-items.md (archived v1.38) — 1 entry (example precommit demo-seed/walkthrough failures) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 176 deferred-items.md (archived v1.37) — 3 entries (format-clean drift ×2, card-nesting coverage RED; table converted to heading entries to carry status) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 177 deferred-items.md (archived v1.37) — 1 entry (example demo-seed 60s setup timeout) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 179 deferred-items.md (archived v1.37) — 5 entries (charter doc-contract + example demo-seed/walkthrough residuals per plan 01/03/04/05/06) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 180 deferred-items.md (archived v1.37) — 1 entry (mix precommit demo-seed failures; Status field repurposed, scope note kept) | acknowledged in-file (status: acknowledged) |
| debug_session (v1.41 close 2026-09-24) | phase-199-ci-uat-classification | diagnosed — acknowledged & deferred |
| seed (v1.41 close 2026-09-24) | SEED-006-ci-feedback-loop-cost-and-latency | dormant — acknowledged & deferred |
| deferred_items (v1.41 close 2026-09-24) | Phase 198 deferred-items.md (archived v1.41) — 9 entries (GREEN-07 terminal disposition, round 4-6 CI lane records, IN-01 row-history height guard) | acknowledged in-file (status: acknowledged). |
| deferred_items (v1.41 close 2026-09-24) | Phase 199 deferred-items.md (archived v1.41) — 5 entries (formatter drift, 199-02 checker handoff, pair-label TODO, locked dependency advisories, Dialyzer contract drift) | acknowledged in-file (status: acknowledged). |
| deferred_items (v1.41 close 2026-09-24) | Phase 200 deferred-items.md (archived v1.41) — 1 entries (CONTRIBUTING.md planning vocabulary in release archive scan) | acknowledged in-file (status: acknowledged). |
| deferred_items (v1.41 close 2026-09-24) | Phase 202 deferred-items.md (archived v1.41) — 11 entries (critic_trust_test temp-dir counter-reuse flake (mechanism proven, unfixed), stale hex-evaluator pin prose) | acknowledged in-file (status: acknowledged). One entry (CORRECTION section) marked by hand; gsd-tools writer cannot match heading-shaped entries in mixed files. |
| deferred_items (v1.41 close 2026-09-24) | Phase 205 deferred-items.md (archived v1.41) — 1 entries (D-205-01 clean_checkout_contract_test temp-dir collision) | acknowledged in-file (status: acknowledged). |

## Accumulated Context

### Pending Todos

- `.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md` is acknowledged at the v1.43 close and still pending. The suite is about 91% synchronous (191 of 209 s). Candidate for v1.44's test rebalancing.
- The next milestone should preserve the standing no-regression rule for operator routes, data-testids, feature gates, capture/query/auth semantics, optional Phoenix dependencies, and host-app-friendly theming unless fresh requirements explicitly change it.

### Roadmap Evolution

- **Phase 223 added (2026-09-29):** Close v1.43 Audit Debt, from `.planning/v1.43-MILESTONE-AUDIT.md` (status tech_debt, 24/24 requirements, integration 15/15, flows 8/8). Scope: release the mint 1.11.0 advisory fix (on main, but in the `ci:` squash #60, so release-please has nothing to release), `persist-credentials: false` on the release.yml target-ref checkouts plus a contract (216 CR-01 remainder), and a disposition for each of the six open 217 round-2 findings (R2-WR-04 is the one to fix).
- **v1.43 roadmap (2026-09-26):** Phases 214-222 from the research SUMMARY split, 24/24 requirements mapped. 214 Baseline, then 215 Supply chain / 216 Platform currency / 217 Repo hygiene (mutually independent), 218 Remove CI waste (ECON-07 re-measure), 219 deps-only `_build` cache, 220 newest lane (spike-gated), 221 names/order (rename once), 222 SEED-006 (conditional). Kept nine phases despite coarse granularity: each boundary is an ordering constraint (fix before gate, delete before cache, rename after roster changes, classifier after measured wins). Research flags: 220, 222, 219, parts of 216; 215 narrow (Hex cooldown only if adopted).
- **v1.42 roadmap (2026-09-24):** Phases 208-213 from research SUMMARY split, adjusted for the four scope decisions. REL-01 (`bump-minor-pre-major`) lands in 208 before any releasable commit. CONF-01 is mapped to 210 (config key, validation, migrate-time enforcement) but completes only when 211 success criterion 3 (override read round-trip) passes. IDX-01 ships in 211 (install creates the index). Kept six phases despite coarse granularity: each boundary is a hard contract hand-off and the 209 security fix must not wait behind the PK rewrite. Research flags: 208 (hashed-name format), 210 (TG_ARGV spike), 211 (composite history API).

- Phase 130.1 inserted after Phase 130: Address tech debt: planning metadata hygiene (URGENT)
- Milestone v1.29 archived 2026-05-29
- **Post-v1.30 direct-PR work (2026-05-30, no milestone):**
  - **0.7.0 release** — unblocked the stuck release-please PR; fixed `bin/verify-release-shape` to accept release-please's CHANGELOG heading; published `v0.7.0` to Hex. Fixed the operator-surface timeline crash on `?correlation_id=` (`FilterParams` `String.to_existing_atom` → compile-time allowlist) that had kept the v1.30 Playwright job red.
  - **Release-pipeline hardening** — generalized `bin/post-publish-distribution-sync` (was 0.5→0.6-pinned); added `workflow_dispatch` to `ci.yml` so "Bootstrap CI on Release PR" stops failing.
  - **Test determinism** — fixed the ~40% retention-pruner flake + a telemetry cross-contamination flake; added `test/support/async_helpers.ex`, `mix verify.flake`, and a nightly **Flake Detection** workflow. See `CONTRIBUTING.md` "Deterministic tests".
- **Direct-PR work (2026-06-03, no milestone):**
  - **Operator surface** — first-class positioning + accessibility pass (#16); deterministic evidence `record_*` export assertions (#18).
  - **0.8.0 + 0.9.0 cuts** — published to Hex via release-please.
  - **Release-please born-red root-cause fix (#22)** — every release PR was born red because release-please bumped `mix.exs` but not the adoption-pilot guide, failing `adoption_pilot_doc_contract_test`. Fixed via `extra-files` + `x-release-please-version` annotation so the SSOT line is bumped atomically in the release commit (green by construction, no manual prep). `bin/post-publish-distribution-sync` now owns only the post-publish Hex row; a guard test enforces the wiring. See memory `release-runbook` and `CONTRIBUTING.md`.
- **Milestone v1.31 opened (2026-06-03):** Hold superseded by a non-signal-gated polish milestone. Ten POLISH-* phases were planned in a fully pre-decided order: measure → enrich → systematize → apply (least-iterated first) → hub → flows → motion → responsive → sweep.
- Phase 144 added: Close gap: POLISH-AUDIT and POLISH-DS
- **v1.31 closeout hygiene (2026-06-05):**
  - The pending "Capture direct demo and UI polish" todo is resolved: the Docker demo is documented in `examples/threadline_phoenix/README.md`, operator-surface polish was absorbed by v1.31, and release notes already cover the automated operator-surface/design-system gate.
  - Phase 135 and Phase 137 HUMAN-UAT records are terminal `status: complete`; their checks are automated by `operator-phase-135-uat.spec.ts` and `operator-prove-mobile.spec.ts` under `mix verify.example_browser`, so no human UAT remains.
- **Milestone v1.33 opened (2026-06-05):** Brand Review + Direction Selection reviews the existing v1.32 `brandbook/` artifacts before public rollout. Phase 150 added `logo-primary-light.svg` after browser preview showed the dark primary logo was too pale on white README/GitHub surfaces.
- **Phase 152 targeted revisions complete (2026-06-06):** Human review selected stand-alone brandbook truth cleanup. `brandbook/` now presents the current brand system without refresh/audit backstory framing.
- **Phase 153 UI-SPEC approved (2026-06-06):** Verification closeout design contract created and checked across copywriting, visuals, color, typography, spacing, and registry safety.
- **Phase 153 verification and closeout complete (2026-06-06):** Current-tree JSON/SVG/HTML parse, direct-open browser, desktop/mobile screenshots, historical-frame scan, binary exclusion, file inventory, and file-size evidence passed. v1.33 is archive-ready with public rollout and legal/trademark work deferred.
- **Milestone v1.33 archived (2026-06-06):** Roadmap, requirements, audit, and phase history are archived under `.planning/milestones/`; fresh requirements are needed before public rollout work.
- **Milestone v1.34 opened (2026-06-06):** Local Docker Admin UI DX focuses on helper-first `bin/demo-up`, localhost-bound dynamic ports, Compose project isolation, cache-friendly Docker behavior, printed `/audit` URLs, lifecycle commands, and docs. Traefik/subdomain routing is deferred; `.localhost` is the future-safe hostname family if proxy support is later added.
- **v1.34 implementation complete (2026-06-06):** `bin/demo-up` now supports project-aware lifecycle commands, `--build`, no-build refreshes when a project image exists, port validation, optional public host, and clearer failure guidance. Compose/Dockerfile now support an overridable demo base image, bundled Dockerfile frontend, `ca-certificates`, localhost-bound ports, project-scoped volumes, and pinned PgBouncer. Docs cover helper-first DX, multi-stack ports, cleanup, cache behavior, and deferred proxy/subdomain routing.
- **Milestone v1.35 roadmap created (2026-06-11):** Unified Logo & Brand Book v2 — phases 159–163 per the approved plan `<home>/.claude/plans/have-to-compare-it-lexical-shore.md`. 159 (audit+research) ∥ 160 (glyph pipeline) → 161 (tournament, human checkpoint rounds, user picks winner) → 162 (brand book v2 + UAT) → 163 (optional product rollout, decision-gated). 28/28 requirements mapped; operator surface `style.ex` frozen in all core phases.
- **Milestone v1.35 shipped + archived (2026-06-12):** C13 topstitch-geist identity, brand book v2, product rollout, and light-mode strategy decision [165-01] (supersedes [136-01]; v1.36 seeded via SEED-004). Archives under `.planning/milestones/v1.35-*`.
- **Milestone v1.37 roadmap created (2026-06-14):** Operator Surface Design-System Stress Test & Component System — phases 171-180 per the approved plan `<home>/.claude/plans/design-system-stress-test-fancy-gizmo.md`, continued numbering. Largely linear fractal sequence: 171 (harness: `/audit/__stress` + DESIGN-SYSTEM.md v2 + scored ratchet ledger + ugly-data fixtures) → 172 (foundations/tokens, parity-gated) → 173 (primitive + overlay/disclosure components) → 174 (form components + page adoption + contract tests) → 175 (shell/nav + runtime theme picker, THEME-TOGGLE-01) → 176 (data display, flatten card-in-card) → 177 (component groups) → 178 (per-page stress, all 11 pages, kill footguns) → 179 (microcopy + IA sweep) → 180 (WCAG 2.2 AA + guardrails + adversarial closeout). 33/33 requirements mapped. Carried-todo phase tags: `theme-picker-idiomatic-ui`→175, `coverage-schema-card-declutter`→176, `transaction-page-left-push-desktop`→178. Invariants held: no public component API, zero new runtime deps, inline assets, brand-token parity green, capture/semantics untouched, fail-closed auth.
- **Milestone v1.36 roadmap created (2026-06-12):** Operator Surface Light Mode — phases 166–170 per the approved 165 recommendation's pre-decided breakdown: 166 (unfreeze + 45-token light lane + `data-tl-theme` mechanism, contract amended same-wave) → 167 (component retune, largest) → 168 (accessibility AA mirror) ∥ 169 (`__light__` screenshots + example + docs) → 170 (brand alignment + closeout). 15/15 requirements mapped. Human gates: light-lane design review after 166; end-of-milestone UAT after 170.
- **Milestone v1.38 roadmap created (2026-06-26):** Operator UI Page-by-Page IA & Design-System Polish — phases 181-187. Order is baseline guard repair → PhoenixStorybook example/dev lane → shell/home → Timeline → Coverage → detail/governance/export → accessibility/motion/docs/adversarial closeout. 24/24 requirements mapped, with former post-close todo pressure absorbed into phases 183, 185, and prior demo-login polish.
- **Milestone v1.38 archived (2026-06-30):** Operator UI Page-by-Page IA & Design-System Polish shipped with phases 181-188 complete, 24/24 requirements satisfied, and residual CI/screenshot/environment/Nyquist items explicitly classified in the archive audit.
- **Milestone v1.39 roadmap created (2026-07-01):** Quality Baseline, Schema Confidence, and CI Efficiency — phases 189-193. Order is quality audit → storage-schema proof/fixes → release/version docs trust → CI/CD measurement and efficiency → closeout/next-step decision. 15/15 requirements mapped. Invariants held: no new operator product scope, no public component API, no compliance expansion, no synthetic external pilot, no runtime destructive redaction, no WAL/CDC backend, and no broad CI cleverness before measurement.
- **Milestone v1.41 roadmap created (2026-08-27):** Green, Clean, and Honest — phases 198-204 per the approved plan `<home>/.claude/plans/so-i-don-t-really-have-quirky-wilkinson.md`, continued numbering. Order is green bringup → decouple (dialyxir lands here) → public surface → rendered output → **release 0.10.0 (deliberately mid-milestone: hex.pm has no undo, so publish once the permanent and rendered surfaces are clean, before the invisible internal work)** → real gates → structure. 53/53 requirements mapped, coarse granularity, est. 26-33 plans. Two workloads are deliberately unmeasured at roadmap time — the full-default Credo backlog (measured in 198 Plan 01) and the dialyzer finding count (measured in 199) — with a pre-committed sizing rule for Phase 203 (<150 → one phase; 150-600 → split mechanical from judgment; >600 or one dominating check → adopt defaults with that check as a counted register row plus a named successor milestone). Phase 201's cost depends on 198 Plan 01's mechanical-sensitivity probe. Highest-variance risk: the `min` CI lane (Elixir 1.15 / OTP 26 / pg14 / ubuntu-22.04) has never executed on origin. Invariants: no operator-UI design/IA/visual change, no Tier-A scorecard regeneration, paid critic scoring stays structurally untriggerable, `.planning/` stays tracked, no git history rewrite, no capture/query/auth semantic change, no version-floor bump; `git mv`/`git rm` for every move/removal, one file per commit where contract tests are involved.
- Phase 205 added (2026-09-24): Release Reconciliation — gap closure for the v1.41 milestone audit (`.planning/v1.41-MILESTONE-AUDIT.md`, status gaps_found, finding F1). The milestone branch is 433 ahead / 5 behind origin/main and never merged Phase 202's shipped release commits (#41, #43, #44, the 0.10.0 release commit, #45); RELEASE-02/05 hold on origin/main only.
- Phase 206 added (2026-09-24): Installer Migration Versions — tech-debt closure from the v1.41 re-audit (status tech_debt, 48/54, F1 resolved). `mix threadline.install` stamps all three migrations with one second-resolution `timestamp()` (lib/mix/tasks/threadline.install.ex:65), so a fresh `mix ecto.migrate` raises a duplicate-version error; 205-REVIEW CR-01, shipped since v0.9.0 incl. 0.10.0/0.10.1.
- Phase 207 added (2026-09-24): Trigger Migration Rerun and Storage-Schema Default Docs — tech-debt closure from the v1.41 second re-audit (fe896464; status tech_debt, 48/54, flows 5/5, CR-01 resolved by 206). W1: rerunning `mix threadline.gen.triggers` for the same tables writes a duplicate migration name (gen.triggers.ex:141), which Ecto rejects, and the drift guides prescribe that rerun. W2: audit-indexing.md:7 and production-checklist.md:14 state the storage_schema default as `threadline`; the code default is `public`.

### Decisions

- [202-04]: `ALLOW_UNVERIFIED_ENVIRONMENT_PROTECTION` is deliberately NOT set in `environment-protection.yml`. Unlike the branch-protection script's classic-protection field, the live required-reviewer read IS the load-bearing assertion, so passing on an unreadable response would recreate the vacuous gate the check exists to close. A hosted token that cannot read the environment must turn the check red.
- [202-04]: `distribution-sync` required `needs.smoke-published.result == 'success'` in its `if:`, not only a `needs:` entry — the job carries `always()`, under which needs: membership orders execution but does not block. Without the result clause the attestation row could still be written after a FAILED smoke run with every gate green.
- [202-04]: Live API observation (2026-09-22) confirmed the logged endpoint assumption: `GET /repos/{owner}/{repo}/environments/production-hex` returns 200 with `protection_rules[].type == "required_reviewers"` and one reviewer, and `prevent_self_review: false` — which is why the approval is documented as a confirmation step, not peer review.
- [202-04]: RELEASE-05 stays OPEN. It is co-declared by 202-05, and its remaining clause (the smoke job resolving the just-published version from hexpm) is observable only in a real release run — marked `verification: backstop`, not manufactured.
- [197-05]: Debt seed #9 re-measured fresh (2026-08-27 full mix test): (undefined_table) count = 0 — the ALTER DATABASE search_path fix is in effect; register row closed-in-environment with a CI reopen-trigger, not an open ~81-failure row.
- [197-05]: copy_contract_test.exs:249 red (stale "Selected schema readiness" pin vs landed 842bd737) discovered and registered rank 2, not auto-fixed (caused by 197-02, out of 197-05 scope); Phase-185 coverage doc-contract copy lock registered rank 5 with owner + concrete trigger.
- [197-05]: GATE-02 true auto-write stays register-as-debt per OQ-1 with trigger N=3 consecutive accepted iterations where the surfaced mechanical diff was applied verbatim with zero human modification.
- [195-02]: Rubric Anchors pole cell-ids use page-level Tier-A scorecard cells (`page.*__theme-breakpoint` format); `footgun.*` and `primitive.*` are conceptual quality labels in the ledger only, not committed scorecard files. All 11 pole cell-ids (pass + fail across 6 lenses) verified against `.planning/scorecards/`. sha8 placeholder `00000000` is intentional — Plan-04 rubric-hash guard recomputes from disk.
- [193-02]: CLOSE-01 clauses 3 & 4 delivered as `193-RISK-REGISTER.md` + `193-NEXT-STEP.md`. Register is a verify-and-refresh of the 189 ledger (rows 1-3 CLOSED by 190/191/192, rows 6-12 preserved) ranked on the adoption/ops/maintainer lens (D-10/D-12); four post-189 residuals folded in with Owner + reopen-trigger — R-A ship-gated D-17/D-19 (rank 1, ops), R-B/WR-01 alt-schema FK-fixture gap (rank 2), R-C charter-test drift (rank 3), R-D ~81 local failures framed as maintainer-friction NOT a regression (rank 4, below R-A/R-B). Next-step is a single HOLD/thin-polish recommendation backed by three converging gates + config policy (`no_auto_new_milestone` → recommends, does not open v1.40) with five armed flip-triggers (EXT-PILOT-01, OBS-01, UI-REG-01, RECONNECT-01 + CI-depth track). No `/gsd-audit-milestone` run, no `v1.39-MILESTONE-AUDIT.md`, no version/tag change (D-01/D-02/D-03). Commits `92fcb932`, `04dd00e8`.
- [192-03]: Release publish-race serialization scoped to the `publish-hex` job (`group: release-publish-${{ github.ref }}`, `cancel-in-progress: false`); the workflow-level `run_id`-embedding no-op group was removed so release-please bookkeeping stays independent of long publishes (D-24). `gate-ci-green` + the idempotency skip remain the real race guards; no `run_id` in the publish group; no `:latest`.
- [192-03]: CONTRIBUTING two lists reconciled without conflating them — List 1 "Stable job keys" table 8→10 (adds `verify-hex-evaluator`, `verify-example-browser`) mirroring the ci.yml header contract (D-25); List 2 branch-protection required checks renamed `Run test suite (verify-test)` → `Run test suite (min)` / `Run test suite (current)` (D-19) while staying a deliberate subset. The GitHub branch-protection reconfig itself is the human step in Plan 04.
- [192-03]: Version support contract made explicit (Elixir 1.15 floor / 1.17.3 current, OTP 26 min / 27 current, PostgreSQL 14 min / 16 current) in README "Supported versions" + a `mix.exs` comment; `elixir: "~> 1.15"` string unchanged — the floor is honored by the CI min lane, never by raising the requirement (D-13/D-14).
- [192-02]: Cache `deps/` (source only) never `_build`; caches change speed only so `mix ci.all` still reproduces CI byte-identically and every gate keeps its teeth (D-06/D-10/D-12). Playwright/npm caches keyed to the e2e subtree lockfile, never folded into the root `mix.lock` key (D-09).
- [192-02]: `verify-test` gains a base-axis `lane: [min, current]` matrix + `include` (elixir/otp/pg/runner), so GitHub posts exactly `Run test suite (min)`/`(current)` (RESEARCH M1 construction A); min lane = 1.15/otp26/pg14/ubuntu-22.04 runs compile-strict + `mix test` only, heavier steps gated `if: matrix.lane == 'current'` (D-15/D-18/D-19). Branch-protection rename is a human-gated step in Plan 04.
- [192-02]: Pinned `edoburu/pgbouncer:v1.25.2-p0` (no `:latest` in ci.yml) + PR-scoped `concurrency` cancelling only superseded pull_request runs (push-to-main and release-PR dispatch land in distinct groups) (D-22/D-23).
- [191-02]: ADOPT-03 routing uses intent VERBS (Evaluate/Adopt/Operate/Contribute), split by medium (Option C): README `## Start here` owns the routing prose (a three-column "I want to... / Start here / Then read" intent table), ExDoc `groups_for_extras` owns the sidebar structure (four matching verb lanes, explicit per-file regexes, all 20 extras in exactly one lane). The flat `## Documentation` dump is replaced (not deleted) by a collapsed `<details>` all-guides index grouped by the four verbs — no new guide (ADOPT-03/D-191-17 refute holds). New `persona_routing_doc_contract_test` asserts the subset (four keys + each README landing) + refutes start-here/where-to-go-next; `release_artifact_contract_test` owns the exact groups-key equality, updated in lockstep so `verify.release` stays green. P1–P5 operator-UI personas + ia_lock untouched.
- [191-01]: The 0.6.x->0.9.x era was surface/DX/proof-lane only (zero host-DB migrations), so the upgrade guide's affirmative "nothing required" is the factually-correct default per bump. The one migration-shaped expectation is storage-schema freeze-at-generation (Phase 190 D-190-14), kept distinct from host `table_schema`. Backport policy (patch on current minor; minor-crossing is deliberate) now stated in both `guides/upgrade-path.md` and `CONTRIBUTING.md`. Structural doc-contract test owns the theme/per-minor axis; version_truth (plan 03) owns the derived current-minor check.
- [v1.39-01]: v1.39 is a consolidation milestone. Recent work already built the demo, brand, light/system theme, design system, and page-by-page UI polish; the next trust risk is quality evidence, schema confidence, docs/version drift, and CI efficiency.
- [v1.39-02]: `storage_schema: "threadline"` remains the respectful default, with `public` requiring explicit opt-in. v1.39 must prove or fix custom-schema behavior before leaning on that posture publicly.
- [v1.39-03]: CI/CD changes must be measured, boring, and reversible. Baseline first; then fix cache/setup/service/release/version-policy gaps without hiding risk.
- [v1.38-01]: PhoenixStorybook is scoped to `examples/threadline_phoenix` for development/design review only. Root `threadline` keeps optional Phoenix/LiveView dependencies, no public component API, and `/audit/__stress` remains the canonical flow stress harness.
- [v1.38-02]: Page cleanup order starts shell/home/timeline, then Coverage, then detail/governance/export, then closeout. This fixes orientation and task flow first and reuses patterns on lower-traffic pages.
- [176-05] (checkpoint, human-approved option 1): T3 destructive pattern ships via "prune now" ONLY this phase; the redact destructive flow is DEFERRED. Redact has no runtime backend (codegen-time only); building one would touch the capture layer (v1.37 invariant violation). Prune is enforced server-side: secure_compare(typed, server-canonical policy name) + authz re-check + scope fail-closed + audit-the-action; client-only `data-confirm` deleted.
- [Phase 174-02]: Extended `<.field>` properties with global attribute pass-through (e.g. `list`, `maxlength`) rather than rigid structs, accommodating existing advanced filter functionality natively.
- [Phase 174-01]: Form components use explicit `name`, `value`, and `errors` rather than requiring `Phoenix.HTML.Form` structs to maintain isolation and independence from Ecto.
- [Phase 174-01]: Form primitives rely entirely on native HTML5 controls rather than custom JS elements for maximum browser compatibility and accessibility.
- [136-01]: Dark-only remains intentional; no `prefers-color-scheme`, no light mode, no theme toggle. *(Superseded by [165-01] in Phase 166 per THEME-04.)*
- [165-01] supersedes [136-01]: dark remains default and brand-primary; light/system are supported via host `theme:` config; no runtime theme toggle in v1; the `theme-toggle` ban remains.
- [136-01]: Lift muted/status contrast and make hover/focus/disabled states explicit through shared `--tl-*` tokens before per-screen polish.
- **130.1-02 (2026-05-29):** Nyquist waivers for doc-only phases 128–129; 130-VALIDATION superseded footnote; `mix ci.all` green at closeout.
- **130-02 (2026-05-28):** SUMMARY SSOT at `conventions/summary-frontmatter.md`; GAP IDs for 125–127 only; single `mix ci.all` in 130-VERIFICATION.
- **130-01 (2026-05-29):** Phase 125 archived under `milestones/v1.27-phases/`; `125-VALIDATION.md` finalized after Tier 1 green.
- **128-02 (2026-05-28):** phx-gen-auth mount uses `&MyApp.Audit.authorize_operator/1` with scope-first lookup and `is_admin: true` gate.
- **v1.29 posture (2026-05-29):** Hold for milestones; pre-pilot hardening: `mix verify.hex_evaluator`, WALKTHROUGH ConnCase tests; pilot pack queued.
- Full decision log: `.planning/PROJECT.md` Key Decisions table.
- [Phase ?]: Generalize actor helpers
- [Phase ?]: D-05 fix: setup rows actor-attributed and backdated
- [Phase ?]: D-06: named actor literals in Manifest
- [135-03]: Membership role change backdated outside 24h window (D-05 compatible); D-13 UPDATE satisfied by ticket/ticket_replies in-window mutations
- [135-03]: agent2 used for role flip to guarantee Ecto sends real SQL UPDATE (trigger fires)
- [135-03]: SavedView actor_ref uses type: :user (matches Timeline mount query for admin)
- [135-04]: D-03: Recipe table in DEMO-MANIFEST.md backed by demo_manifest_contract_test.exs; 24 rows covering all operator-surface screen states
- [135-04]: D-04 deferred: Coverage fully-covered/all-empty state noted as Phase-138-owned (trigger-registration dependent, not seed-reachable)
- [135-04]: demo_manifest_contract_test.exs kept separate from demo_manifest_test.exs (different concerns: doc vs module)
- [Phase 144]: Operation badge semantics stay in Presentation as pure helpers; no Phoenix component/public UI API expansion.
- [Phase 144]: Unknown operations use string-safe normalization with an empty modifier and uppercase fallback label; no String.to_atom/1.
- [Phase 144-03]: The v1.31 design-system freeze is source-first: style.ex and style_contract_test.exs govern the catalog.
- [Phase 144-03]: Phase 144 documents the local .tl-* and --tl-* system without Tailwind, build tooling, light/system theme support, external dependencies, or a public component API.
- [Phase 144-04]: POLISH-AUDIT and POLISH-DS are closed by Phase 144 verification while preserving the original roadmap-owner assignments.
- [Phase 150]: README/GitHub is the deciding surface for brand readiness; use `logo-primary-light.svg` on light documentation/repo surfaces and keep `logo-primary.svg` for dark/high-signal surfaces.
- [Phase 151]: Targeted revisions selected; alternate logo concepts, public rollout, and runtime UI changes remain out of scope.
- [Phase 152]: Brandbook-facing artifacts should present current brand truth; process history belongs in `.planning/`.
- [Phase 153]: Verification closeout UI remains static brandbook evidence only; no runtime UI, registry, component library, build pipeline, or committed raster export batch.
- [v1.34]: Helper-first dynamic localhost ports are canonical for local demo DX; Traefik is deferred and `.dev` hostnames are rejected for HTTP local demos.
- [v1.34]: Normal `bin/demo-up` refresh skips image rebuilds when the project image exists; `--build` is explicit for Dockerfile/dependency/base-image changes, and `--fresh` remains the volume-reset path.
- [v1.34]: Demo Dockerfile uses Docker/BuildKit's bundled frontend and installs `ca-certificates`; the base image is overridable via `THREADLINE_DEMO_BASE_IMAGE`.
- [v1.35]: Rollout to product surfaces (logo.ex, example-app favicon, README header) is an optional final phase (163), decided at that checkpoint with the winner in hand.
- [v1.35]: Seed drift is free exploration — round 1 may use OFL-safe typefaces and palette shifts; tokens/product UI change only if the winner demands it.
- [v1.35]: Hard logo constraints — no background chips on marks, logotype optically close to the mark, no subtitle in the primary lockup (separate `-subtitle` variant), user always picks the winner (never auto-selected).
- [v1.35]: All logo SVGs are pure paths (fontkit glyph-outline pipeline); zero `<text>` elements anywhere in candidates or final assets.
- [Phase 160]: Overlay baseline alignment via zero half-leading: line-height = (ascent-descent)*scale so live-text and SVG baselines coincide at ascent*scale
- [Phase 160]: Phase scripts reuse existing installs via module.createRequire anchored at the owning dir (fontkit via NODE_PATH, Playwright via e2e dir)
- [Phase 159]: 159-02: GitHub SVG sandbox verified empirically (default-src 'none'; style-src 'unsafe-inline'; sandbox) — pure-path SVGs are the only portable wordmark form; inline-CSS adaptive SVGs (Zig pattern) viable
- [Phase 159]: 159-02: Six technique names locked as Phase 161 motif vocabulary; gradient-dependence and gimmick-dependence (moz://a) named as paired antipatterns
- [Phase 159-03]: Motif distinctness defined at the (technique, letterform hook) pair level — 8 candidates need 8 distinct pairs; no technique repeats within a lane
- [163-01]: User opted IN at the rollout checkpoint ("Roll out now"); C13 shipped to logo.ex, example-app admin favicon, and the README header — style.ex untouched (freeze exception covers logo.ex only)
- [163-01]: logo.ex wordmark renders as pure brandbook paths; one non-rendering display=none `<text>` compat node preserves the in-flight nav-overhaul lane's header test contract until that lane lands (brand assets themselves stay zero-`<text>`)
- [Phase 159-03]: GAP-09/UP-08 raster export descoped to SOCIAL-PNG-01 (future); trademark descoped to human review; all other audit items routed to LOGO-*/TOUR-*/BOOK-* requirements
- [Phase 161]: 161-01: strategy matrix doubles Stroke continuation + Continuous-line mark (different hooks); all six BRIEF techniques used across 3/3/1/1 lanes
- [Phase 161]: 161-01: candidate ink uses currentColor with at most one flat accent (#4781E6 blue / #D9A03F gold); monos generated by color substitution only
- [Phase 161]: 161-01: BRIEF double-l-verticals hook mapped to the adjacent d/l ascender pair (no literal ll in Threadline)
- [Phase ?]: 162-01: Stitch arc stays #4781E6 on dark and light; #4F8CFF remains UI accent; #4781E6 recorded as additive stitch-blue raw token in plan 02
- [Phase ?]: 162-01: favicon uses Ink #0F1728 default strokes with internal prefers-color-scheme dark flip to Fog #D7DEEA (standalone equivalent of C13 currentColor design)
- [Phase ?]: 162-01: tagline outlined at 0.24em (240-unit) tracking, justified to wordmark ink edges; examples pruned to readme-header + docs-page
- [Phase ?]: 162-02: Brand book clear space = half cap height for lockups, quarter-size for mark/favicon; minimums 120px lockups / 180px subtitle / 16px mark+favicon (wordmark legibility governs)
- [Phase ?]: 162-02: Stitch Blue #4781E6 added additively to tokens (raw stitch-blue + semantic logo-arc, both lanes); #4F8CFF stays the interface accent; operator-surface values untouched
- [Phase ?]: 162-02: Misuse specimens live only as inline SVG in index.html; index.html inlines all 8 assets via shared pure-path defs; zero network under file://
- [Phase ?]: 162-03 pressure-test rerun
- [Phase 164]: Brand imagery specimens: pure-path linework with HTML labels over the SVG; Thread Blue carries the followable line, Signal Cyan the change ticks, Stitch Blue stays exclusive to the mark's arc
- [Phase ?]: [170-01]: full token parity = curated-subset parity (name + value equal in dark + light); brandbook corrected to style.ex, never the reverse
- [Phase ?]: [170-01]: brandbook<->style.ex drift now caught by brandbook_token_parity_test in both directions; pressure-test dim #11 bumped 8->9 (total 128->129)
- [Phase ?]: [170-02]: v1.36 audit doc authored; COMP-01/02 built+verified-live source-uncommitted; closeout pending-uat
- [Phase ?]: [170-02]: REQUIREMENTS COMP-01/02 token 'Verified (source pending)' (table + checkboxes); BRAND-01/02 Complete; archival+version bump -> /gsd-complete-milestone post-UAT
- [Phase 174-05]: search/date/number need no dedicated input clause — the generic input(assigns) default already emits type={@type} + tl-control; documented as passthrough and proven by contract tests.
- [Phase 174-05]: New form components compose existing classes/BEM modifiers (tl-error-summary__*, tl-radio__*, tl-switch, tl-combobox__*) rather than add any new --tl-* token, keeping style.ex untouched and brand-parity green.
- [Phase 174-05]: combobox confines JS to ARIA state via Phoenix.LiveView.JS (popover/dropdown precedent) — CSP-safe, degrades to free-text input, no Alpine, no new runtime deps.
- [Phase 174]: [Phase 174-06]: field_group renders the base tl-filter-group class + legend; timeline call sites pass only the --primary/--advanced modifier and drop the duplicated raw legend.
- [Phase 174]: [Phase 174-06]: formless guard scans each page's own source (not surface_header), excluding the legitimate hidden _csrf_token and theme-picker form without an explicit allowlist.
- [Phase ?]: [175-01]: CSP guard combines specific onclick/onchange refutes + explicit handler list + broad on*= regex (mitigates T-175-01); breadcrumb_test drives the live actor drill-down with a legacy-landmark fallback; skip_link_test follows the Timeline mount live_redirect.
- [175-03]: One internal `UI.page_header/1` (single `<h1>`, `:heading`/`:lede`/`:actions`/`:inner_block` slots, ordered `breadcrumbs`) adopted across the operator pages; reuses existing CSS only (no style.ex change, no new `--tl-*` token, no public API). Drill-down pages (Transaction/Actor/standalone Row history) carry location-based breadcrumbs under `<nav aria-label="Breadcrumb">` rooted at "Timeline" and pass `current={nil}` so the single `aria-current="page"` lives only on a shell nav link (the inlined CSS `[aria-current="page"]` selector pinned by style_contract counts page-wide, so nav must mark nothing current on drill-downs). Timeline command toolbar + Coverage command-center state kept bespoke single-`<h1>` (specialized command structures pinned by timeline_live_test / aria-labelledby). D-02 doc-contract back-link assertions re-pointed to the D-13 breadcrumb root (Rule 3). Both NAV-01 Wave-0 RED targets GREEN; transaction_live/skip_link/CSP locks + brand-token parity green. Commits `025e9d3`, `3e4b1c7`.
- [175-04]: One internal `UI.pager/1` (de-emphasized Older/Newer time-axis controls + a `role="status" aria-live="polite"` range caption) over the EXISTING keyset engine — hide-at-zero (D-16), disable-not-hide on boundaries (D-18), capped "10,000+" deep total (D-17); controls emit the host page's existing next-page/prev-page events (no engine change). Adopted next-only on Timeline (cursor stays in socket assign, D-19) and bidirectionally on Actor; Exports/Retention get honest "Showing latest N" cap captions (D-20), Coverage/Redaction none. `pager_test.exs` (the binding RED target) drove the signature (`shown`/`match_count`/`has_older`/`has_newer`), with optional `older_event`/`newer_event` phx-click attrs for adoption (`newer_event` is `:any` so Timeline passes nil). query.ex documents the `(captured_at, id)` keyset tiebreaker as DEFERRED capture-layer perf debt (D-15/Q1, T-175-10 accepted) — doc note only, no migration, capture layer byte-for-byte untouched. Zero new `--tl-*` token (brand-parity green). All 4 NAV-02 Wave-0 RED targets GREEN; verify.test 1008/0; credo clean. Commits `1a230bd`, `ac6f762`.
- [175-02]: Shell is CSP-proof — all three inline handlers removed (theme onchange, nav onclick, skip-link onclick); theme picker rebuilt as visible native radios + explicit "Apply theme" button + pure-CSS `.tl-theme-picker__option:has(:checked)` non-color cue (zero new tokens); mobile nav is native `<details>` keyed on `[open]`; scroll-padding-top reconciled to the per-row scroll-margin-top token + overscroll-behavior:contain + 100svh; router macro doc corrected; theme-toggle ban lifted in style_contract_test for a positive CSP guard; backend untouched (D-09).
- [176-02]: Built the internal `OperatorSurface.UI` data-display + data-state family: `ref/1` (binds `data-tl-copy={full}` on `<code>` + gated button, never `.title`/`.visible` D-02; zero-JS renders full D-06; `copy_label` required no-default D-07), `kv/1` (tl-kv `<dl>` + required `:item key` slot D-08), `data_table/1` (`:col label` feeds `<th>` + every `<td data-label>` from one source, rows|stream `phx-update=stream`, row_id, row_status `data-status` stripe, `:action` kebab, no ARIA table roles D-09), `loading_state/1` (role=status + aria-busy + spinner + text node D-13), `stale_banner/1` (role=status `tl-alert--warning` strip above data with `as_of` + Retry D-14), `empty_state` variants `no_data`/`permission`/`unavailable` + `role`/`icon`/`focus_heading` (D-15 focus rescue = generated heading id + `tabindex=-1` + `phx-mounted={JS.focus}`, CSP-clean), and `data_state/1` typed-reason dispatcher (distinct role+icon SHAPE+heading per reason; unavailable sub-cases state "not a permissions issue" D-16). `data_state/1` was a Rule-2 add — the Plan-01 `data_state_mapping` wave-0 test calls it; it is now GREEN. `copy_label` required-attr enforcement is a compile WARNING (Phoenix attr semantics), asserted via CaptureIO. 10 stress stories (ref/kv/data_table + 7 data-states) registered with matching `.planning/design-system-ledger.json` + `DESIGN-SYSTEM.md` rows (Rule-3 coupling — ledger test requires registry↔ledger↔projection parity). Zero new `--tl-*` token; brand-parity + style_contract green; no style.ex change. No page migrated (plans 03/04/05). 6 cross-plan Wave-0 scaffolds remain RED by design (1 card-nesting→03, 5 retention T3+ref-copy→05). Commits `d3273d3`, `617eb47`, `8c880a6`, `93a8027`, `9e17e86`. Capture/semantics untouched.
- [176-01]: `Presentation.ref/2` → `%{visible, title, full}` reuses `secondary_ref_value/1` for `full` (no value-extraction rebuild, D-01); `title == full`. `truncate_middle/3` gains additive `:tail_min` (≥N tail chars survive verbatim; no-`:tail_min` path byte-for-byte unchanged so `export_summary/1` is unaffected, D-03). `value_token/1` truncates at 56 keeping full in `:title`. Per-kind `truncate_for/2` (uuid/correlation/arn/actor/hash/path/email/url/timestamp; `:timestamp` never truncates). Source-down glyph is `:cloud_off` (not `:plug`); `archive` reused for pruned. The four MISSING Wave-0 tests use a self-contained tokenizer/regex (no Floki — not a project dep, v1.37 zero-new-dep invariant); `RefCopyContract` lives in `test/support` (only `test/support` is on the compile path). card-nesting regression treats the synthetic `tl-coverage-command` shell as a card-family surface so it is genuinely RED on coverage today (literal card>card alone would false-green). 9 new assertions RED (3 data-state + 1 card-nesting + 5 retention/ref-copy), all turning GREEN in Plans 02/03/05. Commits `989f03c`, `45a788d`, `a4a13fa`, `3503fdc`. Capture/semantics untouched. Pre-existing `ui_test.exs` format drift logged to deferred-items (out of scope).
- [176-04]: Flattened the coverage "schema" command shell — the DATA-05 / `coverage-schema-card-declutter` target. The success branch's hand-rolled `<section class="tl-coverage-command">…<h1 class="tl-page__title">` header is replaced with `UI.page_header` (title + `:lede` + `:actions` Refresh + a NEW optional `:meta` slot carrying `Presentation.checked_label`); all three branches now use page_header. The synthetic `tl-coverage-command` shell is demoted so trust-rail / `tl-summary-grid` metric tiles / remediation / table become direct page-stack `<section>` siblings (D-11 one card boundary per logical unit); `tl-card--metric` tiles kept, `__metrics` modifier dropped (bare `.tl-summary-grid` supplies the margin). Dead `tl-coverage-command__*` CSS deleted from style.ex (base + tablet) with the paired `refute String.contains?(src, "tl-coverage-command")` style_contract lock added in the SAME commit (T-176-08). **Rule-2:** added an optional `:meta` slot to `UI.page_header` (the plan's key_links require it but plan-175's component lacked it; defaults to `[]`, backward-compatible for every other call site). **Rule-3:** swapped the 3 style_contract assertions that pinned the deleted CSS for the refute lock. Task 2 (system-wide nesting sweep) needed NO source change beyond Task 1 — the card-nesting regression test (renders all 11 surfaces, refutes card-under-card) went GREEN the moment the shell flattened; coverage_live.ex was the only card-nester, so the plan stayed disjoint from plan 05 (retention/redaction untouched). Full operator_surface suite 545/5 — down from 6 RED (card-nesting now GREEN); the 5 remaining are the plan-05 retention T3 prune (4) + ref-copy (1) Wave-0 scaffolds. Zero new `--tl-*` token; brand-parity + style_contract green. Commit `157398d`. Capture/semantics untouched.
- [177-03]: Wave-3 meta-components + breadcrumb truncation. Shipped `@doc false` `UI.data_panel/1` (state-coordinating SHELL: a cond maps the generic state atom — ok|loading|empty|no_data|error|permission|unavailable — onto the EXISTING named state family; NO variant= switch, NO reinvented focus logic; `:permission`/`:unavailable`→`data_state(@reason)` collapses the body preserving the lock/cloud_off forensic distinction + delegating focus rescue D-06c; `stale_banner` rendered ABOVE the region as a cond-sibling, never replacing :ok data D-176-14; pager only when :ok), `UI.toolbar/1` (role=search + `aria-disabled` via `to_string/1` so it emits "true"/"false" + `is-disabled` affordance on `tl-cluster`; documents the page's HTML-`disabled`-on-controls enforcement contract, Pitfall 6), and `UI.detail_header/1` (`<h2>` not `<h1>` per D-175-03 + `justify=end` actions cluster + `kv` metadata from `<:metadata key=...>` slots). Reconciled breadcrumbs by KEEPING the `page_header` list attr (D-14, not a slot per D-04 literal) and truncating the current crumb via `.tl-transaction__breadcrumbs-current { max-width: clamp(12ch,50vw,40ch) }` so the header never horizontal-scrolls at 320px. Added `.tl-data-panel`/`__region`(opacity cross-fade on `--tl-motion-fast`, D-10.2)/`__pager` + `.tl-toolbar`/`.tl-detail-header` CSS (no new tokens). **Rule-1 (self-caught):** the first draft added a `@media (min-width:768px)` block + a "~1ms" CSS comment, reddening 4 phase-141/142 StyleContractTest source-governance assertions (exact min-width literal set; ungoverned `\d+ms`); replaced with `clamp()` (no new media literal) and rephrased the comment, returning the suite to the 2 RED-by-design Plan-04 scaffolds (verified identical to baseline `ac78693`). All 7 component RED scaffolds GREEN; ui_test+page_header 64/0; full suite 1071/2 (2 = Plan-04 overlay/offline, by design); warnings-as-errors + format + credo (2113 mods/funs) clean; brand parity 4/0. GROUP-01/GROUP-02 deliberately NOT marked complete (phase-spanning, complete at Plan 05). Zero new dep; no public API; capture/semantics untouched. Commits `1f4d6d7`, `2b082f8`, `19ef009`.
- [177-02]: Wave-2 layout primitives + semantic gap tokens. Added `--tl-gap-inline`/`--tl-gap-stack`/`--tl-gap-section` to all three sources (tokens.css/tokens.json/style.ex) in ONE task so brandbook_token_parity_test never drifted (8/16/32px → --tl-space-2/4/8). Shipped `@doc false` `UI.stack/1` (gap: stack|section|inline|tight, default stack; tight→--tl-space-1/4px) and `UI.cluster/1` (justify: start|between|end, default start) following the card/1 class-list idiom, with `.tl-stack`/`.tl-cluster` CSS owning inter-child spacing via flexbox `gap` over --tl-gap-* tokens (no raw child margins, GROUP-01/D-02). Turned the Plan-01 gap-parity + stack/cluster render RED scaffolds GREEN. data_panel/toolbar/detail_header scaffolds left RED by design (Plan 03 owns them per task scope + verification_note, despite some test-name tags reading "[RED — Plan 02]"). Zero new dep; no public API; capture/semantics untouched; format + credo clean. Commits `8d701e8`, `38005a3`.
- [177-01]: Wave-0 conflict resolution + RED test scaffolds (zero production code). **Conflict 1 (offline anchor):** confirmed by grep that all 11 audit LiveViews render `<div class="threadline-ui">` as their render root, so the offline-group CSS (Plan 04) keys off `.threadline-ui.phx-loading`/`.threadline-ui.phx-error` (the LiveView ROOT), NOT `<body>`, and NEVER `.phx-disconnected` (which doesn't exist in LiveView 1.x — the dropped-socket state re-applies `.phx-loading`). Corrects the literal wording of D-08/UI-SPEC per RESEARCH Pitfall 1; resolves Open Q1 / A2. **Conflict 2 (breadcrumbs):** keep `page_header/1`'s existing `attr(:breadcrumbs, :list)`; do NOT add a same-named `:breadcrumbs` slot (Phoenix forbids attr+slot name collision → compile error). Deliberate deviation from D-04's literal "slot" wording, justified by D-14 discretion (breadcrumbs are location DATA, not arbitrary markup) + RESEARCH Pitfall 4; Plan 03 adds narrow-viewport truncation only. **Token decision:** `--tl-gap-section`→`--tl-space-8` (32px), `--tl-gap-inline`→`--tl-space-2` (8px), `--tl-gap-stack`→`--tl-space-4` (16px) (D-09 / RESEARCH A1). Laid 12 RED scaffolds (3 source/parity in brandbook_token_parity_test + style_contract_test; 9 component renders in ui_test for stack/cluster/data_panel×4/toolbar×2/detail_header) + 1 GREEN breadcrumbs-trail test. Full suite 1071/12 — every failure is a new expected RED scaffold; no pre-existing regression. RED is the deliverable (Plans 02–05 turn green). Zero new dep (v1.37 invariant). Commits `bede897`, `4b7e304`.
- [176-03]: Migrated the display/read-only operator pages onto the Plan-02 components (non-destructive consumer migration; coverage/retention/redaction are plans 04/05 and were NOT touched). Transaction copy footgun closed — transaction id + correlation id + diff before/after cells all bind `data-tl-copy={full}` via `UI.ref/1` (never `.title`/`.visible`/`.text`, D-02); transaction metadata → `UI.kv`; diff cells truncate via `value_token` (max 56) + gated per-cell copy bound to the full value (`diff_full/1`, D-04); timestamps in semantic `<time datetime=exact_time>` UTC (D-22). actor/timeline/evidence/export migrated to `UI.ref` (copy=full) + `UI.kv` (export per-job + both export-context `tl-param-list` retired). Per-page data-state: actor + timeline branch ok-empty into `empty_state variant=never` (first-run, history) vs `no_data` (narrowing filter active, funnel) — distinct icon SHAPE (D-17); evidence `no_data`; export `never`; invalid-actor-ref → `error_state`. **Rule-1 bug:** `UI.ref` used `String.to_existing_atom(kind)` which raised for `:correlation`/`:arn`/`:actor`/`:email` (atoms not interned) — added `Presentation.kinds/0` + `kind_from_string/1` (literal `@ref_kinds`, compile-time interned) and switched `UI.ref` to the safe resolver. **Rule-3:** `UI.ref` can't nest in an `<a>` (button-in-anchor) — copyable ref renders standalone, deep-link demoted to sibling Timeline/Actor affordance. `.tl-secondary-ref` CSS double-truncation removed (`text-overflow:ellipsis` gone, `overflow-wrap:anywhere` kept, D-05) with the paired `style_contract_test` assertion (refute ellipsis + assert wrap) updated in the SAME commit. Zero new `--tl-*` token; brand-parity + style_contract green. 213 targeted tests green; the 6 remaining operator_surface failures are the documented cross-plan Wave-0 RED scaffolds owned by plans 04/05 (1 card-nesting + 5 retention T3/ref-copy). Commits `e1650c8`, `32b0977`, `a798147`. Capture/semantics untouched.
- [Phase ?]: [177-04]: Completed the motion + connection-lifecycle layer — overlay JS-transition utility CLASS selectors + modal/drawer/toast shells (overlay motion now real), every overlay JS.show/hide synced to time: 180 (=--tl-motion-base), toast fade-up via show_toast/2; reconnect/offline group keyed off the LiveView ROOT .threadline-ui.phx-loading/.phx-error (NOT body, NEVER the legacy disconnected class — Pitfall 1) with a warning-tinted role=status banner + [data-tl-mutating] disable + UI.reconnect_banner/1 documenting the mutating-link aria-disabled/tabindex=-1 contract (Pitfall 6). Both Plan-01 style_contract RED scaffolds GREEN; full suite 1071/0; compile/format/credo(2115)/brand-parity clean; zero new keyframes/tokens/deps; capture/semantics untouched. GROUP-01/02 NOT closed (Plan 05). Commits da4a36d, f1695a1.
- [Phase 178]: [178-06] D-11 corrected: LiveView lifecycle classes attach to [data-phx-main]; reconnect CSS scopes into .threadline-ui. — Real-engine socket-drop verification proved the prior .threadline-ui lifecycle-anchor premise false.
- [Phase 178]: [178-06] Real socket-drop proof must assert visible banner and computed mutating-control dimming/restoration, not lifecycle-class detection alone. — The closure bug was masked by tests that observed class flips without asserting visible/computed behavior.
- [Phase 179]: Shell IA relabeling changed only visible group labels — Preserved nav ids, route hrefs, current atoms, data-testids, and destination order for adopter/bookmark stability.
- [Phase 179]: Home uses task-led job titles with existing workflow destinations — Matched Phase 179 IA while keeping Timeline, Coverage, Evidence, Redaction, Retention, Exports, row-history, and correlation workflows unchanged.
- [Phase 179]: Shared state grammar stays in existing UI and Unsupported helpers — Plan 179-02 normalized state, validation, unsupported, and export-denied copy without adding a copy registry, dependency, LiveComponent, route, or new capability.
- [Phase 179]: 179-03 kept actor, transaction, row-history, and coverage copy inside existing page modules. — No route, public API, dependency, LiveComponent, or capability was added.
- [Phase 179]: 179-03 uses covered for table status and need capture for remediation. — This preserves audit-readiness language without overclaiming complete timeline answers or proof that capture is complete.
- [Phase 179]: 179-04 keeps Timeline explanatory copy below filters, result status, investigation checks, export actions, saved views, and rows.
- [Phase 179]: 179-04 Timeline invalid-filter and unknown-table copy names the failed object and next action while preserving parser/audited-table details.
- [Phase 179]: 179-04 e2e assertions were aligned to current shell, retention modal, and seeded Timeline row-history contracts.
- [Phase 179]: Evidence/export copy now reserves proof-history language for append-only history/detail contexts while using Evidence for current state and handoff labels.
- [Phase 179]: Redaction LiveView preserves the shared Drift detected status-label contract while rendering Redaction drift detected as page-level governance copy.
- [Phase 179]: Retention destructive actions consistently name the retention window and permanent pruning consequence.
- [Phase 179]: Phase 179 stress copy evidence was added to existing story ids only; no stress story, ledger id, route, selector, density knob, capability, ledger row, or DESIGN-SYSTEM projection was added. — Preserves COPY-03 and D-17 stability while adding durable copy-state evidence for final Phase 179 terminology.
- [Phase 179]: The component matrix remains available for component/state/foundation stress stories, but page, footgun, and future-reserved screenshot targets stay bounded to preserve the Phase 178 ledger baselines. — Keeps ledger-owned screenshot baselines useful while avoiding screenshot churn from unrelated component stress content.
- [Phase 180]: 180-01: Use existing Playwright operator accessibility spec for rendered-state A11Y-01 proof; no axe scan or new dependency was added.
- [Phase 180]: 180-01: Use shared LiveView JS overlay helpers for focus entry/restoration where possible, with stress-route-only fixtures for missing rendered state coverage.
- [Phase 180]: 180-01: Classify examples/threadline_phoenix mix precommit demo seed failures as inherited/non-owned for this plan.
- [Phase 180]: [Phase 180-02]: APG guardrails stay implementation-specific: custom widgets get specific ARIA popup/relationship hooks, while native select/input/table behavior is asserted instead of role-inflated.
- [Phase 180]: [Phase 180-02]: Tabs and segmented controls use actual rendered selectors for target sizing and non-color selected-state cues; stale selector rules are removed.
- [Phase 180]: [Phase 180-02]: No dependencies, audit frameworks, public routes, public component APIs, or stress-route auth behavior were added.
- [Phase 180]: [Phase 180-03]: MOTION-01 guardrails stay in the existing style contract and operator-motion Playwright harness, preserving enabled press feedback while collapsing reduced-motion behavior without new dependencies.
- [Phase 180]: [Phase 180-04]: Replaced the manual screen-reader checkpoint with Playwright accessibility-tree snapshots and explicit proof limits; no real assistive-technology UAT is claimed.
- [Phase 180]: [Phase 180-04]: Dynamic E2E ports require LiveView origin checks to be disabled in Phoenix test config only; production origin behavior is unchanged.
- [Phase 180]: [Phase 180-04]: Screenshot regression guards now discover current `ticket_replies` seeded rows instead of stale #4521 correlation assumptions, and local desktop/mobile baselines were refreshed from current rendered output.
- [Phase 180]: [Phase 180-04]: Retention destructive modal tests must open the conditionally mounted modal before asserting or submitting `form[phx-submit=prune_now]`.
- [Phase 181]: Plan 01 keeps screenshot evidence tiered: partial Tier C PNGs are committed, failed cells are recorded with owners, and CI screenshot allowlist remains bounded. — This preserves D-181-07/D-181-08 while avoiding a full page x path x theme x viewport pixel matrix.
- [Phase 181]: Plan 01 adds a desktop-1024 responsive viewport row without changing operator routes, data-testids, capture/query/auth semantics, public APIs, or dependencies. — The new row extends the bounded rendered-slice matrix required by D-181-07 and records current stale Timeline discovery failures for repair.
- [Phase 181]: [181-02] 181-03 owns stale E2E/demo-seed discovery and copy assertion repair; Timeline/Coverage page polish remains deferred to 184/185. — Recorded in 181-02-SUMMARY.md key-decisions.
- [Phase 181]: [181-02] 181-04 owns active source-test prose that still says RED today/RED until after the guarded behavior landed. — Recorded in 181-02-SUMMARY.md key-decisions.
- [Phase 181]: [181-02] Local screenshot skips and stress bad-param strings are intentional guards/fixtures, not defects. — Recorded in 181-02-SUMMARY.md key-decisions.
- [Phase 181]: 181-03 replaced stale issue-number/correlation E2E contracts with current ticket_replies table-filter discovery, transaction href navigation, row-history redaction, and DELETE-row actor transaction checks. — Recorded in 181-03-SUMMARY.md after the targeted Playwright suite passed 18/18.
- [Phase 181]: 181-03 kept adjacent stale browser families outside the declared file contract as residual ledger ownership instead of editing out-of-scope files. — Plan 03 files were explicitly limited to operator.spec.ts, operator-screenshots.spec.ts, and 181-GUARD-REPAIR.md.
- [Phase 181-04]: Plan 181-04 repairs active source-test prose and failure messages while preserving executable assertions, route paths, feature gates, public APIs, and production source. — Plan scope is documentation/prose in tests and guard ledger; behavior remains unchanged.
- [Phase 181-05]: Route/export/stress/header boundaries are locked through source contracts rather than rendered UI redesign. — Plan 05 protects server route/auth/export and feature-gate invariants without changing operator IA or layout.
- [Phase 181-05]: Feature-gated nav group IDs are additive semantic hooks only. — Existing destination IDs, hrefs, copy, active-state semantics, and public component API remain unchanged.
- [Phase 181-05]: Root threadline continues to exclude PhoenixStorybook/Storybook and production story/stress routes. — Phase 182 owns example-app dev/test Storybook; root optional Phoenix boundaries stay intact.
- [Phase 181-06]: 181-06 leaves .planning/design-system-ledger.json, DESIGN-SYSTEM.md, stress fixtures, stress route source, and stress tests unchanged because the existing source-contract slice is green.
- [Phase 181-06]: The three bounded screenshot allowlist cells remain page.home.happy, page.timeline.empty, and footgun.transaction-page-left-push-desktop; broader screenshot freshness remains owned by 181-07 through 181-10.
- [Phase 181-baseline-audit-and-guard-repair]: Stress CI screenshots now read `.planning/design-system-ledger.json` `screenshot_allowlist.ci` directly instead of a separate hardcoded allowlist. — Bounded stress screenshot guard stays ledger-backed and matrix-bounded while local packet evidence remains outside CI baselines.
- [Phase 181-baseline-audit-and-guard-repair]: The selected happy/error/permission/boundary stress-state PNGs are local-only planning evidence, not CI `toHaveScreenshot` baselines. — D-181-07 needs Tier C evidence without expanding the accepted Tier B screenshot ratchet.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 08 found all existing operator-screenshot-regression desktop/mobile local PNG baselines current, with no accepted Plan 09 or Plan 10 PNG updates discovered.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 08 preserved the generic chromium local screenshot-regression skip as intentional platform-sensitive guard behavior rather than expanding CI coverage.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 08 re-recorded the example-app mix precommit residual as inherited demo-seed/walkthrough drift, not local screenshot-regression or PNG baseline fallout.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 09 left all four Home/dense Timeline PNG baselines untouched because Plan 08 classified them as current committed local baselines with no accepted update.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 09 did not run --update-snapshots; the bounded Home/dense Timeline subset passed against existing desktop/mobile local baselines.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 09 re-recorded the example-app mix precommit residual as inherited demo-seed/walkthrough drift, not screenshot baseline fallout.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 10 left all six Row-history/Exports/Retention PNG baselines untouched because Plan 08 classified them as current committed local baselines with no accepted update.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 10 did not run --update-snapshots; the bounded Row-history/Exports/Retention subset passed against existing desktop/mobile local baselines.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 10 re-recorded the example-app mix precommit residual as inherited demo-seed/walkthrough drift, not screenshot baseline fallout.
- [Phase 181-baseline-audit-and-guard-repair]: 181-11: Full CI remains red but classified; Phase 181 closes on targeted guard evidence plus residual ownership, not by relabeling red gates as green.
- [Phase 181-baseline-audit-and-guard-repair]: 181-11: The local Tier C screenshot packet is complete planning evidence and does not expand the CI screenshot allowlist.
- [Phase 182]: Plan 182-01 is RED-only by design: it locks executable contracts before package, route, story, or documentation implementation. — Phase 182 implementation is split across later plans, so this plan intentionally commits failing contracts first.
- [Phase 182]: Storybook browser coverage stays bounded to index plus representative primitive/form/state/overlay/data-display/group stories; no screenshot matrix or external visual regression service was added. — D-182-20 requires bounded browser smoke rather than broad screenshot or SaaS visual-regression coverage.
- [Phase 182]: Root optional-dependency hygiene remains protected by source contracts and mix verify.compile_no_optional. — The plan adds tests only and proves no root PhoenixStorybook dependency leakage occurred.
- [Phase 182-02]: PhoenixStorybook remains an example-app dev/test dependency only; production compiles through a no-op router macro fallback when the package is absent.
- [Phase 182-02]: The maintainer Storybook lane is mounted at /dev/storybook outside /audit and outside normal operator navigation.
- [Phase 182-03]: Core Storybook category files use PhoenixStorybook page stories to document multiple private UI functions without promoting a public component API. — Plan 03 covers category pages, not one public component story per exported API; private operator components remain private.
- [Phase 182-03]: Storybook fixtures expose static samples plus an explicit StressFixtures allowlist, with no database, dynamic atom, ledger mirror, or full stress registry navigation. — This preserves D-182-06 and D-182-07 while giving stories representative ugly data.
- [Phase 182-03]: Overlays, Data Display, Groups, and Patterns received index metadata now to satisfy the RED category spine while later plans still own their story content. — The existing RED story contract required the full top-level category spine before Plan 04 and Plan 05 add those stories.
- [Phase 182-04]: Storybook coverage remains curated component documentation; /audit/__stress remains the flow-level stress harness.
- [Phase 182-04]: Groups sample StressFixtures only through an explicit Storybook helper allowlist instead of mirroring the ledger or full registry.
- [Phase 182-04]: The light/system Playwright lane includes Storybook only through operator-storybook.spec.ts and asserts that bounded contract.
- [Phase 182]: Phase 182 closes on targeted Storybook/package/route/story/browser/stress/docs evidence while classifying inherited example demo-seed and broad-suite residuals as non-green. — Plan 05 verification found all targeted Phase 182 gates green, while mix precommit and mix ci.all still include pre-existing residuals outside the Storybook/docs scope.
- [Phase 182]: Storybook remains example-app dev/test maintainer component documentation; /audit/__stress remains the authenticated operator-flow stress harness. — Docs contracts and 182-VERIFICATION.md preserve the root optional dependency and production-route boundaries.
- [Phase 182]: No schema push task was required because Plan 05 modified only docs and planning verification artifacts. — No schema, migration, SQL trigger, config, struct field, CLI flag, decorator, or dataclass-style field changed.
- [Phase 183]: Plan 01 remains RED/proof-only: browser failures are actionable Plan 02 evidence, not production retuning scope. — 183-01 adds the browser perception proof before shell/Home implementation polish and the plan explicitly allows actionable browser failures.
- [Phase 183]: The Phase 183 supplement is admitted to the existing system/light lane rather than adding a new Playwright project or screenshot matrix. — The plan forbids screenshot matrix expansion and requires preserving the THREADLINE_E2E_THEME=system desktop-chromium-light lane.
- [Phase 183]: Plan 183-02 kept native mobile details/summary navigation but moved the single nav panel to a sibling so desktop rail visibility does not depend on closed-details internals. — Chromium keeps non-summary descendants hidden in closed details, which broke the Phase 183 desktop browser proof.
- [Phase 183]: Plan 183-02 forced example e2e compilation before browser runs so THREADLINE_E2E_THEME compile-time router gates match the current lane. — The system/light lane reused stale dark-compiled router artifacts until the runner used mix compile --force.
- [Phase 183]: Phase 183 closes as targeted PASS with classified residuals: dedicated source and browser evidence is green, broad command failures remain non-green and scoped.
- [Phase 183]: Generated light screenshot candidates from broad verification were treated as verification byproducts and not committed as baselines.
- [Phase 183]: No package, schema, public API, route, data-testid, or adjacent page content change was accepted during Phase 183 closeout.
- [Phase 184]: Timeline row-history links are emitted only for rows with exactly one nonblank scalar primary-key value; unsafe identities keep the transaction pivot only.
- [Phase 184]: Timeline export handoff remains canonical-query driven through FilterParams and ExportController rather than duplicating filter semantics in the UI.
- [Phase 184]: The Timeline command surface reports result facts once through the facts/filter summary; duplicate status copy and its dead selector were removed.
- [Phase 184]: Timeline empty states now distinguish first-run, filtered no-data, and future-window copy through private reason helpers instead of a single future-window boolean. — This preserves distinct operator meanings for no captured changes, no matches, and future windows without adding a new component family.
- [Phase 184]: Timeline rows expose full table, actor, correlation, and safe row-id values for copy/title use while preserving transaction and row-history pivots. — Full values must remain available under long real data; direct row history remains gated by the existing safe routeable identity helper.
- [Phase 184]: No fake Timeline stale branch was added; stale/last-good proof remains with shared UI.stale_banner/data-state primitives because Timeline has no dedicated stale assign. — The plan explicitly prohibited fabricating Timeline-only stale states for coverage when no real branch exists.
- [Phase 184-03]: Use a narrow Timeline-only Playwright proof for required viewport/keyboard/copy/export/theme/reduced-motion coverage instead of broad screenshot baselines.
- [Phase 184-03]: Create browser proof correlation data through existing authenticated /api/posts setup rather than relying on stale demo seed correlations.
- [Phase 184-03]: Classify broad-suite residuals honestly while treating targeted Phase 184 source and browser gates as the closeout authority.
- [Phase 185]: Coverage now answers readiness through one selected-schema verdict and keeps table rows as triage/action detail. — Phase 185 COV-01/COV-02 required deleting repeated readiness signals while preserving row actions.
- [Phase 185]: Phase 185 browser proof stays narrow in the existing light/system lane; non-public schema link truth remains owned by deterministic LiveViewTest setup. — The plan prohibited broad screenshot matrices and had no deterministic example non-public schema fixture.
- [Phase 187]: DOC-01 source truth follows the current runtime server-posted theme picker, not older host-only theme prose. — Plan 187-01 repaired the operator guide and doc contracts against router, surface header, theme controller, and auth source truth.
- [Phase 187]: Storybook remains example-app dev/test maintainer tooling; /audit/__stress remains authenticated stress proof, not production public component documentation. — Plan 187-01 preserved optional dependency, production exclusion, private component, and stress route boundaries in docs and doc contracts.
- [Phase 187]: Plan 187-02 closed A11Y-01/A11Y-02 proof gaps with focused test-only coverage; no private UI or CSS repair was needed. — The new source/browser assertions passed against existing product behavior after proof-specific locator corrections.
- [Phase 187]: Plan 187-02 made no MOTION-01 source changes because existing source and browser-computed proof already covered the Phase 187 contract. — style_contract_test.exs and operator-motion.spec.ts passed unchanged for token, keyframe, transition, and reduced-motion requirements.
- [Phase 187]: Phase 187 closeout treats targeted source/browser/stress proof as green while preserving standalone screenshot and broad CI failures as classified residuals; no real screen-reader certification or screenshot stability claim is made from non-green evidence. — CLOSE-01 requires exact evidence, residual ownership, and proof limits rather than assertion-only closure.
- [Phase 188]: 188-01 queued export worker replay reuses FilterParams.parse/1 instead of a second parser — This preserves URL-shaped string-keyed ExportJob.query_params while ensuring from/to are DateTime filters before Threadline.Query runs and invalid params fail closed.
- [Phase 188]: .tl-copy uses explicit transition-property source governance — 188-02 replaced token-only shorthand with color, border-color, background-color, and box-shadow declarations, and StyleContractTest now rejects token-only transition shorthand.
- [Phase 188]: Phase 188 closeout used focused ExUnit/source evidence plus equivalent audit classification; no browser or screenshot proof was added because source contracts covered .tl-copy.
- [Phase 188]: Phase 188 preserves legacy broad CI, screenshot, Hex auth/advisory, and older Nyquist residuals as explicit audit residuals instead of relabeling them green.
- [Phase 189]: Phase 189 routes custom storage-schema proof and fixes to Phase 190 based on public docs plus fixed-prefix source evidence.
- [Phase 189]: Phase 189 treats screenshot, external pilot, and host staging claims as proof-boundary residuals instead of implementation scope.
- [Phase 190]: [190-01]: Generated install migration SQL uses Threadline.StorageSchema quoted identifiers for every validated storage-schema table, function, and drop/index reference touched by SCHEMA-03.
- [Phase 190]: [190-01]: Adopter docs now show storage_schema: "audit" before mix threadline.install and state that generated migration files freeze the configured schema name.
- [Phase 190]: [190-02] Threadline-owned Ecto schemas now rely on Repo prefix options instead of fixed @schema_prefix attributes. — SCHEMA-02 requires configurable storage schemas not to silently read from or write to hardcoded threadline.
- [Phase 190]: [190-02] Storage-schema test support is explicit and test-only; it does not add a production fallback or Repo hook. — Tests should make omitted prefix plumbing visible while later Phase 190 plans wire production Repo operations.
- [Phase 190]: [190-03]: Treat the per-transaction storage_schema option as authoritative for core audit writes, action linkage, audit-transaction lookup, and captured-change metadata.
- [Phase 190]: [190-03]: Query and investigation preloads must pass resolved storage options explicitly so association reads cannot fall back to the default threadline schema.
- [Phase 190]: [190-04]: Queued export and cleanup runtimes resolve storage_schema once per run/state instead of re-reading global config for each Repo operation.
- [Phase 190]: [190-04]: Export downloads resolve configured storage_schema before lookup and preserve actor authorization after the prefix-scoped fetch.
- [Phase 190]: [190-05]: Retention direct runs and pruner runtimes resolve storage_schema from explicit opts with global config as the default. — This preserves the Phase 190 global configured storage contract while making selected-storage sentinel proof deterministic for retention/pruner paths.
- [Phase 190]: [190-05]: Retention and pruner tests use audit/threadline dual-storage sentinels for destructive governance paths. — SCHEMA-01 requires wrong-prefix deletes, counts, inserts, and updates to be caught by tests, not inferred from source strings.
- [Phase 190]: [190-07]: Malformed host table identifiers now fail before SQL generation. — Empty or ambiguous dot segments could collapse into valid-looking identifiers and weaken host-schema trigger confidence.
- [Phase 190]: [190-07]: Continuity readiness treats selected support schema values as host table identity only. — `support.tickets` and `schema: "support"` select the host table for readiness checks without changing Threadline storage-schema reads.
- [Phase 190-08]: Selected redaction schema is host-schema only — Policy CLI and LiveView validate --schema/?schema with CoverageSchemas and pass it only to redaction catalog inspection; Threadline-owned storage_schema remains governed separately by repo opts.
- [Phase 190]: Timeline renders table_schema as host schema so operators do not confuse audited host schemas with Threadline storage_schema.
- [Phase 190]: Non-public row-history links require exact schema-qualified schemas keys such as support.tickets; public rows keep bare-table shorthand.
- [191-03]: ADOPT-01 install/version reconciliation — seven install pins flipped to three-segment ~> 0.9.0 (co-committed with four guard tests, no CI/release reddening); evaluating-threadline.md false 0.6.0 SSOT corrected to 0.9.0 + release-please marker/extra-files wiring (historical lines preserved); version_truth_doc_contract_test derives Families A/B/C from mix.exs @version and is registered in verify.doc_contract. Pre-existing v1_23_charter failure left deferred (charter truth out of this plan's task scope).
- [Phase ?]: [195-01]: verify.ui_critique is local-only (excluded from ci.all, exits 0 when ANTHROPIC_API_KEY absent, RUNNER-04). verify.critic_trust is pure-Elixir in ci.all before verify.mechanical. All 6 critic lenses seed validated:false. critic-scores/ tree is gitignored; .planning/golden/ is committed oracle.
- [Phase 198]: [198-38]: Repo.checkout/2 chosen over pg_advisory_xact_lock/Repo.transaction/2 to pin the demo lock critical section — the guarded body issues many independent per-seed Repo.transaction/1 calls by design and an outer transaction would collapse them.
- [Phase 198]: [198-38]: promote — Demo.Seed no longer maintains its own copy of the lock guard trio; Demo.Seed.run/0 delegates to Reset.with_demo_lock/1, eliminating the two-copies drift that produced CR-01.
- [Phase 198]: [198-39]: option-a — maintainer accepted GREEN-07/roadmap SC3 as permanently Pending for v1.41 at a blocking checkpoint:decision; verify-capture and verify-example-browser stay red by construction under D-39 for the whole milestone; no gate narrowed, no baseline regenerated. See 198-39-DECISION.md.
- [Phase 198]: The successful PR run supersedes Round 6's red-lane cause but does not close GREEN-07's separate origin/main exact-ancestry clause. — The run is pinned to an immutable branch subject while final local HEAD includes later mandatory GSD commits.
- [Phase 198]: No remote or ruleset mutation is attempted because mandatory evidence and summary commits postdate any finite in-plan push. — A pre-closeout ref update cannot contain commits that do not yet exist.
- [Phase 198]: GREEN-07 remains Pending because exact ancestry fails first and the canonical exact-SHA main run also concludes failure.
- [Phase 198]: GREEN-08 is re-proved from two identical complete editable-field ruleset digests plus active enforcement, no bypass actors, and one byte-exact required context.
- [Phase 198]: No remote or ruleset mutation is authorized; any future mutation requires a fresh blocking-human maintainer checkpoint.
- [Phase 198]: GREEN-07 remains Pending on exact ancestry and exact-main CI; PR #34 is branch-only evidence. — Preserve the requirement own predicate and the maintainer selected option-a disposition.
- [Phase 198]: GREEN-08 remains Complete for the exact required-context contract while roadmap criterion 4 remains partial. — Ruleset 21702804 is correct, but PR #26 remains BLOCKED downstream of GREEN-07.
- [Phase 198]: Phase 198 freezes its exact evidence compatibility contract while Phase 199 retains the generalized classifier. — Keeps gap closure repository-portable without absorbing the next phase scope.
- [Phase 198]: Operator login redirects must match BASE_URL scheme, host, effective port, and exact path. — A login-looking cross-origin Location is not proof that the local operator mount exists.
- [Phase 198]: Evidence subjects, not copied narrative prose, are the primary keys for policy joins.
- [Phase 198]: The GitHub boundary accepts only list-main-runs and view-run-jobs symbolic operations and constructs every argv token internally.
- [Phase 198]: [198-50] Treat the opt-in obscurer as proof of current assertion sensitivity, not proof of the historical failure's cause.
- [Phase 198]: [198-50] Keep the red-control environment read inside the single named scenario and reject unknown non-empty values explicitly.
- [Phase 198]: [198-50] Persist synthetic DOM identifiers and geometry only; exclude field values, cookies, headers, credentials, and environment data.
- [Phase 198]: Plan 198-51: maintainer selected abort verbatim; no branch, PR, tag, main, ruleset, or protection mutation authority was granted.
- [Phase 198]: Plan 198-52 must not execute: six remote ci/198-* refs exist while its decision authority covers only three and its final predicate requires the complete namespace empty.
- [Phase 198]: A preservation subject is keyed by side plus full SHA, so same-name local and origin refs never collapse. — Distinct handles require collision-free archive and restore paths.
- [Phase 198]: Plan 52 remains preserved but superseded; round-11 production evidence grants no mutation authority. — Fresh exact-subject authority is deferred to Plan 54.
- [Phase 198]: The maintainer selected retire verbatim for the exact nine round-11 side/SHA subjects bound to inventory digest 88888854b44111835d753261eb15332a7c98fae7922d65d0d46e6fc5423a4655.
- [Phase 198]: Plan 54 grants authority only to Plan 55's preservation-first sequence; Plan 54 performed no external mutation.
- [Phase 198]: Every round-11 side/SHA preservation subject has a verified local annotated tag, matching origin peeled object, and D-31 register join before its mutable handle was retired.
- [Phase 198]: GREEN-12 is Complete from empty live ci/198-* namespaces; GREEN-07 remains Pending and protected controls remain unchanged.
- [Phase 198]: Phase 198's audited summary set ends at Plan 59; Plan 60 is the sole non-recursive terminal certification exception.
- [Phase 198]: Normal summary validation accepts the exact present 48-59 subset; explicit final mode requires every audited summary 01-59.
- [Phase 198]: Production ref-disposition authority stages reject fixture adapters and use bounded fresh observations; synthetic lifecycle proof is fixture-* only.
- [Phase 198]: Completed round-11 receipts remain immutable historical evidence and are not retroactively upgraded into argv or timestamp proof.
- [Phase 198]: Plan 198-58: four mechanically knowable prohibitions close only from named passing tests; the historical command-method prohibition remains pending judgment.
- [Phase 198]: Plan 198-58: T-198-55-03 remains irrecoverable, below threshold, open, and not accepted.
- [Phase 198]: The recorded cannot-attest outcome leaves P-198-55-01 pending and is neither new mutation authority nor risk acceptance.
- [Phase 198]: T-198-55-03 remains open below threshold because no missing per-operation receipt fields were supplied.
- [Phase 198]: Phase 198 terminal certification audits summaries 01-59 while Plan 60 remains the sole tested non-recursive summary exception.
- [Phase 198]: Terminal evidence preserves T-198-55-03 open below threshold and GREEN-07 accepted-Pending; canonical re-audits remain orchestrator-owned.
- [Phase 198]: Every Phase-198 terminal source is authorized only by exact certified_head equality plus certified_head:path blob identity and digest.
- [Phase 198]: Classic protection communicates only absent or present; all other HTTP, transport, malformed, or unknown states fail closed.
- [Phase 198]: T-198-55-02 and T-198-55-03 remain open and not accepted; GREEN-07 remains accepted-Pending.
- [Phase 198]: [198-62] Legacy receipt compatibility requires exact canonical Round-11 paths, blobs, byte digests, completed state, and 41-row joins; every failed predicate selects strict validation.
- [Phase 198]: [198-62] Plan 62 is the sole mechanically validated non-recursive summary exception after auditing summaries 01-61 exactly once.
- [Phase 198]: [198-62] T-198-55-02 and T-198-55-03 remain open and not accepted; T-198-57-04 is absent from terminal open findings; GREEN-07 remains accepted-Pending.
- [Phase 198]: The maintainer accepted only T-198-55-02's residual historical argv/non-force proof uncertainty with literal signer YOUR_NAME; no evidence or mitigation is claimed.
- [Phase 198]: Plan 63's decline remains immutable history, while canonical security retains sole authority to change the threat verdict before phase verification runs.
- [Phase 198]: Summaries 01-61 remain the immutable audited-final set; Plan 62 remains the sole terminal-certification exception.
- [Phase 198]: Summaries 63-65 require exact content-bound manifest records; Plan 66 is an explicit non-terminal final-mode repair summary.
- [Phase 198]: Plan 66 restores only current-tree GREEN-04 determinism; GREEN-07 remains accepted-Pending and security dispositions remain unchanged.
- [Phase 199]: [199-01] MechanicalChecker owns evaluation only; repository fixture discovery remains at test and tooling edges.
- [Phase 199]: [199-01] Invalid corpora return distinct tagged errors with expanded paths, repository-only=false, and one recovery call.
- [Phase 199]: Private Mix-task overrides resolve within the loaded repository and generated critic scores remain separate from immutable evidence roots. — Keeps repository discovery at the maintainer edge and prevents path traversal, symlink, prefix, and root-alias writes.
- [Phase 199]: Canonical critic fixture replacement uses exclusive sibling temps with sync, close-before-rename, and unconditional cleanup. — Preserves original bytes on failure while making successful regeneration atomic and review-explicit.
- [Phase 199]: The ESM adapter owns frozen deterministic roots; callers may override fixture and output roots only through explicit CLI flags. — Keeps repository discovery at the TypeScript execution edge and avoids ambient environment service location.
- [Phase 199]: Containment rejects traversal and every symlink component, canonicalizes the nearest existing parent, and compares with path.relative. — Prevents traversal, prefix-confusion, and alias escapes for both existing and prospective targets.
- [Phase 199]: Canonical TypeScript replacement uses an exclusive sibling temp, file sync, close-before-rename, and unconditional cleanup. — Preserves original bytes and prevents temp leakage on forced failure.
- [Phase 199]: Manifest membership comes only from git ls-files; filesystem presence alone never grants evidence authority.
- [Phase 199]: Generated critic-score bytes remain invisible to integrity manifests until explicitly promoted into the Git index.
- [Phase 199]: Active citation detection is derived from executable/current-document classes; a historical live-input citation is allowed only when the same artifact has an exact Phase 199 supersession marker.
- [Phase 199]: Git history plus full recovery commits replaces archive copies or tombstones for all four removed artifacts.
- [Phase 199]: [199-10] PLT policy ignores only .plt and .plt.hash files beneath the anchored .dialyzer producer root.
- [Phase 199]: [199-10] Root formatter delegates bench and examples/threadline_phoenix while child configs retain imports and nested migration ownership.
- [Phase 199]: [199-10] Newly owned benchmark entrypoints are formatted in the same change that adds them to the required formatter surface.
- [Phase 199]: [199-12] Derive planning-history scan inputs from tracked ExUnit, Mix-task, mix.exs, and workflow sources; exclude only the scanner's own synthetic-control file.
- [Phase 199]: [199-12] Keep D-01 operator evidence corpus migration separately owned by Plans 199-02 through 199-08 while blocking executable planning-receipt reads now.
- [Phase 199]: [199-12] Retain live CI recorder, workflow, and artifact invariants while retiring completed planning-prose receipt assertions.
- [Phase 199]: [199-02] StressLive accepts only non-empty decoded ledger-entry maps under exact session key threadline_stress_ledger_entries.
- [Phase 199]: [199-02] ExUnit corpus paths descend from one test-support root that Plan 199-08 can flip atomically.
- [Phase 199]: [199-02] Refute partition checks pass explicit empty mechanical floors because they exercise absolute ceilings only.
- [Phase 199]: Plan 199-05: Every critic consumer resolves immutable and generated evidence through the shared TypeScript adapter; explicit root flags activate centrally.
- [Phase 199]: Plan 199-05: Routine critic:check is deterministic and no-paid while explicit scoring commands retain paid critic behavior.
- [Phase 199]: Plan 199-05: Generated score and cache identifiers are rejected rather than sanitized, preventing traversal and collision aliases.
- [Phase 199]: Capture consumers derive immutable corpus and e2e artifact locations from the shared TypeScript adapter, containing every dynamic output segment.
- [Phase 199]: Playwright owns contained screenshot writes; direct text, JSON, and ARIA evidence replacement uses the shared atomic writer.
- [Phase 199]: Reviewed stress snapshots remain under tests while optional generated stress packets are confined to e2e/artifacts.
- [Phase 199]: [199-11] Cleanup snapshots canonical parent/child lstat identities and rejects every live Git worktree root before removal.
- [Phase 199]: [199-11] Clean-checkout verification detaches a no-local clone at exact committed HEAD and keeps index/untracked state out of the proof.
- [Phase 199]: The immutable evidence root is test/fixtures/operator_surface; generated critic output remains ignored and outside manifest authority.
- [Phase 199]: Live evidence joins use mechanical-floor base IDs with explicit variant matching and the documented veto-ordering exception.
- [Phase 199]: Hex privacy is proven from the unpacked artifact file list rather than inferred solely from configuration.
- [Phase 199]: Plan 199-13 halted on the measured 22-file Dialyzer warning-origin set; the 14-file cap was not reinterpreted or weakened.
- [Phase 199]: No Dialyzer suppression or ignore ceiling is approved until the sealed warning set is re-sliced and individually dispositioned.
- [Phase 199]: Plan 199-15: Hash only normalized raw warnings inside each fixture's authorized origins so disjoint later remediation does not invalidate completed slices.
- [Phase 199]: Plan 199-15: Require exact warning-origin coverage and reject malformed, duplicate, unauthorized, unrecorded, or stale residue evidence.
- [Phase 199]: Plan 199-15: Describe unconditional Mix.raise/1 helpers with truthful private no_return() specs without changing runtime behavior.
- [Phase 199]: Use concrete AuditChange and AuditTransaction struct types where remote schema modules do not export t/0 types.
- [Phase 199]: Thread the validated continuity schema forward and match :code.priv_dir/1's charlist/error-tuple results explicitly.
- [Phase 199]: Normalize CSV and NDJSON rows to binary chunks so serialization contracts remain concrete without widening public APIs to streams.
- [Phase 199]: Log export close and removal failures without replacing the established primary result.
- [Phase 199]: Use concrete source-tree structs where provider modules do not export t/0.
- [Phase 199]: Keep Plug remote-address formatting tuple-only and cover both IPv4 and IPv6.
- [Phase 199]: Require every redaction parser reason to have an explicit operator-facing presentation clause.
- [Phase 199]: Use normalized binary inputs directly in private path, email, and URL presentation helpers.
- [Phase 199]: Consume LiveView timer results explicitly while preserving intervals, message names, and scheduling count.
- [Phase 199]: Match Timeline export counts and transaction value tokens only across result shapes guaranteed by their callees.
- [Phase 199]: Keep .dialyzer_ignore.exs empty and the committed ceiling at zero because every sealed warning is fixed.
- [Phase 199]: Use only the five source fixtures as historical authority; the executable contract reads no planning artifact.
- [Phase 199]: Treat unsealed warnings, origin drift, broad suppressions, and unused filters as fail-closed conditions.
- [Phase 199]: Plan 199-14: Set verify-dialyzer timeout-minutes to 9 from ceil(252-second cold whole-job time × 2.0 / 60).
- [Phase 199]: Plan 199-14: Only an exact PLT primary-key match is a cache hit; same-toolchain partial restores rebuild before analysis.
- [Phase 199]: Plan 199-14: Remove the temporary phase-branch push trigger immediately after immutable miss/hit evidence collection.
- [Phase 199]: Plan 199-21 certifies only an exact committed SHA in a no-local clone with .planning physically absent.
- [Phase 199]: Planning quarantine restoration always precedes recursive cleanup delegated solely to bin/safe-temp-tree.
- [Phase 199]: The planning-free aggregate preserves the committed dev-Dialyzer and desktop/mobile Chromium CI topology.
- [Phase 200]: Public-surface gates derive inventories from AST, compiled docs, Mix configuration, and the unpacked Hex artifact; classifications are exact, disjoint, and non-vacuous. — Prevents accidental compatibility promises and vacuous release gates.
- [Phase 200]: Later Phase 200 plans own bounded red tags; full public-document and archive scans remain final-only aggregates. — Allows independently reviewable slices without weakening the complete consumer artifact gate.
- [Phase 200]: The optional path/1 regression captures UndefinedFunctionError as an assertion value. — Proves the intended missing-callback behavior gap rather than accepting a fixture or load crash as RED.
- [Phase 200]: All fourteen literal :threadline runtime keys are the supported application-environment contract; adapter-module options remain a distinct dynamic key class.
- [Phase 200]: Host projects receive threadline.* Mix tasks, while this repository's verify.*, test.*, and ci.all aliases remain repository-local.
- [Phase 200]: Confirmed :storage_adapter as a supported extension point with binary content as the portable put/2 contract and Local file-path detection as an adapter-specific convenience. — Implements the already-locked D-02 compatibility commitment without a new callback or configuration namespace.
- [Phase 200]: Optional storage path/1 dispatch checks adapter capability and otherwise reuses the existing download_url/2 fallback. — Keeps optional callbacks honest while preserving adapter options, export expiry, authorization, and delivery outcomes.
- [Phase 200]: Use six user-role ExDoc module groups with critic tooling hidden and exactly ten adopter Mix tasks. — Keeps documentation compatibility aligned with supported call paths, return types, and extension roles.
- [Phase 200]: Link repository-only project resources as version-derived ExDoc URL extras outside package.files. — Preserves README-led native HexDocs without expanding the consumer archive or adding a custom docs site.
- [Phase 200]: Rename the planning-specific browser alias to verify.operator_component_contracts with no compatibility alias. — A durable purpose-based name removes release chronology while preserving the same targeted browser behavior.
- [Phase 200]: Style, UI, and Capture.Migration are implementation-only; Evidence.Subject and Mix.Tasks.Threadline.Gen.Triggers remain public because they are supported data and task contracts. — Public documentation follows supported adopter seams rather than raw Elixir callability.
- [Phase 200]: RedactionPolicy, TriggerCaptureConfig, TriggerSQL, and CleanupTask are internal plumbing. — Their call sites are Threadline-owned tasks, migrations, supervision, tests, and benchmarks; no supported direct adopter seam exists.
- [Phase 200]: Plan 200-05 changed documentation visibility only and preserved functions, returned structs, runtime behavior, and supported entrypoints. — The public-surface audit must not widen or break the runtime API.
- [Phase 200]: Governance persistence records and migration generators are internal documentation surfaces; supported facades and return values remain public.
- [Phase 200]: Coverage, redaction, retention scheduling, theme routing, and font helpers remain hidden behind public tasks, facades, configuration, and router contracts.
- [Phase 200]: [200-07] Export delivery and coverage modules are internal router/rendering plumbing; Router and Auth remain the supported public seams.
- [Phase 200]: [200-07] Router-installed export, session, and theme plugs are hidden without changing authorization, session, route, telemetry, or response behavior.
- [Phase 200]: [200-07] Public operator documentation belongs on Router and Auth rather than generated controllers, hooks, state carriers, or plugs.
- [Phase 200]: [200-08] Filename, FilterParams, Scope, Script, and SurfaceHeader are internal operator helpers; Presentation remains hidden and Router remains the supported public mount contract.
- [Phase 200]: [200-08] Exact module visibility derives from compiled packaged lib/ sources, excluding test-support modules absent from HexDocs.
- [Phase 200]: [200-08] All 23 modules documented in 0.9 and now hidden are named in the changelog; visibility changes do not alter runtime callability.
- [Phase 200]: Plan 200-16: Stress provenance uses baseline, page-state, data-display, refute-twin, and graded-ladder cohort names instead of numeric implementation chronology.
- [Phase 200]: Plan 200-16: Fixture and ledger provenance share origin_cohort and reserved_for_cohort with exact round-trip coverage.
- [Phase 200]: Plan 200-16: Stress copy cleanup preserves existing DOM structure, classes, styles, routes, and behavior.
- [Phase 200]: Plan 200-17: Each form-oriented LiveView explains its form capability as a current page invariant beside the persisted module attribute.
- [Phase 200]: Plan 200-17: Coverage and redaction name their schema-selector behavior directly; actor, evidence, and exports remain explicitly formless.
- [Phase 200]: Plan 200-17: Export history documents its recent-only cap as a product fact while retaining the dynamic default limit and rendered count.
- [Phase 200]: Plan 200-12: Integration docs name supported public facades and observable outcomes, not hidden implementation modules.
- [Phase 200]: Plan 200-12: Repository-local external resources resolve as links without becoming nodes in the exact 18-guide graph.
- [Phase 200]: Plan 200-12: Package exactly the two theme-aware README logos and copy them through native ExDoc assets.
- [Phase 200]: Ordinary contributors see the complete issue-to-PR path before specialized test and maintainer reference material.
- [Phase 200]: Missing audit table guidance explains the local-state cause and delegates recovery commands to Local Docker DX.
- [Phase 200]: Generated PostgreSQL triggers installed through host-owned Ecto migrations are the shipped capture boundary.
- [Phase 201]: Canonical receipts mount real routes, fix time-dependent inputs, normalize only nondeterministic CSRF values, and otherwise preserve meaningful structure.
- [Phase 201]: Reference comparison requires exact sorted path identity before any per-path byte digest comparison.
- [Phase 201]: Shell and Home browser coverage uses existing form IDs, accessible labels, roles, and visible hierarchy instead of roadmap taxonomy attributes.
- [Phase 201]: Start browser consumers use existing forms, accessible labels, roles, and visible outcomes; no replacement test IDs or provenance hooks were added.
- [Phase 201]: The focused Start contract rejects planning attributes only after proving both lookup controls remain present and operable.
- [Phase 201]: Existing export-context task IDs and the accessible Carry to Exports link express the complete behavior contract without replacement provenance metadata.
- [Phase 201]: The shared earned-flow browser journey uses roles, visible names, routes, and existing product test IDs for both this cohort and the later Row History/Timeline cohort.
- [Phase 201]: [201-04] Validate exact sorted identity for all seven canonical renders before accepting an empty provenance-offender set.
- [Phase 201]: [201-04] Preserve Row History and Timeline through existing semantic anchors without replacement provenance hooks.
- [Phase 202]: Storage-schema default flipped from "threadline" to "public": 0.10.0 is non-breaking for the entire pre-0.10 adopter population, and a dedicated schema becomes an explicit opt-in steered by mix threadline.install and the getting-started guide. — Threadline cannot detect which schema an existing install put its audit tables in, so the default must be the one already true for installs that exist. Proven by HexEvaluator.LegacyPublicSchemaTest, which installs a packaged build of this tree into a fixture that sets no storage_schema key.
- [Phase 202]: The hex evaluator resolves :threadline from a per-run local rehearsal registry built from this tree's own mix hex.build tarball, with hexpm reserved for the published mode set by the release workflow. — The fixture previously pinned threadline ~> 0.9.0 from hexpm with a committed lock, so it re-proved the last published release instead of the tree under test - a pre-publish gate resting on a post-publish fact. bin/with-rehearsal-registry closes that; the lock is now untracked and gitignored.
- [Phase 202]: Install pins are owned by mix release.pins alone; release automation is test-forbidden from ever owning a pin line
- [Phase 202]: Maintainer-only tooling (11 files, 4706 lines) is excluded from the Hex package via exclude_patterns, proven against the unpacked tarball rather than the config
- [Phase 202]: release-please's changelog-path now names CHANGELOG-GENERATED.md; CHANGELOG.md is human-owned and is the file shipped in the tarball
- [Phase 202]: The 0.10.0 changelog entry ships the complete 25-module undocumented list, not the folded 23 — the two sets were measured, not assumed
- [Phase 202]: The stale hex-evaluator prose stays deferred: the false sentences are 2 of the 6 install-pin sites, so the fix is release-tooling work
- [Phase 203]: 203-01: Query.Scope/FilterParams moved to :module_visibility_domain_tail; released CHANGELOG kept verbatim via explicit @renamed_modules register in public_surface_contract_test
- [Phase 203]: GATE-04: zero compile-connected xref cycles + zero no_warn_undefined; runtime AuditTransaction<->AuditAction edge kept (D-18); mix verify.xref_cycles in ci.all and CI verify-test (both lanes)
- [Phase 203]: 203-03: AliasUsage in lib/ and contract tests paid down to 0 as 22 single-file refactor commits; timeline_live.ex and copy_contract_test.exs pre-existing AliasOrder absorbed (Plans 06/07 each expect one fewer)
- [Phase 203]: 203-04: AliasUsage outside test/threadline/operator_surface/ paid to 0 (116 findings, 14 files, 7 directory-batched refactor commits); Threadline.ExportQueue.Oban aliased as ObanAdapter because bare Oban is the real Oban module in oban_test
- [Phase 203]: 203-05: AliasUsage paid to 0 tree-wide (last 187 findings, 20 operator_surface test files, 3 directory-batched refactor commits); no as: needed; StressRouter alias for Code.compile_quoted routers lives in the enclosing module because quote hygiene blocks an inner alias
- [Phase 203]: 203-06 D-09: retention.ex MissedMetadataKeyInLoggerConfig resolved by .credo.exs metadata_keys: param (Plan 10), never by config/*.exs Logger config
- [Phase 203]: 203-07: StringSigils fixes use ~s with an absent delimiter (never ~S), byte-equality proven by evaluation; GATE-05 stale-location half pinned by source_comment_location_contract_test.exs, requirement checkbox left for Plan 10 (moduledoc delta)
- [Phase 203]: D-31: per-site structural-debt line is '# Structural debt: <reason>' — no phase number or requirement ID in packaged source; Phase 204/STRUCT-07 named only in the test-resident register
- [Phase 203]: 203-09: Credo structural register pinned in source (credo_config_contract_test.exs) at Nesting 26 / CyclomaticComplexity 16 / ceiling 42 / historical max 46, exact equality, successor Phase 204 / STRUCT-07; GATE-02 checkbox left for Plan 10 (Logger finding still open)
- [Phase 203]: 203-10: .credo.exs is credo 1.7.18 scaffolding + 3 extra deltas, disabled: []; Logger finding resolved via metadata_keys param (D-09)
- [Phase 204]: 204-01: CSS byte lock pins golden c7baf51e (119,508 B) and full render b10d6a2c (212,633 B); never re-pin during the phase
- [Phase 204]: 204-01: size gate seeded exact (7 files, 12 functions, 42 banner lines in 7 files); each extraction edits the maps in the same commit
- [Phase 204]: 204-02: ci.all runs test files once (verify.test); hand-listed doc-contract alias deleted; runtime alias-tree guard; bump rehearsal derives 33 doc-contract files by filename (floor 30)
- [Phase 204]: 204-03: <style> tags live in the Elixir concatenation; segment bytes are the golden minus those tags (byte-identical first try)
- [Phase 204]: 204-03: browser-lane gate is the known-8 invariant (326 passed / 8 known / 16 skipped today), not the stale 82-passed literal
- [Phase 204]: 204-04: MechanicalChecker pinned constants stay in the parent and reach its six siblings as argument maps; only unpinned constants moved
- [Phase 204]: 204-04: Governance migration pinned by sha256+bytes under the library default (public) and AuditLog schemas before the split
- [Phase 204]: 204-04: Query.Cursors shares the Query.Scope alias line so no recorded Dialyzer coordinate above the moved code shifts
- [Phase 204]: 204-05: desktop-only lost-input browser failures (Task 2: screenshots:90, timeline:583; Task 3: accessibility:620 focus) were flakes, each cleared by one unchanged orchestrator re-run at exactly 326/8/16
- [Phase 204]: 204-06: ui.ex retired into UI.Form via git mv; six @moduledoc false UI families; cross-family shell mount via <Overlay.reconnect_banner /> alias, never import
- [Phase 204]: 204-07: all 15 non-surface lib register sites drained in place (no per-site fallback); register 38 -> 23 (Nesting 17, CyclomaticComplexity 6)
- [Phase 204]: 204-08: LiveView siblings live under live/<page>/; per-page shell, formless, and doc pins read them via Threadline.Test.SourceFamily; sibling components declare attrs for exactly the assigns they read
- [Phase 204]: 204-09: stress_live family is Sections (markup components) + Refute (pure refute-twin helpers) + Paths (URL helpers) under live/stress_live/; mix.exs excludes the family by directory; register 21 -> 19
- [Phase 204]: 204-10: export job list and its display helpers moved to ExportStatusLive.Components (in-module would exceed 800 lines); the three context sections stay private in the LiveView
- [Phase 204]: 204-10: export_workflow_summary/1 split into context and jobs summaries; credo register 19 -> 18
- [Phase 204]: 204-11: actor/start/coverage renders carved in-module (43/47/59 lines); size gate @function_exceptions is %{}; start/coverage banners gone; credo register 17
- [Phase 204]: 204-12: export encoding moved to ExportController.Encoding; lib is banner-free (@banner_exceptions %{}) and has no register site; credo register 17 -> 12 (Nesting 11, CC 1), all test-side
- [Phase 204]: 204-13: shared operator-surface test templates in test/support/operator_surface_case.ex; nine live/*_live_test files migrated (190 tests unchanged); parsers: false supported for 204-14's gating endpoint
- [Phase 204]: 204-14: TestStructureContractTest fails any hand-rolled test Endpoint/Router outside test/support/operator_surface_case.ex unless allowlisted with a reason; stale entries fail
- [Phase 204]: 204-15: structural register drained to %{} with @ceiling 0 (12 test-side sites fixed, none re-registered); size gate at rest pins exactly one named exception (stress_fixtures.ex); phase-end gates green (ci.all 1778/0, browser 326/8/16 known eight, bump rehearsal OK)
- [Phase 205]: 205-01: origin/main (v0.10.1) merged as ONE merge commit 0d8ced0c; 17 conflicts resolved whole-file (10 ours, 4 theirs, 3 combined)
- [Phase 205]: 205-01: sync-release-pr-pins wiring pinned by a contract test in release_control_plane_contract_test.exs, proven RED on the pre-merge release.yml
- [Phase 205]: 205-01: verify.threadline runs under MIX_ENV=test (as ci.yml does); dev configures no :ecto_repos
- [Phase 205]: 205-01: merged origin/main 471ebf6e (v0.10.1) as one merge commit 0d8ced0c; 17 conflicts resolved whole-file (10 ours / 4 theirs / 3 combined); rehearsal 0.10.1 -> 0.11.0 OK; sync-pins job pinned by contract test
- [Phase 206]: Phase 206-01: migration versions come from one hidden helper (Threadline.Mix.MigrationVersion.next/3), computed once per install run and once per gen.triggers write; max(now, highest existing + 1s) with calendar-correct carry, integer fallback for non-timestamp schemes
- [Phase 206]: Phase 206-01: installer dedicated-schema advice prints only on a fresh install; partial re-run gets a keep-public note
- [Phase 206]: 206-02: CHANGELOG keeps the meaning of the partial re-run advice fix but drops WR/CR IDs (packaged-file vocabulary test bans them)
- [Phase 207]: Trigger DDL is CREATE OR REPLACE TRIGGER on every run (PG14 floor); per-table orphan drop has no CASCADE and reuses per_table_function_name/2
- [Phase 207]: 207-02: gen.triggers picks the first free numbered name AND module (_2, Posts2...) from a text-only scan of the migrations dir; rerun tables' down keeps capture on with an explanatory comment
- [Phase 207]: Default-claim guard over guides/**/*.md + README.md compares every storage_schema default claim to StorageSchema.get([]), with positive controls and a non-vacuity floor
- [Phase 207]: Rerun doc contract pins shared phrases across both drift guides, the gen.triggers moduledoc and the generated rerun down comment
- [Phase 208]: REL-01: bump-minor-pre-major flipped true via ci(release) commit 28beadd9, first config-touching commit on milestone/v1.42 with no releasable commit before it
- [Phase 208]: 208-02: validate!/1 delegates to validate_identifier!(v, :storage_schema); host schema/table errors name role, value and byte_size
- [Phase 208]: 208-03: MigrationsPath.resolve/1 checks repeated --repo before --migrations-path short-circuits; install already honoured :priv, so only the flags and unknown-option rejection are new
- [Phase 208]: 208-04: Capture.Naming frozen per D-01..D-06 (all 11 golden hashes matched shasum); P3 generator also biases one table under two schemas after a mutation check showed the gap; migration_name/2 requires a non-empty list
- [Phase 208]: 208-05: gen.triggers uses MigrationsPath.resolve/1; trigger names via Naming.trigger_name/1 (default-mode overflow now cut to 63 bytes); per-table function overflow stays a :derived ArgumentError until Phase 209
- [Phase 210]: Kept the changed_fields SELECT's own to_jsonb(NEW)/to_jsonb(OLD) calls byte-identical to the pre-phase text (not reusing v_row), because RedactionPresenter parses that statement by regex.
- [Phase 210]: PrimaryKeySQL.create_trigger_block/3 does not yet raise for a table with no primary key; a PK-less table gets a zero-argument trigger and the legacy TG_NARGS=0 branch applies until Plan 03 (CAP-03) closes this intentional intermediate state.
- [Phase 210]: PK-less tables, unsupported key types, and redacted key columns now refuse migrations at migrate time with actionable config/config.exs guidance (CAP-03, CAP-05 migrate-time halves closed)
- [Phase 210]: validate_primary_key! rejects on the raw value before normalize_columns/1, so empty/NUL/whitespace/duplicate names cannot be silently absorbed
- [Phase 211]: 211-02: normalize!/2 compares given vs resolved key sets as MapSets of strings, never atomizing caller input; struct rejection narrowed to is_struct(id, schema) so Date/NaiveDateTime scalar keys keep working
- [Phase 211]: READ-04 guard reuses TimelineLive.Helpers.routeable_row_ref/1 rather than a page-local single-key rule, so the transaction page and timeline cannot drift on what counts as a routeable row identity
- [Phase 212]: 212-01: trigger_coverage/1 excludes disabled (D) and replica-only (R) triggers from covered — CHANGELOG Breaking changes, HLTH-05 complete
- [Phase 212]: 212-02: PrimaryKeySQL.override_index_key_set_sql/0 promoted to @doc false public (text unchanged) so health's override qualification reuses the migration's own SQL directly; a recorded column counts as :recorded_column_missing only when no live column matches it under any case, so a same-column case-mismatch reports :key_mismatch instead — the one comparison in the module that folds case, and only to pick a reason, never to decide equality. Key drift is checked against only the canonical trigger per {schema, table}, so a duplicate/extra trigger's own :duplicate_capture_trigger finding is never doubled up with a key finding. HLTH-02, HLTH-03, HLTH-04 complete.
- [Phase 212]: 212-03: verify_coverage gates on gated error findings (positive-list intersection), health.coverage adds an additive findings JSON key and FINDINGS text section; malformed :trigger_capture config raises Mix.Error in both tasks before any findings check. HLTH-06 completes fully in 212-04 (CHANGELOG/guides/doc contract).
- [Phase 212]: 212-05: shape_join primary_key: override and shape_twin mask: entries placed in config/test.exs (not config.exs), THREADLINE_E2E-guarded, per D-19
- [Phase 212]: Local PgBouncer lane ran for real (Docker available) closing HLTH-01's remaining half; HLTH-06 CHANGELOG/guides/doc-contract obligations closed
- [Phase 213]: 213-01: guide prose bumps Threadline via mix.exs prose, not a literal {:threadline, "~> 0.11"} pin, to avoid colliding with version-truth Family A and mix release.pins
- [Phase 213]: 213-01: CHANGELOG Security section placed before Breaking changes in Unreleased, first such heading in this repo
- [Phase 213]: 213-02: guide's SQL and upgrade procedure proven on real PostgreSQL, including rollback-all catalog proof (no orphan capture function, foreign triggers survive)
- [Phase 213]: 213-03: local pre-land/release gates all green on final milestone tree; land/v1.42 built locally (112 cherry-picked commits, 1 ID-free feat! squash commit), ci.all green on it, never pushed; REL-03 stays Pending, maintainer hand-off recorded
- [Phase 214]: 214-01: push-to-main unit = push + workflow_run runs on the pushed SHA (scheduled nightlies excluded); release cycle = non-scheduled runs on release-please PR commits + release merge + sync PR commits
- [Phase 214]: 214-02: Flake Detection fast-failure streak is 79 runs 06-26→09-12 (full scheduled history), not 08-18; measured fact written to PROJECT.md
- [Phase 214]: 214-02: :live_dialyzer passes vacuously without a PLT (--no-check + --ignore-exit-status); cold-PLT cost is mix dialyzer --plt 33.0 s locally
- [Phase 214]: 214-02: tracked local-path count is 387 files at e58aa067 (union of absolute and home-relative regexes; 2 prompts/prior-art, 2 .github runner-cache)
- [Phase 214]: 214-03: inert-path share is 1 of 40 merged PRs (all) and 0 of 20 (30d) under a fail-closed proven allowlist; release/sync PRs are not inert (guides ship and are doc-contract tested)
- [Phase 214]: 214-03: CI test lanes most likely run :live_dialyzer vacuously (no .dialyzer restore); [inference], carried to the CI-economy phase
- [Phase 215]: 215-01: bumped mint via deps.unlock+deps.get (not deps.update) to avoid an uninstructed hpax transitive bump — deps.update mint lazy_html also bumped hpax; deps.unlock+deps.get scoped the lockfile diff to exactly mint and lazy_html
- [Phase 215]: 215-01: bench advisory required bumping ecto/ecto_sql/decimal/postgrex/plug together, not decimal alone — ecto 3.13.5's own package metadata constrains decimal to ~> 2.0, stalling it at the still-vulnerable 2.4.1; ecto 3.14.2 relaxes that constraint
- [Phase 215]: SUP-03 convention: hex_audit_ignores/0 on a MixProject module, checked against resolved hex: [ignore_advisories: ...] config; ignore_retirements refused outright
- [Phase 215]: 215-02: gate logic lives in bin/verify-deps-audit (bash + MIX_BIN seam), not a private mix.exs function, so the full behavior matrix is testable offline
- [Phase 215]: 215-02: negative network proof is bin/verify-deps-audit --self-test run as a CI job step, not a tagged ExUnit test, keeping test/test_helper.exs untouched
- [Phase 215]: Rank-based classification (bump()/RANK_NAMES) instead of a hand-written precedence table, so an advisory always outranks an unrelated fetch failure elsewhere by construction.
- [Phase 215]: Discovered and fixed a set -e leak in bin/deps-health-report's per-directory loop that turned an intentional truncation SIGPIPE into a premature script abort (exit 141); fixed with an explicit set +e after the loop.
- [Phase 217]: Seeded 3 tilde-dot-claude tool-install allowlist entries (gsd-core/, get-shit-done/, skills/) scoped to .planning/ as a deliberate, reversible interpretation; other tilde-dot-claude forms stay unallowlisted for plan 217-04 to scrub.
- [Phase 217]: bin/verify-temp-leaks strips a trailing slash from TMPDIR before building its mktemp template (macOS TMPDIR trailing-slash bug broke a real path-equality assertion)
- [Phase 217]: bin/verify-playwright-fail-fast redirects NODE_COMPILE_CACHE and PWTEST_CACHE_DIR into its own scratch dir to stop npm/Playwright leaking into the system temp dir
- [Phase 217]: HYG-04 verified from live code; no code/CI change; one traceability bullet added to MILESTONE-GUIDE.txt SS7 v1.45 rung
- [Phase 217]: Re-derived guard HIT lists fresh at execution time (P=2, L=316) rather than reusing 217-01's stale census; scrub is forward-only, prefix-only, and idempotent
- [Phase 217]: HYG-02 CI job runs bin/verify-repo-hygiene with no erlef/setup-beam and no cache (matches verify-release-shape, not verify-deps-audit), keeping the setup-beam step count at 14
- [Phase 217]: 217-06: family-6 matcher drops its mandatory trailing dash, so the user segment ends at the first byte outside [A-Za-z0-9._] or end of line (single-segment tokens are now a HIT; placeholders with `<` stay clean)
- [Phase 217]: 217-07: path shapes in docs and planning prose use an angle-bracket placeholder for the user/machine segment (CONTRIBUTING `## Writing about machine-local paths`); no exemption, suppression marker or allowlist widening; the guard prints a stderr hint naming that section on any uncovered HIT
- [Phase 217]: 217-07: git grep records travel NUL-delimited (tr to SOH) and HIT lines parse right-anchored, so colon-containing tracked filenames are scanned and scoped by full path (WR-02)
- [Phase 217]: 217-06: the git-on-PATH check runs before argument parsing so --self-test also names a missing git; allowlist safety net forbids every detected home-prefix family except tilde forms and the runner account
- [Phase 218]: ECON-03: bootstrap-release-pr-ci dispatches ci.yml only when RELEASE_PLEASE_TOKEN is absent (job-level boolean env RELEASE_PAT_CONFIGURED); wiring unchanged, never queries runs
- [Phase 218]: 218-02: --close comments then closes on exactly one match; deps-health closes only on classification clean; #28/#36 close refused by classifier, handed off (218-06/07 wiring + 218-08 verify)
- [Phase 218]: 218-03: bin/verify-dialyzer-slice fails closed: exactly one dialyxir completion marker required, any :dialyzer.run error: line rejects (ECON-05)
- [Phase 218]: 218-03: :live_dialyzer excluded by default; runs only via mix verify.dialyzer_slice in verify-dialyzer (postgres:16, MIX_ENV=test) and ci.all; timeout ceil((252+80)*2/60)=12
- [Phase 218]: 218-03: test_helper stores default excludes under :default_test_excludes app env; ci_all_dedup exempts only a single-file --only leaf over a default-excluded tag
- [Phase 218]: 218-04 D-10 re-check: verify-docs DOMINATED by verify-bump-rehearsal; verify-hex-package DOMINATED by verify-bump-rehearsal + verify-hex-evaluator (same ci.yml triggers, no job-level if:); both removed with verify-mechanical, ci-required 16 -> 13
- [Phase 218]: 218-04: removing verify-docs couples the ExDoc proof to verify-bump-rehearsal; a change-aware skip of that job (Phase 222/SEED-006) also skips docs + hex.build proofs
- [Phase 218]: 218-05: verify.flake moves to 15 repeats; CI and local share one entrypoint
- [Phase 218]: 218-05: only schedule honors the green-SHA skip; dispatch and push always run
- [Phase 218]: 218-05: inconclusive and broken-upstream end red and file the issue; only pass and a post-pass skip end green
- [Phase 218]: 218-06: only classification == pass closes the Flake Detection tracking issue; skip, inconclusive, broken-upstream and unknown never close it
- [Phase 218]: 218-07: Browser-full runs the derived difference (bin/browser-full-projects: config minus ci.yml run: flags and mix alias flags) on every event; nightly gated by bin/ci-sha-gate without --upstream; close-on-green via upsert-ci-issue --close
- [Phase 219]: 219-01: rule ids carry the literal rule=<id> token at their definition; the deps.compile guard is its own rule=compile-guard
- [Phase 219]: 219-01: build_cache_errors/2 proven on a fixture plus a hybrid map (live workflows, fixture ci.yml); only the D-17 security subset is asserted live until plan 02
- [Phase 219]: 219-02: the verify-capture row control is scoped to the Dependency build cache section, because live CONTRIBUTING has an earlier CI table with the same row prefix
- [Phase 219]: 219-02: pgbouncer bootstrap split into install, deps compile, rm and compile steps; the bootstrap step runs only mix run priv/ci/topology_bootstrap.exs; the wait step runs after the compile
- [Phase 219]: 219-03: Landing option (a) on PR #60 gave a PR scope and a dispatch scope, so 2 cold + 8 warm samples came without deleting caches
- [Phase 219]: 219-03: warm ci.yml run 39.3 unrounded / 49 billed runner-min vs 44.4 / 53 post-218; critical path 643 -> 547 s; Test (min) job saving not demonstrated (suite slowdown), Capture noise-level, recorded not dropped
- [Phase 221]: 221-01: required_gate_errors/1 split into per-rule helpers for credo complexity; gate controls mutate the whole workflows map so a second-workflow spoof fits the same loop
- [Phase 222]: SEED-006 re-measured: verdict CLOSE (0 of 28 strict-inert PRs in 30d-now, denominator 1553 billed min, docs-only ceiling 7.3% < 10% gate)
- [Phase 223]: 216 CR-01 closed: default-deny persist-credentials on release.yml checkouts (3 flagged), per-step contract with @persisted_checkout_jobs allowlist, mix_invocation?/1 command-position matcher, six mutation/positive controls; vacuous per-job counting block removed
- [Phase 223]: D-14: family 6 left-anchored with the locked two-branch form (?:(?<![A-Za-z0-9._-])|(?<=[A-Za-z]-)); the review's third branch was omitted per Claude's Discretion, proven equivalent by the drive-form guard test
- [Phase 223]: D-17: exact printf hint-line assertion + deletion mutation control, not a phrase-anywhere check (R2-IN-01)
- [Phase 223]: D-18: allowlist exemption scoped to its own literal column, not the whole repo (R2-IN-02)
- [Phase 223]: D-20: 217-REVIEW-DISPOSITION.md hand-edited, all 11 findings fixed/0 open, gsd-core disposition step never run
- [Phase 223]: B+C landed on main via squash PR #66 (merge db8d5373); PR #60 override applied; release-please opened chore(main): release 0.11.2 (PR #67)
- [Phase 223]: 223-05: docs(release) dating PR landed on main (0.11.2 entry dated, three advisories preserved); release PR #67 regenerated itself already current, so the granted update-branch --rebase was correctly skipped as a verified no-op; release PR head e9f96e05 confirmed green (CHANGELOG matches version + CI required)
- [Phase 223]: 0.11.2 published to hex.pm (run 36654382663), production-hex approval delegated to the orchestrator under the maintainer's explicit in-session authorization
- [Phase 224]: D-01: emit the per-table function drop from the first-run migration only, unconditionally; the rerun migration's down stays untouched
- [Phase 224]: Bundled Task 1 (tracer) + Task 2 code changes into one fix(bench) commit per the plan's own acceptance criteria; evidence committed separately
- [Phase 224]: Reused the pinned rollback-cleanup SQL sweep for the pre-fix rerun-chain remediation (D-06) rather than adding a second snippet
- [Phase 224]: Local SUITE-06 wall clock dominated by shared-machine load noise (high run-to-run variance both directions); CI run 36730596489 used as the reliable before citation, after recorded pending a maintainer push grant
- [Phase 225]: D-03 confirmed N=3 by measurement (T/3=45.7s >= M=28.8s)
- [Phase 225]: attach_telemetry!/1 isolates :telemetry handlers by emitting-process identity ($callers), not by handler id or ref alone
- [Phase 225]: Used :persistent_term (not a linked Agent) to prove on_exit detachment across ExUnit's separate on_exit-runner process
- [Phase 225]: D-07 fixed via MIX_TEST_PARTITION=1 on the coverage step (RESEARCH option 1), not an extra create+migrate step
- [Phase 225]: The .mix_test_failures write under _build/test is an accepted, documented D-06 exception (Mix's own manifest, no redirect flag, read-only crashes the suite, never read back via --failed)
- [Phase 225]: Flake Detection repeat count stays 12 after re-deriving from run 36364688861 (headroom still ~17%); only the cited run and ceilings moved
- [Phase 225]: 225-04: cited CI runs 36808706517/36810081717 vs baseline 36730596489 -> SUITE-02 OVERALL PASS; Flake Detection run 36810083586 pass, raw figures exceeded Plan-03 ceilings, orchestrator-authorized resize (6c4da13f, 287s/228s @ 11 repeats) fits; 225-EVIDENCE.md made fully citation-clean; SUITE-02/SUITE-03 marked Complete

### Blockers

-

- Phase 202 Plan 01 Task 1 was a one-way checkpoint:decision (storage-schema default flip) that AUTO-SELECTED under mode:yolo + auto_advance, with no live maintainer confirmation. Its own acceptance criterion required explicit maintainer confirmation. The underlying D-01 decision is recorded in 202-CONTEXT.md, but a maintainer should re-confirm the flip before the publish gate - hex.pm has no unpublish beyond ~1 hour.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260924-taj | alias Gen.Triggers in trigger_rerun_test.exs to clear credo AliasUsage | 2026-09-24 | c960cefa | [260924-taj-alias-gen-triggers-in-trigger-rerun-test](./quick/260924-taj-alias-gen-triggers-in-trigger-rerun-test/) |

## Session Continuity

**Last session:** 2026-10-01T04:58:13.820Z
**Stopped at:** Completed 225-04-PLAN.md
**Resume file:** None

- **Milestone closeout (2026-05-29):** v1.29 archived; tag `v1.29`; REQUIREMENTS.md removed for fresh next milestone.
- **130.1-02 (2026-05-29):** 130-VALIDATION superseded footnote; Nyquist waivers for 128/129; 130.1-VERIFICATION passed; `mix ci.all` green (744+61 tests).
- **Milestone closeout (2026-06-14):** v1.36 Operator Surface Light Mode archived (ROADMAP + REQUIREMENTS + AUDIT under `milestones/v1.36-*`), PROJECT.md evolved, tag `v1.36`, REQUIREMENTS.md removed for fresh next milestone. Finding F1 resolved — entangled `style.ex` light source committed (`b9f8fc1`); suite green at 912 tests. 6 items acknowledged-deferred (see Deferred Items).
- **175-02 (2026-06-17):** CSP-proof operator shell + runtime theme picker. Removed all 3 inline handlers; rebuilt picker as native radios + Apply button + `:has(:checked)` cue; native `<details>[open]` nav; scroll-padding-top/overscroll/100svh hardening; router doc corrected; theme-toggle ban lifted for a positive CSP guard. Plan-01 CSP RED target now GREEN (9 RED -> 8 RED Wave-0 targets remaining for Plans 03/04). Commits `b0a8c9c`, `25a582d`. Backend untouched (D-09); brand-token parity green.
- **175-03 (2026-06-17):** Internal `UI.page_header/1` + drill-down breadcrumbs. Built the one-`<h1>` page header (reusing existing CSS, zero new token, no public API), adopted it across the operator pages, threaded `[Timeline > …]` location breadcrumbs under `<nav aria-label="Breadcrumb">` into the 3 drill-down pages, relabeled away the bespoke "Investigation path" landmark, and set drill-down `current={nil}` so the single `aria-current="page"` stays on a nav link only. Re-pointed the D-02 doc-contract back-link assertions to the new D-13 breadcrumb root. Both NAV-01 Wave-0 RED targets GREEN; only the 4 Plan-04 PagerTest RED targets remain. Commits `025e9d3`, `3e4b1c7`. style.ex + capture/semantics untouched; brand-token parity green.
- **175-04 (2026-06-17):** Internal `UI.pager/1` + honest cap captions. Built the de-emphasized Older/Newer pager (hide-at-zero, disable-not-hide, capped "10,000+", role=status caption) over the existing keyset engine, adopted it next-only on Timeline (cursor in assign, D-19) and bidirectionally on Actor, added "Showing latest N" cap captions on Exports/Retention (D-20, none on Coverage/Redaction), and documented the `(captured_at, id)` keyset tiebreaker as deferred capture-layer perf debt in query.ex (D-15/Q1; no migration, capture layer untouched). All 4 NAV-02 Wave-0 PagerTest RED targets GREEN; verify.test 1008/0; brand-token parity green; zero new token. Commits `1a230bd`, `ac6f762`.
- **176-01 (2026-06-18):** Presentation core + icon contracts + Wave-0 RED scaffolds. Built `ref/2` (3-face, full == complete value), `truncate_middle/3` `:tail_min` (≥8 tail, default unchanged), per-kind `truncate_for/2`, `value_token/1` truncation (56, full in title); added `eye_off`/`funnel`/`lock`/`cloud_off` glyphs; authored the four MISSING Wave-0 tests (card-nesting D-12, typed-reason→state D-16, T3 fail-closed+audit D-21, ref-copy-equals-full Pitfall 4) all RED against current code with zero new deps. Commits `989f03c`, `45a788d`, `a4a13fa`, `3503fdc`, docs `5c18abf`.
- **176-02 (2026-06-18):** UI data-display + data-state component set. Built `ref/1`, `kv/1`, `data_table/1`, `loading_state/1`, `stale_banner/1`, three new `empty_state` variants, and the `data_state/1` typed-reason dispatcher as pure render functions with per-component contract tests + 10 isolated `/audit/__stress` stories (ledger + DESIGN-SYSTEM parity). Turned the Plan-01 `data_state_mapping` wave-0 RED test GREEN at the component level. ui_test 52/0, stress 33/0, parity+style_contract 37/0; warnings-as-errors clean; format clean. No page migrated. 6 cross-plan Wave-0 scaffolds stay RED by design. Commits `d3273d3`, `617eb47`, `8c880a6`, `93a8027`, `9e17e86`.
- **176-04 (2026-06-18):** Coverage flatten + card-nesting regression GREEN. Replaced the coverage success branch's hand-rolled `tl-coverage-command` header with `UI.page_header` (all 3 branches now use it; added an optional `:meta` slot to page_header for the last-checked line), demoted the command shell to plain page-stack siblings (kept `tl-card--metric` tiles), deleted the dead `tl-coverage-command__*` CSS with a paired style_contract refute lock (T-176-08), and turned the Plan-01 card-nesting Wave-0 RED test GREEN across all 11 surfaces (Task 2 needed no source change beyond Task 1's flatten). Operator_surface suite 545/5 (1 card-nesting RED → GREEN; 5 remaining are plan-05 retention T3 + ref-copy). Zero new token; brand-parity green; capture/semantics untouched. Commit `157398d`.
- **177-01 (2026-06-18):** Wave-0 conflict resolution + RED test scaffolds. Bound both locked-decision-vs-reality conflicts in writing (offline anchor = `.threadline-ui` LiveView root, NOT body/`.phx-disconnected`; keep the breadcrumbs list attr, no slot) and laid 12 RED scaffolds (3 source/parity + 9 component renders) + 1 GREEN breadcrumbs-trail test across the three test files. Full suite 1071/12 — all 12 failures are the new expected RED scaffolds; no pre-existing regression; format clean. Zero production code, zero new dep. Commits `bede897`, `4b7e304`.
- **177-02 (2026-06-18):** Layout primitives + semantic gap tokens. Added the three `--tl-gap-*` tokens parity-first across tokens.css/tokens.json/style.ex, then shipped `UI.stack/1` + `UI.cluster/1` (`@doc false`, card/1 idiom) with `.tl-stack`/`.tl-cluster` flexbox-gap CSS owning the spacing rhythm. Turned the Plan-01 gap-parity + stack/cluster RED scaffolds GREEN (gap-parity 4/0; combined gap+ui 66/7 where the 7 are out-of-scope Plan-03 data_panel/toolbar/detail_header scaffolds). Zero new dep; no public API; format + credo clean; capture/semantics untouched. Commits `8d701e8`, `38005a3`.
- **177-03 (2026-06-18):** Meta-components + breadcrumb truncation. Shipped `UI.data_panel/1` (state-coordinating shell composing the existing state family; stale-above-data; focus delegated; pager only :ok), `UI.toolbar/1` (disabled-coordination on cluster, Pitfall 6 contract), and `UI.detail_header/1` (`<h2>` + kv + actions cluster); reconciled breadcrumbs by keeping the list attr (D-14) + `clamp()` current-crumb truncation. Self-caught + fixed a phase-141/142 StyleContractTest governance regression (new `@media` literal + a `~1ms` comment) within the plan. All 7 component RED scaffolds GREEN; full suite 1071/2 (2 = Plan-04 overlay/offline RED-by-design, identical to baseline); compile/format/credo clean. Commits `1f4d6d7`, `2b082f8`, `19ef009`.
- **177-04 (2026-06-18):** Overlay motion + reconnect/offline group. Defined the previously-missing overlay JS-transition utility CLASS selectors (`.tl-fade-in/out`, `.tl-rise-in/out`, `.tl-slide-in/out-right`, `.opacity-0/100`, `.translate-y-0/4`, `.translate-x-0/full`, `.hidden`) + the modal/drawer/toast SHELLS (all were absent from style.ex) so overlay enter/exit motion is real; synced every overlay `JS.show/hide` to explicit `time: 180` (= `--tl-motion-base`, Pitfall 3) and added a toast fade-up entrance via `show_toast/2`. Built the reconnect/offline group keyed off the LiveView ROOT `.threadline-ui.phx-loading/.phx-error` (NOT body, NEVER the legacy disconnected class — Pitfall 1): warning-tinted `role=status` reconnect banner + `[data-tl-mutating]` pointer-events/opacity disable; added `UI.reconnect_banner/1` documenting the mutating-link `aria-disabled`/`tabindex=-1` contract (Pitfall 6). Self-caught + fixed a `.phx-disconnected` literal in a CSS comment that reddened the offline refute (comments are scanned, same gotcha class as Plan 03's `\d+ms`). Both Plan-01 style_contract RED scaffolds GREEN; full suite 1071/0; compile/format/credo(2115)/brand-parity clean. Zero new keyframes/tokens/deps; no public API; no inline `on*=`; capture/semantics untouched. GROUP-01/02 NOT closed (Plan 05). Commits `da4a36d`, `f1695a1`.
- **177-05 (2026-06-18):** GROUP-01 12-config stress mapping + ledger/projection parity (FINAL plan of phase 177). Remapped `@group_stories` from the 6 reserved baselines to the 12 GROUP-01 configurations as `status:current`/`owner_phase:177` via a `group_story/4` builder carrying a `surface` tag (`:live`|`:reference`) in both data + metadata (D-07; 10 live + 2 reference-only). Absorbed all 6 prior reserved baselines (action-bar/filter-bar/kv-list/pagination/status-strip/timeline-list) — zero orphaned `*.reserved` group ids. Synced `design-system-ledger.json` (12 current group entries 62/62/90, surface in `notes` — no new `@entry_keys`; reconciled `locked_ids`/`minimum_scores`/`required_inventory.groups`) + the DESIGN-SYSTEM.md Groups projection in lockstep; ledger parity GREEN. Added a `stress_router_test` assertion rendering all 12 group ids across 320/375/768/1024/1440 × dark/light/system. Marked GROUP-01 + GROUP-02 complete in REQUIREMENTS.md. Full library suite **1074/0** (1 excluded); verify.format/credo(2129)/compile-warnings-as-errors all clean; zero new dep, no public API, capture/semantics untouched. The only `mix ci.all` failure is a **pre-existing** example-app demo-seed 60s setup timeout (proven unrelated to plan 05 via stashed-baseline run; logged to `deferred-items.md`). Commits `8987793`, `8f62d25`, `9ca8453`, `313e52c`, `2a81604`.
- **Last Action**: Completed Phase 190 with 10/10 plans, passed verification, and recorded storage-schema confidence evidence (2026-07-02).
- **Next Step**: Discuss or plan Phase 191.
- **Resume file**: `.planning/ROADMAP.md`

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
