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

  test "accepts one-segment PostgreSQL storage identifiers across helpers" do
    for schema <- ["audit", "threadline", "AuditLog", "_audit1"] do
      assert StorageSchema.get(storage_schema: schema) == schema
      assert StorageSchema.quote_ident(schema) == ~s("#{schema}")
      assert StorageSchema.qualify(schema, "audit_changes") == ~s("#{schema}"."audit_changes")

      assert StorageSchema.table("audit_changes", storage_schema: schema) ==
               ~s("#{schema}"."audit_changes")

      assert StorageSchema.function("threadline_capture_changes", storage_schema: schema) ==
               ~s("#{schema}"."threadline_capture_changes")
    end
  end

  test "rejects unsafe storage schema identifiers before SQL generation" do
    for invalid <- [
          nil,
          true,
          false,
          "",
          "   ",
          "foo.bar",
          "bad-name",
          "threadline;drop schema public",
          String.duplicate("a", 64)
        ] do
      assert_raise ArgumentError, fn ->
        StorageSchema.get(storage_schema: invalid)
      end
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

  test "rejects malformed host table identifiers instead of falling back to public" do
    for invalid <- ["", "   ", ".tickets", "support.", "support..tickets", "a.b.c"] do
      assert_raise ArgumentError, fn ->
        StorageSchema.parse_table_identifier(invalid)
      end
    end
  end
end
