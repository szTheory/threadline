---
phase: 200-public-surface
reviewed: 2026-09-13T03:10:57Z
depth: standard
files_reviewed: 703
files_reviewed_list:
  - .dialyzer_ignore.exs
  - .formatter.exs
  - .github/ISSUE_TEMPLATE/01-bug.yml
  - .github/ISSUE_TEMPLATE/02-feature-request.yml
  - .github/ISSUE_TEMPLATE/03-question.yml
  - .github/ISSUE_TEMPLATE/config.yml
  - .github/pull_request_template.md
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/flake-detection.yml
  - .github/workflows/release.yml
  - .gitignore
  - CHANGELOG.md
  - CLAUDE.md
  - CODE_OF_CONDUCT.md
  - CONTRIBUTING.md
  - DESIGN-SYSTEM.md
  - README.md
  - SECURITY.md
  - bench/.formatter.exs
  - bench/audit_capture_bench.exs
  - bench/bench_helper.exs
  - bench/redaction_and_changed_from_bench.exs
  - bin/classify-flake-run
  - bin/compare-required-contexts
  - bin/observe-main-ci
  - bin/record-ci-attestation
  - bin/safe-temp-tree
  - bin/upsert-ci-issue
  - bin/verify-branch-protection
  - bin/verify-clean-checkout
  - bin/verify-dialyzer-slice
  - bin/verify-planning-independent
  - bin/verify-playwright-fail-fast
  - bin/verify-row-history-focus-red-control
  - config/test.exs
  - examples/threadline_phoenix/.formatter.exs
  - examples/threadline_phoenix/README.md
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
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/run-e2e.sh
  - examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts
  - examples/threadline_phoenix/e2e/support/operator-surface-paths.ts
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-graded-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-storybook-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/register.spec.ts
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_runs.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/temporal.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/threadline_stress_session.ex
  - examples/threadline_phoenix/test/support/walkthrough_case.ex
  - examples/threadline_phoenix/test/threadline_phoenix/demo/advisory_lock_pinning_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo/retention_tail_env_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_http_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/workers/post_touch_worker_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_happy_path_test.exs
  - guides/adoption-evidence-playbook.md
  - guides/adoption-pilot-backlog.md
  - guides/audit-indexing.md
  - guides/brownfield-continuity.md
  - guides/code-walkthrough.md
  - guides/configuration-and-commands.md
  - guides/domain-reference.md
  - guides/evaluating-threadline.md
  - guides/getting-started-saas.md
  - guides/how-threadline-works.md
  - guides/incident-playbook.md
  - guides/integration-contracts.md
  - guides/integrations/phx-gen-auth.md
  - guides/integrations/sigra.md
  - guides/local-docker-dx.md
  - guides/operator-surface.md
  - guides/performance.md
  - guides/production-checklist.md
  - guides/upgrade-path.md
  - lib/mix/tasks/critic.measure.ex
  - lib/mix/tasks/critic.synth.ex
  - lib/mix/tasks/threadline.evidence.show.ex
  - lib/mix/tasks/threadline.gen.triggers.ex
  - lib/mix/tasks/threadline.health.coverage.ex
  - lib/mix/tasks/threadline.policy.show.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/capture/migration.ex
  - lib/threadline/capture/redaction_policy.ex
  - lib/threadline/capture/trigger_capture_config.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/threadline/change_diff.ex
  - lib/threadline/continuity.ex
  - lib/threadline/critic_trust/krippendorff_alpha.ex
  - lib/threadline/critic_trust/ledger_splice.ex
  - lib/threadline/critic_trust/measure.ex
  - lib/threadline/critic_trust/rank_metrics.ex
  - lib/threadline/evidence/subject.ex
  - lib/threadline/export.ex
  - lib/threadline/export/cleanup_task.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/export_queue.ex
  - lib/threadline/export_queue/oban.ex
  - lib/threadline/export_queue/task_adapter.ex
  - lib/threadline/governance/export_job.ex
  - lib/threadline/governance/migration.ex
  - lib/threadline/governance/retention_run.ex
  - lib/threadline/governance/saved_view.ex
  - lib/threadline/health/coverage_schemas.ex
  - lib/threadline/health/policy.ex
  - lib/threadline/integrations/sigra.ex
  - lib/threadline/investigation/incident_bundle.ex
  - lib/threadline/investigation/linked_change.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/components/logo.ex
  - lib/threadline/operator_surface/components/surface_header.ex
  - lib/threadline/operator_surface/controllers/export_controller.ex
  - lib/threadline/operator_surface/controllers/theme_controller.ex
  - lib/threadline/operator_surface/coverage/on_mount.ex
  - lib/threadline/operator_surface/coverage/snapshot.ex
  - lib/threadline/operator_surface/export_auth_plug.ex
  - lib/threadline/operator_surface/exports/filename.ex
  - lib/threadline/operator_surface/exports/filter_params.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/mechanical_checker.ex
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/operator_surface/scope.ex
  - lib/threadline/operator_surface/script.ex
  - lib/threadline/operator_surface/session_plug.ex
  - lib/threadline/operator_surface/stress_fixtures.ex
  - lib/threadline/operator_surface/stress_router.ex
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/operator_surface/theme_auth_plug.ex
  - lib/threadline/operator_surface/ui.ex
  - lib/threadline/plug.ex
  - lib/threadline/policy/redaction_presenter.ex
  - lib/threadline/query.ex
  - lib/threadline/query/actor_history_page.ex
  - lib/threadline/retention/policy.ex
  - lib/threadline/retention/pruner.ex
  - lib/threadline/semantics/migration.ex
  - lib/threadline/storage.ex
  - lib/threadline/storage/local.ex
  - lib/threadline/storage/s3.ex
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
  - test/mix/tasks/threadline.evidence_show_test.exs
  - test/mix/tasks/threadline.incident_test.exs
  - test/mix/tasks/threadline/export_test.exs
  - test/support/operator_surface_fixtures.ex
  - test/support/storage_schema_case.ex
  - test/threadline/branch_protection_comparison_contract_test.exs
  - test/threadline/capture/trigger_changed_from_test.exs
  - test/threadline/capture/trigger_context_test.exs
  - test/threadline/capture/trigger_redaction_test.exs
  - test/threadline/capture/trigger_test.exs
  - test/threadline/ci_attestation_contract_test.exs
  - test/threadline/ci_issue_upsert_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/clean_checkout_contract_test.exs
  - test/threadline/code_walkthrough_doc_contract_test.exs
  - test/threadline/community_health_contract_test.exs
  - test/threadline/dialyzer_ignore_contract_test.exs
  - test/threadline/dialyzer_slice_contract_test.exs
  - test/threadline/e2e_preflight_contract_test.exs
  - test/threadline/evidence/proof_test.exs
  - test/threadline/example_phoenix_readme_contract_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/formatter_topology_contract_test.exs
  - test/threadline/getting_started_saas_doc_contract_test.exs
  - test/threadline/governance/evidence_record_test.exs
  - test/threadline/guide_graph_contract_test.exs
  - test/threadline/how_threadline_works_doc_contract_test.exs
  - test/threadline/idle_transaction_reaper_contract_test.exs
  - test/threadline/integration_contracts_doc_contract_test.exs
  - test/threadline/local_docker_dx_contract_test.exs
  - test/threadline/main_ci_observer_contract_test.exs
  - test/threadline/operator_surface/breadcrumb_test.exs
  - test/threadline/operator_surface/component_contract_test.exs
  - test/threadline/operator_surface/controllers/export_controller_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/critic_trust_test.exs
  - test/threadline/operator_surface/exports_doc_contract_test.exs
  - test/threadline/operator_surface/exports_mix_parity_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
  - test/threadline/operator_surface/live/coverage_live_test.exs
  - test/threadline/operator_surface/live/evidence_live_test.exs
  - test/threadline/operator_surface/live/export_status_live_test.exs
  - test/threadline/operator_surface/live/policy_redaction_live_test.exs
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/operator_surface/live/row_history_live_test.exs
  - test/threadline/operator_surface/mechanical_checker_test.exs
  - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
  - test/threadline/operator_surface/policy_show_mix_test.exs
  - test/threadline/operator_surface/presentation_test.exs
  - test/threadline/operator_surface/refute_partition_test.exs
  - test/threadline/operator_surface/row_history_component_test.exs
  - test/threadline/operator_surface/stress_fixtures_test.exs
  - test/threadline/operator_surface/stress_ledger_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/theme_doc_contract_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/operator_surface_doc_contract_test.exs
  - test/threadline/optional_deps_contract_test.exs
  - test/threadline/persona_routing_doc_contract_test.exs
  - test/threadline/pgbouncer_topology_test.exs
  - test/threadline/phase06_nyquist_ci_contract_test.exs
  - test/threadline/planning_dependency_contract_test.exs
  - test/threadline/planning_independence_contract_test.exs
  - test/threadline/playwright_fail_fast_contract_test.exs
  - test/threadline/plug_test.exs
  - test/threadline/policy/redaction_presenter_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/release_ci_gate_contract_test.exs
  - test/threadline/release_control_plane_contract_test.exs
  - test/threadline/removed_artifact_contract_test.exs
  - test/threadline/row_history_focus_evidence_contract_test.exs
  - test/threadline/storage_schema_call_site_contract_test.exs
  - test/threadline/storage_schema_prefix_contract_test.exs
