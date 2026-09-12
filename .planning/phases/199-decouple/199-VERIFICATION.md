---
phase: 199-decouple
verified: 2026-09-12T01:11:11Z
status: passed
score: 40/40 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirements_verified: 8/8
decisions_verified: 30/30
security_status: verified
security_threats: 61/61 closed
current_head: "d6d3baee5eabe993fede1b4e2100cb23f131bff8"
historical_certification_sha: "c45b7712"
regressions: []
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
  - "test/threadline/phase06_nyquist_ci_contract_test.exs"
  - "test/threadline/planning_dependency_contract_test.exs"
  - "test/threadline/planning_independence_contract_test.exs"
  - "test/threadline/plug_test.exs"
  - "test/threadline/policy/redaction_presenter_test.exs"
  - "test/threadline/readme_doc_contract_test.exs"
  - "test/threadline/release_artifact_contract_test.exs"
  - "test/threadline/removed_artifact_contract_test.exs"
  - "test/threadline/row_history_focus_evidence_contract_test.exs"
covered_digest: "v1:sha256:86ccdffd861a7dc1558ed003ee28d35e3249aa42a26e87f317a8e2973a45306c"
---

# Phase 199: Decouple Verification Report

**Phase Goal:** The test suite and every CI gate are self-contained in the source tree, so mix ci.all passes with .planning renamed away; dead planning artifacts and root one-off scripts are gone with citations repaired; a fresh clone plus mix deps.get is clean; Dialyzer is a real measured ratcheting gate before refactor-heavy phases.

**Verified:** 2026-09-12T01:11:11Z  
**Status:** passed  
**Re-verification:** No — initial verification  
**Current committed HEAD:** d6d3baee5eabe993fede1b4e2100cb23f131bff8

## Verdict

Phase 199 achieves its goal in the current committed tree. This verdict is based on direct inspection and fresh commands, not SUMMARY claims.

The strongest proof is a new execution of bin/verify-planning-independent against exact current HEAD. In its disposable no-local clone, it physically quarantined .planning, ran dependency setup and the complete mix ci.all aggregate, printed AGGREGATE_RESULT=PASS, restored .planning, removed only the registered temporary clone, and exited 0. The current aggregate produced 1,540 root tests with 0 failures and 1 intentional exclusion, 114 example tests with 0 failures, strict Dialyzer with 0 errors/skips/unnecessary skips, and the 344-test Playwright inventory with 317 passed, 26 intentional skips, and one retry-only pass.

No human verification is required. The phase is repository/tooling work, and each success criterion has executable current-tree evidence.

## Goal Achievement

### Observable Truths

| # | Roadmap truth | Status | Current evidence |
|---|---|---|---|
| 1 | mix ci.all passes with .planning absent; five datasets are test-owned, byte-preserved, reader-wired, and excluded from Hex. | ✓ VERIFIED | Current-head planning-independent probe exited 0. Git reports 427/427 R100 renames in 9de9d968; the live tree contains 429 tracked fixture-root files (427 evidence entries plus README and manifest). Fixture, path, planning-dependency, release archive, root, example, Dialyzer, and browser checks passed. |
| 2 | Dead planning/root artifacts are removed, citations are repaired, and the README assertion is active. | ✓ VERIFIED | All four declared targets are absent from the index and disk. The tracked-root executable inventory contains only .credo.exs, .dialyzer_ignore.exs, .formatter.exs, and mix.exs. The live removal/citation scanner and README mutation control passed in the 95-test focused bundle. |
| 3 | Fresh clone plus mix deps.get is clean and formatter ownership covers bench, scripts, and example. | ✓ VERIFIED | bin/verify-clean-checkout at current HEAD printed DEPENDENCY_STATUS=CLEAN, GENERATED_PROBE_STATUS=CLEAN, TRACKABLE_CONTROLS=VISIBLE, CLEAN_CHECKOUT_VERIFIED, and contained cleanup. mix format --check-formatted passed; .formatter.exs delegates bench and example and directly includes scripts. |
| 4 | Dialyzer is a full-build, blocking, measured, ratcheting gate. | ✓ VERIFIED | Current strict run reported Total errors: 0, Skipped: 0, Unnecessary Skips: 0. mix.exs contains the full optional-app PLT list and ci.all alias; CI has unconditional verify-dialyzer and ci-required wiring. CONTRIBUTING records authenticated cold/hit job evidence. The ignore ceiling is now 0 and fail-closed contract controls passed. |

