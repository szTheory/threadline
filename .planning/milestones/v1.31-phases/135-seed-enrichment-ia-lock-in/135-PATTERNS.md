# Phase 135: Seed Enrichment & IA Lock-In - Pattern Map

**Mapped:** 2026-06-03
**Files analyzed:** 9 new/modified files
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` | test (doc-contract) | request-response | `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` | exact |
| `test/threadline/ia_lock_doc_contract_test.exs` | test (doc-contract) | request-response | `test/threadline/operator_surface_doc_contract_test.exs` | exact |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` | test (integration, extend) | CRUD | self — extend existing file | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex` | utility (extend) | request-response | self — refactor existing functions | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex` | seed (extend) | CRUD | `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` | role-match |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` | seed (extend) | CRUD | self — extend existing module | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex` | seed (extend) | CRUD | self — extend existing module | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex` | config/SSOT (extend) | — | self — extend with named actor literals | exact |
| `.planning/milestones/v1.31-PERSONAS-IA.md` | docs (extend) | — | `.planning/milestones/v1.31-UI-AUDIT.md` | role-match |

---

## Pattern Assignments

### `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` (NEW — doc-contract test)

**Analog:** `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs`

**Module header + file path pattern** (lines 1–5):
```elixir
defmodule ThreadlinePhoenix.WalkthroughDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @walkthrough Path.expand("../../WALKTHROUGH.md", __DIR__)
```

The new test mirrors this exactly, pointing at `DEMO-MANIFEST.md` instead:
```elixir
defmodule ThreadlinePhoenix.DemoManifestContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @manifest Path.expand("../../DEMO-MANIFEST.md", __DIR__)
```

**Core assertion pattern** (lines 9–25 of analog):
```elixir
test "WALKTHROUGH.md carries walk-critical literals for RUN-01 self-containment" do
  doc = File.read!(@walkthrough)

  for literal <- [
        "4521",
        "4518",
        ...
      ] do
    assert String.contains?(doc, literal),
           "expected WALKTHROUGH.md to include #{inspect(literal)}"
  end
end
```

The new test uses the same `File.read!/1` + `String.contains?/2` + per-literal `assert` pattern. Key literals to assert for the recipe table (D-03):
- `"## State recipes"` — the recipe-table section header
- `"empty"` — empty-state row
- `"offboarded-co.example.com"` — scoped-empty login
- `"support@offboarded-co.example.com"` — the scoped support persona
- `"?from=2030"` or similar — future-date filter for filter-empty state
- Screen names present in recipe table: `"Timeline"`, `"Transactions"`, `"Actor"`, `"Row History"`
- `"Named actor literals"` — new DEMO-MANIFEST.md section D-06

**Describe block pattern** (lines 28–50 of analog) — use `describe` blocks for logical groupings (recipe table assertions, named actor literals assertions):
```elixir
describe "recipe table covers expected screens" do
  test "section header present" do ...
  test "empty-state recipes present" do ...
end
```

**Important separation note:** The existing `demo_manifest_test.exs` tests the `ThreadlinePhoenix.Demo.Manifest` Elixir module (not the `.md` file). This new file tests only the `.md` doc. Do NOT merge into `demo_manifest_test.exs`.

---

### `test/threadline/ia_lock_doc_contract_test.exs` (NEW — library suite doc-contract test)

**Analog:** `test/threadline/operator_surface_doc_contract_test.exs`

**Module header + file-path pattern** (lines 1–4 of analog):
```elixir
defmodule Threadline.OperatorSurfaceDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true
```

For this test, paths must resolve from the library test root (`test/threadline/`) up to `.planning/milestones/`:
```elixir
defmodule Threadline.IaLockDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @personas_ia Path.expand("../../.planning/milestones/v1.31-PERSONAS-IA.md", __DIR__)
  @ui_audit Path.expand("../../.planning/milestones/v1.31-UI-AUDIT.md", __DIR__)
```

**Multi-assert per-string pattern** (analog lines 5–9):
```elixir
test "README declares the operator surface mount macro" do
  readme = File.read!("README.md")
  assert String.contains?(readme, "threadline_operator_surface")
