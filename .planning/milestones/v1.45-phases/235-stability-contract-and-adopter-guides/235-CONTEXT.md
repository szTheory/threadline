# Phase 235: Stability Contract and Adopter Guides - Context

**Gathered:** 2026-10-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Threadline's 1.x compatibility promise, supported PostgreSQL table shapes, and redaction limits clear to adopters and security reviewers, with executable contracts that fail CI when those statements drift. The scope includes the maintainer-approved addition of migration-time validation for redaction column names: a generated trigger migration must reject nonexistent `mask:` or `exclude:` columns before trigger installation. It does not broaden into operator UI design, event sourcing, or a general redaction redesign.

</domain>

<decisions>
## Implementation Decisions

### Stability and persistence contracts

- **D-01 — Carry forward the settled 1.x stability policy; do not reopen it.** `guides/stability.md` must explain the Elixir API tier and 1.x deprecation policy; the additive-only database contract for tables, columns, indexes, trigger-function naming, and `threadline.actor_ref`; the narrow security/correctness exception that may require trigger regeneration in a 1.x minor; the operator-surface boundary (HTML/CSS/LiveView internals are not API, while the router macro, options, and documented mount routes are); and the six-month security/correctness backport window for 0.12.x. It must also carry Phase 234 D-51: option `@type` names are stable and option lists are additive; runtime-neutral spec changes are minor or patch with a changelog note, and any narrowing that may warn Dialyzer users is called out.
- **D-02 — Preserve the stable struct-field subset and additive JSONB promise.** `AuditChange`, `AuditTransaction`, and `AuditAction` each document only their selected stable field subset. Their `t` types may gain fields, but the documented stable subset cannot silently shrink. `data_after`, `changed_fields`, and `changed_from` promise additive keys/shapes; they do not promise byte-stable JSON serialization. Pin each documented field set against `__schema__(:fields)`.
- **D-03 — Treat the database catalog and public sets as distinct contracts.** Use live PostgreSQL catalog assertions for required column names, types, nullability, and shipped indexes on `audit_transactions`, `audit_changes`, and `audit_actions`; use literal pins for `threadline.actor_ref` and the trigger-function naming scheme. Pin CSV/JSON export headers (with and without action metadata), `Health.Finding` codes, each Mix task's accepted flags, and `threadline_operator_surface/2` options and documented routes. Removal or rename must fail; additions must require a deliberate pin update. Prefer these focused assertions over byte snapshots or a production registry created only for tests.

### Supported table shapes

- **D-04 — Make eligibility a pre-install decision aid.** Provide one concise matrix with columns for shape, support status, required conditions, and operational caveat/evidence. Answer whether the adopter can install before requiring them to understand Threadline internals. Cite the exact public option/name and the test or implementation evidence behind conditional claims.
- Cover composite and non-`id` keys and the exact supported key-type conditions; document that `primary_key:` is the override for a table without a primary key and requires the documented exact-set unique index over non-null columns. Cover schema-qualified tables, PostgreSQL's identifier limit and Threadline's safe derived-name behavior, and the `char(n)` padding caveat when key/table configuration changes.
- State plainly that partitioned tables are supported with cloned triggers and the physical leaf relation is recorded; unlogged tables are accepted but can lose captured data on a crash; views are unsupported because capture requires row-level `AFTER` triggers. Do not let a positive status hide its conditions or durability caveat.

### Redaction proof and rollout boundary

- **D-05 — Adopt the maintainer's choice 1 (scope amendment): validate configured redaction columns at migration time.** Generated trigger migrations reject every `mask:` or `exclude:` name absent from the selected table before trigger DDL is installed or replaced. Test both invalid option paths and a valid-column control, including evidence that a rejected migration leaves no partially installed trigger. Database-aware existence validation belongs at migration time, where the table catalog is available; shape-only configuration validation cannot establish column membership.
- **D-06 — Describe exactly when that new check takes effect.** Trigger installation migrations are host-owned. Existing installed trigger definitions are not rewritten by adding validation to source; an adopter with an affected configuration must regenerate and run the trigger migration for that table. The check does not redact or repair already captured rows. Keep the error actionable so the adopter can identify the invalid option/column and table without exposing row data.
- **D-07 — Keep the threat guide proof-led and bounded to tested paths.** For every redaction claim, name the exact property test or health check and the data path it proves. `RedactionLeakPropertyTest` covers the generated per-table trigger path across stored rows/change records, diffs, and exports. `RedactionPolicyPropertyTest` validates policy shape. `RedactionPresenterTest` and `mix threadline.policy.show` compare configured and deployed policy; they do not validate column existence and do not create a health finding. Never present those checks as evidence for a guarantee they do not prove.
- State the residual plaintext locations required by DOCS-02: host source tables, WAL/logical decoding, replication slots, backups, superuser access, rows captured before a rule changed, and host logs. Also explain that Threadline cannot control copies made downstream from exports. Qualify every guarantee by its path, timing, and evidence; do not use unscoped absolutes.
- Keep the guide scoped to generated per-table trigger capture. The global redacted `TriggerSQL.install_function` path is not emitted by `gen.triggers`; direct `TriggerSQL.create_trigger/3` use can also bypass the generated path's redacted-primary-key guard. Neither path is covered by this migration-specific fix or by `RedactionLeakPropertyTest`; do not imply otherwise. Track both as separate follow-up gaps.

