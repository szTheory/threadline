# Phase 176: Data display & operator patterns - Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 14 (3 new components, 2 extended core, 9 consuming/integration files)
**Analogs found:** 14 / 14 (every new/modified unit has a verified in-tree analog — this is a fix-and-consolidate phase, not greenfield)

> All new components live in the existing `Threadline.OperatorSurface.UI` module (`@doc false`, strict `attr`/`slot`, `--tl-*`-token-driven, zero public API). All core helpers extend `Threadline.OperatorSurface.Presentation`. **No new module is created.** Match the 173/174/175 conventions verbatim. **Read-only constraint:** this map cites analogs; it does not edit source.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Presentation.ref/2` (presentation.ex, new) | utility (pure helper) | transform | `Presentation.secondary_ref/2` (presentation.ex:229) | exact |
| `Presentation.truncate_middle/2` + `:tail_min` (presentation.ex:58) | utility | transform | itself (extend in place) | exact |
| `Presentation.value_token/1` + truncation (presentation.ex:239) | utility | transform | itself + `secondary_ref/2` | exact |
| `UI.ref/1` (ui.ex, new) | component | transform / request-response | `UI.stat_tile/1` (ui.ex:341) shape + inline copy at `transaction_live.ex:120` | exact |
| `UI.kv/1` (ui.ex, new) | component | CRUD (read/display) | `snapshot_result/1` `<dl class="tl-kv">` (row_history_component.ex:174) | exact |
| `UI.data_table/1` (ui.ex, new) | component | streaming / CRUD | retention `<table>`+`phx-update="stream"` (retention_history_live.ex:177); coverage table (coverage_live.ex:213) | exact |
| `UI.loading_state/1` (ui.ex, new) | component | event-driven (state) | `UI.empty_state/1` (ui.ex:358) + `UI.spinner/1` (ui.ex:131) | role-match |
| `UI.stale_banner/1` (ui.ex, new) | component | event-driven (state) | coverage stale strip (coverage_live.ex:126) + `UI.alert/1` (ui.ex:109) | exact |
| `UI.empty_state/1` variant enum extend (ui.ex:352) | component | event-driven (state) | itself (extend `values:` list) | exact |
| `transaction_live.ex` (copy fix + `kv` + diff) | LiveView (consumer) | request-response / streaming | self (lines 114-151, 193-203) | exact |
| `coverage_live.ex` (flatten + `page_header`) | LiveView (consumer) | request-response | self (lines 110-200) + `UI.page_header/1` (ui.ex:202) | exact |
| `retention_history_live.ex` (T3 enforce + `data_table`) | LiveView (consumer) | streaming / destructive | self `handle_event` (L37) + research skeleton | role-match |
| `policy_redaction_live.ex` (diff collapse fix) | LiveView (consumer) | CRUD (read diff) | self diff `<table>` (L137-159) | exact |
| stress story registration for new units | test fixture / story | event-driven | `stress_fixtures.ex` `@state_stories` (L95) + `assigns_for/1` (L148) | exact |

---

## Pattern Assignments

### `Presentation.ref/2` (utility, transform) — NEW core helper

**Analog:** `Presentation.secondary_ref/2` (presentation.ex:229-237)

The new `ref/2` is `secondary_ref/2` plus a third face (`full`) and per-kind truncation. Copy the exact shape; add `full` (never truncated) and route through the extended `truncate_middle/2`.

```elixir
# presentation.ex:229-237 — the analog returns TWO faces; ref/2 must return THREE
@spec secondary_ref(term(), pos_integer()) :: %{visible: String.t(), title: String.t()}
def secondary_ref(value, max_length \\ 34) do
  full = secondary_ref_value(value)

  %{
    visible: truncate_middle(full, max_length),
    title: full
  }
