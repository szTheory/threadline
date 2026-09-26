defmodule Threadline.Test.NamingGenerators do
  @moduledoc """
  StreamData generators for host table pairs, biased toward the pairs that
  break naive naming: `_`-joined suffixes (public.a_b vs a.b), tables that
  differ only in case, and long tables sharing a 36-byte prefix.
  """

  use ExUnitProperties

  # Generated names only ever use ASCII, so byte and character lengths agree.
  @first Enum.concat([?a..?z, ?A..?Z, [?_]])
  @rest Enum.concat([?a..?z, ?A..?Z, ?0..?9, [?_]])
  @hex Enum.concat(?0..?9, ?a..?f)

  def ident(max) do
    gen all(head <- member_of(@first), tail <- string(@rest, max_length: max - 1)) do
      <<head>> <> tail
    end
  end

  def fixed_ident(bytes) do
    gen all(head <- member_of(@first), tail <- string(@rest, length: bytes - 1)) do
      <<head>> <> tail
    end
  end

  # A 36-byte prefix: the longest public table that keeps its legacy function name.
  defp prefix36, do: fixed_ident(36)

  defp tail_gen, do: string(@rest, min_length: 1, max_length: 20)

  def public(table), do: %{schema: "public", table: table}

  def pair_gen do
    frequency([
      {4, map(ident(63), &public/1)},
      {3, gen(all(schema <- ident(30), table <- ident(40), do: %{schema: schema, table: table}))},
      {2, gen(all(prefix <- prefix36(), tail <- tail_gen(), do: public(prefix <> tail)))},
      {1,
       gen all(stem <- ident(30), hex <- string(@hex, length: 12)) do
         public(stem <> "_" <> hex)
       end}
    ])
  end

  def pair_of_pairs_gen do
    frequency([
      # public.<s>_<t> vs <s>.<t>: the same legacy suffix.
      {3,
       gen all(schema <- ident(20), table <- ident(20)) do
         {public(schema <> "_" <> table), %{schema: schema, table: table}}
       end},
      # Tables that differ only in case.
      {2, gen(all(table <- ident(40), do: {public(table), public(String.upcase(table))}))},
      {1, gen(all(table <- ident(40), do: {public(table), public(swapcase(table))}))},
      # Long tables sharing a 36-byte prefix, so their readable stems agree.
      {3,
       gen all(prefix <- prefix36(), t1 <- tail_gen(), t2 <- tail_gen()) do
         {public(prefix <> t1), public(prefix <> t2)}
       end},
      {1,
       gen all(schema <- ident(20), prefix <- prefix36(), t1 <- tail_gen(), t2 <- tail_gen()) do
         {%{schema: schema, table: prefix <> t1}, %{schema: schema, table: prefix <> t2}}
       end},
      # One table in two schemas, including public.
      {2,
       gen all(schema <- ident(30), table <- ident(40)) do
         {public(table), %{schema: schema, table: table}}
       end},
      {1,
       gen all(prefix <- prefix36(), s1 <- tail_gen(), s2 <- tail_gen(), table <- ident(20)) do
         {%{schema: prefix <> s1, table: table}, %{schema: prefix <> s2, table: table}}
       end},
      {2, tuple({pair_gen(), pair_gen()})}
    ])
  end

  defp swapcase(string) do
    for <<char <- string>>, into: "" do
      cond do
        char in ?a..?z -> <<char - 32>>
        char in ?A..?Z -> <<char + 32>>
        true -> <<char>>
      end
    end
  end
end
