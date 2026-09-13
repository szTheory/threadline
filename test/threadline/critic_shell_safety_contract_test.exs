defmodule Threadline.CriticShellSafetyContractTest do
  use ExUnit.Case, async: true

  @critic_dir "examples/threadline_phoenix/e2e/critic"

  test "path-bearing critic subprocesses use argument arrays without a shell" do
    bundle = File.read!(Path.join(@critic_dir, "bundle.ts"))
    label = File.read!(Path.join(@critic_dir, "label.ts"))
    label_web = File.read!(Path.join(@critic_dir, "label_web.ts"))

    for source <- [bundle, label, label_web] do
      assert source =~ ~s(import { execFileSync } from "node:child_process")
      refute source =~ "execSync("
    end

    assert bundle =~ ~S|execFileSync(
        "sips",
        [|

    assert bundle =~ ~S|execFileSync(
          "magick",
          [|

    assert label =~ ~S|execFileSync("open", [screenshotPath]|

    assert label =~
             ~S|["-C", repoRoot, "status", "--porcelain", "--", repoRelative(r1Path)]|

    assert label_web =~ ~S|execFileSync("open", [uri]|
  end
end
