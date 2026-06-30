if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ThemeAuthPlugTest do
    @moduledoc false
    use ExUnit.Case, async: false

    import Plug.Conn, only: [assign: 3, get_resp_header: 2]
    import Plug.Test, only: [conn: 2, init_test_session: 2]

    alias Threadline.OperatorSurface.ThemeAuthPlug

    setup do
      pid = self()
      handler_id = "theme_auth_plug_test_#{System.unique_integer()}"

      :telemetry.attach(
        handler_id,
        [:threadline, :operator_surface, :authorize],
        fn name, measurements, metadata, _config ->
          send(pid, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)
      :ok
    end

    test "grants when the session is fetched and authorize_fn returns :ok" do
      opts = [authorize_fn: fn _ -> :ok end]

      conn_out =
        conn(:post, "/audit/theme")
        |> init_test_session(operator_id: "support")
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      refute conn_out.halted

      assert_received {:telemetry_event, [:threadline, :operator_surface, :authorize],
                       %{result: :granted}, %{path: "/audit/theme"}}
    end

    test "mirrors conn assigns into the shared LiveView authorize_fn contract" do
      opts = [
        authorize_fn: fn %{assigns: %{current_user: %{role: :support}}} ->
          {:ok, %{actor_ref: "user:support"}}
        end
      ]

      conn_out =
        conn(:post, "/audit/theme")
        |> init_test_session(operator_id: "support")
        |> assign(:current_user, %{role: :support})
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      refute conn_out.halted
      assert conn_out.assigns.threadline_scope == %{actor_ref: "user:support"}
      assert_received {:telemetry_event, _, %{result: :granted}, %{actor_ref: "user:support"}}
    end

    test "denies when authorize_fn returns false" do
      opts = [authorize_fn: fn _ -> false end]

      conn_out =
        conn(:post, "/audit/theme")
        |> init_test_session(operator_id: "support")
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      assert conn_out.halted
      assert conn_out.status == 403
      assert conn_out.resp_body == "forbidden"
      assert get_resp_header(conn_out, "content-type") == ["text/plain; charset=utf-8"]
      assert_received {:telemetry_event, _, %{result: :denied}, %{path: "/audit/theme"}}
    end

    test "fails closed without a fetched session before calling authorize_fn" do
      pid = self()
      ref = make_ref()

      opts = [
        authorize_fn: fn _ ->
          send(pid, {ref, :called})
          :ok
        end
      ]

      conn_out =
        conn(:post, "/audit/theme")
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      assert conn_out.halted
      assert conn_out.status == 403
      assert conn_out.resp_body == "forbidden"
      refute_received {^ref, :called}
      assert_received {:telemetry_event, _, %{result: :denied}, %{path: "/audit/theme"}}
    end

    test "fails closed when authorize_fn raises" do
      opts = [authorize_fn: fn _ -> raise "boom" end]

      conn_out =
        conn(:post, "/audit/theme")
        |> init_test_session(operator_id: "support")
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      assert conn_out.halted
      assert conn_out.status == 403
      assert_received {:telemetry_event, _, %{result: :error}, %{path: "/audit/theme"}}
    end
  end
end
