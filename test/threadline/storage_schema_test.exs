defmodule Threadline.StorageSchemaTest do
  use ExUnit.Case, async: true

  alias Threadline.StorageSchema

  test "defaults to dedicated threadline schema" do
    assert StorageSchema.get() == "threadline"
    assert StorageSchema.table("audit_changes") == ~s("threadline"."audit_changes")
  end

  test "accepts explicit public schema opt-out" do
    assert StorageSchema.get(storage_schema: "public") == "public"

    assert StorageSchema.table("audit_changes", storage_schema: "public") ==
             ~s("public"."audit_changes")
  end

  test "rejects unsafe schema names" do
    assert_raise ArgumentError, fn ->
      StorageSchema.get(storage_schema: "threadline;drop schema public")
    end
  end

  test "parses qualified host table identifiers" do
    assert StorageSchema.parse_table_identifier("support.tickets") == %{
             schema: "support",
             table: "tickets"
           }

    assert StorageSchema.qualified_host_table("support.tickets") == ~s("support"."tickets")
    assert StorageSchema.host_table_suffix("support.tickets") == "support_tickets"
  end
end
