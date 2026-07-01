defmodule Threadline.Policy.RedactionPresenterTest do
  use ExUnit.Case, async: true

  alias Threadline.Capture.{RedactionPolicy, TriggerCaptureConfig, TriggerSQL}
  alias Threadline.Policy.RedactionPresenter

  describe "TriggerCaptureConfig.load/1" do
    test "normalizes and validates configured tables" do
      config = [
        tables: %{
          users: %{
            exclude: [:password_hash],
            mask: ["email"],
            mask_placeholder: "[MASKED]"
          }
        }
      ]

      loaded = TriggerCaptureConfig.load(config)

      assert Map.keys(loaded) == ["users"]
      assert Keyword.get(loaded["users"], :exclude) == ["password_hash"]
      assert Keyword.get(loaded["users"], :mask) == ["email"]
      assert Keyword.get(loaded["users"], :mask_placeholder) == "[MASKED]"
    end

    test "raises through the canonical overlap validator" do
      assert_raise ArgumentError, ~r/exclude and mask overlap/, fn ->
        TriggerCaptureConfig.load(tables: %{users: [exclude: ["email"], mask: ["email"]]})
      end
    end

    test "raises through the canonical placeholder validator" do
      assert_raise ArgumentError, ~r/placeholder/, fn ->
        TriggerCaptureConfig.load(tables: %{users: [mask: ["email"], mask_placeholder: ""]})
      end
    end
  end

  describe "build_report/2" do
    test "treats config-only empty policy and legacy global trigger as a match" do
      report =
        RedactionPresenter.build_report(
          %{"accounts" => []},
          [
            %{
              table: "accounts",
              trigger_name: "threadline_audit_accounts",
              function_name: "threadline_capture_changes",
              function_language: "plpgsql",
              function_source: TriggerSQL.install_function()
            }
          ]
        )

      assert report.summary == %{
               drift_detected: 0,
               could_not_introspect: 0,
               config_matches_deployed: 1
             }

      assert [
               %{
                 table: "accounts",
                 status: :config_matches_deployed,
                 diff: %{placeholder_mismatch: false}
               }
             ] =
               report.tables
    end

    test "matches a configured exclude and mask policy against generated SQL" do
      report =
        RedactionPresenter.build_report(
          %{
            "users" => [
              exclude: ["password_hash"],
              mask: ["email"],
              mask_placeholder: RedactionPolicy.default_placeholder()
            ]
          },
          [
            %{
              table: "users",
              trigger_name: "threadline_audit_users",
              function_name: "threadline_capture_changes_users",
              function_language: "plpgsql",
              function_source:
                TriggerSQL.install_function_for_table("users",
                  exclude: ["password_hash"],
                  mask: ["email"],
                  store_changed_from: true
                )
            }
          ]
        )

      assert [%{status: :config_matches_deployed, diff: diff}] = report.tables
      assert diff.exclude_only_in_config == []
      assert diff.exclude_only_in_deployed == []
      assert diff.mask_only_in_config == []
      assert diff.mask_only_in_deployed == []
      refute diff.placeholder_mismatch
    end

    test "surfaces placeholder mismatch as drift" do
      report =
        RedactionPresenter.build_report(
          %{"users" => [mask: ["email"], mask_placeholder: "[MASK-A]"]},
          [
            %{
              table: "users",
              trigger_name: "threadline_audit_users",
              function_name: "threadline_capture_changes_users",
              function_language: "plpgsql",
              function_source:
                TriggerSQL.install_function_for_table("users",
                  mask: ["email"],
                  mask_placeholder: "[MASK-B]",
                  store_changed_from: true
                )
            }
          ]
        )

      assert [%{status: :drift_detected, diff: diff}] = report.tables
      assert diff.placeholder_mismatch
      assert diff.mask_only_in_config == []
      assert diff.mask_only_in_deployed == []
    end

    test "treats missing configured-table trigger as drift" do
      report = RedactionPresenter.build_report(%{"users" => [mask: ["email"]]}, [])

      assert [%{status: :drift_detected, warning: warning}] = report.tables
      assert warning == "No deployed Threadline trigger found for configured table."
    end

    test "treats deployed-only redaction as drift" do
      report =
        RedactionPresenter.build_report(
          %{},
          [
            %{
              table: "users",
              trigger_name: "threadline_audit_users",
              function_name: "threadline_capture_changes_users",
              function_language: "plpgsql",
              function_source:
                TriggerSQL.install_function_for_table("users",
                  exclude: ["password_hash"],
                  store_changed_from: true
                )
            }
          ]
        )

      assert [%{status: :drift_detected, diff: diff}] = report.tables
      assert diff.exclude_only_in_deployed == ["password_hash"]
      assert diff.exclude_only_in_config == []
    end

    test "fails closed for malformed function source" do
      report =
        RedactionPresenter.build_report(
          %{"users" => [mask: ["email"]]},
          [
            %{
              table: "users",
              trigger_name: "threadline_audit_users",
              function_name: "threadline_capture_changes_users",
              function_language: "plpgsql",
              function_source:
                "CREATE FUNCTION weird() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END; $$"
            }
          ]
        )

      assert [%{status: :could_not_introspect, hint: hint}] = report.tables
      assert hint =~ "Rerun `mix threadline.gen.triggers`"
    end

    test "fails closed for unsupported function language" do
      report =
        RedactionPresenter.build_report(
          %{"users" => []},
          [
            %{
              table: "users",
              trigger_name: "threadline_audit_users",
              function_name: "threadline_capture_changes_users",
              function_language: "sql",
              function_source: TriggerSQL.install_function()
            }
          ]
        )

      assert [%{status: :could_not_introspect, warning: warning}] = report.tables
      assert warning == "Unsupported trigger function language: sql."
    end

    test "preserves canonical section ordering and alphabetical order within sections" do
      report =
        RedactionPresenter.build_report(
          %{
            "delta" => [mask: ["email"]],
            "bravo" => [mask: ["email"]],
            "alpha" => [],
            "charlie" => []
          },
          [
            %{
              table: "alpha",
              trigger_name: "threadline_audit_alpha",
              function_name: "threadline_capture_changes",
              function_language: "plpgsql",
              function_source: TriggerSQL.install_function()
            },
            %{
              table: "bravo",
              trigger_name: "threadline_audit_bravo",
              function_name: "threadline_capture_changes_bravo",
              function_language: "plpgsql",
              function_source:
                TriggerSQL.install_function_for_table("bravo",
                  mask: ["email"],
                  mask_placeholder: "[DIFFERENT]",
                  store_changed_from: true
                )
            },
            %{
              table: "charlie",
              trigger_name: "threadline_audit_charlie",
              function_name: "threadline_capture_changes_charlie",
              function_language: "plpgsql",
              function_source: "not threadline sql"
            }
          ]
        )

      assert Keyword.keys(report.grouped) == [
               :drift_detected,
               :could_not_introspect,
               :config_matches_deployed
             ]

      assert Enum.map(report.grouped[:drift_detected], & &1.table) == ["bravo", "delta"]
      assert Enum.map(report.grouped[:could_not_introspect], & &1.table) == ["charlie"]
      assert Enum.map(report.grouped[:config_matches_deployed], & &1.table) == ["alpha"]
    end

    test "never surfaces sample values in configured or deployed policy fields" do
      report =
        RedactionPresenter.build_report(
          %{"users" => [exclude: ["password_hash"], mask: ["email"]]},
          [
            %{
              table: "users",
              trigger_name: "threadline_audit_users",
              function_name: "threadline_capture_changes_users",
              function_language: "plpgsql",
              function_source:
                TriggerSQL.install_function_for_table("users",
                  exclude: ["password_hash"],
                  mask: ["email"],
                  store_changed_from: true
                )
            }
          ]
        )

      [row] = report.tables

      inspect(row)
      |> then(fn rendered ->
        refute rendered =~ "alice@example.com"
        refute rendered =~ "secret"
      end)
    end
  end

  describe "build_report/3 selected host schema" do
    test "matches schema-qualified configured tables to deployed rows in selected host schema" do
      report =
        RedactionPresenter.build_report(
          %{
            "public.tickets" => [mask: ["email"]],
            "support.tickets" => [
              exclude: ["password_hash"],
              mask: ["email"],
              mask_placeholder: RedactionPolicy.default_placeholder()
            ]
          },
          [
            %{
              table: "tickets",
              trigger_name: "threadline_audit_support_tickets",
              function_name: "threadline_capture_changes_support_tickets",
              function_language: "plpgsql",
              function_source:
                TriggerSQL.install_function_for_table("support.tickets",
                  exclude: ["password_hash"],
                  mask: ["email"],
                  store_changed_from: true
                )
            }
          ],
          schema: "support"
        )

      assert [
               %{
                 table: "support.tickets",
                 table_schema: "support",
                 table_name: "tickets",
                 status: :config_matches_deployed
               }
             ] = report.tables
    end

    test "keeps bare configured table names as public-schema shorthand" do
      report =
        RedactionPresenter.build_report(
          %{
            "tickets" => [mask: ["email"]],
            "support.tickets" => [mask: ["email"]]
          },
          [],
          schema: "support"
        )

      assert [%{table: "support.tickets", table_schema: "support", table_name: "tickets"}] =
               report.tables
    end
  end
end
