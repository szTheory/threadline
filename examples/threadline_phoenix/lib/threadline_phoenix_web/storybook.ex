if Code.ensure_loaded?(PhoenixStorybook) do
  defmodule ThreadlinePhoenixWeb.Storybook do
    @moduledoc false

    use PhoenixStorybook,
      otp_app: :threadline_phoenix,
      content_path: Path.expand("../../storybook", __DIR__),
      sandbox_class: "threadline-ui",
      color_mode: true
  end
end
