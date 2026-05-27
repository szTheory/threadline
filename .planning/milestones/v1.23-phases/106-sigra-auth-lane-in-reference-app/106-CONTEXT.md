# Phase 106: Sigra Auth Lane in Reference App - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire real Sigra signup/login/session in `examples/threadline_phoenix/` only. Replace faked `conn |> assign(:current_user, …)` browser auth with host-owned Sigra sessions. Expose `is_admin`, `role` (`:agent | :support`), and `organization_id` (help-desk org UUID string) on `current_user` so existing `/audit` mount, `my_authorize_fn`, `scope_operator_query`, and API `Threadline.Integrations.Sigra` paths work end-to-end without changing router authorization semantics beyond auth-pipeline wiring.

Requirements: AUTH-01, AUTH-02, AUTH-03, AUTH-04. `lib/` is read-only unless sub-phase **106b** opens for a proven `Threadline.Integrations.Sigra` contract gap.

</domain>

<decisions>
## Implementation Decisions

### Workspace provisioning on signup (D-106-01)

- **D-106-01a:** Add **`HelpDesk.provision_default_workspace_for_user(user_id, opts \\ [])`** — single `Ecto.Multi` creating `Organization` + `OrgMembership` + `Agent` with the same `user_id` string (Sigra-compatible, per Phase 105 D-06).
- **D-106-01b:** Invoke from **Sigra registration success** (after user row exists). Default membership role **`"agent"`** (desk worker without `/audit` until promoted via seed or membership update).
- **D-106-01c:** **`organization_id`** for session and audit meta is **`to_string(organization.id)`** (UUID string) — never slug (Phase 105 D-01a).
- **D-106-01d:** **Idempotent** — if `(organization_id, user_id)` membership already exists, return existing org (safe for Phase 107 `demo.seed` re-runs).
- **D-106-01e:** Phase **107** seeds call the **same** provision helper for Acme/support/admin personas — no second provisioning story.
- **D-106-01f:** **`is_admin`** remains **global** (Sigra admin policy / config allowlist / seed), **not** on `org_memberships` (Phase 105 D-06e).
- **D-106-01g:** Defer: invite/join flows, org switcher, signup form with company name, mirroring Sigra `organizations` tables (avoids dual source of truth and 106b scope creep).

**Rationale:** Identity (Sigra) vs tenancy (help-desk) split matches Sigra field guide, ActsAsTenant/Spark patterns, and Threadline’s host-owned auth boundary. Auto-provision enables `mix ecto.setup` → register → working tenant without seeds; hybrid with 107 seeds gives walkthrough fiction without orphan users.

### Sigra scope → `current_user` bridge (D-106-02)

- **D-106-02a:** New **`ThreadlinePhoenixWeb.OperatorUser`** module: pure **`build_operator_user(scope, session)`** + plug **`:assign_from_scope`**.
- **D-106-02b:** Browser pipeline order on protected routes: `fetch_session` → **`UserAuth.fetch_current_scope`** (Sigra) → `:require_authenticated` (where needed) → **`AssignOperatorUser`** → **`:operator_auth`** (unchanged) → operator mount.
- **D-106-02c:** Mapping contract:

  | `current_user` field | Source |
  |---------------------|--------|
  | `id` | `scope.user.id` |
  | `organization_id` | Help-desk org UUID from `active_organization_id` / `active_organization.id` / `session.active_organization_id` |
  | `role` | `HelpDesk.get_membership_role(user_id, org_id)` → `:agent` \| `:support` |
  | `is_admin` | Sigra global admin policy on **real** user (impersonator when impersonating) |

- **D-106-02d:** **`:agent`** users get a valid `current_user` map; existing **`require_authenticated_operator`** returns **403** (no router change to `my_authorize_fn` / `scope_operator_query`).
- **D-106-02e:** **Recompute on each request** (one indexed `org_memberships` lookup) — do not session-cache full `current_user` in production (revocation / org switch honesty).
- **D-106-02f:** **Impersonation — fail closed on desk roles:** when `scope.impersonating_from` is set, `/audit` uses impersonator’s admin policy for `is_admin`; do **not** grant support scope from impersonated user’s membership. Capture layer may still record `:admin` via `Integrations.Sigra` — surface stays stricter.
- **D-106-02g:** **Do not** extend `lib/threadline/integrations/sigra.ex` for surface auth — API pipeline keeps Sigra adapter only; host owns `/audit` authorization per `guides/integrations/sigra.md`.
- **D-106-02h:** **No changes** to `my_authorize_fn`, `my_export_authorize_fn`, `scope_operator_query`, or `threadline_operator_surface/2` options (AUTH-03).

