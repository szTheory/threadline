---
phase: 199-decouple
verified: 2026-09-22T11:08:34Z
status: passed
score: 40/40 must-haves verified
verification_target: "4d893e19099601cf6af12372adabbbe77510e1a4"
verification_target_is_ancestor_of_head: true
behavior_unverified: 0
overrides_applied: 0
requirements_verified: 8/8
decisions_verified: 30/30
security_status: verified
security_threats: 61/61 closed
previous_verification_target: "51ee7137fdea94dd79832de29a7e00bb1d89f2eb"
regressions: []
re_verification:
  previous_status: passed
  previous_score: 40/40
  previous_verified: "2026-09-13T14:53:14Z"
  gaps_closed: []
  gaps_remaining: []
  regressions: []
  delta_commits: 6
covered_files:
  - ".dialyzer_ignore.exs"
  - ".formatter.exs"
  - ".github/workflows/ci.yml"
  - ".gitignore"
  - ".planning/REQUIREMENTS.md"
  - ".planning/ROADMAP.md"
  - ".planning/phases/198-green-bringup/198-VERIFICATION.md"
  - ".planning/phases/199-decouple/199-01-PLAN.md"
  - ".planning/phases/199-decouple/199-01-SUMMARY.md"
  - ".planning/phases/199-decouple/199-02-PLAN.md"
  - ".planning/phases/199-decouple/199-02-SUMMARY.md"
  - ".planning/phases/199-decouple/199-03-PLAN.md"
  - ".planning/phases/199-decouple/199-03-SUMMARY.md"
  - ".planning/phases/199-decouple/199-04-PLAN.md"
  - ".planning/phases/199-decouple/199-04-SUMMARY.md"
  - ".planning/phases/199-decouple/199-05-PLAN.md"
  - ".planning/phases/199-decouple/199-05-SUMMARY.md"
  - ".planning/phases/199-decouple/199-06-PLAN.md"
  - ".planning/phases/199-decouple/199-06-SUMMARY.md"
  - ".planning/phases/199-decouple/199-07-PLAN.md"
  - ".planning/phases/199-decouple/199-07-SUMMARY.md"
  - ".planning/phases/199-decouple/199-08-PLAN.md"
  - ".planning/phases/199-decouple/199-08-SUMMARY.md"
  - ".planning/phases/199-decouple/199-09-PLAN.md"
  - ".planning/phases/199-decouple/199-09-SUMMARY.md"
  - ".planning/phases/199-decouple/199-10-PLAN.md"
  - ".planning/phases/199-decouple/199-10-SUMMARY.md"
  - ".planning/phases/199-decouple/199-11-PLAN.md"
  - ".planning/phases/199-decouple/199-11-SUMMARY.md"
  - ".planning/phases/199-decouple/199-12-PLAN.md"
  - ".planning/phases/199-decouple/199-12-SUMMARY.md"
  - ".planning/phases/199-decouple/199-13-PLAN.md"
  - ".planning/phases/199-decouple/199-13-SUMMARY.md"
  - ".planning/phases/199-decouple/199-14-PLAN.md"
  - ".planning/phases/199-decouple/199-14-SUMMARY.md"
  - ".planning/phases/199-decouple/199-15-PLAN.md"
  - ".planning/phases/199-decouple/199-15-SUMMARY.md"
  - ".planning/phases/199-decouple/199-16-PLAN.md"
  - ".planning/phases/199-decouple/199-16-SUMMARY.md"
  - ".planning/phases/199-decouple/199-17-PLAN.md"
  - ".planning/phases/199-decouple/199-17-SUMMARY.md"
  - ".planning/phases/199-decouple/199-18-PLAN.md"
  - ".planning/phases/199-decouple/199-18-SUMMARY.md"
  - ".planning/phases/199-decouple/199-19-PLAN.md"
  - ".planning/phases/199-decouple/199-19-SUMMARY.md"
  - ".planning/phases/199-decouple/199-20-PLAN.md"
  - ".planning/phases/199-decouple/199-20-SUMMARY.md"
  - ".planning/phases/199-decouple/199-21-PLAN.md"
  - ".planning/phases/199-decouple/199-21-SUMMARY.md"
  - ".planning/phases/199-decouple/199-CONTEXT.md"
  - ".planning/phases/199-decouple/199-DIALYZER-TRIAGE.md"
  - ".planning/phases/199-decouple/199-REMOVAL-INVENTORY.md"
  - ".planning/phases/199-decouple/199-RESEARCH.md"
  - ".planning/phases/199-decouple/199-RETIRED-CONTRACTS.md"
  - ".planning/phases/199-decouple/199-REVIEW-FIX.md"
  - ".planning/phases/199-decouple/199-REVIEW.md"
  - ".planning/phases/199-decouple/199-SECURITY.md"
  - ".planning/phases/199-decouple/199-UI-REVIEW.md"
  - ".planning/phases/199-decouple/199-VALIDATION.md"
  - "CONTRIBUTING.md"
  - "DESIGN-SYSTEM.md"
  - "bench/.formatter.exs"
  - "bench/audit_capture_bench.exs"
  - "bench/bench_helper.exs"
  - "bench/redaction_and_changed_from_bench.exs"
  - "bin/safe-temp-tree"
  - "bin/verify-clean-checkout"
  - "bin/verify-dialyzer-slice"
  - "bin/verify-planning-independent"
  - "examples/threadline_phoenix/.formatter.exs"
  - "examples/threadline_phoenix/e2e/critic-before-pole.sh"
  - "examples/threadline_phoenix/e2e/critic/bundle.ts"
  - "examples/threadline_phoenix/e2e/critic/cache.ts"
  - "examples/threadline_phoenix/e2e/critic/gate.ts"
  - "examples/threadline_phoenix/e2e/critic/label.ts"
  - "examples/threadline_phoenix/e2e/critic/label_web.ts"
  - "examples/threadline_phoenix/e2e/critic/panel.ts"
  - "examples/threadline_phoenix/e2e/critic/prompt.ts"
  - "examples/threadline_phoenix/e2e/critic/refute.ts"
  - "examples/threadline_phoenix/e2e/critic/report.ts"
  - "examples/threadline_phoenix/e2e/critic/report_html.ts"
  - "examples/threadline_phoenix/e2e/critic/rubric.ts"
  - "examples/threadline_phoenix/e2e/critic/run.ts"
  - "examples/threadline_phoenix/e2e/critic/scorecard.ts"
  - "examples/threadline_phoenix/e2e/package.json"
  - "examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts"
  - "examples/threadline_phoenix/e2e/support/operator-surface-paths.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-graded-capture.spec.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-storybook-capture.spec.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts"
  - "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex"
  - "examples/threadline_phoenix/lib/threadline_phoenix_web/threadline_stress_session.ex"
  - "examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs"
  - "lib/mix/tasks/critic.measure.ex"
  - "lib/mix/tasks/critic.synth.ex"
  - "lib/threadline/change_diff.ex"
  - "lib/threadline/continuity.ex"
  - "lib/threadline/critic_trust/measure.ex"
  - "lib/threadline/export.ex"
  - "lib/threadline/export/orchestrator.ex"
  - "lib/threadline/integrations/sigra.ex"
  - "lib/threadline/investigation/incident_bundle.ex"
  - "lib/threadline/investigation/linked_change.ex"
  - "lib/threadline/operator_surface/auth.ex"
  - "lib/threadline/operator_surface/live/coverage_live.ex"
  - "lib/threadline/operator_surface/live/export_status_live.ex"
  - "lib/threadline/operator_surface/live/retention_history_live.ex"
  - "lib/threadline/operator_surface/live/stress_live.ex"
  - "lib/threadline/operator_surface/live/timeline_live.ex"
  - "lib/threadline/operator_surface/live/transaction_live.ex"
  - "lib/threadline/operator_surface/mechanical_checker.ex"
  - "lib/threadline/operator_surface/presentation.ex"
  - "lib/threadline/operator_surface/stress_router.ex"
  - "lib/threadline/plug.ex"
  - "lib/threadline/policy/redaction_presenter.ex"
  - "lib/threadline/query.ex"
  - "lib/threadline/query/actor_history_page.ex"
  - "lib/threadline/storage/local.ex"
  - "mix.exs"
  - "mix.lock"
  - "test/fixtures/dialyzer/README.md"
  - "test/fixtures/dialyzer/critic-tooling.json"
  - "test/fixtures/dialyzer/export-investigation.json"
  - "test/fixtures/dialyzer/operator-boundaries.json"
  - "test/fixtures/dialyzer/operator-liveviews.json"
  - "test/fixtures/dialyzer/query-storage.json"
  - "test/fixtures/operator_surface/README.md"
  - "test/fixtures/operator_surface/critic-scores/.gitkeep"
  - "test/fixtures/operator_surface/design-system-ledger.json"
  - "test/fixtures/operator_surface/golden/golden-set.json"
  - "test/fixtures/operator_surface/golden/queue.json"
  - "test/fixtures/operator_surface/golden/rounds/.gitkeep"
  - "test/fixtures/operator_surface/golden/synthetic-set.json"
  - "test/fixtures/operator_surface/manifest.sha256"
  - "test/fixtures/operator_surface/refute/refute-set.json"
  - "test/fixtures/operator_surface/scorecards/page.actor.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.actor.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.actor.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.actor.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.actor.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.actor.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__light-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__light-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__light-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.empty__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__dark-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__dark-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__dark-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__light-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__light-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__light-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.error__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__light-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__light-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__light-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.coverage.permission__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.evidence.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.evidence.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.evidence.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.evidence.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.evidence.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.evidence.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.exports.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.exports.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.exports.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.exports.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.exports.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.exports.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.home.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.home.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.home.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.home.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.home.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.home.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.redaction.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.redaction.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.redaction.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.redaction.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.redaction.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.redaction.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__dark-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__dark-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__dark-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__light-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__light-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__light-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.empty__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__dark-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__dark-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__dark-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__light-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__light-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__light-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.error__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__dark-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__dark-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__dark-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__light-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__light-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__light-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.retention.permission__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.row-history.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.row-history.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.row-history.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.row-history.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.row-history.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.row-history.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.shell.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.shell.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.shell.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.shell.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.shell.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.shell.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.timeline.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.timeline.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.timeline.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.timeline.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.timeline.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.timeline.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__light-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__light-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__light-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.empty__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__dark-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__dark-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__dark-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__light-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__light-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__light-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.error__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.happy__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.happy__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.happy__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.happy__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.happy__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.happy__light-768.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__light-1280.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__light-375.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__light-375.json"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__light-768.aria.yml"
  - "test/fixtures/operator_surface/scorecards/page.transaction.permission__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.actor.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.actor.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.actor.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.actor.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.coverage.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.coverage.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.coverage.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.coverage.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.evidence.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.evidence.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.evidence.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.evidence.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.export.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.export.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.export.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.export.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.retention.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.retention.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.retention.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.retention.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.timeline.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.timeline.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.timeline.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.timeline.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.actor.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.actor.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.actor.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.actor.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.coverage.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.coverage.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.coverage.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.coverage.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.diff.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.diff.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.diff.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.diff.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.evidence.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.evidence.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.evidence.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.evidence.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.retention.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.retention.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.retention.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.retention.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.status.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.status.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.status.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.status.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.activity.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.activity.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.activity.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.activity.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.actor.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.actor.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.actor.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.actor.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.coverage.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.coverage.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.coverage.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.coverage.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.evidence.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.evidence.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.evidence.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.evidence.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.exports.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.exports.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.exports.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.exports.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.retention.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.retention.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.retention.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.density.graded.retention.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.activity.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.activity.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.activity.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.activity.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.actor.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.actor.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.actor.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.actor.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.coverage.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.coverage.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.coverage.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.coverage.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.evidence.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.evidence.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.evidence.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.evidence.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.exports.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.exports.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.exports.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.exports.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.retention.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.retention.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.retention.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.retention.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.activity.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.activity.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.activity.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.activity.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.actor.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.actor.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.actor.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.actor.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.coverage.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.coverage.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.coverage.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.coverage.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.evidence.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.evidence.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.evidence.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.evidence.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.exports.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.exports.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.exports.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.exports.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.retention.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.retention.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.retention.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.rhythm.graded.retention.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.activity.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.activity.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.activity.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.activity.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.actor.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.actor.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.actor.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.actor.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.coverage.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.coverage.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.coverage.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.coverage.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.evidence.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.evidence.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.evidence.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.evidence.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.exports.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.exports.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.exports.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.exports.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.retention.r1__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.retention.r2__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.retention.r3__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.graded.retention.r4__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__light-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__light-375.json"
  - "test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__light-768.json"
  - "test/fixtures/operator_surface/scorecards/story.data_display.data_table__system-1280.json"
  - "test/fixtures/operator_surface/scorecards/story.data_display.data_table__system-375.json"
  - "test/fixtures/operator_surface/scorecards/story.data_display.data_table__system-768.json"
  - "test/fixtures/operator_surface/scorecards/story.forms.field__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/story.forms.field__light-375.json"
  - "test/fixtures/operator_surface/scorecards/story.forms.field__light-768.json"
  - "test/fixtures/operator_surface/scorecards/story.foundations.index__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/story.foundations.index__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/story.foundations.index__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/story.groups.operator_groups__light-1280.json"
  - "test/fixtures/operator_surface/scorecards/story.groups.operator_groups__light-375.json"
  - "test/fixtures/operator_surface/scorecards/story.groups.operator_groups__light-768.json"
  - "test/fixtures/operator_surface/scorecards/story.overlays.modal__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/story.overlays.modal__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/story.overlays.modal__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/story.patterns.operator_patterns__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/story.patterns.operator_patterns__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/story.patterns.operator_patterns__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/story.primitives.button__dark-1280.json"
  - "test/fixtures/operator_surface/scorecards/story.primitives.button__dark-375.json"
  - "test/fixtures/operator_surface/scorecards/story.primitives.button__dark-768.json"
  - "test/fixtures/operator_surface/scorecards/story.states.data_state__system-1280.json"
  - "test/fixtures/operator_surface/scorecards/story.states.data_state__system-375.json"
  - "test/fixtures/operator_surface/scorecards/story.states.data_state__system-768.json"
  - "test/support/operator_surface_fixtures.ex"
  - "test/threadline/ci_attestation_contract_test.exs"
  - "test/threadline/ci_topology_contract_test.exs"
  - "test/threadline/clean_checkout_contract_test.exs"
  - "test/threadline/dialyzer_ignore_contract_test.exs"
  - "test/threadline/dialyzer_slice_contract_test.exs"
  - "test/threadline/e2e_preflight_contract_test.exs"
  - "test/threadline/formatter_topology_contract_test.exs"
  - "test/threadline/main_ci_observer_contract_test.exs"
  - "test/threadline/operator_surface/critic_trust_test.exs"
  - "test/threadline/operator_surface/live/coverage_live_test.exs"
  - "test/threadline/operator_surface/live/export_status_live_test.exs"
  - "test/threadline/operator_surface/live/retention_history_live_test.exs"
  - "test/threadline/operator_surface/mechanical_checker_test.exs"
  - "test/threadline/operator_surface/operator_surface_fixture_contract_test.exs"
  - "test/threadline/operator_surface/refute_partition_test.exs"
  - "test/threadline/operator_surface/stress_ledger_test.exs"
  - "test/threadline/operator_surface/stress_router_test.exs"
  - "test/threadline/operator_surface/style_contract_test.exs"
  - "test/threadline/ci_workflow_parity_contract_test.exs"
  - "test/threadline/planning_dependency_contract_test.exs"
  - "test/threadline/planning_independence_contract_test.exs"
  - "test/threadline/plug_test.exs"
  - "test/threadline/policy/redaction_presenter_test.exs"
  - "test/threadline/readme_doc_contract_test.exs"
  - "test/threadline/release_artifact_contract_test.exs"
  - "test/threadline/removed_artifact_contract_test.exs"
  - "test/threadline/row_history_focus_evidence_contract_test.exs"
