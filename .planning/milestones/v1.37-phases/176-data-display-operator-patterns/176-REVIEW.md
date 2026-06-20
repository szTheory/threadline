---
phase: 176-data-display-operator-patterns
reviewed: 2026-06-18T00:00:00Z
depth: deep
files_reviewed: 14
files_reviewed_list:
  - lib/threadline/operator_surface/components/icon.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/stress_fixtures.ex
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/operator_surface/ui.ex
findings:
  critical: 1
  warning: 6
  info: 4
  total: 11
status: issues_found
resolution:
  critical_fixed: 1   # CR-01 fixed in commit (audit-before-trigger, D-21.3)
  warnings_deferred: 6 # tracked as follow-ups (latent / fail-closed; non-blocking)
  note: "CR-01 (prune-before-audit) resolved post-review by reordering the with-chain to audit-then-trigger. Retention T3 suite 15/0 green. Warnings WR-01..WR-06 are latent or already fail-closed and are deferred as non-blocking follow-ups."
---

# Phase 176: Code Review Report

**Reviewed:** 2026-06-18

> **Post-review resolution (orchestrator):** CR-01 (Critical — prune fired before
> it was audited) was FIXED by reordering the `prune_now` `with`-chain to
> audit-then-trigger so an audit-insert failure aborts the prune (D-21.3); the
> audit step stays after `secure_compare`, so a forged token still records
> nothing. Retention T3 suite 15/0 green. The 6 warnings (WR-01 mount-cached
> authz that still fails closed; WR-03/WR-04 latent truncation-length contract
> edges; WR-05 untested stream path; WR-02/WR-06 minor) are deferred as
> non-blocking follow-ups.
**Depth:** deep
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 176 consolidates the operator-surface data-display paths (one `ref/1` + `Presentation.ref/2`, `kv/1`, `data_table/1`, the DATA-03 state taxonomy) and rebuilds the retention "prune now" action as a T3 type-to-confirm flow with server-side enforcement. The bulk of the work is solid and the headline security objectives are largely met:

- **Copy-footgun closed.** `UI.ref/1` binds `data-tl-copy={@r.full}` on both the `<code>` and the button, and the no-JS path renders `@r.full`. The `transaction_live.ex:121/145` `.title` footgun is gone. Every migrated call site I traced (`actor`, `timeline`, `evidence`, `export_status`, `transaction` diff cells) copies the full value, never `.visible`/`.title`.
- **CSP-safe.** No inline `onclick=`/`onchange=` introduced; copy stays on the existing delegated `data-tl-copy` listener; modal/menu use `Phoenix.LiveView.JS`.
- **Atom-safety.** `Presentation.kind_from_string/1` resolves against a compile-time interned `@ref_kinds` list (no `String.to_atom` on untrusted `kind`).
- **T3 enforcement is mostly fail-closed.** Authz is re-checked in the event, `Plug.Crypto.secure_compare/2` compares the typed value against a server constant (the canonical token is never shipped to the client to compare client-side), `phx-value-id` is ignored, and the default `else` path refuses.

However, there is **one Critical ordering defect**: the destructive `Pruner.trigger/0` cast fires *before* the `AuditAction` is recorded, so a prune can execute unaudited (and be reported to the operator as a confirmation failure) if the audit insert fails. There is also a meaningful authz-staleness gap and several quality issues described below.

The invariants hold: capture/semantics layers are untouched, zero new runtime deps, no new `--tl-*` tokens, and the `style_contract`/`card_nesting` tests were updated alongside the CSS deletions.

## Critical Issues

### CR-01: Prune fires before it is audited — destructive action can run unaudited and be reported as a failure

**File:** `lib/threadline/operator_surface/live/retention_history_live.ex:66-92`
**Issue:** The `with` chain triggers the irreversible prune (`Pruner.trigger/0`, a `GenServer.cast` that kicks off `:run_purge`) *before* `audit_prune/2` records the `AuditAction`:

```elixir
with :ok <- authorize_prune(socket),
     canonical <- @canonical_policy_name,
     true <- Plug.Crypto.secure_compare(typed, canonical),
     :ok <- Pruner.trigger(),                       # <-- DESTRUCTIVE cast already sent
     {:ok, _action} <- audit_prune(socket, canonical) do
  ...
else
  _ ->
    # "Could not prune — confirmation did not match."
```

If `audit_prune/2` returns `{:error, _}` (the `AuditAction` changeset is invalid, the repo insert fails, `resolve_repo/1` yields a repo that rejects the write, etc.), control falls into the catch-all `else`, which:
1. Tells the operator **"Could not prune — confirmation did not match"** — a false statement; the prune *did* start and the confirmation *did* match.
2. Leaves the destructive deletion **unaudited**, directly violating D-21.3 / domain §9.3.4 ("audit the destructive action itself," the "audit the auditor" / Repudiation mitigation that is a stated reason this handler was rebuilt).

This is the exact fail-closed/auditability guarantee the phase exists to deliver, inverted: the success-only side effect (prune) precedes the audit, and the failure side effect (misleading flash + no audit) hides it.

