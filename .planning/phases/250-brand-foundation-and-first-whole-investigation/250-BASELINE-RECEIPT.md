# Phase 250 Before Evidence Receipt

**Status:** A corrected before-only candidate passed its selected browser case and candidate integrity check. Parent independent intake is pending; accepted before count remains zero. This receipt does not claim the required strict after proof or final brand asset acceptance.

## Candidate and Scope

- Candidate ID: review-correction-5d1b25cc-r1
- Logical candidate receipt: candidates/review-correction-5d1b25cc-r1/candidate.json
- Candidate receipt SHA-256: bac8162a6471d1ef186c53e33cbaee4e3c587ce0d7435b4ca7f97477681a8251
- Logical half: candidates/review-correction-5d1b25cc-r1/captures/before/half.json
- Half SHA-256: ab1a0fbbbd92fcdc478e6284c0f26d74ffe014fc764c55855bdd1d637d87f293
- Candidate pair ID: 7a476172-0d1f-4387-b091-62f4ff9e6340
- Candidate captured: 2026-11-12T12:51:14.887Z
- Selected Playwright report SHA-256: b34525fb17464916ac84d81c04abf0b6333035f612e05118cb6ae34e7d3b6ac6

The original canonical before pointer remains at captures/before/canonical.json (SHA-256 9bd280cdf7bdf8a29590a0acd1ef238e35e0d63d2d93171dc1e2965b6ca07ffd). It still references captures/before/2026-11-12T11-01-01.122Z-c708081c-edf0-4dd0-ab4b-6c77d355a17f/half.json (SHA-256 f7c1246830c349ed7c52a658e4e6ab623a2d669494074b7597b8a5cd186b9391) with pair ID c708081c-edf0-4dd0-ab4b-6c77d355a17f. The candidate capture flow wrote only beneath its distinct candidates directory; it did not replace or promote that pointer. The original half and its earlier failed-attempt artifacts remain preserved and unaccepted.

This candidate records the current UI's supported before path: filtered Timeline → selected transaction → prior ticket-history snapshot → browser Back → Timeline-origin reply history → Timeline copy. The keyboard copy used a controlled deferred writeText double, trusted activation, pending and success feedback, retained DOM focus, and no fallback. Copy from Timeline is explicitly before-only. The final after proof must copy from transaction-origin reply history and return through UI links with the original filters restored; this candidate does not satisfy that contract.

## Selected Live Materialization

The read-only materialization helper matched the prepared snapshot before and after the failed browser attempt and during candidate integrity validation. The candidate selected fields were compared with its live rows, including raw timestamp precision. The helper returned the same history fingerprint and three linked history changes.

| Field | Observed value |
|---|---|
| Database / partition | threadline_phoenix_testp250pair / p250pair |
| HTTP listener / PostgreSQL port | 60150 / 60025 |
| PostgreSQL system identifier | 7706932079119234489 |
| Action | c5c875c0-ed40-45c2-908e-925872fce082 — ticket_replied_and_closed |
| Correlation | walk-acme-4521-close |
| Transaction | de666048-6343-432a-b800-b4ac5d41e749 |
| Changes | 338472f6-d6df-435d-b9ff-e3d3d6c00580, 9daa43cf-db14-40e2-b4df-aa1a6bfdc7e8 |
| Ticket / reply | 2cfa0b53-305a-4d52-b57c-e82520596390 / 9c8e4f16-806e-47b4-81bd-6e4341056781 |
| Actor | cb1b4a0f-17e6-5afe-a072-5c5a6895ee5b |
| Event / action inserted time | 2026-05-26T14:30:00+00:00 / 2026-11-12T10:06:36.944698+00:00 |
| Counts | one action, one transaction, two selected changes |
| Selected materialization SHA-256 | 163b1003612e386e3612ad478ca518ab12f69a8c6a96c4aed30bb1f04e971143 |
| Linked history SHA-256 / change count | 9ba494ce33ce130528049d0c7fcbf4d5ded7d99b99c389704e8aaec715dbe972 / 3 |
| Ticket subject-row SHA-256 | 5ad4c60f67d47fb440b7d43c0dfc6081bb6f7b3f2e707e0c6dee0238eb3e614e |
| Reply subject-row SHA-256 | 46736a2a81bbc678c2631336c03e799fcf9d2cd931c7b18036558db287459cf4 |

