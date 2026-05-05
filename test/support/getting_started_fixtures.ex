defmodule Threadline.GettingStartedFixtures do
  @moduledoc false

  @repo_root File.cwd!()

  def extract!(relative_path, anchor) when is_binary(relative_path) and is_binary(anchor) do
    path =
      case Path.type(relative_path) do
        :absolute -> relative_path
        :relative -> Path.join(@repo_root, relative_path)
        :volumerelative -> Path.expand(relative_path)
      end

    lines = path |> File.read!() |> String.split("\n", trim: false)
    start_marker = "# doc: start: #{anchor}"
    end_marker = "# doc: end: #{anchor}"

    {status, start_count, end_count, interior} =
      Enum.reduce(Enum.with_index(lines), {:before, 0, 0, []}, fn {line, index},
                                                                   {status, start_count,
                                                                    end_count, interior} ->
        trimmed = String.trim(line)

        cond do
          trimmed == start_marker ->
            case status do
              :before -> {:inside, start_count + 1, end_count, interior}
              :inside -> raise_issue!(:duplicate_anchor, path, anchor, index + 1)
              :after -> raise_issue!(:duplicate_anchor, path, anchor, index + 1)
            end

          trimmed == end_marker ->
            case status do
              :before -> raise_issue!(:unbalanced_anchor, path, anchor, index + 1)
              :inside -> {:after, start_count, end_count + 1, interior}
              :after -> raise_issue!(:duplicate_anchor, path, anchor, index + 1)
            end

          status == :inside ->
            {:inside, start_count, end_count, interior ++ [line]}

          true ->
            {status, start_count, end_count, interior}
        end
      end)

    cond do
      start_count == 0 and end_count == 0 ->
        raise_issue!(:missing_anchor, path, anchor)

      start_count == 0 or end_count == 0 or status != :after ->
        raise_issue!(:unbalanced_anchor, path, anchor)

      start_count != 1 or end_count != 1 ->
        raise_issue!(:duplicate_anchor, path, anchor)

      true ->
        snippet = interior |> trim_blank_edges() |> Enum.join("\n")

        if snippet == "" do
          raise_issue!(:empty_anchor, path, anchor)
        end

        snippet
    end
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
