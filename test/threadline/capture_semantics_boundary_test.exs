defmodule Threadline.CaptureSemanticsBoundaryTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.AuditAction

  describe "API-07: capture and semantics schemas declare no cross-layer associations" do
    test "AuditTransaction declares no :action association" do
      refute :action in AuditTransaction.__schema__(:associations)
    end

    test "AuditAction declares no :transactions association" do
      refute :transactions in AuditAction.__schema__(:associations)
    end

    test "AuditTransaction keeps an explicit :action_id field and a virtual :action field" do
      assert :action_id in AuditTransaction.__schema__(:fields)
      assert :action in AuditTransaction.__schema__(:virtual_fields)
      assert %AuditTransaction{}.action == nil
    end

    test "AuditTransaction.action_id is :binary_id" do
      assert AuditTransaction.__schema__(:type, :action_id) == :binary_id
    end
  end
end