**Roadmap score:** 4/4 roadmap truths verified.  
**Merged score:** 40/40 must-haves verified (4 roadmap truths plus 36 non-duplicate plan-specific truths; 0 present-but-behavior-unverified).

### Plan-Specific Truths

Every PLAN frontmatter truth was merged with the roadmap contract. The compact rows below preserve all 36 plan-specific truths while avoiding repetition of the four broader roadmap truths.

| Plan | Truths | Status | Direct evidence |
|---|---:|---|---|
| 199-01 | 1 | ✓ VERIFIED | MechanicalChecker requires explicit corpus/floors and fails closed; focused contracts pass. |
| 199-02 | 1 | ✓ VERIFIED | Source-anchored ExUnit roots and injected decoded stress ledger are wired; root/example tests pass. |
| 199-03 | 1 | ✓ VERIFIED | Mix anchors, separation, containment, atomic writes, and review command are implemented and tested. |
| 199-04 | 1 | ✓ VERIFIED | Single ESM path authority is imported; 14 path/symlink/atomic controls pass. |
| 199-05 | 1 | ✓ VERIFIED | Critic reader/writer family imports the shared adapter; critic dry-run and typecheck pass. |
| 199-06 | 1 | ✓ VERIFIED | Capture outputs use generated roots while reviewed snapshots remain trackable; contracts pass. |
| 199-07 | 1 | ✓ VERIFIED | Manifest is Git-index-derived and excludes mutable generated scores; live and mutation tests pass. |
| 199-08 | 1 | ✓ VERIFIED | Exactly 427 byte-identical R100 moves plus reader flips occur in atomic commit 9de9d968. |
| 199-09 | 1 | ✓ VERIFIED | Four deletions, recovery/citation repair, live scanner, and README mutation control all pass. |
| 199-10 | 1 | ✓ VERIFIED | Ignore rules are precise and formatter ownership is exactly one; clean-clone/formatter contracts pass. |
| 199-11 | 1 | ✓ VERIFIED | Current fresh-clone probe is clean; hardened cleanup and registered-worktree rejection tests pass. |
| 199-12 | 1 | ✓ VERIFIED | Active planning IO scan is empty; successor live assertions pass; retirement inventory is exact/recoverable. |
| 199-13 | 1 | ✓ VERIFIED via authorized re-slice | Immediate strict full-app gate and triage intent were completed by Plans 15–20 after the designed halt. |
| 199-14 | 1 | ✓ VERIFIED | Local/protected CI wiring, exact cache lifecycle, and authenticated cold/hit measurements exist and are tested. |
| 199-15 | 3 | ✓ VERIFIED | Sealed 40-warning input, W01/W02/W05 fixes, and source-owned bounded verifier contracts pass. |
| 199-16 | 3 | ✓ VERIFIED | Ten warnings/five origins are fully dispositioned; concrete Ecto/ActorRef types and continuity/storage fixes pass tests and analyzer. |
| 199-17 | 3 | ✓ VERIFIED | Fifteen warnings/five origins are dispositioned; export cleanup/bytes and Sigra/investigation contracts pass tests and analyzer. |
| 199-18 | 3 | ✓ VERIFIED | Seven warnings/four origins are dispositioned; auth/plug and presentation/redaction behavior is retained and tested. |
| 199-19 | 3 | ✓ VERIFIED | Five warnings/five LiveView origins are dispositioned; timer lifecycle and reachable result matching pass current analyzer and named timer test. |
| 199-20 | 4 | ✓ VERIFIED | Exact W01–W40/22-origin partition, zero residue/ceiling, strict ignore controls, full-app configuration, and live analyzer all pass. |
| 199-21 | 3 | ✓ VERIFIED | Current full planning-absent certification passes; restoration/cleanup failure test and hostile target/scanner controls pass. |

### Required Artifacts

The frontmatter artifact checker reported every declared artifact substantive across all 21 plans. Several path-literal key-link probes reported false negatives for module aliases, imported symbols, globs, and System.cmd calls; those links were checked manually below.