findings:
  critical: 8
  warning: 4
  info: 0
  total: 12
status: issues_found
---

# Phase 200: Code Review Report

**Reviewed:** 2026-09-13T03:10:57Z
**Depth:** standard
**Files Reviewed:** 703
**Status:** issues_found

## Summary

The canonical 704-path workflow scope was reviewed, with `mix.lock` excluded under the review workflow's lock-file rule. The remaining 703 files include 435 fixture files, 107 test files, 33 documentation/template files, and 128 runtime or automation files. All 377 JSON fixtures parsed successfully and all 62 YAML files parsed successfully. The executable and security-sensitive paths contain eight release-blocking correctness/security defects and four robustness defects. The most serious problems are tenant scope being dropped from asynchronous exports, fail-open export authorization, a destructive action that does not actually re-authorize at event time, path traversal in the default local storage adapter, and shell command injection in the screenshot critic.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Background exports discard host authorization scope and can export cross-tenant rows

**File:** `lib/threadline/operator_surface/live/timeline_live.ex:277-294`, `lib/threadline/operator_surface/live/export_status_live.ex:64-85`, `lib/threadline/export/orchestrator.ex:42-47`

**Issue:** The synchronous export controller passes `scope` and `scope_query_fn` into `Threadline.Export`, but both LiveView queue paths persist only URL filters and actor identity. The worker later calls `stream_export_rows/2` with only `repo` and `storage_schema`. A user authorized with `{:ok, tenant_scope}` therefore sees scoped rows in the LiveView but receives an unscoped asynchronous export containing every tenant that matches the URL filters.

