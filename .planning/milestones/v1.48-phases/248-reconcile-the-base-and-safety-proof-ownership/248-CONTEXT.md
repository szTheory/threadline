# Phase 248: Reconcile the base and safety/proof ownership - Context

**Gathered:** 2026-11-10
**Status:** Ready for research synthesis and planning
**Authority:** `$gsd-autonomous --from 248`, the approved v1.48 proposal and existing mount compatibility policy. No new maintainer decision was needed to carry those decisions forward.

<domain>
## Phase Boundary

Maintain a preserved current-main candidate with traceable brand provenance and a disposition for every retained UI edit. Implement the already approved fail-closed mount correction. Diagnose current root/example dependency advisories and the reported affected-suite failure, apply compatible in-scope remedies, and establish trustworthy affected verification. Requirements: ADM-01 through ADM-04.

This phase establishes prerequisites for later Admin work. It does not redesign screens, migrate the brand runtime, change the support floor, or accept unresolved risk.
</domain>

<decisions>
## Implementation Decisions

### Candidate preservation
- Work from the current-main-based `agent-v148-admin` candidate. Preserve the retained `agent-241-01` checkout and all its unrelated edits.
- Record port/replace/defer for every retained product/docs/test edit; a disposition is not permission to bulk-copy the old diff.
- Keep `brand/BRAND.md`, `brand/brand.json` and `brand/assets/README.md` authoritative. Their import is provenance, not proof that runtime assets have migrated.
- Keep old `brandbook/` consumers until package, docs, components and contracts migrate together in their owning later phases.

### Approved host authorization policy
- A mount must provide `authorize_fn` or the existing explicit unauthenticated acknowledgement. An arbitrary Phoenix pipeline does not establish authorization.
- Reject missing authorization configuration during router compilation, with actionable migration guidance. Keep the explicit acknowledgement deliberate and truthful.
- Preserve host authentication, tenant scope, public module/route/option names, and separate export/coverage/policy/evidence capabilities.
- Demonstrate allowed, denied and misconfigured paths without exposing scoped audit data. Apply this already approved compatibility correction without reopening its policy.

### Advisory and affected-suite evidence
- Refresh issue #61 and #90 evidence against this candidate. Historical required-CI success and screenshots do not establish current safety or behavior.
- Inspect both root and example lockfiles and preserve the existing tiered advisory gate. Prefer compatible targeted remedies; do not raise the support floor or add a runtime dependency as an incidental fix.
- Attribute the suite failure before changing code or retrying. Keep required tests, failure visibility, resource limits and any explicit no-retry instruction intact.
- An unresolved reachable runtime risk blocks its affected acceptance and release paths. An unexplained required-suite failure blocks trustworthy completion claims. Record the owner, consequence and reopen condition; do not relabel unknown evidence as passing.
- If remediation requires a new compatibility/security policy or larger foundation capability, stop the affected path for a consequential decision while continuing independent safe work.

### Execution and verification
- Preserve `workflow.use_worktrees: true`. Use the negotiated GSD adapter and verify the actual executor binding; a planning checkout alone is not executor isolation.
- The active runtime resolves `orchestrator-worktree`. The initial base check could not resolve the default fork reference; the supported local `worktree.set-baseref` remedy sets `worktree.baseRef: head`. The subsequent base check no longer requests degradation. Actual executor creation/binding still needs proof.
- Use named existing verification entrypoints and the smallest checks that observe each acceptance claim; required builds/tests/review and bounded retests are included in phase authority.
- Automate routine verification. Keep records of scope, source identity, results and limitations; no new CI jobs or paid critic loop.

### Agent discretion
- Choose narrow internal implementation details, test placement and artifact structure consistent with the approved policies and current code.
- Synthesize the independent baseline reviews, apply clear compatible remedies, and request input only for a material scope, public-contract, security, cost or irreversible-action decision.
</decisions>

<code_context>
## Existing Code Insights

### Reusable assets
- `lib/threadline/operator_surface/router.ex` and `auth.ex` own the mount guard and mount-time authorization.
- Existing router/auth/export and scoped-read contracts provide negative-path proof; retain their real integration boundaries.
- `bin/verify-deps-audit`, root/example lockfiles and the existing dependency-audit contracts establish advisory policy.
- Existing Flake Detection, test partition and hang diagnostics support attributable suite diagnosis; do not add another runner.

### Established patterns
- Capture, semantics and exploration remain separate. This phase changes host integration and prerequisite proof, not canonical capture persistence.
- Use Phoenix LiveView/HEEx and the existing dev/test-only PhoenixStorybook; no React, speculative Fablebook adapter or duplicate registry.
- Keep passing runtime, database, browser and static evidence distinct.

### Integration points
- Host router mounts, authorization callbacks and scoped reads.
- Root/example dependency resolution and existing required verification.
- The retained candidate reconciliation matrix feeds later phases without implementing their UI changes now.
</code_context>

<specifics>
## Specific Ideas

- Reuse `.planning/research/v1.48-SUMMARY.md`, the approved `milestone-proposal.md` and `milestone-adversarial-review.md` in the dated brand/Admin research directory.
- Three bounded independent reviews cover mount safety, advisory/suite proof, and candidate preservation. Their reports inform implementation plans; they are not execution receipts.
- Package remains 1.1.0. REL-01's original live next-release obligation remains pending. Local verification grants no version bump, merge, publish or risk acceptance.
</specifics>

<deferred>
## Deferred Ideas

- Phase 249 owns the full jobs/scenario/brand-contract map.
- Phase 250 owns runtime brand migration and the first complete investigation; Phases 251–252 own remaining screens/operations/catalog; Phase 253 owns complete inclusive acceptance, docs/package and release readiness.
- Broader restore/transaction-ID, SQL/CSV/PgBouncer and support-floor foundation proposals remain separately queued.
- No new login, white-label, public route, schema, config or telemetry capability is authorized beyond the approved mount policy.
</deferred>
