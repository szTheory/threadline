defmodule Threadline.ReleaseControlPlaneContractTest do
  use ExUnit.Case, async: true
  @root File.cwd!()

  test "the sole publish command is inside the production environment job behind hard gates" do
    paths = Path.wildcard(Path.join(@root, ".github/workflows/*.{yml,yaml}"))
    publishers = Enum.filter(paths, &(File.read!(&1) =~ "mix hex.publish"))
    assert Enum.map(publishers, &Path.basename/1) == ["release.yml"]

    source = File.read!(hd(publishers))
    [_, publish] = String.split(source, "\n  publish-hex:\n", parts: 2)
    assert publish =~ ~r/^    environment:\s*production-hex$/m
    assert publish =~ "needs:"
    assert publish =~ "gate-ci-green"
    assert publish =~ "mix hex.publish"
    refute publish =~ "continue-on-error: true"
    refute publish =~ ~r/if:.*workflow_dispatch/

    assert length(Regex.scan(~r/^\s+mix hex\.publish/m, source)) == 2
  end

  test "Hex authentication remains one contiguous replaceable step" do
    source = File.read!(Path.join(@root, ".github/workflows/release.yml"))

    assert [_, tail] =
             String.split(source, "HEX AUTHENTICATION — TRUSTED-PUBLISHING SWAP POINT", parts: 2)

    [auth | _] = String.split(tail, "END HEX AUTHENTICATION SWAP POINT", parts: 2)
    assert auth =~ "HEX_API_KEY"
    refute auth =~ "mix hex.publish"
  end
end