covered_digest: "v1:sha256:680599af5951be9d593724bb18f57aa3d84e79c4bef658635f1c4fd263013541"
previous_covered_digest: "v1:sha256:a696b527c1f0d8ea7b0266887c9e8e95e686c9d8ec33e2a036ded5e26956701b"
covered_digest_note: "Recomputed 2026-09-22 at HEAD 4d893e19 over the same 586-file covered set as the previous report. All 586 paths resolve on disk (checked individually before hashing), so the fingerprint is determinate rather than failing closed. The set is unchanged because the 6 commits since 51ee7137 touched exactly one covered implementation file — examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts, which added the two fail-closed reader tests in 4d893e19 — plus .planning bookkeeping and mix.exs/mix.lock (a test-only yaml_elixir dependency added by Phase 200). No Phase 199 gate, alias, fixture, or contract test was removed or weakened by the drift."
scope_note: "SUPERSEDED 2026-09-22 — `mix ci.all` was subsequently run end to end at `2925bd95` (a descendant of this target) and exited 0, so the carry below is now closed by measurement: credo 3150 mods/funs no issues, 1677 library tests 0 failures, 117 example tests 0 failures, Dialyzer `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`, Playwright 318 passed / 26 skipped / 0 failed. The original wording is kept verbatim below so the carry is legible rather than erased. ORIGINAL: The full `mix ci.all` aggregate was NOT re-run end to end at this HEAD. Ten of its twelve members were re-measured inside a fresh planning-quarantined clone of 4d893e19; the strict Dialyzer member was re-measured in-tree at 4d893e19; the Playwright browser lane was NOT re-run and is carried from the 51ee7137 measurement under an evidenced zero-delta argument (see 'Aggregate Coverage and What Was Carried'). This is stated in the report body rather than absorbed into the verdict."
advisory:
  - finding: ".tool-versions is untracked and not ignored, so a fresh clone cannot resolve `mix` on an asdf machine; bin/verify-clean-checkout and bin/verify-planning-independent both failed with `No version is set for command mix` until ASDF_* versions were supplied externally."
    category: other
    reason: "DECOUPLE-05's letter (a fresh clone plus `mix deps.get` leaves `git status` clean) is unaffected and was re-measured green. But the two clone-based decoupling probes are not self-sufficient from a clean clone on this toolchain manager. Resolution would be tracking a toolchain pin or documenting the required env in CONTRIBUTING."
    evidence_status: "reproduced twice at HEAD (exit 126 without the env pin, exit 0 with it)"
  - finding: "Two permissive JSON reads remain in the critic tree: critic/cache.ts:89 (verdict cache) and critic/gate.ts:369 (before-pole snapshot)."
    category: other
    reason: "Both are datasets whose ABSENCE is a defined non-error (cache miss; no pre-edit score → caller voids), so they are correctly outside D1's three required datasets. Recorded so 'all critic reads fail closed' is not over-read from the new pins."
    evidence_status: "source-read at HEAD; not a gap"
