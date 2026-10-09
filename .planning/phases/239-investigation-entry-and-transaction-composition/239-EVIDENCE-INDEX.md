# Phase 239 Plan 07 Evidence Index

## Custody chain

- Retained worktree: `.claude/worktrees/v146-operator-preview` (local checkout path recorded in the handoff)
- Branch: `worktree-agent-v146-operator-preview`
- Immutable base: `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`
- Accepted Phase 238 head: `43c5bcfa960b1a10cb07ef997e2231e9615dca6f`
- Accepted Phase 238 receipt SHA-256: `1eaa28ead2105993d73e77364166600033e0940cf345e5b1776eb5ee5823ae99`
- Accepted Phase 238 evidence-index SHA-256: `388700a3de3db3206fdf8fe5bdfc7dc316e8e83e59ed49150094e9e898789d47`
- Forward candidate head: `04f77cadb7feb44a0f294d29fbb3207ef65b387d`
- Candidate source-change digest: `ed2a5e04d5d48c31fbf66f1c32e1f636ce4ea92756d5fbd994ae2b8bf1407709`
- Local candidate receipt SHA-256: `efe7c49c51809628fab96cdcbe51e550a9aa6dd7321884c6966912db1c3b01d3`
- Candidate receipt validation: `tsx ...operator-evidence-manifest.ts --validate-239-receipt ...239-CANDIDATE-RECEIPT.json` → `239 forward receipt verified`.
- The forward receipt records the explicit ordered Phase 239 task commits after the accepted head, the six approved planning-context hashes, relevant source paths/modes/bytes, and the parent receipt/index/manifest hashes. It remains machine-specific and local; it is not committed.
- The accepted 238 receipt and index hashes were rechecked after capture and remain byte-identical.

## Source-bound browser bundles

All listed bundles are ignored/local under `examples/threadline_phoenix/e2e/artifacts/operator-evidence/`. Each `run.json` records evidence mode, base, candidate head, unique short partition, derived test database, host and port. Each route manifest records the exact browser, fixture/route identity, output SHA-256 values and served/local assets.

| Bundle | Actual browser result | Bundle / manifest SHA-256 |
| --- | --- | --- |
| `operator_239trace_1791573389_7971` | Authenticated direct Home capture; 1/1 route test. This first Task 1 snapshot predates the final test-only commit and is historical; the final Home is in the matrix below. | bundle `3256ee73a983b9fa292bd3a05d6011b838e976aa605fcf486b37e1bb7359c5f4`; Home manifest `2f2464b620907287d9f7e874ce98d4604e60e0d41c97abec60c327b452126fae` |
| `operator_239finalr_1791575600_4` | Current authenticated Home, filtered Timeline and Transaction; 3/3 route tests. Dark theme; 1280, 768 and 375 CSS-pixel widths. Current receipt hash is present in each manifest's custody block. | bundle manifest `06dcc7b6d8165a8d0b49e4ddb51eea9c48a121b6ee15dd92a867a2d20318783f`; Home `9bf03fba0bc90fd29c718be6f12043ec8cd8edddadb22b86cb31cefd2923e790`; Timeline `1602059a56d483c739d6a02ca7ebfc1b8ef0d324418055fc83704b3dc48b1792`; Transaction `f3e057d7591b413d0739811d528ebda4a4aba770143f99951eec2321e9570a59` |
| `operator_239fins_1791575700_5` | Current evidence-state run; 12/12 tests passed: theme/reduced motion, pending and empty Timeline, fresh-entry Copy observations, seeded export statuses, real HTTP 403, offline pointer/keyboard, reconnect, focus return and Chromium touch navigation. | theme manifest `906eaea3861fae1515fb46b4ff6d5a08830c87cdd1d992f8bd09859eb373c33a`; individual output hashes are in the raw manifests |
| `operator_239finl_1791575800_6` | Current System preference under actual light OS appearance; 1/1 browser test. `preference=system`, `effectiveTheme=light`, background `rgb(247, 249, 252)`, CSS/document width 1280. | theme manifest `1a32b18b24990259ef24905a7e631a90e63602573bc6df381d038d00e398ae3f` |

