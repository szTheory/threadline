# Phase253 acceptance reconciliation

**Current hosted outcome:** [required candidate CI is green](253-CI-RESULTS.md) at `5be2caf71010cb386cf9b4392db799f4e55c0808`, including both voting browser projects,31/31 required receipt identities, strict actual2x and the corrected full-text warning. Final independent goal assessment and normal completion writeback remain next. Historical pending/authority checkpoints below are superseded by this actual result, not erased. REL-01 remains separate and pending; no merge/tag/publish/risk acceptance is inferred.

Status: current430generic/34semantic identities are reconciled. Both hosted real200% journeys pass with strict acceptance explicitly enabled. Independent code/security reviews are clean; UI closes the identified alert-wrap correction from actual same-fixture RED/GREEN. Exact-candidate required CI and final verification remain pending; static rows, digests, declarations and images do not independently establish behavior or risk acceptance. Historical checkpoints below retain their original proof limits.

## Authorities and current local proof

- Current generic authority: [source checklist](../../../test/fixtures/operator_surface/source-surface-checklist.json),430 distinct rows with436 source anchors and4 explicit exclusion notes. [Route inventory](../../../test/fixtures/operator_surface/route-inventory.json) retains11 routes,418 items and one degraded extra state, totaling430 identities. Three real Phase253 declarations were added after first-CI independent census failure; existing IDs remain unchanged.
- Semantic authority: [journey inventory](../../../examples/threadline_phoenix/e2e/support/operator-journey-inventory.json),34 declaration rows (31 required,3 explicitly nonvoting),16 surfaces,5 resource dispositions,7 carry dispositions and11 scenarios. Source order and identities remain unchanged.
- Earlier metadata33/rendered24 checks remain historical evidence within their boundaries. First requiredCI exposed three missing independently discovered declarations; their existing-registry ownership is now fixed, and the affected156-owner check set passes with negative/source/duplicate controls retained. Whole semantic browser/required-CI acceptance remains pending.
- Current mounted/inclusive/capture proof and its source/data limits are in [paired evidence](253-PAIR-EVIDENCE.md), [sampling](253-SAMPLING.md) and [execution adjustments](253-EXECUTION.md). Required candidate CI remains pending even where local behavior passes.

## Mounted routes

| ID | Path | Current disposition |
| --- | --- | --- |
| route.home | `/audit` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.timeline | `/audit/timeline` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.transaction | `/transactions/:id` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.row | `/rows/:table/:record_id` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.drawer | `/transactions/:id/history/:table/:record_id` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.actor | `/audit/actors/service_account/zendesk-sync` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.coverage | `/audit/coverage` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.evidence | `/audit/evidence` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.exports | `/audit/exports` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.redaction | `/audit/policy/redaction` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |
| route.retention | `/audit/policy/retention` | Current route/source identity checked; required candidate CI passes; boundary-specific proof limits remain. |

Degraded Timeline stays an extra evidence state, not a twelfth route. The415 capture-item snapshot is retained as historical authority; no fresh415-image or all-state browser result is inferred.

## Generic source rows

Each row below has exactly one current static disposition. S means the actual current source/rendered/fixture contract results named above; it proves those contracts, not a mounted journey or data mutation. Exclusions retain their actual authority reason.