human_verification: []
---

# Phase 199: Decouple Verification Report

**Phase Goal:** The test suite and every CI gate are self-contained in the source tree, so `mix ci.all` passes with `.planning/` renamed away; dead planning artifacts and root one-off scripts are gone with citations repaired; a fresh clone plus `mix deps.get` is clean; Dialyzer is a real, measured, ratcheting gate before the refactor-heavy phases begin.

**Verified:** 2026-09-22T11:08:34Z
**Status:** passed
**Re-verification:** Yes — second pass, re-measured at current HEAD
**Verification target:** `4d893e19099601cf6af12372adabbbe77510e1a4` (confirmed ancestor of HEAD: it *is* HEAD; `git merge-base --is-ancestor` exits 0)
**Previous target:** `51ee7137fdea94dd79832de29a7e00bb1d89f2eb` (ancestor; 6 commits behind)

## Why this report was rewritten

`gsd-tools query verification.status .planning/phases/199-decouple` reported `stale`. The staleness was not resolved by moving a commit pointer. Every roadmap truth was re-executed against `4d893e19`, in a fresh planning-quarantined clone where the truth is about planning independence, and in-tree where the truth is about the current toolchain. The commands and their exact outputs are recorded below.

Two ancestry facts from the previous report are worth stating plainly, because they were load-bearing there and are dangling now:

