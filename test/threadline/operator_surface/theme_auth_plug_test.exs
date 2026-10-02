if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ThemeAuthPlugTest do
    @moduledoc false
    use ExUnit.Case, async: true

    import Plug.Conn, only: [assign: 3, get_resp_header: 2]
    import Plug.Test, only: [conn: 2, init_test_session: 2]
    import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

    alias Threadline.OperatorSurface.ThemeAuthPlug

    setup do
      telemetry_ref = attach_telemetry!([[:threadline, :operator_surface, :authorize]])
      {:ok, telemetry_ref: telemetry_ref}
    end

    test "grants when the session is fetched and authorize_fn returns :ok", %{
      telemetry_ref: telemetry_ref
    } do
      opts = [authorize_fn: fn _ -> :ok end, theme_path: "/audit/theme"]

      conn_out =
        conn(:post, "/audit/theme")
        |> init_test_session(operator_id: "support")
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      refute conn_out.halted

      assert_received {[:threadline, :operator_surface, :authorize], ^telemetry_ref,
                       %{result: :granted}, %{path: "/audit/theme"}}
    end

    test "mirrors conn assigns into the shared LiveView authorize_fn contract", %{
      telemetry_ref: telemetry_ref
    } do
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

      assert_received {[:threadline, :operator_surface, :authorize], ^telemetry_ref,
                       %{result: :granted}, %{scope_keys: [:actor_ref]} = metadata}

      refute Map.has_key?(metadata, :actor_ref)
    end

    test "denies when authorize_fn returns false", %{telemetry_ref: telemetry_ref} do
      opts = [authorize_fn: fn _ -> false end, theme_path: "/audit/theme"]

      conn_out =
        conn(:post, "/audit/theme")
        |> init_test_session(operator_id: "support")
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      assert conn_out.halted
      assert conn_out.status == 403
      assert conn_out.resp_body == "forbidden"
      assert get_resp_header(conn_out, "content-type") == ["text/plain; charset=utf-8"]

      assert_received {[:threadline, :operator_surface, :authorize], ^telemetry_ref,
                       %{result: :denied}, %{path: "/audit/theme"}}
    end

    test "fails closed without a fetched session before calling authorize_fn", %{
      telemetry_ref: telemetry_ref
    } do
      pid = self()
      ref = make_ref()

      opts = [
        authorize_fn: fn _ ->
          send(pid, {ref, :called})
          :ok
        end,
        theme_path: "/audit/theme"
      ]

      conn_out =
        conn(:post, "/audit/theme")
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      assert conn_out.halted
      assert conn_out.status == 403
      assert conn_out.resp_body == "forbidden"
      refute_received {^ref, :called}

      assert_received {[:threadline, :operator_surface, :authorize], ^telemetry_ref,
                       %{result: :denied}, %{path: "/audit/theme"}}
    end

    test "fails closed when authorize_fn raises", %{telemetry_ref: telemetry_ref} do
      opts = [authorize_fn: fn _ -> raise "boom" end, theme_path: "/audit/theme"]

      conn_out =
        conn(:post, "/audit/theme")
        |> init_test_session(operator_id: "support")
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      assert conn_out.halted
      assert conn_out.status == 403

      assert_received {[:threadline, :operator_surface, :authorize], ^telemetry_ref,
                       %{result: :error}, %{path: "/audit/theme"}}
    end

    test "path metadata is the plug's fixed :theme_path option, never the live request path",
         %{telemetry_ref: telemetry_ref} do
      # A host that nests this mount under a dynamic router segment (e.g.
      # `/accounts/:account_id/audit`) would have the actual account id
      # substituted into `conn.request_path` at request time. `:theme_path`
      # is set by the router macro from its own compile-time path argument —
      # the un-substituted route template — so the emitted `path` metadata
      # must carry the template, never the live "42" segment below.
      opts = [authorize_fn: fn _ -> :ok end, theme_path: "/accounts/:account_id/audit/theme"]

      conn_out =
        conn(:post, "/accounts/42/audit/theme")
        |> init_test_session(operator_id: "support")
        |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))

      refute conn_out.halted

      assert_received {[:threadline, :operator_surface, :authorize], ^telemetry_ref,
                       %{result: :granted}, %{path: path}}

      assert path == "/accounts/:account_id/audit/theme"
      refute path =~ "42"
    end
  end
end
