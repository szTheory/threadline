defmodule Threadline.Mix.MigrationVersion do
  @moduledoc false

  # Ecto names a migration by the integer before the first "_" in its file name
  # and refuses to run a directory where two files share that integer. A task
  # that writes several migrations in one second cannot use the wall clock
  # alone, so the versions here start after the newest migration already in
  # the directory (or at the current second, whichever is later) and step one
  # second at a time.

  @format "%Y%m%d%H%M%S"

  @doc false
  @spec next(Path.t(), non_neg_integer(), NaiveDateTime.t()) :: [String.t()]
  def next(path, count, now \\ NaiveDateTime.utc_now())

  def next(_path, 0, _now), do: []

  def next(path, count, now) when is_integer(count) and count > 0 do
    now = NaiveDateTime.truncate(now, :second)

    case path |> existing_versions() |> Enum.max(fn -> nil end) do
      nil -> from_datetime(now, count)
      max -> from_existing(max, now, count)
    end
  end

  # A timestamp-shaped maximum is stepped as a datetime, so the seconds, days
  # and years carry correctly (23:59:59 on Dec 31 is followed by 00:00:00 on
  # Jan 1). Any other numbering scheme falls back to plain integers above the
  # maximum, which still keeps every new version unique and in order.
  defp from_existing(max, now, count) do
    case to_datetime(max) do
      {:ok, datetime} ->
        datetime
        |> NaiveDateTime.add(1, :second)
        |> later(now)
        |> from_datetime(count)

      :error ->
        if max + 1 > to_integer(now) do
          Enum.map(0..(count - 1)//1, &Integer.to_string(max + 1 + &1))
        else
          from_datetime(now, count)
        end
    end
  end

  defp from_datetime(base, count) do
    Enum.map(0..(count - 1)//1, fn offset ->
      base
      |> NaiveDateTime.add(offset, :second)
      |> Calendar.strftime(@format)
    end)
  end

  # Mirrors how Ecto discovers migrations: every .exs file under the
  # directory, including subdirectories, whose name starts with an integer
  # followed by "_".
  defp existing_versions(path) do
    [path, "**", "*.exs"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.flat_map(fn file ->
      case Integer.parse(Path.basename(file, ".exs")) do
        {version, "_" <> _} -> [version]
        _ -> []
      end
    end)
  end

  defp to_datetime(version) do
    with <<y::binary-4, mo::binary-2, d::binary-2, h::binary-2, mi::binary-2, s::binary-2>> <-
           Integer.to_string(version),
         {:ok, datetime} <-
           NaiveDateTime.new(int(y), int(mo), int(d), int(h), int(mi), int(s)) do
      {:ok, datetime}
    else
      _ -> :error
    end
  end

  defp int(digits), do: String.to_integer(digits)

  defp later(a, b), do: if(NaiveDateTime.compare(a, b) == :lt, do: b, else: a)

  defp to_integer(datetime), do: datetime |> Calendar.strftime(@format) |> String.to_integer()
end