- The previous body claimed `Current committed HEAD: d6d3baee…`. `d6d3baee` is **not** an ancestor of today's HEAD. Neither is `edb2b240` (`tracking_finalized_head`) nor `c45b7712` (`historical_certification_sha`). Those three SHAs no longer resolve into this branch's history, so nothing in this report rests on them. The one previous field that *does* resolve — `current_head: 51ee7137` — is an ancestor and is retained as `previous_verification_target`.
- Accordingly the Plan-21 historical certificate at `c45b7712` is cited here only as a historical receipt, never as current-head proof.

## Verdict

Phase 199 still achieves its goal at `4d893e19`. No regression was found in the 6 commits since the previous verification, and the one behavioral gap the previous pass left open (UAT test 10, coverage id `199-05-D1`) is now genuinely closed by deterministic evidence.

The decisive re-measurement is a fresh `--no-local` clone of the exact HEAD with `.planning` renamed to `.planning.quarantine` before any command ran. In that clone, with `.planning` verifiably absent after every step:

| `ci.all` member | Re-run at 4d893e19 with `.planning` absent | Result |
|---|---|---|
| `verify.format` | yes | exit 0 |
| `verify.credo` | yes | exit 0 |
| `compile --warnings-as-errors` | yes | exit 0 (105 files) |
| `verify.compile_no_optional` | yes | exit 0 |
| `verify.test` | yes | **1677 tests, 0 failures, 1 excluded** |
| `verify.threadline` | yes (`MIX_ENV=test`) | exit 0 — 1/1 expected tables covered, 0 violated |
| `verify.example` | yes | **117 tests, 0 failures** |
| `verify.doc_contract` | yes | exit 0 |
| `verify.critic_trust` | yes | exit 0 |
| `verify.mechanical` | yes | exit 0 |
| `cmd env MIX_ENV=dev mix verify.dialyzer` | in-tree at HEAD, not in the clone | **Total errors: 0, Skipped: 0, Unnecessary Skips: 0** |
| `verify.example_browser` (Playwright) | **yes** — measured at `2925bd95` via full `ci.all` (318 passed / 26 skipped / 0 failed); originally carried from `51ee7137` | see below |

