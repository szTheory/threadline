# Changelog

## [0.11.0](https://github.com/szTheory/threadline/compare/v0.10.2...v0.11.0) (2026-09-26)


### ⚠ BREAKING CHANGES

* capture every primary-key shape, read it back exactly, and detect broken capture ([#52](https://github.com/szTheory/threadline/issues/52))

### Features

* capture every primary-key shape, read it back exactly, and detect broken capture ([#52](https://github.com/szTheory/threadline/issues/52)) ([b0668e6](https://github.com/szTheory/threadline/commit/b0668e6d8e628c0e6ff70e4b4e41439c713450ac))

## [0.10.2](https://github.com/szTheory/threadline/compare/v0.10.1...v0.10.2) (2026-09-25)


### Bug Fixes

* give installer and gen.triggers rerun migrations distinct, applicable versions ([#49](https://github.com/szTheory/threadline/issues/49)) ([3885b7d](https://github.com/szTheory/threadline/commit/3885b7d14076fe61819d3fa4e8de7aa777344fca))

## [0.10.1](https://github.com/szTheory/threadline/compare/v0.10.0...v0.10.1) (2026-09-22)


### Bug Fixes

* correct the installer's storage-schema advice and the documented default ([#46](https://github.com/szTheory/threadline/issues/46)) ([4553277](https://github.com/szTheory/threadline/commit/45532778d612b40cda920047c4d9ac368c607fbb))

## [0.10.0](https://github.com/szTheory/threadline/compare/v0.9.0...v0.10.0) (2026-09-22)


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
* **ci:** inspect classic protection via branch metadata ([#40](https://github.com/szTheory/threadline/issues/40)) ([5808f14](https://github.com/szTheory/threadline/commit/5808f14046923ec47785f424849cf1eff91e574d))
* **ci:** read classic protection without admin token ([#39](https://github.com/szTheory/threadline/issues/39)) ([2b16bbd](https://github.com/szTheory/threadline/commit/2b16bbd97921a14cda52699a4d9596a20bdcf43a))
* **ci:** run branch protection audit after CI ([#38](https://github.com/szTheory/threadline/issues/38)) ([81cd88f](https://github.com/szTheory/threadline/commit/81cd88ffa82e8c0354cb51dede80c93e44cb5cda))
* **critic:** register all five route-&gt;page twins in gate; dark maskColor for route captures ([83db391](https://github.com/szTheory/threadline/commit/83db3918be6ce850373f436014ba10b22cf27b89))
* **release:** make the release PR green by construction on a minor bump ([#44](https://github.com/szTheory/threadline/issues/44)) ([8c6b8c6](https://github.com/szTheory/threadline/commit/8c6b8c6b0607a1ce3fa7ce4873b6b6e3d57b1192))


### Performance Improvements

* **192-02:** cache deps/ + Playwright/npm on CI jobs ([2610c80](https://github.com/szTheory/threadline/commit/2610c8041dfb8055afc3bf070bb073a3e05342df))
* **198-05:** cut browser fan-out and abort a broken suite early but diagnosably ([914aed3](https://github.com/szTheory/threadline/commit/914aed30445171e320a11faa9a2832f2c4f5ebc9))

## Generated release notes

<!--
  Ownership split (see release-please-config.json `changelog-path`):
    - This file is owned EXCLUSIVELY by release-please. It is the raw,
      commit-subject-derived release note dump the bot writes into the release
      PR. Humans do not edit it; any hand edit is overwritten on the next run.
    - The human-readable changelog adopters actually read is CHANGELOG.md.
      release-please has no write access to that file and must never be given
      any: no `changelog-path`, no `extra-files` entry, and no version marker
      may point at it.
    - This file is deliberately absent from the published package and from
      HexDocs. It is not in `package[:files]` and not in `docs[:extras]` in
      mix.exs, and the release artifact contract asserts its absence from the
      built archive. Commit subjects are internal maintainer vocabulary and are
      not adopter surface.
    - Generated notes begin at 0.10.0. Earlier generated bodies were written
      into CHANGELOG.md when that file was the bot's target; they remain there
      as published history and are not migrated, because the compare and commit
      links inside them are what adopters have followed for two years.
-->

_No generated release notes yet. release-please writes the first entry here at 0.10.0._