**Fix:** Persist a durable, host-defined scope descriptor with the export job and rehydrate it in the worker, then call `stream_export_rows/2` with both `scope:` and `scope_query_fn:`. If a scope cannot be durably rehydrated (for example with the generic Oban adapter), refuse to queue the background export and direct the operator to the already-scoped synchronous endpoint. Add a two-tenant regression test that asserts tenant A can never appear in tenant B's completed export.

### CR-02: An exception in `export_authorize_fn` enables LiveView exports

**File:** `lib/threadline/operator_surface/auth.ex:195-207`

**Issue:** `exports_enabled_for_socket?/3` returns `true` from its rescue clause. That is the opposite of the behavior used by the controller plug and by every other capability gate. A callback crash therefore sets `threadline_exports_enabled: true`, and the background-export handlers treat that cached boolean as authorization to insert and enqueue an export.

**Fix:** Change the rescue result to `false`, emit an authorization-error telemetry event, and add a LiveView test whose `export_authorize_fn` raises and whose forged `request_background_export` event creates no job.

### CR-03: Destructive retention prune checks a stale mount-time boolean instead of re-authorizing

**File:** `lib/threadline/operator_surface/live/retention_history_live.ex:77-105`, `lib/threadline/operator_surface/live/retention_history_live.ex:335-339`

