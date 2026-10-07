## Deferred Items

- The Phase 235 plan files originally contained machine-local home-directory `.codex/gsd-core` references. They were changed to `$HOME`-relative references; `mix verify.repo_hygiene` and the final canonical CI gate pass.
  status: resolved
  **Resolution:** Replaced the five machine-local paths with portable `$HOME`-relative paths, updated stale contract expectations and the generated example fixture, and reran canonical `mix ci.all` successfully.