The reply body was “Thanks — we're closing this out.” and the internal note rendered as [REDACTED]. The ticket's captured state changes from open with a null closed_at value to closed. The raw subject secret canary was not stored in the capsule.

## Browser and Capture Conditions

The corrected selected case passed once in desktop-chromium, with zero retries, skips, flaky results, or report errors. It used Chromium 148.0.7778.96 and Playwright 1.60.0 at 1280 × 900 with DPR 1. Reduced motion was enabled. Dark and light captures record their preference, mounted theme, and effective theme; separate system observations record dark and light system schemes. Browser zoom remains **unverified**; no numeric zoom measurement is claimed.

The candidate contains transaction detail, prior ticket-history snapshot, reply history, and returned Timeline captures in both dark and light lanes. Each lane includes a .threadline-ui shell/header image, #tl-main content image, and JSON observation. There are also two System JSON observations. Candidate integrity validation read all 26 referenced files under the private pair root, rejected no paths, and confirmed each file's recorded SHA-256 and byte length (when recorded).

| Capture | Shell bytes / SHA-256 | Content bytes / SHA-256 | Observation SHA-256 |
|---|---|---|---|
| transaction-dark | 171382 / 31acdde85be9f7c08beb320758a21dc45c166486b2154c3fc20274259dd68629 | 134402 / 5cbd5e3449e74bbb1faaa0c1c97afd187d8a64ff35cd69e60b62ca4ff66c6adc | 382b5771b27f601f01e9588215e15cd15f6cef2908e02c672b8eddbc13885f74 |
| transaction-light | 170734 / 94d0d03af9bbf04241a7b5941765c920afa1fe97d545870aa3efaa7279ccaeeb | 134091 / 2159762e721d4c9547afaed761e40115312f7ba7ecfc5ccab7685de22c44a58f | dfa1d2a0797e7dfbc45904320f6ee61e6a7fb5354cdb6da95c7d9287a7111bcc |
| ticket-prior-dark | 171918 / 2b5dccee60f5580eb6a9dbed8385a5cba2a247c519c0f60eea5265431326fa04 | 132229 / 256714e550c836f75d0b2c236aec3f5b628e1444af2024a7c389853d708acbb4 | ccc8187f571f524280e95e3ef75f6bd6f8136257a771ed5823d5335b55804f5c |
| ticket-prior-light | 173282 / e347ea7ecb69eaaff94f1b2b665435c67a63e1885715b85af952682fcf9d3a04 | 134001 / 36707d9bfd00c85f9dc7775081e63ec3dd031cceacf0f9504902d60505b60fa2 | 2f83c40057da63ac4721f1e9b2ebba0f3fdc2de0c8c8afe713bc54c4f060eb65 |
| reply-history-dark | 104173 / db9a340b26e860b29838784c8c0a3cfca2e7ffe309e8331fe23bec01af735fbe | 68466 / 8e1bf4fca51e4be012c384166d1e552a3af3e8d67dbc81163aad6b6540e921de | 6cfd4bbc43de5da8f3cb7d120a09123f35106635fcce5be90850e0e324aabe3a |
| reply-history-light | 104579 / c64cdffab01f504da5ee5e4e08d20b53f1ddcf4d72b5be0151309d92ad99abb4 | 68935 / b75165d9d01f7175545845afae7061e82a49c5b749d36d64175b15572c07f316 | 2800412d6070b615d4e8b72e91b097d0c56c1686893d018d59cfe63bdcb98df1 |
| timeline-restored-dark | 148180 / a6217c7d4a3832949cca911cee7fb93979148f4db58d634badcce535fcc76698 | 115151 / bc9826e4fa08e9b3e408bedf8fd5ae7cfe9c7a94a469daf8236361f0c1e76cdd | b232d4ade2d7a937502825ac7c3b84a2c05ca2c597bfc7235859f95a5cdc18fc |
| timeline-restored-light | 148098 / fe507c9b8cfa25a7722f7062f9e3c166d30c90b3d0eb16d1d8f97f029a55f2fd | 115301 / a49f322d31bb4c386b027156fb95e92f102170aac2480ab649d8f6e4bbcb9886 | af65958919f7f1f187ca15fbff4d4277d0ef466f9c3f5af79fd87fc45be170b4 |

