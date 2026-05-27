defmodule ThreadlinePhoenix.DemoResetTest do
  use ThreadlinePhoenix.DataCase, async: false

  import ThreadlinePhoenix.HelpDeskFixtures

  alias ThreadlinePhoenix.Demo.Reset
  alias ThreadlinePhoenix.HelpDesk.Organization
  alias ThreadlinePhoenix.Repo

  @app_dir Path.expand("../..", __DIR__)

  test "run/0 truncates demo tables then reseeds manifest organizations" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      _org = organization_fixture(%{slug: "ephemeral-fixture-org"})

      assert Repo.aggregate(Organization, :count, :id) >= 1

      assert :ok = Reset.run()

      assert Repo.get_by!(Organization, slug: "acme")
      assert Repo.get_by!(Organization, slug: "globex")
      assert Repo.get_by!(Organization, slug: "offboarded-co")
      refute Repo.get_by(Organization, slug: "ephemeral-fixture-org")
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
