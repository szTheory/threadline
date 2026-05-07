defmodule Threadline.OperatorSurface.Exports.FilenameTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.Exports.Filename

  describe "for/2" do
    test "returns the canonical CSV filename with HYPHEN between hours and minutes" do
      dt = ~U[2026-05-06 12:00:00.000Z]
      assert Filename.for("csv", dt) == "threadline-changes-2026-05-06T12-00Z.csv"
    end

    test "returns the canonical wrapped-JSON filename" do
      dt = ~U[2026-05-06 12:00:00.000Z]
      assert Filename.for("json", dt) == "threadline-changes-2026-05-06T12-00Z.json"
    end

    test "returns the canonical NDJSON filename" do
      dt = ~U[2026-05-06 12:00:00.000Z]
      assert Filename.for("ndjson", dt) == "threadline-changes-2026-05-06T12-00Z.ndjson"
    end

    test "truncates seconds (minute granularity per EXPO-04)" do
      dt = ~U[2026-05-06 12:00:59.999Z]
      assert Filename.for("csv", dt) == "threadline-changes-2026-05-06T12-00Z.csv"
    end

    test "uses zero-padded month/day/hour/minute" do
      dt = ~U[2026-01-02 03:04:00.000Z]
      assert Filename.for("csv", dt) == "threadline-changes-2026-01-02T03-04Z.csv"
    end

    test "normalizes non-UTC inputs to UTC" do
      # 12:00 EST (utc_offset -18000s) == 17:00 in UTC.
      # Construct via struct literal because the stock UTC-only TZ database in
      # Threadline (no tzdata dep) cannot resolve "America/New_York" via
      # DateTime.from_naive/2; shifting an already-built non-UTC DateTime to
      # "Etc/UTC" does not require a DB lookup.
      non_utc = %DateTime{
        year: 2026,
        month: 5,
        day: 6,
        hour: 12,
        minute: 0,
        second: 0,
        microsecond: {0, 0},
        std_offset: 0,
        utc_offset: -18_000,
        time_zone: "America/New_York",
        zone_abbr: "EST"
      }

      assert Filename.for("csv", non_utc) == "threadline-changes-2026-05-06T17-00Z.csv"
    end

    test "raises FunctionClauseError for an unsupported format (programmer error, not user input)" do
      dt = ~U[2026-05-06 12:00:00.000Z]
      assert_raise FunctionClauseError, fn -> Filename.for("xml", dt) end
    end
  end
end
