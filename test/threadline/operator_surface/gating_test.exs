defmodule Threadline.OperatorSurface.GatingTest do
  use ExUnit.Case, async: true

  describe "operator surface gating" do
    test "modules are conditionally loaded based on Phoenix.LiveView availability" do
      if Code.ensure_loaded?(Phoenix.LiveView) do
        assert Code.ensure_loaded?(Threadline.OperatorSurface.Router)
        assert Code.ensure_loaded?(Threadline.OperatorSurface.Auth)
      else
        refute Code.ensure_loaded?(Threadline.OperatorSurface.Router)
        refute Code.ensure_loaded?(Threadline.OperatorSurface.Auth)
      end
    end
  end
end
