# Phase 113: Adopter Truth & Doc Sync — Patterns

**Mapped:** 2026-05-27

## Files to Create/Modify

| File | Role | Closest analog |
|------|------|----------------|
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | Add `my_evidence_authorize_fn/1` + mount opt | `my_export_authorize_fn/1` at `:84-89`, mount at `:138-144` |
| `examples/threadline_phoenix/README.md` | Evidence gate prose + mount snippet | Export denial prose at `:241-250` |
| `guides/getting-started-saas.md` | Mount snippet + evidence gate paragraph | Export/scope prose at `:222-240` |
| `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` | Admin vs support evidence access | Export denial test at `:49-60` |
| `examples/threadline_phoenix/WALKTHROUGH.md` | WALK-03-02 fiction + §5 CLI footnote | WALK-03-01 time anchors at `:458-459` |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` | Leaving-agent count == 12 + tickets join | `"SEED-03 leaving agent window"` at `:105-126` |
| `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` | Literal lock pattern | Existing RUN-01 literals at `:10-18` |
| `guides/adoption-pilot-backlog.md` | Distribution preflight 0.5.x | Stale 0.2.0 rows at `:11-13` |
| `test/threadline/adoption_pilot_doc_contract_test.exs` | Version SSOT doc contract | `release_artifact_contract_test.exs` / `readme_doc_contract_test.exs` |
| `test/threadline/evidence_cli_doc_contract_test.exs` | Canonical CLI doc contract | `getting_started_saas_doc_contract_test.exs` refute pattern |
| `mix.exs` | Wire new tests into `verify.doc_contract` | Line ~81 alias list |
| `.planning/PROJECT.md`, `.planning/MILESTONES.md` | Living index canonical CLI | D-113-02f |
| `.planning/milestones/v1.23-REQUIREMENTS.md` | WALK-04 errata | Immutable checkbox + errata block |
| `.planning/milestones/v1.23-ROADMAP.md` | WALK-04 errata | Same pattern |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | Assert evidence_authorize_fn in mount | `export_authorize_fn` assert at `:79` |
| `test/threadline/example_phoenix_readme_contract_test.exs` | Assert evidence in README mount | `export_authorize_fn` assert at `:92` |

## Pattern: Admin-only capability gate (`*_authorize_fn`)

**Source:** `router.ex:84-89` (`my_export_authorize_fn/1`)

```elixir
def my_export_authorize_fn(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{is_admin: true} -> :ok
    _ -> {:error, :unauthorized}
  end
end
```

**Target:** parallel `my_evidence_authorize_fn/1` — same shape, separate function (D-113-01c).

**Mount wiring:**

```elixir
threadline_operator_surface("/",
  ...
  export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
  evidence_authorize_fn: &ThreadlinePhoenixWeb.Router.my_evidence_authorize_fn/1,
  scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
  ...
)
```

## Pattern: Example operator surface auth test

**Source:** `operator_surface_test.exs:49-60` (support export 403)

Evidence denied-state HTML from lib test:

```elixir
assert html =~ "Evidence view unavailable."
```

(`evidence_live_test.exs:113`)

**Target example test shape:**

```elixir
test "admin can reach evidence surface", %{conn: conn} do
  user = user_fixture(email: "admin@example.com")
  ...
  conn = login_via_sigra(conn, user) |> get("/audit/evidence")
  refute html_response(conn, 200) =~ "Evidence view unavailable."
end

test "support user sees unsupported evidence view", %{conn: conn} do
  ...
  conn = login_via_sigra(conn, user) |> get("/audit/evidence")
  assert html_response(conn, 200) =~ "Evidence view unavailable."
end
```

## Pattern: Doc-contract version SSOT

**Source:** `MixProject.project()[:version]` in existing contract tests

```elixir
@version MixProject.project()[:version]

test "adoption-pilot distribution preflight matches mix.exs version" do
  guide = File.read!("guides/adoption-pilot-backlog.md")
  assert guide =~ @version
  assert guide =~ "~> 0.5"
  refute guide =~ "0.2.0"
  refute guide =~ "~> 0.2"
end
```

## Pattern: Walkthrough literal lock (not prose lock)

**Source:** `walkthrough_doc_contract_test.exs:10-18`

Add anchors only:

```elixir
for literal <- ["demo_last_tuesday", "demo_epoch", "33123cc4-da21-5674-b030-e168cee90521"] do
  assert String.contains?(doc, literal)
end
```

Do **not** assert full operator-question sentence or refute `"last 24 hours"`.

## Pattern: Leaving-agent demo contract

**Source:** `anchors.ex:13` `@leaving_agent_tx_count 12`

```elixir
from_ts = Manifest.last_tuesday()
to_ts = Manifest.epoch()
assert count == 12

ticket_changes =
  Repo.aggregate(
    from(ac in AuditChange,
      join: at in assoc(ac, :transaction),
      where: ac.table_name == "tickets",
      where: fragment("? @> ?::jsonb", at.actor_ref, ^ActorRef.to_map(agent2_ref)),
      where: at.occurred_at >= ^from_ts,
      where: at.occurred_at <= ^to_ts
    ),
    :count
  )

assert ticket_changes >= 1
```

## Pattern: Planning milestone errata (immutable checkbox)

**Source:** D-113-05c — do not rewrite closed `[x]` items

```markdown
> **Errata (2026-05-27, Phase 113):** The runnable evidence viewer is `mix threadline.evidence.show` only. `mix verify.evidence` was planned but never shipped; see `guides/domain-reference.md`.

- [x] **WALK-04**: Evidence section — ...
```

## PATTERN MAPPING COMPLETE
