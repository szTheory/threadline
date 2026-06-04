defmodule Threadline.OperatorSurface.PresentationTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.Presentation

  @now ~U[2026-06-04 12:00:00Z]
  @future ~U[2026-06-04 13:00:00Z]
  @past ~U[2026-06-04 11:00:00Z]

  describe "operation presentation" do
    test "maps insert operation variants to the insert modifier" do
      assert Presentation.operation_modifier("INSERT") == "tl-change__op--insert"
      assert Presentation.operation_modifier("insert") == "tl-change__op--insert"
      assert Presentation.operation_modifier(:insert) == "tl-change__op--insert"
    end

    test "maps update operations to the update modifier" do
      assert Presentation.operation_modifier("UPDATE") == "tl-change__op--update"
    end

    test "maps delete operations to the delete modifier" do
      assert Presentation.operation_modifier("DELETE") == "tl-change__op--delete"
    end

    test "returns a safe empty modifier for nil and unknown operations without creating atoms" do
      unknown = "SURPRISE_#{System.unique_integer([:positive])}"

      assert_raise ArgumentError, fn -> :erlang.binary_to_existing_atom(unknown) end
      assert Presentation.operation_modifier(nil) == ""
      assert Presentation.operation_modifier(unknown) == ""
      assert_raise ArgumentError, fn -> :erlang.binary_to_existing_atom(unknown) end
    end

    test "labels known operations uppercase and unknown operations safely" do
      assert Presentation.operation_label("insert") == "INSERT"
      assert Presentation.operation_label(:update) == "UPDATE"
      assert Presentation.operation_label("DELETE") == "DELETE"
      assert Presentation.operation_label("snapshot") == "SNAPSHOT"
      assert Presentation.operation_label(nil) == "UNKNOWN"
    end
  end

  describe "export readiness" do
    test "completed unexpired jobs with a file path are ready to hand off" do
      job = %{status: "completed", file_path: "/tmp/export.csv", expires_at: @future}

      assert Presentation.export_readiness(job, now: @now) == :ready
      assert Presentation.export_readiness_title(job, now: @now) == "Ready to hand off"
      assert Presentation.export_readiness_rank(job, now: @now) == 0
      assert Presentation.export_downloadable?(job, now: @now)
      assert Presentation.export_action_label(job, now: @now) == "Download export"
    end

    test "pending and running jobs are preparing and cannot download" do
      for status <- ["pending", "running"] do
        job = %{status: status, file_path: nil, expires_at: @future}

        assert Presentation.export_readiness(job, now: @now) == :preparing
        assert Presentation.export_readiness_title(job, now: @now) == "Preparing"
        assert Presentation.export_readiness_rank(job, now: @now) == 1
        refute Presentation.export_downloadable?(job, now: @now)
        assert Presentation.export_action_label(job, now: @now) == "Preparing download"
      end
    end

    test "failed jobs need attention and use the source-search recovery action" do
      job = %{status: "failed", file_path: nil, expires_at: @future}

      assert Presentation.export_readiness(job, now: @now) == :needs_attention
      assert Presentation.export_readiness_title(job, now: @now) == "Needs attention"
      assert Presentation.export_readiness_rank(job, now: @now) == 2
      refute Presentation.export_downloadable?(job, now: @now)
      assert Presentation.export_action_label(job, now: @now) == "Reopen source search"
    end

    test "expired and missing-file completed jobs are unavailable with explicit labels" do
      expired = %{status: "completed", file_path: "/tmp/export.csv", expires_at: @past}
      missing = %{status: "completed", file_path: nil, expires_at: @future}

      assert Presentation.export_readiness(expired, now: @now) == :unavailable
      assert Presentation.export_readiness_title(expired, now: @now) == "Unavailable"
      assert Presentation.export_readiness_rank(expired, now: @now) == 3
      assert Presentation.export_action_label(expired, now: @now) == "Export expired"

      assert Presentation.export_readiness(missing, now: @now) == :unavailable
      assert Presentation.export_action_label(missing, now: @now) == "File unavailable"
    end
  end

  describe "secondary refs" do
    test "keeps the full value in title and truncates visible text" do
      value = "actor/user-01-abcdefghijklmnopqrstuvwxyz-0123456789"

      assert %{title: ^value, visible: visible} = Presentation.secondary_ref(value, 24)
      assert visible != value
      assert String.starts_with?(visible, "actor/user")
      assert String.ends_with?(visible, "23456789")
    end

    test "normalizes actor refs and JSON subject refs" do
      assert Presentation.secondary_ref(%Threadline.Semantics.ActorRef{type: :user, id: "alice"}) ==
               %{visible: "user/alice", title: "user/alice"}

      ref =
        Presentation.secondary_ref(%{"account_id" => "acct_123", "invoice_id" => "inv_456"}, 80)

      assert ref.title =~ ~s("account_id":"acct_123")
      assert ref.visible == ref.title
    end
  end

  describe "find value tokens" do
    test "renders nil, redacted strings, and ordinary primitives as escaped text data" do
      assert Presentation.value_token(nil) == %{text: "null", modifier: "tl-value--null"}

      assert Presentation.value_token("[REDACTED]") == %{
               text: "[REDACTED]",
               modifier: "tl-value--redacted"
             }

      assert Presentation.value_token("open") == %{text: "open", modifier: "tl-value--string"}
      assert Presentation.value_token(true) == %{text: "true", modifier: "tl-value--primitive"}
      assert Presentation.value_token(42) == %{text: "42", modifier: "tl-value--primitive"}
    end

    test "renders DateTime and ISO8601 timestamp strings with exact titles" do
      dt = ~U[2026-06-04 12:30:00Z]

      assert Presentation.value_token(dt) == %{
               text: "Today, 12:30 PM UTC",
               title: "2026-06-04T12:30:00Z",
               modifier: "tl-value--time"
             }

      assert Presentation.value_token("2026-06-04T12:30:00Z") == %{
               text: "Today, 12:30 PM UTC",
               title: "2026-06-04T12:30:00Z",
               modifier: "tl-value--time"
             }
    end

    test "renders maps and lists as deterministic JSON text" do
      assert Presentation.value_token(%{"b" => 2, "a" => 1}) == %{
               text: ~s({"a":1,"b":2}),
               modifier: "tl-value--json"
             }

      assert Presentation.value_token([%{"id" => 2}, %{"id" => 1}]) == %{
               text: ~s([{"id":2},{"id":1}]),
               modifier: "tl-value--json"
             }
    end
  end

  describe "find change value tokens" do
    test "distinguishes absent keys, omitted prior state, and present nil" do
      assert Presentation.change_value_token(%{"name" => "status"}, "before") == %{
               text: "(omitted)",
               modifier: "tl-value--omitted"
             }

      assert Presentation.change_value_token(%{"name" => "status"}, "after") == %{
               text: "(absent)",
               modifier: "tl-value--absent"
             }

      assert Presentation.change_value_token(%{"name" => "status", "before" => nil}, "before") ==
               %{
                 text: "null",
                 modifier: "tl-value--null"
               }
    end
  end

  describe "find coverage labels" do
    test "renders expected gap count grammar" do
      assert Presentation.expected_gap_count_label(1) == "1 expected gap"
      assert Presentation.expected_gap_count_label(2) == "2 expected gaps"
    end

    test "returns concrete remediation guidance for a table" do
      assert Presentation.coverage_remediation("tickets") == %{
               label: "Add capture",
               command: "mix threadline.gen.triggers --tables tickets",
               follow_up: "Run mix threadline.verify_coverage after applying the migration."
             }
    end

    test "does not build copyable remediation commands for unsupported identifiers" do
      assert Presentation.coverage_remediation("unsafe; touch /tmp/pwned") == %{
               label: "Add capture",
               command: nil,
               follow_up:
                 "Generate a trigger migration for public.unsafe; touch /tmp/pwned after confirming the identifier; do not paste an auto-built shell command for this table."
             }
    end

    test "does not build copyable remediation commands for non-public schemas" do
      assert Presentation.coverage_remediation("tickets", schema: "tenant_iso") == %{
               label: "Add capture",
               command: nil,
               follow_up:
                 "Generate a trigger migration for tenant_iso.tickets after confirming the identifier; do not paste an auto-built shell command for this table."
             }
    end
  end

  describe "find actor transaction summaries" do
    test "falls back when change data is unavailable" do
      assert Presentation.actor_transaction_summary(nil) == "Changes unavailable"
      assert Presentation.actor_transaction_summary([]) == "Changes unavailable"
    end

    test "summarizes operation, table breadth, and field-change count" do
      assert Presentation.actor_transaction_summary([
               %{"op" => "update", "table_name" => "tickets", "field_changes" => [1, 2, 3]}
             ]) == "UPDATE tickets - 3 changes"

      assert Presentation.actor_transaction_summary([
               %{"op" => "update", "table_name" => "tickets", "field_changes" => [1, 2, 3]},
               %{"op" => "update", "table_name" => "ticket_replies", "field_changes" => [4, 5]},
               %{"op" => "update", "table_name" => "accounts", "field_changes" => [6, 7]}
             ]) == "UPDATE tickets + 2 tables - 7 changes"
    end
  end
end
