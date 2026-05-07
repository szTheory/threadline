---
phase: 64-raw-timeline-browse-and-filter-form
audit_mode: retroactive-STRIDE
asvs_level: 2
threat_register_authored_at_plan_time: false
threats_total: 21
threats_closed: 19
threats_open: 0
threats_accepted: 2
audited_date: "2026-05-07"
audited_files:
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/live/actor_live.ex
supporting_files:
  - lib/threadline/query.ex
  - lib/threadline/operator_surface/auth.ex
---

# Phase 64 — Security Audit (retroactive-STRIDE)

Phase 64 shipped a read-only LiveView at `/audit` (`Threadline.OperatorSurface.Live.TimelineLive`) with a five-filter form, URL-as-state via `push_patch`, and `phx-viewport-bottom` infinite scroll over `Phoenix.LiveView.Stream`. No threat model was authored at plan time; SUMMARYs declared "Threat Flags: None". This audit constructs the STRIDE register from implementation and verifies every threat has a code-level mitigation.

## Result

`SECURED` — 19 closed, 2 accepted (documented), 0 open.

No BLOCKER findings. Two accepted-risk items recorded for v1.19+ follow-up.

## Threat Register

| ID | Category | Component | Disposition | Status | Evidence |
|----|----------|-----------|-------------|--------|----------|
| T-S-01 | Spoofing | `actor_id`, `correlation_id` URL inputs → Ecto query | mitigate | CLOSED | `lib/threadline/query.ex:763` (`fragment "? @> ?::jsonb", at.actor_ref, ^actor_map`) and `lib/threadline/query.ex:787` (`aa.correlation_id == ^cid`) — all user-supplied strings flow as parameterized Ecto binds; no string interpolation into SQL |
| T-S-02 | Spoofing | `actor_kind` URL input → atom | mitigate | CLOSED | `lib/threadline/operator_surface/live/timeline_live.ex:387-393` (`safe_actor_kind/1` uses `String.to_existing_atom/1` with rescue → `{:error, :unknown_actor_type}`); `lib/threadline/semantics/actor_ref.ex` `new/2` rejects atoms not in fixed `@types` enum |
| T-S-03 | Spoofing | Cross-tenant scope thread-through | accept | ACCEPTED-RISK | `:threadline_scope` is read at `timeline_live.ex:23`, threaded into `scope_aware_opts/1` at `:248-255`, but `scope_to_query_opts/1` at `:258` returns `[]` (Phase 64 documented passthrough). The v1.17 auth contract gates the surface mount via `:authorize_fn`; per-tenant query predicate scoping is deferred to v1.19+. Documented in `64-01-SUMMARY.md` decisions and in source comment at `:257`. |
| T-T-01 | Tampering | URL filter-key allowlist bypass | mitigate | CLOSED | `timeline_live.ex:282-290` (`normalize_params/1` filters `key in @filter_keys`); `timeline_live.ex:366-373` wraps `Threadline.Query.validate_timeline_filters!/1` (lib/query.ex:138) in `try/rescue ArgumentError` — the same single-source-of-truth validator the library API uses |
| T-T-02 | Tampering | Cursor tampering (keyset pagination) | mitigate | CLOSED | Cursor is in socket assigns only (`timeline_live.ex:43`, `:110`, `:120`, `:154`), never in URL. `lib/threadline/query.ex:709-737` `validate_timeline_cursor!/1` requires `%{captured_at: %DateTime{}, id: uuid}` shape and casts id via `Ecto.UUID.cast/1` (raises ArgumentError otherwise) |
| T-T-03 | Tampering | Datetime input bypass | mitigate | CLOSED | `timeline_live.ex:378-385` `parse_datetime_local/1` pads to `:00Z` and uses `DateTime.from_iso8601/1` returning `{:error, :invalid_datetime}` for malformed input; the error is propagated into `:form_error` at `:298` and rendered (no crash, no SQL) |
| T-T-04 | Tampering | Atom-table exhaustion via attacker-supplied keys | mitigate | CLOSED | `timeline_live.ex:288` (`String.to_existing_atom(key)` after `key in @filter_keys` allowlist); `:389` (`String.to_existing_atom(kind)` with rescue). No `String.to_atom/1` anywhere in `timeline_live.ex` (verified via grep) |
| T-R-01 | Repudiation | Read-only surface | N/A | CLOSED | TimelineLive only reads via `Threadline.Query.timeline_page/2`; no mutations. `lib/threadline/operator_surface/auth.ex:57-61` emits `[:threadline, :operator_surface, :authorize]` telemetry on every mount with result + scope_keys (cannot be subverted from the LV) |
| T-I-01 | Information Disclosure | XSS via filter values echoed into form `value=` attrs | mitigate | CLOSED | All `value={@filters_raw["..."]}` and `<%= ... %>` use HEEx auto-escape (`timeline_live.ex:174,178,182,191,197,204,221,229,230,231`). No `Phoenix.HTML.raw/1`, no `raw/1` in `timeline_live.ex` (verified via grep) |
| T-I-02 | Information Disclosure | Verbose error reflection (lib's ArgumentError message echoed) | mitigate | CLOSED | `safe_validate/1` (`timeline_live.ex:366-373`) puts `e.message` into `:form_error`, rendered via `<%= @form_error %>` (`timeline_live.ex:216`) — HEEx auto-escapes. Lib messages contain `inspect(key)`/`inspect(value)` (`query.ex:142,181,194`) but escaping prevents HTML injection. Same applies to `:339,346` (`"unknown actor kind: " <> inspect(actor_kind)`) |
| T-I-03 | Information Disclosure | Cross-tenant data leak via scope-thread regression | accept | ACCEPTED-RISK | Same as T-S-03. Documented passthrough; surface is mount-time-gated by `:authorize_fn`. Adopters who depend on row-level scope must inject scope via filter shaping outside the surface (e.g., `pipe_through` enforces tenant binding before mount). To be addressed in v1.19+. |
| T-I-04 | Information Disclosure | `actor_kind=anonymous` URL still exposes `actor_id` in form | mitigate | CLOSED | `timeline_live.ex:276-279` `filters_raw_from_params/1` strips `actor_id` from echoed form when `actor_kind=anonymous`. `:317-356` `collapse_actor_ref/1` constructs `%ActorRef{type: :anonymous, id: nil}` regardless of supplied actor_id. `:403-406` `normalize_anonymous/1` removes `actor_id` from canonical query string on submit |
| T-D-01 | DoS | Atom-table exhaustion | mitigate | CLOSED | See T-T-04 |
| T-D-02 | DoS | Unbounded query results / large `page_size` | mitigate | CLOSED | `timeline_live.ex:9` (`@page_size 50`) and `:148` (`page_size: 50` literal at next-page call site); lib's `validate_timeline_page_size!` (`query.ex:701-707`) requires positive integer. Page size is fixed by the LV; not user-controllable |
| T-D-03 | DoS | Oversized `correlation_id` | mitigate | CLOSED | `lib/threadline/query.ex:184-198` `validate_correlation_id_filter!` enforces `byte_size(trimmed) > 256` raises ArgumentError; form input enforces `maxlength="256"` at `timeline_live.ex:205` (defense-in-depth) |
| T-D-04 | DoS | Oversized `table`/`actor_id`/`from`/`to` filter values | accept | ACCEPTED-RISK | No length cap on `table`, `actor_id`, or datetime strings at LV layer. Values flow through Ecto as parameterized binds (no SQL injection). Postgres rejects oversized binds at the protocol layer. Practical attacker would need to ship multi-MB POST bodies which Phoenix/cowboy already cap at the endpoint level. Low-severity, accepted for v1.18 |
| T-E-01 | Elevation of Privilege | Bypass of `:authorize_fn` (mount without auth) | mitigate | CLOSED | `lib/threadline/operator_surface/router.ex:30-36` raises `CompileError` if router scope has no `pipe_through`, no `:authorize_fn`, AND no `:adopter_acknowledges_unauthenticated` — the secure-by-default mount is enforced at compile time |
| T-E-02 | Elevation of Privilege | Mounting without auth on_mount hook | mitigate | CLOSED | `lib/threadline/operator_surface/router.ex:40` (`live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, opts}]`) wraps every route. `lib/threadline/operator_surface/auth.ex:9-44` `halt_unauthorized` redirects to `/` for any non-`:ok`/`true`/`{:ok, scope}` return AND `rescue` block converts exceptions in `authorize_fn` to halts |
| T-E-03 | LV-specific | CSRF on `phx-submit` | mitigate | CLOSED | Form uses `phx-submit="apply"` (`timeline_live.ex:171`) — LiveView WebSocket handshake provides CSRF token automatically via signed live_view session. No custom `<form action="/...">` POST endpoint exists |
| T-E-04 | LV-specific | Open-redirect via `push_patch` | mitigate | CLOSED | `push_patch` calls at `timeline_live.ex:72,134,138` use `socket.assigns.base_path` (derived from `URI.parse(uri).path` at `:58-59` — path component only, never a full URL) plus URI-encoded query string. `push_patch` itself rejects external URLs (Phoenix.LiveView contract). No attacker-controlled host injection vector |
| T-E-05 | LV-specific | Open-redirect via back-link `href` | mitigate | CLOSED | `transaction_live.ex:83` and `actor_live.ex:68,73` use `<a href={@base_path}>` where `@base_path` is regex-anchored extraction from request URI path (`transaction_live.ex:29` — `Regex.run(~r/(.*\/transactions\/[^\/]+)/, uri_parsed.path)`; `actor_live.ex:54` — `Regex.run(~r/(.*)\/actors\/[^\/]+\/[^\/]+/, uri_parsed.path)`). Path-component only; no protocol/host echo |

## Accepted Risks (Decision Log)

### AR-01 — Scope-thread is a Phase 64 passthrough

`scope_to_query_opts(_scope)` returns `[]` (`lib/threadline/operator_surface/live/timeline_live.ex:258`). The `:threadline_scope` value populated by `:authorize_fn` is read into socket assigns and threaded through the `scope_aware_opts/1` helper, but does NOT yet constrain query predicates. The `Threadline.Query.timeline_page/2` API does not accept a `:scope` option (it is silently ignored).

**Why accepted:**
- Phase 64 is read-only LV UI on top of v1.17 query contract; no new auth path introduced.
- v1.17 auth contract documents that `:authorize_fn` returning `{:ok, scope}` is informational; row-level filtering is the adopter's responsibility (e.g., via `pipe_through` Plug enforcing tenant binding before mount).
- Documented in `64-01-SUMMARY.md` decisions block; documented in source comment at `timeline_live.ex:257` ("Phase 64 passthrough — extension point for v1.19+ scope-derived predicates").
- Phase 65's export controller will reuse `scope_aware_opts/1` verbatim, so a single future change in `scope_to_query_opts/1` lights up scope-aware predicates for both LV and HTTP surfaces simultaneously.

**Threats subsumed:** T-S-03, T-I-03.

**Action item for v1.19+:** populate `scope_to_query_opts/1` with the scope→predicate translator the upstream `Threadline.Query` API will accept. Add a regression test that asserts a row owned by tenant A is NOT visible to tenant B given `:authorize_fn` returns `{:ok, %{tenant: ...}}`.

### AR-02 — No length cap on `table`, `actor_id`, datetime filter values

`Threadline.Query.validate_timeline_filters!/1` caps `correlation_id` at 256 UTF-8 bytes but does not cap other string filters.

**Why accepted:**
- All filter values flow as parameterized Ecto binds (`fragment "? @> ?::jsonb", ..., ^actor_map`); no SQL injection risk.
- Postgres rejects oversized binds at the wire-protocol layer (≈1GB hard limit) which is far beyond any practical DoS vector.
- Phoenix/cowboy endpoint-level body size limits cap inbound POST/WebSocket payloads to ≈8MB by default.
- The `actor_id` is JSONB-contained-by predicate against `audit_transactions.actor_ref` — a giant string just produces zero matches, not a SQL pathology.

**Threats subsumed:** T-D-04.

**Action item for v1.19+:** add 2KB caps to `:table`, `:actor_id`, and `:from`/`:to` (string-pre-parse) in `validate_timeline_filters!/1`. Track as a defensive-depth follow-up; not blocking.

## Unregistered Flags

None. Phase 64 SUMMARYs declared "Threat Flags: None" and the audit confirms no new attack surface beyond what is mapped to a CLOSED or ACCEPTED-RISK threat above.

## Notes on Pre-Existing Code

`lib/threadline/operator_surface/live/actor_live.ex:13` contains a `String.to_atom(kind)` fallback in the actor route's `mount/3`. This is **pre-existing code from Phase 60** and is NOT part of the Phase 64 diff. The audit flags it here for visibility but it is out-of-scope for Phase 64 mitigation verification. A separate phase should harden this fallback (replace with explicit-list rejection or remove the fallback entirely). This is a latent atom-table-exhaustion vector on the `/audit/actors/:kind/:id` route (the `:kind` URL segment).

**Recommended action:** open a follow-up phase to remove the `String.to_atom(kind)` fallback at `actor_live.ex:13` and convert to `String.to_existing_atom/1` only (matching `timeline_live.ex:389`).

## Verification Method

For each threat:
1. Identified the trust boundary and user-controlled input.
2. Greppped the implementation files for the declared mitigation pattern (e.g., `String.to_existing_atom`, `validate_timeline_filters!`, `^cid` parameterized bind).
3. Confirmed the mitigation is on every entry point (mount, handle_params, handle_event "apply", handle_event "next-page").
4. Cross-referenced supporting library code (`lib/threadline/query.ex`, `lib/threadline/operator_surface/auth.ex`) to confirm the contract is upheld upstream of the LV.

No declared mitigation was absent from the cited file location. No threat exists for which there is no mitigation OR documented accepted-risk entry.

## Next Audit

Phase 65 (export controller) will reuse `scope_aware_opts/1` verbatim. The next audit should re-verify:
- T-S-03 / T-I-03 dispositions stay accepted-risk OR a real `scope_to_query_opts/1` is wired (in which case AR-01 becomes CLOSED).
- Phase 65's HTTP route shares the same `:authorize_fn` enforcement contract.
- Phase 65 introduces new attack surface (file download, MIME sniffing, content-disposition) — those threats must be enumerated in Phase 65's PLAN `<threat_model>` block (lesson learned from Phase 64's empty register).
