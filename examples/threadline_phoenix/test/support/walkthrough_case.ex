defmodule ThreadlinePhoenixWeb.WalkthroughCase do
  @moduledoc false

  import ExUnit.Assertions
  import Phoenix.ConnTest

  alias ThreadlinePhoenix.Accounts
  alias ThreadlinePhoenix.Demo.{Manifest, Reset, Seed}
  alias ThreadlinePhoenix.Repo

  @endpoint ThreadlinePhoenixWeb.Endpoint

  # Demo.Reset/Demo.Seed run outside the ExUnit sandbox (unboxed_run) and
  # upsert deterministic-UUID-keyed rows (see ThreadlinePhoenix.Demo.Manifest.UUID)
  # with `on_conflict: :replace`. Reset.run/1 and Seed.run/0 serialize
  # themselves via a namespaced, bounded, abnormal-exit-safe Postgres
  # advisory lock (see ThreadlinePhoenix.Demo.Reset.with_demo_lock/1),
  # covering every entry point — this module's callers, the other test
  # modules that call Reset.run/1 / Seed.run/0 directly, and the
  # `mix demo.reset` / `mix demo.seed` tasks. All five demo-seeding test
  # modules are `async: false`, so ExUnit never runs two of them
  # concurrently within one `mix test`; the surviving contention the lock
  # guards against is cross-OS-process — a parallel CI lane, a developer
  # running `mix demo.seed`, or a second `mix test` against the same
  # database (WR-02).
  def seed_demo_fiction! do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      assert :ok = Reset.run()
      assert :ok = Seed.run()
    end)
  end

  def demo_user!(key) do
    email = Manifest.user_email(key)

    case Accounts.get_user_by_email(email) do
      nil -> flunk("missing seeded demo user #{email}")
      user -> user
    end
  end

  def login_demo(conn, key) do
    ThreadlinePhoenixWeb.ConnCase.login_via_sigra(conn, demo_user!(key))
  end

  def follow_audit_redirect(conn) do
    case conn.status do
      302 -> get(conn, redirected_to(conn))
      _ -> conn
    end
  end

  def admin_conn do
    build_conn()
    |> login_demo(:admin)
  end

  def retention_run_subject_ref do
    %{
      "run_id" => Manifest.evidence_run_id(:offboarded_retention),
      "org_slug" => Manifest.org_slug(:offboarded_co),
      "organization_id" => Manifest.org_id(:offboarded_co)
    }
  end
end
