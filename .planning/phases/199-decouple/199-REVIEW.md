---
phase: 199-decouple
reviewed: 2026-09-11T21:58:30Z
depth: standard
files_reviewed: 526
files_reviewed_list:
  - .dialyzer_ignore.exs
  - .formatter.exs
  - .github/workflows/ci.yml
  - .gitignore
  - CONTRIBUTING.md
  - DESIGN-SYSTEM.md
  - bench/.formatter.exs
  - bench/audit_capture_bench.exs
  - bench/bench_helper.exs
  - bench/redaction_and_changed_from_bench.exs
  - bin/safe-temp-tree
  - bin/verify-clean-checkout
  - bin/verify-dialyzer-slice
  - bin/verify-planning-independent
  - examples/threadline_phoenix/.formatter.exs
  - examples/threadline_phoenix/e2e/critic-before-pole.sh
  - examples/threadline_phoenix/e2e/critic/bundle.ts
  - examples/threadline_phoenix/e2e/critic/cache.ts
  - examples/threadline_phoenix/e2e/critic/gate.ts
  - examples/threadline_phoenix/e2e/critic/label.ts
  - examples/threadline_phoenix/e2e/critic/label_web.ts
  - examples/threadline_phoenix/e2e/critic/panel.ts
  - examples/threadline_phoenix/e2e/critic/prompt.ts
  - examples/threadline_phoenix/e2e/critic/refute.ts
  - examples/threadline_phoenix/e2e/critic/report.ts
  - examples/threadline_phoenix/e2e/critic/report_html.ts
  - examples/threadline_phoenix/e2e/critic/rubric.ts
  - examples/threadline_phoenix/e2e/critic/run.ts
  - examples/threadline_phoenix/e2e/critic/scorecard.ts
  - examples/threadline_phoenix/e2e/package.json
  - examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts
  - examples/threadline_phoenix/e2e/support/operator-surface-paths.ts
  - examples/threadline_phoenix/e2e/tests/operator-graded-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-storybook-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts
  - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/threadline_stress_session.ex
  - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
  - lib/mix/tasks/critic.measure.ex
  - lib/mix/tasks/critic.synth.ex
  - lib/threadline/change_diff.ex
  - lib/threadline/continuity.ex
  - lib/threadline/critic_trust/measure.ex
  - lib/threadline/export.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/integrations/sigra.ex
  - lib/threadline/investigation/incident_bundle.ex
  - lib/threadline/investigation/linked_change.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/mechanical_checker.ex
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/stress_router.ex
  - lib/threadline/plug.ex
  - lib/threadline/policy/redaction_presenter.ex
  - lib/threadline/query.ex
  - lib/threadline/query/actor_history_page.ex
  - lib/threadline/storage/local.ex
  - mix.exs
  - test/fixtures/dialyzer/README.md
  - test/fixtures/dialyzer/critic-tooling.json
  - test/fixtures/dialyzer/export-investigation.json
  - test/fixtures/dialyzer/operator-boundaries.json
  - test/fixtures/dialyzer/operator-liveviews.json
  - test/fixtures/dialyzer/query-storage.json
  - test/fixtures/operator_surface/README.md
  - test/fixtures/operator_surface/critic-scores/.gitkeep
  - test/fixtures/operator_surface/design-system-ledger.json
  - test/fixtures/operator_surface/golden/golden-set.json
  - test/fixtures/operator_surface/golden/queue.json
  - test/fixtures/operator_surface/golden/rounds/.gitkeep
  - test/fixtures/operator_surface/golden/synthetic-set.json
  - test/fixtures/operator_surface/manifest.sha256
  - test/fixtures/operator_surface/refute/refute-set.json
  - test/fixtures/operator_surface/scorecards/page.actor.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.actor.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.actor.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.actor.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.actor.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.actor.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__light-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__light-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__light-375.json
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__light-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.empty__light-768.json
  - test/fixtures/operator_surface/scorecards/page.coverage.error__dark-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.error__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.coverage.error__dark-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.error__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.coverage.error__dark-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.error__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.coverage.error__light-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.error__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.coverage.error__light-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.error__light-375.json
  - test/fixtures/operator_surface/scorecards/page.coverage.error__light-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.error__light-768.json
  - test/fixtures/operator_surface/scorecards/page.coverage.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.coverage.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.coverage.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.coverage.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.coverage.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.coverage.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__light-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__light-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__light-375.json
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__light-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.coverage.permission__light-768.json
  - test/fixtures/operator_surface/scorecards/page.evidence.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.evidence.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.evidence.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.evidence.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.evidence.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.evidence.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.exports.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.exports.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.exports.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.exports.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.exports.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.exports.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.home.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.home.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.home.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.home.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.home.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.home.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.redaction.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.redaction.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.redaction.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.redaction.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.redaction.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.redaction.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.retention.empty__dark-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.empty__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.retention.empty__dark-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.empty__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.retention.empty__dark-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.empty__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.retention.empty__light-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.empty__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.retention.empty__light-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.empty__light-375.json
  - test/fixtures/operator_surface/scorecards/page.retention.empty__light-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.empty__light-768.json
  - test/fixtures/operator_surface/scorecards/page.retention.error__dark-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.error__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.retention.error__dark-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.error__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.retention.error__dark-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.error__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.retention.error__light-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.error__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.retention.error__light-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.error__light-375.json
  - test/fixtures/operator_surface/scorecards/page.retention.error__light-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.error__light-768.json
  - test/fixtures/operator_surface/scorecards/page.retention.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.retention.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.retention.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.retention.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.retention.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.retention.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.retention.permission__dark-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.permission__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.retention.permission__dark-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.permission__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.retention.permission__dark-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.permission__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.retention.permission__light-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.permission__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.retention.permission__light-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.permission__light-375.json
  - test/fixtures/operator_surface/scorecards/page.retention.permission__light-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.retention.permission__light-768.json
  - test/fixtures/operator_surface/scorecards/page.row-history.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.row-history.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.row-history.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.row-history.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.row-history.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.row-history.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.shell.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.shell.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.shell.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.shell.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.shell.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.shell.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.timeline.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.timeline.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.timeline.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.timeline.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.timeline.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.timeline.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__light-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__light-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__light-375.json
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__light-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.empty__light-768.json
  - test/fixtures/operator_surface/scorecards/page.transaction.error__dark-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.error__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.transaction.error__dark-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.error__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.transaction.error__dark-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.error__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.transaction.error__light-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.error__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.transaction.error__light-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.error__light-375.json
  - test/fixtures/operator_surface/scorecards/page.transaction.error__light-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.error__light-768.json
  - test/fixtures/operator_surface/scorecards/page.transaction.happy__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.transaction.happy__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.transaction.happy__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.transaction.happy__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.transaction.happy__light-375.json
  - test/fixtures/operator_surface/scorecards/page.transaction.happy__light-768.json
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-1280.json
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-375.json
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__dark-768.json
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__light-1280.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__light-1280.json
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__light-375.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__light-375.json
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__light-768.aria.yml
  - test/fixtures/operator_surface/scorecards/page.transaction.permission__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.flawed__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.brand-fidelity.mis-jobbed-accent.polished__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.actor.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.actor.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.actor.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.actor.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.coverage.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.coverage.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.coverage.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.coverage.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.evidence.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.evidence.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.evidence.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.evidence.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.export.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.export.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.export.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.export.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.retention.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.retention.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.retention.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.retention.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.timeline.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.timeline.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.timeline.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.brand_fidelity.graded.timeline.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.actor.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.actor.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.actor.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.actor.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.coverage.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.coverage.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.coverage.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.coverage.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.diff.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.diff.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.diff.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.diff.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.evidence.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.evidence.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.evidence.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.evidence.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.retention.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.retention.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.retention.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.retention.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.status.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.status.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.status.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.color_contrast.graded.status.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.flawed__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.density.card-section-wrap.polished__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.flawed__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.density.chrome-bloat.polished__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.activity.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.activity.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.activity.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.activity.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.actor.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.actor.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.actor.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.actor.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.coverage.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.coverage.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.coverage.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.coverage.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.evidence.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.evidence.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.evidence.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.evidence.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.exports.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.exports.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.exports.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.exports.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.retention.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.retention.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.retention.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.density.graded.retention.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.flawed__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.flattened.polished__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.activity.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.activity.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.activity.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.activity.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.actor.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.actor.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.actor.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.actor.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.coverage.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.coverage.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.coverage.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.coverage.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.evidence.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.evidence.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.evidence.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.evidence.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.exports.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.exports.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.exports.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.exports.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.retention.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.retention.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.retention.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.hierarchy.graded.retention.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.flawed__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.doubled-padding.polished__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.activity.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.activity.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.activity.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.activity.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.actor.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.actor.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.actor.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.actor.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.coverage.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.coverage.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.coverage.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.coverage.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.evidence.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.evidence.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.evidence.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.evidence.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.exports.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.exports.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.exports.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.exports.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.retention.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.retention.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.retention.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.rhythm.graded.retention.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.activity.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.activity.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.activity.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.activity.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.actor.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.actor.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.actor.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.actor.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.coverage.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.coverage.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.coverage.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.coverage.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.evidence.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.evidence.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.evidence.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.evidence.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.exports.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.exports.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.exports.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.exports.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.retention.r1__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.retention.r2__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.retention.r3__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.graded.retention.r4__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.flawed__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.typography.scale-collapse.polished__light-768.json
  - test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__dark-1280.json
  - test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__dark-375.json
  - test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__dark-768.json
  - test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__light-1280.json
  - test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__light-375.json
  - test/fixtures/operator_surface/scorecards/refute.veto-ordering.off-token-accent.polished__light-768.json
  - test/fixtures/operator_surface/scorecards/story.data_display.data_table__system-1280.json
  - test/fixtures/operator_surface/scorecards/story.data_display.data_table__system-375.json
  - test/fixtures/operator_surface/scorecards/story.data_display.data_table__system-768.json
  - test/fixtures/operator_surface/scorecards/story.forms.field__light-1280.json
  - test/fixtures/operator_surface/scorecards/story.forms.field__light-375.json
  - test/fixtures/operator_surface/scorecards/story.forms.field__light-768.json
  - test/fixtures/operator_surface/scorecards/story.foundations.index__dark-1280.json
  - test/fixtures/operator_surface/scorecards/story.foundations.index__dark-375.json
  - test/fixtures/operator_surface/scorecards/story.foundations.index__dark-768.json
  - test/fixtures/operator_surface/scorecards/story.groups.operator_groups__light-1280.json
  - test/fixtures/operator_surface/scorecards/story.groups.operator_groups__light-375.json
  - test/fixtures/operator_surface/scorecards/story.groups.operator_groups__light-768.json
  - test/fixtures/operator_surface/scorecards/story.overlays.modal__dark-1280.json
  - test/fixtures/operator_surface/scorecards/story.overlays.modal__dark-375.json
  - test/fixtures/operator_surface/scorecards/story.overlays.modal__dark-768.json
  - test/fixtures/operator_surface/scorecards/story.patterns.operator_patterns__dark-1280.json
  - test/fixtures/operator_surface/scorecards/story.patterns.operator_patterns__dark-375.json
  - test/fixtures/operator_surface/scorecards/story.patterns.operator_patterns__dark-768.json
  - test/fixtures/operator_surface/scorecards/story.primitives.button__dark-1280.json
  - test/fixtures/operator_surface/scorecards/story.primitives.button__dark-375.json
  - test/fixtures/operator_surface/scorecards/story.primitives.button__dark-768.json
  - test/fixtures/operator_surface/scorecards/story.states.data_state__system-1280.json
  - test/fixtures/operator_surface/scorecards/story.states.data_state__system-375.json
  - test/fixtures/operator_surface/scorecards/story.states.data_state__system-768.json
  - test/support/operator_surface_fixtures.ex
  - test/threadline/ci_attestation_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/clean_checkout_contract_test.exs
  - test/threadline/dialyzer_ignore_contract_test.exs
  - test/threadline/dialyzer_slice_contract_test.exs
  - test/threadline/e2e_preflight_contract_test.exs
  - test/threadline/formatter_topology_contract_test.exs
  - test/threadline/main_ci_observer_contract_test.exs
  - test/threadline/operator_surface/critic_trust_test.exs
  - test/threadline/operator_surface/mechanical_checker_test.exs
  - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
  - test/threadline/operator_surface/refute_partition_test.exs
  - test/threadline/operator_surface/stress_ledger_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/phase06_nyquist_ci_contract_test.exs
  - test/threadline/planning_dependency_contract_test.exs
  - test/threadline/planning_independence_contract_test.exs
  - test/threadline/plug_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/removed_artifact_contract_test.exs
  - test/threadline/row_history_focus_evidence_contract_test.exs

