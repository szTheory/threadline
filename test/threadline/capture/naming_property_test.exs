defmodule Threadline.Capture.NamingPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Threadline.Test.NamingGenerators

  alias Threadline.Capture.Naming

  @identifier ~r/^[A-Za-z_][A-Za-z0-9_]*$/
  @module ~r/^[A-Z][A-Za-z0-9_]*$/

  # Trigger names are unique per table, not globally (public.a_b and a.b share
  # one), so no property here claims trigger-name injectivity. Function-name
  # injectivity is claimed only for pairs whose hash12 values differ.

  property "every derived name is a valid identifier of at most 63 bytes" do
    check all(pair <- pair_gen()) do
      for name <- [
            Naming.trigger_name(pair),
            Naming.function_name(pair),
            Naming.legacy_function_name(pair)
          ] do
        assert byte_size(name) <= 63
        assert name =~ @identifier
      end
    end
  end

  property "migration names and modules are valid identifiers of at most 63 bytes" do
    check all(
            pairs <- list_of(pair_gen(), min_length: 1, max_length: 60),
            ordinal <- integer(1..20)
          ) do
      {name, module} = Naming.migration_name(pairs, ordinal)

      assert byte_size(name) <= 63
      assert name =~ @identifier
      assert byte_size(module) <= 63
      assert module =~ @module
    end
  end

  property "names are deterministic and a bare public table equals public.table" do
    check all(pair <- pair_gen(), table <- ident(63)) do
      for fun <- [:trigger_name, :function_name, :legacy_function_name, :suffix, :qualified] do
        assert apply(Naming, fun, [pair]) == apply(Naming, fun, [pair])
        assert apply(Naming, fun, [table]) == apply(Naming, fun, ["public." <> table])
      end

      assert Naming.migration_name([pair], 3) == Naming.migration_name([pair], 3)
    end
  end

  property "distinct tables with distinct hash12 get distinct function names" do
    check all(
            {p1, p2} <- pair_of_pairs_gen(),
            p1 != p2,
            Naming.hash12(Naming.qualified(p1)) != Naming.hash12(Naming.qualified(p2))
          ) do
      refute Naming.function_name(p1) == Naming.function_name(p2)
    end
  end

  property "the trigger name is the legacy name cut to 63 bytes" do
    check all(pair <- pair_gen()) do
      legacy = "threadline_audit_" <> Naming.suffix(pair)
      name = Naming.trigger_name(pair)

      assert name == binary_part(legacy, 0, min(63, byte_size(legacy)))
      assert String.starts_with?(name, "threadline_audit_")
    end
  end

  property "the migration hash does not depend on table order" do
    # A 44-byte table plus any other table always overflows 63 bytes, so the
    # generator never has to discard a list that fits.
    check all(
            long <- fixed_ident(44),
            rest <- list_of(pair_gen(), min_length: 1, max_length: 20)
          ) do
      pairs = [public(long) | rest]
      assert byte_size("threadline_triggers_" <> Enum.map_join(pairs, "_", &Naming.suffix/1)) > 63

      {name, _module} = Naming.migration_name(pairs, 1)
      {shuffled, _module} = Naming.migration_name(Enum.shuffle(pairs), 1)

      assert hash_segment(name) == hash_segment(shuffled)
    end
  end

  property "a function name is hashed exactly when the table is not a short public legacy table" do
    check all(pair <- pair_gen()) do
      legacy? =
        pair.schema == "public" and byte_size(pair.table) <= 36 and
          not Regex.match?(~r/_[0-9a-f]{12}\z/, pair.table)

      hashed? = String.ends_with?(Naming.function_name(pair), "_" <> hash12(pair))

      assert hashed? == not legacy?
    end
  end

  defp hash12(pair), do: Naming.hash12(Naming.qualified(pair))

  defp hash_segment(name) do
    [_, segment] = Regex.run(~r/_([0-9a-f]{12})\z/, name)
    segment
  end
end
