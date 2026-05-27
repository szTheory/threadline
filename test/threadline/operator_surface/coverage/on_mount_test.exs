defmodule Threadline.OperatorSurface.Coverage.OnMountTest do
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.Coverage.OnMount

  def mock_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      endpoint: MyApp.Endpoint,
      router: MyApp.Router,
      assigns: Map.merge(%{__changed__: %{}}, assigns)
    }
  end

  describe "on_mount/4" do
    test "returns unmodified socket when threadline_coverage_enabled is false" do
      socket = mock_socket(%{threadline_coverage_enabled: false})

      assert {:cont, returned_socket} = OnMount.on_mount([], %{}, %{}, socket)

      assert returned_socket.assigns.threadline_coverage_enabled == false
      assert returned_socket.assigns.threadline_coverage == nil
      assert returned_socket.assigns.threadline_coverage_error == nil
    end

    test "returns unmodified socket when threadline_coverage_enabled is missing" do
      socket = mock_socket()

      assert {:cont, returned_socket} = OnMount.on_mount([], %{}, %{}, socket)

      assert returned_socket.assigns.threadline_coverage == nil
      assert returned_socket.assigns.threadline_coverage_error == nil
    end

    test "starts coverage process when threadline_coverage_enabled is true (disconnected socket)" do
      # For disconnected socket, it assigns poll_ms and initial coverage, but no timer
      socket = mock_socket(%{threadline_coverage_enabled: true})

      assert {:cont, returned_socket} = OnMount.on_mount([], %{}, %{}, socket)

      assert returned_socket.assigns.threadline_coverage_poll_ms >= 5000
      assert Map.has_key?(returned_socket.assigns, :threadline_coverage)
      refute Map.has_key?(returned_socket.assigns, :threadline_timer_ref)
    end
  end
end