findings:
  critical: 2
  warning: 3
  info: 0
  total: 5
status: issues_found
---

# Phase 199: Code Review Report

**Reviewed:** 2026-09-11T21:58:30Z
**Depth:** standard
**Files Reviewed:** 526
**Status:** issues_found

## Summary

The review covered every existing non-planning path in the Phase 199 diff. The 427-file operator-surface payload was audited through its manifest, integrity contract, and representative schema consumers; every manifest checksum passed. The focused Elixir contracts passed (43 tests), the TypeScript path-adapter suite passed (11 tests), shell syntax checks passed, and the submitted aggregate certification evidence was considered. Those successes do not cover the five defects below: two fail-open safety/gating paths and three containment or generated-state defects remain.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01: Mechanical gate accepts malformed nested evidence as clean

**File:** `/Users/jon/projects/threadline/lib/threadline/operator_surface/mechanical_checker.ex:240-265` (also `306-321`, `469-503`, `535-544`, `608-617`, and `795-796`)

**Issue:** `validate_scorecard/1` validates only top-level container types and checks that the background token is a string. It never validates the nested fields consumed by the WCAG, conformance, and MODE-B checks. Downstream parse failures are then translated into success-shaped values: `wcag_violation/3` returns no violation for any failed parse, invalid CSS sizes are skipped, invalid colors are dropped, and missing/non-numeric MODE-B metrics become zero. A direct invocation with an invalid background color, an invalid color pair, invalid applied colors, and an empty `mode_b` object returned `{:ok, []}`. Malformed or tampered evidence can therefore bypass the mechanical gate rather than failing closed. The fixture integrity contract at `/Users/jon/projects/threadline/test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:174-193` only requires a string `cell_id`, so it does not close this gap.

