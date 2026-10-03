defmodule Threadline.Test.StrictRFC4180 do
  @moduledoc """
  A hand-written, dependency-free RFC 4180 decoder used only in tests.

  Deliberately independent of the CSV-dumping library `Threadline.Export`
  encodes with: decoding CSV with the same library that encoded it would
  hide any quirk the encoder has, since the decoder would share the bug.
  This module reads only RFC 4180 itself.

  ## Accepts

  - a quoted field containing `""` as an escaped literal quote
  - CR and/or LF as plain content inside a quoted field (not a record break)
  - a tab character, or any non-ASCII byte sequence, in any field

  ## Rejects

  Raises `ArgumentError` naming the byte offset for:

  - a bare CR or bare LF inside an unquoted field
  - a stray `"` inside an unquoted field
  - any byte following a quoted field's closing quote other than `,` or the
    record-terminating `\\r\\n`
  - an unterminated quoted field
  - a final record that is not itself terminated by `\\r\\n` (every record,
    including the last one in the document, must end in CRLF)
  """

  @doc "Decodes a full RFC 4180 document into a list of records (each a list of fields)."
  def decode!(binary) when is_binary(binary) do
    parse_records(binary, binary, [])
  end

  defp parse_records(<<>>, _orig, acc), do: Enum.reverse(acc)

  defp parse_records(rest, orig, acc) do
    {fields, rest2} = parse_record(rest, orig, [])
    parse_records(rest2, orig, [fields | acc])
  end

  defp parse_record(bin, orig, fields) do
    {field, rest} = parse_field(bin, orig)

    case rest do
      <<",", rest2::binary>> -> parse_record(rest2, orig, [field | fields])
      <<"\r\n", rest2::binary>> -> {Enum.reverse([field | fields]), rest2}
      _ -> raise_at(orig, rest, "expected ',' or CRLF after field")
    end
  end

  defp parse_field(<<"\"", rest::binary>>, orig), do: parse_quoted(rest, orig, [])
  defp parse_field(bin, orig), do: parse_unquoted(bin, orig, [])

  defp parse_quoted(<<"\"\"", rest::binary>>, orig, acc),
    do: parse_quoted(rest, orig, [<<"\"">> | acc])

  defp parse_quoted(<<"\"", rest::binary>>, _orig, acc),
    do: {IO.iodata_to_binary(Enum.reverse(acc)), rest}

  defp parse_quoted(<<>>, orig, _acc), do: raise_at(orig, <<>>, "unterminated quoted field")

  defp parse_quoted(<<c::utf8, rest::binary>>, orig, acc),
    do: parse_quoted(rest, orig, [<<c::utf8>> | acc])

  defp parse_unquoted(<<",", _::binary>> = bin, _orig, acc),
    do: {IO.iodata_to_binary(Enum.reverse(acc)), bin}

  defp parse_unquoted(<<"\r\n", _::binary>> = bin, _orig, acc),
    do: {IO.iodata_to_binary(Enum.reverse(acc)), bin}

  defp parse_unquoted(<<"\"", _::binary>> = bin, orig, _acc),
    do: raise_at(orig, bin, "stray quote in unquoted field")

  defp parse_unquoted(<<"\r", _::binary>> = bin, orig, _acc),
    do: raise_at(orig, bin, "bare CR in unquoted field")

  defp parse_unquoted(<<"\n", _::binary>> = bin, orig, _acc),
    do: raise_at(orig, bin, "bare LF in unquoted field")

  defp parse_unquoted(<<>>, orig, _acc),
    do: raise_at(orig, <<>>, "final record without CRLF terminator")

  defp parse_unquoted(<<c::utf8, rest::binary>>, orig, acc),
    do: parse_unquoted(rest, orig, [<<c::utf8>> | acc])

  defp raise_at(orig, rest_at_error, msg) do
    offset = byte_size(orig) - byte_size(rest_at_error)
    raise ArgumentError, "#{msg} at byte offset #{offset}"
  end
end