| System observation | SHA-256 |
|---|---|
| system-dark-observation.json | 7d1f0e39e66d6b5b77201b9853f015d866dc60403f58ca74b1ed98c6302807e2 |
| system-light-observation.json | cfca77352e19203827df2972888effa706c4c91892b5c8fcc3a517480b75137d |

## Served Asset Observations

All eight route captures recorded stylesheet SHA-256 eaa6661249378705e1445c2fde5075c31e8884cf424d5e069f71e85f9b8b9631 and inline-script SHA-256 46fb66052fbeca648d5a53e00d6fdbafe39d1b846b6a31509bd62850d81196c6. SVG markup digests vary by route; these are captured outputs and are not a claim that the approved new logo was rendered.

| Capture | SVG markup SHA-256 | SVG count |
|---|---|---:|
| transaction-dark | 1da62837a7a904920715675a9aa2a1dcbe8332185b7cb428b33a67d64ddf710b | 16 |
| transaction-light | 6dae1a0e3e048eea702cb1b1aa936e0bee157caf2eda4946a16a84670310a14d | 16 |
| ticket-prior-dark | 6d341df13116a3c682ccaadc32477fe52581cf32dd059b67551e19d7edc8a0b2 | 17 |
| ticket-prior-light | c92e82f66c57a1c546ba6ce27a9d85d43d10882ffabc3daf8166a0b5778f6982 | 17 |
| reply-history-dark | 26acff9796eeda4941bb3a0c5513bac4a8facb4e25fd543d3e619dc694b4c201 | 4 |
| reply-history-light | 348aa82ed90ebcdf94cfa789d111dd8e9e47990a040b9735ed51ffb19b9b0edd | 4 |
| timeline-restored-dark | 0860ebc6d9a28fca05d9653c62e54c75894bf5cbb34796c6ddd5bf06458bd0bc | 26 |
| timeline-restored-light | 473885a591d005fee7404448e562b4f725ab2e2fe79f3aad4c8d69acb7eef497 | 26 |

Five existing embedded WOFF2 faces were recorded per route observation:

| Served font | Bytes | SHA-256 |
|---|---:|---|
| geist-400.woff2 | 12956 | ead637fd0b6b887d829b3ce3f25fdc242b1de0cfb69c0d97987933675d1315ba |
| geist-500.woff2 | 13296 | 6145bf6706dbc1b6686f04f871489cf724951f00b752745896ccdcac07639a53 |
| geist-600.woff2 | 13372 | edde7cc4e2719898f981a6d970a756030fff75a8ed36dd6a457a60181b889ebf |
| ibm-plex-mono-400.woff2 | 14708 | 08949f728dc52d528e69b1667d15c89a5686a4ee9a296ff90983985f99c380f7 |
| ibm-plex-mono-500.woff2 | 14888 | 01d285447409c8a588692162439a038b8cbd7871309ee20267b0d2d91c6e8e22 |

## Runtime Source at Candidate Startup

The parent-owned app receipt recorded startup source revision ce7daf984af1cd8acfed09be7c213b335d2e6b09 and source-map observation time 2026-11-12T12:42:31.146200Z. Its complete 35-file runtime map matched both current serving and test runtime maps at candidate validation. Test/helper commits after the parent restart changed no files in this runtime inventory; HEAD equality is not used as source freshness evidence.

