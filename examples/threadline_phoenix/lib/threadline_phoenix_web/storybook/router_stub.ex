unless Code.ensure_loaded?(PhoenixStorybook.Router) do
  defmodule PhoenixStorybook.Router do
    @moduledoc false

    defmacro live_storybook(_path, _opts), do: nil
    defmacro storybook_assets(_path \\ "/storybook/assets"), do: nil
  end
end
