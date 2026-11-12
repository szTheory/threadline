# Phase 250 Before Baseline Receipt

**Status:** passed; canonical before half captured on 2026-11-12 at 11:01:01.122 UTC.
**Pair:** `c708081c-edf0-4dd0-ab4b-6c77d355a17f`
**Purpose:** establish a real, materialized investigation baseline before rendered production edits. This portable receipt records evidence identities and limits; the original binary captures and full private custody record remain in the parent-retained capsule.

## Selected Materialization

| Field | Observed value |
|---|---|
| Database / partition | `threadline_phoenix_testp250pair` / `p250pair` |
| HTTP listener / PostgreSQL port | `60150` / `60025` |
| PostgreSQL system identifier | `7706932079119234489` |
| Action | `c5c875c0-ed40-45c2-908e-925872fce082` — `ticket_replied_and_closed` |
| Correlation | `walk-acme-4521-close` |
| Transaction | `de666048-6343-432a-b800-b4ac5d41e749` |
| Changes | `338472f6-d6df-435d-b9ff-e3d3d6c00580`, `9daa43cf-db14-40e2-b4df-aa1a6bfdc7e8` |
| Ticket / reply | `2cfa0b53-305a-4d52-b57c-e82520596390` / `9c8e4f16-806e-47b4-81bd-6e4341056781` |
| Actor | `cb1b4a0f-17e6-5afe-a072-5c5a6895ee5b` |
| Event time / action inserted time | `2026-05-26T14:30:00+00:00` / `2026-11-12T10:06:36.944698+00:00` |
| Counts | one action, one transaction, two changes (reply insert and ticket update) |
| Materialization SHA-256 | `163b1003612e386e3612ad478ca518ab12f69a8c6a96c4aed30bb1f04e971143` |
| Ticket subject-row SHA-256 | `5ad4c60f67d47fb440b7d43c0dfc6081bb6f7b3f2e707e0c6dee0238eb3e614e` |
| Reply subject-row SHA-256 | `46736a2a81bbc678c2631336c03e799fcf9d2cd931c7b18036558db287459cf4` |

The captured reply body is `Thanks — we're closing this out.`; its internal note is `[REDACTED]`. The ticket moves from `open` with `closed_at = null` to `closed` with `closed_at = 2026-05-26T14:30:00`. The event timestamp is asserted independently from the action's later `inserted_at`. The private snapshot and rendered journey passed the secret-canary absence checks; no email identity was inferred.

## Journey and Capture Conditions

The selected desktop Chromium case passed with one executed test, zero retries, and no skips. It began with the exact `ticket_replies` table, `walk-acme-4521-close` correlation, and `2020-01-01T00:00` through `2099-01-01T00:00` bounds. It followed the actual action, transaction, changes, ticket and reply; verified the earlier ticket history as `open`/`closed_at = null`; opened reply history; keyboard-activated the full reply-ID copy control using the controlled deferred `writeText` double; asserted `Copying…` then `Copied.` and retained focus; and returned to the original URL with its filters intact. Native clipboard APIs, OS focus and native clipboard permissions were not used.

The original run was the canonical before half. The required tracer feedback run also passed independently and wrote a noncanonical capture; it did not replace the canonical receipt or reseed data. The focused browser flow and the read-only `check-before` both confirmed the pair's original selected materialization.

| Observation | Value |
|---|---|
| Serving source revision | `81fd490359cd0d68a558675678339df6cbc57b7c` |
| Test source and serving source | Distinct checkouts and process identities; their 22 captured production-source byte/hash entries matched at capture time |
| Browser / Playwright | Chromium `148.0.7778.96` / `1.60.0` (`desktop-chromium`) |
| Viewport / DPR | `1280 × 900` / `1` |
| Dark and light lanes | Preference, mounted theme and effective theme each matched the lane; reduced motion enabled; system scheme observed as dark |
| System lanes | Preference remained `system`; mounted theme remained `system`; dark and light effective themes matched their respective observed system schemes |
| Browser zoom | **Unverified**; no numeric zoom measurement is claimed |

## Captured UI and Served Assets