| Relative source file | Bytes | SHA-256 |
|---|---:|---|
| brand/assets/fonts/web/FamiljenGrotesk-normal-400-700.woff2 | 18884 | 5c2a822104a1c4d658b6f070043548efbe19243aff2aab567494877056527f17 |
| brand/assets/fonts/web/Geist-normal-400-700.woff2 | 29288 | 9b6f5ff45b278c744b5f379a2c4ecbaf858a842b8eaf82ac8d21b699ca16c608 |
| brand/assets/fonts/web/IBMPlexMono-normal-400.woff2 | 10052 | c36f509c0a8f9f85f29cb44bc8701d8a9e0b14c499e77a884f789ead7093a7ac |
| brand/assets/fonts/web/IBMPlexMono-normal-500.woff2 | 10060 | a76f53ca6612e7b3828eec2311098675b7f9849ae4169a8bcef6302aec02a6c0 |
| brand/assets/icon/favicon.svg | 1360 | dc1959e94fa400fc0fc166a2f2979277be6064b15a406e1e6e1c5244a3fd2481 |
| brand/assets/logo/threadline-lockup-dark.svg | 5001 | 83dc3ec35cb4091ba71163ffe5fc3720345fe2cb93e07e27eb42203d1c93a0d5 |
| brand/assets/logo/threadline-lockup-light.svg | 5006 | c539332ce218d9eff9b6fc8611bf34febe15b4f72a532c61ff9486c18d8f52bf |
| lib/threadline/operator_surface/components/icon.ex | 2343 | 4669bd299c159cd35db61bfb1f699ec472f5cce635b21bd67ed6f616b1ccb391 |
| lib/threadline/operator_surface/components/logo.ex | 6194 | 1ca7cccdea64ce6649caf2391ffb891218dde01d06bc78d44a785a523d19b7e4 |
| lib/threadline/operator_surface/components/surface_header.ex | 7032 | 3337f2c9f1beb163f82622185772475e9c86ffe89ab70468c9faffa6c1771e0c |
| lib/threadline/operator_surface/fonts.ex | 2292 | 4d91e2174062690263a5ebb2753bf3e83d10e548c581dd84e65f6200d5a057b9 |
| lib/threadline/operator_surface/live/row_history_component.ex | 10427 | 1215665e841929e5f1d5b7581727587dc76299ac291f317faf1a58335c3c57a5 |
| lib/threadline/operator_surface/live/row_history_live.ex | 5124 | 3391b3313e70f037a98ea9e9858ebbde19ab76294883defeb0cf52f87284c3a9 |
| lib/threadline/operator_surface/live/timeline_live.ex | 25452 | dfba1f7c638cfbe8947ab92f72fad56dd936781b0197c06c3265a10feab7932d |
| lib/threadline/operator_surface/live/timeline_live/changes.ex | 4568 | 4243ee181de3554c96c66a70e1d866802146af7a1ec823d3965572f25de3fd75 |
| lib/threadline/operator_surface/live/transaction_live.ex | 26212 | 0867642c93c2eb15757591d8c200bd86b9c51a27eadee355450c6133d9ff0919 |
| lib/threadline/operator_surface/presentation.ex | 21061 | 2b4d9c4f50c26db5707cc06f7f8b084b326f3e056fdd0a72d34f145b89863829 |
| lib/threadline/operator_surface/script.ex | 10227 | 168baaa726aa1ab4f846af78bb2f11864e575dc70c1fe17d3aee16c80f47985a |
| lib/threadline/operator_surface/style.ex | 1465 | cb56338f070d8d3d6f9a9e8577e4ca758e9d44c529aaa6d365efeafa49dae18b |
| lib/threadline/operator_surface/style/01_tokens.css | 12661 | b0b0c12321d597bb6511aa198564702a6b5fed48b730a729faf8d8cb36fe31c7 |
| lib/threadline/operator_surface/style/02_base_shell.css | 9600 | ccd893da13be8904ed5a83443eae35474c63a0d6d1a0d5e8ad7e259d67f70470 |
| lib/threadline/operator_surface/style/03_page_home.css | 10294 | 821646fca888220b700c502c2d877dabed30524d56c1666a93366c8b9cfe0eff |
| lib/threadline/operator_surface/style/04_controls.css | 16229 | 4c19c64a22416310b65a858b33fc52c79e3af22677372da521065569f8786cf3 |
| lib/threadline/operator_surface/style/05_feedback.css | 11179 | 5c7a296c888aebc1faced428c891f47ee932209d32c43062d8c6efa6de732930 |
| lib/threadline/operator_surface/style/06_layout_primitives.css | 17248 | 00dae71a0081374f1350abfb9290297b977222ddd70e27bd690e7db8c24a9601 |
| lib/threadline/operator_surface/style/07_find_detail.css | 12698 | a18d5ce2487992b2691b88be3e3b291df60884ae28751436f8c8f2b1e430c619 |
| lib/threadline/operator_surface/style/08_overlays_motion.css | 18450 | 5a4448dc70d149102f27079288af27d543292f52aa4983a54ac5f3d0a7c8ac52 |
| lib/threadline/operator_surface/style/09_responsive.css | 13108 | 6550e3215837fa08e19d7cda11a688c054c879e461f05e575d7de9bd63e2e41c |
| lib/threadline/operator_surface/ui/data.ex | 13197 | 186e745429d85f8abd20f6c2eaa40974b469babbf0a4eebf6086b66fb77a440b |
| lib/threadline/operator_surface/ui/display.ex | 8253 | 517065dea3d530984e9fbfebea8f77812cbe9813deefa558c81a1a48584b800b |
| priv/fonts/geist-400.woff2 | 12956 | ead637fd0b6b887d829b3ce3f25fdc242b1de0cfb69c0d97987933675d1315ba |
| priv/fonts/geist-500.woff2 | 13296 | 6145bf6706dbc1b6686f04f871489cf724951f00b752745896ccdcac07639a53 |
| priv/fonts/geist-600.woff2 | 13372 | edde7cc4e2719898f981a6d970a756030fff75a8ed36dd6a457a60181b889ebf |
| priv/fonts/ibm-plex-mono-400.woff2 | 14708 | 08949f728dc52d528e69b1667d15c89a5686a4ee9a296ff90983985f99c380f7 |
| priv/fonts/ibm-plex-mono-500.woff2 | 14888 | 01d285447409c8a588692162439a038b8cbd7871309ee20267b0d2d91c6e8e22 |

## Validation and Custody

The final candidate integrity check reported candidateIntegrity=true and parentAcceptance=false. It read and validated the candidate path, the live selected row/history fingerprints, source freshness, and all 26 private evidence files. Parent environment readiness was recorded at source commit 66d203818fcfb39d615c8cc10afc1b53cbb6c034; the subsequent 5d1b25cc commit changed only E2E capture/test code outside the 35-file runtime inventory, and this candidate check confirmed the startup/serving/test runtime maps still match.

The app lifecycle stayed with the parent. This worker did not stop or start the app, reset or reseed the pair database, repeat migrations, alter the selected rows, use native clipboard APIs, or take desktop focus. The post-failure read-only check returned matched=true with the same selected and history fingerprints. The candidate and failed-attempt logs, report files, and partial candidate folders remain in the private pair root.

The next gate is parent independent intake. The parent owns candidate selection, default check-before acceptance, service/capsule preservation through worktree cleanup, and final GSD reconciliation. Until it accepts the candidate, the original canonical pointer remains authoritative as an unaccepted historical record, and no after proof can rely on this before candidate.

---

Portable evidence is recorded by logical file name and relative runtime source paths. Machine-local checkout and temporary paths are intentionally omitted.
