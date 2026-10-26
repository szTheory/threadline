# Operator-surface evidence

This directory owns the repository's committed operator-surface quality evidence.
The design-system ledger is an immutable review input: ordinary tests and CI read it
but never rewrite or accept changed bytes.

`manifest.sha256` records the Git-index-owned evidence entries using paths relative
to this directory, and excludes this README and the manifest itself. Today it holds
one entry, `design-system-ledger.json`. Generated output is never written beneath
this fixture root.

`route-inventory.json` and `source-surface-checklist.json` describe the current
operator route/control surface. They are generic source contracts, not rendered
reference evidence, and are excluded by exact filename from `manifest.sha256`.
Their route/declaration completeness is checked by the operator evidence contracts.
Other newly tracked files remain subject to the rendered corpus manifest.

Maintainers edit the ledger by hand, regenerate `manifest.sha256` from the Git index
(stage the change first), and review the exact diff before committing. The ledger's
`entries` and `screenshot_allowlist` feed the stress lab session and
`operator-stress.spec.ts`.

Nondeterministic local output belongs under the dedicated ignored
`test/generated/operator_surface/` boundary. It must not be copied into or promoted
as canonical fixture evidence.