| Source identity | Kind | Disposition | Source owner(s) |
| --- | --- | --- | --- |
| `control.actions.href.4f84792665` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/actions.ex |
| `control.actions.navigate.6017f908cf` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/actions.ex |
| `control.actions.patch.e0a14117b9` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/actions.ex |
| `control.actor.href.1165b08259` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.href.823bc480cb` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.href.95c861860b` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.href.9bc92b48d2` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.navigate.93b3f91828` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.phx-click.2fa3cabd79` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.phx-click.3fed9323a5` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.phx-click.5ed0fd00a3` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.phx-click.b73faddd5e` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.phx-click.fe19d1f984` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.phx-viewport-bottom.2a39161ff3` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.actor.phx-viewport-top.b0abed742e` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/actor_live.ex |
| `control.components.href.1129bb6fe4` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/export_status_live/components.ex |
| `control.components.href.fe8fee9337` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/export_status_live/components.ex |
| `control.copy.value` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `control.coverage.data-tl-copy.4453682638` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/coverage_live.ex |
| `control.coverage.navigate.5be8e5d6cf` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/coverage_live.ex |
| `control.coverage.navigate.f8d8d9e358` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/coverage_live.ex |
| `control.coverage.phx-click.f1a6f3f868` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/coverage_live.ex |
| `control.coverage.phx-submit.3b3e7b3381` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/coverage_live.ex |
| `control.data.phx-mounted.c1734f2f05` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/data.ex |
| `control.display.data-tl-copy.6bc9f4aaf0` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `control.display.data-tl-copy.d71869c60b` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `control.evidence.href.8420c3628d` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/evidence_live.ex |
| `control.evidence.phx-click.retry` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/evidence_live.ex |
| `control.evidence.navigate.9b6303e2b4` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/evidence_live.ex |
| `control.evidence.patch.68ccdeb6b5` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/evidence_live.ex |
| `control.evidence.patch.77cca95277` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/evidence_live.ex |
| `control.evidence.patch.956ca2b941` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/evidence_live.ex |
| `control.export-status.navigate.81c4385aef` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/export_status_live.ex |
| `control.export-status.navigate.93b3f91828` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/export_status_live.ex |
| `control.export-status.navigate.9bc87f46f7` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/export_status_live.ex |
| `control.export-status.phx-click.b40cbe9307` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/export_status_live.ex |
| `control.filters.239.be344aac56f3` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.239.c363f049d6e7` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.href.1f60da21e9` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.href.7ab974c902` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.href.96661c06a0` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.href.db5c7a6aa5` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.href.fe5854f229` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.navigate.7250f72902` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.patch.d7aaa17cc0` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.phx-click.36684b05f0` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.phx-click.91ff08e109` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.phx-click.ae1b023ada` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.phx-click.d71e2a4880` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.phx-click.eacdef6b2e` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.phx-submit.3c17fd6489` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.filters.phx-submit.8f477d0ad2` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.form.href.4792e163b2` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `control.form.phx-click-away.7470920894` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `control.form.phx-click.7d109889d1` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `control.form.phx-mounted.f190da2f72` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `control.overlay.239.0d6129dd3631` | control | Excluded: Historical control removed in Phase251: redundant deferred focus handlers and duplicate global Coverage warning were replaced by the existing modal focus lifecycle and one selected-schema status. Retain this ID for historical evidence; no live declaration is claimed. |  |
| `control.overlay.239.27ed11aa535b` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.239.2baf1313506a` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.239.4fb0fe26cebd` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.239.bdaa036eaf17` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.239.e681d54e77e5` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.239.f02edb6ea6bf` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.239.f53dec5b4136` | control | Excluded: Historical control removed in Phase251: redundant deferred focus handlers and duplicate global Coverage warning were replaced by the existing modal focus lifecycle and one selected-schema status. Retain this ID for historical evidence; no live declaration is claimed. |  |
| `control.overlay.239.f5dd28ae4e43` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.239.fb1edc61fc0e` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.href.a007f9c03c` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.phx-click-away.211a2bc905` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.phx-click-away.7470920894` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.phx-click.6cf717f3ca` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.phx-click.7d109889d1` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.phx-click.88a513aed0` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.phx-click.dc303db529` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.phx-mounted.9bc301445d` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.overlay.phx-mounted.e9e1466ec6` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `control.page.href.df5c01aa06` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `control.page.phx-click.4e46cc0ad7` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `control.page.phx-click.ded21c9e6a` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `control.page.phx-click.ff7f7c9882` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `control.policy-redaction.navigate.10e4bba29a` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/policy_redaction_live.ex |
| `control.policy-redaction.navigate.1d33caff8f` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/policy_redaction_live.ex |
| `control.policy-redaction.navigate.62a5caa535` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/policy_redaction_live.ex |
| `control.policy-redaction.navigate.7a66b5c7b9` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/policy_redaction_live.ex |
| `control.policy-redaction.phx-submit.3b3e7b3381` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/policy_redaction_live.ex |
| `control.retention-history.href.417a3da4b4` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live/components.ex |
| `control.retention-history.navigate.def6ea1f42` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live/components.ex |
| `control.retention-history.navigate.e42a97ca6c` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live.ex |
| `control.retention-history.phx-click.39327fd8b0` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live.ex |
| `control.retention-history.phx-click.b1923ff2d5` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live.ex |
| `control.retention-history.phx-click.f5976720b6` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live.ex |
| `control.retention-history.phx-submit.e4adfa4855` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live.ex |
| `control.row-history.patch.6c7e1061bc` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/row_history_component.ex |
| `control.row-history.phx-change.8eb999e27a` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/row_history_component.ex |
| `control.sections.239.0167427e6e86` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.239.30ce520cf8d0` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.239.66dfd3818072` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.239.b65785e711ee` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.239.c5332f34e1c5` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.239.edd1de874752` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.href.2783eac4e8` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.href.3a6db0b52e` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.href.4445b182ff` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.href.51dc606cae` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.href.62a5f59eb4` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.href.8052dd6e35` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.href.84117cae97` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.href.c8f5d68691` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.href.ed27286fa1` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.phx-click.1bf64656f7` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.phx-click.2ee8bd9b36` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.phx-click.a9931db6fc` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.sections.phx-click.e34e281c65` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/stress_live/sections.ex |
| `control.start.href.2c5cabf485` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.start.href.64c1018de5` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.start.href.a0aad145b5` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.start.href.ac1ce752f8` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.start.href.bd952cdf26` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.start.href.c5355b10ab` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.start.href.ddcd26052c` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.start.navigate.5392f6725c` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.start.phx-submit.a477226343` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.start.phx-submit.f0b4076cf3` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/start_live.ex |
| `control.surface-header.action.964445b83e` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.01a6380c49` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.049141eabd` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.251f47a90c` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.coverage-warning-second` | control | Excluded: Historical control removed in Phase251: redundant deferred focus handlers and duplicate global Coverage warning were replaced by the existing modal focus lifecycle and one selected-schema status. Retain this ID for historical evidence; no live declaration is claimed. |  |
| `control.surface-header.href.2a0fd7ea66` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.2d904ff45b` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.3ebf1799a1` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.53d2981aed` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.557ec0bdee` | control | Excluded: Stable Coverage status test marker is a source anchor, not an actionable HTML attribute. | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.57e421191d` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.79afd09204` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.82ce3f310c` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.surface-header.href.d74235e5a6` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `control.timeline-live.239.51cd35c57127` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.timeline.data-tl-copy.321f7208cf` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/changes.ex |
| `control.timeline.href.72926ef11b` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/changes.ex |
| `control.timeline.href.959957c72c` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/changes.ex |
| `control.timeline.href.ecc81993ef` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/changes.ex |
| `control.timeline.href.ed4141ea7c` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/changes.ex |
| `control.timeline.patch.8e6b384b71` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live.ex |
| `control.timeline.phx-viewport-bottom.472e0e89e3` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/changes.ex |
| `control.transaction-live.239.3607e2964f19` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.transaction-live.239.982077b9d054` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.transaction.data-tl-copy.31eb3e6f5e` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.transaction.data-tl-copy.621e2b883e` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.transaction.href.480cb2b8e5` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.transaction.href.95c771c4db` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.transaction.navigate.1d9cac62dd` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.transaction.navigate.e54ea0cac2` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.transaction.phx-viewport-bottom.2a39161ff3` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.transaction.phx-viewport-top.b0abed742e` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.unsupported-view.href.f5cf19b6bb` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/unsupported_view.ex |
| `primitive.actions.button` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/actions.ex |
| `primitive.actions.icon_button` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/actions.ex |
| `primitive.actions.link` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/actions.ex |
| `primitive.data.data_panel` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/data.ex |
| `primitive.data.data_state` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/data.ex |
| `primitive.data.data_table` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/data.ex |
| `primitive.data.empty_state` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/data.ex |
| `primitive.data.error_state` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/data.ex |
| `primitive.data.loading_state` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/data.ex |
| `primitive.data.stale_banner` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/data.ex |
| `primitive.display.239.9fad0b44bf6b` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.239.b05346395a1c` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.alert` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.avatar` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.badge` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.card` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.cluster` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.code_block` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.divider` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.kv` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.ref` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.spinner` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.stack` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.display.stat_tile` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/display.ex |
| `primitive.form.combobox` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.form.error` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.form.error_summary` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.form.field` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.form.field_group` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.form.help` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.form.input` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.form.label` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.form.radio` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.form.switch` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/form.ex |
| `primitive.overlay.accordion` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.drawer` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.dropdown` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.hide_drawer` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.hide_modal` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.hide_toast` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.modal` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.popover` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.reconnect_banner` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.show_drawer` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.show_modal` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.show_toast` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.toast` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.overlay.tooltip` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `primitive.page.detail_header` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `primitive.page.page_header` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `primitive.page.pager` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `primitive.page.segmented_control` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `primitive.page.shell` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `primitive.page.tabs` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `primitive.page.toolbar` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/page.ex |
| `primitive.shell.navigation` | primitive | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/components/surface_header.ex |
| `route.actor` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.coverage` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.drawer` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.evidence` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.exports` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.home` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.redaction` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.retention` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.row` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.timeline` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `route.timeline.degraded` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts |
| `route.transaction` | route | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `seam.exports.changes-csv` | seam | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `seam.exports.changes-json` | seam | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `seam.exports.changes-ndjson` | seam | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `seam.exports.download-job_id` | seam | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `seam.theme` | seam | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/router.ex |
| `state.history.scalar-key` | state | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/row_history_component.ex |
| `state.history.unbounded` | state | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/row_history_component.ex |
| `state.language.labels` | state | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live.ex |
| `state.operator-accessibility.spec.239.0fea5b5641bc` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.operator-accessibility.spec.239.4341203b8c36` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.operator-accessibility.spec.239.d9ce68147284` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.operator-accessibility.spec.239.e93a9847e7bd` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.operator-component-contracts.spec.239.09df22e28860` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts |
| `state.operator-route-states.spec.239.008386555a22` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.operator-route-states.spec.243.c6e75f542ccf` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.operator-timeline-investigation-flow.spec.239.1cc6f878e92c` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts |
| `state.operator-timeline-investigation-flow.spec.239.a5e8a2b4ec68` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts |
| `state.operator-timeline-investigation-flow.spec.239.b40c24c965c5` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts |
| `state.operator-transaction-evidence.spec.239.0433b948ddfb` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-transaction-evidence.spec.ts |
| `state.operator-transaction-evidence.spec.239.560c2df20d4c` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-transaction-evidence.spec.ts |
| `state.operator-zoom-proof.spec.239.e6ac5a52d9bc` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts |
| `state.probe.00bcfb637b35` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts |
| `state.probe.01f898dbb288` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts |
| `state.probe.0292717b3613` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.02a3b7f54f0d` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts |
| `state.probe.043e8ac4176c` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts |
| `state.probe.04abb504d97f` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts |
| `state.probe.05d99f8826b1` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.082cefb4594a` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts |
| `state.probe.08b45250618f` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.0970b3a7e515` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.0a0641539f24` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts |
| `state.probe.0b9215bd10fc` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts |
| `state.probe.0d03d03b74b5` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts |
| `state.probe.111115840031` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts |
| `state.probe.131c042f6888` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.1372f40c8d84` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts |
| `state.probe.148e460d0b28` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts |
| `state.probe.1811058fcc0b` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts |
| `state.probe.182d4b3863b3` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.18a1fa7149a3` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts |
| `state.probe.1a4c32daf5fb` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts |
| `state.probe.204b6707b4ed` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts |
| `state.probe.219fee11aad3` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts |
| `state.probe.23b68185229d` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.27e56b85dcae` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.28be066c5828` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.probe.294e5bd72e3e` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.2bff6841258d` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.2d9f1b000df3` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts |
| `state.probe.2fe19d525dbc` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.34b6571a4ebf` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts |
| `state.probe.36721eaa934b` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts |
| `state.probe.37ffc2eb8df0` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts |
| `state.probe.396f82295a58` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.probe.3a3bea964666` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts |
| `state.probe.3feaab10e39a` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts |
| `state.probe.41778b9a4f7e` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.probe.463b77476361` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.46a1d4d8a696` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts |
| `state.probe.4929f3db268f` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts |
| `state.probe.4947b6201e33` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts |
| `state.probe.4a1b61caf387` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts |
| `state.probe.4bd91efc46e0` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.4dd2c4daae05` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts |
| `state.probe.4efde5a58850` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts |
| `state.probe.50189caa820c` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts |
| `state.probe.5136eda2b62f` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.probe.51839db14f08` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts |
| `state.probe.51a6497cd7d5` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.52472d3c8632` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.5494394b6f26` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.probe.54c4da9ec9f0` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.571bb7ea0d8b` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.probe.5cf84e12a0b5` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.620e48d02474` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.69a9d7f345d0` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.6bb572f664ff` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.6bd30a66f46b` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts |
| `state.probe.6c215aa688d6` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts |
| `state.probe.6eb7395f81fe` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts |
| `state.probe.732b488dde45` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts |
| `state.probe.750b772f6c68` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.7554f20830e6` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.757e622375e5` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts |
| `state.probe.767de114ded3` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.7702538967bf` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts |
| `state.probe.7871ba423526` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.788b98f2762d` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts |
| `state.probe.7956bf8ae936` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts |
| `state.probe.7966121c8575` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.79e6c9a3701a` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.probe.7b1889a9a425` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.7c6b5f9b24ca` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts |
| `state.probe.7d6f57cb9a4c` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.8170966f99ea` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts |
| `state.probe.82b89e8b77f8` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts |
| `state.probe.88d88621290d` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.8bdc5671729f` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.8d5bd8951dfa` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.918404089c15` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts |
| `state.probe.93226e0621bc` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.probe.9cd8622fd0ba` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts |
| `state.probe.a0b4a0824840` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts |
| `state.probe.a14e57a6c843` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.a2c12b48943e` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts |
| `state.probe.a4b85c162389` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts |
| `state.probe.a8828cf25e06` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts |
| `state.probe.a9370ecfbef0` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.probe.ab1fb39e5d14` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.probe.ac50d30eb4af` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts |
| `state.probe.acb655f75a99` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.aee6afc773f8` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts |
| `state.probe.b23a07de3010` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.b34957d24cf0` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.probe.b447c4fe554f` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts |
| `state.probe.b4ab3f00e2ca` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts |
| `state.probe.b5d99623898a` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.b76167c071b7` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.probe.b7714d148a40` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts |
| `state.probe.bc20c0fe64c4` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.probe.bc801efe3c20` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.bca26e193f74` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.bcc3db85f182` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts |
| `state.probe.be96fcfd4771` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.c4f8586ffdcc` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.probe.ce8fcd7a8343` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts |
| `state.probe.d49eb5a55c50` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.d93f0dbd225c` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts |
| `state.probe.d98e6e994fdc` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts |
| `state.probe.dc31c97bf183` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.probe.de2e6831ec4d` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.e17eb573d4f3` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts |
| `state.probe.e4194dffbe26` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.e5369399c294` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-features.spec.ts |
| `state.probe.e53d29107682` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts |
| `state.probe.eb3133cb6f25` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts |
| `state.probe.eca098c592f4` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.probe.edf78329d2fd` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.f0e456ad213c` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.f2347ad069f2` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts |
| `state.probe.f3c26d832634` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.probe.f4dbe45afc7e` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts |
| `state.probe.f57fb86d046c` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.probe.f707c305d03b` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.f7906eed93d1` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.probe.fa21db90b340` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts |
| `state.probe.fca3b6893779` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.token.paper` | state | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/style/01_tokens.css |
| `state.zoom.browser` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts |
| `state.generated.operator_earned_flows.dc882cbc86` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.generated.operator_earned_flows.00bf05efd2` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.generated.operator_earned_flows.768d9c32dd` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.generated.operator_motion.d8a3197e44` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.generated.operator_motion.6e25bfe50a` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.generated.operator_motion.a2e77d459a` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.generated.operator_motion.06ccfc4380` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.generated.operator_route_states.b299bd1b21` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.generated.operator_route_states.f8d8b4b3e4` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.generated.operator_route_states.77dc216b51` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.generated.operator_route_states.fa57a9f772` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `control.generated.row_history_component.70f3fafdec` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/row_history_component.ex |
| `control.generated.row_history_component.704aeee295` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/row_history_component.ex |
| `control.generated.timeline_live.f53f1af5d9` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live.ex |
| `control.generated.timeline_live.d6ba1cec46` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live.ex |
| `control.generated.filters.383d0060f7` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/timeline_live/filters.ex |
| `control.generated.transaction_live.cb4ff57980` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.generated.transaction_live.f60668a09f` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.generated.transaction_live.23102906f6` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/transaction_live.ex |
| `control.generated.overlay.d7969d79ea` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/ui/overlay.ex |
| `state.generated.operator_route_states.056362cb4f` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.generated.operator_route_states.a163a87d6c` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.generated.operator_route_states.a80c892492` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.generated.operator_route_states.453854b3e6` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.evidence.history-navigation` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `control.generated.phase241.b25038b380` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/policy_redaction_live.ex |
| `control.generated.phase241.c05c91e406` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/policy_redaction_live.ex |
| `state.generated.phase241.d0edf01594` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.generated.phase241.4f5bf72ba0` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.generated.phase241.66ab54c1a0` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.generated.phase241.62aeeb3b13` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.generated.phase241.0b14f1f8f1` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts |
| `state.phase242.export-retention-accessibility` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.phase242.retention-reduced-motion` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts |
| `state.phase242.timeline-export-journey` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `control.phase242.export-status.refresh` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/export_status_live.ex |
| `control.phase242.retention.refresh` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live.ex |
| `control.phase242.retention.submit` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live.ex |
| `state.phase250.fonts-brand-boundaries` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.phase250.docs-paired-logo` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-brand-docs.spec.ts |
| `state.phase250.docs-favicon` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-brand-docs.spec.ts |
| `control.phase252.retention.preview-pending` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/retention_history_live.ex |
| `state.phase251.70d4151b61f3` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.phase251.f9d63f93b851` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.phase251.db46d583c8d9` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.phase251.7c109397825b` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts |
| `state.phase251.8e854774f122` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts |
| `control.phase251.8afd29426bfc` | control | S: current static/render contract; no standalone runtime claim | lib/threadline/operator_surface/live/row_history_component.ex |
| `state.phase251.0f0f0de6cb7f` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts |
| `state.phase251.a3bae73bd788` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.phase251.330cb3ba8b20` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.phase251.255a960ff0c3` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.phase251.b83a7acdcf97` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.phase252.retention-no-replay` | state | S: current static/render contract; no standalone runtime claim | examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts |
| `state.phase253.forced-colors` | state | S: current independent source ownership; full executed semantic/browser acceptance pending | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.phase253.served-headlines` | state | S: current independent source ownership; full executed semantic/browser acceptance pending | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts |
| `state.phase253.host-containment` | state | S: current independent source ownership; full executed semantic/browser acceptance pending | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts |

