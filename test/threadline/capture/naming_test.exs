defmodule Threadline.Capture.NamingTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.Capture.Naming
  alias Threadline.StorageSchema

  # Frozen format. Each hash was recomputed independently with
  # `printf '%s' '<schema>.<table>' | shasum -a 256 | cut -c1-12` before it was
  # written here. These names are literals in adopters' migrations: a change to
  # any row renames objects in the field.
  @golden [
    {"public.posts", "c6fcf4ae4927", "threadline_audit_posts",
     "threadline_capture_changes_posts"},
    {"billing.invoices", "9bba11019407", "threadline_audit_billing_invoices",
     "threadline_capture_changes_billing_invoices_9bba11019407"},
    {"public.billing_invoices", "ee2e817bbf91", "threadline_audit_billing_invoices",
     "threadline_capture_changes_billing_invoices"},
    {"public.customer_subscription_line_items_archive", "3b9be56c3c45",
     "threadline_audit_customer_subscription_line_items_archive",
     "threadline_capture_changes_customer_subscription_l_3b9be56c3c45"},
    {"analytics_reporting.customer_lifetime_value_snapshots", "411cf9724315",
     "threadline_audit_analytics_reporting_customer_lifetime_value_sn",
     "threadline_capture_changes_analytics_reporting_cus_411cf9724315"},
    {"public.ledger_0123456789ab", "6095cae6be06", "threadline_audit_ledger_0123456789ab",
     "threadline_capture_changes_ledger_0123456789ab_6095cae6be06"},
    {"public.Users", "3268e9c3e2ba", "threadline_audit_Users",
     "threadline_capture_changes_Users"},
    {"public.users", "14447575adab", "threadline_audit_users", "threadline_capture_changes_users"}
  ]

  describe "golden names" do
    for {input, h12, trigger, function} <- @golden do
      test "#{input}" do
        input = unquote(input)
        pair = Naming.pair(input)

        assert Naming.hash12(Naming.qualified(pair)) == unquote(h12)
        assert Naming.trigger_name(input) == unquote(trigger)
        assert Naming.function_name(input) == unquote(function)
        assert byte_size(Naming.trigger_name(input)) <= 63
        assert byte_size(Naming.function_name(input)) <= 63
        assert Naming.suffix(input) == StorageSchema.host_table_suffix(input)
      end
    end

    test "the cut trigger name of the longest golden row is exactly 63 bytes" do
      name = Naming.trigger_name("analytics_reporting.customer_lifetime_value_snapshots")
      assert byte_size(name) == 63
    end
  end

  describe "input forms" do
    test "a bare table, public.table and a parsed pair give identical names" do
      forms = ["posts", "public.posts", %{schema: "public", table: "posts"}]

      for fun <- [:suffix, :qualified, :trigger_name, :function_name, :legacy_function_name] do
        results = Enum.map(forms, &apply(Naming, fun, [&1]))
        assert Enum.uniq(results) |> length() == 1, "#{fun} differs: #{inspect(results)}"
      end
    end

    test "hash12 hashes the exact bytes with no case folding" do
      assert Naming.hash12("billing.invoices") == "9bba11019407"
      refute Naming.hash12("public.Users") == Naming.hash12("public.users")
    end
  end

  describe "migration_name/2" do
    test "fitting names and modules are unchanged from the per-part form" do
      assert Naming.migration_name(["posts"], 1) ==
               {"threadline_triggers_posts", "ThreadlineTriggersPosts"}

      assert Naming.migration_name(["a", "b"], 2) ==
               {"threadline_triggers_a_b_2", "ThreadlineTriggersAB2"}

      assert Naming.migration_name(["AuditLog"], 1) ==
               {"threadline_triggers_AuditLog", "ThreadlineTriggersAuditLog"}
    end

    test "an overflowing list is hashed over its sorted qualified names" do
      tables = ["customer_subscription_line_items_archive", "billing.invoices"]

      assert Naming.migration_name(tables, 1) ==
               {"threadline_triggers_customer_subscription_line_ite_229374fb2418",
                "ThreadlineTriggersCustomerSubscriptionLineIte229374fb2418"}

      assert Naming.hash12("billing.invoices,public.customer_subscription_line_items_archive") ==
               "229374fb2418"
    end

    test "an ordinal shortens the readable part and stays within 63 bytes" do
      tables = ["customer_subscription_line_items_archive", "billing.invoices"]
      {name, module} = Naming.migration_name(tables, 2)

      assert name == "threadline_triggers_customer_subscription_line_i_229374fb2418_2"
      assert byte_size(name) <= 63
      assert module == "ThreadlineTriggersCustomerSubscriptionLineI229374fb24182"
    end

    test "fifty tables fit in 63 bytes and the hash ignores order" do
      tables = for n <- 1..50, do: "table_number_#{n}"
      {name, _module} = Naming.migration_name(tables, 1)
      {reversed, _module} = Naming.migration_name(Enum.reverse(tables), 1)

      assert byte_size(name) <= 63
      assert name =~ ~r/_[0-9a-f]{12}\z/
      assert String.slice(name, -12, 12) == String.slice(reversed, -12, 12)
    end

    test "duplicate tables do not change the hash" do
      tables = for n <- 1..10, do: "table_number_#{n}"
      {name, _module} = Naming.migration_name(tables, 1)
      {doubled, _module} = Naming.migration_name(tables ++ ["table_number_3"], 1)

      assert String.slice(name, -12, 12) == String.slice(doubled, -12, 12)
    end

    test "an overflowing underscore-only list trims the readable part to empty" do
      underscores = String.duplicate("_", 44)
      assert byte_size("threadline_triggers_" <> underscores) == 64

      assert Naming.migration_name([underscores], 1) ==
               {"threadline_triggers__4b1eb587a18a", "ThreadlineTriggers4b1eb587a18a"}

      assert Naming.hash12("public." <> underscores) == "4b1eb587a18a"
      {name, _module} = Naming.migration_name([underscores], 1)
      assert name =~ ~r/^[A-Za-z_][A-Za-z0-9_]*$/
    end

    test "a fitting underscore-only list is returned unhashed" do
      underscores = String.duplicate("_", 43)

      assert Naming.migration_name([underscores], 1) ==
               {"threadline_triggers_" <> underscores, "ThreadlineTriggers"}

      assert byte_size("threadline_triggers_" <> underscores) == 63

      assert Naming.migration_name(["___", "____"], 1) ==
               {"threadline_triggers_" <> "___" <> "_" <> "____", "ThreadlineTriggers"}
    end

    test "Users and users get distinct names and the same module" do
      {upper, upper_module} = Naming.migration_name(["Users"], 1)
      {lower, lower_module} = Naming.migration_name(["users"], 1)

      refute upper == lower
      assert upper_module == lower_module
    end
  end

  describe "boundaries" do
    test "a 46-byte public table gives an uncut 63-byte trigger name" do
      table = String.duplicate("t", 46)
      name = Naming.trigger_name(table)

      assert byte_size(name) == 63
      assert name == "threadline_audit_" <> table
    end

    test "a 47-byte public table gives a trigger name cut to 63 bytes" do
      table = String.duplicate("t", 47)
      name = Naming.trigger_name(table)

      assert byte_size(name) == 63
      assert name == binary_part("threadline_audit_" <> table, 0, 63)
    end

    test "a 36-byte public table keeps its 63-byte legacy function name" do
      table = String.duplicate("f", 36)
      name = Naming.function_name(table)

      assert name == "threadline_capture_changes_" <> table
      assert byte_size(name) == 63
    end

    test "a 37-byte public table gets a hashed function name" do
      table = String.duplicate("f", 37)
      name = Naming.function_name(table)

      assert name ==
               "threadline_capture_changes_" <>
                 String.duplicate("f", 23) <>
                 "_" <>
                 Naming.hash12("public." <> table)

      assert byte_size(name) <= 63
    end

    test "only a lowercase hex tail forces hashing" do
      assert Naming.function_name("public.ledger_0123456789AB") ==
               "threadline_capture_changes_ledger_0123456789AB"

      assert Naming.function_name("public.ledger_0123456789ab") ==
               "threadline_capture_changes_ledger_0123456789ab_6095cae6be06"
    end

    test "legacy_function_name is the 0.10.x name cut to 63 bytes" do
      assert Naming.legacy_function_name("analytics_reporting.customer_lifetime_value_snapshots") ==
               binary_part(
                 "threadline_capture_changes_analytics_reporting_customer_lifetime_value_snapshots",
                 0,
                 63
               )
    end
  end

  describe "adjacency and case" do
    test "public.a_b and a.b share a trigger name but not a function name" do
      assert Naming.trigger_name("public.a_b") == "threadline_audit_a_b"
      assert Naming.trigger_name("a.b") == "threadline_audit_a_b"
      assert Naming.function_name("public.a_b") == "threadline_capture_changes_a_b"
      assert Naming.function_name("a.b") == "threadline_capture_changes_a_b_2e7336dc8eba"
    end

    test "Users and users keep distinct trigger and function names" do
      refute Naming.trigger_name("public.Users") == Naming.trigger_name("public.users")
      refute Naming.function_name("public.Users") == Naming.function_name("public.users")
      assert Naming.hash12("public.Users") == "3268e9c3e2ba"
      assert Naming.hash12("public.users") == "14447575adab"
    end
  end

  describe "errors" do
    test "an oversized host table raises a host table error with its byte count" do
      error =
        assert_raise ArgumentError, fn ->
          Naming.trigger_name("public." <> String.duplicate("t", 70))
        end

      assert error.message =~ "host table"
      assert error.message =~ "70 bytes"
      refute error.message =~ "storage schema"
    end

    test "an invalid host table raises a host table error" do
      error = assert_raise ArgumentError, fn -> Naming.function_name("bad-name") end

      assert error.message =~ "host table"
      refute error.message =~ "storage schema"
    end

    test "a map is validated like a parsed string" do
      schema_error =
        assert_raise ArgumentError, fn ->
          Naming.function_name(%{schema: "x y", table: "z"})
        end

      assert schema_error.message =~ "host schema"
      refute schema_error.message =~ "storage schema"

      table_error =
        assert_raise ArgumentError, fn ->
          Naming.function_name(%{schema: "public", table: String.duplicate("t", 70)})
        end

      assert table_error.message =~ "host table"
      assert table_error.message =~ "70 bytes"

      assert Naming.pair(%{schema: "billing", table: "invoices"}) ==
               StorageSchema.parse_table_identifier("billing.invoices")
    end
  end
end