`.planning` was confirmed still absent after `mix deps.get --check-locked`, after compilation, and after every gate above.

## Aggregate Coverage and What Was Carried

> **Carry closed (2026-09-22).** Everything in this section described the state at
> `4d893e19`, where the browser lane was carried on a zero-delta argument rather
> than measured. `mix ci.all` has since been run end to end at `2925bd95` and
> exited 0, including the Playwright member. The zero-delta argument turned out
> to be correct, but it is no longer what the verdict rests on. The section is
> left unedited below so the difference between a carried lane and a measured one
> stays visible in the record.


This report does **not** claim that `mix ci.all` was executed end to end at `4d893e19`. Two members were handled differently, and both deviations are stated rather than absorbed:

1. **Strict Dialyzer** was re-measured in the working tree at HEAD rather than inside the quarantined clone, because a fresh clone forces a cold PLT rebuild. The property it proves (zero warnings, zero skips, zero unnecessary skips, with the full optional-app PLT) is a property of the committed source and analyzer configuration, not of the directory layout; `.planning` independence for this member is separately evidenced by the source scan below. Result at HEAD: `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`, exit 0, against the `deps-dev` PLT with `warnings: [:unmatched_returns, :extra_return, :unknown]`.
2. **The Playwright browser lane was not re-run.** Running it here is barred (no app server in this context produces ~45 spurious sub-100ms failures) and it is the hour-plus member of the aggregate. It is carried from the `51ee7137` measurement under a delta argument that was checked, not assumed: `git diff 51ee7137..HEAD` touches exactly two library files, and both changes are `+ @moduledoc false` inside `actor_live.ex` and `transaction_live.ex` — zero rendered-output delta. The only other source change in the window is a *unit* test file, which I ran directly (below). No `.spec.ts`, template, style token, or fixture changed.

The honest reading: planning independence and gate health are re-established at HEAD for every deterministic member; the browser member's currency rests on an evidenced no-op diff plus its last full run at an ancestor.

## Goal Achievement

### Observable Truths (roadmap success criteria)

