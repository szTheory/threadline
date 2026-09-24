defmodule Threadline.TestStructureContractTest do
  @moduledoc """
  Guards the shared operator-surface test templates against copy-paste drift.

  Test endpoints, routers, and root layouts live in one place,
  `test/support/operator_surface_case.ex`. When a contributor hand-rolls a new
  `use Phoenix.Endpoint` or `use Phoenix.Router` in a test file, the duplicated
  boilerplate comes back and the copies drift apart. This contract fails the
  suite when that happens, unless the file is listed in an allowlist with a
  written reason.

  The allowlists are checked for staleness too: an entry whose file is gone,
  or no longer contains the `use` line it excuses, fails the suite so the list
  shrinks as exceptions are removed.

  `validate/3` is a pure function over `{path, source}` pairs, so the detector
  tests run on synthetic input and the real-tree test runs it on the live scan.
  A non-empty scan guard keeps the check from passing vacuously.
  """

  use ExUnit.Case, async: true

  @test_glob "test/**/*.{ex,exs}"

  @template_path "test/support/operator_surface_case.ex"

  @endpoint_use ~r/^\s*use Phoenix\.Endpoint\b/m
  @router_use ~r/^\s*use Phoenix\.Router\b/m

  @endpoint_allowlist %{
    "test/threadline/operator_surface/stress_router_test.exs" =>
      "mounts the stress surface with its own macro (threadline_operator_surface_stress) " <>
        "and live_session :threadline_stress, and compiles throwaway routers, so its " <>
        "endpoints do not fit the shared template"
  }

  @router_allowlist %{
    "test/threadline/operator_surface/router_test.exs" =>
      "throwaway routers built with Code.compile_quoted are the subject under test",
    "test/threadline/operator_surface/stress_router_test.exs" =>
      "mounts the stress surface with its own macro (threadline_operator_surface_stress) " <>
        "and live_session :threadline_stress, and compiles throwaway routers",
    "test/support/stress_router_prod_compile.exs" =>
      "runs under MIX_ENV=prod mix run --no-start, where test/support is not " <>
        "compiled, so it cannot depend on the shared template"
  }

  @doc """
  Checks `files` (a list of `{path, source}`) against the structure rules.

  Returns `:ok`, or `{:error, message}` naming every violation.
  """
  def validate(_files, _endpoint_allowlist, _router_allowlist) do
    # RED: not implemented yet.
    :ok
  end

  defp scan do
    @test_glob
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(fn path -> {path, File.read!(path)} end)
  end

  # Built by concatenation so these lines never start with the `use` text the
  # scan looks for, which keeps this file out of its own offender list.
  defp endpoint_line, do: "  use Phoenix." <> "Endpoint, otp_app: :threadline\n"
  defp router_line, do: "  use Phoenix." <> "Router\n"

  test "the test scan set is non-empty" do
    assert scan() != [],
           "no files matched #{@test_glob}: the glob is broken, and a broken glob would " <>
             "let the structure scan pass vacuously"
  end

  test "test endpoints and routers come from the shared template or a reasoned allowlist" do
    assert validate(scan(), @endpoint_allowlist, @router_allowlist) == :ok
  end

  test "detector: a hand-rolled endpoint is rejected outside the template file" do
    assert {:error, message} =
             validate([{"test/threadline/foo_test.exs", endpoint_line()}], %{}, %{})

    assert message =~ "test/threadline/foo_test.exs"
    assert validate([{@template_path, endpoint_line()}], %{}, %{}) == :ok
  end

  test "detector: a router is accepted only in the template file or an allowlisted path" do
    allowlist = %{"test/threadline/bar_test.exs" => "compiles throwaway routers"}

    assert validate([{"test/threadline/bar_test.exs", router_line()}], %{}, allowlist) == :ok
    assert validate([{@template_path, router_line()}], %{}, %{}) == :ok

    assert {:error, message} =
             validate([{"test/threadline/foo_test.exs", router_line()}], %{}, allowlist)

    assert message =~ "test/threadline/foo_test.exs"
  end

  test "detector: stale and reasonless allowlist entries are rejected" do
    files = [{"test/threadline/plain_test.exs", "defmodule Plain do\nend\n"}]

    assert {:error, missing} =
             validate(files, %{}, %{"test/threadline/gone_test.exs" => "was needed"})

    assert missing =~ "gone_test.exs: the file does not exist"

    assert {:error, no_router} =
             validate(files, %{}, %{"test/threadline/plain_test.exs" => "was needed"})

    assert no_router =~ "plain_test.exs: the file no longer contains `use Phoenix.Router`"

    assert {:error, no_endpoint} =
             validate(files, %{"test/threadline/plain_test.exs" => "was needed"}, %{})

    assert no_endpoint =~ "the file no longer contains `use Phoenix.Endpoint`"

    router_file = [{"test/threadline/bar_test.exs", router_line()}]

    assert {:error, reasonless} =
             validate(router_file, %{}, %{"test/threadline/bar_test.exs" => " "})

    assert reasonless =~ "bar_test.exs has no reason"
  end

  test "detector: an empty scan set is rejected" do
    assert {:error, message} = validate([], %{}, %{})
    assert message =~ "pass vacuously"
  end

  test "every allowlist reason is a non-empty string" do
    for {path, reason} <- Map.merge(@endpoint_allowlist, @router_allowlist) do
      assert is_binary(reason) and String.trim(reason) != "", "#{path} has no reason"
    end

    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end
end
