# Phase 243 exact-candidate evidence index

## Recommendation

**Release-ready for Phase 243 scope on exact candidate `2f7560e97778d914a7639cbae308bb66fb7c528f`.** Local verification, fresh route evidence, the guarded preview, and successful live required CI all bind to this candidate. Run `38158769462` completed successfully with all 16 jobs successful; both `ci-required` and `verify-example-browser` passed, and the uploaded browser receipt reconciles all 31 expected journeys with discovery and execution. DR-243-01 remains a disclosed medium visual-clarity carry-forward; the limitations below bound what this evidence establishes.

## Candidate identity and local verification

| Item | Evidence |
|---|---|
| Candidate HEAD / branch | `2f7560e97778d914a7639cbae308bb66fb7c528f` / `agent-241-01` |
| Candidate commit | `fix: remove unreachable surface header clause`; removes the fallback Elixir 1.20.4 flagged as unreachable under `--warnings-as-errors`. Its parent `f2c2705` adds locked Node/npm setup before the browser evidence ExUnit contract. The machine-readable receipt covers 81 candidate paths and per-path identities. |
| Candidate diff digest | `ed3fb5bdb56e1ac12cfeb5ef26ed713e2532cfc5530d487513523053398c0238` |
| Candidate receipt | `.planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json`; SHA-256 `4950eea98e92468408b95cf4ce504c3a9386d2799bbc72c62b41838757c1f503` |
| Synthetic fixture | `threadline-demo-seed` / `seed-pipeline-v1`; seed manifest `4a44105fca8d931f1c8ef1d420f13693f0e803b4efa05cfa6e87198a5fd1acea`; semantic ID `4305fd447ac36edf25b424f7909c08869569c6278d2b3807552cd50d82629a27` |
| Full local gate | Final-candidate `mix ci.all` passed: root ExUnit 3,129 tests / 0 failures / 3 exclusions; Phoenix example ExUnit 132 / 0; npm unit tests 21 / 21; Credo 69 checks over 454 files; dependency audit clean; Dialyzer 0 errors; hygiene and graph checks passed; browser suite 416 passed / 64 configured skips. |
| Exact-SHA required CI | Workflow `CI`, run `38158769462` ([run](https://github.com/szTheory/threadline/actions/runs/38158769462)), branch `agent-241-01`, head `2f7560e97778d914a7639cbae308bb66fb7c528f`, completed successfully. All 16 jobs succeeded; `CI required` job `114529879475` and `Example app browser E2E (2 projects)` / stable ID `verify-example-browser`, job `114527114926`, both succeeded. |
| Browser artifact and receipt | Artifact `operator-ci-evidence-38158769462` (ID `11708764393`), archive SHA-256 `ddd64cb1962add632a46b41632ebc4e217e68c83b1b2d0831784fa88176fadcb`; receipt `operator-ci-receipt-38158769462.json`, SHA-256 `777ab981f2068b692a2c42925ad037a18c49386057a84b6f2f60d9489f48a99d`. Exact-SHA counts: 31 expected / 31 discovered / 31 executed / 31 passed across `desktop-chromium` and `mobile-chromium`; every identity passed once with no retry or skip. |
| Focused safety contracts | Candidate-review, candidate-receipt, preview-receipt, and CI-evidence contracts: 22 passed, 1 optional live test skipped; E2E preflight: 7 / 7; live guarded preview lifecycle: 5 / 5. Fresh route capture: 12 passed, 1 legacy reference capture skipped. Formatting and scoped `git diff --check` passed. |

### UIV-01 required identities

Every row is in the repository inventory and was independently matched to the exact-SHA artifact receipt for run `38158769462`: native Playwright discovered and executed all 31 identities, each passed once without retry or skip on `2f7560e97778d914a7639cbae308bb66fb7c528f`. Inventory: `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`, SHA-256 `6411b927a4c8f9ddb19f50b5158c1d9b5edb3fa650f1acb1c3c564821945de0a`.

| # | Journey | Project | Exact file and full title path | Expected | Discovered | Executed |
|---:|---|---|---|---|---|---|
| 1 | Home to Timeline transaction investigation | `desktop-chromium` | `operator-timeline-investigation-flow.spec.ts` · Timeline investigation flow browser proof › starts at Home, applies a Timeline query, and opens its transaction | present | present | passed (1 attempt) |
| 2 | Home to Timeline transaction investigation | `mobile-chromium` | `operator-timeline-investigation-flow.spec.ts` · Timeline investigation flow browser proof › starts at Home, applies a Timeline query, and opens its transaction | present | present | passed (1 attempt) |
| 3 | Actor and correlation pivots re-enter a supported Timeline query | `desktop-chromium` | `operator-route-states.spec.ts` · actor and correlation pivots re-enter Timeline with only their supported filters | present | present | passed (1 attempt) |
| 4 | Actor and correlation pivots re-enter a supported Timeline query | `mobile-chromium` | `operator-route-states.spec.ts` · actor and correlation pivots re-enter Timeline with only their supported filters | present | present | passed (1 attempt) |
| 5 | Saved searches preserve canonical sharing and safe destructive actions | `desktop-chromium` | `operator-route-states.spec.ts` · saved searches keep canonical sharing, long summaries, and destructive actions reachable | present | present | passed (1 attempt) |
| 6 | Saved searches preserve canonical sharing and safe destructive actions | `mobile-chromium` | `operator-route-states.spec.ts` · saved searches keep canonical sharing, long summaries, and destructive actions reachable | present | present | passed (1 attempt) |
| 7 | Evidence subject and reference survive proof-history navigation | `desktop-chromium` | `operator-route-states.spec.ts` · Evidence keeps selected subject/reference through latest and proof-history navigation | present | present | passed (1 attempt) |
| 8 | Evidence subject and reference survive proof-history navigation | `mobile-chromium` | `operator-route-states.spec.ts` · Evidence keeps selected subject/reference through latest and proof-history navigation | present | present | passed (1 attempt) |
| 9 | Coverage table links remain scoped and schema recovery stays keyboard reachable | `desktop-chromium` | `operator-coverage-readiness.spec.ts` · Coverage readiness link behavior › keeps public covered-row Timeline links scoped by table without table_schema | present | present | passed (1 attempt) |
| 10 | Coverage table links remain scoped and schema recovery stays keyboard reachable | `mobile-chromium` | `operator-coverage-readiness.spec.ts` · Coverage readiness link behavior › keeps public covered-row Timeline links scoped by table without table_schema | present | present | passed (1 attempt) |
| 11 | Redaction inspection exposes drift and deployment limits safely | `desktop-chromium` | `operator-route-states.spec.ts` · Redaction policy comparison stays safe, keyboard-operable, and responsive | present | present | passed (1 attempt) |
| 12 | Redaction inspection exposes drift and deployment limits safely | `mobile-chromium` | `operator-route-states.spec.ts` · Redaction policy comparison stays safe, keyboard-operable, and responsive | present | present | passed (1 attempt) |
| 13 | Missing policy trigger and unreadable deployment remain distinct | `desktop-chromium` | `operator-route-states.spec.ts` · Redaction inspection distinguishes a missing empty-policy trigger from unreadable deployment | present | present | passed (1 attempt) |
| 14 | Missing policy trigger and unreadable deployment remain distinct | `mobile-chromium` | `operator-route-states.spec.ts` · Redaction inspection distinguishes a missing empty-policy trigger from unreadable deployment | present | present | passed (1 attempt) |
| 15 | Timeline export reaches its protected download and returns to the committed query | `desktop-chromium` | `operator-route-states.spec.ts` · Timeline export reaches protected download and returns to its committed search | present | present | passed (1 attempt) |
| 16 | Timeline export reaches its protected download and returns to the committed query | `mobile-chromium` | `operator-route-states.spec.ts` · Timeline export reaches protected download and returns to its committed search | present | present | passed (1 attempt) |
| 17 | Export pending, failed, completed, unavailable and invalid context states stay distinct | `desktop-chromium` | `operator-route-states.spec.ts` · Exports seeded pending, failed, completed, unavailable and invalid context stay distinct | present | present | passed (1 attempt) |
| 18 | Export pending, failed, completed, unavailable and invalid context states stay distinct | `mobile-chromium` | `operator-route-states.spec.ts` · Exports seeded pending, failed, completed, unavailable and invalid context stay distinct | present | present | passed (1 attempt) |
| 19 | Retention confirmation cancellation preserves state and touch navigation works | `desktop-chromium` | `operator-route-states.spec.ts` · Retention confirmation focus and cancel preserve state; Chromium touch navigation works | present | present | passed (1 attempt) |
| 20 | Retention confirmation cancellation preserves state and touch navigation works | `mobile-chromium` | `operator-route-states.spec.ts` · Retention confirmation focus and cancel preserve state; Chromium touch navigation works | present | present | passed (1 attempt) |
| 21 | Host denial remains distinct from busy and disabled retention states | `desktop-chromium` | `operator-route-states.spec.ts` · real host denial under Acme support is distinct from busy and disabled | present | present | passed (1 attempt) |
| 22 | Host denial remains distinct from busy and disabled retention states | `mobile-chromium` | `operator-route-states.spec.ts` · real host denial under Acme support is distinct from busy and disabled | present | present | passed (1 attempt) |
| 23 | Disconnected export controls wait for fresh persisted state before activation | `desktop-chromium` | `operator-route-states.spec.ts` · offline Exports blocks pointer activation until fresh persisted state returns | present | present | passed (1 attempt) |
| 24 | Disconnected export controls wait for fresh persisted state before activation | `mobile-chromium` | `operator-route-states.spec.ts` · offline Exports blocks pointer activation until fresh persisted state returns | present | present | passed (1 attempt) |
| 25 | Keyboard-only investigation filters, pagination, drawer and route transitions remain operable | `desktop-chromium` | `operator-timeline-investigation-flow.spec.ts` · Timeline investigation flow browser proof › keeps keyboard-only filters, rows, pagination, drawer, and route transitions operable | present | present | passed (1 attempt) |
| 26 | Keyboard-only investigation filters, pagination, drawer and route transitions remain operable | `mobile-chromium` | `operator-timeline-investigation-flow.spec.ts` · Timeline investigation flow browser proof › keeps keyboard-only filters, rows, pagination, drawer, and route transitions operable | present | present | passed (1 attempt) |
| 27 | Operator routes reflow at phone width without root horizontal overflow | `desktop-chromium` | `operator-responsive-mobile-first.spec.ts` · operator responsive matrix: phone › keeps every operator route usable without root horizontal overflow | present | present | passed (1 attempt) |
| 28 | Operator routes reflow at phone width without root horizontal overflow | `mobile-chromium` | `operator-responsive-mobile-first.spec.ts` · operator responsive matrix: phone › keeps every operator route usable without root horizontal overflow | present | present | passed (1 attempt) |
| 29 | Timeline rows remain static with reduced motion enabled | `desktop-chromium` | `operator-timeline-investigation-flow.spec.ts` · Timeline reduced-motion browser proof › keeps Timeline rows static with reduced motion | present | present | passed (1 attempt) |
| 30 | Timeline rows remain static with reduced motion enabled | `mobile-chromium` | `operator-timeline-investigation-flow.spec.ts` · Timeline reduced-motion browser proof › keeps Timeline rows static with reduced motion | present | present | passed (1 attempt) |
| 31 | Investigation routes preserve scope and controls under actual desktop 200% browser zoom | `desktop-chromium` | `operator-zoom-proof.spec.ts` · inspection routes preserve exact scope and controls at verified real 200% tab zoom | present | present | passed (1 attempt) |

## UIV-02 matched route and visual evidence

| Bundle | Outputs | Manifest-set SHA-256 | Output-set SHA-256 | Main-manifest SHA-256 |
|---|---:|---|---|---|
| Phase 238 accepted baseline: `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_close_routes_1791521924` | 135 | `d796f34cfbe976e89b68e3d597b535e564f432cba18e55a3b76024dbc775ffb3` | `71fe864888b16030f8bd6fb5b8f4be901bcf37295348fa34eeb70609718a1028` | `ea0cc9930f3be93b2c873565a0420c8b9d48f98034f201d15c1734473213c121` |
| Candidate `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_243_routes_1791737568230_fix` | 135 | `40bcd53a57e12fcdca2e9bd01f47ec01273a1c1ec33a93f022d29c4b72753234` | `8308e93ea44ff76377ecd0782229f58cb438b1a9b6412760cf31f42cc6a46abf` | `4bbec5959a693ffde4e49f4a6ac57c1fc39d8273729c61c2c5f3d072197fc2dd` |

The candidate bundle has 34 full shells across eleven named routes and degraded Timeline. Validator result: `comparison=limited`, 647 recorded differences, and unchanged Phase 238 baseline byte digest `c744df9cd8e999109be2ac0956028288b4f4b1eb734354d8d22d0bcf3332f4aa`. The generated validator report is `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_243_routes_1791737568230_fix/candidate-review.json`, SHA-256 `f46b3849df0802455337e4c0a7aea6e32f8aa701536e2b2e1f1c9192a3d5c1c8`. Difference groups are asset identity, render-condition metadata, seeded route/state identity, environment metadata, and fixture identity. No pixel-equivalence claim is made. Capture conditions and the detailed finding ledger are in `.planning/phases/243-integrated-verification-and-review-preview/243-VISUAL-REVIEW.md`.

| Finding | Current output and disposition |
|---|---|
| UI-241-01 | Redaction 375 shell `route.redaction__dark-375-shell.png`, SHA-256 `0cf8dd30508db4efd4ca2440f8cf9421708244866e109dd2d782bb6bf60d7454`; posture gap visually confirmed. |
| UI-241-02 | Evidence 375 shell `route.evidence__dark-375-shell.png`, SHA-256 `d3d6e7d30f6a65f240b880a0a6d7a99f85ffe39c41ba3b8cf448a09f1f446aab`; footer actions visibly separated from card edge. |
| UI-241-03 | Redaction shell shows “Could not inspect (0)”; focused mounted contract asserts the accessible label and preserves `:could_not_introspect`. |
| DR-243-01 | Drawer 1280 shell `route.drawer__dark-1280-shell.png`, SHA-256 `f64e1c27164c6b9e57d584d51468c164998bcc9bb628eda53742260452cb146d`; title remains partly under fixed header while Close is reachable. Same issue is in the accepted baseline; carry forward as a medium visual-clarity risk owned by overlay positioning. |

## UIV-03 guarded local preview

- Receipt: `.planning/phases/243-integrated-verification-and-review-preview/243-PREVIEW-RECEIPT.json`, SHA-256 `3b86c70d16b8804523d361347cbe4a59891417befc176f7f5d3b1de9e31d8eca`.
- Candidate: same HEAD, diff digest, source-receipt hash, and fixture as above.
- URL: `http://127.0.0.1:4122`; PID `77236`; partition `operator_243_preview_1791738310061_fix`; database `threadline_phoenix_testoperator_243_preview_1791738310061_fix`.
- The final recheck verified process cwd and ownership, exactly one `127.0.0.1` listener, database mapping to this synthetic database only, unauthenticated login redirect, eleven authenticated routes, connected LiveView, and four matching served/local assets. Asset hashes: app.js `db2c13efe67be20c497f2b18eec870066611e64e310d506f1f36b6acccee051a`; phoenix.mjs `514db00d9819585e1765df2c78b5f416f6e5fab501b631842182cae7d51439a0`; LiveView `880c3dd028e9cd8557ded490f11b712623184f0c3952b1336aef9779de989010`; operator stylesheet `eaa6661249378705e1445c2fde5075c31e8884cf424d5e069f71e85f9b8b9631`.
- Exact guarded stop command for this receipt:

  ```sh
  THREADLINE_E2E_STOP_PREVIEW=1 THREADLINE_E2E_PREVIEW_STATE="<tmpdir>/threadline-e2e-preview-operator_243_preview_1791738310061_fix.json" MIX_TEST_PARTITION=operator_243_preview_1791738310061_fix bash examples/threadline_phoenix/e2e/run-e2e.sh --stop-preview
  ```

- Fresh reopen template (use a free port and new unique partition):

  ```sh
  THREADLINE_E2E_PORT=4123 THREADLINE_E2E_EVIDENCE=1 THREADLINE_E2E_PREVIEW=1 THREADLINE_E2E_CANDIDATE_RECEIPT=.planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json MIX_TEST_PARTITION=operator_243_preview_REPLACE_WITH_UNIQUE mix verify.example_browser --preview
  ```

## Limitations and exact-SHA CI result

- Full-shell screenshots are dark, DPR 1, at 1280/768/375 CSS pixels. The route screenshot manifest does not attest browser-chrome zoom; the Playwright test and inventory files are byte-identical to the prior native reporter lane, which passed the real 200% desktop tab-zoom journey. Light/System focused checks were run on the earlier UI source HEAD and are supplemental, not receipt-bound evidence for this candidate. Mobile emulation does not prove physical-device text scaling or browser-extension zoom; Safari and Firefox were not exercised.
- The candidate comparison remains limited because baseline and candidate metadata, seeded fixture/state identities, and generated asset identities differ. The precise limitations and hashes are in the visual review and the per-capture manifests.
- `.planning/phases/243-integrated-verification-and-review-preview/COVERAGE.md` records the no-external-API declaration required by the coverage detector; SHA-256 `4542903cb5661b1d7afd1b54fdbc24f925e798f05ce79923ed3f9ae763cbba7b`.
- Exact-SHA CI receipt: `.planning/phases/243-integrated-verification-and-review-preview/243-CI-RECEIPT.json`, SHA-256 `99c4391093688b4d0991db5030b36d370150c4258c29a54e47c155e200b8b5e5`. It records workflow `CI`, event `workflow_dispatch`, run `38158769462`, exact branch/head SHA, all 16 successful jobs, required job IDs, and the allowlisted browser artifact and embedded receipt. The source candidate still matches the candidate receipt and preview receipt identities above.
- Run #297 for prior candidate `f2c27053c351082090e074439f9dcebd7e7da3c9` remains diagnostic only: browser E2E passed 416 / 64 configured skips, but latest-Elixir compilation failed on the then-unreachable `SurfaceHeader.seconds_ago/1` fallback and `ci-required` consequently failed. Candidate `2f7560e` removes that fallback; exact-SHA run #38158769462 now passes.
- The CI artifact is a bounded synthetic browser receipt. It proves the listed Chromium journeys on the exact candidate, not browser-engine or physical-device coverage beyond the stated Playwright projects and checks.