Each lane includes a `.threadline-ui` shell/header image, a `#tl-main` content image and a JSON observation. Separate System dark and light JSON observations were also captured. The private capsule contains the corresponding files under logical names such as `timeline-restored-dark-shell.png`, `timeline-restored-dark-content.png`, `timeline-restored-light-shell.png`, `timeline-restored-light-content.png`, `system-dark-observation.json` and `system-light-observation.json`.

| Logical artifact | Bytes | SHA-256 |
|---|---:|---|
| `timeline-restored-dark-shell.png` | 148180 | `a6217c7d4a3832949cca911cee7fb93979148f4db58d634badcce535fcc76698` |
| `timeline-restored-dark-content.png` | 115151 | `bc9826e4fa08e9b3e408bedf8fd5ae7cfe9c7a94a469daf8236361f0c1e76cdd` |
| `timeline-restored-dark-observation.json` | 10094 | `a0c053d3fcd51020b992e7eccc315851ae75c5d3486b1b033e32c5d50e77048a` |
| `timeline-restored-light-shell.png` | 148098 | `fe507c9b8cfa25a7722f7062f9e3c166d30c90b3d0eb16d1d8f97f029a55f2fd` |
| `timeline-restored-light-content.png` | 115301 | `a49f322d31bb4c386b027156fb95e92f102170aac2480ab649d8f6e4bbcb9886` |
| `timeline-restored-light-observation.json` | 10098 | `ca8f509f783f2041b33f75228af78f91e7a72f4c1afbf3dba9f6584f240555b2` |
| `system-dark-observation.json` | — | `d0811e30d163f554404f7f76f02f266fce5b00c5b99bd4b4faab1b027b55b50f` |
| `system-light-observation.json` | — | `16b3af724baf7c23a6b9eb63f7fa25738352053c0333e805431f6eea7964fb72` |

| Served asset observation | SHA-256 |
|---|---|
| CSS stylesheet bytes | `eaa6661249378705e1445c2fde5075c31e8884cf424d5e069f71e85f9b8b9631` |
| Inline script bytes | `46fb66052fbeca648d5a53e00d6fdbafe39d1b846b6a31509bd62850d81196c6` |
| SVG markup (dark lane) | `d4d33657b5bb29322132ad4be140be1d2c9056c0d3e2b0891f4f395ef5c14971` |
| SVG markup (light lane) | `089ff635f24538c1947264fde34b33ab3c1edb9a867c4bdea77ad949d550355b` |

Five decoded WOFF2 font files were observed:

| Served font | Bytes | SHA-256 |
|---|---:|---|
| `geist-400.woff2` | 12956 | `ead637fd0b6b887d829b3ce3f25fdc242b1de0cfb69c0d97987933675d1315ba` |
| `geist-500.woff2` | 13296 | `6145bf6706dbc1b6686f04f871489cf724951f00b752745896ccdcac07639a53` |
| `geist-600.woff2` | 13372 | `edde7cc4e2719898f981a6d970a756030fff75a8ed36dd6a457a60181b889ebf` |
| `ibm-plex-mono-400.woff2` | 14708 | `08949f728dc52d528e69b1667d15c89a5686a4ee9a296ff90983985f99c380f7` |
| `ibm-plex-mono-500.woff2` | 14888 | `01d285447409c8a588692162439a038b8cbd7871309ee20267b0d2d91c6e8e22` |

## Production Source at Capture

The serving source identity was recorded separately from the test process. The live parent app served unchanged production-rendered source at revision `81fd490359cd0d68a558675678339df6cbc57b7c`. The table records the 22 relative source files' byte counts and SHA-256 digests; the test checkout's captured map matched it. These are the old baseline assets and source, not the approved new brand assets.

