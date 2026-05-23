---
phase: 76
slug: batched-retention-and-ui
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
updated: 2026-05-23T14:26:00Z
---

# Phase 76 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 76 is validated on the repaired final tree after Phase 81 closed the missing supervision gap. The primary risk is evidence drift back to the historical unsupervised story instead of the current application-owned runtime path.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit runtime tests plus code-surface grep verification |
| **Config file** | `mix.exs`; `config/config.exs`; `config/test.exs`; `lib/threadline/application.ex`; `lib/threadline/retention.ex`; `lib/threadline/retention/pruner.ex`; `lib/threadline/operator_surface/live/retention_history_live.ex` |
| **Quick run command** | `mix test test/threadline/retention/pruner_test.exs test/threadline/retention_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~10-20 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- Re-run the repaired retention trio after any change to `Threadline.Application`, `Threadline.Retention.Pruner`, or `RetentionHistoryLive`.
- Re-run the grep proof whenever milestone evidence files are repaired so the active artifacts continue to point at the supervised runtime path.
- Defer full-suite proof to later milestone-closeout work instead of duplicating broad closure claims here.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 76-01-01 | 01 | 1 | RET-01 | T-81-01 | `Threadline.Application` starts the named retention pruner on the built-in OTP path when retention is enabled and a repo is configured. | code-surface + targeted unit | `rg -n 'mod: \{Threadline.Application|Threadline.Retention.Pruner|interval_ms|sleep_ms' mix.exs lib/threadline/application.ex lib/threadline/retention/pruner.ex && mix test test/threadline/retention/pruner_test.exs --max-failures 1` | ✅ | ✅ green |
| 76-01-02 | 01 | 1 | RET-02 | T-81-03 | `Threadline.Retention.purge/1` records completed `threadline_retention_runs` metadata on real purge execution. | targeted unit | `mix test test/threadline/retention_test.exs --max-failures 1` | ✅ | ✅ green |
| 76-02-01 | 02 | 2 | RET-03 | T-81-02 | The Retention History page monitors and triggers the same named supervised pruner runtime used by scheduled pruning. | targeted liveview | `rg -n 'Pruner.trigger|Run Pruning Batch|Retention History' lib/threadline/operator_surface/live/retention_history_live.ex test/threadline/operator_surface/live/retention_history_live_test.exs && mix test test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/76-batched-retention-and-ui/76-01-PLAN.md`
- [x] `.planning/phases/76-batched-retention-and-ui/76-02-PLAN.md`
- [x] `.planning/phases/76-batched-retention-and-ui/76-01-SUMMARY.md`
- [x] `.planning/phases/76-batched-retention-and-ui/76-02-SUMMARY.md`
- [x] `.planning/phases/76-batched-retention-and-ui/76-VERIFICATION.md`
- [x] `.planning/phases/76-batched-retention-and-ui/76-VALIDATION.md`

Wave 0 is complete. Phase 76 now has a full current-tree evidence chain for the repaired supervised retention runtime.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that the repaired evidence does not fall back to the old unsupervised-runtime story | RET-01, RET-03 | The highest-risk failure mode is wording drift in milestone artifacts rather than broken unit logic | Read `76-VERIFICATION.md` and confirm it names `Threadline.Application`, `Threadline.Retention.Pruner.trigger/0`, and the Retention History LiveView as the active runtime path. |

---

## Validation Sign-Off

- [x] Phase 76 has explicit automated coverage for startup, run tracking, and LiveView trigger behavior on the repaired runtime path.
- [x] The active evidence references the current tree instead of relying on historical summary prose.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-23 after Phase 81 proved the built-in supervised retention runtime and rewrote the closeout artifacts around that repaired truth.
