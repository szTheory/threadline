defmodule Threadline.TelemetryDocContractTest do
  @moduledoc """
  Doc-parity contract for `Threadline.Telemetry` (D-12.3, D-15, ROADMAP SC4).

  Both the `Threadline.Telemetry` moduledoc and `guides/telemetry.md` carry a
  hand-written markdown table of every telemetry event. Hand-written, not
  interpolated from `__events__/0`, so a doc author can lie — the only thing
  keeping the two tables honest against the code is this test: it parses both
  tables and asserts the parsed `{name, measurements, metadata, when}` row set
  equals the set built from `Threadline.Telemetry.__events__/0`.
  """

  use ExUnit.Case, async: true

  @guide_path "guides/telemetry.md"

  defp registry_rows do
    for event <- Threadline.Telemetry.__events__(), into: MapSet.new() do
      {event.name, MapSet.new(event.measurements), MapSet.new(event.metadata), event.when}
    end
  end

  defp moduledoc_text! do
    case Code.fetch_docs(Threadline.Telemetry) do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} ->
        moduledoc

      other ->
        flunk("expected Threadline.Telemetry to have a moduledoc, got: #{inspect(other)}")
    end
  end

  defp guide_text! do
    File.read!(@guide_path)
  end

  # Keeps only lines that open with the backticked event-name cell, e.g.
  # `| `[:threadline, :export, :completed]` | ... |`. The header row (`| Event
  # | ...`) and the separator row (`|---|...`) do not start with a backtick
  # right after the leading pipe, so neither matches.
  defp table_rows!(text) do
    text
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(~r/^\|\s*`/, &1))
    |> Enum.map(&parse_row!/1)
  end

  defp parse_row!(line) do
    cells =
      line
      |> String.trim()
      |> String.trim_leading("|")
      |> String.trim_trailing("|")
      |> String.split("|")
      |> Enum.map(&String.trim/1)

    [event_cell, measurements_cell, metadata_cell, when_cell] = cells

    name = event_cell |> backtick_text!() |> Code.string_to_quoted!()

    {name, backtick_keys(measurements_cell), backtick_keys(metadata_cell), when_cell}
  end

  defp backtick_text!(cell) do
    case Regex.run(~r/`([^`]*)`/, cell) do
      [_, inner] -> inner
      nil -> flunk("expected a backticked event-name cell, got: #{inspect(cell)}")
    end
  end

  defp backtick_keys(cell) do
    if String.trim(cell) == "—" do
      MapSet.new()
    else
      Regex.scan(~r/`([a-z_]+)`/, cell)
      |> Enum.map(fn [_, key] -> String.to_atom(key) end)
      |> MapSet.new()
    end
  end

  test "the moduledoc table is non-vacuous and matches the registry exactly" do
    rows = table_rows!(moduledoc_text!()) |> MapSet.new()
    expected = registry_rows()

    assert MapSet.size(rows) == length(Threadline.Telemetry.__events__()),
           "expected #{length(Threadline.Telemetry.__events__())} parsed moduledoc rows, " <>
             "got #{MapSet.size(rows)} — the table parser or the moduledoc table is vacuous"

    assert rows == expected,
           "Threadline.Telemetry moduledoc table does not match __events__/0.\n" <>
             "only in moduledoc: #{inspect(MapSet.difference(rows, expected))}\n" <>
             "only in registry: #{inspect(MapSet.difference(expected, rows))}"
  end

  test "the guide table is non-vacuous and matches the registry exactly" do
    rows = table_rows!(guide_text!()) |> MapSet.new()
    expected = registry_rows()

    assert MapSet.size(rows) == length(Threadline.Telemetry.__events__()),
           "expected #{length(Threadline.Telemetry.__events__())} parsed guide rows, " <>
             "got #{MapSet.size(rows)} — the table parser or #{@guide_path} is vacuous"

    assert rows == expected,
           "#{@guide_path} event table does not match __events__/0.\n" <>
             "only in guide: #{inspect(MapSet.difference(rows, expected))}\n" <>
             "only in registry: #{inspect(MapSet.difference(expected, rows))}"
  end
end