**Issue:** The source comments and security contract say authorization is re-checked at action time, but `authorize_prune/1` only reads `socket.assigns[:threadline_policy_enabled]`, which was computed during mount. Revoking the operator's policy permission while the LiveView remains connected does not prevent that socket from triggering the irreversible prune.

**Fix:** Retain the server-side `policy_authorize_fn` (or a dedicated event authorizer) and invoke it against current server-owned assigns inside `handle_event("prune_now", ...)`. Treat denial, malformed returns, and exceptions as `{:error, :unauthorized}`. Add a connected-socket regression test that grants at mount, revokes before submit, and proves neither the audit action nor prune trigger occurs.

### CR-04: Default local storage permits path traversal for write, read, serve, and delete operations

**File:** `lib/threadline/storage/local.ex:29-85`

**Issue:** The public `:file_id` option and all subsequent adapter operations flow directly into `Path.join/1` without validating separators or dot segments. Values such as `../../outside.csv` escape `priv/threadline_exports`; `put/2` can overwrite, `get/1` and `path/1` can read/serve, and `delete/1` can remove arbitrary files reachable by the application user. `Path.expand/1` in `path/1` happens after the escaped path has already been constructed and does not enforce containment.

**Fix:** Resolve the export root once, reject non-basename IDs, separators, control characters, `.`/`..`, and disallowed extensions, then expand the candidate and require it to remain a strict child of the canonical root. Reject symlink traversal for existing components. Apply the same validated resolver to `put`, `get`, `path`, and `delete`, and add traversal/absolute/symlink escape tests.

### CR-05: Supplying an actor kind without an actor ID silently removes the actor filter

**File:** `lib/threadline/operator_surface/exports/filter_params.ex:141-179`

**Issue:** The public contract says a missing actor ID is an error, but the `actor_kind`-without-`actor_id` branch returns the filter list after deleting both actor parameters. A malformed or tampered request for one actor kind is silently widened into an unfiltered timeline/export, potentially disclosing substantially more audit data than the operator requested.

**Fix:** Replace the branch at lines 173-175 with `{:error, "actor id is required for non-anonymous actors"}`. Add controller and LiveView tests proving `actor_kind=user` without an ID returns an error and never executes an unfiltered query.

### CR-06: The standard actor bridge is not installed on export download routes

**File:** `lib/threadline/operator_surface/router.ex:93-107`, `lib/threadline/operator_surface/router.ex:135-158`, `lib/threadline/operator_surface/controllers/export_controller.ex:26-40`

**Issue:** When `actor_fn` is configured, `SessionPlug` is applied only inside the LiveView scope. The sibling export-controller pipeline installs only `ExportAuthPlug`, which neither invokes `actor_fn` nor restores `threadline_actor_ref` from the fetched session. Jobs are created with the LiveView actor, while downloads compare them to a missing controller actor and return 404. The documented normal mount therefore cannot download its own completed background exports unless the host happens to provide an undocumented duplicate actor assignment.

**Fix:** Have the export pipeline derive and assign the actor from the configured `actor_fn` (or add a controller-safe actor bridge that reads the fetched session), and fail closed when either the job actor or request actor is absent. Add an end-to-end router-macro test using only the documented `actor_fn` option: queue, complete, and download as the same actor; deny a different actor and a missing actor.

### CR-07: Cleanup permanently forgets exports whose backing-object deletion failed

**File:** `lib/threadline/export/cleanup_task.ex:79-100`

