# Threadline 1.x stability policy

<!-- STABILITY-01 -->

## What can change in a 1.x upgrade?

Threadline's 1.x Elixir API follows Hex semantic versioning. A deprecated public
function remains a functioning, fully specced delegate throughout 1.x; removal
will happen no earlier than 2.0. Read each deprecation notice and the
`CHANGELOG.md` before upgrading.

The database contract is additive across 1.x: Threadline may add tables,
columns, and indexes, but does not remove or rename them. Generated capture
trigger-function names and the transaction-local `threadline.actor_ref` setting
remain stable. A 1.x minor may require trigger regeneration only for a
security- or correctness-critical fix; the release notes will call out that
requirement. See [the upgrade path](upgrade-path.md),
`lib/threadline/capture/primary_key_sql.ex`, and
`test/threadline/capture/trigger_pk_shapes_test.exs` for the migration and
key-shape evidence.

The documented `threadline_operator_surface/2` router macro, its documented
options, and its documented mount routes are public integration contracts.
Rendered HTML, CSS, and LiveView internals are not public API. See the
[operator-surface contract](operator-surface.md) and its
`test/threadline/operator_surface/router_test.exs` coverage.

For the 0.12.x line, security and correctness fixes are backported for six
months after the 0.12.0 release. After that window, upgrade to a supported line
for those fixes.

## Typespec changes

Public option `@type` names are stable and option lists are additive. A spec
change that does not change runtime behavior may ship in a minor or patch
release, with a `CHANGELOG.md` note. If a narrower type can cause Dialyzer
warnings for existing callers, the release notes will call that out.
See the Phase 234 D-51 policy in
`.planning/phases/234-typespec-and-doc-completion-gate/234-CONTEXT.md`.

## Operator implementation boundary

The macro, its documented options, and the documented routes are the supported
mount surface. HTML structure, CSS selectors, and LiveView implementation
details may change within 1.x. Hosts should integrate through the macro and
follow [the operator guide](operator-surface.md), not depend on rendered markup.

## Next steps

- [Check the supported table shapes before installation](supported-tables.md).
- [Review the upgrade path](upgrade-path.md).
- [Return to Getting Started](getting-started-saas.md).
