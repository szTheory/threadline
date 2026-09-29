defmodule Threadline.RepoHygieneGuardTest do
  @moduledoc """
  Offline behavior matrix for `bin/verify-repo-hygiene`, driven against
  runtime-built fixture repos through the REPO_HYGIENE_ROOT (and
  REPO_HYGIENE_ALLOWLIST) env seams. Every fixture path is assembled at
  runtime by string concatenation, so this file's own text never contains a
  matchable home-directory literal — a future scrub of the tracked tree
  must never need to touch this file.
  """
  use ExUnit.Case, async: true
  @moduletag :tmp_dir

  @script Path.expand("../../bin/verify-repo-hygiene", __DIR__)

  # --- Fixture helpers ---------------------------------------------------------

  defp fixture_repo!(tmp_dir, files) do
    root = Path.join(tmp_dir, "repo_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    for {rel_path, contents} <- files do
      full = Path.join(root, rel_path)
      File.mkdir_p!(Path.dirname(full))
      File.write!(full, contents)
    end

    {_, 0} = System.cmd("git", ["init", "-q"], cd: root)

    if files != %{} do
      {_, 0} = System.cmd("git", ["add", "--"] ++ Map.keys(files), cd: root)
    end

    root
  end

  defp write_allowlist!(tmp_dir, lines) do
    path = Path.join(tmp_dir, "allowlist_#{System.unique_integer([:positive])}.tsv")
    File.write!(path, Enum.join(lines, "\n") <> "\n")
    path
  end

  @header_only_allowlist [
    "# repo-hygiene allowlist"
  ]

  defp run_guard(root, opts) do
    allowlist = Keyword.get(opts, :allowlist)
    extra_env = Keyword.get(opts, :env, [])

    env =
      [{"REPO_HYGIENE_ROOT", root}, {"GIT_TERMINAL_PROMPT", "0"}] ++
        if(allowlist, do: [{"REPO_HYGIENE_ALLOWLIST", allowlist}], else: []) ++ extra_env

    System.cmd(@script, [], env: env, stderr_to_stdout: true)
  end

  # --- Runtime-built fake paths (never a literal in this file's source) ------

  @fake_macos_home "/" <> "Users" <> "/" <> "fixture-user"
  @fake_linux_home "/" <> "home" <> "/" <> "fixture-user"
  @fake_linux_home_runner "/" <> "home" <> "/" <> "runner"
  @fake_windows_home "C:" <> "\\" <> "Users" <> "\\" <> "fixture-user"
  @fake_tilde_home "~" <> "/" <> "fixture-cache"
  @fake_macos_temp "/" <> "var" <> "/" <> "folders" <> "/" <> "ab" <> "/"
  @fake_claude_dir "-" <> "Users" <> "-" <> "fixture-user" <> "-"
  @fake_claude_dir_single "-" <> "Users" <> "-" <> "fixture"
  @placeholder_claude_dir "-" <> "Users" <> "-" <> "<user>" <> "-" <> "<project>"
  @fake_json_home "\\" <> "/" <> "Users" <> "\\" <> "/" <> "fixture-user"
  @mid_word_form "shell" <> @fake_linux_home
  @placeholder_users "/" <> "Users" <> "/" <> "<user>" <> "/"
  @placeholder_home "/" <> "home" <> "/" <> "<user>" <> "/"
  @regex_source_form "/" <> "Users" <> "/[A-Za-z]"
  @mid_word_prose_form "shell" <> "/" <> "home" <> "/" <> "timeline" <> "/coverage"
  @fake_claude_dir_linux "-" <> "ho" <> "me" <> "-" <> "fixture-user" <> "-"
  @placeholder_claude_dir_linux "-" <> "home" <> "-" <> "<user>" <> "-" <> "<project>"
  @mid_word_claude_dir_linux "x" <> "self-" <> "home" <> "-page-title"
  @titlecase_claude_dir "Admin-" <> "Users" <> "-Guide"
  @space_boundary_claude_dir "x " <> "-" <> "Users" <> "-fixture"
  @slash_boundary_claude_dir "/foo/" <> "-" <> "Users" <> "-fixture/bar"
  @drive_form_claude_dir "C-" <> "-" <> "Users" <> "-fixture-proj"
  @start_of_line_claude_dir "-" <> "Users" <> "-fixture-startline"

  # --- Too-broad allowlist literals (D-13, R2-WR-01) ---------------------------

  @too_broad_root_slash "/"
  @too_broad_backslash "\\"
  @too_broad_tilde "~"
  @too_broad_tilde_slash "~" <> "/"
  @too_broad_var_folders "/" <> "var" <> "/" <> "folders"
  @too_broad_users "/" <> "Users"
  @too_broad_users_slash "/" <> "Users" <> "/"
  @too_broad_home "/" <> "home"
  @too_broad_home_slash "/" <> "home" <> "/"
  @too_broad_json_users "\\" <> "/" <> "Users" <> "\\" <> "/"
  @too_broad_dash_users "-" <> "Users" <> "-"

  # --- Tracer-carried coverage: single family, red vs green -------------------

  test "one macOS-home hit goes red end-to-end with a HIT file:line: token report", %{
    tmp_dir: tmp_dir
  } do
    root =
      fixture_repo!(tmp_dir, %{
        "notes.md" => "line one\n#{@fake_macos_home}/code\nline three\n"
      })

    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)

    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT notes.md:2:"
    assert output =~ @fake_macos_home
  end

  test "the same fixture without that line is clean", %{tmp_dir: tmp_dir} do
    root =
      fixture_repo!(tmp_dir, %{
        "notes.md" => "line one\nline two\nline three\n"
      })

    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)

    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "tracked text file(s) clean"
  end

  # --- All seven pattern families ---------------------------------------------

  test "family 2 (Linux home) produces exactly one HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "x #{@fake_linux_home}/y\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
    assert output =~ @fake_linux_home
  end

  test "family 3 (Windows home) produces exactly one HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "path #{@fake_windows_home}\\x\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 4 (home-relative tilde) produces exactly one HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "x #{@fake_tilde_home}/y\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 5 (macOS per-user temp root) produces exactly one HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "x #{@fake_macos_temp}\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 6 (Claude-encoded project dir) produces exactly one HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "x #{@fake_claude_dir}\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 6 (Claude-encoded project dir) hits a single-segment token at end of line", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"a.md" => "x " <> @fake_claude_dir_single <> "\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 6 hits a single-segment token followed by a slash", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "/foo/" <> @fake_claude_dir_single <> "/bar\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "a Claude-encoded placeholder form gives no HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => @placeholder_claude_dir <> "/memory\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "clean"
  end

  # --- Family 6 left-anchor (D-14, R2-WR-02) -----------------------------------

  test "a TitleCase kebab word with the users word between dashes gives no HIT", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"a.md" => @titlecase_claude_dir <> "\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "clean"
  end

  test "family 6 after a space is still a HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => @space_boundary_claude_dir <> "\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 6 after a slash is still a HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => @slash_boundary_claude_dir <> "\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 6 drive form (preceded by a letter and a dash) is still a HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => @drive_form_claude_dir <> "\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 6 at the start of a line is still a HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => @start_of_line_claude_dir <> "\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 7 (JSON-escaped home) produces exactly one HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "x #{@fake_json_home}\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "family 8 (Linux-encoded Claude project dir) produces exactly one HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "x #{@fake_claude_dir_linux}proj\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  test "a Linux-encoded placeholder form gives no HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => @placeholder_claude_dir_linux <> "\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "clean"
  end

  test "a mid-word Linux home-word dash form gives no HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => @mid_word_claude_dir_linux <> "\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "clean"
  end

  # --- Boundary and placeholder negatives --------------------------------------

  test "a mid-word form gives no HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "#{@mid_word_form}/y\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "clean"
  end

  test "placeholder and regex-source forms give no HIT", %{tmp_dir: tmp_dir} do
    root =
      fixture_repo!(tmp_dir, %{
        "a.md" =>
          "#{@placeholder_users}\n#{@placeholder_home}\n#{@regex_source_form}\n#{@mid_word_prose_form}\n"
      })

    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "clean"
  end

  test "two hits on one line are two HIT lines", %{tmp_dir: tmp_dir} do
    root =
      fixture_repo!(tmp_dir, %{
        "a.md" => "#{@fake_macos_home}/one #{@fake_macos_home}/two\n"
      })

    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert Enum.count(String.split(output, "\n"), &String.starts_with?(&1, "HIT a.md:1:")) == 2
  end

  test "a doubled-slash form is still a HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "/#{@fake_macos_home}/x\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT a.md:1:"
  end

  # --- Untracked / binary exclusion --------------------------------------------

  test "an untracked file with a fake path gives no HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"tracked.md" => "clean\n"})
    File.write!(Path.join(root, "untracked.md"), "#{@fake_macos_home}/x\n")
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "clean"
  end

  test "a tracked file with a NUL byte and a fake path gives no HIT", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"tracked.md" => "clean\n"})
    binary_path = Path.join(root, "binary.dat")
    File.write!(binary_path, "#{@fake_macos_home}/x\0binary\n")
    {_, 0} = System.cmd("git", ["add", "--", "binary.dat"], cd: root)
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "clean"
  end

  # --- Allowlist coverage: used, adjacency, scope ------------------------------

  test "an allowlist entry with reason >= 20 chars covers a hit and counts as used", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"a.md" => "#{@fake_tilde_home}/x\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        ".\t#{@fake_tilde_home}/\tRunner cache path used across CI jobs"
      ])

    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "1 allowlist entry used"
  end

  test "adjacency: literal covers a trailing slash and exact match but not a directly-adjacent byte",
       %{tmp_dir: tmp_dir} do
    root =
      fixture_repo!(tmp_dir, %{
        "a.md" => "#{@fake_linux_home_runner}/work\n#{@fake_linux_home_runner}x\n"
      })

    allowlist =
      write_allowlist!(tmp_dir, [
        ".\t#{@fake_linux_home_runner}\tGitHub-hosted runner account in CI log receipts"
      ])

    assert {output, 1} = run_guard(root, allowlist: allowlist)
    # covered: the runner-account path plus "/work" -> not printed as HIT
    refute output =~ "/work"
    # not covered: the runner-account literal directly followed by "x" -> stays a HIT
    assert output =~ "HIT a.md:2:"
  end

  test "a scoped entry covers a hit in its own directory but not a sibling directory", %{
    tmp_dir: tmp_dir
  } do
    root =
      fixture_repo!(tmp_dir, %{
        "docs/a.md" => "#{@fake_tilde_home}/x\n",
        "other/a.md" => "#{@fake_tilde_home}/x\n"
      })

    allowlist =
      write_allowlist!(tmp_dir, [
        "docs/\t#{@fake_tilde_home}\tDocs-only fixture cache path exemption"
      ])

    assert {output, 1} = run_guard(root, allowlist: allowlist)
    refute output =~ "HIT docs/a.md"
    assert output =~ "HIT other/a.md:1:"
  end

  test "an unused allowlist entry with no covered hit fails with UNUSED", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        ".\t#{@fake_tilde_home}\tRunner cache path that never appears in this fixture"
      ])

    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "UNUSED allowlist entry"
  end

  test "a .planning/ scoped entry is inert (not failed) when no .planning/ file is tracked", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        ".planning/\t#{@fake_tilde_home}\tGSD tool install path with no username segment"
      ])

    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "1 inert"
  end

  test "a non-.planning/ scoped entry whose scope matches nothing fails as UNUSED, not inert", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        "typo-dir/\t#{@fake_tilde_home}\tA typo'd scope that should never be silently inert"
      ])

    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "UNUSED allowlist entry"
  end

  test "two overlapping entries covering one hit are both used, order-independent", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"a.md" => "#{@fake_tilde_home}/x\n"})

    allowlist_a =
      write_allowlist!(tmp_dir, [
        ".\t#{@fake_tilde_home}\tBroad repo-wide cache path exemption for fixtures",
        "a.md\t#{@fake_tilde_home}/x\tFile-scoped exact cache path exemption fixture"
      ])

    allowlist_b =
      write_allowlist!(tmp_dir, [
        "a.md\t#{@fake_tilde_home}/x\tFile-scoped exact cache path exemption fixture",
        ".\t#{@fake_tilde_home}\tBroad repo-wide cache path exemption for fixtures"
      ])

    assert {output_a, 0} = run_guard(root, allowlist: allowlist_a)
    assert {output_b, 0} = run_guard(root, allowlist: allowlist_b)
    assert output_a =~ "2 allowlist entries used"
    assert output_b =~ "2 allowlist entries used"
  end

  # --- Allowlist structural validation (exit 2) --------------------------------

  test "a malformed allowlist line (two fields) exits 2", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})
    allowlist = write_allowlist!(tmp_dir, [".\tonly-two-fields"])
    assert {output, 2} = run_guard(root, allowlist: allowlist)
    assert output =~ "ALLOWLIST 1:"
  end

  test "a reason under 20 characters exits 2", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})
    allowlist = write_allowlist!(tmp_dir, [".\t#{@fake_tilde_home}\ttoo short"])
    assert {output, 2} = run_guard(root, allowlist: allowlist)
    assert output =~ "ALLOWLIST 1:"
  end

  test "a duplicate identical scope+literal line exits 2", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        ".\t#{@fake_tilde_home}\tFirst entry with a sufficiently long reason",
        ".\t#{@fake_tilde_home}\tDuplicate entry with a sufficiently long reason"
      ])

    assert {output, 2} = run_guard(root, allowlist: allowlist)
    assert output =~ "ALLOWLIST 2:"
  end

  test "a scope with a leading slash exits 2", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

    allowlist =
      write_allowlist!(tmp_dir, ["/docs/\t#{@fake_tilde_home}\tA scope that leads with a slash"])

    assert {output, 2} = run_guard(root, allowlist: allowlist)
    assert output =~ "ALLOWLIST 1:"
  end

  test "a scope with a glob character exits 2", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        "docs/*\t#{@fake_tilde_home}\tA scope containing a glob character"
      ])

    assert {output, 2} = run_guard(root, allowlist: allowlist)
    assert output =~ "ALLOWLIST 1:"
  end

  # --- literal_too_broad structural check (D-13, R2-WR-01) --------------------

  @too_broad_literals [
    {"a lone slash", @too_broad_root_slash},
    {"a lone backslash", @too_broad_backslash},
    {"a lone tilde", @too_broad_tilde},
    {"tilde-slash", @too_broad_tilde_slash},
    {"/var/folders (no trailing slash)", @too_broad_var_folders},
    {"/Users (no trailing slash)", @too_broad_users},
    {"/Users/ (trailing slash)", @too_broad_users_slash},
    {"/home (no trailing slash)", @too_broad_home},
    {"/home/ (trailing slash)", @too_broad_home_slash},
    {"JSON-escaped \\/Users\\/ ", @too_broad_json_users},
    {"-Users- (dash form)", @too_broad_dash_users}
  ]

  for {label, literal} <- @too_broad_literals do
    test "too-broad allowlist literal #{label} exits 2 with literal_too_broad", %{
      tmp_dir: tmp_dir
    } do
      root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

      allowlist =
        write_allowlist!(tmp_dir, [
          ".\t#{unquote(literal)}\tA literal too broad for this family fixture"
        ])

      assert {output, 2} = run_guard(root, allowlist: allowlist)
      assert output =~ "literal_too_broad"
    end
  end

  test "a scoped tool-install cache literal with a matching hit exits 0", %{tmp_dir: tmp_dir} do
    cache_literal = "~" <> "/" <> "." <> "cache"
    root = fixture_repo!(tmp_dir, %{"a.md" => "x " <> cache_literal <> "/x\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        ".\t#{cache_literal}/\tRunner cache path used across CI jobs, not too broad"
      ])

    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "1 allowlist entry used"
  end

  test "the runner home literal with a matching hit exits 0 with 1 allowlist entry used", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"a.md" => "x " <> @fake_linux_home_runner <> "/work\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        ".\t#{@fake_linux_home_runner}/\tGitHub-hosted runner account in CI log receipts"
      ])

    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "1 allowlist entry used"
  end

  # --- Newline pre-scan (D-15, R2-WR-03) ---------------------------------------

  test "a tracked path containing a newline exits 2 even with a phantom-scope allowlist entry",
       %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{})
    newline_name = "a" <> "\n" <> "b.md"
    File.write!(Path.join(root, newline_name), "x #{@fake_macos_home}/code\n")
    {_, 0} = System.cmd("git", ["add", "-A"], cd: root)

    allowlist =
      write_allowlist!(tmp_dir, [
        "b.md\t#{@fake_macos_home}\tA phantom-scope entry that must never cover this HIT"
      ])

    assert {output, 2} = run_guard(root, allowlist: allowlist)
    assert output =~ "newline"
  end

  test "an allowlist comment containing a fake home path exits 1 with ALLOWLIST", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        "# see #{@fake_macos_home}/notes for context"
      ])

    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "ALLOWLIST 1:"
  end

  test "an allowlist reason containing a fake home path exits 1 with ALLOWLIST", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        ".\t#{@fake_tilde_home}\tSee #{@fake_macos_home}/notes for the full reason text"
      ])

    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "ALLOWLIST 1:"
  end

  # --- Empty cases --------------------------------------------------------------

  test "empty allowlist (header only) with a clean tree exits 0", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {_output, 0} = run_guard(root, allowlist: allowlist)
  end

  test "empty allowlist with one hit exits 1", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "#{@fake_macos_home}/x\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {_output, 1} = run_guard(root, allowlist: allowlist)
  end

  test "a fixture repo with zero tracked files exits 0", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "0 tracked text file(s) clean"
  end

  # --- Summary label and missing git ------------------------------------------

  test ".planning/ absent label appears only when no .planning/ file is tracked", %{
    tmp_dir: tmp_dir
  } do
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)

    with_planning =
      fixture_repo!(tmp_dir, %{"a.md" => "clean\n", ".planning/notes.md" => "clean notes\n"})

    without_planning = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})

    assert {present_output, 0} = run_guard(with_planning, allowlist: allowlist)
    assert present_output =~ "inert"
    refute present_output =~ "(.planning/ absent)"

    assert {absent_output, 0} = run_guard(without_planning, allowlist: allowlist)
    assert absent_output =~ "(.planning/ absent)"
  end

  test "a PATH without git exits 2 naming the missing git", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    bin_dir = Path.join(tmp_dir, "nogit_bin")
    File.mkdir_p!(bin_dir)

    for tool <- ["bash", "dirname"] do
      source = System.find_executable(tool) || flunk("#{tool} not found on the test PATH")
      File.ln_s!(source, Path.join(bin_dir, tool))
    end

    if File.exists?(Path.join(bin_dir, "git")) do
      flunk("the git-free PATH fixture unexpectedly contains git; the test would be vacuous")
    end

    assert {output, 2} =
             System.cmd(@script, [],
               env: [
                 {"PATH", bin_dir},
                 {"REPO_HYGIENE_ROOT", root},
                 {"REPO_HYGIENE_ALLOWLIST", allowlist}
               ],
               stderr_to_stdout: true
             )

    assert output =~ "git not found on PATH"
  end

  test "an uncovered HIT prints the placeholder-convention hint; a clean run does not", %{
    tmp_dir: tmp_dir
  } do
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)

    dirty = fixture_repo!(tmp_dir, %{"a.md" => "x #{@fake_macos_home}/code\n"})
    assert {dirty_output, 1} = run_guard(dirty, allowlist: allowlist)
    assert dirty_output =~ "Writing about machine-local paths"

    clean = fixture_repo!(tmp_dir, %{"a.md" => "nothing interesting here\n"})
    assert {clean_output, 0} = run_guard(clean, allowlist: allowlist)
    refute clean_output =~ "Writing about machine-local paths"
  end

  # --- Ordering and CLI narrowing ------------------------------------------------

  test "HIT output is sorted by file then numeric line", %{tmp_dir: tmp_dir} do
    lines = for n <- 1..10, do: "line #{n}"
    content10 = Enum.join(lines, "\n") <> "\n#{@fake_macos_home}/at-line-11\n"

    root =
      fixture_repo!(tmp_dir, %{
        "a.md" => "#{@fake_macos_home}/line-1\n" <> Enum.join(lines, "\n"),
        "z.md" => content10
      })

    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)

    hit_lines =
      output
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "HIT "))

    files_and_lines =
      Enum.map(hit_lines, fn line ->
        [_, rest] = String.split(line, "HIT ", parts: 2)
        [file, lineno | _] = String.split(rest, ":")
        {file, String.to_integer(lineno)}
      end)

    assert files_and_lines == Enum.sort(files_and_lines)
  end

  test "a hit in a colon-containing tracked filename is reported with its full path", %{
    tmp_dir: tmp_dir
  } do
    root = fixture_repo!(tmp_dir, %{"notes:draft.md" => "x #{@fake_macos_home}/code\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)
    assert {output, 1} = run_guard(root, allowlist: allowlist)
    assert output =~ "HIT notes:draft.md:1:"
  end

  test "a file-scoped entry covers a hit in a colon-containing filename", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"notes:draft.md" => "x #{@fake_tilde_home}/y\n"})

    allowlist =
      write_allowlist!(tmp_dir, [
        "notes:draft.md\t#{@fake_tilde_home}/\tCache path documented in a colon-named file"
      ])

    assert {output, 0} = run_guard(root, allowlist: allowlist)
    assert output =~ "1 allowlist entry used"
  end

  test "an unknown CLI argument exits 2", %{tmp_dir: tmp_dir} do
    root = fixture_repo!(tmp_dir, %{"a.md" => "clean\n"})
    allowlist = write_allowlist!(tmp_dir, @header_only_allowlist)

    assert {_output, 2} =
             System.cmd(@script, ["docs/"],
               env: [{"REPO_HYGIENE_ROOT", root}, {"REPO_HYGIENE_ALLOWLIST", allowlist}],
               stderr_to_stdout: true
             )
  end

  # --- --self-test mode --------------------------------------------------------

  test "--self-test runs its ten cases and exits 0" do
    assert {output, 0} = System.cmd(@script, ["--self-test"], stderr_to_stdout: true)
    assert output =~ "self-test: ok (10 cases)"
  end

  test "the self-test case count matches the number of distinct case labels in the script" do
    script_text = File.read!(@script)
    labels = Regex.scan(~r/^    # \(([a-z]'?)\) /m, script_text) |> Enum.map(&Enum.at(&1, 1))
    assert Enum.uniq(labels) == labels, "duplicate self-test case labels: #{inspect(labels)}"
    assert length(labels) == 10, "expected 10 case labels, got #{inspect(labels)}"
  end

  # --- The real, seeded allowlist shape ----------------------------------------

  @real_allowlist_path Path.expand("../../.github/repo-hygiene-allowlist.tsv", __DIR__)

  defp real_allowlist_entries do
    @real_allowlist_path
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.map(&String.split(&1, "\t"))
  end

  test "every real allowlist entry has 3 tab-separated fields and a reason >= 20 chars" do
    entries = real_allowlist_entries()
    assert entries != []

    for fields <- entries do
      assert length(fields) == 3, "malformed allowlist line: #{inspect(fields)}"
      [_scope, _literal, reason] = fields
      assert String.length(reason) >= 20, "reason too short: #{inspect(fields)}"
    end
  end

  test "the real allowlist allowlists runner and cache paths (HYG-02)" do
    literals = Enum.map(real_allowlist_entries(), fn [_scope, literal, _reason] -> literal end)

    assert Enum.any?(literals, &String.starts_with?(&1, "/" <> "home" <> "/" <> "runner"))
    cache_prefix = "~" <> "/" <> ".cache"
    assert Enum.any?(literals, &String.starts_with?(&1, cache_prefix))
  end

  # Every home-directory prefix family the guard's matcher detects, built by
  # concatenation. Home-relative (tilde) forms stay permitted: the real
  # allowlist legitimately holds cache and tool-install forms that carry no
  # username. The runner account (exactly, or a subpath) is the one Linux
  # home the allowlist may hold.
  @users_word "Us" <> "ers"
  @home_word "ho" <> "me"
  @runner_home "/" <> @home_word <> "/" <> "runner"

  defp forbidden_home_literal?(literal) do
    windows_home = Regex.compile!("^[A-Za-z]:" <> "\\\\+" <> @users_word <> "\\\\+")

    prefixes = [
      "/" <> @users_word <> "/",
      "-" <> @users_word <> "-",
      "-" <> @home_word <> "-",
      "\\" <> "/" <> @users_word <> "\\" <> "/",
      "\\" <> "/" <> @home_word <> "\\" <> "/",
      "/" <> "var" <> "/" <> "folders" <> "/",
      "/" <> "private" <> "/" <> "var" <> "/" <> "folders" <> "/"
    ]

    linux_home? =
      String.starts_with?(literal, "/" <> @home_word <> "/") and
        not (literal == @runner_home or String.starts_with?(literal, @runner_home <> "/"))

    linux_home? or Regex.match?(windows_home, literal) or
      Enum.any?(prefixes, &String.starts_with?(literal, &1))
  end

  test "forbidden_home_literal?/1 flags one synthetic literal per family and passes runner/cache literals" do
    user = "fix" <> "ture"

    flagged = [
      "/" <> @users_word <> "/" <> user,
      "/" <> @home_word <> "/" <> user,
      "C:" <> "\\" <> @users_word <> "\\" <> user,
      "d:" <> "\\\\" <> @users_word <> "\\\\" <> user,
      "-" <> @users_word <> "-" <> user,
      "-" <> @home_word <> "-" <> user,
      "\\" <> "/" <> @users_word <> "\\" <> "/" <> user,
      "\\" <> "/" <> @home_word <> "\\" <> "/" <> user,
      "/" <> "var" <> "/" <> "folders" <> "/" <> "ab" <> "/",
      "/" <> "private" <> "/" <> "var" <> "/" <> "folders" <> "/" <> "ab" <> "/"
    ]

    for literal <- flagged do
      assert forbidden_home_literal?(literal), "expected a forbidden home literal: #{literal}"
    end

    passed = [
      @runner_home,
      @runner_home <> "/" <> "work",
      "~" <> "/" <> ".cache",
      "~" <> "/" <> ".claude" <> "/" <> "skills" <> "/"
    ]

    for literal <- passed do
      refute forbidden_home_literal?(literal), "expected a permitted literal: #{literal}"
    end
  end

  test "the real allowlist never allowlists a person's home directory" do
    literals = Enum.map(real_allowlist_entries(), fn [_scope, literal, _reason] -> literal end)

    for literal <- literals do
      refute forbidden_home_literal?(literal),
             "allowlist entry allowlists a person's home directory: #{literal}"
    end
  end
end
