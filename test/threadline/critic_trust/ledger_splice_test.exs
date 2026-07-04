defmodule Threadline.CriticTrust.LedgerSpliceTest do
  use ExUnit.Case, async: true

  alias Threadline.CriticTrust.{LedgerSplice, Measure}

  defp vacuous_block, do: Measure.build_block(%{"items" => []}, %{}, %{})

  test "render_block emits 6 lenses × 8 keys at the ledger's indentation" do
    rendered = LedgerSplice.render_block(vacuous_block())

    # 4-space lens keys, 6-space fields, 2-space block close.
    assert rendered =~ ~r/\n    "hierarchy": \{\n/
    assert rendered =~ ~r/\n      "alpha": null,/
    assert String.ends_with?(rendered, "\n  }")

    decoded = Jason.decode!(rendered)
    assert Map.keys(decoded) |> Enum.sort() == Enum.sort(Measure.lenses())
  end

  test "replace swaps only the critic_trust object, preserving all other bytes" do
    ledger = ~s({
  "keep_me": {
    "nested": "value with a } brace and \\" quote"
  },
  "version": 2,
  "critic_trust": {
    "old": true
  }
}
)

    {:ok, out} = LedgerSplice.replace(ledger, vacuous_block())

    decoded = Jason.decode!(out)
    # Untouched sibling survives verbatim, braces-in-strings and all.
    assert decoded["keep_me"]["nested"] == "value with a } brace and \" quote"
    assert decoded["version"] == 2
    # critic_trust replaced with the full 6-lens block.
    assert Map.keys(decoded["critic_trust"]) |> Enum.sort() == Enum.sort(Measure.lenses())
    assert decoded["critic_trust"]["hierarchy"]["validated"] == false

    # The prefix bytes before critic_trust are byte-identical.
    [prefix, _] = String.split(ledger, ~s("critic_trust":), parts: 2)
    assert String.starts_with?(out, prefix)
  end

  test "replace is idempotent — splice(splice(x)) == splice(x)" do
    ledger = ~s({
  "version": 2,
  "critic_trust": {
    "stale": 1
  }
}
)

    {:ok, once} = LedgerSplice.replace(ledger, vacuous_block())
    {:ok, twice} = LedgerSplice.replace(once, vacuous_block())
    assert once == twice
  end

  test "handles critic_trust as a non-final key (trailing comma preserved)" do
    ledger = ~s({
  "critic_trust": {
    "x": 1
  },
  "after": 7
}
)

    {:ok, out} = LedgerSplice.replace(ledger, vacuous_block())
    decoded = Jason.decode!(out)
    assert decoded["after"] == 7
    assert Map.keys(decoded["critic_trust"]) |> Enum.sort() == Enum.sort(Measure.lenses())
  end

  test "returns an error when the block is absent" do
    assert {:error, :critic_trust_not_found} = LedgerSplice.replace(~s({"a": 1}), vacuous_block())
  end
end
