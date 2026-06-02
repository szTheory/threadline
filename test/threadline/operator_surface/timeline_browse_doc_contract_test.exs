defmodule Threadline.OperatorSurface.TimelineBrowseDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @router_path "lib/threadline/operator_surface/router.ex"
  @lv_path "lib/threadline/operator_surface/live/timeline_live.ex"
  @query_path "lib/threadline/query.ex"
  @transaction_lv_path "lib/threadline/operator_surface/live/transaction_live.ex"
  @actor_lv_path "lib/threadline/operator_surface/live/actor_live.ex"

  # --- BROWSE-04: route literal ---

  test "router declares the timeline browse live route at the surface root" do
    router_src = File.read!(@router_path)

    assert String.contains?(router_src, ~s|live("/", TimelineLive, :index)|),
           "expected #{@router_path} to declare `live(\"/\", TimelineLive, :index)` inside the live_session :threadline scope"
  end

  # --- BROWSE-04: ARIA labels ---

  test "timeline live form exposes ARIA labels for every filter input" do
    live_src = File.read!(@lv_path)

    # Each label asserted individually so CI output pinpoints which label regressed
    assert String.contains?(live_src, ~s|aria-label="from"|),
           "missing ARIA label for filter input 'from'"

    assert String.contains?(live_src, ~s|aria-label="to"|),
           "missing ARIA label for filter input 'to'"

    assert String.contains?(live_src, ~s|aria-label="table"|),
           "missing ARIA label for filter input 'table'"

    assert String.contains?(live_src, ~s|aria-label="actor kind"|),
           "missing ARIA label for filter input 'actor kind'"

    assert String.contains?(live_src, ~s|aria-label="actor id"|),
           "missing ARIA label for filter input 'actor id'"

    assert String.contains?(live_src, ~s|aria-label="correlation id"|),
           "missing ARIA label for filter input 'correlation id'"
  end

  # --- BROWSE-04: filter-key parity (LOAD-BEARING) ---

  test "filter form key list matches Threadline.Query allowlist exactly (BROWSE-04 parity guarantee)" do
    live_src = File.read!(@lv_path)
    query_src = File.read!(@query_path)

    # Extract @allowed_timeline_filter_keys literal from query.ex source
    [_, allowlist_block] =
      Regex.run(~r/@allowed_timeline_filter_keys\s+~w\(([^)]+)\)a/, query_src) ||
        flunk("could not find @allowed_timeline_filter_keys in #{@query_path}")

    lib_keys =
      allowlist_block
      |> String.split()
      |> MapSet.new()
      # :repo is socket-injected, not URL-supplied
      |> MapSet.delete("repo")

    # Extract form filter keys from LV source
    form_keys =
      Regex.scan(~r/name="filter\[(\w+)\]"/, live_src)
      |> Enum.map(fn [_, k] -> k end)
      |> MapSet.new()

    # Collapse actor_kind + actor_id → actor_ref for parity
    form_keys_collapsed =
      form_keys
      |> MapSet.delete("actor_kind")
      |> MapSet.delete("actor_id")
      |> MapSet.put("actor_ref")

    assert form_keys_collapsed == lib_keys,
           """
           Filter form keys diverged from Threadline.Query allowlist.
           Form (after actor_kind+actor_id→actor_ref collapse): #{inspect(MapSet.to_list(form_keys_collapsed) |> Enum.sort())}
           Lib  (allowlist minus :repo):                        #{inspect(MapSet.to_list(lib_keys) |> Enum.sort())}
           Update either lib/threadline/query.ex (line with @allowed_timeline_filter_keys) OR the
           form's name="filter[…]" inputs so they agree.
           """

    # Belt + braces: assert the explicit six raw form keys are present
    for key <- ~w(from to table actor_kind actor_id correlation_id) do
      assert String.contains?(live_src, ~s|name="filter[#{key}]"|),
             "missing filter input name=\"filter[#{key}]\""
    end
  end

  # --- BROWSE-04: file-scope Code.ensure_loaded? gate ---

  test "timeline live module is wrapped in file-scope Code.ensure_loaded? gate" do
    live_src = File.read!(@lv_path)
    first_line = live_src |> String.split("\n") |> hd()

    assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do",
           "expected line 1 of #{@lv_path} to be the Sentry-idiom file-scope gate, got: #{inspect(first_line)}"
  end

  # --- BROWSE-04: native widgets (no custom date-pickers, no custom selects) ---

  test "timeline live uses native datetime-local input for from/to and native select for actor_kind" do
    live_src = File.read!(@lv_path)

    assert String.contains?(live_src, ~s|type="datetime-local"|),
           "expected LV to use native <input type=\"datetime-local\"> per D-09 / BROWSE-03 (no custom date pickers)"

    assert String.contains?(live_src, ~s|name="filter[actor_kind]"|) and
             String.contains?(live_src, "<select"),
           "expected LV to use native <select> for actor_kind per D-09 / BROWSE-03 (no custom dropdown widgets)"
  end

  # --- BROWSE-04: phx-change prohibition (D-04 / F-6 / Pitfall 3) ---

  test "timeline live form contains no phx-change attribute (D-04 explicit Apply only)" do
    live_src = File.read!(@lv_path)

    refute String.contains?(live_src, "phx-change="),
           """
           Filter form must use phx-submit only (per CONTEXT.md D-04 + RESEARCH Pitfall 3).
           Per-keystroke push_patch inflates browser history, breaking BROWSE-03 back/forward semantics.
           If you genuinely need a UI-only toggle (e.g. disable actor_id when actor_kind=anonymous),
           do it via render-time conditional `disabled={...}` — not via phx-change.
           """
  end

  # --- BROWSE-03: replace-style default-window canonicalization (no extra history entry) ---

  test "default-window canonicalization push_patches with replace: true (no extra history entry on bare /audit)" do
    live_src = File.read!(@lv_path)

    # The bare /audit → /audit?from=...&to=... patch must use replace: true so the
    # browser back button returns to the page before /audit, not to a bare /audit step.
    # LiveViewTest cannot observe the browser history stack directly; this source-level
    # assertion locks the LV contract that delivers correct history behavior.
    assert String.contains?(live_src, "replace: true"),
           """
           Expected #{@lv_path} default-window push_patch to include `replace: true`.
           Without it, opening /audit creates an extra history entry, breaking BROWSE-03's
           back-button contract (back from canonicalized /audit?from=...&to=... should
           return to the page BEFORE /audit, not to bare /audit).
           """
  end

  # --- D-02: Timeline back-link present on sibling LVs ---

  test "TransactionLive header contains Timeline back-link" do
    src = File.read!(@transaction_lv_path)

    assert String.contains?(src, ">Timeline</a>"),
           "expected #{@transaction_lv_path} to contain inline back-link literal 'Timeline'"
  end

  test "ActorLive header contains ← Timeline back-link" do
    src = File.read!(@actor_lv_path)

    assert String.contains?(src, "← Timeline"),
           "expected #{@actor_lv_path} to contain inline back-link literal '← Timeline' per CONTEXT.md D-02"
  end

  test "ActorLive not_found branch also contains ← Timeline back-link (D-02 escape hatch)" do
    src = File.read!(@actor_lv_path)

    occurrences = src |> String.split("← Timeline") |> length() |> Kernel.-(1)

    assert occurrences >= 2,
           "expected #{@actor_lv_path} to contain '← Timeline' at least twice (once in :not_found, once in actor-header per D-02), found #{occurrences}"
  end
end
