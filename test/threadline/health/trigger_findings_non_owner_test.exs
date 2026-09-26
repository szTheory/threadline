defmodule Threadline.Health.TriggerFindingsNonOwnerTest do
  use Threadline.DataCase

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.TriggerSQL
  alias Threadline.Health

  @repo Threadline.Test.Repo

  test "a zero-grant NOLOGIN role reads the same findings as the owner" do
    role = "threadline_findings_probe_#{System.unique_integer([:positive])}"
    quoted_role = ~s("#{role}")

    SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_role CASCADE", [])
    SQL.query!(@repo, "CREATE SCHEMA hlth_find_role", [])
    SQL.query!(@repo, "CREATE TABLE hlth_find_role.disabled_t (id bigserial PRIMARY KEY)", [])
    SQL.query!(@repo, TriggerSQL.create_trigger("hlth_find_role.disabled_t"), [])

    SQL.query!(
      @repo,
      "ALTER TABLE hlth_find_role.disabled_t DISABLE TRIGGER threadline_audit_hlth_find_role_disabled_t",
      []
    )

    SQL.query!(@repo, "CREATE ROLE #{quoted_role} NOLOGIN", [])

    on_exit(fn ->
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_role CASCADE", [])
      SQL.query!(@repo, "DROP ROLE IF EXISTS #{quoted_role}", [])
    end)

    owner_findings = Health.trigger_findings(repo: @repo, schema: "hlth_find_role")
    assert owner_findings != []
    assert [%{code: :capture_trigger_disabled}] = owner_findings

    {:ok, {role_findings, current_user, has_usage}} =
      Repo.transaction(fn ->
        SQL.query!(@repo, "SET LOCAL ROLE #{quoted_role}", [])

        %{rows: [[current_user]]} = SQL.query!(@repo, "SELECT current_user", [])

        %{rows: [[has_usage]]} =
          SQL.query!(
            @repo,
            "SELECT has_schema_privilege($1, 'hlth_find_role', 'USAGE')",
            [role]
          )

        findings = Health.trigger_findings(repo: @repo, schema: "hlth_find_role")

        {findings, current_user, has_usage}
      end)

    assert current_user == role
    assert has_usage == false
    assert role_findings == owner_findings

    SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_role CASCADE", [])
    SQL.query!(@repo, "DROP ROLE IF EXISTS #{quoted_role}", [])

    %{rows: rows} = SQL.query!(@repo, "SELECT 1 FROM pg_roles WHERE rolname = $1", [role])
    assert rows == []
  end
end
