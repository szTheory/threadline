defmodule Threadline.StorageSchemaTest do
  # async: false — the default-resolution describe block below temporarily
  # removes `:threadline, :storage_schema` from the application environment,
  # which is process-global. Sync modules run after every async module has
  # finished, so no concurrently-running test can observe the gap.
  use ExUnit.Case, async: false

  alias Threadline.StorageSchema

  # A documented default claim is only looked for on lines that talk about the
  # storage schema. Sources, not compiled regexes, are kept in attributes so the
  # module compiles on OTP releases that refuse regexes in module attributes.
  @default_claim_scope "storage[ _]schema"
  @default_claim_id "`\"?([A-Za-z_][A-Za-z0-9_]*)\"?`"
  @default_claim_sources [
    {"\\bdefaults?\\s+(?:to\\s+)?(?:the host.s\\s+)?" <> @default_claim_id, "i"},
    {"\\(default\\s+" <> @default_claim_id, ""},
    {@default_claim_id <> "\\s+(?:\\(the default\\)|by default)", "i"},
    {"\\busually\\s+" <> @default_claim_id, "i"}
  ]
  @documented_default_files Path.wildcard("guides/**/*.md") ++ ["README.md"]

  describe "default storage schema (D-01)" do
    setup do
      previous = Application.fetch_env(:threadline, :storage_schema)
      Application.delete_env(:threadline, :storage_schema)

      on_exit(fn ->
        case previous do
          {:ok, value} -> Application.put_env(:threadline, :storage_schema, value)
          :error -> Application.delete_env(:threadline, :storage_schema)
        end
      end)

      :ok
    end

    test "resolves to the host's public schema when no storage_schema is configured" do
      assert StorageSchema.get([]) == "public",
             "a host that sets no :storage_schema must resolve to public — anything else " <>
               "prefixes every read path onto tables a pre-0.10 install does not have while " <>
               "its already-deployed unqualified triggers keep writing to public"

      assert StorageSchema.get() == "public"
      assert StorageSchema.table("audit_changes") == ~s("public"."audit_changes")
      assert StorageSchema.repo_opts() == [prefix: "public"]
    end

    test "the configuration reference states the default the code actually resolves" do
      default = StorageSchema.get([])

      row =
        "guides/configuration-and-commands.md"
        |> File.read!()
        |> String.split("\n")
        |> Enum.find(&String.starts_with?(&1, "| `config :threadline, storage_schema:"))

      assert row, "guides/configuration-and-commands.md lost its `storage_schema` row"

      # Columns: key | meaning | default | where documented. The default column
      # must open with the resolved default — 0.10.0 shipped this row still
      # claiming `"threadline"` after the default flipped to `public`.
      [_, _key, _meaning, default_cell | _] = String.split(row, "|")

      assert String.starts_with?(String.trim(default_cell), ~s(`"#{default}"`)),
             "guides/configuration-and-commands.md documents the storage_schema default as " <>
               "#{String.trim(default_cell)}, but StorageSchema resolves #{inspect(default)} " <>
               "when no key is configured"
    end

    test "a dedicated schema stays available as an explicit opt-in" do
      assert StorageSchema.get(storage_schema: "threadline") == "threadline"

      assert StorageSchema.table("audit_changes", storage_schema: "threadline") ==
               ~s("threadline"."audit_changes")

      Application.put_env(:threadline, :storage_schema, "threadline")
      assert StorageSchema.get([]) == "threadline"
    end

    test "every documented storage_schema default matches the code default" do
      default = StorageSchema.get([])

      claims =
        for path <- @documented_default_files,
            {line, value} <- default_claims(File.read!(path)),
            do: {path, line, value}

      offenders = Enum.reject(claims, fn {_path, _line, value} -> value == default end)
      correct = length(claims) - length(offenders)

      assert offenders == [],
             "these docs claim a storage_schema default other than #{inspect(default)}, " <>
               "which StorageSchema.get([]) resolves when no key is configured: " <>
               Enum.map_join(offenders, ", ", fn {path, line, value} ->
                 "#{path}:#{line} -> #{value}"
               end)

      assert correct >= 3,
             "the default-claim scan over guides/**/*.md and README.md found only " <>
               "#{correct} claim(s) of the #{inspect(default)} default; the matcher has " <>
               "probably stopped matching and would pass without checking anything"
    end

    test "the default-claim matcher flags every known offender" do
      offenders = [
        "Threadline stores these relations in the configured `storage_schema` " <>
          "(`threadline` by default, explicit `public` for the historical footprint).",
        "confirm the configured Threadline `storage_schema` exists " <>
          "(default `threadline`, explicit `public` for the historical footprint).",
        "The storage schema defaults to `threadline`.",
        "placeholder schema **`your_schema`** for Threadline's storage schema — usually " <>
          "`threadline` unless you configured `storage_schema: \"public\"` or another name."
      ]

      for sentence <- offenders do
        assert "threadline" in Enum.map(default_claims(sentence), &elem(&1, 1)),
               "the default-claim matcher did not flag: #{sentence}"
      end

      for sentence <- [
            ~s(config :threadline, storage_schema: "threadline"),
            "`storage_schema` **defaults to `\"public\"`**, your host's default schema.",
            "a dedicated schema such as `\"threadline\"` is an opt-in for `storage_schema`"
          ] do
        assert Enum.reject(default_claims(sentence), &(elem(&1, 1) == "public")) == [],
               "the default-claim matcher flagged a correct or opt-in sentence: #{sentence}"
      end
    end
  end

  # Returns {1-based line number, claimed default} for every default claim found
  # on a line that mentions the storage schema.
  defp default_claims(text) do
    scope = Regex.compile!(@default_claim_scope, "i")

    claims =
      Enum.map(@default_claim_sources, fn {source, opts} -> Regex.compile!(source, opts) end)

    text
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.filter(fn {line, _number} -> Regex.match?(scope, line) end)
    |> Enum.flat_map(fn {line, number} ->
      for regex <- claims, [_match, value] <- Regex.scan(regex, line), do: {number, value}
    end)
  end

  test "honours an explicitly configured storage schema" do
    assert StorageSchema.get() == "threadline"
    assert StorageSchema.table("audit_changes") == ~s("threadline"."audit_changes")
  end

  test "accepts explicit public schema opt-out" do
    assert StorageSchema.get(storage_schema: "public") == "public"

    assert StorageSchema.table("audit_changes", storage_schema: "public") ==
             ~s("public"."audit_changes")
  end

  test "accepts one-segment PostgreSQL storage identifiers across helpers" do
    for schema <- ["audit", "threadline", "AuditLog", "_audit1"] do
      assert StorageSchema.get(storage_schema: schema) == schema
      assert StorageSchema.quote_ident(schema) == ~s("#{schema}")
      assert StorageSchema.qualify(schema, "audit_changes") == ~s("#{schema}"."audit_changes")

      assert StorageSchema.table("audit_changes", storage_schema: schema) ==
               ~s("#{schema}"."audit_changes")

      assert StorageSchema.function("threadline_capture_changes", storage_schema: schema) ==
               ~s("#{schema}"."threadline_capture_changes")
    end
  end

  test "rejects unsafe storage schema identifiers before SQL generation" do
    for invalid <- [
          nil,
          true,
          false,
          "",
          "   ",
          "foo.bar",
          "bad-name",
          "threadline;drop schema public",
          String.duplicate("a", 64)
        ] do
      assert_raise ArgumentError, fn ->
        StorageSchema.get(storage_schema: invalid)
      end
    end
  end

  test "parses qualified host table identifiers" do
    assert StorageSchema.parse_table_identifier("support.tickets") == %{
             schema: "support",
             table: "tickets"
           }

    assert StorageSchema.qualified_host_table("support.tickets") == ~s("support"."tickets")
    assert StorageSchema.host_table_suffix("support.tickets") == "support_tickets"
  end

  test "rejects malformed host table identifiers instead of falling back to public" do
    for invalid <- ["", "   ", ".tickets", "support.", "support..tickets", "a.b.c"] do
      assert_raise ArgumentError, fn ->
        StorageSchema.parse_table_identifier(invalid)
      end
    end
  end
end