| Artifact | Expected | Status | Evidence |
|---|---|---|---|
| test/fixtures/operator_surface/ | Test-owned five-dataset corpus | ✓ VERIFIED | 429 tracked files; README says complete corpus is 427 evidence files; manifest contract passes. |
| test/fixtures/operator_surface/manifest.sha256 | Index-derived byte manifest | ✓ VERIFIED | Exists, non-empty, and live contract verifies it against Git-index entries. |
| lib/threadline/operator_surface/mechanical_checker.ex | Pure explicit-input checker | ✓ VERIFIED | run/1 requires scorecard_dir and mechanical_floors; no repository-relative fallback. |
| test/support/operator_surface_fixtures.ex | Test-edge path adapter | ✓ VERIFIED | Test authority points to the fixture tree and is consumed by corpus readers. |
| examples/threadline_phoenix/e2e/support/operator-surface-paths.ts | TypeScript edge resolver and safe writer | ✓ VERIFIED | Imported by critic and capture paths; traversal, symlink, alias, and atomic-write tests pass. |
| test/threadline/removed_artifact_contract_test.exs | Tracked deletion/citation/root scanner | ✓ VERIFIED | Live Git-derived scan passes and injected violations fail. |
| bin/verify-clean-checkout | Exact-SHA clean-clone proof | ✓ VERIFIED | Direct current-head execution exited 0. |
| bin/safe-temp-tree | Hardened sole recursive-cleanup primitive | ✓ VERIFIED | Canonical path, lstat identity, direct-child, and registered-worktree checks guard the sole recursive removal. |
| .formatter.exs and child formatter files | Exactly-one formatter ownership | ✓ VERIFIED | Format check and topology contract pass. |
| mix.exs, .dialyzer_ignore.exs, CI workflow | Analyzer configuration and gates | ✓ VERIFIED | Full apps, strict flags, zero ceiling, cache topology, measurements, and required aggregation are wired. |
| bin/verify-planning-independent | End-to-end exact-HEAD proof | ✓ VERIFIED | Direct probe completed aggregate, restore, and cleanup at current HEAD. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| mix ci.all | strict Dialyzer | cmd env MIX_ENV=dev mix verify.dialyzer | ✓ WIRED | mix.exs lines 160–175; direct aggregate executed it successfully. |
| bin/verify-planning-independent | mix ci.all | quarantined clone invocation | ✓ WIRED | Lines 94–131 clone exact HEAD, remove planning visibility, run aggregate, and assert it stays absent. |
| bin/verify-planning-independent | bin/safe-temp-tree | sourced containment/cleanup | ✓ WIRED | Restore precedes registered-tree cleanup; current probe emitted both markers. |
| ExUnit and Mix readers | test/fixtures/operator_surface | explicit test/Mix edge roots | ✓ WIRED | Live corpus contracts, mechanical/critic/refute tests, and aggregate pass. |
| Critic/capture TypeScript | operator-surface-paths.ts | imported resolver and writer exports | ✓ WIRED | run.ts, scorecard.ts, and capture specs import the adapter; 14 path tests and typecheck pass. |
| Mechanical checker tests | MechanicalChecker | explicit corpus and floors | ✓ WIRED | run/1 has no hidden repository default; positive/negative tests pass. |
| CI verify-dialyzer | ci-required | unconditional needs entry | ✓ WIRED | Workflow lines 132–251 define the job; lines 874–899 aggregate it under if: always(). |
| .dialyzer_ignore.exs | Dialyxir | ignore_warnings plus unused-filter enforcement | ✓ WIRED | mix.exs points to the file and enables list_unused_filters; live analyzer reports zero skipped/unused. |
| Removal scanner | tracked repository | git ls-files-derived source sets | ✓ WIRED | Direct System.cmd calls are present; live scanner passes. |
| Planning dependency scanner | active ExUnit/Mix/CI sources | Git-derived tracked set plus injected controls | ✓ WIRED | Current 95-test bundle passed and planning-independent aggregate provided behavioral proof. |

### Data-Flow Trace

