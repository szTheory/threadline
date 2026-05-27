defmodule Threadline.CiTopologyContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "ci.yml defines PgBouncer topology job with transaction pool and mix verify.topology" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert String.contains?(yaml, "verify-pgbouncer-topology:")
    assert String.contains?(yaml, "POOL_MODE: transaction")
    assert String.contains?(yaml, "AUTH_TYPE: scram-sha-256")
    assert String.contains?(yaml, "THREADLINE_PGBOUNCER_TOPOLOGY: \"1\"")
    assert String.contains?(yaml, "mix verify.topology")
    assert String.contains?(yaml, "priv/ci/topology_bootstrap.exs")
    assert String.contains?(yaml, "edoburu/pgbouncer:")
  end

  test "ci.all alias does not include verify.bench" do
    mix_exs = read_rel!(["mix.exs"])

    assert mix_exs =~ "\"ci.all\": ["

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.bench\"")
  end

  test "ci.all alias does not include verify.release" do
    mix_exs = read_rel!(["mix.exs"])

    assert mix_exs =~ "\"ci.all\": ["

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.release\"")
  end

  test "mix aliases expose the named support-lane proof entrypoints" do
    mix_exs = read_rel!(["mix.exs"])

    assert String.contains?(mix_exs, "\"verify.compile_no_optional\":")
    assert String.contains?(mix_exs, "\"compile --no-optional-deps --warnings-as-errors\"")
    assert String.contains?(mix_exs, "\"verify.test\": [\"test\"]")
    assert String.contains?(mix_exs, "\"verify.example\": &verify_example/1")

    assert String.contains?(mix_exs, "\"verify.doc_contract\": [")
    assert String.contains?(mix_exs, "test test/threadline/readme_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/how_threadline_works_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/operator_surface_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/upgrade_path_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/getting_started_saas_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/audit_doc_contract_test.exs")

    assert String.contains?(
             mix_exs,
             "test/threadline/integration_contracts_doc_contract_test.exs"
           )

    assert String.contains?(mix_exs, "test/threadline/example_phoenix_readme_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/v1_23_charter_doc_contract_test.exs")
  end

  test "ci.all keeps capture-only and phoenix-surface proof steps in order" do
    mix_exs = read_rel!(["mix.exs"])

    assert [_, ci_block] =
             Regex.run(~r/"ci\.all":\s*\[\s*\n((?:.*\n)*?)\s*\]/, mix_exs),
           "expected mix.exs to declare a multiline ci.all list"

    {pos_compile_strict, _} = :binary.match(ci_block, "\"compile --warnings-as-errors\"")
    {pos_compile_no_optional, _} = :binary.match(ci_block, "\"verify.compile_no_optional\"")
    {pos_verify_test, _} = :binary.match(ci_block, "\"verify.test\"")
    {pos_verify_threadline, _} = :binary.match(ci_block, "\"verify.threadline\"")
    {pos_verify_example, _} = :binary.match(ci_block, "\"verify.example\"")
    {pos_verify_doc_contract, _} = :binary.match(ci_block, "\"verify.doc_contract\"")

    assert pos_compile_strict < pos_compile_no_optional
    assert pos_compile_no_optional < pos_verify_test
    assert pos_verify_test < pos_verify_threadline
    assert pos_verify_threadline < pos_verify_example
    assert pos_verify_example < pos_verify_doc_contract
  end

  test "ci workflow exposes the documented support-lane job ids" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert Regex.match?(~r/^  verify-compile-no-optional:/m, yaml)
    assert Regex.match?(~r/^  verify-test:/m, yaml)
    assert Regex.match?(~r/^  verify-docs:/m, yaml)
  end

  test "verify-test job runs the phoenix-surface and sigra-reference proof path" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert String.contains?(yaml, "- name: Run tests")
    assert String.contains?(yaml, "run: mix verify.test")
    assert String.contains?(yaml, "- name: Verify Threadline trigger coverage")
    assert String.contains?(yaml, "run: mix verify.threadline")
    assert String.contains?(yaml, "- name: Verify Threadline Phoenix example")
    assert String.contains?(yaml, "run: mix verify.example")
    assert String.contains?(yaml, "- name: Doc contract tests")
    assert String.contains?(yaml, "run: mix verify.doc_contract")
  end

  test "adoption pilot backlog carries CI topology contract marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "CI-PGBOUNCER-TOPOLOGY-CONTRACT")
  end

  test "adoption pilot backlog carries STG host topology template marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
  end

  test "adoption pilot backlog carries STG audited path rubric marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  end
end
