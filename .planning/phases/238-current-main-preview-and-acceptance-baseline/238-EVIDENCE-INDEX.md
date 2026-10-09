# Phase 238 plan 02 evidence handoff

manifest_path: /Users/jon/projects/threadline/.claude/worktrees/v146-operator-preview/examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_routes_final_1791516878_82721/manifest.json

Accepted after the last runner/config/capture-source edit; earlier runs are superseded. This index contributes to UIB-01/UIB-02, without closing the shared requirements or claiming a live preview. Parent owns plan 03, planning-state advancement and byte-for-byte index/receipt synchronization.

## Custody and candidate

- Retained worktree: `/Users/jon/projects/threadline/.claude/worktrees/v146-operator-preview`; branch: `worktree-agent-v146-operator-preview`.
- Immutable base: `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`.
- Honest capture-time HEAD: `aed99dfad3efdc536f06f0c2622b1344f01ef201`. Captures include effective uncommitted task-02 bytes; committing identical bytes preserves the digest rather than rewriting capture-time HEAD.
- Relevant candidate diff digest: `78db5478e57c8cb41ec16d673ecd360ceace786dc51a99f610440131386517b8`.
- Fixture: `threadline-demo-seed` / `seed-pipeline-v1`; seed SHA-256: `c657f19bedf54433ef86ff0d8698b26995046cd77c07f47a83c04dad4b053a30`; semantic ID: `86a43988888299a0981077a0950599aef52016cbf05d55c3d9350a060a264029`.
- Verification: 2026-10-09T03:36:24Z. Strict manifest serialization, every effective source path/mode/hash, each CSS/JavaScript served/local comparison and every output byte hash passed. Receipt ancestry equals the exact first-parent prefix. Copied context matches receipt hashes, including its explicitly recorded isolated config override. Product rendering source and reference fixtures remain unchanged; the route inventory is the only new fixture.
- Browser: Playwright 1.60.0 / Chromium 148.0.7778.96; normal Chromium sandbox under narrow approved execution. No DOM HTML, response headers, cookies, credential-bearing traces or session values are saved. Screenshots contain synthetic seeded audit data; observations are allowlisted facts.

All following paths are beneath `examples/threadline_phoenix/e2e/artifacts/operator-evidence/` in the retained worktree. Raw generated bundles stay ignored/local, with no bulk screenshot commit. Keep this worktree and these directories through preview/inventory acceptance. Files referenced by each manifest are relative to its run directory; those manifests contain the individual output SHA-256 values and asset/source proof.

| Accepted run | Browser result | Cells / unique outputs | Manifest-set SHA-256 | Output-set SHA-256 |
|---|---|---|---|---|
| `operator_routes_final_1791516878_82721` | 11 named routes + degraded twin passed; 1 legacy reference writer intentionally mode-skipped | 34 / 135 | `a290485c9fc3823a9dd64832935de22eba3c2f7eb1247058f215106feb8be8f7` | `85f006ae0ef53e45e44e945a2185eabcd8c1a3881fda05696faf785770bc28b1` |
| `operator_states_1791516768_67927` | desktop/dark: 11 passed | 21 / 63 | `f76430421460ba7f411865fa64511d04f3768e7c510a762a9bd4418660be85a6` | `a497e533ad9b983605ef8be9bb14b714912153d86f6ab67a83583381a41f952d` |
| `operator_system_light_1791516801_73894` | compile-time System/light: 11 passed | 21 / 63 | `6121ea2e2e6361e616930288973eab6fcdb019c38a419d05d4b85433cbd9742c` | `bca2fc9d47b26f937ce2fe1f515530ab39a8838397dc0f6ffab92b234edafcd9` |

Set hashes use SHA-256 over compact UTF-8 `JSON.stringify` of `[filename, sha256]` pairs. Manifest pairs are the sorted `*-manifest.json` names, followed by `manifest.json` for the route run only. Output pairs are the filename-sorted union of all manifest output references, without duplicates. Each individual manifest below is SHA-256 of its exact file bytes. This makes every set value reproducible without trusting this prose.

