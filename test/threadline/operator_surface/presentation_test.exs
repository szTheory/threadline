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

  describe "export status label" do
    test "pending and queued statuses render Queued" do
      for status <- ["pending", "queued"] do
        job = %{status: status, expires_at: @future}
        assert Presentation.export_status_label(job, now: @now) == "Queued"
      end
    end

    test "running and processing statuses render Processing" do
      for status <- ["running", "processing"] do
        job = %{status: status, expires_at: @future}
        assert Presentation.export_status_label(job, now: @now) == "Processing"
      end
    end

    test "failed and error statuses render Failed" do
      for status <- ["failed", "error"] do
        job = %{status: status, expires_at: @future}
        assert Presentation.export_status_label(job, now: @now) == "Failed"
      end
    end

    test "completed jobs with an expired expires_at render Export expired" do
      job = %{status: "completed", expires_at: @past}
      assert Presentation.export_status_label(job, now: @now) == "Export expired"
    end

    test "completed jobs with a missing file (unexpired) render File unavailable" do
      job = %{status: "completed", expires_at: @future}
      assert Presentation.export_status_label(job, now: @now) == "File unavailable"
    end

    test "exact-equality expiry boundary at a frozen clock is treated as expired" do
      job = %{status: "completed", expires_at: @now}

      assert Presentation.export_status_label(job, now: @now) == "Export expired"
    end

    test "nil expires_at on a completed job falls back to File unavailable, not a raise or empty string" do
      job = %{status: "completed", expires_at: nil}

      assert Presentation.export_status_label(job, now: @now) == "File unavailable"
    end

    test "absent expires_at key on a completed job falls back to File unavailable" do
      job = %{status: "completed"}

      assert Presentation.export_status_label(job, now: @now) == "File unavailable"
    end

    test "nil status falls back to a named label, not a raise or empty string" do
      job = %{status: nil, expires_at: @future}

      assert Presentation.export_status_label(job, now: @now) == "Unknown"
    end

    test "unrecognised status falls back to a named, capitalized label" do
      job = %{status: "mystery_state", expires_at: @future}

      assert Presentation.export_status_label(job, now: @now) == "Mystery state"
    end

    test "atom status and its string equivalent resolve to the same label" do
      atom_job = %{status: :pending, expires_at: @future}
      string_job = %{status: "pending", expires_at: @future}

      assert Presentation.export_status_label(atom_job, now: @now) ==
               Presentation.export_status_label(string_job, now: @now)

      assert Presentation.export_status_label(atom_job, now: @now) == "Queued"
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

  describe "truncate_middle tail_min guarantee (DATA-01)" do
    test "preserves at least :tail_min trailing chars verbatim for a long value" do
      # 40-char value, max 34, tail_min 8 → last 8 chars must survive verbatim.
      value = "abcdefghijklmnopqrstuvwxyz0123456789ABCD"
      assert String.length(value) == 40

      result = Presentation.truncate_middle(value, 34, tail_min: 8)

      assert String.length(result) < String.length(value)
      assert String.ends_with?(result, String.slice(value, -8, 8))
      assert String.ends_with?(result, "6789ABCD")
    end

    test "default behavior is byte-for-byte unchanged (export_summary backward-compat)" do
      # The keyword/3rd-arg extension must NOT alter the no-:tail_min path.
      value = "00000000-1111-2222-3333-444444444444"

      assert Presentation.truncate_middle(value, 28) ==
               Presentation.truncate_middle(value, 28, [])
    end

    test "does not truncate values within max_length" do
      assert Presentation.truncate_middle("short", 34, tail_min: 8) == "short"
    end
  end

  describe "ref/2 three faces (DATA-01)" do
    test "returns visible, title, and full with full == the exact complete value" do
      value = "actor/user-01-abcdefghijklmnopqrstuvwxyz-0123456789"

      ref = Presentation.ref(value, kind: :actor)

      assert ref.full == value
      assert ref.title == ref.full
      assert ref.visible != value
      assert String.ends_with?(ref.full, "0123456789")
    end

    test "reuses secondary_ref_value extraction for ActorRef and JSON maps" do
      actor = Presentation.ref(%Threadline.Semantics.ActorRef{type: :user, id: "alice"})
      assert actor.full == "user/alice"
      assert actor.title == "user/alice"
      assert actor.visible == "user/alice"

      json = Presentation.ref(%{"account_id" => "acct_123", "invoice_id" => "inv_456"})
      assert json.full =~ ~s("account_id":"acct_123")
      assert json.title == json.full
    end

    test "short value: visible == full (no truncation)" do
      ref = Presentation.ref("user/alice", kind: :actor)
      assert ref.visible == ref.full
    end

    test "timestamp kind is never truncated (visible == full)" do
      long_iso = "2026-06-04T12:30:00.123456789012345678901234567890Z"
      ref = Presentation.ref(long_iso, kind: :timestamp)
      assert ref.visible == ref.full
      assert ref.full == long_iso
    end

    test "uuid kind middle-truncates while preserving the discriminating tail" do
      uuid = "00000000-1111-2222-3333-444444444444-EXTRA-PADDING-TO-OVERFLOW"
      ref = Presentation.ref(uuid, kind: :uuid)
      assert ref.full == uuid
      assert ref.visible != uuid
      assert String.ends_with?(ref.visible, String.slice(uuid, -8, 8))
    end

    test "hash kind truncates around 24 chars keeping the tail" do
      hash = String.duplicate("a", 30) <> "DEADBEEF"
      ref = Presentation.ref(hash, kind: :hash)
      assert ref.full == hash
      assert ref.visible != hash
      assert String.ends_with?(ref.visible, "DEADBEEF")
    end

    test "path kind keeps the filename tail" do
      path = "/very/long/nested/directory/structure/that/overflows/the/limit/report-final.csv"
      ref = Presentation.ref(path, kind: :path)
      assert ref.full == path
      assert String.ends_with?(ref.visible, "report-final.csv")
    end

    test "email kind keeps the full domain" do
      email = "a-very-long-local-part-that-overflows-the-budget@example-domain.example.com"
      ref = Presentation.ref(email, kind: :email)
      assert ref.full == email
      assert String.ends_with?(ref.visible, "@example-domain.example.com")
    end

    test "url kind keeps host head and last segment tail" do
      url = "https://operator.example.com/audit/very/deep/path/segment/final-resource-id"
      ref = Presentation.ref(url, kind: :url)
      assert ref.full == url
      assert String.starts_with?(ref.visible, "https://operator.example.com")
      assert String.ends_with?(ref.visible, "final-resource-id")
    end
  end

  describe "value_token truncation (DATA-04)" do
    test "truncates a long string while keeping the full value in title" do
      long = String.duplicate("x", 80) <> "TAILMARK"
      token = Presentation.value_token(long)

      assert Map.has_key?(token, :text)
      assert Map.has_key?(token, :modifier)
      assert Map.has_key?(token, :title)
      assert token.title == long
      assert String.length(token.text) < String.length(long)
      assert String.ends_with?(token.text, "TAILMARK")
    end

    test "short strings are untouched and carry no truncation artifacts" do
      assert Presentation.value_token("open") == %{text: "open", modifier: "tl-value--string"}
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
               text: "Jun 4, 12:30 PM UTC",
               title: "2026-06-04T12:30:00Z",
               modifier: "tl-value--time"
             }

      assert Presentation.value_token("2026-06-04T12:30:00Z") == %{
               text: "Jun 4, 12:30 PM UTC",
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
