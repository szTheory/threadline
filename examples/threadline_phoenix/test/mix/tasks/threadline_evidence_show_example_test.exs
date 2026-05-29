defmodule Mix.Tasks.Threadline.EvidenceShowExampleTest do
  @moduledoc false
  use ThreadlinePhoenix.DataCase, async: false

  import ExUnit.CaptureIO

  alias ThreadlinePhoenix.Demo.{Manifest, Reset, Seed}
  alias ThreadlinePhoenix.Repo

  setup do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      assert :ok = Reset.run()
      assert :ok = Seed.run()
    end)

    Mix.Task.reenable("threadline.evidence.show")
    :ok
  end

  test "mix threadline.evidence.show prints seeded retention_run row from example fiction" do
    Mix.Task.run("app.start")
    subject_ref = %{
      "run_id" => Manifest.evidence_run_id(:offboarded_retention),
      "org_slug" => Manifest.org_slug(:offboarded_co),
      "organization_id" => Manifest.org_id(:offboarded_co)
    }

    output =
      capture_io(fn ->
        assert :ok =
                 Mix.Tasks.Threadline.Evidence.Show.run([
                   "--subject",
                   "retention_run",
                   "--subject-ref-json",
                   Jason.encode!(subject_ref)
                 ])
      end)

    assert output =~ "retention_run"
    assert output =~ subject_ref["run_id"]
    assert output =~ "proven"
  end
end
