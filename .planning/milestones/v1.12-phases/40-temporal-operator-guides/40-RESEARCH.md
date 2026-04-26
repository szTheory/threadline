# Findings

- `guides/domain-reference.md` already works as a hub doc: it uses short topical sections, cross-links to deeper playbooks, and keeps operator-facing details in one place (`# Exploration API routing`, `# Support incident queries`, `# Brownfield continuity`) [VERIFIED: /Users/jon/projects/threadline/guides/domain-reference.md:177-205].
- The current as-of contract is narrow and explicit: `Threadline.as_of/4` returns `{:ok, map}` by default, `{:error, :deleted_record}` for deleted snapshots, `{:error, :before_audit_horizon}` for genesis gaps, and `cast: true` opt-in returns structs or `{:error, {:cast_error, _}}` [VERIFIED: /Users/jon/projects/threadline/lib/threadline/query.ex:216-257; /Users/jon/projects/threadline/test/threadline/query_test.exs:93-168].
- The example app already teaches by workflow, not by API dump: `examples/threadline_phoenix/README.md` walks through install, audited HTTP, incident drill-down, correlation, jobs, and tests in separate sections [VERIFIED: /Users/jon/projects/threadline/examples/threadline_phoenix/README.md:32-161].
- ExDoc and Phoenix both favor layered docs: ExDoc supports extra pages/guides and automatic linking, while Phoenix docs separate overview, guides, and how-to material [CITED: https://hexdocs.pm/ex_doc/readme.html; CITED: https://hexdocs.pm/phoenix/overview.html].
- Ecto’s `embedded_load/3` docs match Phase 39’s loose-casting behavior: unknown fields are ignored and invalid values raise, which is exactly the ergonomics story to explain to readers [CITED: https://hexdocs.pm/ecto/Ecto.html#embedded_load/3].

# Recommended Direction

- Put a single `## Time Travel (As-of)` hub section in `guides/domain-reference.md`, adjacent to the existing exploration routing / support query material, instead of creating a separate guide [VERIFIED: /Users/jon/projects/threadline/guides/domain-reference.md:177-205].
- Keep that section compact: define what `as_of/4` is for, show one happy-path example, then a small edge-case table for deleted records, genesis gaps, and `cast: true` [VERIFIED: /Users/jon/projects/threadline/test/threadline/query_test.exs:93-168].
- Expand `examples/threadline_phoenix/README.md` with one short walkthrough section that shows `ThreadlinePhoenix.Post` reconstruction over time, plus a cast example and an explicit “what happens when the row is deleted?” note [VERIFIED: /Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix/post.ex:1-18; /Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix/blog.ex:12-75].
- Use the example README to teach workflow and operator ergonomics; use the domain guide to define semantics and edge cases; avoid duplicating full API reference text in both places [CITED: https://hexdocs.pm/ex_doc/readme.html; CITED: https://hexdocs.pm/phoenix/overview.html].

# Why This Fits Threadline

- Threadline’s docs already separate “what it is” from “how to use it”; this keeps the new time-travel docs aligned with the project’s existing operator-doc pattern [VERIFIED: /Users/jon/projects/threadline/README.md:13-24; /Users/jon/projects/threadline/guides/production-checklist.md:1-85].
- The feature is intentionally small and explicit, so the docs should be equally small and explicit: one API, one default shape, three important edge cases, no extra knobs [VERIFIED: /Users/jon/projects/threadline/.planning/phases/39-reification-schema-safety/39-CONTEXT.md:13-33].
- The Phoenix example already demonstrates real production-shaped flows (`POST /api/posts`, incident drill-down, correlation, jobs), so adding time-travel there reinforces the library’s “copy-pasteable ergonomics” story [VERIFIED: /Users/jon/projects/threadline/examples/threadline_phoenix/README.md:87-161].
- This also matches Elixir/Ecto doc ergonomics: readers should see a canonical snippet, then learn the failure modes and field-loading behavior without reading source [CITED: https://hexdocs.pm/ecto/Ecto.html; CITED: https://hexdocs.pm/ex_doc/readme.html].

# Deferred Ideas

- A separate `guides/time-travel.md` is not needed unless Phase 40’s content outgrows the existing domain-reference hub [ASSUMED].
- Collection-wide `as_of_all/4`, association travel, or richer comparison examples belong to future phases, not this docs pass [VERIFIED: /Users/jon/projects/threadline/.planning/REQUIREMENTS.md:22-32; /Users/jon/projects/threadline/.planning/phases/39-reification-schema-safety/39-CONTEXT.md:89-95].
- A full “API reference” rewrite for `as_of/4` would be redundant with HexDocs and should stay out of the example README [CITED: https://hexdocs.pm/ex_doc/readme.html].
