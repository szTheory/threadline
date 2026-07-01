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

    assert sql =~ ~S|CREATE TRIGGER "threadline_audit_support_tickets"|
    assert sql =~ ~S|ON "support"."tickets"|
    assert sql =~ ~S|EXECUTE FUNCTION "threadline"."threadline_capture_changes"()|
  end

  test "qualified host tables call the configured Threadline storage function" do
    sql = TriggerSQL.create_trigger("support.tickets", :default, storage_schema: "audit")

    assert sql =~ ~S|ON "support"."tickets"|
    assert sql =~ ~S|EXECUTE FUNCTION "audit"."threadline_capture_changes"()|
    refute sql =~ ~S|"support"."threadline_capture_changes"|
  end

  test "per-table functions include host schema in the function suffix" do
    sql = TriggerSQL.install_function_for_table("support.tickets", store_changed_from: true)

    assert sql =~
             ~S|CREATE OR REPLACE FUNCTION "threadline"."threadline_capture_changes_support_tickets"()|

    assert TriggerSQL.drop_function_for_table("support.tickets") =~
             ~S|DROP FUNCTION IF EXISTS "threadline"."threadline_capture_changes_support_tickets"()|
  end
end
