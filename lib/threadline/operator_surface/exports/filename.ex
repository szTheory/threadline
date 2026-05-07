defmodule Threadline.OperatorSurface.Exports.Filename do
  @moduledoc """
  Canonical filename for operator-surface exports.

  Format: `threadline-changes-YYYY-MM-DDTHH-MM-Z.{csv|json|ndjson}` — UTC,
  minute granularity per EXPO-04 literal example `threadline-changes-2026-05-06T12-00Z.csv`.

  The hyphen between hours and minutes (NOT a colon) is filesystem-friendly:
  Windows forbids colons in filenames.

  Filenames are ASCII by construction. RFC 5987 `Content-Disposition`
  `filename*=UTF-8''...` percent-encoding is a no-op for these inputs; the
  controller emits both `filename=` and `filename*=` per RFC 6266 §4.3
  belt-and-braces dual-emit (the strings are identical for ASCII filenames,
  but the dual-emit pattern is harmless and future-proofs against any future
  filename change that introduces non-ASCII characters).
  """

  @valid_formats ~w(csv json ndjson)

  @doc """
  Returns the canonical export filename for the given format and datetime.

  ## Examples

      iex> Threadline.OperatorSurface.Exports.Filename.for("csv", ~U[2026-05-06 12:00:00.000Z])
      "threadline-changes-2026-05-06T12-00Z.csv"

      iex> Threadline.OperatorSurface.Exports.Filename.for("json", ~U[2026-05-06 12:00:00.000Z])
      "threadline-changes-2026-05-06T12-00Z.json"

      iex> Threadline.OperatorSurface.Exports.Filename.for("ndjson", ~U[2026-05-06 12:00:00.000Z])
      "threadline-changes-2026-05-06T12-00Z.ndjson"
  """
  @spec for(String.t(), DateTime.t()) :: String.t()
  def for(format, %DateTime{} = dt) when format in @valid_formats do
    stamp = format_stamp(dt)
    "threadline-changes-#{stamp}.#{format}"
  end

  defp format_stamp(%DateTime{} = dt) do
    dt
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%Y-%m-%dT%H-%MZ")
  end
end