### Auth UI surface (D-106-03)

- **D-106-03a:** Install via **`mix sigra.install Accounts User users --no-live --no-organizations --no-passkeys --no-admin`** — controller-first auth; **no** Sigra org tables (conflict with help-desk `organizations` / `org_memberships`).
- **D-106-03b:** Bootstrap minimal Phoenix 1.8 HTML stack the app lacks (`--no-html` scaffold): `Layouts`, `core_components` with `<.input>`, Gettext, Swoosh **dev mailbox** for WALK-01 email confirm.
- **D-106-03c:** Ship walkthrough-critical routes only: **register, login, logout**; session persists across reload (Sigra `UserAuth.log_in_user/3` + DB session). Generated reset/MFA/passkey/admin routes may exist but stay **dormant** (undocumented in 106 unless needed to log in).
- **D-106-03d:** Minimal **`PageController`** home: unauthenticated links to register/login; authenticated link to **`/audit`**. No ticket/help-desk product UI (Phase 109).
- **D-106-03e:** Do **not** run full Sigra LiveView install, `phx.gen.auth`, or parallel CSS for `/audit` (105-UI-SPEC).
- **D-106-03f:** Do **not** fork generated `UserAuth` unless **106b** documents a Sigra contract gap.

### Test authentication strategy (D-106-04)

- **D-106-04a:** Add **`login_via_sigra(conn, user, opts \\ [])`** to `ConnCase` — default **`:http`** (POST `/users/log_in` → real session → production fetch plugs); optional **`:session`** fast path if Sigra exposes stable session API.
- **D-106-04b:** **Migrate** `operator_surface_test.exs` off `assign(:current_user, …)` to **`login_via_sigra/2`** (admin + support scenarios).
- **D-106-04c:** **Keep** `sigra_conn/2` for API tests (`posts_audit_path_test`, `posts_correlation_path_test`, `posts_incident_json_path_test`) — proves post-plug `Integrations.Sigra` boundary, not browser auth.
- **D-106-04d:** **Keep** `help_desk_audit_test.exs` on **DataCase** with explicit `%AuditContext{}` (Phase 105 D-05d fast regression).
- **D-106-04e:** **Add** `help_desk_audit_http_test.exs` (ConnCase, `async: false`): ≥1 test proving Sigra login `user_id` → captured `actor_ref` on help-desk write (minimal HTTP route OK until Phase 109 UI).
- **D-106-04f:** Fixtures: `help_desk_fixtures` membership `user_id` strings **match** Sigra user ids used in login helpers (D-06c).
- **D-106-04g:** **No** Capybara/Wallaby in 106; **no** config fake-admin plug in production router; lib `operator_surface` LiveView tests keep test-router assigns unchanged.

**Rationale:** Layered pyramid — many fast DataCase proofs, some `sigra_conn` API integration, few real-session HTTP proofs — satisfies AUTH-04 and OSS DNA honest verification without suite bloat.

### Claude's Discretion

- Auto-org slug/name generation (email local-part vs random suffix).
- Whether dev walkthrough seeds first support user as `:support` vs promoting via fixture only.
- Exact Sigra registration callback hook module/function name after install.
- `login_via_sigra` default `:http` vs `:session` once Sigra install is applied.
- Minimal help-desk HTTP write route shape for AUTH-04 proof before Phase 109.

### Folded Todos

(none — `todo.match-phase` returned empty)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contracts

- `.planning/ROADMAP.md` § Phase 106 — goal, success criteria, scope guard, 106b escape valve
- `.planning/REQUIREMENTS.md` — AUTH-01 through AUTH-04, Out of Scope (Sigra vs phx.gen.auth)
- `.planning/phases/105-help-desk-domain-expansion-in-reference-app/105-CONTEXT.md` — org UUID meta, agents↔user_id, roles, DataCase vs ConnCase split
- `.planning/phases/104-reference-walkthrough-charter-override-decision/104-CONTEXT.md` — v1.23 non-goals, `lib/` read-only, host-owned auth boundary

### Sigra reference lane