end
```

**D-01/D-02:** `ref/2` returns `%{visible, title, full}` where `full == secondary_ref_value(value)` (exact). Reuse the existing `secondary_ref_value/1` dispatch (presentation.ex:360-367) — it already handles `%ActorRef{}` → `"type/id"`, `%{"type","id"}`, JSON-encoded maps, and `to_string`. **Do not** rebuild value extraction.

**D-03 (per-kind truncation):** add a `:kind`-aware `truncate_for/2` that delegates to the extended `truncate_middle/2`. The `:tail_min` extension goes in `truncate_middle/2`:

```elixir
# presentation.ex:58-68 — current truncate_middle; add :tail_min guaranteeing >=8 tail chars
def truncate_middle(value, max_length \\ 34) do
  value = to_string(value || "")
  if String.length(value) <= max_length do
    value
  else
    keep = max(div(max_length - 3, 2), 4)   # <-- replace 4 floor with :tail_min-aware split
    String.slice(value, 0, keep) <> "..." <> String.slice(value, -keep, keep)
  end
end
```

> Note: `export_summary/1` (presentation.ex:151) already calls `truncate_middle(correlation, 28)` — preserve backward compatibility when adding `:tail_min` (default keeps current behavior).

---

### `UI.ref/1` (component, transform) — NEW call-site component

**Analog (copy markup):** the inline copy button at `transaction_live.ex:119-124`; **analog (component shape):** `UI.stat_tile/1` (ui.ex:341-348).

This is the single API that retires the 3 ad-hoc copy wirings. Copy the existing inline `<code>`+button markup, but bind `data-tl-copy={ref.full}` (NOT `.title`).

```elixir
# transaction_live.ex:119-124 — the CURRENT inline pattern (has the D-02 BUG: copies .title)
<:heading>
  Transaction <code title={transaction_ref.title}><%= transaction_ref.visible %></code>
  <button :if={Threadline.OperatorSurface.Script.enabled?()} type="button"
          class="tl-copy tl-button tl-button--compact tl-button--secondary"
          data-tl-copy={transaction_ref.title} aria-label="Copy transaction id">
    <Threadline.OperatorSurface.Components.Icon.icon name={:copy} class="tl-button__icon" />
    Copy
  </button>
</:heading>
```

**Required for `ref/1`:**
- `data-tl-copy={@r.full}` on **both** the `<code>` and the button (D-02/D-06). The `.title` binding above is the live footgun — `ref/1` MUST never bind `.title` or `.visible` to `data-tl-copy`.
- `:if={Threadline.OperatorSurface.Script.enabled?()}` gate stays exactly as shown (D-06). When disabled, render `@r.full` in `<code>` (not `@r.visible`) for zero-JS select-all.
- `copy_label` is a `required` attr with **no default** (D-07) — mirror the `attr(:label, :string, required: true)` style at `stat_tile/1` (ui.ex:337). Visible text `Copy`; specificity in `aria-label`.
- Component skeleton follows `stat_tile/1` (ui.ex:341-348): `@doc false`, `attr` block, single `~H` with `tl-*` classes.

**Attr block to mirror** (from `stat_tile/1`, ui.ex:329-339):
```elixir
@doc false
attr(:value, :any, required: true)
attr(:kind, :string, default: nil)          # uuid|correlation|arn|actor|hash|path|email|url|timestamp
attr(:copy_label, :string, required: true)  # NO default (D-07)
attr(:class, :any, default: nil)
attr(:rest, :global)
```

---

### `UI.kv/1` (component, CRUD/display) — NEW, lift from `row_history_component`

**Analog (exact source to lift):** `snapshot_result/1` `<dl class="tl-kv">` at `row_history_component.ex:173-184`.

```elixir
# row_history_component.ex:173-184 — the canonical correct <dl>; this IS the kv/1 body
<dl class="tl-kv">
  <div :for={{key, token} <- @rows} class="tl-kv__row">
    <dt class="tl-kv__key"><%= key %></dt>
    <dd class="tl-kv__value">
      <span class={["tl-value", token.modifier]} title={Map.get(token, :title)}>
        <%= token.text %>
      </span>
    </dd>
  </div>