end
```

The IA lock test must assert ~15 items. Follow the one-assert-per-test pattern (not a loop) OR use the loop pattern from `walkthrough_doc_contract_test.exs` lines 9–25 for persona/JTBD/EF batches:

```elixir
# Option A — loop (compact, like walkthrough_doc_contract_test.exs)
test "PERSONAS-IA.md contains all persona IDs P1–P5" do
  doc = File.read!(@personas_ia)
  for id <- ~w(P1 P2 P3 P4 P5) do
    assert String.contains?(doc, id),
           "expected v1.31-PERSONAS-IA.md to contain #{inspect(id)}"
  end
end

test "PERSONAS-IA.md contains all JTBD IDs J1–J11" do
  doc = File.read!(@personas_ia)
  for id <- ~w(J1 J2 J3 J4 J5 J6 J7 J8 J9 J10 J11) do
    assert String.contains?(doc, id),
           "expected v1.31-PERSONAS-IA.md to contain #{inspect(id)}"
  end
end

test "PERSONAS-IA.md contains all earned flow IDs EF1–EF5" do
  doc = File.read!(@personas_ia)
  for id <- ~w(EF1 EF2 EF3 EF4 EF5) do
    assert String.contains?(doc, id),
           "expected v1.31-PERSONAS-IA.md to contain #{inspect(id)}"
  end
end

test "PERSONAS-IA.md contains the Find/Verify/Prove triad" do
  doc = File.read!(@personas_ia)
  assert String.contains?(doc, "Find/Verify/Prove") or
           String.contains?(doc, "Find / Verify / Prove")
end

test "v1.31-UI-AUDIT.md contains the D-17 IA pointer line" do
  doc = File.read!(@ui_audit)
  assert String.contains?(doc, "v1.31-PERSONAS-IA.md")
  assert String.contains?(doc, "P1–P5")
end
```

**Sequencing constraint (Pitfall 4):** EF1–EF5 tests will be red until D-16 writes EF IDs into `v1.31-PERSONAS-IA.md`. Write the test file and D-16 edits in the same Wave 0 task so both pass together.

---

### `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` (EXTEND existing)

**Pattern source:** self — add a new `describe` block to the existing file.

**Existing setup pattern** (lines 1–20):
```elixir
defmodule ThreadlinePhoenix.DemoContractTest do
  use ThreadlinePhoenix.DataCase, async: false
  @moduletag :demo_contract

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  ...

  setup do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      assert :ok = Reset.run()
    end)
    :ok
  end
```

The seed runs once in `setup`. New assertions must NOT re-seed — they read post-setup state.

**In-window assertion pattern** — mirror the existing `describe "SEED-03 leaving agent window"` block (lines 105–156), but query for op types instead of actor ref:

```elixir
describe "D-13 in-window variety guarantee" do
  test "default 24h window contains ≥1 UPDATE and ≥1 DELETE" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      window_start = DateTime.utc_now() |> DateTime.add(-24, :hour)

      for op <- ["update", "delete"] do
        count =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.op == ^op,
              where: at.occurred_at >= ^window_start,
              select: count(ac.id)
            )
          )

        assert count >= 1,
               "expected ≥1 #{op} in default 24h window, got #{count}"
      end
    end)
  end
end
```

**Key pattern notes:**
- `Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn -> ... end)` — required wrapper for all queries in this test file (lines 17–19, 41, 70, 107, etc.)
- `from(ac in AuditChange, join: at in assoc(ac, :transaction), ...)` — the join pattern for change+transaction queries (established at lines 47–56)
- `at.occurred_at >= ^window_start` — time-window filter pattern (line 131 uses `>=` and `<=` for the leaving-agent window)

---

### `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex` (EXTEND — D-07 generalization)

**Pattern source:** self — refactor two existing functions.

**Current `set_actor_guc!/1`** (lines 57–66):
```elixir
def set_actor_guc!(user_id) when is_binary(user_id) do
  {:ok, actor_ref} = ActorRef.new(:user, user_id)

  json =
    actor_ref
    |> Threadline.Semantics.ActorRef.to_map()
    |> Jason.encode!()

  Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