- `guides/integrations/sigra.md` — plug wire-up, capture vs surface auth split, correlation formats, soft-dep contract
- `guides/getting-started-saas.md` — first-hour path; example README as runnable proof
- `examples/threadline_phoenix/README.md` — operator mount, `current_user` contract, sigra-reference lane versions
- `lib/threadline/integrations/sigra.ex` — read-only; actor_ref + correlation overrides from `current_scope` / `sigra_session`

### Example app integration points

- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — `require_authenticated_operator`, `my_authorize_fn`, `scope_operator_query`, `:api` pipeline
- `examples/threadline_phoenix/test/support/conn_case.ex` — `sigra_conn/2` (keep for API)
- `examples/threadline_phoenix/test/support/help_desk_fixtures.ex` — org → membership → agent chain
- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` — extend with provision + membership helpers
- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk/org_membership.ex` — roles `agent` | `support`

### Vision, ecosystem lessons, OSS DNA

- `prompts/audit-lib-domain-model-reference.md` — capture vs semantics vs exploration; tenant binding
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — PaperTrail queryable metadata, Logidze footguns, host-owned context
- `prompts/threadline-elixir-oss-dna.md` — honest `mix test`, layered verification, host-owned auth boundary
- `prompts/prior-art/from-sigra/Auth Domain Language — A Field Guide.md` — identity vs account vs session; org vocabulary

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ThreadlinePhoenixWeb.Router` — operator auth plugs and authorize fns already expect `current_user` shape; only auth pipeline wiring changes
- `Threadline.Integrations.Sigra` — API `actor_fn` / `context_overrides_fn` already wired; reads `current_scope` + `private[:sigra_session`
- `ThreadlinePhoenix.HelpDesk` + fixtures — org/membership/agent schemas from Phase 105; add provision + `get_membership_role/2`
- `ThreadlinePhoenix.Blog.audit_transaction_meta/1` — pattern for `%{"organization_id" => uuid_string}` meta
- `conn_case.ex` `sigra_conn/2` — keep for API tests; extend with `login_via_sigra/2`

### Established Patterns

- Host owns browser auth before Threadline operator mount (`README` phx.gen.auth-style posture)
- Support scope: `{:ok, %{access: :support_read_only, organization_id: org_id}}` from `my_authorize_fn`
- Phase 105: DataCase for capture proof; Phase 106 adds ConnCase HTTP for auth transport
- Sigra optional dep `~> 0.2` (lockfile `0.2.5`); soft-loaded in library via `Code.ensure_loaded?(Sigra.Session)`

### Integration Points

- Sigra install injects `fetch_current_scope` into `:browser` pipeline
- Registration callback → `HelpDesk.provision_default_workspace_for_user/1`
- `AssignOperatorUser` before `:operator_auth` on `/audit` scope
- Phase 107 `demo.seed` must call same provision helper for seeded Sigra users

</code_context>

<specifics>
## Specific Ideas

- Coherent package: **narrow Sigra install + auto-provision help-desk tenant + OperatorUser plug + layered tests** — optimized for fresh-clone walkthrough, AUTH-03 router stability, and zero `lib/` churn unless 106b.
- Ecosystem steal list: Slack/Shopify auto-workspace on join; PaperTrail/GH stable id for ACL; django-auditlog host middleware for actor; reject dual org tables and Logidze connection-metadata footguns.
- Impersonation: capture records admin actor; operator surface fails closed on impersonated desk membership.
- Phase 108 WALK-01 documents register/login/logout URLs and `/dev/mailbox` confirm — not passkeys or org picker.

</specifics>

<deferred>
## Deferred Ideas

- Invite/join-only org onboarding (GitHub-org pattern) — post–v1.23 host responsibility
- Org switcher / multi-org membership UX
- Signup form with company/org name
- Sigra `--organizations` tables mirroring help-desk orgs
- Full Sigra LiveView auth suite (passkeys, admin users, org picker)
- `phx.gen.auth` parallel lane (REQUIREMENTS: Sigra only)
- Ticket/agent console UI — Phase 109 (RUN-01)
- Capybara/browser E2E — Phase 108+ if needed
- Config-based demo-admin plug in production router
- `lib/threadline/integrations/sigra.ex` changes — **106b only** on proven contract gap

### Reviewed Todos (not folded)

(none)

</deferred>

---

*Phase: 106-sigra-auth-lane-in-reference-app*
*Context gathered: 2026-05-27*