**Fix:** Record the `AuditAction` *before* triggering the prune, so an audit failure aborts the prune (fail closed, attributable). Trigger only after the audit row commits:

```elixir
with :ok        <- authorize_prune(socket),
     canonical  <- @canonical_policy_name,
     true       <- Plug.Crypto.secure_compare(typed, canonical),
     {:ok, _a}  <- audit_prune(socket, canonical),   # audit FIRST — abort if it fails
     :ok        <- Pruner.trigger() do                # only prune once attributable
  Process.send_after(self(), :refresh, 500)
  {:noreply, socket |> assign(:prune_modal_open, false) |> put_flash(:info, "Prune started.")}
else
  {:error, :not_started} ->
    {:noreply, socket |> assign(:prune_modal_open, false)
     |> put_flash(:error, "Retention runtime is not started.")}

  _ ->
    {:noreply, socket |> assign(:prune_modal_open, false)
     |> put_flash(:error, "Could not prune — confirmation did not match.")}
end
```

Additionally, the catch-all flash conflates distinct failures (bad confirmation vs. audit-write failure) under "confirmation did not match." Once the audit moves ahead of the trigger, give the audit-failure path its own honest message (e.g. "Could not record the prune — no records were deleted.") so the operator is not told a falsehood. Add a Wave-0 integration test asserting that when `audit_prune` fails, `Pruner.trigger` is **not** invoked.

## Warnings

### WR-01: Authorization re-check reads a mount-time cached assign, not a live re-evaluation

**File:** `lib/threadline/operator_surface/live/retention_history_live.ex:321-323`
**Issue:** `authorize_prune/1` checks `socket.assigns[:threadline_policy_enabled]`, which is computed once at mount/auth time (`auth.ex:237-261`) and then cached on the socket. The research (D-21.2) explicitly calls for re-checking authorization *in the event* because "policy access can change between mount and submit." Re-reading a frozen assign does not satisfy that: if the operator's policy access is revoked mid-session, the stale `true` still authorizes the destructive prune for the lifetime of the LiveView process. The good news is it fails *closed* by default (`assign_policy_enabled` defaults to `false`), so this is a downgrade-not-bypass gap, not an open door — but it is weaker than the spec.
**Fix:** Plumb the host `policy_authorize_fn` (or a re-authorization helper) through to the socket and re-invoke it inside `authorize_prune/1` at action time, rather than trusting the mount-time snapshot. At minimum, document the accepted staleness window explicitly and add a test pinning the chosen behavior.

### WR-02: Dead/misleading correlation-existence guard recomputes a truncated value

**File:** `lib/threadline/operator_surface/live/transaction_live.ex:284-288`
**Issue:** `transaction_correlation_id/1` is now used only as an `:if={...}` presence check in render, but its body still calls `Presentation.secondary_ref(correlation_id, 42).visible` — it builds and *truncates* the correlation id purely to produce a truthy value. This is leftover from the pre-consolidation code (the new `transaction_correlation_value/1` directly below returns the raw id). It is not a copy footgun (the value is never copied), but it is confusing dead logic that computes a truncated string for a boolean test and invites a future maintainer to reuse it as a value.
**Fix:** Make the guard return the presence of the raw id, not a truncated render:
```elixir
defp transaction_correlation_id(%{action: %{correlation_id: cid}})
     when is_binary(cid) and cid != "", do: cid
defp transaction_correlation_id(_), do: nil
```
(or delete it and gate the `:item` on `transaction_correlation_value(@bundle.transaction)` directly).

### WR-03: `truncate_middle/2` `:tail_min` can request more tail than the available width, distorting the head/tail split

**File:** `lib/threadline/operator_surface/presentation.ex:60-77`
**Issue:** With `:tail_min` set, `tail = max(default_keep, tail_min)` while `head = default_keep`. For small `max_length` and a larger `tail_min`, `head + 3 + tail` can exceed `max_length` (e.g. `truncate_middle(value, 24, tail_min: 12)` for hash → `head=10`, `tail=12`, output core `10 + 3 + 12 = 25 > 24`). The function never re-checks the assembled length against `max_length`, so the "max" is not actually an upper bound once `:tail_min` is engaged. For the `:hash` (24/8) and `:arn|:actor` (34/12) call sites the current numbers stay at/under budget, so this is latent rather than firing today, but the contract (`@spec` says `max_length`) is violated for plausible future kind tunings.
**Fix:** Clamp the head so the total respects `max_length` when `:tail_min` is honored, e.g. `head = max(min(default_keep, max_length - 3 - tail), 0)`, and add a property/unit test asserting `String.length(result) <= max_length` for any `tail_min`.

### WR-04: `truncate_url/1` can emit a "truncated" string longer than the original

