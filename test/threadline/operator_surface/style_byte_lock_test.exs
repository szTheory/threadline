if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StyleByteLockTest do
    @moduledoc """
    Byte lock for the rendered operator stylesheet.

    `Threadline.OperatorSurface.Style.css/1` renders the embedded `@font-face`
    block followed by the style-owned stylesheet. The style-owned part is pinned
    byte for byte by a committed golden file, and both the golden file and the
    full rendered output (fonts included) are pinned by sha256.

    Restructuring the stylesheet source must leave every pin green. A failure
    here means the rendered bytes changed; revert the change rather than
    regenerating the golden file. The bump procedure for an intentional CSS
    change lives in `test/fixtures/style/README.md`.

    The suffix is computed by stripping the fonts prefix, never by toggling the
    application env, so this module is safe to run with `async: true`.
    """

    use ExUnit.Case, async: true

    alias Phoenix.HTML.Safe
    alias Threadline.OperatorSurface.Fonts
    alias Threadline.OperatorSurface.Style
    alias Threadline.Test.StyleSource

    @root Path.expand("../../..", __DIR__)
    @golden_relative "test/fixtures/style/operator_surface.css"
    @golden_path Path.join(@root, @golden_relative)

    @golden_sha256 "c7baf51ecd9b4465675ea12a67218974157616ea8e8937e71aa166ca8154ab4b"
    @rendered_sha256 "b10d6a2c9a7d8abc99642f332cea9611ea7dab8f8a4ea8b212fac582ecaea5b1"

    @readme_relative "test/fixtures/style/README.md"
    @readme_path Path.join(@root, @readme_relative)

    @style_module_path Path.join(@root, "lib/threadline/operator_surface/style.ex")
    @style_dir_relative "lib/threadline/operator_surface/style"
    @style_dir Path.join(@root, @style_dir_relative)

    # The cascade: segment order is rule order in the rendered stylesheet.
    @cascade ~w(
      stylesheet.css
      04_controls.css
      05_feedback.css
      06_layout_primitives.css
      07_find_detail.css
      08_overlays_motion.css
      09_responsive.css
    )

    test "fonts are embedded, so the lock is computed against the default render" do
      assert Application.get_env(:threadline, :operator_surface_embed_fonts, true) == true,
             "the byte lock must run with operator_surface_embed_fonts enabled (the default)"
    end

    test "golden file is present and non-empty" do
      assert File.regular?(@golden_path), "missing golden file #{@golden_relative}"

      assert byte_size(File.read!(@golden_path)) > 0,
             "golden file #{@golden_relative} is empty; the lock would compare nothing"
    end

    test "golden hash pin" do
      actual = sha256(read_golden!())

      assert actual == @golden_sha256,
             "#{@golden_relative} sha256 is #{actual}, pinned #{@golden_sha256}. " <>
               "The golden file changed without its pin."
    end

    test "rendered output equals the fonts prefix plus the golden file" do
      full = render()
      prefix = fonts_prefix()

      assert String.starts_with?(full, prefix),
             "rendered output does not start with the embedded font-face block " <>
               "(#{byte_size(prefix)} bytes); the fonts/style join changed"

      suffix = binary_part(full, byte_size(prefix), byte_size(full) - byte_size(prefix))

      case diff_report(read_golden!(), suffix) do
        :same -> assert prefix <> read_golden!() == full
        message -> flunk(message)
      end
    end

    test "full rendered hash pin" do
      actual = sha256(render())

      assert actual == @rendered_sha256,
             "full rendered output sha256 is #{actual}, pinned #{@rendered_sha256}. " <>
               "The fonts block or the stylesheet changed."
    end

    test "render is deterministic" do
      first = render()
      second = render()

      case diff_report(first, second) do
        :same -> :ok
        message -> flunk("two renders in the same VM differ. " <> message)
      end
    end

    test "diff reporter names the first differing line and stays bounded" do
      filler = String.duplicate("x", 100_000)
      expected = "line one\nline two\nline three #{filler}\nline four #{filler}\n"
      actual = "line one\nline two\nline 3 #{filler}\nline four #{filler}\n"

      assert diff_report(expected, expected) == :same

      message = diff_report(expected, actual)
      assert is_binary(message)
      assert message =~ "first differing line: 3"
      assert message =~ "byte offset: #{byte_size("line one\nline two\nline ")}"
      assert message =~ "expected #{byte_size(expected)} bytes"
      assert message =~ "actual #{byte_size(actual)} bytes"
      assert byte_size(expected) > 200_000
      assert byte_size(message) < 2_000
    end

    test "source reader follows the rendered cascade" do
      css = StyleSource.css!()

      case diff_report(read_golden!(), "<style>" <> css <> "</style>") do
        :same ->
          :ok

        message ->
          flunk(
            "the segment files, read in Style.segments/0 order, do not reproduce " <>
              "the rendered stylesheet. " <> message
          )
      end

      css_first? = String.starts_with?(StyleSource.read!(), css)

      assert css_first?,
             "StyleSource.read!/0 must begin with the stylesheet in cascade order, " <>
               "so positional slicers never see the module text first"
    end

    test "segments are the cascade" do
      assert Style.segments() == @cascade
    end

    test "every segment exists, is non-empty, and is unique" do
      segments = Style.segments()

      assert segments != [], "Style.segments/0 is empty; the stylesheet would render nothing"
      assert segments == Enum.uniq(segments), "a segment is listed twice: #{inspect(segments)}"

      for segment <- segments do
        path = Path.join(@style_dir, segment)
        assert File.regular?(path), "segment #{@style_dir_relative}/#{segment} does not exist"
        assert File.stat!(path).size > 0, "segment #{@style_dir_relative}/#{segment} is empty"
      end
    end

    test "no orphan css" do
      on_disk =
        @style_dir
        |> Path.join("*.css")
        |> Path.wildcard()
        |> Enum.map(&Path.basename/1)
        |> Enum.sort()

      assert Enum.sort(Style.segments()) == on_disk,
             "every .css file in #{@style_dir_relative} must be listed in Style.segments/0, " <>
               "and every listed segment must exist"
    end

    test "every segment is an external resource" do
      resources =
        Style.__info__(:attributes)
        |> Keyword.get_values(:external_resource)
        |> List.flatten()
        |> Enum.map(&Path.basename/1)

      missing = Style.segments() -- resources

      assert missing == [],
             "segments without @external_resource would leave stale compiled CSS: " <>
               inspect(missing)
    end

    test "the style module lists its segments explicitly" do
      refute File.read!(@style_module_path) =~ "Path.wildcard",
             "the segment order is the cascade; list it literally instead of globbing"
    end

    test "the README carries the regeneration one-liner the failure message quotes" do
      command = regenerate_command()

      assert command =~ "MIX_ENV=test mix run --no-start",
             "#{@readme_relative} must keep the `MIX_ENV=test mix run --no-start -e …` " <>
               "regeneration one-liner on its own line"

      assert command =~ @golden_relative
    end

    test "this contract never references the planning directory" do
      planning_directory = "." <> "planning"
      refute File.read!(__ENV__.file) =~ planning_directory
    end

    defp render do
      %{__changed__: nil}
      |> Style.css()
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
    end

    defp fonts_prefix, do: "<style>" <> Fonts.face_css() <> "</style>"

    defp read_golden! do
      case File.read(@golden_path) do
        {:ok, ""} -> flunk("golden file #{@golden_relative} is empty")
        {:ok, bytes} -> bytes
        {:error, reason} -> flunk("cannot read golden file #{@golden_relative}: #{reason}")
      end
    end

    defp diff_report(same, same), do: :same

    defp diff_report(expected, actual) do
      offset = first_difference(expected, actual, 0)
      line = count_newlines(binary_part(expected, 0, min(offset, byte_size(expected)))) + 1

      """
      rendered stylesheet differs from #{@golden_relative}
        expected #{byte_size(expected)} bytes, actual #{byte_size(actual)} bytes
        first differing line: #{line}
        byte offset: #{offset}
        expected line: #{excerpt(expected, line)}
        actual line:   #{excerpt(actual, line)}
        actual sha256: #{sha256(actual)}
      Restructuring must not change rendered bytes; revert the change. For an
      intentional CSS change only, regenerate with:
        #{regenerate_command()}
      then paste both new hashes into this test (see test/fixtures/style/README.md).
      """
    end

    # The bump procedure is owned by the README; quote it rather than duplicate it.
    defp regenerate_command do
      with {:ok, readme} <- File.read(@readme_path),
           line when is_binary(line) <-
             readme
             |> String.split("\n")
             |> Enum.map(&String.trim/1)
             |> Enum.find(
               &(String.starts_with?(&1, "MIX_ENV=test mix run") and &1 =~ "binary_part")
             ) do
        line
      else
        _ -> "(see #{@readme_relative})"
      end
    end

    defp first_difference(expected, actual, offset) do
      case {expected, actual} do
        {<<byte, rest_e::binary>>, <<byte, rest_a::binary>>} ->
          first_difference(rest_e, rest_a, offset + 1)

        _ ->
          offset
      end
    end

    defp count_newlines(bytes), do: bytes |> :binary.matches("\n") |> length()

    defp excerpt(bytes, line) do
      bytes
      |> String.split("\n")
      |> Enum.at(line - 1, "")
      |> String.slice(0, 160)
      |> inspect()
    end

    defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  end
end
