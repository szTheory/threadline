---
phase: 57-optional-deps-and-module-gating
reviewed: 2026-05-06T00:00:00Z
depth: quick
files_reviewed: 4
files_reviewed_list:
  - lib/threadline/operator_surface.ex
  - mix.exs
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
status: issues_found
---

# Phase 57: Code Review Report

**Reviewed:** 2026-05-06
**Depth:** quick
**Files Reviewed:** 4
**Status:** issues_found (1 INFO; no BLOCKERs, no WARNINGs)

## Summary

Phase 57 ships exactly what its plan promises: four `optional: true` Phoenix/LiveView family deps in `mix.exs`, one `@moduledoc`-only namespace module gated at file scope, a `verify.compile_no_optional` alias folded into `ci.all`, and a dedicated GitHub Actions job mirroring the `verify-format` / `verify-credo` twin convention. Zero behavior, zero new attack surface — and the diff matches that claim.

Quick-depth pattern scans (hardcoded secrets, dangerous functions, debug artifacts, empty catch blocks) are all clean across the four files. Structural spot checks pass:

- `lib/threadline/operator_surface.ex` correctly wraps `defmodule` at file scope on `Code.ensure_loaded?(Phoenix.LiveView)` — this is the Sentry idiom, NOT the elixir-lang/elixir#8970 footgun (no `use Phoenix.LiveView` macros are inside the `if`, the body is documentation-only). The `@moduledoc` heredoc plus separate `@moduledoc since: "0.4.0"` attribute are well-formed; the subdirectory `lib/threadline/operator_surface/` is correctly NOT pre-created (D-06 honored).
- `mix.exs` deps additions are well-formed, version-pinned with single-major constraints (`~> 1.7`, `~> 1.0`, `~> 4.0`, `~> 2.1`), `:plug` stays hard, `application/0` is untouched (Pitfall 3 honored). Alias key style `"verify.compile_no_optional":` matches the surrounding string-key atoms convention. `ci.all` ordering inserts the new step between `compile --warnings-as-errors` and `verify.test` per D-10. `compile --no-optional-deps` is a real Mix flag (`mix help compile` confirms).
- `.github/workflows/ci.yml` adds the new job between `verify-credo` and `verify-test`, uses pinned actions (`actions/checkout@v4`, `erlef/setup-beam@v1`) consistent with the rest of the workflow, calls the named alias (not the raw command) per the OSS DNA "named entrypoints" rule, has no `services:` block (compile-only), and updates the top-of-file job-id contract comment correctly. Job key appears exactly once.
- `CONTRIBUTING.md` adds one row to the stable-job-keys table in the correct position. No formatting or markdown lint issues.

The single finding below is documentation hygiene, not a defect — surfaced because the new gate now runs on every PR but its status as a required check is undocumented.

## Info

### IN-01: Branch protection list (CONTRIBUTING.md) does not mention the new `verify-compile-no-optional` job

**File:** `CONTRIBUTING.md:104-115`
**Issue:** The "Branch protection (maintainers)" section lists seven required checks for `main` (verify-format, verify-credo, verify-test, verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape). The new `verify-compile-no-optional` job is added to the *stable-job-keys table* (lines 56-63) but is not referenced in the branch-protection list, leaving it ambiguous to a maintainer reading this guide whether the new gate is a required check or merely advisory.

The plan (`57-01-PLAN.md`, Task 5 action notes) explicitly defers branch-protection updates as out-of-scope ("the maintainer can add `Compile without optional deps (verify-compile-no-optional)` to that list manually after the first green run if desired (Phase 63 docs work can audit it)"). So the omission is intentional, but it is also undocumented in the SUMMARY's "Deferred Issues" table — the only deferred items listed are downstream phase work, not this doc-staleness item. A future maintainer auditing branch-protection coverage will not know whether the new gate was forgotten or deliberately deferred.

**Fix:** Either (a) add a one-line note in `57-01-SUMMARY.md` "Deferred Issues" recording that the branch-protection list update is deferred to Phase 63, OR (b) add a one-liner under the branch-protection list in `CONTRIBUTING.md` like:

```markdown
> Note: `verify-compile-no-optional` (added in v0.3.x) is advisory until Phase 63 ships the v0.4.0 docs work, which audits the branch-protection set.
```

Option (a) is the minimal fix and keeps `CONTRIBUTING.md` stable; option (b) is more discoverable for an outside maintainer.

---

_Reviewed: 2026-05-06_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: quick_