| Consumer | Data source | Flow | Status |
|---|---|---|---|
| MechanicalChecker | Explicit scorecard_dir and mechanical_floors supplied by repository tests | JSON decode → validation → findings | ✓ FLOWING |
| Critic trust gate | Ledger, golden set, scorecards under test/fixtures/operator_surface | Edge adapter → decoded data → measured trust block | ✓ FLOWING |
| TypeScript critic/capture tools | import.meta.url-anchored repository root and explicit overrides | Resolver → contained immutable/generated roots → atomic writer | ✓ FLOWING |
| Release gate | Actual mix hex.build archive | Archive contents → rejection of test/fixtures and .planning | ✓ FLOWING |
| Planning-independent certification | Exact committed no-local clone | .planning quarantine → deps/PLT → mix ci.all → restore/cleanup | ✓ FLOWING |
| Dialyzer CI | mix.lock/mix.exs-keyed PLT plus full compiled build | Restore/build/save/analyze → parsed wall/RSS markers → required aggregate | ✓ FLOWING |

No rendered dynamic-data artifact is introduced by this non-UI phase; Level 4 here concerns repository evidence and gate data rather than UI rendering.

## Current Behavioral Evidence

| Behavior | Command | Result | Status |
|---|---|---|---|
| Exact current HEAD passes with .planning absent | bin/verify-planning-independent | Exit 0; exact SHA; planning absent; aggregate pass; planning restored; safe temp removed | ✓ PASS |
| Root tests inside planning-absent aggregate | mix verify.test via mix ci.all | 1,540 tests, 0 failures, 1 intentional exclusion | ✓ PASS |
| Example tests inside planning-absent aggregate | mix verify.example via mix ci.all | 114 tests, 0 failures | ✓ PASS |
| Browser lane inside planning-absent aggregate | Playwright via mix ci.all | 344 total: 317 passed, 26 intentional skips, 1 flaky test passed on retry | ✓ PASS WITH FLAKE |
| Focused Phase 199 contracts | 12 named ExUnit files | 95 tests, 0 failures | ✓ PASS |
| TypeScript path safety | npm run test:paths | 14 tests, 0 failures | ✓ PASS |
| TypeScript compile | npm run typecheck | Exit 0 | ✓ PASS |
| Critic dry-run | npm run critic:check | Exit 0; six pre-existing rubric sha8 warnings remain non-blocking | ✓ PASS |
| Root formatting | mix format --check-formatted | Exit 0 | ✓ PASS |
| Strict analyzer | mix dialyzer --no-check --list-unused-filters | 0 errors, 0 skipped, 0 unnecessary skips | ✓ PASS |
| Clean clone | bin/verify-clean-checkout | All four clean/control markers and safe cleanup; exit 0 | ✓ PASS |
| CONTEXT decision gate | check.decision-coverage-verify | 30 honored, 0 not_honored | ✓ PASS |
| Timer ownership transition | mix test test/threadline/operator_surface/live/export_status_live_test.exs:140 | 1 named test, 0 failures | ✓ PASS |
| Restore-before-cleanup failure transition | mix test test/threadline/planning_independence_contract_test.exs:45 | 1 named test, 0 failures | ✓ PASS |

### Probe Execution

| Probe | Result | Status |
|---|---|---|
| bin/verify-planning-independent | Current exact-HEAD clone passed complete aggregate with planning absent; restore and cleanup passed | PASS |
| bin/verify-clean-checkout | Current exact-HEAD dependency and generated-output cleanliness passed | PASS |
| Historical Plan 21 certificate at c45b7712 | 1,534 root, 114 example, 0 Dialyzer errors/skips, 318 browser passed plus 26 skips | PASS (historical) |
| Current direct strict Dialyzer | 0 errors/skips/unnecessary skips | PASS |

## Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| DECOUPLE-01 | ✓ SATISFIED | Current planning-independent exact-HEAD probe ran the full aggregate with .planning absent and exited 0. |
| DECOUPLE-02 | ✓ SATISFIED | 427 R100 Git renames in atomic commit 9de9d968; 427-row manifest and live reader/package contracts pass. |
| DECOUPLE-03 | ✓ SATISFIED | Four removal targets absent; Git-derived active citation scanner passes; removal inventory preserves recovery SHAs. |
| DECOUPLE-04 | ✓ SATISFIED | No tracked root one-off patch/migration script; README canonical-wording assertion and deliberate mutation control pass. |
| DECOUPLE-05 | ✓ SATISFIED | Fresh no-local clone remains clean after locked deps fetch and generated-output probes. |
| DECOUPLE-06 | ✓ SATISFIED | Root format command passes with bench/example subdirectories and scripts inputs under executable topology contracts. |
| DECOUPLE-07 | ✓ SATISFIED | Dialyzer runs locally and in CI with full optional apps; cold/hit cost and bounded timeout are documented from authenticated jobs. |
| DECOUPLE-08 | ✓ SATISFIED | Ignore file is empty under a committed zero ceiling; exact-entry, comment, broad-filter, duplicate, fixed-warning, extra-entry, and unused-filter controls fail closed. |