## Semantic declarations and voting status

Required rows remain pending the actual candidate CI run, rather than inheriting a green result from an old source, a list operation or a different project. Nonvoting rows keep their original reason; an intentional unsupported-project skip is not success.

| Project | Existing declaration | Voting | Current disposition |
| --- | --- | --- | --- |
| desktop-chromium | `operator-timeline-investigation-flow.spec.ts` — Timeline investigation flow browser proof > starts at Home, applies a Timeline query, and opens its transaction | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-timeline-investigation-flow.spec.ts` — Timeline investigation flow browser proof > starts at Home, applies a Timeline query, and opens its transaction | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — actor and correlation pivots re-enter Timeline with only their supported filters | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — actor and correlation pivots re-enter Timeline with only their supported filters | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — saved searches keep canonical sharing, long summaries, and destructive actions reachable | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — saved searches keep canonical sharing, long summaries, and destructive actions reachable | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — Evidence keeps selected subject/reference through latest and proof-history navigation | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — Evidence keeps selected subject/reference through latest and proof-history navigation | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-coverage-readiness.spec.ts` — Coverage readiness link behavior > keeps public covered-row Timeline links scoped by table without table_schema | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-coverage-readiness.spec.ts` — Coverage readiness link behavior > keeps public covered-row Timeline links scoped by table without table_schema | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — Redaction policy comparison stays safe, keyboard-operable, and responsive | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — Redaction policy comparison stays safe, keyboard-operable, and responsive | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — Redaction inspection distinguishes a missing empty-policy trigger from unreadable deployment | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — Redaction inspection distinguishes a missing empty-policy trigger from unreadable deployment | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — Timeline export reaches protected download and returns to its committed search | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — Timeline export reaches protected download and returns to its committed search | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — Exports seeded pending, failed, completed, unavailable and invalid context stay distinct | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — Exports seeded pending, failed, completed, unavailable and invalid context stay distinct | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — Retention confirmation focus and cancel preserve state; Chromium touch navigation works | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — Retention confirmation focus and cancel preserve state; Chromium touch navigation works | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — real host denial under Acme support is distinct from busy and disabled | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — real host denial under Acme support is distinct from busy and disabled | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-route-states.spec.ts` — offline Exports blocks pointer activation until fresh persisted state returns | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-route-states.spec.ts` — offline Exports blocks pointer activation until fresh persisted state returns | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-timeline-investigation-flow.spec.ts` — Timeline investigation flow browser proof > keeps keyboard-only filters, rows, pagination, drawer, and route transitions operable | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-timeline-investigation-flow.spec.ts` — Timeline investigation flow browser proof > keeps keyboard-only filters, rows, pagination, drawer, and route transitions operable | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-responsive-mobile-first.spec.ts` — operator responsive matrix: phone > keeps every operator route usable without root horizontal overflow | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-responsive-mobile-first.spec.ts` — operator responsive matrix: phone > keeps every operator route usable without root horizontal overflow | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-timeline-investigation-flow.spec.ts` — Timeline reduced-motion browser proof > keeps Timeline rows static with reduced motion | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| mobile-chromium | `operator-timeline-investigation-flow.spec.ts` — Timeline reduced-motion browser proof > keeps Timeline rows static with reduced motion | required | Passed in current exact-candidate required CI receipt; local contribution limits remain separate |
| desktop-chromium | `operator-zoom-proof.spec.ts` — inspection routes preserve exact scope and controls at verified real 200% tab zoom | required | Passed in current desktop actual2x CI; local navigation failure retained historically |
| mobile-chromium | `operator-zoom-proof.spec.ts` — inspection routes preserve exact scope and controls at verified real 200% tab zoom | nonvoting | Nonvoting: Mobile zoom limitation: browser limitation; mobile emulation cannot prove physical-device extension zoom or operating-system text scaling. |
| desktop-chromium-light | `operator-accessibility.spec.ts` — operator accessibility baseline > keeps System selection while served colors follow OS through investigation navigation | nonvoting | Nonvoting: Light/System is compiled and run through the local-only desktop-chromium-light lane, not the required dark voting projects. |
| route-capture | `operator-page-capture.spec.ts` — operator real-route deterministic capture > renders every curated operator route at 1280 | nonvoting | Nonvoting: Browser-full runs route-capture in a separate nonrequired workflow; it does not vote in ci-required. |

