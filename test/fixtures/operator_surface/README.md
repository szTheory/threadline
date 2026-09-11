# Operator-surface evidence

This directory owns the repository's committed operator-surface quality evidence.
The ledger, scorecards, golden sets, and refute set are immutable review inputs:
ordinary tests and CI read them but never rewrite or accept changed bytes.

`manifest.sha256` records the Git-index-owned evidence entries using paths relative
to this directory. It includes the historical `critic-scores/.gitkeep` evidence entry
and excludes this README and the manifest itself. The complete 427-file tracked corpus
stays immutable; generated output is never written beneath this fixture root.

Maintainers regenerate canonical evidence only through the named commands that own
it, then review the exact diff before committing:

- `mix verify.capture` regenerates committed Tier A scorecards.
- `mix critic.synth` regenerates the synthetic golden oracle atomically.
- `mix critic.measure` updates the ledger's critic-trust blocks atomically.
- `npm --prefix examples/threadline_phoenix/e2e run critic:check` validates critic inputs without paid scoring.

Nondeterministic route scorecards, critic scores, verdict caches, reports, and refute
transcripts belong under the dedicated ignored `test/generated/operator_surface/`
boundary. They must not be copied into or promoted as canonical fixture evidence.