No orphaned Phase 199 requirements were found: ROADMAP and REQUIREMENTS map exactly DECOUPLE-01 through DECOUPLE-08.

## Locked Decision Coverage

| Decision | Status | Codebase evidence |
|---|---|---|
| D-01 | ✓ | Single mirror at test/fixtures/operator_surface with all five named roots. |
| D-02 | ✓ | Git reports exactly 427 R100 renames; tracked SHA-256 manifest and mutation control pass. |
| D-03 | ✓ | README and precise ignore rules separate immutable evidence from generated critic/report output. |
| D-04 | ✓ | Ordinary contracts are read-only; named maintainer writers use sibling temporary files and rename. |
| D-05 | ✓ | Live corpus test rejects missing/malformed/empty required evidence and validates non-vacuously. |
| D-06 | ✓ | Elixir/TypeScript containment and separation controls cover traversal, sibling prefixes, symlinks, and aliases. |
| D-07 | ✓ | MechanicalChecker requires explicit scorecard_dir and mechanical_floors; release archive excludes fixtures. |
| D-08 | ✓ | Path adapters live at test, Mix, TypeScript, and CI edges; no runtime/global fixture service locator. |
| D-09 | ✓ | Mix anchors to project_file, TypeScript to import.meta.url, tests expose roots; root/nested/worktree tests pass. |
| D-10 | ✓ | Explicit fixture-root/output-root options override deterministic defaults and are normalized/validated. |
| D-11 | ✓ | Writers reject immutable/generated aliasing and contained immutable targets except named canonical regeneration. |
| D-12 | ✓ | Missing/invalid/installed-Hex controls produce dataset, resolved-path, scope, and recovery diagnostics. |
| D-13 | ✓ | Surgical removal targets are absent; Git history is the recovery source. |
| D-14 | ✓ | Live citation scan is clean; historical addenda retain execution truth and route to durable evidence. |
| D-15 | ✓ | README assertion targets current support wording and its deliberate mutation is rejected. |
| D-16 | ✓ | Removal inventory records purpose/use/supersession/recovery; live consumer/citation scanner passes. |
| D-17 | ✓ | Shared ignores are anchored and producer-owned; broad-hide controls remain trackable. |
| D-18 | ✓ | e2e artifacts/results/reports are ignored while reviewed snapshots remain trackable; tarball ignore is root-anchored. |
| D-19 | ✓ | Disposable clone uses mix deps.get --check-locked and exact porcelain emptiness with generated probes. |
| D-20 | ✓ | Root delegates bench/example and includes scripts; child ownership/import contracts pass. |
| D-21 | ✓ | Tracked root executable inventory has no one-off patch/migration script; untracked operator scratch is out of contract. |
| D-22 | ✓ | Dialyxir is dev/test-only, runtime false, and blocking in ci.all/CI. |
| D-23 | ✓ | All 40 triaged warnings are fixed; ignore file is empty rather than a generated broad snapshot. |
| D-24 | ✓ | All nine optional applications plus Mix/ExUnit are explicitly in the PLT; no-optional compile remains independent. |
| D-25 | ✓ | unmatched_returns and extra_return are enabled; unknown was not removed. |
| D-26 | ✓ | Zero entries vacuously meet exact-commented shape; executable controls reject regex/file/class/wildcard/broad forms. |
| D-27 | ✓ | Ceiling is 0 and can only decrease; extra/broadened/duplicate/uncommented/unused controls fail. |
| D-28 | ✓ | Stable current-toolchain CI job, header/docs/topology, ci-required, and local ci.all are wired. |
| D-29 | ✓ | PLT is outside _build; precise ignores and exact toolchain/config/dependency keys; restore/build/save/analyze order is enforced. |
| D-30 | ✓ | CONTRIBUTING records same-SHA authenticated cold/hit measurements, hashes, runner/toolchain, wall/RSS, and 2x-derived nine-minute timeout. |

The centralized decision-coverage verb independently returned 30/30 honored. The table above records the direct evidence basis rather than using that heuristic as the sole proof.

