# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Elixir application developers are Threadline's primary adopters. They integrate
auditing into an existing Ecto/PostgreSQL application and need confidence that
the installation captures the intended tables and preserves useful context.

Engineers and support/on-call operators have equal priority in the operator UI
(confirmed by the maintainer on 2026-10-08). Both need familiar investigation
flows. Support users should be able to understand what happened without reading
implementation details; engineers must still be able to reach exact identifiers,
timestamps, field values, diffs and diagnostic evidence.

Platform engineers and DBAs inspect capture coverage and operational health.
Security reviewers inspect redaction, retention and available evidence.
Authorized administrators manage the operations allowed by their host
application. These roles are product audiences, not a new built-in role model.

## Product Purpose

Threadline is an open-source audit platform for Elixir teams using Ecto and
PostgreSQL, with optional Phoenix/LiveView integration. It captures row changes
through PostgreSQL triggers and connects them to application-level actions,
actors, reasons and execution context when supplied.

Its core value is durable capture of relevant row mutations without requiring
developers to remember a special write call for every change. Operators use the
result to answer who changed what, when and why, while seeing the limits of the
recorded evidence. Correct capture depends on installing the generated triggers
for the intended tables; missing context or coverage must remain visible.

Success means an adopter can establish capture reliably, an operator can follow
and explain a change, and an authorized maintainer can act on operational
findings with accurate context and predictable controls.

## Positioning

Threadline combines trigger-backed row capture, semantic application actions,
and practical investigation/operations surfaces. Audit data remains queryable
with SQL and integrates with the host application's Elixir ecosystem.

It is not event sourcing, a SIEM, a pgAudit replacement or a data warehouse.
Audit visibility does not by itself establish regulatory certification,
immutability, complete business causality, or complete capture coverage.

## Operating Context

The library runs inside a host application. The host owns authentication,
authorization, tenancy/scope, layouts and application policy. Threadline supplies
the audit capture and integration contracts and an optional operator surface.
Phoenix and LiveView remain optional dependencies for the root package.

Common operator jobs:

- Find a change by time, table, actor or correlation; inspect its transaction and
  before/after values; follow related actor activity or row history.
- Recover an investigation through its URL or saved view, then export its
  supported evidence while preserving scope.
- Inspect schema-specific capture gaps and obtain migration remediation guidance.
- Compare redaction configuration with deployed trigger policy and inspect
  available evidence and retention history.
- Follow queued exports and completed downloads; inspect failed operations and
  perform an authorized retention prune with explicit confirmation.

The example Phoenix host mounts the operator surface at `/audit`. Other hosts
choose their mount. Direct links, reloads, browser navigation and operation in
an existing application are part of the experience, not only entry from a demo
landing page. Operators may be investigating under time pressure on narrow
screens or with keyboard navigation.

## Capabilities and Constraints

Keep the three layers distinct:

- Capture owns audit transactions, row changes, trigger registration and integrity.
- Semantics owns application actions, actor references, intent and execution context.
- Exploration/operations owns investigation, diffs, as-of reads, exports, coverage,
  retention, redaction inspection, health and telemetry.

Canonical language:

| Term | Meaning |
| --- | --- |
| AuditTransaction | Groups changes from one database transaction; it is not a request |
| AuditChange | One captured row mutation |
| AuditAction | An application-level semantic event; it is not interchangeable with a change or transaction |
| AuditContext | Execution context such as request/job provenance, correlation and route |
| ActorRef | Stable reference to an actor, which may be a person, service, job, system or anonymous actor |
| Correlation | Connects related records across execution boundaries without inventing causality |

Use the domain's nouns consistently in navigation, controls, feedback and docs.
Distinguish unknown from empty, redacted from missing, pruned from unavailable,
and an accepted operation from a completed result. A zero count is not proof of
healthy capture. Preserve exact identifiers, timestamps and evidence values even
when their primary presentation is compact.

Server authorization and tenant scope remain authoritative. UI controls must
reflect those boundaries; redacted data must not be exposed through alternate
presentation, copying or export paths that promise masking. Generated capture
triggers are installed through host-owned Ecto migrations.

Capture supports more table shapes than every UI path: the current row-history
route accepts one scalar primary key. Do not imply that composite-key capture
automatically provides composite-key navigation. Public API/route expansion and
new backend capabilities need a deliberate scope decision.

## Brand Commitments

The existing Threadline identity and `prompts/Threadline Brand Book.txt` provide
the brand authority. The current request is refinement of that established
identity and supported operator experience.

The voice is a calm, precise, helpful senior engineer. Use plain, task-oriented
language, sentence-case labels and specific, actionable errors. Avoid marketing
filler, invented assurance and unnecessary internal terminology. Distinguish
actions, changes and transactions even when simplifying their presentation.

Visual recipes, token values and surface compositions belong in the inspected
design record and their owning source files, not in this product record.

## Evidence on Hand

- `prompts/audit-lib-domain-model-reference.md`: domain language, boundaries,
  personas and intent; distinguish its aspirations from implemented capability.
- `prompts/threadline-elixir-oss-dna.md`: engineering and verification conventions.
- `prompts/Threadline Brand Book.txt`: established identity and editorial guidance.
- `lib/threadline/operator_surface/`: current operator components, presentation,
  routes, styles and behavior.
- `examples/threadline_phoenix/`: runnable host, deterministic demonstration data,
  Storybook/stress surfaces and connected browser workflows.
- `guides/local-docker-dx.md`: the `bin/demo-up` preview lifecycle and printed URL.
- `.planning/UI-MILESTONE-PREFLIGHT.md`: source inventory, sibling-project lessons,
  suspected defects, evidence limits and the prepared UI kickoff.

Historical screenshots and verification artifacts exist. They are not a fresh
visual baseline for the current application. Bind new captures to the actual
source, served assets, fixture, route/state, scope, theme and browser conditions.
No customer endorsements, measured usability gains or certification claims have
been supplied as product evidence for this work.

## Product Principles

1. Protect audit truth: preserve recorded evidence and make its limitations clear.
2. Support both ordinary investigation and expert inspection through familiar
   controls, consistent terminology and deliberate disclosure.
3. Make integration composable: respect host ownership and keep the three layers
   understandable and separate.
4. Build consistency through existing shared primitives, while choosing each
   representation to suit the user's job.
5. Verify actual behavior and rendered results in bounded passes. Automate routine
   verification; maintainer feedback refines taste rather than replacing tests.

## Accessibility & Inclusion

The maintainer requires responsive, readable interfaces with complete happy,
error and boundary states. Keyboard and pointer operation, touch access, focus
visibility and return, meaningful labels, reduced motion and usable magnification
belong to the supported experience.

Do not rely on color or hover alone to communicate status or expose essential
evidence. Full identifiers and values must remain reachable at narrow widths and
browser zoom. Reflow and real browser zoom need separate verification. Existing
light, dark and System preferences must remain usable and accurately represented.
Automated results must state the browser/device coverage actually exercised;
this record makes no blanket accessibility certification claim.
