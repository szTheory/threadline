# Plan 71-01 Summary

## What shipped

- Rewrote [guides/operator-surface.md](/Users/jon/projects/threadline/guides/operator-surface.md) around one canonical `/audit` topology.
- Added the admin-first recipe, the support-read-only variation, first verification steps, and a mounted-workflow parity table.
- Tightened [guides/integration-contracts.md](/Users/jon/projects/threadline/guides/integration-contracts.md) to teach one shared `%{assigns: assigns}` `authorize_fn`, keep `export_authorize_fn` advanced-only, and describe `{:ok, scope}` as opaque host-owned scope.

## Key outcomes

- Docs now teach `pipe_through [:browser, :admin_auth]` plus `authorize_fn` together.
- The support recipe defaults to `exports: false` and avoids claiming page-level or universal scope narrowing.
- Export auth is documented as a separate HTTP boundary with plain-text `403` denial semantics.

## Verification

- `rg -n "support-read-only|exports: false|live_session|403|mix threadline\\.(incident|export|health\\.coverage|policy\\.show)" guides/operator-surface.md`
- `rg -n "%\\{assigns: assigns\\}|export_authorize_fn|host-owned|support_read_only|organization_id|opaque" guides/integration-contracts.md`