## Historical Integrity and Plan 13

Plan 199-13 is not an unexplained incomplete plan. It halted at the designed 14-origin authority ceiling when the sealed full run exposed 22 origins. Plans 199-15 through 199-20 are the authorized bounded re-slice and consolidation. Their current artifacts account for the exact W01–W40 and 22-origin partition, fix every warning, set the ignore ceiling to 0, and pass both the contract and live analyzer.

The historical Plan 21 certificate at c45b7712 remains a valid receipt for that SHA. It is not used as current-head proof; the new direct probe at d6d3baee5eabe993fede1b4e2100cb23f131bff8 supersedes it for this verification.

## CI Measurement Receipt Calibration

The two CONTRIBUTING links are valid job-level Dialyzer evidence, not globally green workflow receipts:

| Run | Event / SHA | Workflow conclusion | Dialyzer job |
|---|---|---|---|
| 34642915672 | push / a4f21e7e | failure | Job 103406722917: success; cold miss measurements present |
| 34643744220 | workflow_dispatch / a4f21e7e | failure | Job 103410179816: success; exact-key hit measurements present |

The overall failures came from other jobs at that historical SHA. The documentation accurately labels the Dialyzer jobs as successful and uses them only for measurement. Current-tree gate correctness is established separately by the exact-HEAD local planning-independent aggregate, not by mischaracterizing those workflow conclusions.

## Security Status

Phase security status is verified at audited commit 3680760f: 61/61 registered threats closed, 0 open, with five explicitly accepted low risks. Current full tests include the remediated redaction/timer paths, the focused Phase 199 contracts pass, and current strict Dialyzer is clean.

The fresh dependency fetch prints advisories for several locked third-party packages, including high-severity notices. Those advisories are a repository-wide dependency-maintenance concern, not evidence that any Phase 199 decoupling truth failed; the DECOUPLE-05 contract is exact checkout cleanliness after dependency resolution. They are recorded here so “clean clone” is not mistaken for “no upstream advisories.”

## Test Quality Audit

- Requirement-linked ExUnit and Node contracts are active and passed; no phase requirement relies only on a skipped test.
- The aggregate has one intentional ExUnit exclusion governed by the existing topology contract.
- Playwright reports 26 intentional capture/snapshot skips. Active structural and route tests cover the Phase 199 fixture/gate paths.
- One reduced-motion test timed out on its first attempt because a visible toast intercepted the Show Drawer click, then passed in 1.4 seconds on retry. The aggregate exit remained 0. This is a reproducible flake signal worth fixing, but it is outside the Decouple goal and does not invalidate the successful planning-absent gate.
- Six rubric sha8=00000000 warnings remain visible during critic dry-run. They predate this phase and the critic command still exits 0; no Decouple requirement depends on those hashes.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| examples/threadline_phoenix/e2e/critic/label.ts | 708 | TODO for future pair token wiring | ℹ️ Info | Blame a248073a (2026-07-03), predates Phase 199; no Phase 199 gate depends on pair mode. |
| bin/safe-temp-tree and verifier scripts | n/a | “XXXXXX” mktemp templates matched a naive XXX grep | ℹ️ False positive | Secure mktemp syntax, not a debt marker. |
| critic prompt files | n/a | “JTBD” matched a naive TBD grep | ℹ️ False positive | Job-to-be-done prose, not a debt marker. |

No semantic unreferenced TBD, FIXME, or XXX marker was introduced in a Phase 199 implementation file. No missing, stub, orphaned, hollow, placeholder, or console-only must-have artifact was found.

## Human Verification Required

None. Visual/UI review is correctly N/A because Phase 199 owns no visual delta and has no UI-SPEC. Repository state, filesystem behavior, gate execution, analyzer results, CI topology, and measurement receipts are programmatically verifiable and were verified programmatically.

## Gaps Summary

No blocking gaps, incomplete wiring, behavior-unverified truths, requirement gaps, decision violations, or regressions were found.

Non-blocking follow-up signals are the single retry-only Playwright flake, the six pre-existing critic rubric-hash warnings, and upstream dependency advisories printed during the fresh clone. None changes the Phase 199 verdict.

---

_Verified: 2026-09-12T01:11:11Z_  
_Verifier: the agent (gsd-verifier)_
