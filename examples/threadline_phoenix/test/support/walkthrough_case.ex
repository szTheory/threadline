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
  # with `on_conflict: :replace`. Two concurrent unboxed seed/reset cycles
  # racing on the same primary-key rows take real Postgres row locks against
  # each other; when scheduling happens to overlap this shows up as a blocked
  # `Postgrex.Protocol.msg_recv` inside `insert_all`/`update!`, occasionally
  # exceeding ExUnit's 60s default timeout (198-25 diagnosis: cause class
  # "lock/deadlock against the seeded transaction"). A session-level advisory
  # lock serializes this module's own seed/reset cycles so they can never
  # contend with each other.
  @demo_seed_lock_key :erlang.phash2("threadline_phoenix_demo_seed")

  def seed_demo_fiction! do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      Repo.query!("SELECT pg_advisory_lock($1)", [@demo_seed_lock_key])

      try do
        assert :ok = Reset.run()
        assert :ok = Seed.run()
      after
        Repo.query!("SELECT pg_advisory_unlock($1)", [@demo_seed_lock_key])
      end
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