**File:** `lib/threadline/operator_surface/presentation.ex:165-187`
**Issue:** In the `true ->` branch the result is `head <> "/..." <> last_segment` where `head = "#{scheme}://#{host}"`. If the path between host and last segment is short but the host is long, `scheme://host + "/..." + last_segment` can be *longer* than the original value (which contained the same host plus a shorter middle). The function already gated on `String.length(value) <= 56`, so it only fires for long URLs, but it provides no guarantee the rebuilt visible string is shorter than the input — the whole point of truncation. A pathological host+segment can produce a "truncated" face wider than the raw value, defeating the responsive goal.
**Fix:** After building the candidate, fall back to `truncate_middle(value, 56, tail_min: 8)` when the candidate is not actually shorter:
```elixir
candidate = head <> "/..." <> last_segment
if String.length(candidate) < String.length(value), do: candidate,
  else: truncate_middle(value, 56, tail_min: 8)
```

### WR-05: `data_table/1` streams require per-row DOM ids but the component does not enforce it

**File:** `lib/threadline/operator_surface/ui.ex:446-465`
**Issue:** When `stream` is truthy the `<tbody>` gets `phx-update="stream"`, which **requires** every child `<tr>` to carry a stable DOM id; LiveView raises/misbehaves at runtime otherwise. The `<tr id={@row_id && @row_id.(row)}>` renders `id={nil}` when `row_id` is not supplied. The retention call site passes `row_id`, so it works there, but the component silently accepts `stream:` without `row_id:` and produces id-less rows that break streaming. The stress story exercises `rows:` (not `stream:`), so this path is untested.
**Fix:** Guard the contract — when `stream` is set, require `row_id` (raise at compile/render time, or `assert` in dev), or derive the id from the stream's `{dom_id, _}` tuple shape the retention caller already uses. Add a stress/integration story that renders `data_table` with `stream:` so the streaming path is covered.

### WR-06: `data_state/1` catch-all hardcodes timeline-specific copy for every non-matched reason

**File:** `lib/threadline/operator_surface/ui.ex:648-655`
**Issue:** The fallback clause renders `error_state` with the literal title **"Could not load this timeline"** and body "Retry, then check logs." `data_state/1` is a generic dispatcher intended for any audit surface (retention, coverage, evidence, exports), but any unrecognized reason on a non-timeline page will tell the operator their *timeline* failed. This silently mis-describes the surface and partially undercuts DATA-03's "never collapse to a generic something-went-wrong" intent by collapsing to a *wrong-context* specific message.
**Fix:** Make the catch-all surface-neutral ("Could not load this audit data") or accept an optional `:subject`/`:label` attr so callers name their own surface, and document that unknown reasons render the generic error face.

## Info

### IN-01: `confirm_param/1` silently coerces a missing confirmation to `""`

**File:** `lib/threadline/operator_surface/live/retention_history_live.ex:316-317`
**Issue:** A submit without a `"confirm"` field yields `""`, which then fails `secure_compare(""," default")` and falls through to refusal. Correct (fail-closed), but the empty-string coercion is implicit; a future change to `@canonical_policy_name = ""` (unlikely but unguarded) would make an empty submission *pass*.
**Fix:** Keep the behavior but add an explicit guard `canonical != "" and secure_compare(...)`, plus a test asserting an empty/blank confirmation always refuses.

### IN-02: `audit_prune/2` ignores `ActorRef.new/2` failure with a hard match

**File:** `lib/threadline/operator_surface/live/retention_history_live.ex:328-336`
**Issue:** `{:ok, actor} = ActorRef.new(:system, "retention_pruner")` uses a strict `=`. `ActorRef.new(:system, "retention_pruner")` succeeds today, so this never raises, but a future change to `ActorRef` validation would turn this into an unhandled `MatchError` inside the destructive handler rather than a clean fail-closed refusal.
**Fix:** Pattern-match in the `with` or `case` and route a failure to the refusal path, e.g. `with {:ok, actor} <- ActorRef.new(:system, "retention_pruner"), ...`.

### IN-03: `data_table/1` builds `data_rows` via `assign_new` over a value that always exists

**File:** `lib/threadline/operator_surface/ui.ex:447`
**Issue:** `assign_new(assigns, :data_rows, fn -> assigns.stream || assigns.rows || [] end)` uses `assign_new`, which only computes when `:data_rows` is absent. Since callers never pass `:data_rows`, this is effectively a plain `assign`; using `assign_new` here is a minor readability smell (implies a caller-override path that does not exist).
**Fix:** Use `assign(assigns, :data_rows, assigns.stream || assigns.rows || [])` for clarity, or document the intended override.

### IN-04: `data_state` `as_of` accepted on clauses that ignore it

**File:** `lib/threadline/operator_surface/ui.ex:585-646`
**Issue:** `attr(:as_of, ...)` is declared once for all `data_state/1` heads but only consumed by the `:pruned` clause. Passing `as_of` to `:no_data`/`:unauthorized`/etc. is silently dropped. Harmless, but a caller may expect `as_of` to render on `:source_down`/`:redacted` and get nothing.
**Fix:** Document that `as_of` applies only to `:pruned` (and `stale_banner/1`), or thread it into `:redacted`/`:source_down` copy if those should also state an as-of time.

---

_Reviewed: 2026-06-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
