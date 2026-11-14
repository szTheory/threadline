# Phase 249: Map jobs, scenarios and the brand contract - Pattern Map

**Mapped:** 2026-11-11  
**Files analyzed:** 17 existing/inferred phase touch points  
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` | config | transform | Same inventory | exact |
| `test/fixtures/operator_surface/route-inventory.json` | test | batch | `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts` | exact |
| `examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts` | test | batch | Same test | exact |
| `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts` | test | batch | Same test | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex` | config | batch | `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_test.exs` | role-match |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex` | utility | batch | Same module; `accounts/user.ex` changeset pipeline | role-match |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` | service | batch | Same module and `demo_contract_test.exs` | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex` | service | batch | Same module; anchor writes | role-match |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex` | service | batch | `seed/anchors.ex` event timestamp flow | role-match |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/temporal.ex` | service | batch | Same module | exact |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` | test | batch | Same database contract | exact |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_test.exs` | test | batch | Same manifest contract | exact |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` | test | batch | Same documentation contract | exact |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs` | test | batch | Same reset contract | exact |
| `examples/threadline_phoenix/e2e/run-e2e.sh` | utility | batch | `demo_reset_test.exs` and current runner recipe | role-match |
| `examples/threadline_phoenix/DEMO-MANIFEST.md` | utility | transform | `test/threadline_phoenix/demo_manifest_contract_test.exs` | role-match |
| `examples/threadline_phoenix/WALKTHROUGH.md` | utility | transform | `test/threadline_phoenix/walkthrough_doc_contract_test.exs` | role-match |

## Pattern Assignments

### Inventory and route fixture

Keep the semantic inventory as the job/state/action/proof owner; keep the root fixture as structural route data. Do not copy semantic fields into a third registry. The current voting and nonvoting identities are part of the contract and should be preserved while adding route/job mapping.

- `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json:2-6,36-38` has `schemaVersion`, voting project IDs, stable Playwright identity objects, and a reason for nonvoting rows.
- `examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts:71-84` reads this JSON and asserts required journey categories. Extend this contract for semantic links while retaining its existing voting-identity checks.
- `test/fixtures/operator_surface/route-inventory.json:1-20` holds structural `id`, `pattern`, `path`, seed resolution, role, and scope.
- `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts:7-20` independently reads `lib/threadline/operator_surface/router.ex`, checks all eleven LiveView patterns against the fixture, enforces unique IDs, and requires `seedResolution`, `role`, and `scope`. Keep that independent structural check; link semantic entries to it from the semantic inventory.
- Renderer/access examples are in the live router `lib/threadline/operator_surface/router.ex:68-141` and host wrapper `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:111-170,365-378`. Preserve separate auth, capability, and organization-scope facts. Static Storybook renders are not lifecycle or mutation proofs.

### Seed stages and event-time stamping

`examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex:25-46` creates one `ctx` with a `timestamps` map and pipes it through `Personas`, `Exports`, `Anchors`, `Filler`, `Temporal`, then retention stages. Continue using this seed-local context; no public clock option or global clock is needed.

`examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex:12-17` shows the current convention: record an audit transaction UUID and event time in `ctx.timestamps`. `seed/temporal.ex:13-29` later aligns `audit_transactions.occurred_at` and `audit_changes.captured_at`. That post-write pass does not change the business-row JSON already captured by the trigger.

`seed/anchors.ex:63-90,93-134,136-184` is the closest event-story analog: it runs HelpDesk writes, captures transaction IDs, then assigns represented occurrence times. `seed/filler.ex:66-99` is the closest ordinary filler write. Stamp existing business timestamp fields on the changeset before `Repo.insert!/update!`, and keep the existing transaction clock map for audit timestamps. Do not alter public HelpDesk signatures or transaction boundaries.

There is no existing tracked seed helper that stamps Ecto timestamps before capture. The nearest tracked changeset idiom is `examples/threadline_phoenix/lib/threadline_phoenix/accounts/user.ex:70-80` (`put_change/3` in a changeset pipeline). `examples/threadline_phoenix/lib/threadline_phoenix/help_desk/ticket.ex:9-25` confirms `closed_at` plus Ecto `inserted_at`/`updated_at` fields. Add only a small private seed helper in `seed/support.ex`; keep `AuditAction.inserted_at` as recording time and `AuditContext` unchanged.

`manifest.ex:62-74` owns the fixed epoch, calendar anchor, and stable fixture IDs. Its test is `demo_manifest_test.exs:10-40`. Align dependent export/example dates and exact contracts to the corrected calendar day; do not regenerate stable UUID/persona/ticket/correlation/evidence keys.

### Database and command contracts

`examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:17-23` resets once in setup under `Sandbox.unboxed_run/3`. Existing capture-boundary assertions query `AuditChange.data_after` at lines 73-105; event ordering and represented timestamps belong in this DB contract, with both persisted business rows and trigger snapshots asserted. The #4518 actor distinction at lines 162-187 is an existing closer/deleter control.

For reset semantics, reuse `demo_reset_test.exs:44-85`; `demo_contract_test.exs:191-242` covers repeated reset and the current reset-then-seed “does not raise” check, which must not be described as direct-seed idempotence. `demo_manifest_contract_test.exs:39-48` already pins the documented reset/seed recipe. The E2E runner has adjacent duplicate setup commands at `examples/threadline_phoenix/e2e/run-e2e.sh:432-434`; keep only `mix demo.reset` there and align docs/contracts together.

`DEMO-MANIFEST.md` and `WALKTHROUGH.md` contain the calendar examples; their existing contract owners are `demo_manifest_contract_test.exs` and `walkthrough_doc_contract_test.exs`. Preserve the retention-tail boundary and its existing purge tests rather than using the mass-backdated organization as an ordinary scenario.

## Shared Patterns

- **Proof ownership:** source contract, LiveView lifecycle, database, mounted browser, accessibility, and visual proofs are separate evidence kinds. Inventory rows point to current owners; they are not fresh run receipts.
- **Seed chronology:** changeset business times are captured at write time; `Temporal` only aligns audit transaction/change clocks afterward. Maintain both representations and test their relationship.
- **Data ownership:** `brand/BRAND.md`, `brand/brand.json`, and `brand/assets/README.md` remain the only brand authority. Reference stable role IDs/assets from the inventory/crosswalk; do not add token values, hashes, ratios, or a second asset registry.
- **Runtime boundary:** PhoenixStorybook stays in example/dev/test and production renderers remain LiveView/HEEx. Do not introduce framework, dependency, public API, or compatibility changes.

## Focused Test Commands

Commands are locators only; no tests or services were run for this mapping.

- From repository root: `mix test test/threadline/operator_surface/operator_evidence_contract_test.exs`
- From `examples/threadline_phoenix`: `mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo_manifest_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs test/threadline_phoenix/demo_reset_test.exs`
- From `examples/threadline_phoenix/e2e`: `./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts`

## Environment and Metadata

All analog paths above were confirmed by `git ls-files`; no ignored install mirror is cited. The example `deps/`, `_build/`, and E2E `node_modules/` directories are absent in this checkout; both `examples/threadline_phoenix/mix.lock` and `examples/threadline_phoenix/e2e/package-lock.json` are tracked. Cached Hex package archives are present on the host, but the locked dependencies are not unpacked into the project. No install, database service, or test command was run.

**Analog search scope:** current route/inventory tests, seed stages and helpers, and demo database/manifest/reset contracts.  
**Files scanned:** 17 phase touch points; representative analogs only.  
**Pattern extraction date:** 2026-11-11
