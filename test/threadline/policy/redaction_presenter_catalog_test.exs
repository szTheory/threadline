defmodule Threadline.Policy.RedactionPresenterCatalogTest do
  use Threadline.DataCase

  alias Threadline.Capture.TriggerSQL
  alias Threadline.Policy.RedactionPresenter

  @repo Threadline.Test.Repo
  @table "threadline_redaction_presenter_users"

  setup_all do
    @repo.query!("DROP TABLE IF EXISTS #{@table}")

    @repo.query!("""
    CREATE TABLE #{@table} (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      email text NOT NULL,
      password_hash text NOT NULL,
      display_name text NOT NULL DEFAULT ''
    )
    """)

    on_exit(fn ->
      @repo.query!(TriggerSQL.drop_trigger(@table))
      @repo.query!(TriggerSQL.drop_function_for_table(@table))
      @repo.query!("DROP TABLE IF EXISTS #{@table}")
    end)

    :ok
  end

  setup do
    original = Application.get_env(:threadline, :trigger_capture)

    Application.put_env(:threadline, :trigger_capture,
      tables: %{
        @table => [
          exclude: ["password_hash"],
          mask: ["email"],
          mask_placeholder: "[REDACTED]"
        ]
      }
    )

    @repo.query!(TriggerSQL.drop_trigger(@table))
    @repo.query!(TriggerSQL.drop_function_for_table(@table))

    sql =
      TriggerSQL.install_function_for_table(@table,
        exclude: ["password_hash"],
        mask: ["email"],
        mask_placeholder: "[REDACTED]",
        store_changed_from: true
      )

    @repo.query!(sql)
    @repo.query!(TriggerSQL.create_trigger(@table, :per_table))

    on_exit(fn ->
      @repo.query!(TriggerSQL.drop_trigger(@table))
      @repo.query!(TriggerSQL.drop_function_for_table(@table))

      if is_nil(original) do
        Application.delete_env(:threadline, :trigger_capture)
      else
        Application.put_env(:threadline, :trigger_capture, original)
      end
    end)

    :ok
  end

  test "reads deployed trigger SQL from pg_proc and matches Threadline-generated redaction" do
    report = RedactionPresenter.build(repo: @repo, schema: "public")
    row = Enum.find(report.tables, &(&1.table == @table))

    assert %{table: @table, status: :config_matches_deployed} = row
    assert row.configured.exclude == ["password_hash"]
    assert row.configured.mask == ["email"]
    assert row.deployed.exclude == ["password_hash"]
    assert row.deployed.mask == ["email"]
    assert row.deployed.mask_placeholder == "[REDACTED]"
  end
end