| Relative source file | Bytes | SHA-256 |
|---|---:|---|
| `lib/threadline/operator_surface/components/icon.ex` | 2343 | `4669bd299c159cd35db61bfb1f699ec472f5cce635b21bd67ed6f616b1ccb391` |
| `lib/threadline/operator_surface/fonts.ex` | 2292 | `4d91e2174062690263a5ebb2753bf3e83d10e548c581dd84e65f6200d5a057b9` |
| `lib/threadline/operator_surface/live/row_history_component.ex` | 10427 | `1215665e841929e5f1d5b7581727587dc76299ac291f317faf1a58335c3c57a5` |
| `lib/threadline/operator_surface/live/timeline_live.ex` | 25452 | `dfba1f7c638cfbe8947ab92f72fad56dd936781b0197c06c3265a10feab7932d` |
| `lib/threadline/operator_surface/live/timeline_live/changes.ex` | 4568 | `4243ee181de3554c96c66a70e1d866802146af7a1ec823d3965572f25de3fd75` |
| `lib/threadline/operator_surface/live/transaction_live.ex` | 26212 | `0867642c93c2eb15757591d8c200bd86b9c51a27eadee355450c6133d9ff0919` |
| `lib/threadline/operator_surface/script.ex` | 10227 | `168baaa726aa1ab4f846af78bb2f11864e575dc70c1fe17d3aee16c80f47985a` |
| `lib/threadline/operator_surface/style.ex` | 1465 | `cb56338f070d8d3d6f9a9e8577e4ca758e9d44c529aaa6d365efeafa49dae18b` |
| `lib/threadline/operator_surface/style/01_tokens.css` | 12661 | `b0b0c12321d597bb6511aa198564702a6b5fed48b730a729faf8d8cb36fe31c7` |
| `lib/threadline/operator_surface/style/02_base_shell.css` | 9600 | `ccd893da13be8904ed5a83443eae35474c63a0d6d1a0d5e8ad7e259d67f70470` |
| `lib/threadline/operator_surface/style/03_page_home.css` | 10294 | `821646fca888220b700c502c2d877dabed30524d56c1666a93366c8b9cfe0eff` |
| `lib/threadline/operator_surface/style/04_controls.css` | 16229 | `4c19c64a22416310b65a858b33fc52c79e3af22677372da521065569f8786cf3` |
| `lib/threadline/operator_surface/style/05_feedback.css` | 11179 | `5c7a296c888aebc1faced428c891f47ee932209d32c43062d8c6efa6de732930` |
| `lib/threadline/operator_surface/style/06_layout_primitives.css` | 17248 | `00dae71a0081374f1350abfb9290297b977222ddd70e27bd690e7db8c24a9601` |
| `lib/threadline/operator_surface/style/07_find_detail.css` | 12698 | `a18d5ce2487992b2691b88be3e3b291df60884ae28751436f8c8f2b1e430c619` |
| `lib/threadline/operator_surface/style/08_overlays_motion.css` | 18450 | `5a4448dc70d149102f27079288af27d543292f52aa4983a54ac5f3d0a7c8ac52` |
| `lib/threadline/operator_surface/style/09_responsive.css` | 13108 | `6550e3215837fa08e19d7cda11a688c054c879e461f05e575d7de9bd63e2e41c` |
| `priv/fonts/geist-400.woff2` | 12956 | `ead637fd0b6b887d829b3ce3f25fdc242b1de0cfb69c0d97987933675d1315ba` |
| `priv/fonts/geist-500.woff2` | 13296 | `6145bf6706dbc1b6686f04f871489cf724951f00b752745896ccdcac07639a53` |
| `priv/fonts/geist-600.woff2` | 13372 | `edde7cc4e2719898f981a6d970a756030fff75a8ed36dd6a457a60181b889ebf` |
| `priv/fonts/ibm-plex-mono-400.woff2` | 14708 | `08949f728dc52d528e69b1667d15c89a5686a4ee9a296ff90983985f99c380f7` |
| `priv/fonts/ibm-plex-mono-500.woff2` | 14888 | `01d285447409c8a588692162439a038b8cbd7871309ee20267b0d2d91c6e8e22` |

## Custody and Next Proof

The live listener, database, partition, materialization, canonical before half, source map and binary outputs remain parent-owned. The app was not restarted or stopped by this executor, and the pair database was not reset, migrated or reseeded. The strengthened `check-before` command passed twice, including after the final receipt-validation changes. The after half is still pending; the next rendered slice must preserve this same selected materialization and prove its after capture separately. A source digest or screenshot alone does not establish same-data behavior.
