# Phase 199 Removal Inventory

These four tracked artifacts were preflighted with `git ls-files`, repository-wide consumer search, and `git log --follow` before literal `git rm --` removal. Git history is the recovery mechanism; no archive copy or tombstone is retained in active HEAD.

| Removed path | Purpose and last meaningful use | Superseding evidence | Full recovery commit |
| --- | --- | --- | --- |
| `.planning/ROADMAP.md.bak` | Stale v1.21 roadmap backup, last changed 2026-05-24 while the scoped-support milestone was active. | Current `.planning/ROADMAP.md` plus the versioned milestone records under `.planning/milestones/`. | `cd6cd4b8442bea5ad3e67739fa93741523d6187f` (`git show cd6cd4b8442bea5ad3e67739fa93741523d6187f:.planning/ROADMAP.md.bak`) |
| `.planning/HANDOFF.json` | Paused direct-work handoff, last changed 2026-08-30 and consumed by Plan 198-41 at execution time. | `.planning/phases/198-green-bringup/198-41-SUMMARY.md`, the historical addendum in `198-41-PLAN.md`, and later Phase 198 terminal evidence. | `60f75f56d32b1e421f8d9817b397e1bd7604acf4` (`git show 60f75f56d32b1e421f8d9817b397e1bd7604acf4:.planning/HANDOFF.json`) |
| `update_roadmap.rb` | Nine-line one-off that replaced the first `**Plans**: TBD`, last used 2026-05-24. | Current roadmap phase records and the GSD roadmap state handlers. | `cd6cd4b8442bea5ad3e67739fa93741523d6187f` (`git show cd6cd4b8442bea5ad3e67739fa93741523d6187f:update_roadmap.rb`) |
| `fix_tests.exs` | One-off multi-file patch, last used 2026-05-29; among its edits it commented out the README operator-support wording assertion. | Current source plus the restored and mutation-proven contract in `test/threadline/readme_doc_contract_test.exs`; `.planning/phases/198-green-bringup/198-04-SUMMARY.md` already identified the script as tracked debris. | `db94c492003e369b0bd39862fb2e4ba84b6f8b64` (`git show db94c492003e369b0bd39862fb2e4ba84b6f8b64:fix_tests.exs`) |

## Preflight Result

- All four exact paths were tracked before removal.
- Repository-wide search found no runtime, CI, Mix-task, or current public-document consumer.
- The only live-input-shaped historical citation was Plan 198-41's `@.planning/HANDOFF.json`; its Phase 199 addendum preserves that execution-time truth and routes present readers to durable evidence.
- The live contract derives tracked files through `git ls-files`, classifies executable and documentation consumers, reports stale citations as `file:line`, and rejects tracked root one-off patch/migration scripts.

## Recovery

Recover an artifact without rewriting history by inspecting the recorded object with its `git show <full-sha>:<path>` command above. If restoration is deliberately authorized later, write the inspected bytes to a newly reviewed path and add a current contract; do not silently revive these stale live paths.
