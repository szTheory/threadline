defmodule Threadline.Test.RedactionPolicyGenerators do
  @moduledoc """
  StreamData generators for `Threadline.Capture.RedactionPolicy` options.

  Valid policies are built by construction, from two disjoint name pools (one
  for `exclude:`, one for `mask:`), so they can never accidentally overlap.
  Each column name is rendered as a plain string, a whitespace-padded string,
  a plain atom, or a whitespace-padded atom, biased toward exercising
  `normalize_columns/1`'s `to_string` + `trim` pipeline; blank entries ("" and
  whitespace-only strings) are interleaved around the real names. Options are
  rendered as a keyword list or a map, the map with atom or string keys.

  Invalid policies each carry exactly one tagged defect (see `defect_tags/0`
  for the full list): `:overlap` (a column named in both `exclude:` and
  `mask:`, rendered differently on each side about as often as not, biased
  toward the trim/case mismatches `normalize_columns/1` must still catch),
  `:empty_placeholder`, `:too_long` (201 graphemes, drawn from ASCII,
  multibyte, and combining-mark forms so every length-counting bug surfaces),
  `:control_char` (one byte 0..31 inserted into an otherwise-valid
  placeholder), `:non_list_columns` (`exclude:`/`mask:` given as an atom,
  binary, integer, or map instead of a list), and `:non_binary_placeholder`
  (`mask_placeholder:` given as an integer or a non-boolean atom — `false`
  and `nil` are valid defaults, not defects).

  Valid policies' placeholder ladder (drawn with `member_of`, independent of
  generator "size") covers the default (key absent), `false`, `nil`, exactly
  200 ASCII graphemes, exactly 200 multibyte graphemes, 200 graphemes each
  built from a base character plus a combining mark, a string containing
  DEL (127), and a string containing U+0085 — every rung the length and
  control-character checks must accept.
  """

  use ExUnitProperties

  # Disjoint by construction: no name below appears in more than one pool.
  @exclude_pool ~w(ssn ein tax_id passport_no credit_card bank_acct)
  @mask_pool ~w(email phone address dob ip_addr device_id)
  @overlap_pool ~w(flagged_col shared_field dup_attr legacy_key)

  @blank_forms ["", "   ", "\t", "\n "]

  @doc "One column name rendered as a plain/padded string or plain/padded atom."
  def rendered_name_gen(name) do
    gen all(
          padded <- padded_form_gen(name),
          as_atom? <- boolean()
        ) do
      if as_atom?, do: String.to_atom(padded), else: padded
    end
  end

  defp padded_form_gen(name) do
    member_of([
      name,
      " " <> name,
      name <> " ",
      " " <> name <> " ",
      "\t" <> name <> "\t"
    ])
  end

  defp blank_entry_gen, do: member_of(@blank_forms)

  defp entries_gen(names) do
    gen all(
          rendered <- names |> Enum.map(&rendered_name_gen/1) |> StreamData.fixed_list(),
          before_blanks <- list_of(blank_entry_gen(), max_length: 1),
          after_blanks <- list_of(blank_entry_gen(), max_length: 1)
        ) do
      before_blanks ++ rendered ++ after_blanks
    end
  end

  # A small subset of a fixed, small name pool. `uniq_list_of/2` hits
  # StreamData's "too many non-unique elements" guard on pools this small at
  # high generation sizes, so dedup after a plain bounded list instead.
  defp names_subset_gen(pool) do
    map(list_of(member_of(pool), max_length: 3), &Enum.uniq/1)
  end

  defp opts_shape_gen, do: member_of([:keyword, {:map, :atom_keys}, {:map, :string_keys}])

  # A single grapheme made of a base character plus a combining mark (U+0301,
  # combining acute accent) — `String.length/1` counts the pair as one
  # grapheme, exactly what RedactionPolicy's 200-grapheme limit counts.
  defp combining_mark_grapheme, do: "e" <> <<0x0301::utf8>>

  defp placeholder_pair_gen do
    frequency([
      {3, constant(:absent)},
      {1, constant({:present, false})},
      {1, constant({:present, nil})},
      {1, constant({:present, String.duplicate("a", 200)})},
      {1, constant({:present, String.duplicate("é", 200)})},
      {1, constant({:present, String.duplicate(combining_mark_grapheme(), 200)})},
      {1, constant({:present, "lead" <> <<127>> <> "tail"})},
      {1, constant({:present, "lead" <> <<0x85::utf8>> <> "tail"})},
      {2,
       gen all(value <- string(:alphanumeric, min_length: 1, max_length: 10)) do
         {:present, value}
       end}
    ])
  end

  defp build_opts(opts_shape, exclude_entries, mask_entries, placeholder) do
    pairs =
      [{:exclude, exclude_entries}, {:mask, mask_entries}] ++
        case placeholder do
          :absent -> []
          {:present, value} -> [{:mask_placeholder, value}]
        end

    case opts_shape do
      :keyword ->
        pairs

      {:map, :atom_keys} ->
        Map.new(pairs)

      {:map, :string_keys} ->
        pairs |> Enum.map(fn {k, v} -> {to_string(k), v} end) |> Map.new()
    end
  end

  @doc """
  A valid policy: disjoint exclude/mask column sets, each entry rendered in
  one of four forms with blanks interleaved, as a keyword list or a map with
  atom or string keys.
  """
  def valid_policy_gen do
    gen all(
          exclude_names <- names_subset_gen(@exclude_pool),
          mask_names <- names_subset_gen(@mask_pool),
          exclude_entries <- entries_gen(exclude_names),
          mask_entries <- entries_gen(mask_names),
          opts_shape <- opts_shape_gen(),
          placeholder <- placeholder_pair_gen()
        ) do
      {:valid, build_opts(opts_shape, exclude_entries, mask_entries, placeholder)}
    end
  end

  @doc "The full list of tags `invalid_policy_gen/0` can produce."
  def defect_tags do
    [
      :overlap,
      :empty_placeholder,
      :too_long,
      :control_char,
      :non_list_columns,
      :non_binary_placeholder
    ]
  end

  # A disjoint-by-construction valid exclude/mask pair, for every invalid
  # generator below that injects exactly one unrelated defect.
  defp disjoint_entries_gen do
    gen all(
          exclude_names <- names_subset_gen(@exclude_pool),
          mask_names <- names_subset_gen(@mask_pool),
          exclude_entries <- entries_gen(exclude_names),
          mask_entries <- entries_gen(mask_names),
          opts_shape <- opts_shape_gen()
        ) do
      {exclude_entries, mask_entries, opts_shape}
    end
  end

  @doc """
  An invalid policy carrying exactly one tagged defect. See the moduledoc
  for the full tag list and what each one injects.
  """
  def invalid_policy_gen do
    frequency([
      {1, overlap_gen()},
      {1, empty_placeholder_gen()},
      {1, too_long_gen()},
      {1, control_char_gen()},
      {1, non_list_columns_gen()},
      {1, non_binary_placeholder_gen()}
    ])
  end

  defp overlap_gen do
    gen all(
          overlap_name <- member_of(@overlap_pool),
          {exclude_extra_entries, mask_extra_entries, opts_shape} <- disjoint_entries_gen(),
          overlap_on_exclude <- rendered_name_gen(overlap_name),
          overlap_on_mask <- rendered_name_gen(overlap_name)
        ) do
      exclude_entries = [overlap_on_exclude | exclude_extra_entries]
      mask_entries = [overlap_on_mask | mask_extra_entries]
      opts = build_opts(opts_shape, exclude_entries, mask_entries, :absent)
      {:invalid, :overlap, overlap_name, opts}
    end
  end

  defp empty_placeholder_gen do
    gen all({exclude_entries, mask_entries, opts_shape} <- disjoint_entries_gen()) do
      opts = build_opts(opts_shape, exclude_entries, mask_entries, {:present, ""})
      {:invalid, :empty_placeholder, nil, opts}
    end
  end

  defp too_long_gen do
    gen all(
          too_long <-
            member_of([
              String.duplicate("a", 201),
              String.duplicate("é", 201),
              String.duplicate(combining_mark_grapheme(), 201)
            ]),
          {exclude_entries, mask_entries, opts_shape} <- disjoint_entries_gen()
        ) do
      opts = build_opts(opts_shape, exclude_entries, mask_entries, {:present, too_long})
      {:invalid, :too_long, nil, opts}
    end
  end

  defp control_char_gen do
    gen all(
          byte <- member_of(Enum.to_list(0..31)),
          position <- integer(0..10),
          {exclude_entries, mask_entries, opts_shape} <- disjoint_entries_gen()
        ) do
      base = "valid_placeholder_text"
      {pre, post} = String.split_at(base, position)
      placeholder = pre <> <<byte>> <> post
      opts = build_opts(opts_shape, exclude_entries, mask_entries, {:present, placeholder})
      {:invalid, :control_char, nil, opts}
    end
  end

  defp non_list_columns_gen do
    gen all(
          which <- member_of([:exclude, :mask]),
          bad_value <- member_of([:ssn, "ssn", 5, %{a: 1}]),
          {exclude_entries, mask_entries, opts_shape} <- disjoint_entries_gen()
        ) do
      {exclude_value, mask_value} =
        case which do
          :exclude -> {bad_value, mask_entries}
          :mask -> {exclude_entries, bad_value}
        end

      opts = build_opts(opts_shape, exclude_value, mask_value, :absent)
      {:invalid, :non_list_columns, which, opts}
    end
  end

  defp non_binary_placeholder_gen do
    gen all(
          bad_placeholder <- member_of([5, :not_a_bool_or_nil, 3.14]),
          {exclude_entries, mask_entries, opts_shape} <- disjoint_entries_gen()
        ) do
      opts = build_opts(opts_shape, exclude_entries, mask_entries, {:present, bad_placeholder})
      {:invalid, :non_binary_placeholder, nil, opts}
    end
  end

  @doc "Either a valid or an invalid (tagged) policy, biased toward valid."
  def policy_gen do
    frequency([
      {7, valid_policy_gen()},
      {3, invalid_policy_gen()}
    ])
  end
end