## Semantic surfaces and jobs

| Surface ID | Existing job | Renderer/source boundary | Current disposition |
| --- | --- | --- | --- |
| `route.home` | Investigate Acme ticket 4521 and follow its captured reply into row history | lib/threadline/operator_surface/live/start_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.timeline` | Investigate Acme ticket 4521 and follow its captured reply into row history | lib/threadline/operator_surface/live/timeline_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.transaction` | Investigate Acme ticket 4521 and follow its captured reply into row history | lib/threadline/operator_surface/live/transaction_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.row` | Investigate Acme ticket 4521 and follow its captured reply into row history | lib/threadline/operator_surface/live/row_history_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.drawer` | Investigate Acme ticket 4521 and follow its captured reply into row history | lib/threadline/operator_surface/live/transaction_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.actor` | Inspect one actor’s committed changes in a selected time window | lib/threadline/operator_surface/live/actor_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.coverage` | Check whether selected tables have audit capture and what to fix | lib/threadline/operator_surface/live/coverage_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.evidence` | Review a selected subject and reference, then follow its latest proof history | lib/threadline/operator_surface/live/evidence_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.exports` | Review export jobs, refresh status, download completed output, and return to its search | lib/threadline/operator_surface/live/export_status_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.redaction` | Compare configured redaction policy with deployed database behavior | lib/threadline/operator_surface/live/policy_redaction_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `route.retention` | Preview configured-store retention, deliberately confirm and inspect recorded outcomes | lib/threadline/operator_surface/live/retention_history_live.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `seam.exports.changes-csv` | Export CSV data or retrieve a completed CSV artifact | lib/threadline/operator_surface/controllers/export_controller.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `seam.exports.changes-json` | Export JSON data or retrieve a completed JSON artifact | lib/threadline/operator_surface/controllers/export_controller.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `seam.exports.changes-ndjson` | Export NDJSON data or retrieve a completed NDJSON artifact | lib/threadline/operator_surface/controllers/export_controller.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `seam.exports.download-job_id` | Export completed export artifact data or retrieve a completed completed export artifact artifact | lib/threadline/operator_surface/controllers/export_controller.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |
| `seam.theme` | Set the operator’s local light, dark, or system theme preference | lib/threadline/operator_surface/controllers/theme_controller.ex | Current source/inventory and fixture contract passes required CI; scoped mounted/pixel proof remains separate. |

## Scenario custody

| Scenario ID | Class | Existing job | Current disposition |
| --- | --- | --- | --- |
| `scenario.acme-4521-investigation` | ordinary | job.acme-4521-investigation | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.acme-4518-reply-close-delete` | ordinary | job.acme-4518-delete-investigation | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.globex-2001-ordinary-close` | ordinary | job.globex-2001-investigation | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.offboarded-co-retention-boundary` | boundary | job.offboarded-retention-boundary | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.state-empty` | stress | job.state-fixture-catalog | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.state-export-failed` | stress | job.exports-failed-state | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.state-permission-denied` | stress | job.state-fixture-catalog | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.state-pagination-boundary` | stress | job.state-fixture-catalog | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.state-long-content` | stress | job.state-fixture-catalog | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.state-unicode` | stress | job.state-fixture-catalog | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |
| `scenario.state-duplicate-labels` | stress | job.state-fixture-catalog | Existing deterministic scenario identity retained; ordinary and stress remain separate. No reset or invented seed/capture custody is claimed. |

