## Deferred Items

- `mix ci.all` stops at `verify.repo_hygiene` because all five existing Phase 235 plan files contain machine-local home-directory `.codex/gsd-core` references. These planning inputs predate the 235-05 implementation and are outside its declared implementation files.
  status: open
  **What:** Replace the machine-local references with repository-safe placeholder forms and rerun the phase-level gate before Phase 235 verification.