**Fix:** Deeply validate every consumed nested field before evaluating a scorecard: require parseable token/pair colors, the required element-style keys and parseable CSS values, every required numeric MODE-B metric, and parseable applied colors. Return `{:error, {:malformed_scorecard, reason}}` for any invalid value; do not convert parse failures or absent metrics to an empty violation list or zero. Add mutation tests for malformed nested scorecards.

#### CR-02: Worktree safety check fails open when Git cannot enumerate worktrees

**File:** `/Users/jon/projects/threadline/bin/safe-temp-tree:110-134` (removal authority at `193-205`)

**Issue:** `_safe_temp_tree_reject_worktree_root` reads `git worktree list` through process substitution. Bash does not propagate the producer's exit status through the `while` loop, so a failed Git command produces an empty stream and the function returns success. The caller then reaches `rm -rf` without proving that the target is not a registered worktree. This creates a data-loss path precisely when repository metadata is unavailable or Git fails.

**Fix:** Materialize the NUL-delimited registry into a safely created temporary file, check the `git worktree list --porcelain -z` exit status, and only then parse it. Any enumeration or parse failure must return nonzero before cleanup. Add a contract test with a fake `git` that fails specifically on `worktree list` and assert that the registered child is retained.

### Warnings

#### WR-01: Migrated generated outputs are no longer ignored

