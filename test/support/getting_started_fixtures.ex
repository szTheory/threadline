defmodule Threadline.GettingStartedFixtures do
  @moduledoc false

  @repo_root File.cwd!()

  def extract!(relative_path, anchor) when is_binary(relative_path) and is_binary(anchor) do
    path = resolve_path(relative_path)
    lines = path |> File.read!() |> String.split("\n", trim: false)

    scan = %{
      path: path,
      anchor: anchor,
      start: "# doc: start: #{anchor}",
      end: "# doc: end: #{anchor}"
    }

    lines
    |> Enum.with_index()
    |> Enum.reduce({:before, 0, 0, []}, &scan_line(&1, &2, scan))
    |> finish!(path, anchor)
  end

  defp resolve_path(relative_path) do
    case Path.type(relative_path) do
      :absolute -> relative_path
      :relative -> Path.join(@repo_root, relative_path)
      :volumerelative -> Path.expand(relative_path)
    end
  end

  defp scan_line({line, index}, state, scan) do
    trimmed = String.trim(line)

    cond do
      trimmed == scan.start -> start_marker(state, scan, index + 1)
      trimmed == scan.end -> end_marker(state, scan, index + 1)
      true -> interior_line(state, line)
    end
  end

  defp start_marker({:before, start_count, end_count, interior}, _scan, _line_no),
    do: {:inside, start_count + 1, end_count, interior}

  defp start_marker({_status, _start_count, _end_count, _interior}, scan, line_no),
    do: raise_issue!(:duplicate_anchor, scan.path, scan.anchor, line_no)

  defp end_marker({:before, _start_count, _end_count, _interior}, scan, line_no),
    do: raise_issue!(:unbalanced_anchor, scan.path, scan.anchor, line_no)

  defp end_marker({:inside, start_count, end_count, interior}, _scan, _line_no),
    do: {:after, start_count, end_count + 1, interior}

  defp end_marker({:after, _start_count, _end_count, _interior}, scan, line_no),
    do: raise_issue!(:duplicate_anchor, scan.path, scan.anchor, line_no)

  defp interior_line({:inside, start_count, end_count, interior}, line),
    do: {:inside, start_count, end_count, interior ++ [line]}

  defp interior_line(state, _line), do: state

  defp finish!({status, start_count, end_count, interior}, path, anchor) do
    cond do
      start_count == 0 and end_count == 0 ->
        raise_issue!(:missing_anchor, path, anchor)

      start_count == 0 or end_count == 0 or status != :after ->
        raise_issue!(:unbalanced_anchor, path, anchor)

      start_count != 1 or end_count != 1 ->
        raise_issue!(:duplicate_anchor, path, anchor)

      true ->
        non_empty_snippet!(interior, path, anchor)
    end
  end

  defp non_empty_snippet!(interior, path, anchor) do
    snippet = interior |> trim_blank_edges() |> Enum.join("\n")

    if snippet == "" do
      raise_issue!(:empty_anchor, path, anchor)
    end

    snippet
  end

  defp trim_blank_edges(lines) do
    lines
    |> Enum.drop_while(&blank?/1)
    |> Enum.reverse()
    |> Enum.drop_while(&blank?/1)
    |> Enum.reverse()
  end

  defp blank?(line), do: String.trim(line) == ""

  defp raise_issue!(issue, path, anchor, line \\ nil) do
    detail =
      case issue do
        :missing_anchor -> "missing start/end markers"
        :duplicate_anchor -> "duplicate start/end markers"
        :unbalanced_anchor -> "unbalanced start/end markers"
        :empty_anchor -> "empty marked block"
      end

    location =
      case line do
        nil -> path
        line_no -> "#{path}:#{line_no}"
      end

    raise ArgumentError, "#{location} anchor #{inspect(anchor)}: #{detail}"
  end
end