</dl>
```

**D-08:** `kv/1` replaces the `:for` over `@rows` with an `:item` slot carrying a **required `key` attr** (slot-attr pattern is established at `tabs/1` ui.ex:653-655 and `card/1` slots ui.ex:161-164). The `<dd>` content becomes `render_slot(item)` so callers drop a `ref/1` (or `value_token` span) inside. Slot-with-attr reference:

```elixir
# ui.ex:653-655 — slot-with-required-attr idiom to mirror for kv's :item
slot :tab, required: true do
  attr(:active, :boolean)
end
```

**Migration targets** (retire `tl-param-list`/`tl-meta` span-soup → `kv`): `transaction_live.ex:127-150` (`tl-param-list` metadata), actor detail header, export per-job filter lists.

---

### `UI.data_table/1` (component, streaming/CRUD) — NEW, mirror CoreComponents `table/1`

**Analog (stream + responsive table):** retention table at `retention_history_live.ex:176-189`; **analog (responsive `data-label`):** coverage table at `coverage_live.ex:212-224`.

```elixir
# retention_history_live.ex:177-189 — the stream + data-label pattern data_table/1 generalizes
<table class="tl-table tl-table--retention tl-table--compact tl-table--sticky tl-table--responsive">
  <thead>
    <tr><th>Status</th><th>Deleted Rows</th><th>Duration</th><th>Date</th><th>Actions</th></tr>
  </thead>
  <tbody id="retention-runs" phx-update="stream" data-testid="retention-runs">
    <tr :for={{dom_id, run} <- @streams.runs} id={dom_id}
        class={["tl-table__row--" <> run.status, if(run.status == "failed", do: "tl-target-row")]}>
      <td data-label="Status"><span class={["tl-chip", Presentation.status_modifier(run.status)]}>…</span></td>
```

```elixir
# coverage_live.ex:221-224 — the th/td data-label pairing data_table/1 must structurally guarantee
<td data-label="TABLE"><code><%= table %></code></td>
<td data-label="STATUS"><span class="tl-chip tl-chip--danger">Needs capture</span></td>
<td data-label="SOURCE">missing trigger</td>
<td data-label="Actions" class="tl-table__actions">…</td>
```

**D-08/D-09 contract for `data_table/1`:**
- `:col` slot with required `label` attr → emit `<th>{label}` AND every `<td data-label={label}>` from the SAME source (structurally guarantees mobile labels match). Slot-attr idiom: ui.ex:653-655.
- `stream` (truthy) → `phx-update="stream"` on `<tbody>` exactly as retention does; `rows` for non-streamed.
- `row_id` → `<tr id={...}>`; `row_status` → existing `data-status` stripe convention (ZERO new CSS — see code_context note). Note retention currently uses `tl-table__row--#{status}` class; `data_table` should standardize on the `data-status` attr per stat_tile (ui.ex:343).
- Always emit `tl-table tl-table--responsive`; pass-through `class` for variant modifiers (`tl-table--coverage`, `tl-table--retention`).
- `:action` slot hosts the kebab; replaces `tl-table--actionable` class-soup (coverage_live.ex:213, `tl-table__actions` cells).
- **NO ARIA `role="table"/"row"/"cell"`** (D-09) — the analogs deliberately have none; do not add them.

---

### `UI.loading_state/1` (component, state) — NEW named sibling

**Analog:** `UI.empty_state/1` (ui.ex:358-368) for the block shape + `UI.spinner/1` (ui.ex:131-138) for the glyph.

```elixir
# ui.ex:358-368 — empty_state block shape to mirror for loading_state
def empty_state(assigns) do
  ~H"""
  <div class={["tl-empty", @variant && "tl-empty--#{@variant}", @class]} {@rest}>
    <h3 :if={@title != []} class="tl-empty__title"><%= render_slot(@title) %></h3>
    <div class="tl-empty__body"><%= render_slot(@inner_block) %></div>
    <div :if={@actions != []} class="tl-empty__actions"><%= render_slot(@actions) %></div>
  </div>
  """
end
```

