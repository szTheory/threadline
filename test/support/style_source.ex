if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.Test.StyleSource do
    @moduledoc false

    # Reads the operator stylesheet source in cascade order.
    #
    # The stylesheet is split into `.css` segments under
    # `lib/threadline/operator_surface/style/`, and their order is the cascade.
    # The order comes only from `Threadline.OperatorSurface.Style.segments/0`,
    # the same list the module compiles, never from the filesystem. Tests that
    # slice the stylesheet by position (for example "everything before the
    # first `@media`") therefore see exactly the text the browser sees.

    alias Threadline.OperatorSurface.Style

    @root Path.expand("../..", __DIR__)
    @style_module "lib/threadline/operator_surface/style.ex"
    @style_dir "lib/threadline/operator_surface/style"

    @doc false
    def css! do
      Enum.map_join(Style.segments(), fn segment ->
        @root |> Path.join(@style_dir) |> Path.join(segment) |> File.read!()
      end)
    end

    # The stylesheet followed by the module that compiles it. The module text
    # comes last, so it can never precede the first rule a slicer splits on.
    @doc false
    def read!, do: css!() <> "\n" <> File.read!(Path.join(@root, @style_module))
  end
end