| # | Roadmap truth | Status | Evidence re-measured at 4d893e19 |
|---|---|---|---|
| 1 | `mix ci.all` passes with `.planning/` renamed away; the five datasets are test-owned, `git mv`-moved, reader-wired, and excluded from the Hex tarball. | ✓ VERIFIED | Fresh `--no-local` clone at exact HEAD, `.planning` quarantined before any command: 10 of 12 aggregate members green (table above), `.planning` never reappeared. Dialyzer member green in-tree; browser member carried on an evidenced zero-delta diff. Corpus: `git ls-files test/fixtures/operator_surface` = 429 tracked (427 evidence + README + manifest). `package.files` in mix.exs:384-385 lists only `lib priv/fonts guides brandbook/… .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md` — `test/fixtures` and `.planning` are both outside it, and `release_artifact_contract_test.exs` (which refutes `.planning/` entries in a real archive) passed. Source scan for planning reads across `lib/ test/ mix.exs bin/ .github/workflows/ scripts/` found only refutations and one writer (`bin/record-ci-attestation`, not in any gate). |
| 2 | Dead planning/root artifacts are removed, no register or doc cites a vanished path, the root holds no one-off migration/patch script, and the silently-disabled assertion is enabled and passing. | ✓ VERIFIED | `mix test removed_artifact_contract_test.exs planning_dependency_contract_test.exs planning_independence_contract_test.exs` → 13 tests, 0 failures at HEAD. Tracked root inventory re-enumerated with `git ls-files --full-name \| grep -v /`: 21 files, all of them config/docs/manifests (`.credo.exs`, `.dialyzer_ignore.exs`, `.dockerignore`, `.env.example`, `.formatter.exs`, `.gitignore`, `.release-please-manifest.json`, `CHANGELOG/CLAUDE/CODE_OF_CONDUCT/CONTRIBUTING/DESIGN-SYSTEM/GEMINI/LICENSE/README/SECURITY`, two `docker-compose*.yml`, `mix.exs`, `mix.lock`, `release-please-config.json`) — no migration or patch script. `verify.doc_contract` (21 contract files including the README assertion) passed inside the planning-absent clone. |
| 3 | A fresh clone plus `mix deps.get` leaves `git status` clean, generated/crash/tarball/e2e artifacts are ignored, and `mix format --check-formatted` covers bench, scripts, and the example app. | ✓ VERIFIED | `bin/verify-clean-checkout` executed at HEAD: `SOURCE_SHA=4d893e19…`, `DEPENDENCY_STATUS=CLEAN`, `GENERATED_PROBE_STATUS=CLEAN`, `TRACKABLE_CONTROLS=VISIBLE`, `CLEAN_CHECKOUT_VERIFIED`, `SAFE_TEMP_TREE_REMOVED`, exit 0 — this now includes the newly-added test-only `yaml_elixir` dependency, so the clean-clone contract holds across the Phase 200 dependency change. `mix format --check-formatted` exit 0 in-tree and `verify.format` exit 0 in the quarantined clone; `formatter_topology_contract_test.exs` passed. See the advisory about `.tool-versions` for the one friction this probe exposed. |
| 4 | Dialyzer runs inside `ci.all` with all optional deps in the PLT, its cold cost is measured and documented in CONTRIBUTING, and its ignore file holds only specific commented entries under a committed lower-only ceiling. | ✓ VERIFIED | `env MIX_ENV=dev mix verify.dialyzer` at HEAD: `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`, exit 0. `.dialyzer_ignore.exs` re-read at HEAD: literally `[]`. `dialyzer_ignore_contract_test.exs` + `dialyzer_slice_contract_test.exs` passed in the 186-test bundle, with `@warning_ceiling 0` and the exact W01–W40 / five-fixture partition intact. `.github/workflows/ci.yml:132` still defines `verify-dialyzer` and line 880 still lists it under `ci-required`'s `needs`; the new `community-health.yml` workflow added since the last verification did not displace it. `CONTRIBUTING.md:491-542` still records the authenticated cold/hit job evidence and the 2x-derived timeout. |

**Roadmap score:** 4/4.
**Merged score:** 40/40 must-haves (4 roadmap truths + 36 non-duplicate plan-specific truths). `behavior_unverified: 0`.

### Plan-Specific Truths (36) — regression pass

Re-verification optimization: these 36 passed in the previous pass and none of them names an artifact touched by the 6-commit delta except 199-05 (treated as a full re-verification below). They were re-confirmed by re-running the executable contracts that own them rather than by re-reading each summary:

| Plans | Truths | Re-measurement at HEAD | Status |
|---|---:|---|---|
| 199-01, 199-03, 199-07, 199-08, 199-09, 199-10, 199-11, 199-12 | 8 | 186-test focused bundle (15 contract files incl. fixture-manifest, mechanical-checker, removal/citation, formatter-topology, clean-checkout, release-artifact, CI topology/parity/attestation/observer, e2e preflight, critic-trust, refute-partition) — **186 tests, 0 failures**; plus the 13-test planning bundle | ✓ VERIFIED |
| 199-02, 199-06 | 2 | Full root suite in the planning-absent clone — 1677 tests, 0 failures; example suite 117/0 | ✓ VERIFIED |
| **199-05** | 1 | **Fully re-verified — see "Test 10 / 199-05-D1" below.** `npm run test:paths` 17/17, `npm run typecheck` exit 0, and the three required-read call sites read directly in source | ✓ VERIFIED |
| 199-13, 199-15 … 199-20 | 20 | Strict analyzer 0/0/0 at HEAD; ignore ceiling 0; W01–W40 partition contracts green | ✓ VERIFIED |
| 199-14 | 1 | `verify-dialyzer` job + `ci-required` needs entry present at ci.yml:132/880; CONTRIBUTING cold/hit receipts intact | ✓ VERIFIED |
| 199-21 | 3 | Planning-quarantined clone at exact HEAD completed its gate set and the clone was removed; `planning_independence_contract_test.exs` (restore-before-cleanup failure path) green | ✓ VERIFIED |

