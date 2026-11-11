# Phase 248 candidate baseline

## Candidate and preservation identities

The current-main planning candidate is branch `agent-v148-admin`, initially at `bd95469c29cfd2cfc86576ad375768d3a0510a95`, descended from current main `d35b9422fb2a83897902c2276cb94ecf5129a5e3`. The actual executor fork and cwd binding are recorded in [248-ISOLATION.json](248-ISOLATION.json). The observed executor started at the exact expected base and tree through the negotiated `orchestrator-worktree` adapter.

The preserved comparison candidate is worktree ID `v146-phase241-orchestrator`, repository-relative path `.claude/worktrees/v146-phase241-orchestrator`, branch `agent-241-01`, HEAD `0f9347f207d9395565faa4a3b0280804c4c14e1b`, tree `2b989aa87d88e6ae43dd6cfd74a7bebe76fb3bb1`. Its merge base with current main is `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`. The 31 retained product/docs/test paths have patch SHA-256 `7bb1328b375ed9c9b656d22785e089831122b002b6892554e8ce476d2b7c9074`; the complete Git status snapshot has SHA-256 `863d6375a0a13223ab4db8b8ed196a8d3ed29cc9a61999f1a065c24c73d2c8d1`. These fingerprints cover the preserved candidate; this plan does not modify it.

Separate candidate material is excluded from the 31-file product/docs/test set and remains in its owning checkout: five tracked `.planning/` changes (including the handoff deletion), `AGENTS.md`, `CLAUDE.md`, untracked planning conventions/research/seed material, and untracked root/example `deps` directories. These are planning, instruction, configuration/history, or dependency artifacts, not retained Admin product edits. The validator compares the exact scoped tracked-path set and also checks the complete status fingerprint so these exclusions cannot silently change during observation.

## Tracer: first retained edit

| Repo-relative path | Dirty candidate blob | Disposition and owner |
|---|---|---|
| `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts` | `2527627c489c46bd7060c5af68e555bde11fd83e` | DEFER — Phase 250 implements and proves theme evidence capture against the accepted accessible preference control. |

The recorded source identity is verified with `git -C <worktree resolved from branch agent-241-01> hash-object -- examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts`. The candidate bytes produce the blob above. The phase-local validator rechecks this trace, the candidate patch/status fingerprints, candidate ancestry and the actual executor binding without changing either worktree.

## Approved brand source identity

These are the approved imported source files. Their current checkout Git blob IDs are recorded below; the old runtime `brandbook/` consumers remain in place until their owning migrations.

| Repository path | Git blob |
|---|---|
| `brand/BRAND.md` | `deccfab0b0c003390dd959f60821fa4d8bac0cec` |
| `brand/brand.json` | `647f43d817a726894a8f26bd73e74e1add670080` |
| `brand/assets/README.md` | `c24dac3d1a206b49b29224a5cea8d1136b51dd93` |