end
```

**Generalized shape** — add `kind` default param (D-07); add `set_anonymous_actor_guc!/0` for `:anonymous` (no id):
```elixir
def set_actor_guc!(actor_id, kind \\ :user)
    when is_binary(actor_id) and kind in [:user, :admin, :service_account, :job, :system] do
  {:ok, actor_ref} = ActorRef.new(kind, actor_id)

  json =
    actor_ref
    |> Threadline.Semantics.ActorRef.to_map()
    |> Jason.encode!()

  Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
end

def set_anonymous_actor_guc! do
  {:ok, actor_ref} = ActorRef.new(:anonymous)

  json =
    actor_ref
    |> Threadline.Semantics.ActorRef.to_map()
    |> Jason.encode!()

  Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
end
```

**Current `audit_context/2`** (lines 19–27):
```elixir
def audit_context(user_id, opts \\ []) when is_binary(user_id) do
  {:ok, actor_ref} = ActorRef.new(:user, user_id)

  %Threadline.Semantics.AuditContext{
    actor_ref: actor_ref,
    correlation_id: Keyword.get(opts, :correlation_id),
    request_id: Keyword.get(opts, :request_id, "demo-seed")
  }
end
```

**Generalized shape** — accept `kind:` keyword option with `:user` default:
```elixir
def audit_context(actor_id, opts \\ []) when is_binary(actor_id) do
  kind = Keyword.get(opts, :kind, :user)
  {:ok, actor_ref} = ActorRef.new(kind, actor_id)

  %Threadline.Semantics.AuditContext{
    actor_ref: actor_ref,
    correlation_id: Keyword.get(opts, :correlation_id),
    request_id: Keyword.get(opts, :request_id, "demo-seed")
  }
end
```

All existing callers (`anchors.ex`, `filler.ex`) pass a positional `user_id` only — they continue to work unchanged with the `:user` default.

---

### `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex` (EXTEND — D-05 fix)

**Analog for fix pattern:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` — specifically `seed_leaving_agent_window` (lines 131–158), which wraps mutations in `Repo.transaction` + `set_actor_guc!` + `put_timestamp`.

**Root-cause site — bare inserts without actor GUC** (`personas.ex` lines 126–148):
```elixir
defp ensure_membership!(%Organization{} = org, user_id, role) do
  case Repo.get_by(OrgMembership, ...) do
    nil ->
      %OrgMembership{...}
      |> OrgMembership.changeset(%{role: role})
      |> Repo.insert!()   # <— no set_actor_guc!, no Repo.transaction, no put_timestamp
  end
end

defp ensure_agent!(%Organization{} = org, user_id, display_name) do
  case Repo.get_by(Agent, ...) do
    nil ->
      %Agent{...}
      |> Agent.changeset(%{display_name: display_name})
      |> Repo.insert!()   # <— same: no actor, no backdate
  end
end
```

**Fix pattern to copy from `anchors.ex` `seed_leaving_agent_window`** (lines 140–157):
```elixir
{:ok, tx_id} =
  Repo.transaction(fn ->
    Support.set_actor_guc!(leaving_id)   # set actor BEFORE the insert/update
    # ... Repo.insert! or Repo.update! ...
    Support.stamp_org_meta!(acme)        # org meta on the tx (optional for personas)
    Support.current_audit_transaction_id!()  # capture tx id for backdate
  end)

ts = Manifest.last_tuesday()            # OR DateTime.add(demo_epoch, -N, :day)
Support.put_timestamp(acc, tx_id, ts)   # register for Temporal.run backdate
```

**D-05 fix shape for `seed_memberships`** — wrap each org's membership+agent setup in ONE `Repo.transaction`, using `:admin` kind (D-06 says ~15% admin):
```elixir
defp seed_memberships(ctx) do
  admin_id = to_string(Map.fetch!(ctx.users, :admin).id)

  Enum.reduce(Map.keys(ctx.orgs), ctx, fn org_slug, acc ->
    org = Map.fetch!(acc.orgs, org_slug)
    setup_ts = DateTime.add(Manifest.epoch(), -21, :day)  # far outside 24h window

    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(admin_id, :admin)   # D-07 kind param
        ensure_membership!(org, admin_id, "support")
        ensure_agent!(org, admin_id, "Admin")
        # ... persona members ...
        Support.current_audit_transaction_id!()
      end)

    Support.put_timestamp(acc, tx_id, setup_ts)
  end)
end
```

