if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportAuthPlugTest do
    @moduledoc false
    use ExUnit.Case, async: true

    import Plug.Test, only: [conn: 2]
    import Plug.Conn, only: [get_resp_header: 2]

    alias Threadline.OperatorSurface.ExportAuthPlug

    setup do
      pid = self()
      handler_id = "export_auth_plug_test_#{System.unique_integer()}"

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

    describe "call/2 with `:authorize_fn` returning a granted result" do
      test "case 1: :ok grants and does not halt" do
        opts = [authorize_fn: fn _ -> :ok end]
        conn_in = conn(:get, "/audit/exports/changes.csv")
        conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        refute conn_out.halted

        assert_received {:telemetry_event, [:threadline, :operator_surface, :authorize],
                         %{result: :granted}, _meta}
      end

      test "case 2: true grants and does not halt" do
        opts = [authorize_fn: fn _ -> true end]
        conn_in = conn(:get, "/audit/exports/changes.csv")
        conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        refute conn_out.halted
        assert_received {:telemetry_event, _, %{result: :granted}, _meta}
      end

      test "case 3: {:ok, scope} when scope is a map grants and assigns :threadline_scope" do
        scope = %{user_id: 42, role: :admin}
        opts = [authorize_fn: fn _ -> {:ok, scope} end]
        conn_in = conn(:get, "/audit/exports/changes.csv")
        conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        refute conn_out.halted
        assert conn_out.assigns[:threadline_scope] == scope

        assert_received {:telemetry_event, _, %{result: :granted}, %{scope_keys: scope_keys}}
        assert scope_keys == [:role, :user_id]
      end

      test "shared %{assigns: assigns} callback grants support scope through the mirror" do
        opts = [
          authorize_fn: fn %{assigns: assigns} ->
            case assigns[:current_user] do
              %{role: :support, organization_id: org_id} ->
                {:ok, %{access: :support_read_only, organization_id: org_id}}

              _ ->
                {:error, :unauthorized}
            end
          end
        ]

        conn_in =
          conn(:get, "/audit/exports/changes.csv")
          |> Plug.Conn.assign(:current_user, %{role: :support, organization_id: "org_123"})

        conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        refute conn_out.halted

        assert conn_out.assigns[:threadline_scope] == %{
                 access: :support_read_only,
                 organization_id: "org_123"
               }

        assert_receive {:telemetry_event, _, %{result: :granted},
                        %{scope_keys: [:access, :organization_id]}}
      end
    end

    describe "call/2 with `:authorize_fn` returning a denial / raising" do
      test "case 4: false halts with 403 plain-text body and :denied telemetry" do
        opts = [authorize_fn: fn _ -> false end]
        conn_in = conn(:get, "/audit/exports/changes.csv")
        conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        assert conn_out.halted
        assert conn_out.status == 403
        assert conn_out.resp_body == "forbidden"
        assert get_resp_header(conn_out, "content-type") == ["text/plain; charset=utf-8"]
        assert_received {:telemetry_event, _, %{result: :denied}, _meta}
      end

      test "case 5: raise inside authorize_fn halts with 403 and :error telemetry" do
        opts = [authorize_fn: fn _ -> raise "boom" end]
        conn_in = conn(:get, "/audit/exports/changes.csv")
        conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        assert conn_out.halted
        assert conn_out.status == 403
        assert_received {:telemetry_event, _, %{result: :error}, _meta}
      end
    end

    describe "authorizer dispatch (D-20)" do
      test "case 6a: when :export_authorize_fn is provided, it is called with `conn` directly" do
        ref = make_ref()
        pid = self()

        export_fn = fn %Plug.Conn{} = conn ->
          send(pid, {ref, :export_called_with_conn, conn.request_path})
          :ok
        end

        opts = [
          export_authorize_fn: export_fn,
          authorize_fn: fn _ -> raise "should NOT be called" end
        ]

        conn_in = conn(:get, "/audit/exports/changes.csv")

        _conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        assert_received {^ref, :export_called_with_conn, "/audit/exports/changes.csv"}
      end

      test "case 6a2: export_authorize_fn can opt support into export access" do
        opts = [
          authorize_fn: fn _ -> {:error, :unauthorized} end,
          export_authorize_fn: fn %Plug.Conn{assigns: %{current_user: user}} ->
            if user.role == :support and user.export_access do
              {:ok, %{access: :support_read_only, organization_id: user.organization_id}}
            else
              {:error, :unauthorized}
            end
          end
        ]

        conn_in =
          conn(:get, "/audit/exports/changes.csv")
          |> Plug.Conn.assign(:current_user, %{
            role: :support,
            export_access: true,
            organization_id: "org_123"
          })

        conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        refute conn_out.halted

        assert conn_out.assigns[:threadline_scope] == %{
                 access: :support_read_only,
                 organization_id: "org_123"
               }
      end

      test "case 6b: when :export_authorize_fn is absent, :authorize_fn is called with the synthetic %{assigns: conn.assigns} mirror" do
        ref = make_ref()
        pid = self()

        # The mirror MUST have :assigns key; MUST NOT be a %Plug.Conn{} struct.
        authorize_fn = fn mirror ->
          send(pid, {ref, :authorize_called_with_mirror, mirror})
          :ok
        end

        opts = [authorize_fn: authorize_fn]

        conn_in =
          conn(:get, "/audit/exports/changes.csv")
          |> Plug.Conn.assign(:current_user, %{id: 7})

        _conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        assert_receive {^ref, :authorize_called_with_mirror, mirror}
        # The mirror is a plain map with an :assigns key — NOT a %Plug.Conn{}.
        refute is_struct(mirror, Plug.Conn)
        assert mirror.assigns[:current_user] == %{id: 7}
      end
    end

    describe "repo passthrough" do
      test "assigns `:threadline_repo` from opts so the controller can read it" do
        opts = [authorize_fn: fn _ -> :ok end, repo: MyApp.Repo]
        conn_in = conn(:get, "/audit/exports/changes.csv")
        conn_out = ExportAuthPlug.call(conn_in, ExportAuthPlug.init(opts))

        assert conn_out.assigns[:threadline_repo] == MyApp.Repo
      end
    end
  end
end
