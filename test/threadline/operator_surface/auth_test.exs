defmodule Threadline.OperatorSurface.AuthTest do
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.Auth

  # Simple mock socket for tests
  def mock_socket do
    %Phoenix.LiveView.Socket{
      endpoint: MyApp.Endpoint,
      router: MyApp.Router,
      assigns: %{__changed__: %{}}
    }
  end

  defp socket_with_user(user) do
    Phoenix.Component.assign(mock_socket(), :current_user, user)
  end

  setup do
    # Clear telemetry messages
    pid = self()
    handler_id = "auth_test_#{System.unique_integer()}"

    :telemetry.attach(
      handler_id,
      [:threadline, :operator_surface, :authorize],
      fn name, measurements, metadata, _config ->
        send(pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)
    end)

    :ok
  end

  describe "on_mount/4" do
    test "Case 1: returns :ok -> connection continues, telemetry :granted emitted" do
      opts = [authorize_fn: fn _socket -> :ok end]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert returned_socket.assigns.threadline_repo == nil
      assert returned_socket.assigns.threadline_schemas == %{}

      assert_receive {:telemetry_event, [:threadline, :operator_surface, :authorize],
                      %{result: :granted}, _metadata}
    end

    test "Case 2: returns {:ok, scope} -> connection continues, assigns scope, telemetry :granted emitted" do
      scope = %{user_id: 123, role: "admin"}
      opts = [authorize_fn: fn _socket -> {:ok, scope} end]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert returned_socket.assigns.threadline_scope == scope

      assert_receive {:telemetry_event, [:threadline, :operator_surface, :authorize],
                      %{result: :granted}, metadata}

      assert metadata.scope_keys == [:role, :user_id]
    end

    test "shared %{assigns: assigns} callback can return an opaque support scope" do
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

      socket = socket_with_user(%{role: :support, organization_id: "org_123"})

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)

      assert returned_socket.assigns.threadline_scope == %{
               access: :support_read_only,
               organization_id: "org_123"
             }

      assert_receive {:telemetry_event, [:threadline, :operator_surface, :authorize],
                      %{result: :granted}, metadata}

      assert metadata.scope_keys == [:access, :organization_id]
    end

    test "Case 3: returns true -> connection continues, telemetry :granted emitted" do
      opts = [authorize_fn: fn _socket -> true end]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert returned_socket.assigns.threadline_repo == nil
      assert returned_socket.assigns.threadline_schemas == %{}

      assert_receive {:telemetry_event, [:threadline, :operator_surface, :authorize],
                      %{result: :granted}, _metadata}
    end

    test "Case 4: returns false -> connection halts with redirect, telemetry :denied emitted" do
      opts = [authorize_fn: fn _socket -> false end]
      socket = mock_socket()

      assert {:halt, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      # Phoenix.LiveView.redirect adds a redirect instruction.
      assert {:redirect, %{to: "/"}} = returned_socket.redirected

      assert_receive {:telemetry_event, [:threadline, :operator_surface, :authorize],
                      %{result: :denied}, _metadata}
    end

    test "Case 4: returns nil -> connection halts with redirect, telemetry :denied emitted" do
      opts = [authorize_fn: fn _socket -> nil end]
      socket = mock_socket()

      assert {:halt, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert {:redirect, %{to: "/"}} = returned_socket.redirected

      assert_receive {:telemetry_event, [:threadline, :operator_surface, :authorize],
                      %{result: :denied}, _metadata}
    end

    test "Case 5: crashes -> handled gracefully, halts with redirect, telemetry :error emitted" do
      opts = [authorize_fn: fn _socket -> raise "Boom!" end]
      socket = mock_socket()

      assert {:halt, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert {:redirect, %{to: "/"}} = returned_socket.redirected

      assert_receive {:telemetry_event, [:threadline, :operator_surface, :authorize],
                      %{result: :error}, _metadata}
    end

    test "defaults to true/ok if authorize_fn is missing" do
      opts = []
      socket = mock_socket()

      assert {:cont, _returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)

      assert_receive {:telemetry_event, [:threadline, :operator_surface, :authorize],
                      %{result: :granted}, _metadata}
    end
  end
end