**Critical constraint:** The backdate timestamp for persona setup rows must be **far outside** the 24h window (e.g., `DateTime.add(Manifest.epoch(), -21, :day)`). This prevents them from appearing above the fold in the default Timeline view (the D-05 symptom). Do NOT use `DateTime.utc_now()` for setup rows.

---

### `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` (EXTEND — D-10/D-11/D-12 variety pack)

**Pattern source:** self — extend `run/1` with a new `seed_variety_pack/1` function after `seed_active_agent_window`.

**In-window wall-clock anchor pattern** (lines 33–58 of `anchors.ex`):
```elixir
defp seed_active_agent_window(ctx) do
  ...
  [1, 3, 6]
  |> Enum.with_index()
  |> Enum.reduce(ctx, fn {hours_ago, idx}, acc ->
    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(active_id)
        # ... mutation ...
        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts = DateTime.utc_now() |> DateTime.add(-hours_ago, :hour)
    Support.put_timestamp(acc, tx_id, ts)   # registers for Temporal.run backdate
  end)
end
```

**Critical note — in-window rows MUST still call `put_timestamp`:** `Temporal.run` uses `UPDATE ... SET occurred_at = $1` to overwrite with the timestamp registered in `ctx.timestamps`. For in-window rows, the timestamp registered is `DateTime.utc_now() |> DateTime.add(-N, :hour)` — a recent wall-clock value. They ARE added to `ctx.timestamps`. Temporal.run then sets `occurred_at` to that recent value, which keeps them in the 24h window. The key is the timestamp VALUE is wall-clock-recent, NOT that they skip `put_timestamp`. (This is what `seed_active_agent_window` does at line 57: `ts = DateTime.utc_now() |> DateTime.add(-hours_ago, :hour); Support.put_timestamp(acc, tx_id, ts)`.)

**DELETE pattern** — copy from `seed_acme_delete` (lines 89–129), which does:
1. `HelpDesk.delete_reply(deleter_ctx, acme, reply)` → for HelpDesk-API-backed DELETEs
2. Or raw `Repo.transaction` + `Repo.delete!` for direct variety-pack DELETEs (same `Repo.transaction` wrapper pattern)

**UPDATE + before→after diff pattern** — the reply-edit story (D-12 story 1) must use the HelpDesk API for `ticket_replies` to capture the `store_changed_from` diff. Pattern from `seed_acme_close` (lines 62–87) using `HelpDesk.ticket_replied_and_closed/6`. For the body-edit specifically, use two-step: INSERT reply (get `reply.id`), then UPDATE via `Repo.update!` in a new transaction with `set_actor_guc!`.

**Run pipeline extension** — extend `run/1` at line 17:
```elixir
def run(ctx) do
  ctx
  |> seed_acme_close()
  |> seed_acme_delete()
  |> seed_leaving_agent_window()
  |> seed_active_agent_window()
  |> seed_globex_close_sample()
  |> seed_variety_pack()   # D-11/D-12 in-window variety: 5 INSERT / 4 UPDATE / 2 DELETE
end
```

---

### `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex` (EXTEND — D-11 DELETE branch)

**Pattern source:** self — extend `insert_filler_ticket/4` (lines 66–103).