**D-13/D-15:** `loading_state/1` is its own function (NOT an `empty_state` variant — it is structurally different). `role="status"` + `aria-busy="true"`, render `<.spinner/>` + a **text node** ("Loading audit changes…"). Reuse `spinner/1` (ui.ex:131) verbatim for the accent-stroke spinner.

---

### `UI.stale_banner/1` (component, state) — NEW named sibling

**Analog (exact in-page precedent):** coverage stale strip at `coverage_live.ex:125-129`; **analog (component):** `UI.alert/1` (ui.ex:109-115).

```elixir
# coverage_live.ex:125-129 — the proven role="status" stale strip stale_banner/1 generalizes
<%= if @threadline_coverage_error do %>
  <div class="tl-alert tl-alert--warning" role="status">
    Coverage check failed at <%= now_label() %> — showing last successful result from <%= last_label(@coverage_for_schema.last_checked_at) %>.
  </div>
<% end %>
```

**D-14:** `stale_banner/1` renders ABOVE still-shown data (PRECEDES, never replaces) — it is **NOT** in the `<.async_result>` switch. `role="status"`, refresh/warning icon shape, `as_of` timestamp attr. Mirror `alert/1` (ui.ex:109-115) for the `tl-alert tl-alert--warning` shell; add the timestamp + icon.

---

### `UI.empty_state/1` variant extension (component, state) — EXTEND in place

**Analog:** itself, ui.ex:352.

```elixir
# ui.ex:352 — extend this values list
attr(:variant, :string, default: nil, values: [nil, "error", "never", "unsupported"])
# → add "no_data", "permission", "unavailable"
```

**D-13/D-15/D-16:** add `no_data`, `permission`, `unavailable` to the enum. Each variant's role/icon/heading/microcopy is locked in UI-SPEC §"Data-State Taxonomy" (permission = `role=alert`+lock/shield; no_data = `role=status`+funnel; unavailable = cause-split icon, three sub-cases all stating "NOT a permissions issue"). `error_state/1` (ui.ex:377-385) stays a thin `variant="error"` wrapper — do not touch its delegation.

---

### `transaction_live.ex` (consumer) — copy fix + kv + diff-cell routing

**Analog:** self.

1. **D-02 fix (THE live footgun):** lines 121 and 145 bind `data-tl-copy={...ref.title}` → change to `ref.full` (after migrating to `ref/1`, the component enforces this). Both call sites shown above.
2. **D-08:** `tl-param-list` metadata block (lines 127-150) → `UI.kv/1`.
3. **D-04:** diff before/after cells (lines 196-202) currently render `change_value_token` raw with no copy:
```elixir
# transaction_live.ex:196-202 — raw, untruncated, no copy — the core DATA-01 gap
<% before = Presentation.change_value_token(field, :before) %>
<span class={["tl-value", before.modifier]} title={Map.get(before, :title)}><%= before.text %></span>
<span class="tl-diff__arrow">-&gt;</span>
…
<% after_token = Presentation.change_value_token(field, :after) %>
<span class={["tl-value", after_token.modifier]} title={Map.get(after_token, :title)}><%= after_token.text %></span>
```
Route these through the truncate+gated-copy path (max ~56). `value_token/1` (presentation.ex:239-275) gains truncation; the diff cell gains a gated copy affordance.

---

### `coverage_live.ex` (consumer) — flatten command shell + page_header

**Analog:** the already-correct `page_header` branches in this same file (coverage_live.ex:112-122 form-error branch, :132-142 empty branch).

The defect is NOT literal `card>card` — the success branch (coverage_live.ex:150-200) hand-rolls a header inside a synthetic `tl-coverage-command` shell while the other two branches use `page_header`:

```elixir
# coverage_live.ex:150-171 — DELETE this hand-rolled header + shell; use page_header instead
<section class="tl-coverage-command" aria-labelledby="coverage-command-title">
  <div class="tl-coverage-command__header">
    <div class="tl-coverage-command__heading">
      <h1 id="coverage-command-title" class="tl-page__title">Coverage — schema: <%= @schema_param %></h1>
      <p class="tl-page__lede">Audit readiness by table: …</p>
      <p class="tl-page__meta"><%= Presentation.checked_label(@coverage_for_schema.last_checked_at) %></p>
    </div>
    <div class="tl-coverage-command__actions">
      <button type="button" phx-click="refresh" class="tl-button tl-button--secondary">…Refresh</button>
    </div>
  </div>
  …trust-rail, tl-summary-grid metrics…
</section>
```

```elixir
# coverage_live.ex:112-122 — the CANONICAL page_header to use in ALL THREE branches
<UI.page_header title={"Coverage — schema: #{@schema_param}"}>
  <:lede>Audit readiness by table: fix "Needs capture" before relying on complete timeline answers.</:lede>
  <:actions>
    <button type="button" phx-click="refresh" class="tl-button tl-button--secondary">
      <Threadline.OperatorSurface.Components.Icon.icon name={:refresh} class="tl-button__icon" />
      Refresh
    </button>
  </:actions>
</UI.page_header>
```

**D-12:** delete hand-rolled header → `page_header` (add a `:meta` for `checked_label`); demote the `tl-coverage-command` shell so trust-rail / `tl-summary-grid` / remediation / table become direct page-stack siblings; keep `tl-card--metric` tiles (legit repeated items, coverage_live.ex:187-198); delete dead `tl-coverage-command__*` CSS in `style.ex` (~3336) **paired with** a `style_contract_test.exs` assertion update.

---

### `retention_history_live.ex` (consumer) — T3 server enforcement + data_table

**Analog (handler to replace):** `handle_event("prune_now", …)` at retention_history_live.ex:37-51; **analog (security skeleton):** RESEARCH.md §"T3 destructive enforcement skeleton".

```elixir
# retention_history_live.ex:37-51 — CURRENT handler: NO secure_compare, NO authz re-check, NO audit
def handle_event("prune_now", _params, socket) do
  if not socket.assigns[:threadline_policy_enabled] do
    {:noreply, socket}
  else
    case Pruner.trigger() do
      :ok -> Process.send_after(self(), :refresh, 500); {:noreply, socket}
      {:error, :not_started} -> {:noreply, put_flash(socket, :error, "Retention runtime is not started.")}
    end
  end
end
```

```elixir
# retention_history_live.ex:159 — DELETE this client-only data-confirm (zero server enforcement)
<button class="tl-button tl-button--secondary tl-button--danger" phx-click="prune_now"
        data-confirm="Confirm retention prune. This permanently deletes older audit records; …">
```

**D-20/D-21:** replace with a T3 `modal/1` (ui.ex:406, `focus_first`/`pop_focus`) hosting `<form phx-submit>`; operator types the policy name. The handler must (1) re-check authz, (2) scope-filter the query (forged id fails closed), (3) `Plug.Crypto.secure_compare(typed, canonical_name)` re-fetched from DB, (4) audit the action via `Threadline.Semantics.AuditAction.changeset/2`, (5) fail closed. Keep `Pruner.trigger/0` as the real backend. Streamed runs table (retention_history_live.ex:177-189) migrates to `data_table/1` `stream:`.

> **Redact T3 has NO runtime backend** (research Pitfall 1 / Open Q2). `policy_redaction_live.ex` has no redact `handle_event`. Gate redact with a `checkpoint:human-verify`; do NOT mirror the prune handler against a non-existent backend.

---

### `policy_redaction_live.ex` (consumer) — fix diff-table collapse

**Analog:** self, the 2-col diff table at policy_redaction_live.ex:137-159.

