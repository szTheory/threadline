defmodule Threadline.NotFoundErrorTest do
  @moduledoc """
  Covers `Threadline.NotFoundError` (D-17) — message shape and the
  `Plug.Exception` implementation.
  """

  use ExUnit.Case, async: true

  test "message carries only the resource and the inspected id" do
    error = %Threadline.NotFoundError{resource: :audit_transaction, id: "abc"}

    assert Exception.message(error) == "audit transaction not found: \"abc\""
  end

  test "Plug.Exception.status/1 is 404 and actions/1 is []" do
    error = %Threadline.NotFoundError{resource: :audit_transaction, id: "abc"}

    assert Plug.Exception.status(error) == 404
    assert Plug.Exception.actions(error) == []
  end

  test "is a real exception struct" do
    assert_raise Threadline.NotFoundError, "audit transaction not found: \"x\"", fn ->
      raise Threadline.NotFoundError, resource: :audit_transaction, id: "x"
    end
  end
end
