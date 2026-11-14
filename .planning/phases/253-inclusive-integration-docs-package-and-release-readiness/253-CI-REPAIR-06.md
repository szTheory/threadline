# Sixth natural CI: alert text owner isolated and corrected

[Sixth run](https://github.com/szTheory/threadline/actions/runs/43539542006) at `291b1592904a5f2f0d6c7c32f8a65fe6e28c1a99` passes all13 non-browser gates and mobile. Desktop still fails the one long-filter case; receipt skips and required aggregate fails. Both real2x journeys execute successfully and ordinary output now explicitly proves `acceptMode:true`. The executed failed report and failure archive are retained.

## Actual cause and bounded remedy

Linux root scrollWidth1358 exceeds viewport1280 with fonts loaded. All form controls and element rectangles fit, but warning text can escape its own contained element. The initial inference that overflow must be outside main was wrong; actual screenshots identify the Table filter warning inside main. Its existing wrapping properties applied only below768px.

Promote `min-width:0` and `overflow-wrap:anywhere` to the base `.tl-alert`, removing the mobile duplicate. No clipping, ellipsis, tolerance increase, data truncation or new dependency is used. Golden CSS, both byte pins, fixture rationale and the owning contract migrate together.

The original test now uses the same226-character identifier with wider m glyphs, preserving identifier validity while removing dependence on platform glyph width. A fixed24-hour fixture window makes the matched pair deterministic. It asserts the full warning, its scroll/client bounds and text Range containment at desktop and375px, preserving strict shell/control checks. Existing success/failure screenshot transport embeds the image in the executed report.

## Actual RED, GREEN and limits

The real unmodified-before CSS fails locally: page2566 at viewport1280, alertclient966/scroll2285, textRange right2565.8. The final CSS passes four selected original route cases across desktop/mobile first attempts with retries0, no skips/flakes; page1280, alert966/966, textRange contained and full403-character warning retained. Actual before/final PNGs show wrapped full text and the resulting extra line of natural height. All five full-row logical table hash/count maps match across five snapshots on the same owned database. The example dependency was actually rebuilt before serving final CSS, and the launch receipt binds the dirty runtime hashes explicitly. This is a new bounded pair, not restoration of lost original evidence.

Retain failed setup attempts: initial scoped browser launch was denied the macOS bootstrap port by the sandbox before browser startup; the explicitly escalated background launch succeeds. Two style-contract attempts retained obsolete mobile ownership or incorrectly sliced before the first media rule; the corrected owner reads the actual unconditionally applied feedback shard. Final91 style/byte/size checks, named format and strict Credo pass. No full-root/default browser/localrealzoom/native clipboard/foreground attempt is renewed. Only owned app and isolated database stop, both cleanly; shared services and original paired fixture remain untouched.

`ci-fix6-review-input-01.json` freezes seven source paths, actual RED/GREEN, fixture maps and image paths. Independent code review is clean with zero findings, confirms every bound hash and the actual bounded pair, and distinguishes wide m from original Linux t. Independent security review confirms every bound hash,24/24 mitigations, zero open/no accepted risks. Independent UI reviewer views all three new PNGs, matches all seven source hashes and closes F09 for this bounded correction; score20/24 is unchanged. Required exact-candidate Linux CI and phase/milestone acceptance remain pending. Parent continues the authorized review/push/CI cycle; no user action is needed. Merge/tag/version/publish/risk authority remains excluded.
