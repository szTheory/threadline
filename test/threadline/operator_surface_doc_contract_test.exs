defmodule Threadline.OperatorSurfaceDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "README declares the operator surface mount macro" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "threadline_operator_surface")
  end

  test "README documents fail-closed posture and links guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "fail-closed")
    assert String.contains?(readme, "guides/operator-surface.md")
  end

  test "operator surface guide declares route literals" do
    guide = File.read!("guides/operator-surface.md")
    
    assert String.contains?(guide, "/audit/transactions/:id")
    assert String.contains?(guide, "/audit/actors/:kind/:id")
    assert String.contains?(guide, "/audit/rows/:table/:pk")
  end

  test "operator surface guide details fail-closed security and auth options" do
    guide = File.read!("guides/operator-surface.md")
    
    assert String.contains?(guide, "fail-closed")
    assert String.contains?(guide, ":authorize_fn")
    assert String.contains?(guide, ":adopter_acknowledges_unauthenticated: true")
  end
end
