defmodule ThreadlinePhoenix.ShapeFixturesMigrationContractTest do
  @moduledoc """
  TWIN-01 (D-20): the committed `*_threadline_triggers_shape_*.exs` fixture
  trigger migration is provably what `mix threadline.gen.triggers` produces
  today. Regenerates the migration into a fresh temp directory, seeded with
  the other committed sibling migrations so the name/module resolution sees
  the same directory state the real generation run saw, and asserts the new
  file is identical to the committed one once the 14-digit version prefix
  and all AST metadata (line numbers) are stripped.

  Never hand-edit the committed fixture migration (D-20 prohibition). If this
  test fails, the fix is always to regenerate it, never to patch it by hand.

  Calls `Mix.Tasks.Threadline.Gen.Triggers.run/1` directly (aliased below as
  `Triggers`, following `test/mix/tasks/threadline/gen_triggers_test.exs`).
  """
  use ExUnit.Case, async: false

  alias Mix.Tasks.Threadline.Gen.Triggers

  @tables "shape_code_keyed,shape_composite,shape_join,shape_twin,shapes.shape_twin,shape_long_name_padded_to_prove_sixty_byte_identifiers_work_ok"

  @committed_dir Path.expand("../../priv/shape_fixtures/migrations", __DIR__)

  @regenerate_hint "Regenerate: cd examples/threadline_phoenix && MIX_ENV=test mix threadline.gen.triggers " <>
                     "--migrations-path priv/shape_fixtures/migrations --tables #{@tables}, delete the old " <>
                     "*_threadline_triggers_shape_*.exs, then run mix format on the new file."

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "shape_fixtures_contract_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    on_exit(fn ->
      Mix.shell(previous_shell)
      File.rm_rf!(tmp)
    end)

    {:ok, tmp: tmp}
  end

  defp committed_files do
    @committed_dir
    |> Path.join("*")
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
  end

  defp committed_trigger_file do
    case Path.wildcard(Path.join(@committed_dir, "*_threadline_triggers_shape_*.exs")) do
      [file] ->
        file

      other ->
        raise "expected exactly one committed *_threadline_triggers_shape_*.exs, got: #{inspect(other)}"
    end
  end

  # Seeds `tmp` with every committed sibling file except the trigger migration
  # itself, so TriggerMigration.scan/1's name/version resolution sees the
  # same directory state the real generation run saw.
  defp seed_siblings!(tmp) do
    trigger_file = committed_trigger_file()

    for file <- committed_files(), file != trigger_file do
      File.cp!(file, Path.join(tmp, Path.basename(file)))
    end
  end

  defp strip_meta(ast) do
    Macro.prewalk(ast, &Macro.update_meta(&1, fn _ -> [] end))
  end

  defp strip_version(basename), do: String.replace(basename, ~r/^\d{14}_/, "")

  test "exactly one committed fixture trigger migration exists" do
    assert length(Path.wildcard(Path.join(@committed_dir, "*_threadline_triggers_shape_*.exs"))) ==
             1
  end

  test "regenerating into a fresh temp dir writes exactly one new file", %{tmp: tmp} do
    seed_siblings!(tmp)
    before = Path.wildcard(Path.join(tmp, "*.exs"))

    Triggers.run(["--migrations-path", tmp, "--tables", @tables])

    new_files = Path.wildcard(Path.join(tmp, "*.exs")) -- before

    assert length(new_files) == 1, @regenerate_hint
  end

  test "the regenerated file matches the committed file (name and AST, version-normalized)", %{
    tmp: tmp
  } do
    seed_siblings!(tmp)
    before = Path.wildcard(Path.join(tmp, "*.exs"))

    Triggers.run(["--migrations-path", tmp, "--tables", @tables])

    [new_file] = Path.wildcard(Path.join(tmp, "*.exs")) -- before
    committed_file = committed_trigger_file()

    assert strip_version(Path.basename(new_file)) == strip_version(Path.basename(committed_file)),
           @regenerate_hint

    new_ast = new_file |> File.read!() |> Code.string_to_quoted!() |> strip_meta()

    committed_ast =
      committed_file |> File.read!() |> Code.string_to_quoted!() |> strip_meta()

    assert new_ast == committed_ast, @regenerate_hint
  end

  test "an edited copy is detected as unequal (the contract is not vacuous)" do
    committed_file = committed_trigger_file()
    original_source = File.read!(committed_file)

    # Flip one SQL character deep inside the migration body. If this
    # replacement finds nothing, the committed file's shape changed and this
    # control must be updated to still exercise a real difference.
    edited_source =
      String.replace(original_source, "CREATE OR REPLACE TRIGGER", "CREATE OR REPLACE  TRIGGER",
        global: false
      )

    assert edited_source != original_source,
           "the edited-copy control made no change — update it to flip a real character, " <>
             "so this test still proves the contract is not vacuous"

    original_ast = original_source |> Code.string_to_quoted!() |> strip_meta()
    edited_ast = edited_source |> Code.string_to_quoted!() |> strip_meta()

    refute original_ast == edited_ast,
           "edited copy was judged equal to the original — the AST comparison is vacuous"
  end
end
