# Phase 7 — Pattern map

Analogs for executors planning Hex release work (no new modules).

---

## Release documentation pattern

| New / touched | Role | Closest analog | Notes |
|---------------|------|----------------|-------|
| `CHANGELOG.md` | Release notes | `.planning/phases/06-ci-on-github/06-CONTEXT.md` tone for factual bullets | Keep a Changelog + ISO date; no empty `###` shells (07-CONTEXT D-01). |
| `mix.exs` `@version` | SemVer source of truth | Current `@version "0.1.0-dev"` | Flip to `"0.1.0"` only on release commit. |

---

## Plan document pattern

| Artifact | Analog |
|----------|--------|
| Executable plan | `.planning/phases/08-publish-main-verify-ci/08-01-PLAN.md` — Threat model table, numbered tasks, Read first, Acceptance criteria, Verification section. |
| Maintainer git steps | Same file — Task 2 push pattern; **no** `--force` language. |

---

## Excerpt: `doc_source_ref/0` (release behavior)

From `mix.exs`:

```elixir
defp doc_source_ref do
  case Version.parse(@version) do
    {:ok, %Version{pre: []}} -> "v#{@version}"
    _ -> "main"
  end
end
```

When `@version` is `"0.1.0"`, ExDoc `source_ref` and package Changelog link use **`v0.1.0`** — tag must exist on GitHub for those URLs to resolve.

---

## PATTERN MAPPING COMPLETE