Final route `manifest.json` SHA-256: `29c9d02eb80a2130b22908c64929bf5c0208de1a4bfeb07a3efe6081a03c46d4`.

## Eleven-route surface

Independent router comparison proves exact equality with `lib/threadline/operator_surface/router.ex`, rather than deriving the expected set from capture tests. Each named route test directly navigates at 1280, 768 and 375 CSS pixels after login. Each cell has `-shell.png`, `-content.png`, `-observation.json` and `-scorecard.json`; IDs are `<route-id>__dark-<width>`. HTTP 200, mounted operator shell, heading, connected LiveView and intended detail/drawer state are checked. Width/DPR and reduced motion are observed separately from browser zoom.

| Route ID / host-relative pattern | Seed identity | Per-route manifest SHA-256 |
|---|---|---|
| `route.home` / `/` | admin persona | `d9655eadd37fe33771ab578ba6771f34bda4853cc178f37f8ba96965d6ee883d` |
| `route.timeline` / `/timeline` | synthetic activity | `11cf9b264d82336fd1cf478f1b01276fa99b6284de4d253e784fd3e20278d0d8` |
| `route.transaction` / `/transactions/:id` | `walk-acme-4521-close` AuditTransaction link | `0afacf98f4659807f538e3f30614e0f24b7c0401e85ebdb66f1e8564ad9850fb` |
| `route.row` / `/rows/:table/:record_id` | same AuditTransaction's `tickets` AuditChange scalar row | `e702febe77633d459dd9ea00833168c875ac53bab17bc2a832a95d6be636a476` |
| `route.drawer` / `/transactions/:id/history/:table/:record_id` | same transaction/row; preserves seeded `as_of` query | `2e22dae09e59c14a727cdf8a5de367097cd189e82f3cf31f5fb07b6398a2ef80` |
| `route.actor` / `/actors/:kind/:id` | ActorRef `service_account/zendesk-sync` | `aa657c00b7b2f8c89ef6808e97dac1af8c649b64c872778655c04ae357d87076` |
| `route.coverage` / `/coverage` | seeded trigger registration | `8d5d60ab9caef97d5b471ab45cd5d439950e16dd905530921e3f08b07035d87c` |
| `route.evidence` / `/evidence` | seeded evidence subject/snapshots | `abf547c9c6927a4f6cd07425da3415e0fe46b8640d5a345dd0962bfef341a713` |
| `route.exports` / `/exports` | synthetic export jobs | `8f1618a1d8d3cc3346f3bffd172b384496083948f4751c600e2b0396f1d1baa2` |
| `route.redaction` / `/policy/redaction` | seeded redaction policy | `bec0799d3ec78aa063b7eff6f81d7dc095b18b5c0e5247f3735d8de26995d8c0` |
| `route.retention` / `/policy/retention` | offboarded retention fixture | `442dff838eeedd7a8253cedc6c122cae7c31bb37e0bc399acf90862087478ff6` |

Mount is `/audit`; concrete URLs are recorded in each manifest. Role is seeded admin; scope is the isolated local demo database. The degraded Timeline at 1280 is an intentionally injected ranking twin with three outputs, **not a twelfth route**; `route.timeline.degraded-manifest.json`: `2766b4ea00eb19932589ccbaf3ac22aca80717dba243320723d95ff0a0cb6d22`.

## Bounded state matrix

Each row references a `<state>-manifest.json` in both state run directories, with shell/content PNGs and observations per cell. A passing state test proves evidence collection and asserted observations; it does not declare recorded product failures acceptable.