**Existing INSERT+UPDATE pattern** (lines 66–103):
```elixir
defp insert_filler_ticket(ctx, %Organization{} = org, number, agent_user_ids) do
  user_id = Enum.at(agent_user_ids, :rand.uniform(length(agent_user_ids)) - 1)
  agent = Repo.get_by!(Agent, organization_id: org.id, user_id: user_id)
  status = if rem(number, 3) == 0, do: "closed", else: "open"

  {:ok, tx_id} =
    Repo.transaction(fn ->
      Support.set_actor_guc!(user_id)

      ticket =
        %Ticket{organization_id: org.id}
        |> Ticket.changeset(%{number: number, status: "open", assignee_id: agent.id})
        |> Repo.insert!()

      if status == "closed" do
        ticket
        |> Ticket.changeset(%{status: "closed", closed_at: ThreadlinePhoenix.Demo.Manifest.epoch()})
        |> Repo.update!()
      else
        ticket
        |> Ticket.changeset(%{status: "in_progress"})
        |> Repo.update!()
      end

      Support.stamp_org_meta!(org)
      Support.current_audit_transaction_id!()
    end)

  ts = Support.random_days_ago_timestamp()
  Support.put_timestamp(ctx, tx_id, ts)
end
```

**DELETE branch to add** — shift from ~95% INSERT to ~55/35/10 (D-11). Add a `rem(number, 10) == 0` branch that does `Repo.delete!` after INSERT, producing a DELETE audit_change in the same transaction:
```elixir
status_roll = rem(number, 10)
# 0 → delete (10%), 1..3 → closed UPDATE (30–35%), else → open/in_progress UPDATE (55–60%)

if status_roll == 0 do
  Repo.delete!(ticket)   # DELETE branch — corpus DELETE for wide-date-range counts
end
```

The `Repo.transaction` wrapper and `set_actor_guc!` pattern stay identical. Only the inner conditional changes. The `Support.random_days_ago_timestamp()` call remains (filler rows are epoch-relative, not in-window).

---

### `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex` (EXTEND — D-06 named actor literals)

**Pattern source:** self — extend with named actor literal constants and accessors.

**Existing constant + accessor pattern** (lines 62–73, 113–117):
```elixir
@demo_epoch ~U[2026-05-27 12:00:00Z]
@demo_last_tuesday ~U[2026-05-20 14:30:00Z]
@correlation_acme_close "walk-acme-4521-close"

def epoch, do: @demo_epoch
def last_tuesday, do: @demo_last_tuesday
def correlation_id(:acme_4521_close), do: @correlation_acme_close
```

**Pattern to add for named actor literals** — module attributes + accessor function:
```elixir
# Named actor literals (D-06) — used in seed clusters and DEMO-MANIFEST.md
@actor_zendesk_sync "zendesk-sync"
@actor_oban_retention_purge "oban-retention-purge"
@actor_trigger_backfill "trigger-backfill"

@doc "Named actor id for a non-human seed actor (:zendesk_sync, :oban_retention_purge, :trigger_backfill)."
def actor_id(:zendesk_sync), do: @actor_zendesk_sync
def actor_id(:oban_retention_purge), do: @actor_oban_retention_purge
def actor_id(:trigger_backfill), do: @actor_trigger_backfill
```

**ActorRef construction at call sites** — the seed calls these like:
```elixir
Support.set_actor_guc!(Manifest.actor_id(:zendesk_sync), :service_account)
Support.set_actor_guc!(Manifest.actor_id(:oban_retention_purge), :job)
Support.set_actor_guc!(Manifest.actor_id(:trigger_backfill), :system)
# anonymous: no id
Support.set_anonymous_actor_guc!()
```

---

## Shared Patterns

### `Repo.transaction` + `set_actor_guc!` + `current_audit_transaction_id!` + `put_timestamp`
**Source:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` lines 44–58
**Apply to:** Every new seed mutation in `Anchors.seed_variety_pack/1`, `Personas.seed_memberships/1` fix, `Filler.insert_filler_ticket/4` DELETE branch

```elixir
{:ok, tx_id} =
  Repo.transaction(fn ->
    Support.set_actor_guc!(actor_id)          # must be FIRST inside transaction
    # ... Repo.insert! / Repo.update! / Repo.delete! ...
    Support.stamp_org_meta!(org)              # optional; sets meta.organization_id on tx
    Support.current_audit_transaction_id!()  # returns tx id for put_timestamp
  end)

ts = DateTime.utc_now() |> DateTime.add(-hours_ago, :hour)  # in-window: wall-clock-relative
# OR
ts = DateTime.add(Manifest.epoch(), -N, :day)                # epoch-relative: for corpus/setup rows