### Reader experience and engineering ergonomics

- **D-08 — Organize around three reader jobs, not implementation modules.** The stability guide answers “what can change in a 1.x upgrade?”; the table-shapes guide answers “will this table work before I install?”; the redaction guide answers “what is protected, what proves it, and where can plaintext remain?” Keep each claim near its evidence and use the domain nouns consistently.
- Use direct, answer-first headings, short qualified statements, minimal examples, and links to the canonical guide/test rather than copying long install instructions. Use the current Threadline Brand Book voice: precise, composed, clear, and calm. Explain backend details only where they change an adopter's installation or a security decision.
- This phase has no user-facing operator UI. Apply documentation accessibility through readable structure, descriptive links, explicit conditions, and examples that do not rely on color or screenshots; dark/light styling, hover/focus states, and graphic motifs do not apply here.
- **D-09 — Keep contract tests durable and attributable.** Prefer narrow tests with named fixtures and literal expected sets. Keep mutation controls for removal/rename and document-claim drift where they materially prove the gate. Reuse existing contract-test patterns; do not add a generic framework or hidden-test bypass. Continue to use named `mix verify.*` / `mix ci.*` entrypoints in contributor-facing instructions.

### the agent's Discretion

- Exact guide filenames/heading hierarchy where requirements do not already lock them; exact phrasing and error text; test module/file grouping; whether shared assertions live in an existing contract test or a focused sibling; and plan/wave split.
- Implement catalog validation in the existing migration-time SQL path that best matches the established code. Preserve the public host-owned migration boundary and avoid application-startup checks.
- Choose exact examples and evidence-link format. Keep examples executable against supported current APIs and avoid duplicating the README's golden install path.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope, prior decisions, and requirements
- `.planning/ROADMAP.md` § Phase 235 — phase goal and five success criteria.
- `.planning/REQUIREMENTS.md` § CONTRACT-01–05 and DOCS-01–02 — explicit acceptance conditions, including the approved DOCS-02 amendment recorded during this discussion.
- `.planning/PROJECT.md` — project constraints, architecture, and zero-human-verification default.
- `.planning/phases/234-typespec-and-doc-completion-gate/234-CONTEXT.md` § D-49–D-51 — spec semver, stable-field handoff, and 1.x option type/additivity promises.
- `.planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-CONTEXT.md` — established API and documentation contract patterns.
- `.planning/milestones/v1.44-phases/227-db-backed-property-tests/227-CONTEXT.md` § PROP-04, D-10–D-13, Deferred Ideas — redaction proof coverage, fail-open column-name gap, global-function deferral, and direct-trigger guard gap.

### Product, language, and OSS engineering direction
- `AGENTS.md` — three-layer architecture, domain vocabulary, build conventions, and research/recommendation rule.
- `prompts/audit-lib-domain-model-reference.md` — entity language, bounded contexts, personas/JTBD, and anti-patterns.
- `prompts/THREADLINE-GSD-IDEA.md` — original product goals and first milestone intent.
- `prompts/threadline-elixir-oss-dna.md` — CI, doc contracts, examples, release hygiene, and audit-adjacent engineering habits.
- `prompts/Threadline Brand Book.txt` — current brand promise, audiences, voice, and trust cues; this supersedes older brand references.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — product and ecosystem framing.
- `prompts/prior-art/SOURCE-CANONICAL.md` — canonical source map for prior-art research.
- `prompts/prior-art/oss-deep-research/elixir-best-practices-deep-research.md` — Elixir design and library conventions.
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md` — Ecto schemas, changesets, and migration conventions.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — Hex library API and adopter DX practices.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — CI and release practices for Elixir OSS.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — composable Plug/Ecto/Phoenix boundary guidance.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` — Phoenix conventions.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LiveView conventions; useful context though UI work is deferred.
- User's discussion brief in this conversation — broader DX, least-surprise, domain/JTBD, and expert-lens criteria. No literal `prompt.txt` exists in the repository; this inline brief and the prompt files above are the applicable source material.