## Test 10 / 199-05-D1 — judgement on the flip to `pass`

**The flip is warranted.** I checked it as a claim, not as a given, and it survives.

D1 asserts two things: (a) all bounded critic readers and the shell edge consume the shared path authority, and (b) required scorecard, refute, and ledger evidence fails closed. Neither half is a statement about LLM scoring quality, so a real-`ANTHROPIC_API_KEY` run was never the instrument that would settle it; `npm run critic:check` would have proven the planner exits 0, not that a missing scorecard is fatal. Re-scoping to the claim as written is the correct move, and the paid loop stays parked.

What I measured, rather than accepting:

- **The artifact, not the config.** I read the three call sites in source at HEAD — `critic/bundle.ts:138 readRequiredJson<ScorecardJson>(scorecardPath, …)`, `critic/refute.ts:165 readRequiredJson<RefuteSet>(refuteSetPath, …)`, `critic/gate.ts:518 readRequiredJson<LedgerShape>(paths().ledgerPath, …)` — and the adapter itself at `support/operator-surface-paths.ts:238-264`, which wraps `readFileSync` and `JSON.parse` in try/catch and **throws** a diagnostic naming dataset, resolved path, repository scope, and recovery command. There is no return path that yields `null`, `{}` or `[]`.
- **The tests actually run and actually discriminate.** `npm --prefix examples/threadline_phoenix/e2e run test:paths` → 17 tests, 0 failures (was 14 before this commit; +2 new, +1 from an earlier commit). `npm run typecheck` → exit 0. The call-site test carries its own non-vacuity control (it asserts the matcher rejects a permissive `JSON.parse(readFileSync(scorecardPath …))`), which is the guard whose absence produced the Phase 200 vacuous-gate finding.
- **They run in CI, not only locally.** `package.json:6` `"test": "npm run test:unit && playwright test"`, `:20` `test:unit` includes `support/operator-surface-paths.test.ts`; `run-e2e.sh:304/306` invokes `npm test`; `mix.exs:238/262` invokes `run-e2e.sh` from `verify.example_browser`, which is the last member of `ci.all`. The chain is real.

Two limits I am recording rather than smoothing over, neither of which defeats the flip:

- The call-site test is a **source-text** assertion. It pins the identifier passed (`scorecardPath`, `refuteSetPath`, `paths().ledgerPath`), so the regression it names — swapping to a permissive read — is caught, and the mutation check proves that. It would not catch a reader that passed a *different but correctly-required* path. That is a weaker property than the one D1 claims, but the adapter-level throw test covers the behavioral half, so the pair is sufficient.
- D1's "all bounded critic readers" half was already covered by the pre-existing 11-reader + `critic-before-pole.sh` sweep, which is an *import* assertion. The new call-site pin is precisely the acknowledgement that an import is a proxy. The two remaining permissive reads in the critic tree (`cache.ts:89`, `gate.ts:369`) are recorded in `advisory:` — both read datasets whose absence is a defined non-error, so they are correctly outside D1's three.

The deferred follow-up ("prove D1 against a real-key refute battery") is correctly marked `withdrawn` rather than dropped: a real-key run would validate scoring quality, which is a different claim and is not owed by Phase 199.

## Requirements Coverage

| Requirement | Status | Re-measured evidence |
|---|---|---|
| DECOUPLE-01 | ✓ SATISFIED | Planning-quarantined clone at exact HEAD; 10/12 aggregate members green, `.planning` absent throughout |
| DECOUPLE-02 | ✓ SATISFIED | 429 tracked fixture files; fixture/manifest contracts green; `package.files` excludes `test/fixtures` |
| DECOUPLE-03 | ✓ SATISFIED | `removed_artifact_contract_test.exs` green; Git-derived citation scan clean |
| DECOUPLE-04 | ✓ SATISFIED | 21-file tracked root inventory re-enumerated — no one-off script; README assertion green inside `verify.doc_contract` |
| DECOUPLE-05 | ✓ SATISFIED | `bin/verify-clean-checkout` exit 0 at HEAD, including the new test-only dependency |
| DECOUPLE-06 | ✓ SATISFIED | `mix format --check-formatted` exit 0; formatter-topology contract green |
| DECOUPLE-07 | ✓ SATISFIED | Dialyzer 0/0/0 at HEAD with the full optional-app PLT; `verify-dialyzer` → `ci-required` wiring intact |
| DECOUPLE-08 | ✓ SATISFIED | `.dialyzer_ignore.exs` is `[]` under `@warning_ceiling 0`; ratchet controls green |

ROADMAP and REQUIREMENTS map exactly DECOUPLE-01…08; no orphaned Phase 199 requirement.

## Locked Decision Coverage

30/30 honored. The previous report's per-decision table (D-01 … D-30) was re-checked against the delta rather than re-derived: no commit in `51ee7137..HEAD` touches a decision's artifact except D-08/D-09 (path-adapter authority), whose contracts were re-run green (`test:paths` 17/17, typecheck 0), and none weakens a decision. `.gitignore` drift noted in the previous digest note (machine-local `.planning/critic-scores/` entries) reinforces D-03/D-17/D-18 rather than eroding them.