Support.put_timestamp(ctx, tx_id, ts)
```

### `unboxed_run` test wrapper
**Source:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` lines 17–19, 41
**Apply to:** All new assertions in `demo_contract_test.exs` (D-13 describe block)

```elixir
Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
  # ... Repo queries ...
end)
```

### `Path.expand/2` for doc-contract file paths
**Source:** `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` line 5
**Apply to:** Both new doc-contract test modules

```elixir
@manifest Path.expand("../../DEMO-MANIFEST.md", __DIR__)
# library suite (two levels up from test/threadline/ to project root, then into .planning/):
@personas_ia Path.expand("../../.planning/milestones/v1.31-PERSONAS-IA.md", __DIR__)
```

### `String.contains?/2` + per-literal assert message
**Source:** `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` lines 9–25
**Apply to:** Both new doc-contract test modules for all literal checks

```elixir
assert String.contains?(doc, literal),
       "expected <filename> to include #{inspect(literal)}"
```

### AuditChange + AuditTransaction join query
**Source:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` lines 47–56, 123–136
**Apply to:** D-13 in-window guarantee assertion in `demo_contract_test.exs`

```elixir
from(ac in AuditChange,
  join: at in assoc(ac, :transaction),
  where: ac.op == ^op,
  where: at.occurred_at >= ^window_start,
  select: count(ac.id)
)
```

---

## No Analog Found

All files have analogs. No entries.

---

## Sequencing Constraints for Planner

These are ordering requirements derived from the pattern analysis:

1. **D-07 before D-06 clusters:** `Support.set_actor_guc!/2` (with `kind` param) must exist before any non-`:user` actor cluster is inserted. Generalize `support.ex` first.

2. **D-16 before D-18:** EF1–EF5 must be written into `v1.31-PERSONAS-IA.md` before the `ia_lock_doc_contract_test.exs` EF assertions can pass. Both should land in the same Wave 0 task.

3. **D-05 fix before D-13 assertion:** The D-05 `Personas` fix (actor + backdate) must be in place before the D-13 in-window query is added to `demo_contract_test.exs`, because the test reads post-setup state and the variety-pack inserts depend on `set_actor_guc!/2` being available.

4. **In-window rows bypass is a TIMESTAMP VALUE choice, not a `put_timestamp` skip:** All variety-pack mutations (D-12) call `put_timestamp` — but with a `DateTime.utc_now() |> DateTime.add(-N, :hour)` value (stays in 24h window). Only epoch-relative rows (corpus, setup) use `DateTime.add(Manifest.epoch(), -N, :day)`. Never use `DateTime.utc_now()` for setup/persona rows.

---

## Metadata

**Analog search scope:** `examples/threadline_phoenix/`, `test/threadline/`, `lib/`
**Files read:** 10
**Pattern extraction date:** 2026-06-03

---

## PATTERN MAPPING COMPLETE

**Phase:** 135 - Seed Enrichment & IA Lock-In
**Files classified:** 9
**Analogs found:** 9 / 9

### Coverage
- Files with exact analog: 7 (self-extensions + direct test analogs)
- Files with role-match analog: 2 (`personas.ex` → `anchors.ex` fix pattern; `v1.31-PERSONAS-IA.md` → `v1.31-UI-AUDIT.md` header convention)
- Files with no analog: 0

### Key Patterns Identified
- All seed mutations use `Repo.transaction` + `Support.set_actor_guc!` + `Support.current_audit_transaction_id!` + `Support.put_timestamp` — the four-step idiom in `anchors.ex` is the canonical template
- In-window rows use wall-clock-relative timestamps (`DateTime.utc_now() |> DateTime.add(-N, :hour)`) passed to `put_timestamp` — the value is recent, not the skip of `put_timestamp` itself
- Doc-contract tests in both suites use `async: true`, `Path.expand/2` for file paths, and `String.contains?/2` with per-item assert messages
- `demo_contract_test.exs` uses `@moduletag :demo_contract`, `async: false`, `unboxed_run` wrappers for all DB queries

### File Created
`.planning/phases/135-seed-enrichment-ia-lock-in/135-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in PLAN.md files.
