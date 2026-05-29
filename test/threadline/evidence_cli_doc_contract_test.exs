defmodule Threadline.EvidenceCliDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @canonical "mix threadline.evidence.show"
  @legacy "mix verify.evidence"

  for path <- ["guides/domain-reference.md", "guides/operator-surface.md"] do
    test "#{path} documents canonical evidence CLI only" do
      doc = File.read!(unquote(path))
      assert String.contains?(doc, @canonical)
      refute String.contains?(doc, @legacy)
    end
  end

  test "WALKTHROUGH command blocks use canonical evidence CLI" do
    doc = File.read!("examples/threadline_phoenix/WALKTHROUGH.md")
    assert String.contains?(doc, @canonical)
    assert String.contains?(doc, "--subject retention_run")
  end

  test "WALKTHROUGH allows at most one verify.evidence footnote mention" do
    doc = File.read!("examples/threadline_phoenix/WALKTHROUGH.md")
    count = doc |> String.split(@legacy) |> length() |> Kernel.-(1)
    assert count <= 1
  end

  test "mix.exs has no verify.evidence alias" do
    mix = File.read!("mix.exs")
    refute String.contains?(mix, "\"verify.evidence\":")
  end

  test "README compact evidence strip refutes runnable CLI strings" do
    readme = File.read!("README.md")
    refute String.contains?(readme, @canonical)
    refute String.contains?(readme, @legacy)
  end
end
