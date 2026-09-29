defmodule Threadline.GettingStartedFixturesTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  alias Threadline.GettingStartedFixtures

  test "extracts the interior block and trims outer blank lines", %{tmp_dir: tmp_dir} do
    path =
      write_fixture!(tmp_dir, """
      before
      # doc: start: sample

        one
        two

      # doc: end: sample
      after
      """)

    assert GettingStartedFixtures.extract!(path, "sample") == "  one\n  two"
  end

  test "raises loudly when anchors are missing", %{tmp_dir: tmp_dir} do
    path = write_fixture!(tmp_dir, "before\nafter\n")

    assert_raise ArgumentError,
                 ~r/#{Regex.escape(path)} anchor "sample": missing start\/end markers/,
                 fn ->
                   GettingStartedFixtures.extract!(path, "sample")
                 end
  end

  test "raises loudly when anchors are duplicated", %{tmp_dir: tmp_dir} do
    path =
      write_fixture!(tmp_dir, """
      # doc: start: sample
      one
      # doc: end: sample
      # doc: start: sample
      two
      # doc: end: sample
      """)

    assert_raise ArgumentError,
                 ~r/#{Regex.escape(path)}:\d+ anchor "sample": duplicate start\/end markers/,
                 fn ->
                   GettingStartedFixtures.extract!(path, "sample")
                 end
  end

  test "raises loudly when anchors are unbalanced", %{tmp_dir: tmp_dir} do
    path =
      write_fixture!(tmp_dir, """
      # doc: start: sample
      one
      """)

    assert_raise ArgumentError,
                 ~r/#{Regex.escape(path)} anchor "sample": unbalanced start\/end markers/,
                 fn ->
                   GettingStartedFixtures.extract!(path, "sample")
                 end
  end

  defp write_fixture!(tmp_dir, contents) do
    path =
      Path.join(
        tmp_dir,
        "getting_started_fixture_#{System.unique_integer([:positive])}.txt"
      )

    File.write!(path, contents)
    path
  end
end
