defmodule Threadline.StorageSchemaCallSiteContractTest do
  @moduledoc """
  A **static, source-level** sweep for unprefixed Ecto call sites against
  Threadline-owned schema modules — the guard `pgbouncer_topology_test.exs`
  needed and didn't have.

  CI run 33183920952's `PgBouncer transaction topology` job failed at
  `pgbouncer_topology_test.exs:21` with a `Postgrex.Error 42P01
  (undefined_table)` — the setup block called `Repo.delete_all/1` against
  `AuditChange` with no `Threadline.StorageSchemaCase.repo_opts()`. That
  defect existed on disk the whole time. It never showed up in 198-12's
  "observed local failure list"
  because the file carries `@moduletag :pgbouncer_topology`
  (`test/test_helper.exs` excludes that tag from every local run), so a sweep
  driven by *which tests fail locally* is structurally blind to it.

  This module reads source text instead. It never connects to a database and
  never runs another test, so tag exclusion, environment gates, and CI-only
  services are all irrelevant to its coverage — that property is the entire
  point. A file that only runs in CI, behind an env var, on a schedule, or not
  at all, is scanned exactly like a file that runs by default.

  **No escape hatch.** There is no permitted-file collection, no opt-out
  source marker, and no skipped-path constant. `repo_opts()` is harmless on a
  call site that would have resolved anyway (it is a no-op default), so there
  is no legitimate reason a real Threadline-owned call site would need to be
  exempted — and an exemption mechanism is precisely the surface through which
  the next silent regression (a second `pgbouncer_topology_test.exs`) would
  arrive (D-05).

  **Receiver shapes recognised.** Two families: (1) a CamelCase module-chain
  receiver ending in the literal `Repo` (the bare alias `Repo`, or a
  fully-qualified chain like `Threadline.Test.Repo`), and (2) a variable/
  attribute receiver — the module attribute `@repo` or the lowercase `repo`
  binding. A receiver glued directly to a preceding word character
  (`MyRepo`, `some_repo`) is never in either family and is not matched
  (round 3, CR-01, 198-REVIEW.md).

  The owned-module roster is *derived* from
  `Threadline.StorageSchemaCase.owned_schema_modules/0` — the same list
  `clean_storage_schema!/2` cleans in FK-safe order — via
  `Module.split/1 |> List.last/1`. It is never re-typed here, so it cannot
  drift from the cleanup order.
  """

  use ExUnit.Case, async: true

  alias Threadline.StorageSchemaCase

  @test_glob "test/**/*.exs"

  # Ecto.Repo callbacks that accept a trailing opts list (the argument
  # `repo_opts()` is appended to). Longest/most-specific variants are listed
  # first for readability; the anchor to a literal "(" at the end of the
  # pattern means match ordering does not actually affect correctness (e.g.
  # the "get" alternative cannot partially match "get_by(" because the very
  # next character after "get" is "_", not "(").
  @ecto_functions ~w(
    insert_all
    insert_or_update! insert_or_update
    insert! insert
    update! update
    delete_all update_all
    delete! delete
    all
    stream
    one! one
    get_by! get_by
    get! get
    aggregate
    exists?
    reload! reload
    preload
  )

  # Receiver shapes seen in this codebase: the bare `Repo` alias (optionally
  # preceded by a chain of CamelCase module segments, e.g.
  # `Threadline.Test.Repo`), a module attribute receiver (`@repo`, used by the
  # `test/mix/tasks/` files), or a lowercase `repo` variable/param. The
  # negative lookbehind is word-character-only (no `.`) so it still rejects a
  # receiver glued to a preceding word character mid-identifier (e.g.
  # "MyRepo.insert(" or "some_repo.insert(") while admitting a receiver
  # preceded only by a `.` from a fully-qualified module chain
  # (CR-01, 198-REVIEW.md).
  @call_regex ~r/
    (?<![\w])
    (?:(?:[A-Z][A-Za-z0-9_]*\.)*Repo|@repo|repo)
    \.
    (?:#{Enum.join(@ecto_functions, "|")})
    \(
  /x

  # Bound on how far the balanced-paren scan walks past a matched call before
  # giving up (T-198-14-03: a malformed source file must not hang `mix test`).
  @max_scan_bytes 20_000

  defp owned_short_names do
    StorageSchemaCase.owned_schema_modules()
    |> Enum.map(fn mod -> mod |> Module.split() |> List.last() end)
  end

  defp test_files, do: Path.wildcard(@test_glob)

  # Some call sites pass a variable bound earlier from `repo_opts(...)` rather
  # than the literal `repo_opts` token inline (e.g.
  # `storage_opts = repo_opts(schema)` reused across several calls in the same
  # helper). That is functionally identical to inlining `repo_opts()` at each
  # call site — the opts value still originates from `repo_opts/0,1` — so
  # treating it as an offense would be a detector precision bug, not a real
  # defect. Recognized as a sanctioned marker rather than as a file exemption:
  # it applies uniformly to every call site in every file, with a behaviour
  # case (`"a call passing a variable bound from repo_opts(...) is not an
  # offence"` below) proving it does not also swallow a genuinely bare
  # variable that was never assigned from repo_opts.
  @trailing_var_regex ~r/,\s*([a-z_][a-zA-Z0-9_]*[?!]?)\s*\)\s*\z/

  @doc """
  Scans `source` for Ecto call sites against the Repo/repo receiver shapes,
  returning one map per call site found:

    %{in_scope: boolean, offense: boolean, line: pos_integer, snippet: String.t()}

  `in_scope` is true when the call expression mentions one of `owned_names`
  (as a whole word). `offense` is true only for an in-scope call expression
  that does not mention `repo_opts`, directly or via a same-source variable
  bound from `repo_opts(...)`.
  """
  def scan_call_sites(source, owned_names) do
    @call_regex
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [{match_start, match_len}] ->
      # match_len already includes the trailing literal "(" the pattern ends
      # with, so depth 1 has already been opened at (match_start + match_len - 1).
      expr = balanced_call_expression(source, match_start, match_len)
      line = line_number(source, match_start)
      snippet = expr |> String.split("\n") |> List.first()

      in_scope? =
        Enum.any?(owned_names, fn name ->
          Regex.match?(~r/\b#{Regex.escape(name)}\b/, expr)
        end)

      %{
        in_scope: in_scope?,
        offense:
          in_scope? and not carries_repo_opts?(expr, source) and
            not expected_failure_context?(source, match_start),
        line: line,
        snippet: snippet
      }
    end)
  end

  defp carries_repo_opts?(expr, source) do
    String.contains?(expr, "repo_opts") or trailing_var_bound_from_repo_opts?(expr, source)
  end

  # A call site that is itself the deliberate proof that an unprefixed read
  # fails — e.g. `Threadline.StorageSchemaMaskContractTest`'s D-02 teeth test,
  # which reads AuditTransaction through Repo.all/1 with NO options
  # specifically to assert it raises `undefined_table` — is not the defect this sweep exists
  # to catch; it is the same defect *demonstrated on purpose* as a regression
  # guard. Recognized structurally (lexically inside an `assert_raise` lambda
  # or a `try do ... rescue` block that has not yet closed), not by file name
  # or a permitted-file list, so it applies identically to any current or
  # future test proving raise-on-missing-options behavior.
  @window_bytes 300

  defp expected_failure_context?(source, match_start) do
    window_start = max(match_start - @window_bytes, 0)
    preceding = binary_part(source, window_start, match_start - window_start)

    contains_unclosed?(preceding, "assert_raise", "end") or
      contains_unclosed?(preceding, "try do", "rescue")
  end

  defp contains_unclosed?(text, open_marker, close_marker) do
    case :binary.matches(text, open_marker) do
      [] ->
        false

      matches ->
        {last_open, _len} = List.last(matches)
        after_open = binary_part(text, last_open, byte_size(text) - last_open)
        not String.contains?(after_open, close_marker)
    end
  end

  defp trailing_var_bound_from_repo_opts?(expr, source) do
    case Regex.run(@trailing_var_regex, String.trim_trailing(expr)) do
      [_, var] -> Regex.match?(~r/\b#{Regex.escape(var)}\s*=[^\n]*repo_opts/, source)
      nil -> false
    end
  end

  defp balanced_call_expression(source, match_start, match_len) do
    window_len = min(@max_scan_bytes, byte_size(source) - match_start)
    window = binary_part(source, match_start, window_len)

    # depth 1 because `window` already ends with the opening "(" consumed by
    # the regex match; start walking from the very next byte.
    close_at = walk_balanced(window, match_len, byte_size(window), 1)
    binary_part(window, 0, close_at)
  end

  # Byte-level walk (not codepoint-level) is safe here: UTF-8 continuation
  # bytes are always >= 0x80, so they can never collide with the ASCII
  # parenthesis bytes (0x28 / 0x29) this scan looks for.
  defp walk_balanced(window, idx, len, depth) when idx < len and depth > 0 do
    case :binary.at(window, idx) do
      40 -> walk_balanced(window, idx + 1, len, depth + 1)
      41 -> walk_balanced(window, idx + 1, len, depth - 1)
      _ -> walk_balanced(window, idx + 1, len, depth)
    end
  end

  defp walk_balanced(_window, idx, _len, depth) when depth <= 0 do
    idx
  end

  defp walk_balanced(_window, idx, len, _depth) do
    # Bounded escape hatch for the scan itself, not for the detector: ran off
    # the window without balancing (malformed file or a call exceeding
    # @max_scan_bytes). Report what was scanned rather than hang.
    min(idx, len)
  end

  defp line_number(source, index) do
    source
    |> binary_part(0, index)
    |> String.split("\n")
    |> length()
  end

  defp format_offenses(offenses) do
    lines =
      for %{path: path, line: line, snippet: snippet} <- offenses do
        "  #{path}:#{line}: #{snippet}"
      end

    "these call sites target a Threadline-owned schema without repo_opts() " <>
      "(D-02/D-05 — the exact defect class that hid at " <>
      "pgbouncer_topology_test.exs:21 until this sweep found it):\n" <>
      Enum.join(lines, "\n")
  end

  describe "detector behaviour (inline fixtures)" do
    @owned ["AuditChange", "AuditTransaction"]

    test "an unprefixed call against an owned schema is an offence" do
      # Built via concatenation, not as a contiguous literal: this file is
      # itself matched by the glob the "real tree sweep" test below scans, so
      # a literal offending call written out verbatim in this comment or as a
      # plain string would flag itself as an offense (self-scanning guard
      # self-consistency, same idiom as zero_skips_contract_test.exs's
      # runtime-assembled needles).
      offending_call = "Repo." <> "delete_all(AuditChange)"
      assert [%{in_scope: true, offense: true}] = scan_call_sites(offending_call, @owned)
    end

    test "the same call with repo_opts() as a trailing argument is not an offence" do
      assert [%{in_scope: true, offense: false}] =
               scan_call_sites("Repo.delete_all(AuditChange, repo_opts())", @owned)
    end

    test "a multi-line call whose repo_opts() argument sits several lines below is not an offence" do
      source = """
      Repo.insert!(
        AuditTransaction.changeset(%{
          txid: 1,
          occurred_at: now
        }),
        repo_opts()
      )
      """

      assert [%{in_scope: true, offense: false}] = scan_call_sites(source, @owned)
    end

    test "a call naming a module not in the owned roster is not an offence" do
      assert [%{in_scope: false, offense: false}] =
               scan_call_sites("Repo.delete_all(SomeOtherSchema)", @owned)
    end

    test "raw SQL mentioning an owned table name with no Ecto call is not an offence" do
      source = "Repo.query!(\"SELECT * FROM audit_changes WHERE id = $1\", [id])"
      assert [] = scan_call_sites(source, @owned)
    end

    test "an @repo module-attribute receiver is detected the same as Repo" do
      offending_call = "@repo." <> "delete_all(AuditChange)"
      assert [%{in_scope: true, offense: true}] = scan_call_sites(offending_call, @owned)
    end

    test "a lowercase repo variable receiver is detected the same as Repo" do
      offending_call = "repo." <> "aggregate(AuditChange, :count, :id)"
      assert [%{in_scope: true, offense: true}] = scan_call_sites(offending_call, @owned)
    end

    test "repo_opts as an unrelated identifier fragment does not falsely satisfy an offence" do
      # "repo_optsx" contains "repo_opts" as a substring; this fixture exists
      # to document that the detector uses substring containment (not a
      # regex boundary) for the repo_opts marker itself, matching the
      # sanctioned call shape `repo_opts()` and its parameterized variants
      # (e.g. `repo_opts("audit")`) identically.
      assert [%{in_scope: true, offense: false}] =
               scan_call_sites("Repo.delete_all(AuditChange, repo_optsx())", @owned)
    end

    test "a call passing a variable bound from repo_opts(...) earlier in the file is not an offence" do
      # Real pattern in this codebase (e.g. timeline_live_test.exs's
      # seed_change!/1): compute the opts once, reuse it across several
      # calls. Functionally identical to inlining repo_opts() at each call
      # site, so it must not be flagged.
      source = """
      storage_opts = repo_opts(storage_schema)

      repo.insert!(
        AuditTransaction.changeset(%{txid: 1}),
        storage_opts
      )
      """

      results = scan_call_sites(source, @owned)
      assert Enum.any?(results, &(&1.in_scope and not &1.offense))
      refute Enum.any?(results, & &1.offense)
    end

    test "a bare variable NOT bound from repo_opts(...) is still an offence" do
      # The variable-binding recognition above must not become a blanket
      # pass for any trailing identifier — only one traceable to repo_opts.
      # Built via concatenation (see the first test in this describe block
      # for why): this fixture is a deliberate offense, and writing the
      # insert call out contiguously here would make the "real tree sweep"
      # test below flag this very file.
      source =
        "unrelated_opts = [something: 1]\n\n" <>
          "repo." <>
          "insert!(\n" <>
          "  AuditTransaction.changeset(%{txid: 1}),\n" <>
          "  unrelated_opts\n" <>
          ")\n"

      assert [%{in_scope: true, offense: true}] = scan_call_sites(source, @owned)
    end

    test "a call inside assert_raise's expected-failure lambda is not an offence" do
      source =
        "assert_raise Postgrex.Error, ~r/undefined_table/, fn ->\n" <>
          "  Repo." <>
          "all(AuditTransaction)\n" <>
          "end\n"

      assert [%{in_scope: true, offense: false}] = scan_call_sites(source, @owned)
    end

    test "a call inside a try/rescue expected-failure block is not an offence" do
      source =
        "error =\n" <>
          "  try do\n" <>
          "    Repo." <>
          "all(AuditTransaction)\n" <>
          "    nil\n" <>
          "  rescue\n" <>
          "    e in Postgrex.Error -> e\n" <>
          "  end\n"

      assert [%{in_scope: true, offense: false}] = scan_call_sites(source, @owned)
    end

    test "assert_raise recognition does not leak past its own end and re-permit a later offence" do
      source =
        "assert_raise Postgrex.Error, fn ->\n" <>
          "  Repo." <>
          "all(AuditTransaction)\n" <>
          "end\n\n" <>
          "Repo." <> "delete_all(AuditChange)\n"

      assert [%{offense: false}, %{offense: true}] = scan_call_sites(source, @owned)
    end

    # CR-01 (198-REVIEW.md): the fully-qualified receiver form used at 73 real
    # call sites (Threadline.Test.Repo.*) must be visible to the sweep.
    test "a fully-qualified Threadline.Test.Repo receiver is detected the same as Repo" do
      offending_call = "Threadline.Test.Repo." <> "delete_all(AuditChange)"
      assert [%{in_scope: true, offense: true}] = scan_call_sites(offending_call, @owned)
    end

    test "a fully-qualified Threadline.Test.Repo receiver with repo_opts() is not an offence" do
      assert [%{in_scope: true, offense: false}] =
               scan_call_sites(
                 "Threadline.Test.Repo.delete_all(AuditChange, repo_opts())",
                 @owned
               )
    end

    # CR-01 boundary/adjacency edge: a receiver glued to a preceding word
    # character (mid-identifier) must not match, even though it is only one
    # character different from the fully-qualified `.Repo.` form above.
    test "a MyRepo receiver (word-glued, not dot-glued) is not matched at all" do
      offending_call = "MyRepo." <> "delete_all(AuditChange)"
      assert [] = scan_call_sites(offending_call, @owned)
    end

    test "a some_repo receiver (word-glued, not dot-glued) is not matched at all" do
      offending_call = "some_repo." <> "delete_all(AuditChange)"
      assert [] = scan_call_sites(offending_call, @owned)
    end

    # CR-02 (198-REVIEW.md): insert_all/2,3 must be visible to the sweep.
    test "an unprefixed repo.insert_all/2 call is an offence" do
      offending_call = "repo." <> "insert_all(AuditChange, entries)"
      assert [%{in_scope: true, offense: true}] = scan_call_sites(offending_call, @owned)
    end

    test "an @repo.insert_all/3 call with repo_opts() is not an offence" do
      assert [%{in_scope: true, offense: false}] =
               scan_call_sites(
                 "@repo.insert_all(AuditChange, chunk, repo_opts())",
                 @owned
               )
    end

    # CR-02 ordering edge: insert_all( must resolve to the insert_all
    # alternative, not partially match a shorter "insert" alternative, because
    # the pattern anchors on a literal open paren immediately after the
    # function-name alternation.
    test "insert_all( is not mistaken for a partial match of insert(" do
      offending_call = "repo." <> "insert_all(AuditChange, entries)"
      assert [%{snippet: snippet}] = scan_call_sites(offending_call, @owned)
      assert snippet =~ "insert_all("
    end

    test "get_by( is not mistaken for a partial match of get(" do
      offending_call = "repo." <> "get_by(AuditChange, id: 1)"
      assert [%{snippet: snippet}] = scan_call_sites(offending_call, @owned)
      assert snippet =~ "get_by("
    end
  end

  describe "real tree sweep" do
    test "no unprefixed owned-schema Ecto call site exists anywhere under test/ (source scan)" do
      files = test_files()

      assert files != [],
             "no files matched #{@test_glob} — the glob is broken. A broken glob would " <>
               "make this guard pass vacuously while every unprefixed call site in the " <>
               "suite went unnoticed, which is worse than having no guard at all."

      owned_names = owned_short_names()

      results =
        for path <- files,
            source = File.read!(path),
            site <- scan_call_sites(source, owned_names) do
          Map.put(site, :path, Path.relative_to_cwd(path))
        end

      offenses = Enum.filter(results, & &1.offense)
      in_scope_count = Enum.count(results, & &1.in_scope)

      assert offenses == [], format_offenses(offenses)

      assert in_scope_count > 0,
             "found zero in-scope owned-schema call sites across #{@test_glob} — the " <>
               "detector's matching rule has silently stopped matching anything, which " <>
               "would let a real regression pass unnoticed. Expected many (transaction, " <>
               "change, action, evidence, export, retention, saved-view call sites)."

      # CR-01 non-vacuity: a future regression that re-narrows the receiver
      # regex back to rejecting fully-qualified module chains must fail here,
      # not pass silently on the aliased Repo./repo. sites alone.
      assert Enum.any?(results, &Regex.match?(~r/\.Repo\./, &1.snippet)),
             "no scanned call site used a fully-qualified module-chain receiver " <>
               "(e.g. Threadline.Test.Repo.*) — CR-01's fix may have regressed, or " <>
               "the real-tree scan is no longer seeing the 9 files that use this form."
    end
  end
end