## Behavioral Evidence (this pass)

| Behavior | Command | Result | Status |
|---|---|---|---|
| Root suite with `.planning` absent at exact HEAD | `mix verify.test` in quarantined clone | 1677 tests, 0 failures, 1 excluded | ✓ PASS |
| Example suite with `.planning` absent | `mix verify.example` in quarantined clone | 117 tests, 0 failures | ✓ PASS |
| Dependency fetch cannot resurrect planning | `mix deps.get --check-locked` then existence check | exit 0; `PLANNING_STILL_ABSENT` | ✓ PASS |
| Coverage gate with `.planning` absent | `MIX_ENV=test mix verify.threadline` | exit 0; 1/1 tables covered, 0 violated | ✓ PASS |
| Doc contracts with `.planning` absent | `mix verify.doc_contract` | exit 0 | ✓ PASS |
| Deterministic critic + mechanical gates, planning absent | `mix verify.critic_trust`, `mix verify.mechanical` | exit 0, exit 0 | ✓ PASS |
| No-optional compile, planning absent | `mix verify.compile_no_optional` | exit 0 | ✓ PASS |
| Focused Phase 199 contracts in-tree | 15 named ExUnit files | 186 tests, 0 failures | ✓ PASS |
| Planning-decoupling contracts in-tree | 3 named ExUnit files | 13 tests, 0 failures | ✓ PASS |
| Strict analyzer in-tree | `env MIX_ENV=dev mix verify.dialyzer` | 0 errors, 0 skipped, 0 unnecessary skips | ✓ PASS |
| Formatting in-tree | `mix format --check-formatted` | exit 0 | ✓ PASS |
| Clean-clone probe | `bin/verify-clean-checkout` | 4 markers + safe cleanup; exit 0 | ✓ PASS |
| TypeScript path/fail-closed unit tests | `npm run test:paths` | 17 tests, 0 failures | ✓ PASS |
| TypeScript compile | `npm run typecheck` | exit 0 | ✓ PASS |
| Playwright browser lane | RUN — full `ci.all` at `2925bd95`, exit 0 | 318 passed, 26 skipped, 0 failed; the 8 known local screenshot failures self-skip under `CI=true`, which is how `ci.all` invokes the lane | ✓ MEASURED |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Planning quarantine at exact HEAD | clone `--no-local` + `mv .planning .planning.quarantine` + gate set | `PLANNING_STATUS=ABSENT` and `PLANNING_STILL_ABSENT` after every step; all deterministic gates exit 0 | PASS |
| `bin/verify-clean-checkout` | direct execution at HEAD | exit 0 with all four markers | PASS |
| `bin/verify-planning-independent` | attempted; not completed | Blocked by the untracked `.tool-versions` (exit 126, `No version is set for command mix`) and then deliberately not run end to end because it includes the browser lane. Its deterministic portion was reproduced manually above. | PARTIAL (see advisory) |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `examples/threadline_phoenix/e2e/critic/label.ts` | 708 | TODO for future pair-token wiring | ℹ️ Info | Pre-dates Phase 199 (blame a248073a, 2026-07-03); no Phase 199 gate depends on pair mode. Carried unchanged from the previous pass. |
| `bin/safe-temp-tree` and verifiers | n/a | `XXXXXX` mktemp templates | ℹ️ False positive | Secure `mktemp` syntax, not a debt marker. |
| critic prompt files | n/a | `JTBD` matched a naive `TBD` grep | ℹ️ False positive | Job-to-be-done prose. |

No new unreferenced `TBD`/`FIXME`/`XXX` marker appears in the delta. The delta introduced one test file and two `@moduledoc false` lines; neither carries a debt marker.

## Human Verification Required

None. Phase 199 owns no visual delta and has no UI-SPEC. Every truth resolved to executable evidence at this HEAD, and no truth was left ⚠️ PRESENT_BEHAVIOR_UNVERIFIED. The two disclosures above (carried browser lane, `.tool-versions` friction) are recorded as scope/advisory, not as human checkpoints: neither asks a human to observe a behavior that grep cannot see.

## Gaps Summary

No gaps. No regression in the 6 commits since `51ee7137`, and the previous pass's single open item (UAT test 10 / `199-05-D1`, previously `skipped`) is closed by deterministic, mutation-proven, CI-wired evidence that I re-ran and independently corroborated in source.

Non-blocking signals carried forward: the untracked `.tool-versions` that makes both clone probes non-self-sufficient on asdf; two intentionally-permissive optional-dataset reads in the critic tree; upstream dependency advisories printed during a fresh `mix deps.get` (a repository-wide maintenance concern, not a decoupling failure); the previously-noted single retry-only Playwright flake and six pre-existing rubric `sha8=00000000` warnings, neither re-measured this pass.

---

_Verified: 2026-09-22T11:08:34Z_
_Verifier: Claude (gsd-verifier), re-verification pass at 4d893e19_
