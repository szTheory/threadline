# Second natural CI: masked browser premises

[Second run](https://github.com/szTheory/threadline/actions/runs/43526588143) at `7d3c3712bfe481511abe141aaac9aabc2ffa06f1`: all13 non-browser jobs succeed, including current root/example, minimum/latest, compiler, Dialyzer, consumer and next-minor rehearsal. Both browser legs hit the unchanged five-failure cap: desktop190 passes/six skips, mobile185 passes/11 skips. Configured retries remain visible; skips still require row-level disposition before acceptance. Browser receipt skipped and aggregate failed. Dedicated real2x proof remains unaccepted.

## Attributed correction

The first browser repair exposed later stale premises: Timeline facts expected two tracks from viewport768/1024 despite the independently reviewed ≤812px available-container rule, and Home expected obsolete32px instead of approved28px. A bounded forward review found another masked premise: compact copy labels use12px while full text actions retain their existing readable sizing.

Two test files change only their assertions. Timeline independently measures the intended named container's content width, requires the correct name/positive width and facts containment, applies the fixed812px threshold, and retains mobile hiding/wide2–3tracks, first-result visibility/action hit tests/focus/overflow. Home expects28px. Only actual `.tl-copy` label controls expect12px; all compact controls still need width/height≥40px and other action/axis text retains≥14px. No production CSS/Elixir/handler/authorization, clipboard behavior, paired capture custody, retry, timeout, skip or resource-limit change.

## Independent dispositions

Frozen `ci-fix2-review-input-02.json` binds exactly two spec hashes against the prior candidate; packet01 is preserved. Typed code reviewer: clean, no critical/warning/info/necessity findings; independent named-container measurement is not tautological. Same security reviewer: SECURED, all24 original mitigations retained, zero open/no accepted risks. Same UI reviewer: both hashes match; bounded forward scan found no further stale headline/theme/reference/Outcome/viewport-only premises tied to these changes; no new pixels warranted by test-only delta. All were read-only and launched no tests/services/network. These are source judgments, not hosted-browser success.

Playwright declaration listing parses both files successfully (`ci-browser-repair2-list-01.json`). Original second-run logs and browser diagnostic/timing ZIPs are retained privately under `.planning/tmp/253-recovery/`, with matching GitHub artifact digests. No local app/database was restarted or local full/default browser/root/realzoom/native-clipboard stop renewed. The next proof is ordinary required CI on the repaired candidate; parent continues, no user action needed.