## Resource dispositions

| Existing identity | Current disposition |
| --- | --- |
| `resource.shared-assets` | Existing source ownership retained. Approved current brand/runtime/ten-asset package boundaries are assessed in the package record; the inventory’s historical migration prose is not current behavioral acceptance. |
| `resource.embedded-fonts` | Existing source ownership retained. Approved current brand/runtime/ten-asset package boundaries are assessed in the package record; the inventory’s historical migration prose is not current behavioral acceptance. |
| `resource.storybook` | Existing source ownership retained. Approved current brand/runtime/ten-asset package boundaries are assessed in the package record; the inventory’s historical migration prose is not current behavioral acceptance. |
| `resource.help-desk-writes` | Existing source ownership retained. Approved current brand/runtime/ten-asset package boundaries are assessed in the package record; the inventory’s historical migration prose is not current behavioral acceptance. |
| `resource.mailbox-preview` | Existing source ownership retained. Approved current brand/runtime/ten-asset package boundaries are assessed in the package record; the inventory’s historical migration prose is not current behavioral acceptance. |

## Carried dispositions

| Existing identity | Current disposition |
| --- | --- |
| `seed008.drawer-title-overlap` | Current transaction-origin history images and accepted251 source are available; independent visual review pending. No automatic closure from an image count. |
| `seed008.dense-typography` | Current page-title and compact-preview rendered roles/bytes pass; current paired images await independent judgment. |
| `seed008.redaction-empty-copy` | Accepted251 boundary is unchanged; current static/render and Light inspection contributions are distinct from fresh required-CI empty/error journeys. |
| `seed008.screenshot-provenance` | Historical snapshot failures/local-only guard baselines retained. Six current changed comparisons and explicit preservation/after-only limits await independent review; no blind PNG regeneration or retired paid critic. |
| `seed008.degraded-timeline` | Existing extra evidence state retained, not counted as a new route or a new current capture. |
| `adm06.descriptorless-intent` | Unresolved flagged-unverified, non-authoritative engine annotation preserved. No fabricated descriptor, green enforcement result or risk acceptance. |
| `proof-scope.local-only` | Scope-limited local proof only; required CI and REL-01 natural release evidence remain pending. |

