defmodule Threadline.HealthFindingsDocContractTest do
  @moduledoc """
  Keeps `Threadline.Health.TriggerFindings.codes/0`, the domain-reference and
  production-checklist guides, and the `Finding`/`Telemetry` moduledocs
  aligned. A code or the findings telemetry event added to the source without
  a matching doc update fails this test (CLAUDE.md: doc contract tests).
  """

  use ExUnit.Case, async: true

  alias Threadline.Health.{Finding, TriggerFindings}

  @domain_reference_path "guides/domain-reference.md"
  @production_checklist_path "guides/production-checklist.md"
  @configuration_and_commands_path "guides/configuration-and-commands.md"

  @findings_checked_event "[:threadline, :health, :findings_checked]"

  defp read_rel!(path), do: File.read!(Path.join(File.cwd!(), path))

  defp moduledoc!(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} -> moduledoc
      other -> flunk("expected #{inspect(module)} to have a moduledoc, got: #{inspect(other)}")
    end
  end

  test "TriggerFindings.codes/0 is non-empty" do
    codes = TriggerFindings.codes()

    assert codes != [],
           "Threadline.Health.TriggerFindings.codes/0 must not be empty " <>
             "(a vacuous list would make every check below pass trivially)"
  end

  test "every code appears in domain-reference.md and the Finding moduledoc" do
    domain_reference = read_rel!(@domain_reference_path)
    finding_moduledoc = moduledoc!(Finding)

    for code <- TriggerFindings.codes() do
      literal = inspect(code)

      assert String.contains?(domain_reference, literal),
             "missing #{literal} in #{@domain_reference_path}"

      assert String.contains?(finding_moduledoc, literal),
             "missing #{literal} in the Threadline.Health.Finding moduledoc"
    end
  end

  test "[:threadline, :health, :findings_checked] appears in domain-reference.md and the Telemetry moduledoc" do
    domain_reference = read_rel!(@domain_reference_path)
    telemetry_moduledoc = moduledoc!(Threadline.Telemetry)

    assert String.contains?(domain_reference, "findings_checked"),
           "missing findings_checked telemetry event in #{@domain_reference_path}"

    assert String.contains?(telemetry_moduledoc, @findings_checked_event),
           "missing #{@findings_checked_event} in the Threadline.Telemetry moduledoc"
  end

  test "production-checklist.md documents the findings gate" do
    checklist = read_rel!(@production_checklist_path)

    assert String.contains?(checklist, "verify_coverage"),
           "missing verify_coverage in #{@production_checklist_path}"

    assert String.contains?(checklist, ":capture_trigger_disabled"),
           "missing :capture_trigger_disabled in #{@production_checklist_path}"
  end

  test "configuration-and-commands.md mentions findings" do
    guide = read_rel!(@configuration_and_commands_path)

    assert String.contains?(guide, "findings"),
           "missing \"findings\" in #{@configuration_and_commands_path}"
  end
end
