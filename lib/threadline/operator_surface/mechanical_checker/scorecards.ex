defmodule Threadline.OperatorSurface.MechanicalChecker.Scorecards do
  @moduledoc false

  alias Threadline.OperatorSurface.MechanicalChecker.Parsing

  # Loads and validates the committed Tier A scorecard corpus for the mechanical
  # checker. Every failure is returned as an actionable error tuple that names the
  # dataset, the expanded path, and the call that recovers from it; nothing here
  # raises on bad input.

  def fetch_required_input(opts, option) do
    case Keyword.fetch(opts, option) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_input, missing_input_details(option)}}
    end
  end

  defp missing_input_details(:scorecard_dir) do
    %{
      dataset: "mechanical scorecard corpus",
      option: :scorecard_dir,
      path: nil,
      repository_only: false,
      recovery:
        ~s|call MechanicalChecker.run(scorecard_dir: "/absolute/path/to/scorecards", mechanical_floors: floors)|
    }
  end

  defp missing_input_details(:mechanical_floors) do
    %{
      dataset: "mechanical floor map",
      option: :mechanical_floors,
      path: nil,
      repository_only: false,
      recovery:
        ~s|call MechanicalChecker.run(scorecard_dir: scorecard_dir, mechanical_floors: %{})|
    }
  end

  def load(dir) do
    expanded_dir = Path.expand(dir)

    with {:ok, paths} <- list_scorecard_paths(expanded_dir) do
      decode_scorecards(paths)
    end
  end

  defp list_scorecard_paths(dir) do
    case File.ls(dir) do
      {:ok, files} ->
        paths =
          files
          |> Enum.filter(&String.ends_with?(&1, ".json"))
          # The mechanical FLOOR governs the real operator surface — the Tier-A `/audit`
          # (`page.*`) cells and the committed refute/graded oracle. Two cell families are
          # deliberately out of its jurisdiction:
          #   • `route.*` — live-server, live-data captures, gitignored and not byte-stable;
          #     a local capture would otherwise redden the gate off a
          #     non-deterministic artifact (e.g. the deliberately-degraded ranking twin).
          #   • `story.*` — Storybook demo cells that exist to feed the LLM critic's aesthetic
          #     scoring, NOT the deterministic pixel-grid floor. They render isolated/unstyled
          #     demo primitives (e.g. demo-only tl-accordion/tl-toast with no style.ex rules)
          #     and demo scaffolding (bare description <p>) that were never meant to pass the
          #     token-grid checks — holding demos to the production floor is a category error.
          # CI over the real surface is unaffected (Tier-A cells still gate).
          |> Enum.reject(
            &(String.starts_with?(&1, "route.") or String.starts_with?(&1, "story."))
          )
          |> Enum.sort()
          |> Enum.map(&Path.join(dir, &1))

        if paths == [] do
          corpus_error(:empty_corpus, dir, :no_eligible_scorecards)
        else
          {:ok, paths}
        end

      {:error, :enoent} ->
        corpus_error(:missing_corpus, dir, :enoent)

      {:error, reason} ->
        corpus_error(:unreadable_corpus, dir, reason)
    end
  end

  defp decode_scorecards(paths) do
    Enum.reduce_while(paths, {:ok, []}, fn path, {:ok, scorecards} ->
      case decode_scorecard(path) do
        {:ok, scorecard} -> {:cont, {:ok, [scorecard | scorecards]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, scorecards} -> {:ok, Enum.reverse(scorecards)}
      error -> error
    end
  end

  defp decode_scorecard(path) do
    with {:ok, body} <- File.read(path),
         {:ok, scorecard} <- Jason.decode(body),
         :ok <- validate_scorecard(scorecard) do
      {:ok, scorecard}
    else
      {:error, %Jason.DecodeError{} = error} ->
        corpus_error(:malformed_scorecard, path, Exception.message(error))

      {:error, {:invalid_scorecard, reason}} ->
        corpus_error(:malformed_scorecard, path, reason)

      {:error, reason} ->
        corpus_error(:unreadable_corpus, path, reason)
    end
  end

  defp validate_scorecard(scorecard) when is_map(scorecard) do
    required = [
      {"cell_id", &is_binary/1, "a string"},
      {"ledger_id", &is_binary/1, "a string"},
      {"theme", &is_binary/1, "a string"},
      {"breakpoint", &is_number/1, "a number"},
      {"tokens", &is_map/1, "an object"},
      {"color_pairs", &list_of_maps?/1, "an array of objects"},
      {"element_styles", &list_of_maps?/1, "an array of objects"},
      {"applied_colors", &is_list/1, "an array"},
      {"mode_b", &is_map/1, "an object"}
    ]

    case Enum.find(required, fn {key, valid?, _expected} ->
           not valid?.(Map.get(scorecard, key))
         end) do
      nil ->
        validate_nested_scorecard(scorecard)

      {key, _valid?, expected} ->
        {:error, {:invalid_scorecard, "#{key} must be #{expected}"}}
    end
  end

  defp validate_scorecard(_scorecard) do
    {:error, {:invalid_scorecard, "top-level JSON value must be an object"}}
  end

  defp list_of_maps?(value), do: is_list(value) and Enum.all?(value, &is_map/1)

  defp validate_nested_scorecard(scorecard) do
    with :ok <-
           validate_color(get_in(scorecard, ["tokens", "--tl-color-bg"]), "tokens.--tl-color-bg"),
         :ok <- validate_non_empty_list(scorecard["color_pairs"], "color_pairs"),
         :ok <- validate_entries(scorecard["color_pairs"], &validate_color_pair/2),
         :ok <- validate_non_empty_list(scorecard["element_styles"], "element_styles"),
         :ok <- validate_entries(scorecard["element_styles"], &validate_element_style/2),
         :ok <- validate_non_empty_list(scorecard["applied_colors"], "applied_colors"),
         :ok <- validate_entries(scorecard["applied_colors"], &validate_applied_color/2) do
      validate_mode_b(scorecard["mode_b"])
    end
  end

  defp validate_non_empty_list([], field), do: invalid_scorecard("#{field} must not be empty")
  defp validate_non_empty_list(_values, _field), do: :ok

  defp validate_entries(values, validator) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {value, index}, :ok ->
      case validator.(value, index) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp validate_color_pair(pair, index) do
    prefix = "color_pairs[#{index}]"

    with :ok <- validate_non_empty_string(pair["selector"], "#{prefix}.selector"),
         :ok <- validate_color(pair["color"], "#{prefix}.color"),
         :ok <- validate_color(pair["background_color"], "#{prefix}.background_color"),
         :ok <- validate_px(pair["font_size"], "#{prefix}.font_size") do
      validate_font_weight(pair["font_weight"], "#{prefix}.font_weight")
    end
  end

  defp validate_element_style(style, index) do
    prefix = "element_styles[#{index}]"

    with :ok <- validate_non_empty_string(style["selector"], "#{prefix}.selector"),
         :ok <- validate_px_list(style["border_radius"], "#{prefix}.border_radius"),
         :ok <- validate_box_shadow(style["box_shadow"], "#{prefix}.box_shadow"),
         :ok <-
           validate_duration_list(style["transition_duration"], "#{prefix}.transition_duration"),
         :ok <- validate_px(style["font_size"], "#{prefix}.font_size"),
         :ok <- validate_px(style["margin_top"], "#{prefix}.margin_top"),
         :ok <- validate_px(style["margin_bottom"], "#{prefix}.margin_bottom"),
         :ok <- validate_px(style["padding_top"], "#{prefix}.padding_top") do
      validate_px(style["padding_bottom"], "#{prefix}.padding_bottom")
    end
  end

  defp validate_applied_color(color, index),
    do: validate_color(color, "applied_colors[#{index}]")

  defp validate_mode_b(mode_b) do
    ~w(type_size_count interactive_control_count card_nesting_depth scroll_cost)
    |> Enum.reduce_while(:ok, fn metric, :ok ->
      if is_number(mode_b[metric]) do
        {:cont, :ok}
      else
        {:halt, invalid_scorecard("mode_b.#{metric} must be a number")}
      end
    end)
  end

  defp validate_non_empty_string(value, _field) when is_binary(value) and value != "", do: :ok

  defp validate_non_empty_string(_value, field),
    do: invalid_scorecard("#{field} must be a non-empty string")

  defp validate_color(value, field) do
    case Parsing.parse_color(value) do
      {:ok, _rgba} -> :ok
      :error -> invalid_scorecard("#{field} must be a parseable CSS color")
    end
  end

  defp validate_px(value, field) when is_binary(value) do
    if Regex.match?(~r/^-?(?:\d+(?:\.\d+)?|\.\d+)px$/, value),
      do: :ok,
      else: invalid_scorecard("#{field} must be a CSS pixel value")
  end

  defp validate_px(_value, field), do: invalid_scorecard("#{field} must be a CSS pixel value")

  defp validate_px_list(value, field) when is_binary(value) do
    values = String.split(value)

    if values != [] and length(values) <= 4 and
         Enum.all?(values, &Regex.match?(~r/^-?(?:\d+(?:\.\d+)?|\.\d+)px$/, &1)),
       do: :ok,
       else: invalid_scorecard("#{field} must contain one to four CSS pixel values")
  end

  defp validate_px_list(_value, field),
    do: invalid_scorecard("#{field} must contain one to four CSS pixel values")

  defp validate_box_shadow("none", _field), do: :ok

  defp validate_box_shadow(value, field) when is_binary(value) do
    signatures = Parsing.shadow_signatures(value)

    if signatures != [] and Enum.all?(signatures, &(length(&1) == 3)),
      do: :ok,
      else: invalid_scorecard("#{field} must be none or a parseable CSS box-shadow")
  end

  defp validate_box_shadow(_value, field),
    do: invalid_scorecard("#{field} must be none or a parseable CSS box-shadow")

  defp validate_duration_list(value, field) when is_binary(value) do
    durations = value |> String.split(",") |> Enum.map(&String.trim/1)

    if durations != [] and
         Enum.all?(durations, &Regex.match?(~r/^-?(?:\d+(?:\.\d+)?|\.\d+)s$/, &1)),
       do: :ok,
       else: invalid_scorecard("#{field} must contain CSS durations in seconds")
  end

  defp validate_duration_list(_value, field),
    do: invalid_scorecard("#{field} must contain CSS durations in seconds")

  defp validate_font_weight(value, _field)
       when is_integer(value) and value >= 1 and value <= 1000,
       do: :ok

  defp validate_font_weight(value, field) when is_binary(value) do
    valid =
      value in ~w(normal bold bolder lighter) or
        match?({weight, ""} when weight >= 1 and weight <= 1000, Integer.parse(value))

    if valid, do: :ok, else: invalid_scorecard("#{field} must be a CSS font weight")
  end

  defp validate_font_weight(_value, field),
    do: invalid_scorecard("#{field} must be a CSS font weight")

  defp invalid_scorecard(reason), do: {:error, {:invalid_scorecard, reason}}

  defp corpus_error(tag, path, reason) do
    expanded_path = Path.expand(path)

    {:error,
     {tag,
      %{
        dataset: "mechanical scorecard corpus",
        path: expanded_path,
        reason: reason,
        repository_only: false,
        recovery:
          ~s|call MechanicalChecker.run(scorecard_dir: #{inspect(expanded_path)}, mechanical_floors: floors)|
      }}}
  end
end