| Manifest stem | Dark SHA-256 | System/light SHA-256 |
|---|---|---|
| `state.theme` | `e3f1101fb2e7e4a5564fad19fe7582ac87f5e2d90895c2c8852cb30d490265df` | `74a34433daa6c51b2e4343849eea3e13ae403491a8935cfdaf93cb3939fdc593` |
| `state.copy.evidence` | `e5f0ce6eb53b915af9a39116f74ba59e77a1cdb9781a3395c36e43f8d16f9515` | `1f1106140b08835512566e3d56fe1fd75ccaa02efae2edd36c936ae4be1bf671` |
| `state.copy.exports` | `93d2911fe698e1f1e9d1dd825db189c9b8f9c88f7b6c0d5438eac74854c678df` | `f7deabbe7d1000c18be3cf74a2299a4da6ce5c99d9362011b735f9b05a654c20` |
| `state.copy.retention` | `2c5d9309635a90c2ae14b181184422f906102d0907c7781decc04c2b53fdf0e2` | `a2413f608c11614dda2d5d5dd61e4e7e021164d930cb59b869319fd2b7811de1` |
| `state.clipboard` | `713b0e65cd0eb5d73150adf360a8bd9c466d19e59b964758b9856e692344e7db` | `4ab2b4314a3072d103ca2c10c7231e04ce07f611d3841161117693985226672b` |
| `state.exports` | `60d2f5e0a3e6c79b4b18f8857eb05a44fe0d9063f3e45e877e52669b338c4fea` | `4b78f1f1699c86e5e9ad0a4a24e27409e9b7763dc43e170f3d83eee8a901c57e` |
| `state.timeline` | `d719270488ec36b56fc26bddba7a89d726a91e552f627def161b54c7cace410b` | `f0e56e6115119ee9e9b2f36b03b0fea03c89528189db3d2644cf68c18a486ba0` |
| `state.offline.pointer` | `8a08b6aaeb4384f27393539d1c800f84b7c6bda5bda4ebe1bf0f83e5a696d710` | `86a3f7db7d495e87d86a4b320055e4c7d02ec86bdd90a317df88c53c05939f4d` |
| `state.offline.keyboard` | `b1688c56ea99a0d3b3c1bc119db36b31c1024b54442e58b5c11f8ec530549cc1` | `2def64e1d4f07a0ee825e241a7dd0935133fac7041f702e0878daaf6c4a6dbb1` |
| `state.focus` | `23a0313fd0792cc16f8dd25e000f08d23afbfc08ed1ac4c44bd874b8985e8e41` | `541601b150bdbeebac77dee0cd739e060a5a1357fa6a7b4a561d7be0ad062679` |
| `state.touch` | `2895b42214a016f107df80235d71d4ce365fb326298b6d3d293f0a832b183373` | `09cb22a7b6fccc2a2d5911b8c77b30db8f73506df95860449897c7f8dd40f256` |
| `state.denied` | `2561c3a585316946a284a8be4b55a864103d8b6bb31d169072424d1375db5ec6` | `106e400f61dd711e2dc91c84667efa2e964df58835674dd71245b6d8b78e8ae5` |

Observed coverage:

- Themes: separate checked preference, mounted attribute and computed effective color scheme/background. Compile-time System starts with System checked and effective light; explicit Light/Dark/System form submissions work. Reduced-motion media matches and home card animation duration is `0.001s`; token values are actual computed values, not declared source defaults.
- Copy: three fresh authenticated contexts directly enter Evidence, Exports and Retention without prior operator navigation. Exact clipboard completion is false and delegated handler absent on each. A separate bound Timeline control completes an exact clipboard copy.
- Pending/empty/long value: intercept the real outbound LiveView query, observe `phx-submit-loading` while held, release to the server, observe zero rows and the actual empty message with the full 232-character filter retained at 375px.
- Failed/pending/completed/unavailable: existing synthetic export jobs render their distinct status groups, failure alert and completed download link. Malformed subject input renders a real invalid-context alert. These are seeded status fixtures, not a newly finished export mutation.
- Offline/reconnect: really disconnect LiveView and block reconnect; banner is visible. Pointer and keyboard queue activation are sampled separately. Reconnect restores the connected root/banner state; both lanes observe zero added jobs for each activation, with no observed duplicates and **no completion claim**.
- Focus/touch: keyboard opens retention confirmation, focus is inside; Escape closes it and returns focus. No prune submission occurs. A separate 375px Chromium touch context opens mobile navigation by `tap`; this is emulated touch, not a physical device.
- Denied: real host GET of `/audit/exports/changes.csv` as seeded Acme support read-only returns HTTP 403. The status and host authorization provenance are recorded separately from busy/disabled; no denial response body is saved.

