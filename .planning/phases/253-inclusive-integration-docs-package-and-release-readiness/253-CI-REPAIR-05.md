# Fifth natural CI: real zoom complete, failure data transport corrected

[Fifth run](https://github.com/szTheory/threadline/actions/runs/43535007690) at `02204881bc294d0b5d99e71aea234d2f0393b871`: all13 non-browser gates and mobile browser pass. Desktop224 passes/29 skips/one long-filter containment failure; mobile217 passes/37 skips. Receipt skips and required aggregate fails. The original failure remains unresolved, not waived.

## Executed zoom evidence

Both dedicated ordinary and inspection declarations complete. Raw `THREADLINE_ZOOM_OBSERVATION` and `THREADLINE_INSPECTION_ZOOM_OBSERVATION` exactly match retained `ci5-real-zoom-observations.json`: three ordinary plus seven inspection checkpoints use actual same-tab factor2, reduced640px CSS viewport, zero whole-page overflow and observed reachable/focused controls. Ordinary filter overlay opens/dismisses/returns focus. Independent UI review resolves F01 from these actual values, keeps score20/24 and opens F09 for the separate Linux long-filter failure. No nativeMac clipboard or local zoom retry is inferred.

The prior ordinary `acceptMode` flag was not proven enabled. Actual observations satisfy its predicates, but future CI must enforce them. The existing Playwright step now sets `THREADLINE_ZOOM_ACCEPT: "1"`; result output includes `acceptMode`. The branch changes assertions only, not interactions. Next hosted output must showtrue; old data does not prove mode enforcement.

## Failure transport defect

Body-only test attachments existed in the executed JSON, but that artifact uploaded only after success. Failed-run diagnostics contained neither JSON nor PNG for this trace-disabled case. The previous readiness hypothesis did not resolve the failure, and its supposed numeric transport was not observable. Parent missed this boundary before that push.

Existing executed-report upload now uses `${{ !cancelled() }}` to retain partial reports after failure without extending cancellation. GitHub's [status-function reference](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions#status-check-functions) documents the defaultsuccess condition and this recommended noncancelled override. Missing reports still error, both browser legs still vote and failed legs still block receipt/aggregate. No new job/action/permission/retention/dependency or accepted-failure rule.

The case synchronously writes geometry JSON, emits one structured log record and uses an explicit outputPath PNG before the unchanged strict assertion. Path attachments preserve those files in the existing failure archive. The output is geometry/style metadata plus the same synthetic fixture screenshot, not real-user data.

## Actual verification

An explicitly marked private source copy forces only `shellFits:false`, after the same measured browser flow. It exits1 and leaves a structured log, primary JSON/PNG and attachment copies. This proves transport, not the original Linux bug. Original four named route cases then pass first-attempt at default zoom with controlled clipboard/retries0. The existing89 CI topology/parity checks pass again after the new flag; zoom declaration listing parses;19 existing executed-report/negative controls pass, including malformed/skipped/untrusted report rejection. No full/default/localrealzoom/native/foreground stop is renewed. Owned app/PG stopped0.

`ci-fix5-review-input-03.json` binds the three source hashes, actual post-change workflow receipt and marked fault transport. Packet01/02 remain historical;03 corrects only the receipt pointer after the flag edit. Independent code/security/UI reviewers confirm hashes, persistence, unchanged strict/failed-job predicates and assertion-only mode. Security retains24/24, zero open/no accepted risks. Code review's mistaken directory-absence search was corrected using the preserved exact absolute path; both original/injected hashes and limited transformation independently match, with no recreation.

Parent next: push this reviewed observability/enforcement candidate for the existing Linux run; inspect real failing bounds and solve F09. No production layout remedy or phase/milestone acceptance is claimed. No user action is needed while this authorized work continues; merge/publication/version/tag/risk authority remains excluded.