```elixir
# policy_redaction_live.ex:137-158 — KEEP as 2-col diff table (D-10); fix the collapse
<table class="tl-table tl-table--policy tl-table--responsive">
  <thead>
    <tr><th></th><th>Configured</th><th>Deployed</th></tr>   <!-- empty corner th -->
  </thead>
  <tbody>
    <tr>
      <th>exclude</th>   <!-- D-10: needs scope="row" so field name renders when stacked -->
      <td data-label="Configured" class={diff_cell_class(row, :config, :exclude)}>…</td>
      <td data-label="Deployed" class={diff_cell_class(row, :deployed, :exclude)}>…</td>
```

**D-10:** do NOT convert to `kv` (would destroy the Configured-vs-Deployed comparison). Add `scope="row"` to the field `<th>` rows (lines 147, 152, 157) and ensure the field name renders when stacked at ≤480px.

---

### Stress story registration (test fixture) — register every new unit + state

**Analog:** `stress_fixtures.ex` `@state_stories` table (L95-108) + `assigns_for/1` dispatch (L148-206).

```elixir
# stress_fixtures.ex:95-108 — the {id, fixture_key, scenario, cases} story tuple shape to extend
@state_stories [
  {"state.empty", "state.empty", "Empty audit result", ["empty", "zero_count"]},
  {"state.stale-reconnecting", "state.stale_reconnecting", "Stale and reconnecting state",
   ["stale", "reconnecting"]},
  …
]
```

```elixir
# stress_fixtures.ex:170-180 — the per-story assigns_for/1 clause shape to add for each new state
def assigns_for(%{id: "state.permission-denied"}) do
  {:ok, %{title: "Permission denied", body: "…", fallback_label: "Fixture",
          fallback_value: "state.permission_denied", base_path: "/audit"}}
end
```

**Research Open Q3:** add a story + `assigns_for/1` clause for each new component (`ref`, `kv`, `data_table`) and each data-state (loading, stale, no_data, permission, unavailable-down, unavailable-redacted, unavailable-pruned), reusing existing ugly-data fixtures (`long_id`, `permission_denied`, `stale`, `non_ascii` — stress_fixtures.ex:8-18, 415-420). Update `stress_ledger_test.exs` + `stress_router_test.exs` expectations in the same task.

---

## Shared Patterns

### Copy affordance (delegated, CSP-proof)
**Source:** `Threadline.OperatorSurface.Script` (script.ex:34 `enabled?/0`, :48-84 delegated listener).
**Apply to:** every `ref/1` render, `data_table` action cells, coverage command copy, KV/diff copy.
```elixir
# script.ex — the listener already copies data-tl-copy, idempotent via __tlCopyBound, survives patches
document.addEventListener("click", function (e) {
  var btn = e.target.closest("[data-tl-copy]");
  if (!btn) return;
  var text = btn.getAttribute("data-tl-copy");
  …navigator.clipboard.writeText(text)…
});
```
Gate every copy button with `:if={Threadline.OperatorSurface.Script.enabled?()}`. Bind `data-tl-copy={ref.full}` (D-02). Do NOT write a new JS hook (research "Don't Hand-Roll").

### Time display (UTC, relative + absolute)
**Source:** `Presentation.human_time/2` (presentation.ex:10), `exact_time/1` (:29), `checked_label/1` (:33).
**Apply to:** all timestamp cells, stale `as_of`, change times.
```elixir
# D-22 — wrap existing helpers in semantic <time>; helpers already emit UTC-explicit strings
<time datetime={Presentation.exact_time(@dt)} title={Presentation.exact_time(@dt)}>
  <%= Presentation.human_time(@dt) %>
</time>
```
ISO timestamps NEVER truncate (D-03). No live-ticking (deferred — would need JS).

### Status as color + label + shape (never color alone)
**Source:** `Presentation.status_modifier/1` (presentation.ex:70) paired with `status_label/1` (:90); `data-status` stripe (stat_tile ui.ex:343).
**Apply to:** all status cells, row stripes, metric tiles.
```elixir
# always pair the chip class with a label — never color alone (brand-book.md:297)
<span class={["tl-chip", Presentation.status_modifier(run.status)]}><%= Presentation.status_label(run.status) %></span>
```

