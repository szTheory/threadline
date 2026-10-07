defmodule Threadline.CloakAdvisoryReachabilityContractTest do
  @moduledoc """
  Keeps the two D-58 Hex advisory acknowledgements tied to the example's live
  encryption configuration. Any future CTR reader, PBKDF2 field, legacy
  ciphertext marker, or opaque non-static fixture requires a new review.
  """

  use ExUnit.Case, async: true

  @example_root "examples/threadline_phoenix"
  @vault_path Path.join(@example_root, "lib/threadline_phoenix/vault.ex")
  @encrypted_path Path.join(@example_root, "lib/threadline_phoenix/accounts/encrypted.ex")
  @scan_roots ["lib", "config", "priv"]
  @text_extensions MapSet.new(
                     ~w(.ex .exs .heex .eex .html .js .ts .json .csv .sql .txt .md .yaml .yml .xml)
                   )

  @forbidden_source_patterns [
    {~r/Cloak\.Ciphers\.AES\.CTR|\bAES\.CTR\b/i, "an AES-CTR cipher or tag"},
    {~r/Cloak\.Ecto\.PBKDF2/i, "a Cloak.Ecto.PBKDF2 field"},
    {~r/Cloak\.(?:Cipher\.)?decrypt!?\s*\(/i,
     "a direct Cloak decryptor or cipher-rotation reader"},
    {~r/\b(?:legacy|deprecated)[\w .-]{0,80}\bCTR\b|\bCTR\b[\w .-]{0,80}\b(?:legacy|ciphertext|decrypt(?:or|ion)?)\b/i,
     "a legacy/deprecated CTR reader or ciphertext marker"}
  ]

  test "the live vault configures exactly one GCM cipher with the established tag" do
    ast = parse_source!(@vault_path)

    assert [init_body] = function_bodies(ast, :init)
    assert [cipher_config] = keyword_put_values(init_body, :ciphers)
    assert Keyword.keys(cipher_config) == [:default]

    assert {cipher_module, cipher_options} = Keyword.fetch!(cipher_config, :default)
    assert alias_segments(cipher_module) == [:Cloak, :Ciphers, :AES, :GCM]
    assert Keyword.fetch!(cipher_options, :tag) == "AES.GCM.V1"
  end

  test "the encrypted field is a live Cloak.Ecto.Binary field using this vault" do
    ast = parse_source!(@encrypted_path)

    assert module_defined?(ast, [:ThreadlinePhoenix, :Accounts, :Encrypted, :Binary])
    assert [options] = use_options(ast, [:Cloak, :Ecto, :Binary])
    assert alias_segments(Keyword.fetch!(options, :vault)) == [:ThreadlinePhoenix, :Vault]
  end

  test "example lib, config, migrations, seeds, and fixtures expose no affected path" do
    sources = example_sources()

    assert Enum.any?(sources, fn {path, _source} -> path == @vault_path end),
           "the source scan must include the live vault"

    assert Enum.any?(sources, fn {path, _source} -> path == @encrypted_path end),
           "the source scan must include the encrypted field"

    offenders =
      for {path, source} <- sources,
          {pattern, description} <- @forbidden_source_patterns,
          Regex.match?(pattern, source) do
        "#{path}: #{description}"
      end

    assert offenders == [],
           "D-58 reachability changed; keep affected advisories blocking and re-scope:\n" <>
             Enum.join(offenders, "\n")
  end

  test "tracked source scan cannot silently omit a non-static binary or new file type" do
    files = example_source_paths()
    unsupported = Enum.reject(files, &MapSet.member?(@text_extensions, Path.extname(&1)))

    assert files != [], "the example source scan is empty"

    assert unsupported == [],
           "review new example source/fixture file types before relying on advisory reachability: " <>
             Enum.join(unsupported, ", ")
  end

  defp example_sources do
    for path <- example_source_paths(),
        MapSet.member?(@text_extensions, Path.extname(path)) do
      {path, File.read!(path)}
    end
  end

  defp example_source_paths do
    @scan_roots
    |> Enum.flat_map(fn root ->
      root
      |> then(&Path.join(@example_root, &1))
      |> Path.join("**/*")
      |> Path.wildcard()
    end)
    |> Enum.filter(&File.regular?/1)
    |> Enum.reject(&String.starts_with?(&1, Path.join(@example_root, "priv/static") <> "/"))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp parse_source!(path) do
    source = File.read!(path)
    assert {:ok, ast} = Code.string_to_quoted(source, file: path)
    ast
  end

  defp function_bodies(ast, name) do
    {_ast, bodies} =
      Macro.prewalk(ast, [], fn
        {:def, _, [{^name, _, [_argument]}, [do: body]]} = node, acc ->
          {node, [body | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(bodies)
  end

  defp keyword_put_values(ast, key) do
    {_ast, values} =
      Macro.prewalk(ast, [], fn
        {{:., _, [{:__aliases__, _, [:Keyword]}, :put]}, _, [_config, ^key, value]} = node, acc ->
          {node, [value | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(values)
  end

  defp use_options(ast, expected_module) do
    {_ast, options} =
      Macro.prewalk(ast, [], fn
        {:use, _, [module, options]} = node, acc when is_list(options) ->
          if alias_segments(module) == expected_module do
            {node, [options | acc]}
          else
            {node, acc}
          end

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(options)
  end

  defp module_defined?(ast, expected_module) do
    {_ast, modules} =
      Macro.prewalk(ast, [], fn
        {:defmodule, _, [module, _body]} = node, acc ->
          if alias_segments(module) == expected_module do
            {node, [module | acc]}
          else
            {node, acc}
          end

        node, acc ->
          {node, acc}
      end)

    modules != []
  end

  defp alias_segments({:__aliases__, _, segments}), do: segments
  defp alias_segments(_), do: nil
end
