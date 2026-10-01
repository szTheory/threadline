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

  Invalid policies each carry exactly one tagged defect. This module starts
  with `:overlap` (a column named in both `exclude:` and `mask:`, rendered
  differently on each side about as often as not, biased toward the
  trim/case mismatches `normalize_columns/1` must still catch); later plans
  extend `invalid_policy_gen/0` with the remaining tags.
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

  defp placeholder_pair_gen do
    gen all(
          present? <- boolean(),
          value <- string(:alphanumeric, min_length: 1, max_length: 10)
        ) do
      if present?, do: {:present, value}, else: :absent
    end
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

  @doc """
  An invalid policy carrying exactly one tagged defect. Currently only
  `:overlap`: a column named in both `exclude:` and `mask:`, rendered
  independently (so it differs on each side about as often as it matches).
  """
  def invalid_policy_gen do
    overlap_gen()
  end

  defp overlap_gen do
    gen all(
          overlap_name <- member_of(@overlap_pool),
          exclude_extra_names <- names_subset_gen(@exclude_pool),
          mask_extra_names <- names_subset_gen(@mask_pool),
          overlap_on_exclude <- rendered_name_gen(overlap_name),
          overlap_on_mask <- rendered_name_gen(overlap_name),
          exclude_extra_entries <- entries_gen(exclude_extra_names),
          mask_extra_entries <- entries_gen(mask_extra_names),
          opts_shape <- opts_shape_gen()
        ) do
      exclude_entries = [overlap_on_exclude | exclude_extra_entries]
      mask_entries = [overlap_on_mask | mask_extra_entries]
      opts = build_opts(opts_shape, exclude_entries, mask_entries, :absent)
      {:invalid, :overlap, overlap_name, opts}
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