**File:** `/Users/jon/projects/threadline/.gitignore:58-67`; `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/support/operator-surface-paths.ts:87-111`; `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/cache.ts:68-113`; `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/refute.ts:61-62,149-157`; `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/report.ts:43-46,391`; `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/report_html.ts:34,238`; `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:105-115,374`

**Issue:** The path adapter moved generated route scorecards, verdict caches, reports, and refute transcripts under `test/fixtures/operator_surface`, but the ignore rules still point to their former `.planning` or e2e locations. `git check-ignore --no-index` confirms that `scorecards/route.*.json`, `critic-verdict-cache/*.json`, `CRITIQUE.md`, `critic-report.html`, and `refute/transcripts/*.json` are now trackable; only `critic-scores/*` is ignored. Running the documented capture/critic tools can dirty the repository and make nondeterministic evidence easy to commit accidentally. The clean-checkout probe only exercises `critic-scores`, so the successful certification does not detect the regression.

**Fix:** Route all nondeterministic outputs to one dedicated, source-anchored generated directory outside the immutable fixture roots and add exact anchored ignore rules for each producer-owned subtree/file. Extend `verify-clean-checkout` and the ignore contract to probe route scorecards, verdict cache entries, reports, and refute transcripts at their resolved destinations.

#### WR-02: Elixir output containment permits a parent of immutable evidence

**File:** `/Users/jon/projects/threadline/lib/mix/tasks/critic.measure.ex:222-245`

**Issue:** `validate_root_separation!/2` rejects equality and an output root nested inside an immutable root, but it does not reject the inverse relationship. For example, `--fixture-root test/fixtures/operator_surface --output-root test/fixtures` passes this separation check even though the output root contains every immutable evidence root. This contradicts the bidirectional overlap check implemented by the TypeScript adapter and leaves future output cleanup or recursive processing able to affect trusted inputs.

**Fix:** Reject overlap in both directions for each immutable root: `within?(output_root, immutable_root) or within?(immutable_root, output_root)`. Apply the check to canonical paths and add explicit tests for parent, child, equal, prefix-confusion, and symlink-alias cases.

#### WR-03: Early verifier failures can rename caller-owned state

**File:** `/Users/jon/projects/threadline/bin/verify-planning-independent:22-53` (early failure points at `79-85`; quarantine begins at `88-96`)

**Issue:** The EXIT trap always looks for the relative path `.planning.threadline-quarantine`, but the script does not enter the clone until line 88. If source-SHA, clone, checkout, or SHA verification fails first, cleanup runs in the caller's working directory. A caller-owned path with that name can be renamed to `.planning` or can cause cleanup to retain the clone. The existing tests exercise failures after the clone quarantine begins, not these pre-`cd` failure paths.

**Fix:** Track quarantine ownership explicitly (for example, initialize `PLANNING_QUARANTINED=0`, set it only after the clone-local `mv` succeeds, and condition restoration on that flag). Use absolute clone paths for restore checks, and add an early Git/clone-failure test that places sentinel `.planning` and quarantine names in the caller directory and asserts byte-for-byte preservation.

---

_Reviewed: 2026-09-11T21:58:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
