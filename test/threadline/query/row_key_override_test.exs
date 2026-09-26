defmodule Threadline.Query.RowKeyOverrideTest do
  @moduledoc """
  Proves the CONF-01 read half: `Threadline.history/3` reads a
  `primary_key:`-override table with the same declared columns the trigger
  recorded, mapped back to schema fields through `field_source`.
  """

  use Threadline.DataCase, async: false

  alias Threadline.Capture.TriggerSQL
  alias Threadline.Query.RowKey
  alias Threadline.Test.MigrationHarness, as: Harness

  @table "rk_posts_tags"

  setup do
    previous_capture = Application.fetch_env(:threadline, :trigger_capture)
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-row-key-override-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    Repo.query!(TriggerSQL.install_function([]))
    drop_fixtures!()

    on_exit(fn ->
      Mix.shell(previous_shell)

      case previous_capture do
        {:ok, value} -> Application.put_env(:threadline, :trigger_capture, value)
        :error -> Application.delete_env(:threadline, :trigger_capture)
      end

      Harness.cleanup!(Harness.migration_files(tmp))
      drop_fixtures!()
      File.rm_rf!(tmp)
    end)

    %{tmp: tmp}
  end

  defp drop_fixtures! do
    Repo.query!("DROP TABLE IF EXISTS #{@table} CASCADE")
  end

  defmodule RkPostTag do
    use Ecto.Schema

    @primary_key false
    schema "rk_posts_tags" do
      field(:post, :integer, source: :post_id)
      field(:tag, :integer, source: :tag_id)
      field(:note, :string)
    end
  end

  defmodule RkPostTagMissingSource do
    use Ecto.Schema

    @primary_key false
    schema "rk_posts_tags" do
      field(:post, :integer, source: :post_id)
      field(:note, :string)
    end
  end

  defp create_table! do
    Repo.query!("""
    CREATE TABLE #{@table} (
      post_id bigint NOT NULL,
      tag_id  bigint NOT NULL,
      note    text
    )
    """)

    Repo.query!("CREATE UNIQUE INDEX rk_posts_tags_uniq ON #{@table} (post_id, tag_id)")
  end

  describe ~s|a primary_key: override table, config key "rk_posts_tags"| do
    test "history/3 reads through the declared columns mapped to schema fields", %{tmp: tmp} do
      create_table!()

      Application.put_env(:threadline, :trigger_capture,
        tables: %{@table => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", @table])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO #{@table} (post_id, tag_id, note) VALUES (1, 2, 'a')")
      Repo.query!("UPDATE #{@table} SET note = 'b' WHERE post_id = 1 AND tag_id = 2")

      rows = Threadline.history(RkPostTag, [post: 1, tag: 2], repo: Repo)
      assert length(rows) == 2
      assert Enum.all?(rows, &(&1.table_pk == %{"post_id" => "1", "tag_id" => "2"}))
    end
  end

  describe ~s|the same override, config key "public.rk_posts_tags"| do
    test "resolves the same way", %{tmp: tmp} do
      create_table!()

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"public.#{@table}" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", @table])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO #{@table} (post_id, tag_id, note) VALUES (3, 4, 'a')")

      rows = Threadline.history(RkPostTag, [post: 3, tag: 4], repo: Repo)
      assert length(rows) == 1
    end
  end

  describe "a declared column with no mapped schema field" do
    test "raises naming the column and the schema" do
      Application.put_env(:threadline, :trigger_capture,
        tables: %{@table => [primary_key: ["post_id", "tag_id"]]}
      )

      error = assert_raise(ArgumentError, fn -> RowKey.resolve!(RkPostTagMissingSource) end)

      message = Exception.message(error)
      assert message =~ "tag_id"
      assert message =~ inspect(RkPostTagMissingSource)
    end
  end
end
