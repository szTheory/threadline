defmodule Threadline.CriticPairLabelingContractTest do
  use ExUnit.Case, async: true

  @critic_dir "examples/threadline_phoenix/e2e/critic"

  test "pair creation validates and records two distinct non-held-out cells" do
    label = File.read!(Path.join(@critic_dir, "label.ts"))

    assert label =~ ~s|--pair-with <cell-id>|
    assert label =~ "A pair requires two distinct cells"
    assert label =~ "const requestedCells = pairWith ? [cellId, pairWith] : [cellId]"
    assert label =~ ~s|const kind: QueueItem["kind"] = pairWith ? "pair" : "single"|
    assert label =~ "pair_with: pairWith"
  end

  test "CLI and web pair rounds present and persist both opaque sides" do
    label = File.read!(Path.join(@critic_dir, "label.ts"))
    web = File.read!(Path.join(@critic_dir, "label_web.ts"))

    assert label =~ "LEFT: ${token}"
    assert label =~ "RIGHT: ${pairToken}"
    assert label =~ "showScreenshot(pairScreenshotPath)"
    assert label =~ "pair_with_token: pairToken"

    assert web =~ "LEFT · ${tokens.primary}"
    assert web =~ "RIGHT · ${tokens.pair}"
    assert web =~ ~s|src=\"/img/${tokens.primary}\"|
    assert web =~ ~s|src=\"/img/${tokens.pair}\"|
    assert web =~ "pair_with_token: tokens.pair"
  end

  test "round reconciliation keys and golden items retain pair identity" do
    label = File.read!(Path.join(@critic_dir, "label.ts"))

    assert label =~
             ~s|return [item.cell_id, item.lens, item.kind, item.pair_with ?? ""].join("::")|

    assert length(Regex.scan(~r/pair_with: r1Item\.pair_with/, label)) == 3

    assert label =~ "r1Item.kind !== \"pair\" || r1Item.margin === r2Item.margin"
    assert label =~ ~s|{ margin: r1Item.margin }|

    refute label =~ "TODO: wire pair tokens"
  end
end
