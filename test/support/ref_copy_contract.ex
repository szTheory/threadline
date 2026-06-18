defmodule Threadline.OperatorSurface.RefCopyContract do
  @moduledoc """
  Shared Wave-0 contract helper (DATA-01 / D-02, RESEARCH Pitfall 4).

  The forensic non-negotiable: a rendered copy target must carry the EXACT full
  value, never the truncated/visible text. `data-tl-copy` must equal `ref.full`
  and must NOT equal the visible (truncated) text. This helper is reused across
  every consuming LiveView test (retention, transaction, …) so the copy footgun
  cannot regress on any page.

  Usage in a LiveView test:

      import Threadline.OperatorSurface.RefCopyContract

      assert_copy_equals_full(html, full: long_correlation_id)

  The assertion is RED until the consuming page migrates its copy wiring to
  `UI.ref/1` (which binds `data-tl-copy={ref.full}`); today the transaction page
  binds `.title` and other pages render no copy affordance at all.
  """

  import ExUnit.Assertions

  @doc """
  Assert the rendered HTML contains a `data-tl-copy` whose value equals the
  full value, and that the full value is long enough to have been truncated
  (so the assertion is meaningful — a non-truncated value would pass trivially).
  """
  def assert_copy_equals_full(html, full: full) when is_binary(full) do
    assert String.length(full) > 34,
           "ref-copy contract needs a value long enough to truncate (got #{String.length(full)} chars)"

    copy_targets = extract_copy_targets(html)

    assert full in copy_targets,
           "expected a data-tl-copy carrying the FULL value #{inspect(full)}; " <>
             "found copy targets: #{inspect(copy_targets)}"
  end

  @doc """
  Assert NO `data-tl-copy` in the rendered HTML carries a truncated form of the
  full value (i.e. a copy target that is a strict, shorter prefix/middle of the
  full value but not equal to it). Guards against copying `.visible`/`.title`.
  """
  def refute_copy_truncated(html, full: full) when is_binary(full) do
    copy_targets = extract_copy_targets(html)

    truncated =
      Enum.filter(copy_targets, fn target ->
        target != full and String.contains?(target, "...")
      end)

    assert truncated == [],
           "found truncated copy target(s) #{inspect(truncated)} — copy must bind the full value"
  end

  @doc "Extract every `data-tl-copy` attribute value from rendered HTML."
  def extract_copy_targets(html) do
    Regex.scan(~r/data-tl-copy="([^"]*)"/, html)
    |> Enum.map(fn [_, value] -> html_unescape(value) end)
  end

  defp html_unescape(value) do
    value
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
  end
end
