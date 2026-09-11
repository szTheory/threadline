# Operator-surface evidence

This directory owns the repository's committed operator-surface quality evidence.
The ledger, scorecards, golden sets, and refute set are immutable review inputs:
ordinary tests and CI read them but never rewrite or accept changed bytes.

`manifest.sha256` records the Git-index-owned evidence entries using paths relative
to this directory. It includes `critic-scores/.gitkeep` and excludes this README,
the manifest itself, and all ignored generated critic-score output.

Maintainers regenerate canonical evidence only through the named commands that own
it, then review the exact diff before committing:

- `mix verify.capture` regenerates committed Tier A scorecards.
- `mix critic.synth` regenerates the synthetic golden oracle atomically.
- `mix critic.measure` updates the ledger's critic-trust blocks atomically.
- `npm --prefix examples/threadline_phoenix/e2e run critic:check` validates critic inputs without paid scoring.

Generated critic scores belong under `critic-scores/`, are ignored by Git except
for `.gitkeep`, and must not be promoted into committed evidence accidentally.