Each route manifest contains 12 captures (shell/content/observation/scorecard across 3 widths). The current full-shell PNGs were visually compared with the accepted Phase 238 Home and Transaction images. Home entry points and hierarchy remain visible; Timeline filters/results and transaction identity, actor, action, request/correlation context, change rows and redacted values are present. The regenerated mobile Transaction shell has no unexplained upper gutter. Content-only locator screenshots on tall pages crop the top of some content; full-shell PNGs, not those crops, were used for visual review.

The exact per-output hashes, conditions, assets and observations are in the raw manifests. A read-only integrity pass checked all 111 manifest-referenced capture records across the current route, state and light bundles: every output byte hash matched and each served CSS/JS hash matched its local asset hash. Each capture ran on its own fresh database with loopback host and unique output path.

## Genuine browser zoom

`THREADLINE_ZOOM_ACCEPT=1` ran `operator-zoom-proof.spec.ts` in isolated Chromium; 1/1 passed. The browser extension reported genuine tab `zoomFactor=2` on Home, Timeline and Transaction. The browser viewport was 1280×900 physical pixels; page CSS viewport was 640×450, DPR was independently 2, document width equaled client width at 640 on every route, and overflow was zero. Home lookup controls, Timeline filters/theme controls and Transaction native full-value disclosure/row-history controls were keyboard- and pointer-reachable. This is actual tab zoom, not a CSS, viewport or DPR substitute.

## Test and runtime evidence

- `operator-evidence-manifest.test.ts`: 21/21 passed with nonzero discovery, including forged accepted-parent/head/index/context/source, extra/out-of-order task commit, changed served asset/output and unsafe DB/host controls.
- `operator-page-capture.spec.ts --grep 'route\\.(home|timeline|transaction)'`: 3/3 passed.
- `operator-route-states.spec.ts` in the current receipt-bound evidence run: 12/12 passed. A separate ordinary browser run discovered 47 tests: 38 passed and 9 were evidence-only tests skipped by non-evidence mode; these 9 ran in the current evidence run.
- Light/System theme lane: 1/1 passed.
- Actual zoom lane: 1/1 passed.
- `mix ci.all` under `/opt/homebrew/bin/bash` with `MIX_TEST_PARTITION=tl239_1791575000`: exit 10 at `mix credo --strict`; it found 3 refactoring opportunities and 2 software-design suggestions in unchanged `test/threadline/operator_surface/operator_evidence_contract_test.exs`, last changed in Phase 238. It did not reach ExUnit.
- To establish test discovery after that early exit, `mix verify.test` ran on `MIX_TEST_PARTITION=tl239_1791575100`: 3,087 tests, 36 failures, 3 exclusions. Failing groups included rendered CSS byte locks after the intentional Phase 239-05 token fix, inventory/source-anchor assertions, repo-hygiene Bash array handling and unrelated property/rendered-output contracts. No full-suite pass is claimed.

The CSS byte-lock failure is specifically due to Phase 239-05 changing two invalid self-referential custom-property declarations to concrete values while the committed golden fixture and pins still describe the prior CSS. Updating that tracked golden was proposed as the in-scope correction, but the automatic approval reviewer rejected the write because it could mask pre-existing failures and was outside 239-07. No workaround or retry was attempted. This is a remaining final-gate blocker.

## Scope and limits

- No browser tests had zero discovery. No ExUnit test file was added, so partition-weight files did not need changes.
- Authenticated browser evidence uses seeded synthetic data and allowlisted observations. No credentials, page HTML, response bodies or real operator data are stored in the capture bundles.
- Fresh-entry Copy did not complete on Evidence, Exports and Retention; Timeline copy had a separate positive control. Clipboard permission denial itself was unavailable in this Chromium context, so no denial-feedback claim is made. Copy reliability belongs to later Phase 242.
- The offline queue activation observation found the Exports control remains enabled while disconnected; the run observed no added jobs after reconnect. Mutation affordance hardening belongs to later phases.
- Eight edge rows remain explicitly unclassified. No requirement or UC is marked passed based only on a text field or an unexecuted plan.
- Full report, including all 35 UC dispositions and all 10 plan requirement outcomes: `239-REVIEW.md`.