## Ranked findings for later classification

| Rank | Observed finding / evidence | Follow-up owner |
|---|---|---|
| High | Fresh-entry Copy does not complete and handler is absent on Evidence/Exports/Retention in both lanes; `state.copy.*-observation.json`. Timeline exact-copy positive control works. | 242 interaction truth |
| High | Exports queue remains enabled while truly disconnected: `disabled=false`, no `aria-disabled`, no mutation marker, `pointer-events:auto`; `state.offline.*-observation.json`. No new/duplicate job was observed after reconnect. | 241 status/affordance, 242 interaction |
| High | Long-filter narrow Timeline overflows: CSS width 375, document scroll width 1928 dark / 1924 light; `state.timeline.empty-long-observation.json` and PNGs visibly clip controls/active filter. | 240 layout, 242 resilience |
| Medium, classification candidate | Narrow drawer full-shell PNG shows its heading/Close area under the persistent shell header/navigation; `route.drawer__dark-375-shell.png`. Confirm against the live preview before prescribing layout changes. | 241 detail/drawer |
| Medium, token/test debt | Computed `--tl-color-paper` and `--tl-color-ink` are empty in both initial themes; backgrounds/text do resolve and differ as expected. This is not a blanket visible contrast failure. | 239 token ownership |
| Low, terminology candidate | Inspected home/coverage PNGs show “Check audit readiness”, navigation “Coverage”, and heading “Audit coverage”; retain rendered wording for canonical-label classification. AuditTransaction/AuditChange/ActorRef remain distinct in fixture/evidence notes. No comprehensive label-consistency pass is claimed. | 241 labels/content |

Visually inspected final PNGs: dark home 375, coverage 768, drawer 375, Exports 1280; System/light initial home; dark empty/long Timeline 375. Inspection confirms actual shell/content and the noted clipping candidates. This is evidence review, not final design acceptance or a paid critic run.

## Explicit acceptance limitations

- **Actual browser-chrome 200% zoom: unverified.** Computer Use denied the exact installed Google Chrome for Testing app with “Computer Use was not approved to use Google Chrome for Testing”. No browser UI zoom value was observed. Viewport resizing, DPR=1, screenshot CSS scale and the manifest's neutral compatibility `input.zoom=1` do not establish browser zoom; every capture condition explicitly says `browserZoom=unverified`. Carry this precise unresolved condition into the final inventory.
- **Clipboard denial/unavailability: unverified.** Clearing permissions and a context-specific CDP `Browser.setPermission(clipboard-write, denied)` still reports `prompt` in this Chromium context. The ensuing click shows copied feedback; no Clipboard API denial or failed legacy fallback is claimed. Fresh-entry unbound controls never attempt clipboard access, so they cannot establish denial handling. Missing-API/fallback failure was not forced; `state.clipboard.denied-observation.json` records the probe limitation. The independent host HTTP 403 is genuine authorization denial, not clipboard denial proof.
- Offline tests sample the Exports queue control. Timeline's separate export activation and all other mutation controls are not exhaustively sampled. Zero observed new jobs is narrower than proof that any future queued job completes; worker completion is covered only by the seeded fixture here.
- Reduced-motion proof covers media state and one actual home card animation; it is not an all-animation audit. Focus proof covers retention confirmation; touch proof covers mobile navigation. No Firefox/Safari, physical-device, full keyboard inventory, every route/theme Cartesian product or 200% readability claim is made.
- The legacy reference-writing browser test is deliberately skipped in opt-in evidence mode to preserve read-only reference fixtures. Eleven route tests and the extra degraded-state test all execute; plan 01 already verified legacy evidence-off behavior.
- Unsupported conditions and observed product failures are handoff items for plan 03's classification; no product fixes, public API changes, auth/scope changes, shared planning-state edits, publication or worktree cleanup occur in this plan.