### Code and test evidence for planning
- `lib/threadline/capture/primary_key_sql.ex`, `lib/threadline/capture/trigger_capture_config.ex`, `lib/threadline/capture/trigger_sql.ex`, `lib/threadline/capture/redaction_policy.ex`, `lib/threadline/capture/migration.ex`, and `lib/threadline/storage_schema.ex` — migration-time validation, trigger configuration, naming, key support, and catalog behavior.
- `test/threadline/capture/trigger_migrate_time_errors_test.exs`, `test/threadline/capture/trigger_pk_shapes_test.exs`, and `test/threadline/capture/trigger_pk_override_test.exs` — migration failures, key shapes, and overrides.
- `test/threadline/capture/redaction_leak_property_test.exs`, `test/threadline/capture/redaction_policy_property_test.exs`, and redaction presenter/health tests — exact current redaction evidence boundary.
- `test/threadline/storage_schema_migration_contract_test.exs` and `test/threadline/telemetry_registry_contract_test.exs` — reusable schema and explicit-set contract patterns.

### External primary/practice references surfaced during research
- PostgreSQL documentation: `https://www.postgresql.org/docs/current/trigger-definition.html`, `https://www.postgresql.org/docs/current/sql-createtrigger.html`, `https://www.postgresql.org/docs/current/sql-syntax-lexical.html`, `https://www.postgresql.org/docs/current/logicaldecoding.html`, `https://www.postgresql.org/docs/current/warm-standby.html`, `https://www.postgresql.org/docs/current/continuous-archiving.html`, `https://www.postgresql.org/docs/current/role-attributes.html`, and `https://www.postgresql.org/docs/current/runtime-config-logging.html` — trigger behavior, identifier limits, and plaintext locations.
- Diátaxis, `https://diataxis.fr/` — task-oriented documentation structure.
- OWASP Threat Modeling Cheat Sheet, `https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html` — explicit threat boundary and evidence.
- Carbonite (Elixir), `https://github.com/bitfo/carbonite` — adjacent trigger-backed audit implementation for comparative lessons, not a contract source.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PrimaryKeySQL.redaction_check_sql` — existing migration-time SQL validation pattern to examine for the column-existence guard.
- `TriggerMigrateTimeErrorsTest`, `TriggerPKShapesTest`, and `TriggerPKOverrideTest` — migration and eligibility test patterns.
- `RedactionLeakPropertyTest` — strongest existing generated per-table trigger-path evidence; its exact surface boundary must remain explicit.
- `StorageSchemaMigrationContractTest` and `TelemetryRegistryContractTest` — patterns for explicit DB and public-set contracts.

### Established Patterns
- Host-owned Ecto migrations install generated PostgreSQL triggers; capture remains SQL-native and trigger-backed.
- Policy-shape validation is currently application/config-level; checking actual table columns requires the database catalog at migration time.
- Current key checks support composite and non-`id` keys only under the accepted PostgreSQL key types; overrides have explicit unique-index constraints.
- Existing docs and tests use named canonical verification entrypoints and executable doc contracts. Avoid introducing a generic test registry.

### Integration Points
- Column existence validation belongs before trigger creation in the generated migration path under `lib/threadline/capture/`.
- The redaction guide contract must distinguish a configured policy from the SQL actually deployed, and describe the timing of host migration regeneration.
- Stability claims cross `guides/stability.md`, schema moduledocs, migration/catalog tests, public allowlist contract tests, and `REQUIREMENTS.md`.
- Supported-table claims cross the capture key/config modules, migration errors, and the pre-install guide contract test.

</code_context>

<specifics>
## Specific Ideas

- Research recommendation is one cohesive, proof-led package: lock the 1.x promises already decided; test persistent schema facts from PostgreSQL's catalog; use explicit allowlists for public surfaces; qualify every table/redaction claim with its conditions; and fail closed on misspelled redaction columns at migration time.
- Alternatives considered for the misspelled-column gap: document the existing fail-open behavior and defer code, or add migration-time validation. The maintainer chose option 1 because a documentation-only warning leaves a typo capable of storing plaintext while presenting a redacted-looking value.
- Prior art lessons: Carbonite demonstrates the value of direct SQL/trigger-based audit capture but is comparative only; Elixir ecosystem conventions favor composable host-owned migrations, explicit option errors, named verification aliases, and small testable contracts. Diátaxis and OWASP support separate task and threat-model reading paths.
- Research did not find a need for a UI/graphic design contract: Phase 235 changes adopter-facing prose and developer contracts, while operator UI work is explicitly parked until after 1.0.0.

</specifics>

<deferred>
## Deferred Ideas

- Exercise or remove the global redacted `TriggerSQL.install_function` path separately; `gen.triggers` does not emit it, so it is outside the selected migration guard and current redaction property proof.
- Close the direct `TriggerSQL.create_trigger/3` redacted-primary-key guard bypass in separately scoped work.
- Revisit causal ordering for `audit_changes`, capture fidelity for `numeric`/`timestamptz`, redaction history cleanup, retention, RLS, partitioning policy, and operator UI only when their owning requirement/phase calls for them.
- No repo-local `prompt.txt` was found. The user's inline prompt plus the current Threadline brand book and prompt/prior-art files are the applicable references.

</deferred>

---

*Phase: 235-Stability Contract and Adopter Guides*
*Context gathered: 2026-10-06*
