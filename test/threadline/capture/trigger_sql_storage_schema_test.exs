defmodule Threadline.Capture.TriggerSQLStorageSchemaTest do
  use ExUnit.Case, async: true

  alias Threadline.Capture.TriggerSQL

  test "global function writes to configured Threadline storage schema" do
    sql = TriggerSQL.install_function()

    assert sql =~ ~S|CREATE OR REPLACE FUNCTION "threadline"."threadline_capture_changes"()|
    assert sql =~ ~S|INSERT INTO "threadline"."audit_transactions"|
    assert sql =~ ~S|FROM "threadline"."audit_transactions"|
    assert sql =~ ~S|INSERT INTO "threadline"."audit_changes"|
  end

  test "public storage schema remains an explicit opt-out" do
    sql = TriggerSQL.install_function(storage_schema: "public")

    assert sql =~ ~S|CREATE OR REPLACE FUNCTION "public"."threadline_capture_changes"()|
    assert sql =~ ~S|INSERT INTO "public"."audit_transactions"|
  end

  test "qualified host tables create schema-qualified triggers" do
    sql = TriggerSQL.create_trigger("support.tickets")

    assert sql =~ ~S|CREATE OR REPLACE TRIGGER "threadline_audit_support_tickets"|
    assert sql =~ ~S|ON "support"."tickets"|
    assert sql =~ ~S|EXECUTE FUNCTION "threadline"."threadline_capture_changes"(%s)|
  end

  test "qualified host tables call the configured Threadline storage function" do
    sql = TriggerSQL.create_trigger("support.tickets", :default, storage_schema: "audit")

    assert sql =~ ~S|ON "support"."tickets"|
    assert sql =~ ~S|EXECUTE FUNCTION "audit"."threadline_capture_changes"(%s)|
    refute sql =~ ~S|"support"."threadline_capture_changes"|
  end

  test "a per-table function for a schema table is named from the schema and table" do
    sql = TriggerSQL.install_function_for_table("support.tickets", store_changed_from: true)

    assert sql =~
             ~S|CREATE OR REPLACE FUNCTION "threadline"."threadline_capture_changes_support_tickets_0a670b783726"()|

    assert TriggerSQL.drop_function_for_table("support.tickets") =~
             ~S|DROP FUNCTION IF EXISTS "threadline"."threadline_capture_changes_support_tickets_0a670b783726"()|
  end

  test "a per-table trigger on a schema table calls its own function" do
    sql = TriggerSQL.create_trigger("support.tickets", :per_table, storage_schema: "threadline")

    assert sql =~
             ~S|EXECUTE FUNCTION "threadline"."threadline_capture_changes_support_tickets_0a670b783726"(%s)|
  end

  test "the drop-if-unused block resolves a fully quoted function and never cascades" do
    sql =
      TriggerSQL.drop_function_if_unused("threadline_capture_changes_billing_invoices",
        storage_schema: "threadline"
      )

    assert sql =~
             ~S|to_regprocedure('"threadline"."threadline_capture_changes_billing_invoices"()')|

    assert sql =~ "-- threadline: drop this capture function only if no trigger still uses it"
    assert sql =~ "IF fn IS NULL THEN RETURN; END IF;"
    assert sql =~ "WHERE t.tgfoid = fn AND t.tgparentid = 0;"
    assert sql =~ "ORDER BY n.nspname, c.relname"
    assert sql =~ "EXECUTE format('DROP FUNCTION %s', fn)"
    assert sql =~ "RAISE WARNING 'threadline: kept % because triggers on % still use it"
    refute sql =~ ~r/cascade/i
    refute sql =~ ~r/RAISE EXCEPTION/i
  end

  test "the drop-if-unused block quotes a mixed-case storage schema" do
    sql =
      TriggerSQL.drop_function_if_unused("threadline_capture_changes_posts",
        storage_schema: "Audit"
      )

    assert sql =~ ~S|to_regprocedure('"Audit"."threadline_capture_changes_posts"()')|
  end

  test "the drop-if-unused block refuses a name PostgreSQL would cut" do
    name = "threadline_capture_changes_" <> String.duplicate("x", 37)
    assert byte_size(name) == 64

    assert_raise ArgumentError, ~r/derived identifier .*is 64 bytes/, fn ->
      TriggerSQL.drop_function_if_unused(name)
    end
  end

  test "the owner guard fails when another table's trigger uses a public table's function" do
    sql = TriggerSQL.function_owner_guard("billing_invoices", storage_schema: "threadline")

    assert sql =~
             ~S|to_regprocedure('"threadline"."threadline_capture_changes_billing_invoices"()')|

    assert sql =~ ~S|to_regclass('"public"."billing_invoices"')|
    assert sql =~ "t.tgfoid = fn AND t.tgparentid = 0 AND t.tgrelid <> owner"
    assert sql =~ "ORDER BY n.nspname, c.relname"
    assert sql =~ "RAISE EXCEPTION"
    assert sql =~ "may now apply another table''s redaction rules"
    assert sql =~ "USING HINT"
    assert sql =~ "mix threadline.gen.triggers --tables billing_invoices,"
    refute sql =~ ~r/cascade/i
  end

  test "the owner guard names a schema table the way --tables takes it" do
    sql = TriggerSQL.function_owner_guard("billing.invoices", storage_schema: "threadline")

    assert sql =~
             ~S|to_regprocedure('"threadline"."threadline_capture_changes_billing_invoices_9bba11019407"()')|

    assert sql =~ ~S|to_regclass('"billing"."invoices"')|
    assert sql =~ "mix threadline.gen.triggers --tables billing.invoices,"
    refute sql =~ ~r/cascade/i
  end

  test "the owner guard quotes a mixed-case storage schema" do
    sql = TriggerSQL.function_owner_guard("posts", storage_schema: "Audit")

    assert sql =~ ~S|to_regprocedure('"Audit"."threadline_capture_changes_posts"()')|
  end

  test "the per-table function drop never cascades" do
    sql = TriggerSQL.drop_function_for_table("support.tickets")

    assert sql ==
             ~S|DROP FUNCTION IF EXISTS "threadline"."threadline_capture_changes_support_tickets_0a670b783726"()|

    refute sql =~ ~r/cascade/i
  end
end
