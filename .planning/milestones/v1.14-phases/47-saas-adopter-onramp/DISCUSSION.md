# Phase 47: Discuss & Architectural Decisions

## Overview
Phase 47 (saas-adopter-onramp) focuses on creating a "getting started" guide (`guides/getting-started-saas.md`) and a staging matrix column (`guides/adoption-pilot-backlog.md`), with strict doc-contract testing to prevent "stale docs" drift against the `examples/threadline_phoenix/` reference application.

## Gray Area: Doc-Contract Extraction Strategy
How do we ensure the Markdown code blocks in `guides/getting-started-saas.md` exactly match the working code in the example app without brittle tests or massive maintenance overhead?

### Options Considered
1. **Specific Markers/Comments (Recommended)**: Use language-agnostic comments (`# doc: start: <anchor>` / `# doc: end: <anchor>`) in the example app's source code to define extractable blocks. A test fixture reads the file, slices by the markers, and asserts the block exists verbatim in the Markdown guide.
2. **AST Parsing (`Code.string_to_quoted`)**: Parse the Elixir source code to AST and extract modules/functions. Clean, but fails completely on non-Elixir files (e.g., JSON) or partial Elixir blocks (e.g., adding a specific plug to a pipeline in `router.ex`).
3. **Regex Extraction (No Markers)**: Use regular expressions to find patterns in source files. Extremely brittle to standard `mix format` whitespace changes, leading to high false-positive failures in CI.

### Rationale for Specific Markers/Comments
To satisfy Phase 47’s strict drift requirements (ADOPT-01/02), a Specific Markers/Comments strategy via a pure file-read fixture module is the most pragmatic choice. Phoenix quickstarts inherently require mixed-language and partial snippets (e.g., specific `router.ex` pipelines or `config.exs` additions). AST parsing fails on these non-pure-Elixir contexts, while marker-less Regex extraction is notoriously brittle. 

By structuring `test/support/getting_started_fixtures.ex` to extract lines bounded by `# doc: start: <anchor>` from `examples/threadline_phoenix/`, and pairing it with an async `test/threadline/getting_started_saas_doc_contract_test.exs` that strictly asserts `String.contains?(guide_markdown, extracted_block)`, any un-mirrored mutation in the example app will instantly fail CI. This establishes a highly visible contract that adheres to the principle of least surprise, maximizes developer ergonomics, and definitively prevents the "stale docs" footgun without fragile regex.

## ADOPT-02 Content Guardrails
For the `adoption-pilot-backlog.md` matrix, we will enforce the placeholder requirement ("ExampleCloud", "GenericPooler") and the explicit `<!-- ADOPT-EXAMPLE-DISCLAIMER -->` banner via a straightforward string match in `test/threadline/stg_doc_contract_test.exs`. No complex AST or block extraction is needed here, just simple regex/string assertions against the markdown content.
