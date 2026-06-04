defmodule Threadline.OperatorSurface.PresentationTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.Presentation

  @now ~U[2026-06-04 12:00:00Z]
  @future ~U[2026-06-04 13:00:00Z]
  @past ~U[2026-06-04 11:00:00Z]

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
end
