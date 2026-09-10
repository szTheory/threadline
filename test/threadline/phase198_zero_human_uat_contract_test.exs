defmodule Threadline.Phase198ZeroHumanUatContractTest do
  use ExUnit.Case, async: false

  @phase_dir ".planning/phases/198-green-bringup"
  @manifest ".planning/audits/198-summary-coverage-manifest.json"
  @delta ".planning/audits/198-plan46-coverage-delta.json"
  @baseline_numbers Enum.map(1..47, &(Integer.to_string(&1) |> String.pad_leading(2, "0")))
  @closeout_start 48
  @audited_final_plan_number 61
  @terminal_certification_plan_number 62
  @closeout_numbers Enum.map(@closeout_start..@audited_final_plan_number, &Integer.to_string/1)
  @final_state_numbers @baseline_numbers ++ @closeout_numbers
  @terminal_certification_number Integer.to_string(@terminal_certification_plan_number)
  @post_terminal_numbers ~w(63 64 65)
  @policy_repair_number "66"
  @plan46_numbers Enum.map(1..45, &(Integer.to_string(&1) |> String.pad_leading(2, "0")))
  @exact_delta MapSet.new([
                 "198-01:D4",
                 "198-03:D7",
                 "198-04:D8",
                 "198-05:D2",
                 "198-05:D5",
                 "198-05:D7",
                 "198-06:D3",
                 "198-06:D4",
                 "198-07:D3",
                 "198-12:D5",
                 "198-18:D3",
                 "198-27:D3",
                 "198-29:D3",
                 "198-31:D4",
                 "198-37:D4"
               ])

  test "immutable summaries 01-47 match the repository-owned manifest" do
    manifest = read_json!(@manifest)
    assert manifest["scope"] == "phase-198-only"
    assert manifest["general_classifier_owner"] == "phase-199"
    assert @audited_final_plan_number == 61
    assert @terminal_certification_plan_number == 62
    assert manifest["baseline_numbers"] == @baseline_numbers
    assert manifest["audited_final_plan_number"] == @audited_final_plan_number
    assert manifest["terminal_certification_plan_number"] == @terminal_certification_plan_number
    assert manifest["allowed_closeout_numbers"] == @closeout_numbers
    assert manifest["final_state_numbers"] == @final_state_numbers

    assert_manifest_namespace!(manifest)

    assert manifest["baseline_counts"] == %{
             "automated_passes" => 192,
             "coverage_entries" => 192,
             "errors" => 0,
             "present" => 0,
             "summaries" => 47
           }

    expected = Map.new(manifest["summaries"], &{&1["number"], &1})
    assert expected |> Map.keys() |> Enum.sort() == @baseline_numbers

    actual_entry_count =
      Enum.sum(
        for number <- @baseline_numbers,
            do: summary_path(number) |> File.read!() |> coverage_entries() |> map_size()
      )

    assert actual_entry_count == manifest["baseline_counts"]["coverage_entries"]
    assert actual_entry_count == 192

    for number <- @baseline_numbers do
      relative = summary_path(number)
      body = File.read!(relative)
      entries = coverage_entries(body)
      record = Map.fetch!(expected, number)

      assert record["path"] == relative
      assert record["sha256"] == digest(body), "#{relative} changed"
      assert record["coverage_ids"] == entries |> Map.keys() |> Enum.sort()
      assert record["verification_state_sha256"] == verification_digest(entries)
      assert coverage_errors(entries, relative) == []
    end
  end

  test "manifest declares the exact content-bound post-terminal repair policy" do
    manifest = read_json!(@manifest)
    assert_post_terminal_policy!(manifest)

    assert Map.keys(manifest) |> Enum.sort() ==
             Enum.sort([
               "schema_version",
               "scope",
               "general_classifier_owner",
               "audited_final_plan_number",
               "terminal_certification_plan_number",
               "baseline_numbers",
               "allowed_closeout_numbers",
               "final_state_numbers",
               "baseline_counts",
               "summaries",
               "post_terminal_policy"
             ])
  end

  test "summary discovery rejects missing, renamed, modified, and out-of-namespace files" do
    mode = if System.get_env("PHASE198_SUMMARY_SET") == "final", do: :final, else: :normal
    assert validate_summary_set!(@phase_dir, mode) == :ok
  end

  test "every present closeout summary is independently automated and valid" do
    for number <- @closeout_numbers ++ [@terminal_certification_number],
        path = summary_path(number),
        File.regular?(path) do
      entries = path |> File.read!() |> coverage_entries()
      assert coverage_errors(entries, path) == []
    end
  end

  test "summaries 53 through 55 are valid members of the exact closeout namespace" do
    assert Enum.all?(~w(53 54 55), &(&1 in @closeout_numbers))

    for number <- ~w(53 54 55) do
      path = summary_path(number)
      assert File.regular?(path)
      assert path |> File.read!() |> coverage_entries() |> coverage_errors(path) == []
    end
  end

  test "isolated discovery fixtures enforce audited final timing and the sole Plan 62 exception" do
    root = phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)

    assert validate_summary_set!(root, :normal) == :ok

    assert_raise ExUnit.AssertionError, ~r/missing audited.*56.*57.*58.*59.*60.*61/s, fn ->
      validate_summary_set!(root, :final)
    end

    for number <- 56..61, do: write_summary!(root, Integer.to_string(number), "[]")
    write_repair_summary!(root)
    assert validate_summary_set!(root, :final) == :ok

    File.rm!(Path.join(root, "198-58-SUMMARY.md"))

    assert_raise ExUnit.AssertionError, ~r/missing audited.*58/s, fn ->
      validate_summary_set!(root, :final)
    end

    write_summary!(root, "58", "[]")
    malformed = Path.join(root, "198-58-copy-SUMMARY.md")
    File.write!(malformed, summary_body("[]"))

    assert_raise ExUnit.AssertionError, ~r/198-58-copy-SUMMARY\.md/, fn ->
      validate_summary_set!(root, :final)
    end

    File.rm!(malformed)

    for illegal <- ~w(00 048 67) do
      write_summary!(root, illegal, "[]")

      assert_raise ExUnit.AssertionError, ~r/#{illegal}/, fn ->
        validate_summary_set!(root, :normal)
      end

      File.rm!(Path.join(root, "198-#{illegal}-SUMMARY.md"))
    end

    write_summary!(root, @terminal_certification_number, "[]")
    assert validate_summary_set!(root, :final) == :ok
  end

  test "Plan 62 remains outside the audited set and must carry mechanical passing coverage" do
    root = phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)
    for number <- 56..61, do: write_summary!(root, Integer.to_string(number), "[]")

    invalid_entries = [
      "  - id: D1\n    human_judgment: false\n    verification:\n      - kind: integration",
      "  - id: D1\n    human_judgment: false\n    verification:\n      - kind: integration\n        ref: \"focused test\"\n        status: fail",
      "  - id: D1\n    human_judgment: true\n    verification:\n      - kind: integration\n        ref: \"focused test\"\n        status: pass"
    ]

    for entry <- invalid_entries do
      write_summary!(root, @terminal_certification_number, "\n" <> entry)

      assert_raise ExUnit.AssertionError, ~r/198-62-SUMMARY\.md:D1/, fn ->
        validate_summary_set!(root, :normal)
      end
    end

    passing =
      "\n  - id: D1\n    human_judgment: false\n    verification:\n      - kind: integration\n        ref: \"focused test\"\n        status: pass"

    write_summary!(root, @terminal_certification_number, passing)
    write_repair_summary!(root)
    assert validate_summary_set!(root, :final) == :ok

    assert discover_numbers(root) --
             (@final_state_numbers ++ @post_terminal_numbers ++ [@policy_repair_number]) ==
             [@terminal_certification_number]
  end

  test "coverage accepts only an explicit empty list or structurally valid entries" do
    assert coverage_entries(summary_body("[]")) == %{}

    assert_raise ExUnit.AssertionError, ~r/malformed coverage block/, fn ->
      coverage_entries(summary_body("\n  this is not a coverage entry"))
    end
  end

  test "Plan 46 changed exactly the literal 15-entry coverage allowlist" do
    delta = read_json!(@delta)
    assert MapSet.new(delta["allowlist"]) == @exact_delta
    assert length(delta["allowlist"]) == 15

    pre = coverage_at_tree(delta["pre_plan46_tree"])
    post = coverage_at_tree(delta["post_plan46_tree"])
    changed = changed_keys(pre, post)

    assert changed == @exact_delta,
           "Plan 46 coverage delta mismatch: missing=#{inspect(MapSet.difference(@exact_delta, changed))} " <>
             "extra=#{inspect(MapSet.difference(changed, @exact_delta))}"
  end

  test "manifest data and copied evidence stay repository-relative and secret-free" do
    for relative <- [@manifest, @delta] do
      value = read_json!(relative)

      assert disclosure_errors(value) == [],
             "unsafe field in #{relative}: #{inspect(disclosure_errors(value))}"
    end

    unsafe = %{
      "authorization" => "Bearer example",
      "path" => "/private/workstation/path",
      "cookie" => "session=example"
    }

    for {key, value} <- unsafe do
      assert disclosure_errors(%{key => value}) != []
    end
  end

  test "each content-bound post-terminal summary fails closed under file mutations" do
    for number <- @post_terminal_numbers do
      assert_summary_fixture_rejected!(
        fn root ->
          File.rm!(Path.join(root, "198-#{number}-SUMMARY.md"))
        end,
        ~r/missing post-terminal summary #{number}/
      )

      assert_summary_fixture_rejected!(
        fn root ->
          File.rename!(
            Path.join(root, "198-#{number}-SUMMARY.md"),
            Path.join(root, "198-0#{number}-SUMMARY.md")
          )
        end,
        ~r/0#{number}/
      )

      assert_summary_fixture_rejected!(
        fn root ->
          File.rename!(
            Path.join(root, "198-#{number}-SUMMARY.md"),
            Path.join(root, "198-#{number}-copy-SUMMARY.md")
          )
        end,
        ~r/198-#{number}-copy-SUMMARY\.md/
      )

      assert_summary_fixture_rejected!(
        fn root ->
          path = Path.join(root, "198-#{number}-SUMMARY.md")
          File.write!(path, File.read!(path) <> "\n")
        end,
        ~r/changed/
      )

      assert_summary_fixture_rejected!(
        fn root ->
          path = Path.join(root, "198-#{number}-SUMMARY.md")

          File.write!(
            path,
            String.replace(File.read!(path), "phase: 198-green-bringup", "phase: 199",
              global: false
            )
          )
        end,
        ~r/changed|wrong phase/
      )

      assert_summary_fixture_rejected!(
        fn root ->
          path = Path.join(root, "198-#{number}-SUMMARY.md")

          File.write!(
            path,
            "---\nphase: 198-green-bringup\nplan: #{number}\ncoverage:\n  malformed\nstatus: complete\n---\n"
          )
        end,
        ~r/changed|malformed coverage/
      )
    end

    assert_summary_fixture_rejected!(
      fn root ->
        File.write!(Path.join(root, "198-67-SUMMARY.md"), summary_body("[]"))
      end,
      ~r/67/
    )
  end

  test "post-terminal manifest schema rejects identity, order, membership, and role mutations" do
    manifest = read_json!(@manifest)
    policy = manifest["post_terminal_policy"]

    mutations = [
      put_in(manifest, ["post_terminal_policy", "numbers"], ~w(63 65 64)),
      put_in(manifest, ["post_terminal_policy", "summaries"], Enum.reverse(policy["summaries"])),
      put_in(manifest, ["post_terminal_policy", "summaries", Access.at(0), "number"], "64"),
      put_in(manifest, ["post_terminal_policy", "summaries", Access.at(0), "path"], "wrong"),
      put_in(
        manifest,
        ["post_terminal_policy", "summaries", Access.at(0), "sha256"],
        String.duplicate("0", 64)
      ),
      update_in(manifest, ["post_terminal_policy"], &Map.delete(&1, "numbers")),
      put_in(manifest, ["post_terminal_policy", "extra"], true),
      update_in(manifest, ["post_terminal_policy", "summaries"], &tl/1),
      update_in(manifest, ["post_terminal_policy", "summaries"], &(&1 ++ [List.last(&1)])),
      put_in(manifest, ["post_terminal_policy", "policy_repair_summary", "number"], "65"),
      put_in(
        manifest,
        ["post_terminal_policy", "policy_repair_summary", "terminal_certification"],
        true
      ),
      put_in(
        manifest,
        ["post_terminal_policy", "policy_repair_summary", "excluded_from_audited_final_state"],
        false
      )
    ]

    for mutated <- mutations do
      assert_raise ExUnit.AssertionError, fn ->
        validate_manifest_json!(Jason.encode!(mutated))
      end
    end
  end

  test "duplicate manifest members are rejected recursively in both orders before map conversion" do
    raw = File.read!(@manifest)

    for {key, fixture} <- post_terminal_duplicate_fixtures(raw) do
      assert {:error, {:duplicate_member, ^key}} = decode_unique_ordered_json(fixture)
    end
  end

  test "Plan 66 is optional only before final mode and fails closed whenever present" do
    root = complete_phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)

    assert validate_summary_set!(root, :normal) == :ok

    assert_raise ExUnit.AssertionError, ~r/missing policy repair summary 66/, fn ->
      validate_summary_set!(root, :final)
    end

    write_repair_summary!(root)
    assert validate_summary_set!(root, :final) == :ok

    for {mutation, reason} <- repair_summary_mutations() do
      path = Path.join(root, "198-66-SUMMARY.md")
      original = File.read!(path)
      File.write!(path, mutation.(original))
      assert_raise ExUnit.AssertionError, reason, fn -> validate_summary_set!(root, :normal) end
      File.write!(path, original)
    end

    File.rename!(Path.join(root, "198-66-SUMMARY.md"), Path.join(root, "198-066-SUMMARY.md"))

    assert_raise ExUnit.AssertionError, ~r/066/, fn ->
      validate_summary_set!(root, :normal)
    end

    File.rename!(Path.join(root, "198-066-SUMMARY.md"), Path.join(root, "198-66-SUMMARY.md"))
    File.write!(Path.join(root, "198-67-SUMMARY.md"), summary_body("[]"))

    assert_raise ExUnit.AssertionError, ~r/67/, fn ->
      validate_summary_set!(root, :final)
    end
  end

  test "Plan 66 rejects contradictory duplicate frontmatter fields before trusting values" do
    root = complete_phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)
    write_repair_summary!(root)
    path = Path.join(root, "198-66-SUMMARY.md")
    original = File.read!(path)

    duplicate_fields = [
      {"phase", "phase: 198-green-bringup", "phase: 199"},
      {"plan", "plan: 66", "plan: 65"},
      {"status", "status: complete", "status: halted"},
      {"coverage", "coverage: []", "coverage:\n  malformed"}
    ]

    for {field, canonical, conflicting} <- duplicate_fields,
        fixture <- [
          String.replace(original, canonical, conflicting <> "\n" <> canonical, global: false),
          String.replace(original, canonical, canonical <> "\n" <> conflicting, global: false)
        ] do
      File.write!(path, fixture)

      assert_raise ExUnit.AssertionError, ~r/duplicate frontmatter field #{field}/, fn ->
        validate_summary_set!(root, :normal)
      end
    end
  end

  test "Plan 66 rejects YAML key aliases outside the constrained frontmatter grammar" do
    root = complete_phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)
    write_repair_summary!(root)
    path = Path.join(root, "198-66-SUMMARY.md")
    original = File.read!(path)

    canonical_fields = [
      {"phase: 198-green-bringup", [{~s("phase": 199), "phase"}, {~s('phase': 199), "phase"}]},
      {"plan: 66", [{~s("plan": 65), "plan"}, {~s('plan': 65), "plan"}]},
      {"status: complete", [{~s("status": halted), "status"}, {~s('status': halted), "status"}]},
      {"coverage: []", [{~s("coverage": []), "coverage"}, {~s('coverage': []), "coverage"}]}
    ]

    for {canonical, aliases} <- canonical_fields,
        {alias_line, _field} <- aliases,
        fixture <- [
          String.replace(original, canonical, alias_line <> "\n" <> canonical, global: false),
          String.replace(original, canonical, canonical <> "\n" <> alias_line, global: false)
        ] do
      File.write!(path, fixture)

      assert_raise ExUnit.AssertionError,
                   ~r/unsupported root frontmatter syntax/,
                   fn -> validate_summary_set!(root, :normal) end
    end

    equivalent_aliases = [
      "phase : 199",
      "!!str phase: 199",
      "&identity phase: 199",
      "? phase\n: 199",
      "{phase: 199}"
    ]

    for alias_syntax <- equivalent_aliases,
        fixture <- [
          String.replace(
            original,
            "phase: 198-green-bringup",
            alias_syntax <> "\nphase: 198-green-bringup",
            global: false
          ),
          String.replace(
            original,
            "phase: 198-green-bringup",
            "phase: 198-green-bringup\n" <> alias_syntax,
            global: false
          )
        ] do
      File.write!(path, fixture)

      assert_raise ExUnit.AssertionError, ~r/unsupported root frontmatter syntax/, fn ->
        validate_summary_set!(root, :normal)
      end
    end
  end

  test "reserved root fields cannot hide behind indentation or YAML alias syntax" do
    root = complete_phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)
    write_repair_summary!(root)
    path = Path.join(root, "198-66-SUMMARY.md")
    original = File.read!(path)

    fields = [
      {"phase", "phase: 198-green-bringup", "199"},
      {"plan", "plan: 66", "65"},
      {"status", "status: complete", "halted"},
      {"coverage", "coverage: []", "[]"}
    ]

    aliases = [
      fn field, value -> "#{field}: #{value}" end,
      fn field, value -> ~s("#{field}": #{value}) end,
      fn field, value -> ~s('#{field}': #{value}) end,
      fn field, value -> "#{field} : #{value}" end,
      fn field, value -> "!!str #{field}: #{value}" end,
      fn field, value -> "&identity #{field}: #{value}" end,
      fn field, value -> "? #{field}\n: #{value}" end,
      fn field, value -> "{#{field}: #{value}}" end,
      fn field, value -> ~s(!!str "#{field}": #{value}) end,
      fn field, value -> ~s(&identity '#{field}': #{value}) end,
      fn field, value -> ~s(? "#{field}"\n: #{value}) end,
      fn field, value -> ~s({"#{field}": #{value}}) end
    ]

    for {field, canonical, value} <- fields,
        alias_builder <- aliases,
        indentation <- [" ", "  ", "    ", "        ", "\t"] do
      alias_syntax = indent_each_line(alias_builder.(field, value), indentation)

      for fixture <- [
            String.replace(original, canonical, alias_syntax <> "\n" <> canonical, global: false),
            String.replace(original, canonical, canonical <> "\n" <> alias_syntax, global: false)
          ] do
        assert_raise ExUnit.AssertionError,
                     ~r/indented frontmatter outside a recognized block/,
                     fn ->
                       strict_frontmatter!(fixture, "fixture")
                     end
      end
    end

    assert validate_summary_set!(root, :final) == :ok
  end

  test "indented mappings require an active recognized root block" do
    body = File.read!(summary_path("66"))

    for indentation <- [" ", "  ", "    ", "        ", "\t"],
        fixture <- [
          String.replace(
            body,
            "phase: 198-green-bringup",
            indentation <> "shadow: true\nphase: 198-green-bringup",
            global: false
          ),
          String.replace(
            body,
            "phase: 198-green-bringup",
            "phase: 198-green-bringup\n" <> indentation <> "shadow: true",
            global: false
          )
        ] do
      assert_raise ExUnit.AssertionError,
                   ~r/indented frontmatter outside a recognized block/,
                   fn -> strict_frontmatter!(fixture, "fixture") end
    end
  end

  test "coverage entry and verification item fields are exact before semantic trust" do
    body = File.read!(summary_path("66"))

    entry_duplicates = [
      {"description", ~r/^    description:.*$/m, "    description: \"conflicting\""},
      {"requirement", ~r/^    requirement:.*$/m, "    requirement: GREEN-04"},
      {"verification", ~r/^    verification:$/m, "    verification:"},
      {"human_judgment", ~r/^    human_judgment:.*$/m, "    human_judgment: true"}
    ]

    for {field, canonical_pattern, conflicting} <- entry_duplicates do
      [canonical] = Regex.run(canonical_pattern, body)

      for fixture <- [
            String.replace(body, canonical, conflicting <> "\n" <> canonical, global: false),
            String.replace(body, canonical, canonical <> "\n" <> conflicting, global: false)
          ] do
        assert_raise ExUnit.AssertionError, ~r/duplicate field #{field}/, fn ->
          strict_frontmatter!(fixture, "fixture")
        end
      end
    end

    verification_duplicates = [
      {"ref", ~r/^        ref:.*$/m, "        ref: \"conflicting\""},
      {"status", ~r/^        status:.*$/m, "        status: fail"}
    ]

    for {field, canonical_pattern, conflicting} <- verification_duplicates do
      [canonical] = Regex.run(canonical_pattern, body)

      for fixture <- [
            String.replace(body, canonical, conflicting <> "\n" <> canonical, global: false),
            String.replace(body, canonical, canonical <> "\n" <> conflicting, global: false)
          ] do
        assert_raise ExUnit.AssertionError, ~r/duplicate field #{field}/, fn ->
          strict_frontmatter!(fixture, "fixture")
        end
      end
    end

    unknown_entry =
      String.replace(
        body,
        "    human_judgment: false",
        "    surprise: true\n    human_judgment: false",
        global: false
      )

    unknown_item =
      String.replace(body, "        status: pass", "        surprise: true\n        status: pass",
        global: false
      )

    assert_raise ExUnit.AssertionError, ~r/unknown coverage field surprise/, fn ->
      strict_frontmatter!(unknown_entry, "fixture")
    end

    assert_raise ExUnit.AssertionError, ~r/unknown verification field surprise/, fn ->
      strict_frontmatter!(unknown_item, "fixture")
    end
  end

  test "verification refs use only non-empty canonical double-quoted scalars" do
    body = File.read!(summary_path("66"))
    refs = Regex.scan(~r/^        ref:.*$/m, body) |> List.flatten()
    assert length(refs) >= 2
    assert strict_frontmatter!(body, "198-66-SUMMARY.md")

    invalid_values = [
      ~s(""),
      ~s("   "),
      "null",
      "Null",
      "NULL",
      "~",
      "unquoted",
      "'single quoted'",
      ~s("unterminated),
      ~s("bad\\q"),
      "|",
      ">"
    ]

    for canonical <- [List.first(refs), List.last(refs)], value <- invalid_values do
      fixture = String.replace(body, canonical, "        ref: #{value}", global: false)

      assert_raise ExUnit.AssertionError,
                   ~r/(?:empty verification ref|non-canonical verification ref)/,
                   fn -> strict_frontmatter!(fixture, "fixture") end
    end

    for indicator <- ["|", ">"] do
      canonical = List.first(refs)

      fixture =
        String.replace(body, canonical, "        ref: #{indicator}\n          hidden value",
          global: false
        )

      assert_raise ExUnit.AssertionError, ~r/non-canonical verification ref/, fn ->
        strict_frontmatter!(fixture, "fixture")
      end
    end
  end

  test "identity and coverage control scalars reject YAML coercion aliases" do
    body = File.read!(summary_path("66"))

    root_mutations = [
      {"phase: 198-green-bringup", [~s(phase: "198-green-bringup"), "phase: null", "phase: ~"]},
      {"plan: 66", [~s(plan: "66"), "plan: 066", "plan: null", "plan: ~"]},
      {"status: complete", [~s(status: "complete"), "status: true", "status: null", "status: ~"]}
    ]

    for {canonical, mutations} <- root_mutations, mutation <- mutations do
      fixture = String.replace(body, canonical, mutation, global: false)

      assert_raise ExUnit.AssertionError,
                   ~r/(?:non-canonical (?:phase|plan|status) scalar|wrong phase|wrong plan|invalid status)/,
                   fn ->
                     validate_summary_semantics!(fixture, "fixture", "66", ["complete"])
                   end
    end

    scalar_mutations = [
      {~r/^      - kind: integration$/m,
       ["null", "~", "true", ~s("integration"), "!!str integration"],
       ~r/non-canonical kind scalar/},
      {~r/^        status: pass$/m, ["null", "~", "true", "yes", ~s("pass"), "!!str pass"],
       ~r/non-canonical status scalar/},
      {~r/^    human_judgment: false$/m, ["null", "~", "no", "off", ~s("false"), "!!bool false"],
       ~r/non-canonical human_judgment scalar/}
    ]

    for {pattern, values, reason} <- scalar_mutations, value <- values do
      [canonical] = Regex.run(pattern, body)
      [prefix] = Regex.run(~r/^\s*(?:- )?[A-Za-z_][A-Za-z0-9_-]*:\s*/, canonical)
      fixture = String.replace(body, canonical, prefix <> value, global: false)

      assert_raise ExUnit.AssertionError, reason, fn ->
        strict_frontmatter!(fixture, "fixture")
      end
    end
  end

  test "Plan 66 coverage leaf scalars reject aliases across D1 and D2" do
    body = File.read!(summary_path("66"))

    leaf_cases = [
      {~r/^    description:.*$/m,
       [
         ~s(""),
         ~s("   "),
         "null",
         "~",
         "unquoted",
         "'single'",
         "!!str value",
         "&value text",
         "|",
         ">",
         ~s("bad\\q")
       ], ~r/(?:description is empty|description is not a canonical double-quoted string)/},
      {~r/^    requirement:.*$/m,
       [
         "null",
         "~",
         ~s("GREEN-04"),
         "'GREEN-04'",
         "!!str GREEN-04",
         "&req GREEN-04",
         "[GREEN-04]",
         "|",
         ">",
         "GREEN-4"
       ], ~r/non-canonical requirement scalar/},
      {~r/^      - kind:.*$/m,
       [
         "null",
         "~",
         ~s("integration"),
         "'integration'",
         "!!str integration",
         "&kind integration",
         "[integration]",
         "|",
         ">"
       ], ~r/non-canonical kind scalar/},
      {~r/^        status:.*$/m,
       [
         "null",
         "~",
         ~s("pass"),
         "'pass'",
         "!!str pass",
         "&status pass",
         "[pass]",
         "|",
         ">",
         "true"
       ], ~r/non-canonical status scalar/},
      {~r/^    human_judgment:.*$/m,
       [
         "null",
         "~",
         ~s("false"),
         "'false'",
         "!!bool false",
         "&human false",
         "[false]",
         "|",
         ">",
         "no"
       ], ~r/non-canonical human_judgment scalar/}
    ]

    for {pattern, aliases, reason} <- leaf_cases,
        canonical <- [
          List.first(Regex.scan(pattern, body) |> List.flatten()),
          List.last(Regex.scan(pattern, body) |> List.flatten())
        ],
        alias_value <- aliases do
      [prefix] = Regex.run(~r/^\s*(?:- )?[A-Za-z_][A-Za-z0-9_-]*:\s*/, canonical)
      fixture = String.replace(body, canonical, prefix <> alias_value, global: false)

      assert_raise ExUnit.AssertionError, reason, fn ->
        strict_frontmatter!(fixture, "fixture")
      end
    end
  end

  test "coverage IDs reject null-like aliases and semantic duplicates before maps" do
    for id <- ~w(D1 D2) do
      canonical = strict_coverage_entry(id, "canonical #{id}")
      conflicting = strict_coverage_entry(id, "conflicting #{id}")

      for entries <- [canonical <> "\n" <> conflicting, conflicting <> "\n" <> canonical] do
        assert_raise ExUnit.AssertionError, ~r/duplicate coverage id #{id}/, fn ->
          strict_frontmatter!(repair_summary_body(entries), "fixture")
        end
      end

      for alias_id <- [
            "null",
            "Null",
            "NULL",
            "~",
            ~s("#{id}"),
            "'#{id}'",
            "!!str #{id}",
            "&id #{id}",
            "[#{id}]",
            "|",
            ">",
            "D0",
            "D01"
          ] do
        aliased = strict_coverage_entry(alias_id, "aliased #{id}")

        for entries <- [aliased <> "\n" <> canonical, canonical <> "\n" <> aliased] do
          assert_raise ExUnit.AssertionError, ~r/non-canonical coverage id/, fn ->
            strict_frontmatter!(repair_summary_body(entries), "fixture")
          end
        end
      end
    end
  end

  test "Plan 66 rejects repeated coverage IDs in both orders before entry validation" do
    root = complete_phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)

    passing =
      "  - id: D1\n    description: \"passing\"\n    requirement: GREEN-04\n    verification:\n      - kind: integration\n        ref: \"fixture\"\n        status: pass\n    human_judgment: false"

    conflicting =
      "  - id: D1\n    description: \"conflicting\"\n    requirement: GREEN-04\n    verification:\n      - kind: integration\n        ref: \"conflicting\"\n        status: fail\n    human_judgment: true"

    for coverage <- [passing <> "\n" <> conflicting, conflicting <> "\n" <> passing] do
      write_repair_summary!(root, "\n" <> coverage)

      assert_raise ExUnit.AssertionError, ~r/duplicate coverage id D1/, fn ->
        validate_summary_set!(root, :normal)
      end
    end

    assert @final_state_numbers ==
             Enum.map(1..47, &(Integer.to_string(&1) |> String.pad_leading(2, "0"))) ++
               Enum.map(48..61, &Integer.to_string/1)

    assert @terminal_certification_number == "62"
    assert @post_terminal_numbers == ~w(63 64 65)
    assert @policy_repair_number == "66"
  end

  defp discover_numbers(dir) do
    dir
    |> Path.join("198-*-SUMMARY.md")
    |> Path.wildcard()
    |> Enum.map(fn path ->
      case Regex.run(~r/198-(\d+)-SUMMARY\.md$/, path, capture: :all_but_first) do
        [number] -> number
        _ -> flunk("malformed Phase 198 summary path: #{path}")
      end
    end)
    |> Enum.sort()
  end

  defp validate_summary_set!(dir, mode) do
    manifest = read_json!(@manifest)
    assert_manifest_namespace!(manifest)
    policy = assert_post_terminal_policy!(manifest)
    discovered = discover_numbers(dir)

    allowed =
      @final_state_numbers ++
        [@terminal_certification_number] ++ policy["numbers"] ++ [@policy_repair_number]

    unexpected = discovered -- allowed
    missing_baseline = @baseline_numbers -- discovered

    assert unexpected == [], "unexpected Phase 198 summary numbers: #{inspect(unexpected)}"

    assert missing_baseline == [],
           "missing immutable Phase 198 summaries: #{inspect(missing_baseline)}"

    if mode == :final do
      audited = Enum.filter(discovered, &(&1 in @final_state_numbers))
      missing = @final_state_numbers -- audited
      extra = audited -- @final_state_numbers

      assert missing == [] and extra == [],
             "final Phase 198 state has missing audited summaries #{inspect(missing)} and extra audited summaries #{inspect(extra)}"

      assert @policy_repair_number in discovered,
             "final Phase 198 state is missing policy repair summary #{@policy_repair_number}"
    end

    for number <- @closeout_numbers ++ [@terminal_certification_number],
        number in discovered,
        path = Path.join(dir, "198-#{number}-SUMMARY.md") do
      entries = path |> File.read!() |> coverage_entries()
      assert coverage_errors(entries, path) == []
    end

    validate_post_terminal_summaries!(dir, discovered, policy)

    if @policy_repair_number in discovered do
      validate_repair_summary!(Path.join(dir, "198-#{@policy_repair_number}-SUMMARY.md"))
    end

    :ok
  end

  defp assert_manifest_namespace!(manifest) do
    assert manifest["audited_final_plan_number"] == @audited_final_plan_number
    assert manifest["terminal_certification_plan_number"] == @terminal_certification_plan_number

    assert manifest["terminal_certification_plan_number"] ==
             manifest["audited_final_plan_number"] + 1

    assert manifest["baseline_numbers"] == @baseline_numbers
    assert manifest["allowed_closeout_numbers"] == @closeout_numbers
    assert manifest["final_state_numbers"] == @final_state_numbers
    assert Enum.uniq(manifest["final_state_numbers"]) == manifest["final_state_numbers"]
    assert Enum.all?(manifest["final_state_numbers"], &String.match?(&1, ~r/^\d{2}$/))
    assert List.first(manifest["allowed_closeout_numbers"]) == Integer.to_string(@closeout_start)
  end

  defp assert_post_terminal_policy!(manifest) do
    expected = %{
      "policy" => "explicit-content-bound-repair-summaries",
      "audited_final_state_unchanged" => true,
      "terminal_certification_unchanged" => true,
      "numbers" => @post_terminal_numbers,
      "summaries" => [
        %{
          "number" => "63",
          "path" => ".planning/phases/198-green-bringup/198-63-SUMMARY.md",
          "sha256" => "12fc1b775f7822b74bbc5d8648e15eb37ae5387dff726dded9ca6bc7e2e2c23c"
        },
        %{
          "number" => "64",
          "path" => ".planning/phases/198-green-bringup/198-64-SUMMARY.md",
          "sha256" => "76e9ed1735d3885114c7de09cdb721bac2ce34a5f9cc7d3696eb46d2ef0fe4da"
        },
        %{
          "number" => "65",
          "path" => ".planning/phases/198-green-bringup/198-65-SUMMARY.md",
          "sha256" => "9542156d7a2aaf0209a7e48920fed1b581163e5fd2e07b8ce4248eb2ed5d87b0"
        }
      ],
      "policy_repair_summary" => %{
        "number" => "66",
        "path" => ".planning/phases/198-green-bringup/198-66-SUMMARY.md",
        "role" => "post-terminal-policy-repair-execution-summary",
        "required_in_final_mode" => true,
        "excluded_from_audited_final_state" => true,
        "terminal_certification" => false
      }
    }

    assert manifest["post_terminal_policy"] == expected,
           "manifest post_terminal_policy does not match the normative contract"

    expected
  end

  defp validate_post_terminal_summaries!(dir, discovered, policy) do
    for record <- policy["summaries"] do
      number = record["number"]
      assert number in discovered, "missing post-terminal summary #{number}"

      path = Path.join(dir, Path.basename(record["path"]))
      body = File.read!(path)
      assert Path.basename(path) == Path.basename(record["path"])
      assert digest(body) == record["sha256"], "#{path} changed"
      validate_summary_semantics!(body, path, number, ["complete", "halted"])
    end
  end

  defp validate_repair_summary!(path) do
    body = File.read!(path)
    validate_summary_semantics!(body, path, @policy_repair_number, ["complete"])
  end

  defp validate_summary_semantics!(body, path, number, allowed_statuses) do
    yaml = strict_frontmatter!(body, path)
    assert Regex.match?(~r/^phase:\s*198-green-bringup\s*$/m, yaml), "#{path} has wrong phase"
    assert Regex.match?(~r/^plan:\s*#{Regex.escape(number)}\s*$/m, yaml), "#{path} has wrong plan"

    [_, status] = Regex.run(~r/^status:\s*([^\s]+)\s*$/m, yaml)
    assert status in allowed_statuses, "#{path} has invalid status #{status}"

    entries = coverage_entries(body)
    assert coverage_errors(entries, path) == []
  end

  defp phase_fixture! do
    root = Path.join(System.tmp_dir!(), "phase198-summary-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    for number <- @baseline_numbers ++ ~w(48 49 50 51 52 53 54 55 63 64 65) do
      File.cp!(summary_path(number), Path.join(root, "198-#{number}-SUMMARY.md"))
    end

    root
  end

  defp complete_phase_fixture! do
    root = phase_fixture!()

    for number <- ~w(56 57 58 59 60 61 62) do
      File.cp!(summary_path(number), Path.join(root, "198-#{number}-SUMMARY.md"))
    end

    root
  end

  defp assert_summary_fixture_rejected!(mutation, reason) do
    root = complete_phase_fixture!()

    try do
      mutation.(root)
      assert_raise ExUnit.AssertionError, reason, fn -> validate_summary_set!(root, :normal) end
    after
      File.rm_rf!(root)
    end
  end

  defp write_summary!(dir, number, coverage) do
    File.write!(Path.join(dir, "198-#{number}-SUMMARY.md"), summary_body(coverage))
  end

  defp write_repair_summary!(dir, coverage \\ "[]") do
    File.write!(
      Path.join(dir, "198-#{@policy_repair_number}-SUMMARY.md"),
      "---\nphase: 198-green-bringup\nplan: 66\ncoverage: #{coverage}\nstatus: complete\n---\n# Fixture\n"
    )
  end

  defp repair_summary_body(entries) do
    "---\nphase: 198-green-bringup\nplan: 66\ncoverage:\n#{entries}\nstatus: complete\n---\n"
  end

  defp strict_coverage_entry(id, description) do
    "  - id: #{id}\n    description: #{Jason.encode!(description)}\n    requirement: GREEN-04\n    verification:\n      - kind: integration\n        ref: \"fixture\"\n        status: pass\n    human_judgment: false"
  end

  defp repair_summary_mutations do
    [
      {&String.replace(&1, "phase: 198-green-bringup", "phase: 199", global: false),
       ~r/wrong phase/},
      {&String.replace(&1, "plan: 66", "plan: 65", global: false), ~r/wrong plan/},
      {&String.replace(&1, "status: complete", "status: halted", global: false),
       ~r/invalid status/},
      {&String.replace(&1, "coverage: []", "coverage:\n  malformed", global: false),
       ~r/malformed coverage block|coverage content precedes/},
      {&String.replace(
         &1,
         "coverage: []",
         "coverage:\n  - id: D1\n    description: \"human fixture\"\n    requirement: GREEN-04\n    verification:\n      - kind: integration\n        ref: \"fixture\"\n        status: pass\n    human_judgment: true",
         global: false
       ), ~r/is human/},
      {&String.replace(
         &1,
         "coverage: []",
         "coverage:\n  - id: D1\n    description: \"failing fixture\"\n    requirement: GREEN-04\n    verification:\n      - kind: integration\n        ref: \"fixture\"\n        status: fail\n    human_judgment: false",
         global: false
       ), ~r/is not all-pass/}
    ]
  end

  defp summary_body(coverage),
    do: "---\ncoverage: #{coverage}\nstatus: complete\n---\n# Fixture\n"

  defp summary_path(number), do: Path.join(@phase_dir, "198-#{number}-SUMMARY.md")

  defp read_json!(relative) do
    raw = File.read!(relative)
    assert {:ok, value} = decode_unique_ordered_json(raw)
    value
  end

  defp validate_manifest_json!(raw) do
    assert {:ok, manifest} = decode_unique_ordered_json(raw)
    assert_manifest_namespace!(manifest)
    assert_post_terminal_policy!(manifest)

    assert Map.keys(manifest) |> Enum.sort() ==
             Enum.sort([
               "schema_version",
               "scope",
               "general_classifier_owner",
               "audited_final_plan_number",
               "terminal_certification_plan_number",
               "baseline_numbers",
               "allowed_closeout_numbers",
               "final_state_numbers",
               "baseline_counts",
               "summaries",
               "post_terminal_policy"
             ])

    :ok
  end

  defp decode_unique_ordered_json(raw) when is_binary(raw) do
    with {:ok, ordered} <- Jason.decode(raw, objects: :ordered_objects),
         :ok <- reject_duplicate_members(ordered) do
      {:ok, ordered_to_plain(ordered)}
    end
  end

  defp reject_duplicate_members(%Jason.OrderedObject{values: members}) do
    keys = Enum.map(members, &elem(&1, 0))

    case duplicate_key(keys) do
      nil -> Enum.reduce_while(members, :ok, &reject_member_duplicates/2)
      key -> {:error, {:duplicate_member, key}}
    end
  end

  defp reject_duplicate_members(values) when is_list(values) do
    Enum.reduce_while(values, :ok, fn value, :ok ->
      case reject_duplicate_members(value) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp reject_duplicate_members(_scalar), do: :ok

  defp reject_member_duplicates({_key, value}, :ok) do
    case reject_duplicate_members(value) do
      :ok -> {:cont, :ok}
      error -> {:halt, error}
    end
  end

  defp duplicate_key(keys) do
    keys
    |> Enum.reduce_while(MapSet.new(), fn key, seen ->
      if MapSet.member?(seen, key),
        do: {:halt, key},
        else: {:cont, MapSet.put(seen, key)}
    end)
    |> case do
      %MapSet{} -> nil
      key -> key
    end
  end

  defp ordered_to_plain(%Jason.OrderedObject{values: members}) do
    Map.new(members, fn {key, value} -> {key, ordered_to_plain(value)} end)
  end

  defp ordered_to_plain(values) when is_list(values), do: Enum.map(values, &ordered_to_plain/1)
  defp ordered_to_plain(scalar), do: scalar

  defp post_terminal_duplicate_fixtures(raw) do
    root = [
      {"scope", String.replace(raw, "{", ~s({"scope":"wrong",), global: false)},
      {"scope", append_root_member(raw, "scope", ~s("wrong"))}
    ]

    policy = [
      {"policy",
       String.replace(
         raw,
         ~s("post_terminal_policy": {),
         ~s("post_terminal_policy": {\n    "policy":"wrong",),
         global: false
       )},
      {"policy",
       String.replace(
         raw,
         ~s("policy": "explicit-content-bound-repair-summaries",),
         ~s("policy": "explicit-content-bound-repair-summaries",\n    "policy":"wrong",),
         global: false
       )}
    ]

    records =
      for number <- @post_terminal_numbers,
          fixture <- duplicate_number_pair(raw, number) do
        {"number", fixture}
      end

    repair =
      for fixture <- duplicate_number_pair(raw, @policy_repair_number) do
        {"number", fixture}
      end

    root ++ policy ++ records ++ repair
  end

  defp duplicate_number_pair(raw, number) do
    [marker] = Regex.run(~r/^\s*"number": "#{Regex.escape(number)}",$/m, raw)
    [_, indentation] = Regex.run(~r/^(\s*)/, marker)

    [
      String.replace(raw, marker, ~s(#{indentation}"number":"wrong",\n#{marker}), global: false),
      String.replace(raw, marker, ~s(#{marker}\n#{indentation}"number":"wrong",), global: false)
    ]
  end

  defp append_root_member(raw, key, value) do
    String.replace(raw, ~r/\n}\s*\z/, ~s(,\n  "#{key}":#{value}\n}\n))
  end

  defp frontmatter(body) do
    case Regex.run(~r/\A---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|\z)/, body, capture: :all_but_first) do
      [yaml] ->
        yaml

      _ ->
        flunk("summary has no strictly delimited YAML frontmatter")
    end
  end

  defp strict_frontmatter!(body, path) do
    yaml = frontmatter(body)

    root_fields =
      ~w(phase plan subsystem tags requires provides affects actuals tech-stack key-files key-decisions patterns-established requirements-completed requirements-pending coverage duration completed status)

    block_fields =
      ~w(requires provides actuals tech-stack key-files key-decisions patterns-established coverage)

    {keys, blocks, _current} =
      yaml
      |> String.split(~r/\r?\n/)
      |> Enum.reduce({[], %{}, nil}, fn line, {keys, blocks, current} ->
        cond do
          line == "" or String.match?(line, ~r/^\s*#/) ->
            {keys, blocks, current}

          Regex.match?(~r/^[^ \t]/, line) ->
            case Regex.run(~r/^([A-Za-z_][A-Za-z0-9_-]*):(?:[ \t]*(.*))$/, line,
                   capture: :all_but_first
                 ) do
              [key, value] ->
                assert key in root_fields, "#{path} has unknown root frontmatter field #{key}"
                validate_root_scalar_shape!(key, value, path)
                next = if value == "" and key in block_fields, do: key, else: nil
                {[key | keys], Map.put_new(blocks, key, []), next}

              _ ->
                flunk("#{path} has unsupported root frontmatter syntax: #{line}")
            end

          current == nil ->
            flunk("#{path} has indented frontmatter outside a recognized block: #{line}")

          String.contains?(line, "\t") ->
            flunk("#{path} has unsupported tab indentation in #{current}: #{line}")

          true ->
            assert_block_line!(current, line, path)
            {keys, Map.update!(blocks, current, &(&1 ++ [line])), current}
        end
      end)

    case duplicate_key(Enum.reverse(keys)) do
      nil -> :ok
      key -> flunk("duplicate frontmatter field #{key}")
    end

    if Map.get(blocks, "coverage", []) != [] do
      [_, plan] = Regex.run(~r/^plan:\s*([^\s]+)\s*$/m, yaml)
      validate_strict_coverage_block!(blocks["coverage"], path, plan)
    end

    yaml
  end

  defp assert_block_line!("coverage", _line, _path), do: :ok

  defp assert_block_line!(block, line, path) do
    valid =
      case block do
        "requires" ->
          String.match?(line, ~r/^  - phase:\s*.+$/) or
            String.match?(line, ~r/^    provides:\s*.+$/)

        block when block in ["provides", "key-decisions", "patterns-established"] ->
          String.match?(line, ~r/^  -\s+.+$/)

        block when block in ["actuals", "tech-stack"] ->
          String.match?(line, ~r/^  [A-Za-z_][A-Za-z0-9_-]*:\s*.*$/)

        "key-files" ->
          String.match?(line, ~r/^  [A-Za-z_][A-Za-z0-9_-]*:\s*.*$/) or
            String.match?(line, ~r/^    -\s+.+$/)
      end

    assert valid, "#{path} has invalid #{block} block line: #{line}"
  end

  defp validate_strict_coverage_block!(lines, path, plan) do
    entries = split_yaml_items!(lines, ~r/^  - id:/, "#{path} coverage")
    ids = Enum.map(entries, &validate_strict_coverage_entry!(&1, path, plan))

    case duplicate_key(ids) do
      nil -> :ok
      id -> flunk("duplicate coverage id #{id}")
    end
  end

  defp validate_strict_coverage_entry!([id_line | lines], path, plan) do
    id =
      case Regex.run(~r/^  - id:\s*(D[1-9]\d*)\s*$/, id_line) do
        [_, value] -> value
        _ -> flunk("#{path} has non-canonical coverage id")
      end

    expected_requirement =
      Map.get(%{"64" => "GREEN-12", "65" => "GREEN-12", "66" => "GREEN-04"}, plan)

    {fields, verification_lines, _in_verification} =
      Enum.reduce(lines, {[], [], false}, fn line,
                                             {fields, verification_lines, in_verification} ->
        case Regex.run(~r/^    ([A-Za-z_][A-Za-z0-9_-]*):(?:[ \t]*(.*))$/, line,
               capture: :all_but_first
             ) do
          [field, value] ->
            assert field in ~w(description requirement verification human_judgment),
                   "#{path}:#{id} has unknown coverage field #{field}"

            assert field != "verification" or value == "",
                   "#{path}:#{id} verification must be a block"

            case field do
              "description" ->
                validate_canonical_string!(value, "#{path}:#{id} description")

              "requirement" ->
                assert expected_requirement != nil and value == expected_requirement,
                       "#{path}:#{id} has non-canonical requirement scalar"

              "human_judgment" ->
                assert value in ~w(true false),
                       "#{path}:#{id} has non-canonical human_judgment scalar"

              "verification" ->
                :ok
            end

            {[field | fields], verification_lines, field == "verification"}

          _ ->
            assert in_verification, "#{path}:#{id} has invalid coverage entry line: #{line}"
            {fields, verification_lines ++ [line], true}
        end
      end)

    assert_exact_fields!(
      Enum.reverse(fields),
      ~w(description requirement verification human_judgment),
      "#{path}:#{id} coverage entry"
    )

    verification_lines
    |> split_yaml_items!(~r/^      - kind:\s*.+$/, "#{path}:#{id} verification")
    |> Enum.each(&validate_strict_verification_item!(&1, "#{path}:#{id}"))

    id
  end

  defp validate_strict_verification_item!([kind_line | lines], owner) do
    kind =
      case Regex.run(~r/^      - kind:\s*([^\s]+)\s*$/, kind_line) do
        [_, value] -> value
        _ -> flunk("#{owner} has non-canonical kind scalar")
      end

    assert kind in ~w(integration unit e2e other manual_procedural),
           "#{owner} has non-canonical kind scalar"

    fields =
      Enum.map(lines, fn line ->
        case Regex.run(~r/^        ([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$/, line,
               capture: :all_but_first
             ) do
          [field, value] ->
            assert field in ~w(ref status), "#{owner} has unknown verification field #{field}"

            case field do
              "ref" ->
                validate_canonical_ref!(value, owner)

              "status" ->
                assert value in ~w(pass fail pending),
                       "#{owner} has non-canonical status scalar"
            end

            field

          _ ->
            flunk("#{owner} has invalid verification line: #{line}")
        end
      end)

    assert_exact_fields!(["kind" | fields], ~w(kind ref status), "#{owner} verification item")
  end

  defp split_yaml_items!(lines, start_pattern, owner) do
    {items, current} =
      Enum.reduce(lines, {[], []}, fn line, {items, current} ->
        if String.match?(line, start_pattern) do
          {if(current == [], do: items, else: [current | items]), [line]}
        else
          assert current != [], "#{owner} content precedes its first item: #{line}"
          {items, current ++ [line]}
        end
      end)

    items = Enum.reverse(if(current == [], do: items, else: [current | items]))
    assert items != [], "#{owner} has no items"
    items
  end

  defp assert_exact_fields!(actual, expected, owner) do
    case duplicate_key(actual) do
      nil -> :ok
      field -> flunk("#{owner} has duplicate field #{field}")
    end

    assert Enum.sort(actual) == Enum.sort(expected), "#{owner} fields are not exact"
  end

  defp validate_root_scalar_shape!(key, value, path) when key in ["phase", "plan", "status"] do
    pattern =
      case key do
        "phase" -> ~r/^[A-Za-z0-9][A-Za-z0-9-]*$/
        "plan" -> ~r/^(?:0|[1-9]\d*)$/
        "status" -> ~r/^[a-z][a-z-]*$/
      end

    assert String.match?(value, pattern), "#{path} has non-canonical #{key} scalar"
  end

  defp validate_root_scalar_shape!("coverage", value, path) do
    assert value in ["", "[]"], "#{path} has non-canonical coverage scalar"
  end

  defp validate_root_scalar_shape!(_key, _value, _path), do: :ok

  defp validate_canonical_ref!(value, owner) do
    case Jason.decode(value) do
      {:ok, decoded} when is_binary(decoded) ->
        assert decoded != "" and String.trim(decoded) != "",
               "#{owner} has empty verification ref"

      _ ->
        flunk("#{owner} has non-canonical verification ref")
    end
  end

  defp validate_canonical_string!(value, owner) do
    case Jason.decode(value) do
      {:ok, decoded} when is_binary(decoded) ->
        assert decoded != "" and String.trim(decoded) != "", "#{owner} is empty"

      _ ->
        flunk("#{owner} is not a canonical double-quoted string")
    end
  end

  defp indent_each_line(value, indentation) do
    indentation <> String.replace(value, "\n", "\n" <> indentation)
  end

  defp coverage_entries(body) do
    yaml = frontmatter(body)
    [_, coverage_tail] = String.split(yaml, ~r/^coverage:[ \t]*/m, parts: 2)
    [head | lines] = String.split(coverage_tail, "\n")

    case String.trim(head) do
      "[]" ->
        %{}

      "" ->
        block =
          lines |> Enum.take_while(&(&1 == "" or String.match?(&1, ~r/^\s/))) |> Enum.join("\n")

        assert String.match?(block, ~r/^  - id:/m), "malformed coverage block"

        matches =
          Regex.scan(~r/^  - id:\s*([^\s]+)\n((?:(?!^  - id:)[\s\S])*)/m, block,
            capture: :all_but_first
          )

        case matches |> Enum.map(&hd/1) |> duplicate_key() do
          nil ->
            Map.new(matches, fn [id, entry] ->
              {id, normalize_entry("  - id: #{id}\n" <> entry)}
            end)

          id ->
            flunk("duplicate coverage id #{id}")
        end

      _ ->
        flunk("malformed coverage block")
    end
  end

  defp normalize_entry(entry) do
    entry
    |> String.replace(
      ~r/verification:\s*\[\{kind:\s*([^,]+),\s*ref:\s*("[^"]*"),\s*status:\s*([^}\]]+)\}\]/,
      "verification:\n      - kind: \\1\n        ref: \\2\n        status: \\3"
    )
    |> String.replace(
      ~r/- \{kind:\s*([^,]+),\s*ref:\s*("[^"]*"),\s*status:\s*([^}]+)\}/,
      "- kind: \\1\n        ref: \\2\n        status: \\3"
    )
    |> String.replace("\r\n", "\n")
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.join("\n")
    |> String.trim()
  end

  defp coverage_errors(entries, path) do
    Enum.flat_map(entries, fn {id, entry} ->
      statuses = Regex.scan(~r/^\s+status:\s*([^\s]+)\s*$/m, entry, capture: :all_but_first)
      refs = Regex.scan(~r/^\s+ref:\s*(.+?)\s*$/m, entry, capture: :all_but_first)

      []
      |> maybe_error(
        not Regex.match?(~r/^\s+human_judgment:\s*false\s*$/m, entry),
        "#{path}:#{id} is human"
      )
      |> maybe_error(refs == [], "#{path}:#{id} has no verification ref")
      |> maybe_error(
        statuses == [] or Enum.any?(statuses, &(&1 != ["pass"])),
        "#{path}:#{id} is not all-pass"
      )
    end)
  end

  defp maybe_error(errors, true, message), do: [message | errors]
  defp maybe_error(errors, false, _message), do: errors

  defp verification_digest(entries) do
    entries
    |> Enum.sort()
    |> Enum.map_join("\n", fn {id, entry} -> "#{id}\n#{entry}" end)
    |> digest()
  end

  defp coverage_at_tree(tree) do
    @plan46_numbers
    |> Enum.flat_map(fn number ->
      path = summary_path(number)
      {body, 0} = System.cmd("git", ["show", "#{tree}:#{path}"], stderr_to_stdout: true)

      for {id, entry} <- coverage_entries(body), into: %{} do
        {"198-#{number}:#{id}", entry}
      end
    end)
    |> Map.new()
  end

  defp changed_keys(left, right) do
    (Map.keys(left) ++ Map.keys(right))
    |> MapSet.new()
    |> Enum.filter(&(Map.get(left, &1) != Map.get(right, &1)))
    |> MapSet.new()
  end

  defp disclosure_errors(value), do: disclosure_errors(value, [])

  defp disclosure_errors(map, path) when is_map(map) do
    Enum.flat_map(map, fn {key, value} ->
      key_path = path ++ [key]

      key_error =
        if key =~ ~r/(authorization|credential|password|secret|token|cookie)/i,
          do: [key_path],
          else: []

      key_error ++ disclosure_errors(value, key_path)
    end)
  end

  defp disclosure_errors(list, path) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.flat_map(fn {value, index} -> disclosure_errors(value, path ++ [index]) end)
  end

  defp disclosure_errors(value, path) when is_binary(value) do
    unsafe =
      String.starts_with?(value, "/") or
        value =~ ~r/(authorization:|bearer\s+|password=|token=|cookie:)/i or
        value =~ ~r/^([A-Z][A-Z0-9_]+)=/

    if unsafe, do: [path], else: []
  end

  defp disclosure_errors(_value, _path), do: []
  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
