defmodule ThreadlinePhoenixWeb.StorybookRouteTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @router ThreadlinePhoenixWeb.Router
  @router_source "lib/threadline_phoenix_web/router.ex"
  @router_stub_source "lib/threadline_phoenix_web/storybook/router_stub.ex"

  test "dev/test router exposes the maintainer Storybook route and assets" do
    routes = Phoenix.Router.routes(@router)

    assert Enum.any?(routes, &(&1.path == "/dev/storybook")),
           "expected /dev/storybook in the example app dev/test route table"

    assert Enum.any?(routes, &String.starts_with?(&1.path, "/dev/storybook/assets")),
           "expected /dev/storybook/assets route in the example app dev/test route table"
  end

  test "Storybook router source follows the root-scope dev_routes contract" do
    source = File.read!(@router_source)

    assert source =~ "Application.compile_env(:threadline_phoenix, :dev_routes)"
    assert source =~ "Code.ensure_loaded?(PhoenixStorybook.Router)"
    assert source =~ "dev_routes requires the :phoenix_storybook dependency"
    assert source =~ "import PhoenixStorybook.Router"
    assert source =~ ~s|storybook_assets("/dev/storybook/assets"|
    assert source =~ ~s|live_storybook("/dev/storybook"|
    assert source =~ "backend_module: ThreadlinePhoenixWeb.Storybook"
    assert source =~ "assets_path: \"/dev/storybook/assets\""
    assert source =~ ~r/scope "\/".*storybook_assets/s
    assert source =~ ~r/scope "\/", ThreadlinePhoenixWeb.*live_storybook/s

    refute File.exists?(@router_stub_source),
           "Storybook router fallback stubs hide dependency mistakes; dev_routes must fail loudly"
  end

  test "Storybook remains outside the authenticated /audit operator route family" do
    routes = Phoenix.Router.routes(@router)

    refute Enum.any?(routes, fn route ->
             String.starts_with?(route.path, "/audit") and
               String.contains?(String.downcase(route.path), "storybook")
           end)
  end

  test "production config and source keep Storybook behind dev_routes" do
    source = File.read!(@router_source)
    prod_config = File.read!("config/prod.exs")

    assert source =~ "Application.compile_env(:threadline_phoenix, :dev_routes)"
    refute prod_config =~ "dev_routes: true"
    refute prod_config =~ "PhoenixStorybook"
    refute prod_config =~ "live_storybook"
    refute prod_config =~ "/dev/storybook"
  end
end
