defmodule Threadline.GettingStartedFixturesTest do
  use ExUnit.Case, async: true

  alias Threadline.GettingStartedFixtures

  test "extracts the interior block and trims outer blank lines" do
    path =
      write_fixture!("""
      before
      # doc: start: sample

        one
        two

      # doc: end: sample
      after
      """)

    assert GettingStartedFixtures.extract!(path, "sample") == "  one\n  two"
  end

  test "raises loudly when anchors are missing" do
    path = write_fixture!("before\nafter\n")

    assert_raise ArgumentError,
                 ~r/#{Regex.escape(path)} anchor "sample": missing start\/end markers/,
                 fn ->
                   GettingStartedFixtures.extract!(path, "sample")
                 end
  end

  test "raises loudly when anchors are duplicated" do
    path =
      write_fixture!("""
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

  test "raises loudly when anchors are unbalanced" do
    path =
      write_fixture!("""
      # doc: start: sample
      one
      """)

    assert_raise ArgumentError,
                 ~r/#{Regex.escape(path)} anchor "sample": unbalanced start\/end markers/,
                 fn ->
                   GettingStartedFixtures.extract!(path, "sample")
                 end
  end

  defp write_fixture!(contents) do
    path =
      Path.join(
        System.tmp_dir!(),
        "getting_started_fixture_#{System.unique_integer([:positive])}.txt"
      )

    File.write!(path, contents)
    path
  end
end
