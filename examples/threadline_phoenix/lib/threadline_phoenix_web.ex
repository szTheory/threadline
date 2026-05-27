defmodule ThreadlinePhoenixWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use ThreadlinePhoenixWeb, :controller
      use ThreadlinePhoenixWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      import Plug.Conn

      use Gettext, backend: ThreadlinePhoenixWeb.Gettext

      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Component, only: [form: 1, link: 1, sigil_H: 2]
      import Phoenix.HTML
      import ThreadlinePhoenixWeb.CoreComponents
      import ThreadlinePhoenixWeb.Layouts

      alias Phoenix.LiveView.JS

      use Gettext, backend: ThreadlinePhoenixWeb.Gettext

      unquote(verified_routes())
    end
  end

  def layout do
    quote do
      use Phoenix.Component

      import ThreadlinePhoenixWeb.CoreComponents

      use Gettext, backend: ThreadlinePhoenixWeb.Gettext
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ThreadlinePhoenixWeb.Endpoint,
        router: ThreadlinePhoenixWeb.Router,
        statics: ThreadlinePhoenixWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
