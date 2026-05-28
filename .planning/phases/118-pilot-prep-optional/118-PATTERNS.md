# Phase 118 — Pattern Map

**Phase:** 118-pilot-prep-optional  
**Mapped:** 2026-05-27

## Files to create/modify

| File | Role | Closest analog | Pattern to replicate |
|------|------|----------------|---------------------|
| `guides/adoption-pilot-backlog.md` | PILOT-01 prose | Self (L62–66 PgBouncer contract) | Named entrypoints + CONTRIBUTING pointer; no test counts |
| `guides/evaluating-threadline.md` | PILOT-02 new guide | `guides/upgrade-path.md` | Thin adopter guide; D-117-02g opener; outward links |
| `README.md` | Discovery map | Phase 117 Evidence plane strip | Single bullet + Documentation list entry |
| `mix.exs` | ExDoc + alias SSOT | Phase 117-02 mix.exs edit | Append to `verify.doc_contract` list + `extras` |
| `test/threadline/adoption_pilot_doc_contract_test.exs` | PILOT-01 contract | Phase 117 semver contracts | Literal asserts + refutes |
| `test/threadline/evaluating_threadline_doc_contract_test.exs` | PILOT-02 contract | `upgrade_path_doc_contract_test.exs` | Guide existence + locked literals + refutes |
| `test/threadline/readme_doc_contract_test.exs` | README map contract | Existing link tests L40–62 | `assert String.contains?(readme, "guides/evaluating-threadline.md")` |

## Key excerpts

**ci.all order (mix.exs L88–96):**
```elixir
"ci.all": [
  "verify.format",
  "verify.credo",
  "compile --warnings-as-errors",
  "verify.compile_no_optional",
  "verify.test",
  "verify.threadline",
  "verify.example",
  "verify.doc_contract"
],
```

**D-117-02g evaluator sentence (upgrade-path.md L5):**
```
Threadline **0.6.0** packages Evidence, `Audit.transaction/3`, and aligned operator surfaces that landed in-repo after **0.5.0**; upgrade steps are semver-scoped in `CHANGELOG.md` and this guide.
```

**Adoption pilot contract module shape:**
```elixir
defmodule Threadline.AdoptionPilotDocContractTest do
  use ExUnit.Case, async: true
  @guide "guides/adoption-pilot-backlog.md"
  @version Threadline.MixProject.project()[:version]
  # version SSOT tests...
end
```

## Do-not-duplicate

- `ci_topology_contract_test.exs` — owns `ci.all` **ordering** asserts
- `stg_doc_contract_test.exs` — owns STG marker strings in adoption-pilot-backlog
- `semver_adopter_doc_contract_test.exs` — owns `v1.2x` refutes

## PATTERN MAPPING COMPLETE
