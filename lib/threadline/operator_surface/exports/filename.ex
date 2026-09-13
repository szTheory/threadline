defmodule Threadline.OperatorSurface.Exports.Filename do
  @moduledoc false

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