### Modal + dropdown (focus-correct, CSP-proof, reuse as-is)
**Source:** `UI.modal/1` (ui.ex:406, `show_modal`/`focus_first` :439-450), `UI.dropdown/1` (ui.ex:629, `role=menu`/`aria-haspopup`), `UI.divider/1` (ui.ex:121).
**Apply to:** T2/T3 confirmations (modal), per-row kebab (dropdown). Destructive items render LAST after `<.divider/>` with `tl-button--danger` + non-color cue (D-18). Reuse verbatim — do not rebuild disclosure/focus-trap (research "Don't Hand-Roll").

### Component shape conventions (173/174/175)
**Source:** every function in `ui.ex` — `@doc false`, `attr(...)` / `slot(...)` blocks, single `~H`, `tl-*` BEM classes, `attr(:rest, :global)`, `attr(:class, :any, default: nil)`.
**Apply to:** `ref/1`, `kv/1`, `data_table/1`, `loading_state/1`, `stale_banner/1`. Mirror `stat_tile/1` (ui.ex:329-348) for the simplest attr-only component and `card/1` (ui.ex:152-179) for slotted components.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `assign_async`/`<.async_result>` dispatch | LiveView state dispatch | event-driven | **No `assign_async` exists anywhere in the surface today** (research Open Q1 — all 11 LiveViews load synchronously in `mount`). Closest in-tree idiom: the manual `case`/`<%= if %>` state branching at `coverage_live.ex:110-149` (form_error / coverage_error / all_empty? branches) and `snapshot_result/1` clause-dispatch at `row_history_component.ex:170-208` (pattern-matching `{:ok, _}` / `{:error, :deleted_record}` / `{:error, :before_audit_horizon}`). **Planner decision (Open Q1):** the data-state TAXONOMY (loading/stale/no_data/permission/unavailable components) is the hard requirement; `assign_async` is the recommended-but-per-page means. Pages that load fast in-DB may keep synchronous load + the explicit `case` branching shown in `snapshot_result/1` and still satisfy DATA-03. Use the LV best-practices research doc (`prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md`) for the canonical `<.async_result>` shape since no local analog exists. |
| Runtime "redact one stored value" backend | service / destructive | CRUD (write) | **No runtime redaction operation exists** (research Pitfall 1 / Open Q2 — redaction is codegen-time only in `capture/redaction_policy.ex` + `trigger_sql.ex`; `policy_redaction_live.ex` is read-only with no redact `handle_event`). The T3 prune handler (retention_history_live.ex:37) is the only real destructive backend to model. Gate redact with `checkpoint:human-verify` before planning any handler. |
| Card-nesting regression test (D-12) | test | — | No existing test refutes card-family nesting across rendered pages. Closest analogs: `style_contract_test.exs` (string assertions over `style.ex`) for the assertion style, and the 11 LiveView render tests for the page-rendering harness. New test renders each of the 11 pages and `refute`s any `tl-card*` class nested under another `tl-card*` class. |
| Missing icons (`eye_off`, `plug`/`cloud_off`, `lock`, `funnel`) | utility (icon) | — | Icon registry currently has `history`, `shield`, `filter_x`, `archive`, `trash`, `refresh`, `copy`, `search`, `warning` (verified in icon.ex) but NOT `eye_off`/`plug`/`cloud_off`/`lock`/`funnel`. Add only the missing glyphs per the existing `icon.ex` registry shape (D-15 / research A5). |

---

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/` (ui.ex, presentation.ex, script.ex, components/icon.ex, stress_fixtures.ex, stress_live.ex), `lib/threadline/operator_surface/live/` (transaction, retention_history, policy_redaction, coverage, row_history_component), `test/threadline/operator_surface/stress_*`.
**Files scanned:** 14 source files read/grepped; line:col anchors verified against the working tree (consistent with RESEARCH.md's verified map).
**Pattern extraction date:** 2026-06-17
