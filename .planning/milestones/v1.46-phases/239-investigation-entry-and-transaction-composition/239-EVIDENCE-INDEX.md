# Phase 239 Plan 07 Evidence Index

## Candidate custody

- Retained worktree: `.claude/worktrees/v146-operator-preview`.
- Branch: `worktree-agent-v146-operator-preview`.
- Immutable base: `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`.
- Accepted Phase 238 head: `43c5bcfa960b1a10cb07ef997e2231e9615dca6f`.
- Accepted Phase 238 receipt SHA-256: `1eaa28ead2105993d73e77364166600033e0940cf345e5b1776eb5ee5823ae99`.
- Accepted Phase 238 evidence-index SHA-256: `388700a3de3db3206fdf8fe5bdfc7dc316e8e83e59ed49150094e9e898789d47`.
- Final candidate: `b97f0ab9523de8669e53310adc757f393cbbfd36`.
- Final candidate diff digest: bound by the local forward receipt below.
- Ordered Phase 239 task commits: 49.
- Local forward receipt SHA-256: `f613da56ae3c839cdc4675106c445f44adecba066b5385f627f537f90357d61e`.
- Receipt validation: `tsx examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts --validate-239-receipt .planning/phases/239-investigation-entry-and-transaction-composition/239-CANDIDATE-RECEIPT.json` → `239 forward receipt verified`.

The machine-specific receipt binds the accepted Phase 238 receipt/index, approved planning context, first-parent candidate commits, and current source digest. Evidence captures below all bind this receipt SHA. The receipt remains local. Accepted Phase 238 evidence is unchanged.

## Final receipt-bound captures

Artifacts are local and ignored under `examples/threadline_phoenix/e2e/artifacts/operator-evidence/`. Every manifest binds candidate `b97f0ab9`, receipt SHA `f613da56…57d61e`, Playwright 1.60.0, Chromium 148.0.7778.96, and the synthetic `threadline-demo-seed` fixture. Run records use unique loopback ports and fresh derived test databases.

| Lane | Partition / directory | Result | Output coverage |
|---|---|---|---|
| Authenticated route matrix | `operator_239routes_b97f0ab9final` | `route-capture`, 3/3 passed | Home, filtered Timeline and Transaction at 1280/768/375 CSS px; 4 manifests and 36 unique contained outputs. |
| State matrix | `operator_239states_b97f0ab9final` | `desktop-chromium`, 12/12 passed | 12 manifests and 63 outputs covering theme/motion, copy success/denial, seeded exports, pending/empty, focus return, offline/reconnect, touch navigation, and host denial. |
| System/light | `operator_239light_b97f0ab9final` | `desktop-chromium-light`, 1/1 passed | 1 manifest and 12 outputs for saved preference and effective System/light appearance. |

Exact commands:

```sh
MIX_TEST_PARTITION=operator_239routes_b97f0ab9final THREADLINE_E2E_EVIDENCE=1 THREADLINE_E2E_FORWARD_RECEIPT="$PWD/.planning/phases/239-investigation-entry-and-transaction-composition/239-CANDIDATE-RECEIPT.json" E2E_HOST=127.0.0.1 PORT=4273 DB_HOST=127.0.0.1 mix verify.example_browser --project=route-capture operator-page-capture.spec.ts --grep='route\.(home|timeline|transaction)'
MIX_TEST_PARTITION=operator_239states_b97f0ab9final THREADLINE_E2E_EVIDENCE=1 THREADLINE_E2E_FORWARD_RECEIPT="$PWD/.planning/phases/239-investigation-entry-and-transaction-composition/239-CANDIDATE-RECEIPT.json" E2E_HOST=127.0.0.1 PORT=4274 DB_HOST=127.0.0.1 mix verify.example_browser --project=desktop-chromium operator-route-states.spec.ts
MIX_TEST_PARTITION=operator_239light_b97f0ab9final THREADLINE_E2E_EVIDENCE=1 THREADLINE_E2E_FORWARD_RECEIPT="$PWD/.planning/phases/239-investigation-entry-and-transaction-composition/239-CANDIDATE-RECEIPT.json" E2E_HOST=127.0.0.1 PORT=4275 DB_HOST=127.0.0.1 mix verify.example_browser_light --project=desktop-chromium-light operator-route-states.spec.ts --grep=theme
```

## Integrity and zoom

The local integrity helper `/private/tmp/threadline-239-evidence-check-b97f.ts` verified all three bundles against the current candidate and receipt. All 17 manifest files serialized canonically and matched candidate ancestry, changed-path/mode/byte digests and the receipt SHA. It checked 147 manifest capture references across 111 unique bundle-scoped outputs, 588 served asset references, contained output paths, output SHA-256 values, served/local CSS and JS SHA-256 equality, and synthetic redaction-canary absence. Every check passed.

The final-candidate dedicated zoom command was `MIX_TEST_PARTITION=1791590058 THREADLINE_ZOOM_ACCEPT=1 E2E_HOST=127.0.0.1 PORT=4278 DB_HOST=127.0.0.1 mix verify.example_browser --project=desktop-chromium operator-zoom-proof.spec.ts` → 1/1 passed. Chromium set and read back tab zoom `2.0` on the same tab; CSS viewport measured 640×450, with zero horizontal overflow on Home, Timeline and Transaction. Primary controls, the exact-value disclosure and row-history link remained visible and reachable. This is actual tab zoom, not CSS/DPR/viewport scaling.

## CI and focused checks

The final candidate `mix ci.all` command and results are recorded in `239-VALIDATION.md`. It exited 0. Playwright discovered 428 cases: 357 passed, 69 intentionally skipped and two first-attempt failures recovered on retry. The desktop group-catalog test and mobile Transaction-to-row-history test each passed 1/1 in separate fresh isolated reruns. The full gate also passed 3,089 root ExUnit tests (0 failures, 3 excluded), 132 Phoenix example tests (0 failures), Dialyzer (0 errors), the live-Dialyzer slice (17 passed, 16 excluded), 21 E2E Node tests, formatting, Credo, dependency audit, repository hygiene and cycle checks. The separate E2E TypeScript typecheck passed.

## Review and remaining scope

`239-REVIEW.md` records the final code review (0 blockers, 3 warnings); `239-SECURITY.md` records the final threat audit; `239-UI-REVIEW.md` records the rendered review. The UI review retains the approved 17/24 score and keeps eight of thirteen edge rows explicitly unclassified; adjacent rendered evidence does not turn them into passes. Remaining warnings are recoverable database failure handling for Timeline pagination and transaction row-history, plus a localhost-origin mismatch in the zoom helper. They are non-blocking for Phase 239's owned acceptance criteria and remain visible for follow-up.

No credentials, customer data, DOM HTML or response headers were saved. Raw evidence bundles remain local and ignored.