## Acceptance limits

The28 UI and16 surfaced edge rows remain mapped by [the probe record](253-PROBE-RECORD.md). Descriptorless/unclassified engine annotations retain their exact non-authoritative limits; they are distinct from the actual missing zoom/required-CI proof. No human UAT, native clipboard observation, full-root repeat, foreground use, hosted execution, merge, version bump or publication is inferred. Local package and independent review results are appended by their owners; this reconciliation is not a substitute for them.


## Closing current-source disposition and artifact loss

Current code review closes its three original findings; security reports24/24 source mitigations,0open/noacceptedrisk; UI20/24 retains real200%zoom as blocking. Current recovery gates and limits are in [package readiness](253-PACKAGE-READINESS.md), [review disposition](253-REVIEW-DISPOSITION.md) and [sampling](253-SAMPLING.md). Original private raw proofs were removed by restart; their actual independent observations remain historical and are not a claim of present raw-file custody. Three new after-only table images and equal five-table row hashes use a different explicitly identified fixture. Final verification must assess this custody limitation separately from missing real zoom/exactCI; no row is auto-promoted from metadata or fresh image counts. All required semantic CI rows remain pending their exact candidate run.


### Current new-packet remedy

Initial final verification preserved an actual ADM31raw-custody gap. Parent completed its prescribed seven NEW retained-source before/final pairs (14PNGs) and three after-only states on the same identified fixture without reset/source change. Same UI reviewer actually viewed17images, verified60sealed/876archived files, confirmed current custody and retained20/24/real2xblocker. The original pixels remain lost; real clocks differ; no restoration/original pre-edit-order/2x claim is made. Four bracketing five-table full-row hash/count objects match. Both replay apps and ownedPGstopped0; immutable seal excludes mutablePG/build files. Current served-doc link count is43/0missing. Same-verifier changed-evidence/normal-record refresh is next, not another source/security audit or broad suite. ExactCI/REL01 remain pending.


Current same-verifier result: the prescribed local paired-custody gap is **closed**. Six of nine requirements are locally satisfied; roadmap remains3/5 because real2x/exactcandidateCI are still required and unproven. No further local repair/source gap remains from this assessment. FutureREL01stays separate. Original loss/verdict/history remain preserved; this closes current custody with new controlled evidence, not restored original pixels. Parent completes only normal closeout record hashing, then the maintainer decides on the concrete review-branch/PR/requiredCI action. No human UAT or new local audit/repeat is requested.
