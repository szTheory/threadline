# Research Summary: Threadline v1.19 Integration Breadth

**Summarized:** 2026-05-07
**Scope:** Broaden host/framework adoption for Threadline without weakening the auth-agnostic core or forcing a premature `threadline_web` split.

## Recommended milestone posture

- **No new required runtime deps** in `threadline`
- **Keep Phoenix/LiveView optional and in-tree** for now
- **Broaden adoption through adapter contracts, mount recipes, and example parity**
- **Treat `threadline_web` as an extraction-readiness decision**, not as the milestone premise
- **Keep retention admin, saved views, queued exports, and mutable policy UI out of v1.19**

## Stack additions

- No new hard deps in core
- Keep current optional web deps posture:
  - `phoenix ~> 1.7`
  - `phoenix_live_view ~> 1.0`
  - `phoenix_html ~> 4.0`
  - `phoenix_pubsub ~> 2.1`
- Keep `verify.compile_no_optional` as a release gate
- Treat Sigra as a **host adapter target**, not a library dependency
- Refresh stale example/docs pins to the current supported Sigra line and state any Phoenix-version caveats explicitly

## Feature table stakes

- Canonical mount recipes for the main host shapes:
  - Plug-only / CLI-only
  - Phoenix admin pipeline
  - support read-only operator surface
- One stable adapter contract for:
  - actor extraction
  - additive context overrides
  - optional dependency behavior
- Example-backed guidance for operator-surface auth in both router pipeline and LiveView mount paths
- A narrow, honest support matrix naming only proven combinations
- An extraction-readiness scorecard for a future `threadline_web` package

## Differentiators worth shipping

- Thin first-party `Threadline.Integrations.*` adapters where they materially reduce host glue
- Resolver-style separation between identity extraction, access checks, and optional scope narrowing
- Copy-paste secure mount packs with CLI fallback parity
- A documented “stay in-tree unless these triggers are true” extraction decision

## Watch out for

- **Auth leakage into core**: no user model, role model, or ownership state in `threadline`
- **Premature `threadline_web` split**: do not extract for aesthetics alone
- **Version-matrix overclaiming**: only promise combinations that CI or compile gates prove
- **UI scope creep**: do not let “integration breadth” turn into saved views, retention admin, or workflow UI
- **Misleading docs/examples**: example apps must be precise about assumptions and proven paths

## Recommended milestone shape

1. Adapter contract and support matrix
2. Concrete host adapter/reference-path refresh
3. Mount recipes and access-tier runbooks
4. Packaging-boundary scorecard and closeout decision

## Expected outcome

v1.19 should end with Threadline easier to adopt across real host setups, clearer about what it supports, and still packaged as a single library with optional web deps. If extraction pressure is still mostly theoretical, the right closeout is **stay in-tree and revisit later with explicit triggers recorded**.
