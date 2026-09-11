defmodule ThreadlinePhoenix.DemoResetTest do
  use ThreadlinePhoenix.DataCase, async: false

  import ThreadlinePhoenix.HelpDeskFixtures

  alias ThreadlinePhoenix.Demo.Reset
  alias ThreadlinePhoenix.HelpDesk.Organization
  alias ThreadlinePhoenix.Repo
  alias Threadline.Governance.ExportJob

  @app_dir Path.expand("../..", __DIR__)

  # Cold `MIX_ENV=prod mix compile` (~30s measured on this machine, 2026-08-30)
  # is paid once here, in `setup_all`, rather than inside the per-test 60s
  # ExUnit timeout budget. ExUnit's `:timeout` does not apply to `setup_all`,
  # so the compile is visible as its own named failure if it breaks, instead
  # of silently eating into (or blowing) the test at line 56. The warm
  # guard-only `mix demo.reset` run measured ~0.75s, comfortably inside the
  # 60s default, so no `@tag timeout:` is added below — a tag that is not
  # needed is itself a small mask.
  setup_all do
    {output, exit_code} =
      System.cmd(
        "mix",
        ["compile"],
        cd: @app_dir,
        env: [{"MIX_ENV", "prod"}],
        stderr_to_stdout: true
      )

    unless exit_code == 0 do
      flunk("""
      MIX_ENV=prod mix compile failed in setup_all — this is a prod build defect,
      not a test-harness defect. Output:

      #{output}
      """)
    end

    :ok
  end

  test "run/0 truncates demo tables then reseeds manifest organizations" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      _org = organization_fixture(%{slug: "ephemeral-fixture-org"})
      {:ok, actor_ref} = Threadline.Semantics.ActorRef.new(:user, "ephemeral-export-owner")

      %ExportJob{}
      |> ExportJob.changeset(%{
        status: "pending",
        query_params: %{"table" => "tickets"},
        actor_ref: actor_ref
      })
      |> Repo.insert!()

      assert Repo.aggregate(Organization, :count, :id) >= 1
      assert Repo.get_by(ExportJob, actor_ref: actor_ref)

      assert :ok = Reset.run()

      assert Repo.get_by!(Organization, slug: "acme")
      assert Repo.get_by!(Organization, slug: "globex")
      assert Repo.get_by!(Organization, slug: "offboarded-co")
      refute Repo.get_by(Organization, slug: "ephemeral-fixture-org")
      refute Repo.get_by(ExportJob, actor_ref: actor_ref)
    end)
  end

  test "assert_dev_or_allowed!/1 raises in prod without DEMO_ALLOW_RESET=1" do
    prev = System.get_env("DEMO_ALLOW_RESET")

    on_exit(fn ->
      case prev do
        nil -> System.delete_env("DEMO_ALLOW_RESET")
        value -> System.put_env("DEMO_ALLOW_RESET", value)
      end
    end)

    System.delete_env("DEMO_ALLOW_RESET")

    assert_raise RuntimeError, ~r/DEMO_ALLOW_RESET/, fn ->
      Reset.assert_dev_or_allowed!(:prod)
    end
  end

  test "prod mix demo.reset fails fast without DEMO_ALLOW_RESET=1" do
    prev = System.get_env("DEMO_ALLOW_RESET")

    on_exit(fn ->
      case prev do
        nil -> System.delete_env("DEMO_ALLOW_RESET")
        value -> System.put_env("DEMO_ALLOW_RESET", value)
      end
    end)

    System.delete_env("DEMO_ALLOW_RESET")

    {output, exit_code} =
      System.cmd(
        "mix",
        ["demo.reset"],
        cd: @app_dir,
        env: [{"MIX_ENV", "prod"}],
        stderr_to_stdout: true
      )

    assert exit_code != 0
    assert output =~ "DEMO_ALLOW_RESET"
  end
end
