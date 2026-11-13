# Package readiness — local candidate, required CI pending

The implementation source is frozen at `4f35334f20fc4c8a89ac46d446b9fbb3b6b46672`. Package version remains **1.1.0**. All required selected local package gates have actual successful receipts; this is neither exact-candidate hosted CI nor release acceptance. Later metadata-only commits do not change the inspected package bytes.

## Observed local gates

| Gate | Actual result | Receipt basename |
| --- | --- | --- |
| Formatting / strict lint | Both exit0 after the bounded mechanical cleanup | format-02; credo-02 |
| Optional-host compile | Exit0 | optional-compile-01 |
| Affected runtime / package / optional / Storybook boundaries | 222 tests,0 failures in one combined invocation | package-boundaries-01 |
| Existing semantic inventory validators | 33 tests,0 failures; negative controls retained | inventory-contract-02 |
| Rendered inventory / fixture / journey / current changelog contracts | 56 tests,0 failures | inventory-doc-contract-02 |
| CI topology / partition admission | 35 tests,0 failures | ci-topology-admission-01 |
| Canonical `mix verify.release` | Clean tracked candidate; release shape,56 tests, strict ExDoc, Hex build all exit0 | release-03 |
| Nested example `mix precommit` | 151 tests,0 failures; compile, unused-lock check and format succeeded | example-precommit-02 |
| Canonical `mix verify.hex_evaluator` rehearsal | Exact local tarball resolved through signed owned loopback registry; consumer compile/migrations and19 tests,0 failures | evaluator-01 |
| Actual served ExDoc page | Threadline Admin heading, preserved mount anchor,42 generated local links and Light/Dark logo hook observed | served-docs-03 |

Full wrapper identities, exits and durations are reconciled in `threadline-253-package-gate-reconciliation.json`. Receipts are private local artifacts; source hashes and actual commands are retained there. Each result applies at its named boundary, not to every test in the repository.

## Archive bytes and exclusions

The canonical release archive was copied before rehearsal rebuilt its own archive. Preserved archive SHA-256 is `03e63300de92f49371aea97841f4dcbce14751c3a39f78a0c748d2000b963f45`. Actual outer members are VERSION, CHECKSUM, metadata.config and contents.tar.gz; the inner archive contains178 files. All ten approved brand assets, including all four WOFF2 files and three licenses, match current source bytes exactly. No `.planning/`, `examples/`, `test/`, historical `brandbook/` or Storybook file is present. See `threadline-253-release-archive-inspection.json`, its complete file list and preserved archive. No pre-change archive was available; source history and the archive-fixture timing comparison are not represented as an old archive comparison.

## Consumer rehearsal and cleanup

The existing canonical rehearsal unlocked only fixture `threadline`, built the current1.1.0 tarball, signed a fresh throwaway registry and resolved the consumer against that registry. Fixture sources/lock were prepared from existing locked local cache; no path dependency substituted for the package. An OS child policy allowed owned loopback and denied external outbound connections; its separate preflight actually rejected an external socket. The consumer used its existing fixed `hex_evaluator_test` database on owned PostgreSQL60025, not the root partition name. The canonical trap removed its registration/server/signing directory/rehearsal cache; post-run observation confirms port60158 closed and rehearsal package cache absent. No global network settings changed.

## ExDoc observation limits

The headless browser served `operator-surface.html`, not only index.html. Existing numeric `1-minute-mount` anchor and42 local link targets resolve. The generated hook changes the actual logo from the approved light asset to the approved dark asset after the body theme changes. Local requests and hashes are retained in `threadline-253-served-docs-observation-v03.json`. External CDN Mermaid requests were deliberately blocked; CDN rendering is unproven. ExDoc requested optional absent `docs_config.js` (404); no successful config load is claimed. This observation does not establish human comprehension or every generated page.

## Preserved failed attempts and remedies

- release-01 used an unnecessary outer dev environment and stopped before tests because test support was unavailable. release-02 executed56 cases with four failures from one missing font-test partition owner; docs/archive were not reached. The existing three inventories now contain one honest6ms admission estimate, rounded from an actual local5.7ms four-case module observation; it is explicitly not a min/latest CI measurement. All previous weights and inventory negative controls remain.
- example-precommit-01 executed151 cases with four replay failures: the existing safety guard correctly rejects the named `p253tests` suffix. A dry diagnostic exposed that refusal. A preflight established numeric25313 database absent on the owned server; the diagnosed retest used the permitted disposable numeric suffix and passed. No guard/source change, ordinary fixture reset or shared server access occurred.
- served-docs-01 had an invalid CSS selector for a numeric anchor;02 observed the page but the diagnostic logo selector selected its parent.03 narrowed the selector and asserted actual Light/Dark image changes. Original receipts are retained.
- Initial strict Credo findings and earlier browser failures remain in the execution records. The consumed full-root repeat was not renewed; no full-root or default browser suite ran here.

## Remaining acceptance

Real desktop200% tab zoom has no successful local result. Default-zoom images, declaration listing, normal headless checks and local package results cannot close it. Existing required Linux CI, its two voting browser projects and journey receipt remain pending at the exact proposed candidate. REL-01 remains pending until its original first natural release event. No merge, version bump, tag, publication, native clipboard, foreground or risk acceptance follows from local readiness. See [CI proposal](253-CI-PROPOSAL.md).
