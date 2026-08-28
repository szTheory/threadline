# Changelog

## [0.10.0](https://github.com/szTheory/threadline/compare/v0.9.0...v0.10.0) (2026-08-28)


### Features

* **185-01:** implement coverage readiness verdict ([36086b9](https://github.com/szTheory/threadline/commit/36086b9a4bd167377ef3a64f84cad3bd510bebff))
* **186-01:** align actor activity detail surface ([3022e2e](https://github.com/szTheory/threadline/commit/3022e2e0ec270c5a2080d55da28fc681f041e089))
* **186-01:** align row history detail and drawer ([6685aeb](https://github.com/szTheory/threadline/commit/6685aeb13c5b4531f95c1d728068cf4050c91702))
* **186-01:** align transaction detail surface ([42f0bfe](https://github.com/szTheory/threadline/commit/42f0bfeb64fe16d768a76d755e60e734d5cab1d9))
* **186-02:** focus evidence workflow summary ([39229dc](https://github.com/szTheory/threadline/commit/39229dcc997d74a6d3d17f337e4d65a7be7bcb9a))
* **186-02:** focus redaction policy posture ([cf097ff](https://github.com/szTheory/threadline/commit/cf097ff75e5f636b3a0e1bedac60f338b47b87d5))
* **186-03:** implement retention destructive-flow contract ([107fa9f](https://github.com/szTheory/threadline/commit/107fa9f4688b92b3480e8b083b76c8c9f003ceab))
* **186-04:** implement export workflow affordances ([cc6ec29](https://github.com/szTheory/threadline/commit/cc6ec295836961217d07538e5fa65789f59f1a46))
* **190-01:** quote all generated migration SQL references ([d6bc075](https://github.com/szTheory/threadline/commit/d6bc0753b09c533e649d32a75aac5cafb4996cd6))
* **190-01:** quote generated migration schema contracts ([50cdba4](https://github.com/szTheory/threadline/commit/50cdba4e98c5b6f452cdae37e951c6b77abf6f09))
* **190-02:** remove fixed owned schema prefixes ([b1e1231](https://github.com/szTheory/threadline/commit/b1e12313181ff5c29318a561fad788297ebf0826))
* **190-03:** make query preloads storage schema aware ([04dd8fb](https://github.com/szTheory/threadline/commit/04dd8fb769c8c1c4abfa41008c24145d985f2710))
* **190-03:** thread storage schema through audited transactions ([3e2cac3](https://github.com/szTheory/threadline/commit/3e2cac3cadfd6319e90db3c63a7103473a052265))
* **190-04:** make export download lookup storage-prefix explicit ([2717669](https://github.com/szTheory/threadline/commit/271766988dd79b23bc594af5a11e4aecf4e8a6be))
* **190-04:** make queued export storage prefix stable ([12a06e5](https://github.com/szTheory/threadline/commit/12a06e56458ebea52f984a8f43bdabf8494f9c23))
* **190-05:** make retention pruner storage-prefix aware ([ad5f0b8](https://github.com/szTheory/threadline/commit/ad5f0b86e67ad0afeba73cd5d0f952107e1e70a7))
* **190-05:** make retention storage-prefix aware ([6c0332d](https://github.com/szTheory/threadline/commit/6c0332d3dbc8693150920a49acef3888acfce1b4))
* **190-06:** make remaining operator views storage-prefix aware ([a440910](https://github.com/szTheory/threadline/commit/a44091077fe7dff39cd33fa0c920b4dfe78af9b6))
* **190-06:** make timeline and export status storage-prefix aware ([7faea51](https://github.com/szTheory/threadline/commit/7faea51119fde4e91be85b078ae53d784a5d83b9))
* **190-07:** make continuity host-schema aware ([cf2e4ba](https://github.com/szTheory/threadline/commit/cf2e4bae36365cde4539c4f88c32cf512573daf3))
* **190-07:** validate support host table identifiers ([dfcb88b](https://github.com/szTheory/threadline/commit/dfcb88b402fbddd85506def966bbb0e0640af785))
* **190-08:** add redaction LiveView host schema selection ([4b5d978](https://github.com/szTheory/threadline/commit/4b5d978913f299c8707fd44fda60df5ba8011c2c))
* **190-08:** add selected redaction schema CLI support ([4d88615](https://github.com/szTheory/threadline/commit/4d88615539c9bfe0b95f71774d07b1f36f1b3e56))
* **190-09:** clarify Timeline host schema filters ([ff54af7](https://github.com/szTheory/threadline/commit/ff54af7d56f2650699d6a2ff171fa5e75743bb7c))
* **190-09:** support schema-qualified row history ([b65bd65](https://github.com/szTheory/threadline/commit/b65bd65e92cff3ae8f5d83ade845cfe1a3435aec))
* **191-02:** replace groups_for_extras with four verb lanes ([3fe06fd](https://github.com/szTheory/threadline/commit/3fe06fd8bb6fe8562e4c2c0cd4d5a95f46a51d70))
* **191-03:** add central version_truth_doc_contract_test derived from [@version](https://github.com/version) ([d24ca5e](https://github.com/szTheory/threadline/commit/d24ca5efdad43fdca1cc775da30cf35b50823d06))
* **192-02:** verify-test min/current matrix, PR concurrency, pgbouncer pin ([cce7f40](https://github.com/szTheory/threadline/commit/cce7f40965a8e55f2dc968bd39d2c92846eb0b88))
* **194-01:** migrate design-system ledger v1-&gt;v2 scorecard cube ([d8970e3](https://github.com/szTheory/threadline/commit/d8970e3c67bcdeae8182691a6234f2021fe323d5))
* **194-01:** project Scorecard Cube per-lens table + freshness guard ([3814511](https://github.com/szTheory/threadline/commit/3814511db6a776202947ad2f5884b149c9d82df8))
* **194-02:** author Tier A capture spec + verify.capture runner (MECH-04) ([d472f2b](https://github.com/szTheory/threadline/commit/d472f2b6602f2d47b64f6d4d6677640be2cf42a1))
* **194-02:** document tiered Capture Matrix + guard it (MECH-05) ([19dbf28](https://github.com/szTheory/threadline/commit/19dbf28281fda97f80530eeca64f0733dec4ba0a))
* **194-02:** scaffold Tier A capture lane (viewport 1280, projects, gitignore) ([3f69edf](https://github.com/szTheory/threadline/commit/3f69edfd80bdcaac1b843ce5ab2d7096483e22b9))
* **194-03:** create MechanicalChecker (WCAG + MODE-A conformance + MODE-B metrics) ([a918524](https://github.com/szTheory/threadline/commit/a918524f075857abfc23a3bcb113796e3a7ee883))
* **195-01:** add critic toolchain to e2e devDependencies + tsconfig + gitignore ([a018fc5](https://github.com/szTheory/threadline/commit/a018fc580aed1e1643ff92cddc5a6a5ea2eb9a47))
* **195-01:** add verify.ui_critique (local-only) and verify.critic_trust (ci.all) mix aliases ([04bb6b5](https://github.com/szTheory/threadline/commit/04bb6b5e822224fc012dc546295786e30eac94a5))
* **195-01:** seed critic_trust skeleton, golden-set.json, and green pure-Elixir guard stub ([f2ca21f](https://github.com/szTheory/threadline/commit/f2ca21f405efaf95e649b6d10f32e0a47b5474d8))
* **195-02:** author hierarchy, density, rhythm lens rubrics ([d445703](https://github.com/szTheory/threadline/commit/d4457034af73cc09bfcb3e3713b8563ebd87f783))
* **195-02:** author typography, color_contrast, brand_fidelity lens rubrics ([9860e50](https://github.com/szTheory/threadline/commit/9860e5094c408a8bc16d894bc4a76368d74ec7eb))
* **195-03:** author 14 D-03 refute-twin fixtures + capture wiring ([6455539](https://github.com/szTheory/threadline/commit/645553910e2d924f09d7e5426fd7e02b870f5a7d))
* **195-03:** Task 2 — refute manifest + committed scorecards + partition guard ([099afba](https://github.com/szTheory/threadline/commit/099afbaadaccc5205d1a57288ff9c33e834e3435))
* **195-04:** expand verify.critic_trust — full per-lens gate + rubric-hash + golden + disjointness guards ([cf0522c](https://github.com/szTheory/threadline/commit/cf0522c4f79a7dcb8b7f29b0606b462094a7d65c))
* **195-04:** implement pure-Elixir Krippendorff's alpha (ordinal) with bootstrap CI ([ddceb50](https://github.com/szTheory/threadline/commit/ddceb50db220cbf69933c830980fc7bf59306fde))
* **195-05:** client.ts (N-sample) + scorecard.ts + cache.ts (RUNNER-01/02) ([85d1bde](https://github.com/szTheory/threadline/commit/85d1bde53fea9212c482d434bf6853ba67b241f9))
* **195-05:** run.ts CLI dispatcher + Plan 06/07 stub stubs (RUNNER-01/02) ([6534655](https://github.com/szTheory/threadline/commit/6534655a049e25a28e830753c8ef4321f4b5fa8d))
* **195-05:** schema.ts (CRITIC-05) + prompt.ts (3-strata prefix) + bundle.ts ([9cea5e2](https://github.com/szTheory/threadline/commit/9cea5e2f0e3e4df52de5b335d7dab0a652b35280))
* **195-06:** implement 7-critic panel with brand-veto ordering (RUNNER-03) ([db7b938](https://github.com/szTheory/threadline/commit/db7b938444a743cf15b954b54125ff55d993953e))
* **195-06:** implement refute battery with directional+margin+metamorphic gates (CRITIC-02) ([ccbb6ca](https://github.com/szTheory/threadline/commit/ccbb6ca42ea5b0c75fa44bf7358f53ebd4529a70))
* **195-07:** implement label.ts + rubric.ts — blind-round authoring CLI (D-09) ([a248073](https://github.com/szTheory/threadline/commit/a248073a9d2eec2de64fdac5e91d289eee8d2d27))
* **195-07:** implement report.ts — CRITIQUE.md projection surface (D-08) ([5663b25](https://github.com/szTheory/threadline/commit/5663b2555822881b08a13eb85412ac87609c8204))
* **195-08:** inline lens guidance in critic label CLI ([651e600](https://github.com/szTheory/threadline/commit/651e60065fcc0add5949abfa3306f75775e78543))
* **195-08:** trust-measurement writer — mix critic.measure + pure engine + ledger splice ([6161a4c](https://github.com/szTheory/threadline/commit/6161a4c14f9efbb133a97f2d2f5a3e3446c92ba8))
* **195-09:** bootstrap enqueues clean story cells first, poles last ([9f27827](https://github.com/szTheory/threadline/commit/9f27827fe6e009f40ce9e282e29a687edf204bfd))
* **195-09:** clean refute-pole re-capture for golden-set labeling ([082105d](https://github.com/szTheory/threadline/commit/082105d3e8cfd224c54bb47e33ff17d204f196ed))
* **195-09:** local web labeling page (critic label --web) ([181cee5](https://github.com/szTheory/threadline/commit/181cee52a7d5d233c76534cafb4cf573d4a5f1db))
* **195-09:** repoint rubric poles + golden bootstrap to real-UI cells ([44e8708](https://github.com/szTheory/threadline/commit/44e8708e39fba89c555389ccf9e860a669c5c630))
* **195-09:** Storybook real-UI capture lane + 24 committed story scorecards ([34753f7](https://github.com/szTheory/threadline/commit/34753f7cfcc03f5fa782647875b5a0bc404297cf))
* **195:** synthetic twin oracle + ranking trust gate (2 lenses validated, zero labeling) ([aef9e65](https://github.com/szTheory/threadline/commit/aef9e655c2b69895f5efb82a3b08ab7107a50a94))
* **195:** visual critique viewer + first real-UI baseline (4 story cells) ([ddecdda](https://github.com/szTheory/threadline/commit/ddecddaa5269fbe4b90399b44eec88d37c36c16c))
* **196-01:** seed critic_panel ledger baseline + GATE-04 panel-membership freeze ([90d92d7](https://github.com/szTheory/threadline/commit/90d92d78fa1ada41b725dbb037fb0c7c1df530f4))
* **196-01:** tracer — one-lens×one-cell forward-only gate, dry-run wired ([527a3e9](https://github.com/szTheory/threadline/commit/527a3e901611f4ad34d00dbc3fe6e2b9d959d5ec))
* **196-02:** GATE-02 empty structural whitelist + GATE-05 semantic-guard stamp ([80c74c4](https://github.com/szTheory/threadline/commit/80c74c449674363cc69865c126dbb04890b3cd1c))
* **196-03:** full 4-lens blast-radius ranking gate + advisory reporting ([d0bb2ff](https://github.com/szTheory/threadline/commit/d0bb2fff208de376903f36212ce27394b7edfe60))
* **196-03:** GATE-03 held-out divergence halt + GATE-02 MODE-A fix-surfacing ([d1110a5](https://github.com/szTheory/threadline/commit/d1110a53ebceb0759e09a82ef288b383118b7e02))
* **196-04:** expand route capture lane to the five weakest-page candidates ([a4037e8](https://github.com/szTheory/threadline/commit/a4037e8c7dd821c7d3a6a011fe49e69901f83402))
* **196-05:** raise evidence page signal-to-chrome — de-duplicate section headers ([f6c40b6](https://github.com/szTheory/threadline/commit/f6c40b6cf5d21905b1a224e3ed8fec9b96ac715b))
* **196-06:** raise retention page signal-to-chrome — drop duplicated status banner + destructive self-label ([c6f9355](https://github.com/szTheory/threadline/commit/c6f9355e8ca102504a335ddf3e433bfca17a0702))
* **196:** color_contrast nudge (0.688→0.698) — top-end ceiling, stays provisional ([84195c9](https://github.com/szTheory/threadline/commit/84195c9ee316f3c0f1eaaaa506fa6dbdd3a9d848))
* **196:** degraded-twin ranking trust-test for the critic ([11df1f8](https://github.com/szTheory/threadline/commit/11df1f8c30f8af538ed9e8702f019a9b200031a9))
* **196:** density graded ladder (1-persona) — oracle now covers all 6 lenses ([052b166](https://github.com/szTheory/threadline/commit/052b166fd1a9dbec7812ac68d63d0efba710e3f6))
* **196:** full-panel trust measurement — 1-persona scoring; hierarchy/density fail the gate ([59c95e2](https://github.com/szTheory/threadline/commit/59c95e27bde0d00214ebb2800628b78cd166bb5e))
* **196:** hierarchy graded ladder (1-persona) + route.* mechanical-gate exclusion ([0945997](https://github.com/szTheory/threadline/commit/09459974ec6a82e83897c68de1eec53d09f2dc37))
* **196:** hierarchy rescore on widened ladder — ρ 0.086→0.418 (partial rescue) ([b7c8ae0](https://github.com/szTheory/threadline/commit/b7c8ae067ed97a003a124e7ce7830e5f5001b434))
* **196:** real operator-route capture lane for the critic ([a465c03](https://github.com/szTheory/threadline/commit/a465c03c48d110a4e5d7e8ecb99eb319561cb459))
* **196:** rescue density (ρ0.55→0.84 ✓) + typography validated (n22) — 4 of 6 lenses trusted ([f711805](https://github.com/szTheory/threadline/commit/f7118057b4973fc852d75be19f7dbe4ede6b893f))
* **196:** widen hierarchy graded ladder for separability (rescue attempt) ([8a928ee](https://github.com/szTheory/threadline/commit/8a928ee7f670c7265b9610c6b5b0c5eef8691570))
* **197-01:** screenshot-keyed verdict cache + before-pole overwrite guard ([4fd68ce](https://github.com/szTheory/threadline/commit/4fd68cea0506fb860cfd04a2dd2310aa7a427521))
* **197-02:** raise coverage page signal-to-chrome — drop verdict eyebrow self-label + duplicated schema/checked meta line ([842bd73](https://github.com/szTheory/threadline/commit/842bd737ad1a129d7e163f77ce4c3b1846544885))
* **198-04:** add stale-schema tripwire and test.reset/test.setup aliases ([4934d0b](https://github.com/szTheory/threadline/commit/4934d0b26c8086fe25139b57cc9290fa4bc948e7))
* **198-05:** split the browser lane honestly and guard the split with a doc contract ([7cd0e20](https://github.com/szTheory/threadline/commit/7cd0e203843f135e8a55754bbc16534374e2cb46))
* **198-06:** Flake Detection classifies broken vs flaky, bounded, deduplicated (GREEN-11, D-35) ([d1b3bc8](https://github.com/szTheory/threadline/commit/d1b3bc81fc077d80d95884f8517e01c086d8ef59))
* **198-06:** single gated publish path, guarded by tests (GREEN-10, D-25, D-26, D-27) ([8fcbbbe](https://github.com/szTheory/threadline/commit/8fcbbbe455175ea4a81421bffef4c75cd983371a))
* **198-07:** committed branch-protection contract, ruleset, and verifier (GREEN-08) ([e34d19d](https://github.com/szTheory/threadline/commit/e34d19d9cbc49f7059363701d7ea92f9af54e3c5))


### Bug Fixes

* **185:** align coverage actions with UI contract ([af26f58](https://github.com/szTheory/threadline/commit/af26f580cfa00fc76981d32d9a6a7b8143171077))
* **185:** close UI review copy and color findings ([9e221c6](https://github.com/szTheory/threadline/commit/9e221c6e4e7b479945a3f4511afa1d9856dbe5ce))
* **185:** CR-01 guard selected schema snapshots ([2ae671f](https://github.com/szTheory/threadline/commit/2ae671feb56deae4029b03ef3c79bfacfc1a5002))
* **185:** CR-02 handle schema catalog failures ([dd33e21](https://github.com/szTheory/threadline/commit/dd33e21bfe56a4cf394686432d8fb705d608dd39))
* **185:** revise coverage readiness plan ([0033cb9](https://github.com/szTheory/threadline/commit/0033cb969d8cfd2d1e3849a4ef85ccfcf0bd16a5))
* **185:** revise plan verification closeout ([3ff56c8](https://github.com/szTheory/threadline/commit/3ff56c8020ea9fec818a1f8bb8f174c3bfd572de))
* **185:** WR-01 block refresh on invalid schema ([63535b4](https://github.com/szTheory/threadline/commit/63535b472e2208502d544d1882ec00364ae624f8))
* **185:** WR-02 cover stale schema behavior ([6e0fb15](https://github.com/szTheory/threadline/commit/6e0fb15e7cb588b2e51397013fe40212004a242d))
* **185:** WR-03 update coverage readiness docs ([699e29d](https://github.com/szTheory/threadline/commit/699e29de2f76370c32d1b8c982a050570eee1cfc))
* **185:** WR-04 prove focus by keyboard tabbing ([a42cb3e](https://github.com/szTheory/threadline/commit/a42cb3e8e475d568483003f0a96c1bf1f87c89f7))
* **186-02:** align focused workflow assertions ([8c20b31](https://github.com/szTheory/threadline/commit/8c20b314961e2a71b3c790377f7d2325bba31a4c))
* **186:** revise plans based on checker feedback ([a539e69](https://github.com/szTheory/threadline/commit/a539e699ec433c5f713f19fe737f2816efd7c611))
* **186:** revise plans based on checker feedback ([24aa643](https://github.com/szTheory/threadline/commit/24aa6430bac524b5ce2682158e75bf37faf9b51b))
* **187:** align runtime theme picker contract ([7a6ab82](https://github.com/szTheory/threadline/commit/7a6ab82e8a0c33f79a298ee6faea75a513e2334b))
* **187:** secure runtime theme route ([8c0abd7](https://github.com/szTheory/threadline/commit/8c0abd756ac8653ad52d5703bc220d3ef6e9e3d0))
* **188-01:** parse queued export params with canonical filters ([506f99e](https://github.com/szTheory/threadline/commit/506f99eb40a7d196e136c98128aa2d4f137f9816))
* **188-02:** bound copy control transitions ([8bc2f5e](https://github.com/szTheory/threadline/commit/8bc2f5e60186bb286d8644ecd385592b4ed51bef))
* **190-review:** carry export storage schema into queues ([d3e18c6](https://github.com/szTheory/threadline/commit/d3e18c62253fa78f7dd097bc6babe5512227ce39))
* **191-03:** correct evaluating-threadline SSOT claim to 0.9.0 + release-please wiring ([0b4975e](https://github.com/szTheory/threadline/commit/0b4975e2daa77578ce6c7d4badf4b4d0eb47b4ca))
* **191-03:** flip seven install pins to ~&gt; 0.9.0 with co-committed guards ([9a26d58](https://github.com/szTheory/threadline/commit/9a26d5887ae70b896b277b8091916ff0acbcc527))
* **192-03:** scope release concurrency to the publish-hex job ([d1b29c5](https://github.com/szTheory/threadline/commit/d1b29c537ccf94289de1dc72fc31483eb058e508))
* **194:** scope Tier A capture to product surface + add real-evidence mechanical gate ([ab2fb7f](https://github.com/szTheory/threadline/commit/ab2fb7f789112398a15c5b5508e8136b013855f5))
* **195-08:** forward flags through mix verify.ui_critique + add critic score --golden ([9ddf802](https://github.com/szTheory/threadline/commit/9ddf802daeee6751500eeb838dcbe1ea807aeae2))
* **196:** composite translucent backgrounds before WCAG contrast in MechanicalChecker ([35fc174](https://github.com/szTheory/threadline/commit/35fc17454c981efee458f1a83c3685f70a4ce372))
* **196:** recognize the status-stripe geometry [3,0,0] as an on-token box-shadow ([866f4f0](https://github.com/szTheory/threadline/commit/866f4f0334cf69b1e15ff52e2b13d9c4de864f9a))
* **196:** scope mechanical gate to the real /audit surface; reset checkbox/radio margins ([a2cfef6](https://github.com/szTheory/threadline/commit/a2cfef61277bb3616e65ade46520d8d47e398e26))
* **197:** flip stale coverage copy pin to surviving carriers (register D-197-B closed) ([294a0ba](https://github.com/szTheory/threadline/commit/294a0baf53f8097f97283feac65828c61249ed8c))
* **198-05:** recompose cache keys so the two matrix lanes stop sharing one entry ([d941ae1](https://github.com/szTheory/threadline/commit/d941ae1050c639121bdb5c1cc6fd8ea13e6cfafc))
* **198-06:** derive the workflow-file list by glob, not a hardcoded literal ([8b1aa2c](https://github.com/szTheory/threadline/commit/8b1aa2cc6d103b286a20f39774f2c634c3001934))
* **critic:** register all five route-&gt;page twins in gate; dark maskColor for route captures ([83db391](https://github.com/szTheory/threadline/commit/83db3918be6ce850373f436014ba10b22cf27b89))


### Performance Improvements

* **192-02:** cache deps/ + Playwright/npm on CI jobs ([2610c80](https://github.com/szTheory/threadline/commit/2610c8041dfb8055afc3bf070bb073a3e05342df))
* **198-05:** cut browser fan-out and abort a broken suite early but diagnosably ([914aed3](https://github.com/szTheory/threadline/commit/914aed30445171e320a11faa9a2832f2c4f5ebc9))

## [0.9.0](https://github.com/szTheory/threadline/compare/v0.8.0...v0.9.0) (2026-06-03)


### Features

* **operator-surface:** first-class positioning + accessibility pass ([#16](https://github.com/szTheory/threadline/issues/16)) ([4bf1a07](https://github.com/szTheory/threadline/commit/4bf1a071cc26a81efd08b01cd19c8f91a16f6cc0))

## [0.8.0] - 2026-06-03

Operator-surface release: the `/audit` admin UI matured into a coherent, branded operator console, backed by a fully automated (zero-human-verification) test gate.

### Added

- **Operator surface overhaul** — dark "night infrastructure" theme; a Home task-launcher (Find / Verify / Prove) as the default `/audit` page; copy-to-clipboard affordances for correlation and transaction ids; evidence verdicts (Proven / Inferred / Unsupported) with drill-down history; forward "completion" links so every Verify/Prove screen reaches a done state; a scoped-view indicator and scope-aware empty states for support-read-only operators; explicit "all clear" success states; and restrained, brand-coherent motion.
- **Asset/CSP controls** — `config :threadline, operator_surface_embed_scripts: false` opts out of the embedded (zero-dependency) copy-to-clipboard helper; the new "Assets and Content-Security-Policy" section in `guides/operator-surface.md` documents the inline style/font/script embeds and CSP guidance.

### Changed

- **Design system** — consolidated onto tokenized status stripes and a letter-spacing scale, a canonical metric card (`tl-card--metric` + `[data-status]`) and metadata row (`tl-meta`), and ARIA-driven selected/active state.
- **CI / quality** — official GitHub Actions bumped to their Node 24 majors ahead of GitHub's forced migration; an opt-in/nightly flake-detection gate; and test-determinism hardening across the suite. The operator-surface behaviors are locked by deterministic LiveView + Playwright assertions that gate every PR.

## [0.7.0](https://github.com/szTheory/threadline/compare/v0.6.0...v0.7.0) (2026-05-30)


### Features

* **123-01:** add Configure Threadline subsection to getting-started ([7b929a1](https://github.com/szTheory/threadline/commit/7b929a17963b01b09cd1c51d0972f77cce73927a))
* **123-02:** add Host repo wiring prerequisite to production checklist ([a07775d](https://github.com/szTheory/threadline/commit/a07775dd039aa3dedfa6b40eca21f3c6bf80bd5f))
* **127-01:** wire :schemas mount and sync operator-surface doc snippets examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex guides/getting-started-saas.md examples/threadline_phoenix/README.md .planning/phases/127-example-app-schemas-demonstration/127-01-SUMMARY.md ([17507ba](https://github.com/szTheory/threadline/commit/17507ba958215b86c761d1e4b613ab5193bdd502))
* **128-02:** add PhxGenAuthReference.Audit mirroring guide module ([2836be1](https://github.com/szTheory/threadline/commit/2836be141df0e5c2547a9fb91f9478cf35431213))


### Bug Fixes

* **130-02:** format phx_gen_auth_integration_test for ci.all gate ([e04f275](https://github.com/szTheory/threadline/commit/e04f275cd3bd123ae18f192da73f6da332aa1285))
* operator timeline crash on correlation_id filter (+ release-please changelog guard) ([43a6f23](https://github.com/szTheory/threadline/commit/43a6f2364feb3a285c15b13a68f35f905bc8a0d5))
* **operator-surface:** prevent timeline crash on correlation_id filter ([d62e509](https://github.com/szTheory/threadline/commit/d62e509e932b3b85b1749a13745b510ad78c0042))
* **release:** run publish chain when release-ref succeeds via dispatch ([19c7549](https://github.com/szTheory/threadline/commit/19c7549d64f67f34329566590ebf45eca96223a7))
* **release:** use hex.build preflight instead of verify.release in CI ([d4413ef](https://github.com/szTheory/threadline/commit/d4413efe783779554a8d9b39d395034d0dea405f))

## [Unreleased]

### Added

- **Architecture documentation** — rewrote How Threadline Works as an end-to-end visual architecture guide and added a source-driven Code Walkthrough, with dark/light Mermaid rendering and the Threadline mark as the HexDocs favicon.

## [0.6.0] - 2026-05-27

Threadline 0.6.0 is the adopter-ready release: it packages the in-repo stack since 0.5.0 — the Evidence plane (`Threadline.Evidence`, proof vocabulary, `/audit/evidence`), the blessed audited write path (`Threadline.Audit.transaction/3`), and operator/demo surfaces from the realistic walkthrough — so Hex evaluators and pilot hosts see the same truth the library already ships in-tree.

### Added

- **Evidence plane** — `Threadline.Evidence`, `Threadline.Evidence.Proof`, `Threadline.Evidence.Subject`, evidence persistence schema, and `mix threadline.evidence.show` for machine-readable proof export.
- **Audited write path** — `Threadline.Audit.transaction/3` as the blessed helper wrapping capture + semantics in one transaction.
- **Operator and evidence surfaces** — `/audit/evidence` LiveView, host-owned `evidence_authorize_fn` (not inherited from `/audit` auth), and viewer parity with coverage/policy Mix tasks.
- **Reference composition (sigra-reference)** — example app and maintainer walkthrough demonstrate end-to-end audited writes and evidence mounts; see `examples/threadline_phoenix/README.md` and walkthrough docs.

### Changed

- **Public documentation and evidence-plane contract** — Evidence-plane contract locks across public docs: canonical non-goals list, shared verdict vocabulary, and narrower `/audit/evidence` support language. Public guidance treats `/audit/evidence` as a separately authorized capability under the `phoenix-surface` lane instead of a blanket `/audit` inheritance claim.
- **Release metadata** — install snippets target `{:threadline, "~> 0.6"}`; Hex metadata and adoption-pilot distribution preflight align with `0.6.0`.

### Deprecated

- Manual `SET LOCAL` GUC recipes and hand-rolled `record_action/2`-only write paths remain supported as legacy escape hatches; new code should prefer `Threadline.Audit.transaction/3`.

### Breaking

- **None** for existing `capture-only` and `phoenix-surface` adopters who do not opt into Evidence or the audited write helper.

### Upgrade from 0.5.x

- Bump dependency to `{:threadline, "~> 0.6"}` in host `mix.exs`.
- Run `mix deps.get` and `mix deps.compile`.
- If using Evidence: apply evidence schema migrations from library docs / example migrations before calling `Threadline.Evidence` APIs.
- Wire `evidence_authorize_fn` on `threadline_operator_surface/2` when mounting `/audit/evidence` — it does **not** inherit timeline/export `authorize_fn`.
- Adopt `Threadline.Audit.transaction/3` for new write paths; keep legacy GUC/`record_action/2` only where migration cost is high.
- Use `mix threadline.evidence.show` (not deprecated `mix verify.evidence` naming) for CLI proof export.
- Re-run host verification: `mix threadline.verify_coverage`, `mix verify.doc_contract` (host), and operator-surface smoke tests if mounted.
- See `guides/upgrade-path.md` for lane matrix (`capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference`) and surface deprecation policy.
- ExDoc sidebar adds **Evidence** group and Core API entries for Audit, Query, Investigation, ChangeDiff.
- Maintainer pre-flight before tag: `mix verify.release` on a clean tree (see `CONTRIBUTING.md`).
- Apply evidence migrations before enabling `/audit/evidence` in production — schema must exist before first proof query.
- Deny `/audit/evidence` with the same host-owned auth UX as timeline/export; do not rely on blanket `/audit` session checks.
- Correlation filter semantics on timeline/export are unchanged from 0.5.x — no migration needed for existing query params.
- Re-run `mix threadline.gen.triggers` after evidence schema changes if audited tables gain new columns.
- Confirm `evidence_authorize_fn` returns explicit deny reasons for operator logs — inherited `/audit` auth is not sufficient.

## [0.5.0] - 2026-05-08

Threadline 0.5.0 is the integration-breadth release: the package now ships a narrower and more honest support matrix, a first-party Sigra/Phoenix reference path, canonical admin and support-read-only operator-surface mount recipes, an explicit `threadline_web` extraction-readiness scorecard with a documented stay-in-tree decision, and a repaired shared authorization/scope contract that keeps auth and scoping host-owned across timeline, actor, transaction, and export flows.

### Added

- **Upgrade-path guide** at `guides/upgrade-path.md` — canonical lifecycle policy for the optional Phoenix/LiveView/HTML/PubSub surface. It distinguishes `capture-only` from `surface-mounted`, documents the supported compatibility matrix from declared deps + current lock resolution + CI coverage, and locks the surface-only deprecation/removal overlap policy in one place.
- **Integration breadth guide** at `guides/integration-contracts.md` — canonical host-integration contract for actor extraction, additive audit context, optional dependency posture, operator-surface composition, and fallback CLI workflows.
- **Support-matrix closeout** — the project now names only the three proven lanes `capture-only`, `phoenix-surface`, and `sigra-reference`, and the compile-without-optional / example / doc-contract proof chain is locked to those claims.
- **Sigra/Phoenix reference refresh** — the first-party Sigra integration path and example app were refreshed to the current supported lines while keeping Sigra a soft dependency.
- **Canonical access-tier runbooks** — docs, example code, and tests now prove one shared host-owned `authorize_fn` contract, one host-owned `scope_query_fn` seam, and a real support-read-only `exports: false`/scoped-query story across the operator surface.
- **Packaging Boundary Scorecard** — `guides/upgrade-path.md` now records the explicit `threadline_web` extraction-readiness rubric and the current answer: stay in-tree for now.
- **Coverage dashboard** at `/audit/coverage` — polled three-bucket coverage view with a surface-header pill on every operator-surface LV. `?schema=NAME` URL param for multi-schema adopters; manual Refresh affordance with cancel-and-reschedule timer semantics; on-poll-error UX that keeps the last-good snapshot and ALWAYS reschedules.
- **`mix threadline.health.coverage`** parity Mix task with `--json` and `--schema=NAME` flags. Viewer-only — always exits 0; the CI gate remains `mix threadline.verify_coverage`.
- **Policy redaction drift viewer** at `/audit/policy/redaction` — read-only configured-vs-deployed redaction reconciliation with the three operator-safe states `Config matches deployed`, `Drift detected`, and `Could not introspect`. The surface never shows sample values; it exposes only column names and placeholder metadata, and drift/introspection failures instruct operators to rerun `mix threadline.gen.triggers` and apply the migration.
- **`mix threadline.policy.show`** parity Mix task with `--json`. Default output prints one summary line plus an aligned `TABLE / STATUS / CONFIG / DEPLOYED / HINT` table; `--json` emits the same stable state taxonomy as `config_matches_deployed`, `drift_detected`, and `could_not_introspect`. Viewer-only — drift does not exit non-zero by itself.
- **`Threadline.Health.trigger_coverage/1` `:schema` opt** (default `"public"`). Both inner SQL queries are now parameterized; the `pg_trigger`/`pg_class` query gains a `pg_namespace` join so cross-schema results no longer leak into the covered set. Programmatic callers are responsible for sanitizing `:schema`; surfaces that take untrusted input validate at the edge.
- **Three-bucket return shape on `Threadline.Health.trigger_coverage/1`** — `[{:covered | :uncovered | :expected_uncovered, name}]`. The third bucket is hardcoded to `["schema_migrations"]` plus `config :threadline, :health, expected_uncovered_tables: [...]`, with `:audit_anyway` removing entries. Existing pattern-match callsites (`Continuity.assert_capture_ready!/2`, `TimelineLive` datalist) remain unchanged — the third tuple variant is purely additive.
- **`Threadline.Health.Policy.validate!/1`** — pure-stdlib config validator mirroring `Threadline.Capture.RedactionPolicy.validate!/1`. Validate at boot to fail loud on bad config.
- **`[:threadline, :health, :checked]` event metadata** gains `expected_uncovered` measurement key (additive). Old subscribers reading only `covered`/`uncovered` keep working unchanged.
- **`[:threadline, :health, :checked, :error]` sibling event** for polled coverage check failures.
- **`mix threadline.verify_coverage --schema=NAME`** additive flag with the same edge validation contract as the new Mix task. Default behavior unchanged.

### Changed

- **Release metadata** — install snippets now target `{:threadline, "~> 0.5"}`, ExDoc names the operator surface `Optional In-Tree`, and the release/audit artifacts record v1.19 as the integration-breadth closeout milestone.
- **Operator-surface auth/scoping contract** — the example app no longer relies on a socket-only auth bypass, and timeline, actor, transaction, and export flows all consume the same host-owned scope seam.
- **`Threadline.Verify.CoveragePolicy.violations/2`** treats `{:expected_uncovered, _}` as covered-equivalent for tables not in the adopter's `:expected_tables`. Existing semantics preserved for tables IN `:expected_tables`.

## [0.4.0] - 2026-05-06

Threadline 0.4.0 is the operator-surface foundation release: an opt-in web UI ships behind optional Phoenix/LiveView/HTML/PubSub deps so capture-only adopters keep zero new transitive bloat, the timeline / export query and Mix-task surface gains a `:correlation_id` filter that walks `audit_actions.correlation_id` via the action linkage, and exports learn an opt-in action-metadata pair (JSON `action` object, CSV `include_action_metadata: true`) so incident-response tooling can correlate rows back to the action that produced them — all without changing the default column order or breaking pre-0.4 callers.

### Added

- **Operator Surface** — introduces an opt-in web UI via `Threadline.OperatorSurface.Router`. `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` are now declared as `optional: true` dependencies, meaning zero bloat for capture-only adopters. Hosts that want the UI must add these dependencies to their `mix.exs` and use the `threadline_operator_surface` mount macro in their router.
- **`examples/threadline_phoenix`** — **`audit_transaction_id`** on **`POST /api/posts`** and **`GET /api/audit_transactions/:id/changes`** returning ordered changes with **`change_diff`** maps per row (composition demo; add auth in production). **`guides/domain-reference.md`** documents the pattern under **COMP-EXAMPLE-INCIDENT-JSON**.
- **`:correlation_id` timeline / export filter** — optional keyword on `Threadline.Query.timeline/2`,
  `timeline_query/1`, `export_changes_query/1`, and export entrypoints. Values are trimmed; empty
  after trim, `nil`, non-binary, or longer than **256 UTF-8 bytes** raise `ArgumentError`. When set,
  only `audit_changes` whose transaction has a matching `audit_actions.correlation_id` (via
  `action_id`) are returned (inner join; omit the key for previous behavior). See `Threadline.Query`
  moduledoc for full rules.
- **Export JSON `action` object** — each change may include `"action": {"id", "correlation_id"}`
  when the transaction is linked to an `audit_actions` row.
- **Export CSV `include_action_metadata: true`** — opt-in trailing columns `correlation_id` and
  `action_id`; default CSV column order is unchanged.
- **`guides/adoption-pilot-backlog.md`** — matrix aligned to the production checklist for host pilots, plus distribution preflight and prioritized issue rows.
- **Telemetry (operator reference)** — `[:threadline, …]` event table in **`guides/domain-reference.md`**, linked from **`guides/production-checklist.md`** observability section.

### Changed

- **README** — Documentation list includes the adoption pilot backlog; **ExDoc** extras include the new guide.

## [0.3.0] - 2026-05-05

Threadline 0.3.0 is the drop-in production adoption release for Phoenix SaaS teams: the release packages the first-hour SaaS onboarding path, Sigra-ready actor capture, operator incident guidance, and published capture baselines into one taggable Hex surface.

### Added

- **SaaS onboarding route** — [`guides/getting-started-saas.md`](guides/getting-started-saas.md) ships as the first-hour Phoenix SaaS path and is now promoted from the package front door.
- **Sigra integration route** — [`guides/integrations/sigra.md`](guides/integrations/sigra.md) ships as the best-supported auth bridge for Sigra-backed Phoenix hosts and is surfaced separately in ExDoc navigation.
- **Published capture baselines** — the cold-single-table benchmark now anchors the release story with `insert` at `4.87 K` IPS / `205.13 µs`, `update` at `4.30 K` IPS / `232.49 µs`, and `delete` at `7.61 K` IPS / `131.39 µs`.
- **Release-surface contract** — `test/threadline/release_artifact_contract_test.exs` locks package files, ExDoc extras/module grouping, guide presence on disk, and release-only README / maintainer literals.

### Changed

- **README install and routing** — the install snippet now targets `{:threadline, "~> 0.3"}` and sends new adopters first to the SaaS quickstart and Sigra guide, with performance and incident docs one step deeper.
- **ExDoc information architecture** — `guides/integrations/sigra.md` now matches an `Integrations` extras group before the broader reference bucket, and `Threadline.Integrations.Sigra` now appears under a new plural `Integrations` module group while Plug / Job / Health / Continuity / Telemetry remain under the singular `Integration` group.
- **Release pre-flight** — `mix verify.release` now validates the exact taggable tree through release metadata checks, pure file-read release contracts, `MIX_ENV=dev mix docs`, and `mix hex.build`.
- **Maintainer publish runbook** — `CONTRIBUTING.md` now documents the `mix verify.release` pre-flight and the `main` CI wait before tagging `v0.3.0`.

### Deprecated

- No runtime API is deprecated in 0.3.0. Older install snippets using `{:threadline, "~> 0.2"}` should be treated as stale documentation, not a supported release target.

### Breaking

- No breaking runtime, dependency, config, or schema changes are introduced in 0.3.0.

### Upgrade from 0.2.x

- **Dependencies:** no runtime dependency changes are required to adopt 0.3.0.
- **Config changes:** none.
- **Migration steps:** none beyond bumping the dependency and re-running your normal dependency fetch/docs sync flow.
- **Sigra adapter:** use `Threadline.Integrations.Sigra.actor_ref_from_conn/1` as the `Threadline.Plug` `actor_fn` when your host already authenticates requests with Sigra.

## [0.2.0] - 2026-04-23

### Added

- **Production checklist** — [`guides/production-checklist.md`](guides/production-checklist.md) for first-week production review (capture, redaction, retention, export, observability, brownfield).
- **`Threadline.Query.timeline_repo!/2`** — resolves `:repo` from filters or opts with clear `ArgumentError` messages for timeline and export callers.
- **ExDoc** — `guides/production-checklist.md` in extras; **`Threadline.Retention`** and **`Threadline.Retention.Policy`** listed under Core API module groups.

### Changed

- **Timeline filter errors** — `validate_timeline_filters!/1` messages now point at allowed keys and `Threadline.Export`.
- **Validation order** — `timeline/2` and export entrypoints validate filter keys before resolving `:repo`, so unknown keys surface before a missing-repo error.

### Release notes (capabilities since 0.1.0)

This minor release documents and packages capabilities shipped across the **v1.1–v1.3** planning cycles that were not fully reflected in the **0.1.0** changelog entry:

- **Before-values** — optional `changed_from` on UPDATE when triggers are generated with `--store-changed-from`; `Threadline.history/3` loads the column when present.
- **Verify coverage & doc contracts** — `mix threadline.verify_coverage`, CI `verify.threadline` / `verify.doc_contract`, README fixture contracts.
- **Brownfield continuity** — `Threadline.Continuity`, `mix threadline.continuity`, [`guides/brownfield-continuity.md`](guides/brownfield-continuity.md).
- **Redaction at capture** — `config :threadline, :trigger_capture`, per-table `exclude` / `mask`, codegen validation.
- **Retention** — `Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`.
- **Export** — `Threadline.Export`, `Threadline.export_csv/2`, `Threadline.export_json/2`, `mix threadline.export`, shared timeline filter validation.

## [0.1.0] - 2026-04-23

### Added

- `Threadline` core API plus `Threadline.Semantics.ActorRef` and `Threadline.Semantics.AuditContext` for attributing writes to actors in audit context.
- `Threadline.Plug` for resolving `ActorRef` from `Plug.Conn`, plus integration modules `Threadline.Job`, `Threadline.Health`, and `Threadline.Telemetry`.
- `Threadline.Semantics.AuditAction` and `Threadline.Capture` schemas (`AuditTransaction`, `AuditChange`) for PostgreSQL trigger-backed row-change capture.
- Mix tasks `Mix.Tasks.Threadline.Install` and `Mix.Tasks.Threadline.Gen.Triggers` to generate migrations and table-specific audit triggers.
