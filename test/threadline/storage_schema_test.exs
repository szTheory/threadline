defmodule Threadline.StorageSchemaTest do
  # async: false — the default-resolution describe block below temporarily
  # removes `:threadline, :storage_schema` from the application environment,
  # which is process-global. Sync modules run after every async module has
  # finished, so no concurrently-running test can observe the gap.
  use ExUnit.Case, async: false

  alias Threadline.StorageSchema

  describe "default storage schema (D-01)" do
    setup do
      previous = Application.fetch_env(:threadline, :storage_schema)
      Application.delete_env(:threadline, :storage_schema)

      on_exit(fn ->
        case previous do
          {:ok, value} -> Application.put_env(:threadline, :storage_schema, value)
          :error -> Application.delete_env(:threadline, :storage_schema)
        end
      end)

      :ok
    end

    test "resolves to the host's public schema when no storage_schema is configured" do
      assert StorageSchema.get([]) == "public",
             "a host that sets no :storage_schema must resolve to public — anything else " <>
               "prefixes every read path onto tables a pre-0.10 install does not have while " <>
               "its already-deployed unqualified triggers keep writing to public"

      assert StorageSchema.get() == "public"
      assert StorageSchema.table("audit_changes") == ~s("public"."audit_changes")
      assert StorageSchema.repo_opts() == [prefix: "public"]
    end

    test "a dedicated schema stays available as an explicit opt-in" do
      assert StorageSchema.get(storage_schema: "threadline") == "threadline"

      assert StorageSchema.table("audit_changes", storage_schema: "threadline") ==
               ~s("threadline"."audit_changes")

      Application.put_env(:threadline, :storage_schema, "threadline")
      assert StorageSchema.get([]) == "threadline"
    end
  end

  test "honours an explicitly configured storage schema" do
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
