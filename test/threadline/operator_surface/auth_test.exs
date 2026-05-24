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

    mismatch_handler_id = "auth_mismatch_test_#{System.unique_integer()}"

    :telemetry.attach(
      mismatch_handler_id,
      [:threadline, :operator_surface, :actor_ref_mismatch],
      fn name, measurements, metadata, _config ->
        send(pid, {:mismatch_telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)
      :telemetry.detach(mismatch_handler_id)
    end)

    :ok
  end

  describe "on_mount/4 session extraction" do
    test "extracts valid threadline_actor_ref from session and assigns it" do
      session = %{"threadline_actor_ref" => "{\"id\":\"user-1\",\"type\":\"user\"}"}
      opts = [authorize_fn: fn _socket -> :ok end]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, session, socket)

      assert %Threadline.Semantics.ActorRef{type: :user, id: "user-1"} =
               returned_socket.assigns.threadline_actor_ref
    end

    test "ignores invalid threadline_actor_ref in session" do
      session = %{"threadline_actor_ref" => "invalid json"}
      opts = [authorize_fn: fn _socket -> :ok end]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, session, socket)
      assert returned_socket.assigns[:threadline_actor_ref] == nil
    end

    test "falls back to scope if session actor is absent" do
      actor = %Threadline.Semantics.ActorRef{type: :job, id: "job-1"}
      scope = %{actor_ref: actor}
      opts = [authorize_fn: fn _socket -> {:ok, scope} end]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)

      assert returned_socket.assigns.threadline_actor_ref == actor
    end

    test "falls back to user_id in scope if session actor is absent" do
      scope = %{user_id: 123}
      opts = [authorize_fn: fn _socket -> {:ok, scope} end]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)

      # Since we only get a user_id, we might just store it. Wait, the goal says:
      # "ensure socket.assigns.threadline_actor_ref is correctly populated with the ActorRef struct regardless of the source."
      # But legacy user_id might not be an ActorRef. We can create an ActorRef for user_id!
      assert %Threadline.Semantics.ActorRef{type: :user, id: "123"} =
               returned_socket.assigns.threadline_actor_ref
    end

    test "keeps the session actor and emits telemetry when scope fallback disagrees" do
      session = %{"threadline_actor_ref" => "{\"id\":\"user-1\",\"type\":\"user\"}"}
      scope = %{user_id: 456}
      opts = [authorize_fn: fn _socket -> {:ok, scope} end]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, session, socket)

      assert %Threadline.Semantics.ActorRef{type: :user, id: "user-1"} =
               returned_socket.assigns.threadline_actor_ref

      assert_receive {:mismatch_telemetry_event,
                      [:threadline, :operator_surface, :actor_ref_mismatch],
                      %{count: 1},
                      metadata}

      assert metadata.session_actor_ref == %{"type" => "user", "id" => "user-1"}
      assert metadata.scope_actor_ref == %{"type" => "user", "id" => "456"}
    end
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

  describe "assign_coverage_enabled" do
    test "defaults to false when no coverage_authorize_fn is provided" do
      opts = [authorize_fn: fn _ -> :ok end]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert returned_socket.assigns.threadline_coverage_enabled == false
    end

    test "assigns true when coverage_authorize_fn returns :ok" do
      opts = [
        authorize_fn: fn _ -> :ok end,
        coverage_authorize_fn: fn _ -> :ok end
      ]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert returned_socket.assigns.threadline_coverage_enabled == true
    end

    test "assigns true when coverage_authorize_fn returns true" do
      opts = [
        authorize_fn: fn _ -> :ok end,
        coverage_authorize_fn: fn _ -> true end
      ]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert returned_socket.assigns.threadline_coverage_enabled == true
    end

    test "assigns false when coverage_authorize_fn returns false" do
      opts = [
        authorize_fn: fn _ -> :ok end,
        coverage_authorize_fn: fn _ -> false end
      ]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert returned_socket.assigns.threadline_coverage_enabled == false
    end

    test "assigns false when coverage_authorize_fn raises" do
      opts = [
        authorize_fn: fn _ -> :ok end,
        coverage_authorize_fn: fn _ -> raise "Boom!" end
      ]
      socket = mock_socket()

      assert {:cont, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
      assert returned_socket.assigns.threadline_coverage_enabled == false
    end
  end
end