**Issue:** `perform_cleanup/2` ignores the result of `storage_adapter.delete/1` and unconditionally deletes the database job. A transient S3/network/permission failure therefore leaves the sensitive export object in storage beyond its retention deadline while removing the only metadata needed to retry or locate it. This is a retention failure and an unrecoverable orphaning path.

**Fix:** Delete the `ExportJob` only after the adapter reports `:ok` (with adapter-specific not-found treated as success). On any other result, retain the row, record/log the failure, and retry on the next cleanup pass. Add a storage stub that fails once and prove the row survives until object deletion succeeds.

### CR-08: Repository-contained screenshot paths are interpolated into a shell command unsafely

**File:** `examples/threadline_phoenix/e2e/critic/bundle.ts:165-202`

**Issue:** `JSON.stringify(path)` is not shell escaping: command substitutions and backticks are still evaluated inside the resulting double-quoted shell argument. A scorecard artifact path containing shell metacharacters can execute commands when the critic invokes `sips` or `magick`, even though filesystem containment checks pass.

**Fix:** Replace `execSync(commandString)` with `execFileSync("sips", ["-z", String(dstH), String(dstW), srcPath, "--out", tmpOut])` and the equivalent argument-array call for `magick`. Do the same for other path-bearing `execSync` calls in the critic tooling.

## Warnings

### WR-01: Export jobs are claimed non-atomically and can run concurrently more than once

**File:** `lib/threadline/export/orchestrator.ex:92-101`

**Issue:** `fetch_and_mark_running/3` performs an unlocked `get!` followed by an unconditional update. Duplicate enqueue, retry overlap, or two nodes can both read the same job and execute it, producing competing terminal updates and orphaning at least one generated object.

**Fix:** Claim only an eligible status with one atomic conditional update, or lock the row in a transaction with `FOR UPDATE SKIP LOCKED`; proceed only when exactly one worker wins the claim.

### WR-02: Actor extraction failures leave stale session ownership in place

**File:** `lib/threadline/operator_surface/session_plug.ex:22-34`

**Issue:** When `actor_fn` returns `nil`, an invalid value, or raises, the plug returns the connection unchanged. If the same browser session previously stored `threadline_actor_ref`, that old identity remains authoritative for subsequent LiveView mounts, causing actions and ownership checks to be attributed to the previous actor after logout, impersonation changes, or extraction failures.

**Fix:** Delete the `threadline_actor_ref` session key on every non-`ActorRef` result and in the rescue path. Add an identity-transition test that stores actor A, then returns nil/raises for actor B and proves no stale actor reaches the socket.

### WR-03: Operator-triggered destructive actions are attributed to a generic system actor

**File:** `lib/threadline/operator_surface/live/retention_history_live.ex:341-352`

**Issue:** The audit record described as the operator's request always uses `%ActorRef{type: :system, id: "retention_pruner"}` even though the socket already carries the authenticated operator identity. This prevents the audit trail from answering which human initiated an irreversible deletion and weakens repudiation controls.

**Fix:** Record the request with `socket.assigns[:threadline_actor_ref]` and fail closed if a destructive action has no accountable actor. If backend execution also needs a system record, emit it as a separate lifecycle action linked by correlation ID.

### WR-04: Missing Sigra identifiers collapse unrelated requests onto constant correlation IDs

**File:** `lib/threadline/integrations/sigra.ex:99-115`, `lib/threadline/integrations/sigra.ex:166-176`

**Issue:** The correlation builder interpolates `nil` session/token IDs into strings such as `sigra-session:` and `sigra-token:`. Requests with a recognized scope shape but absent identifier therefore share one correlation ID, incorrectly grouping unrelated audit actions and investigations.

**Fix:** Construct a correlation ID only when every required component is a non-empty binary; otherwise return `nil`/`%{}`. Add cases for missing session ID, token ID, and impersonation session ID.

---

_Reviewed: 2026-09-13T03:10:57Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
