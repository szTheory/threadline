if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.RowHistoryComponentTest do
    use ExUnit.Case, async: true
    import Phoenix.LiveViewTest

    # We test it using render_component/2

    setup_all do
      :ok
    end

    setup do
      {:ok, %{}}
    end

    test "renders error when schema is missing" do
      html =
        render_component(Threadline.OperatorSurface.Live.RowHistoryComponent, %{
          id: "test-history",
          table: "unknown_table",
          record_id: "1",
          base_path: "/audit/transactions/123",
          threadline_schemas: %{},
          repo: Threadline.Test.Repo,
          as_of: nil
        })

      assert html =~ "Row History:"
      assert html =~ "is not mapped to an Ecto schema"
    end
  end
end
