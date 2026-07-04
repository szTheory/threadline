defmodule Threadline.CriticTrust.LedgerSplice do
  @moduledoc """
  Surgical, byte-stable replacement of *only* the `"critic_trust"` object in the
  design-system ledger JSON text.

  The ledger is ~14k lines. Re-encoding the whole document with `Jason.encode!`
  would reorder every key (Elixir maps are unordered) — a catastrophic diff and a
  violation of "never writes outside the critic_trust block". Instead we locate the
  `"critic_trust":` value, brace-match its object (string-literal aware), and splice
  a freshly rendered block over exactly those bytes. Everything else is preserved
  verbatim.

  `render_block/1` emits the block with a fixed lens order, fixed field order, and
  the ledger's exact 2-space nesting, so re-running with unchanged inputs produces
  byte-identical output (idempotent — empty `git diff`).
  """

  alias Threadline.CriticTrust.Measure

  @doc """
  Replace the `critic_trust` object in `ledger_text` with `block`.

  Returns `{:ok, new_text}` or `{:error, reason}` when the key/object cannot be located.
  """
  @spec replace(binary(), map()) :: {:ok, binary()} | {:error, atom()}
  def replace(ledger_text, block) when is_binary(ledger_text) and is_map(block) do
    key = ~s("critic_trust":)

    with {ks, kl} <- match(ledger_text, key),
         rest_start = ks + kl,
         rest = binary_part(ledger_text, rest_start, byte_size(ledger_text) - rest_start),
         {ob_rel, _} <- match(rest, "{"),
         open = rest_start + ob_rel,
         {:ok, close} <- find_close(ledger_text, open) do
      prefix = binary_part(ledger_text, 0, open)
      suffix = binary_part(ledger_text, close + 1, byte_size(ledger_text) - close - 1)
      {:ok, prefix <> render_block(block) <> suffix}
    else
      :nomatch -> {:error, :critic_trust_not_found}
      :error -> {:error, :unbalanced_braces}
    end
  end

  @doc """
  Render the `critic_trust` value object (`{ ... }`) as a JSON string with the
  ledger's exact indentation: lens keys at 4 spaces, fields at 6, block close at 2.
  """
  @spec render_block(map()) :: binary()
  def render_block(block) do
    lens_strs =
      Enum.map(Measure.lenses(), fn lens ->
        data = Map.fetch!(block, lens)

        field_strs =
          Enum.map(Measure.field_order(), fn f ->
            "      #{Jason.encode!(f)}: #{Jason.encode!(Map.fetch!(data, f))}"
          end)

        "    #{Jason.encode!(lens)}: {\n" <> Enum.join(field_strs, ",\n") <> "\n    }"
      end)

    "{\n" <> Enum.join(lens_strs, ",\n") <> "\n  }"
  end

  # :binary.match/2 wrapper returning {start, len} | :nomatch.
  defp match(bin, pat), do: :binary.match(bin, pat)

  # Find the byte index of the `}` matching the `{` at `open`. String-literal aware.
  defp find_close(text, open) do
    <<_::binary-size(open), rest::binary>> = text

    case scan(rest, 0, 0, false, false) do
      {:ok, rel} -> {:ok, open + rel}
      :error -> :error
    end
  end

  # Byte-wise scan. UTF-8 continuation bytes (>127) never collide with the ASCII
  # structural characters, so single-byte matching is safe.
  defp scan(<<>>, _idx, _depth, _in_str, _esc), do: :error

  defp scan(<<_c, tail::binary>>, idx, depth, true = _in_str, true = _esc),
    do: scan(tail, idx + 1, depth, true, false)

  defp scan(<<?\\, tail::binary>>, idx, depth, true = _in_str, false),
    do: scan(tail, idx + 1, depth, true, true)

  defp scan(<<?", tail::binary>>, idx, depth, true = _in_str, false),
    do: scan(tail, idx + 1, depth, false, false)

  defp scan(<<_c, tail::binary>>, idx, depth, true = _in_str, false),
    do: scan(tail, idx + 1, depth, true, false)

  defp scan(<<?", tail::binary>>, idx, depth, false, _esc),
    do: scan(tail, idx + 1, depth, true, false)

  defp scan(<<?{, tail::binary>>, idx, depth, false, _esc),
    do: scan(tail, idx + 1, depth + 1, false, false)

  defp scan(<<?}, tail::binary>>, idx, depth, false, _esc) do
    if depth == 1, do: {:ok, idx}, else: scan(tail, idx + 1, depth - 1, false, false)
  end

  defp scan(<<_c, tail::binary>>, idx, depth, false, _esc),
    do: scan(tail, idx + 1, depth, false, false)
end
