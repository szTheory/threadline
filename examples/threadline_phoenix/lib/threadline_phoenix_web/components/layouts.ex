defmodule ThreadlinePhoenixWeb.Layouts do
  @moduledoc """
  Application layouts for controller-rendered HEEx templates.
  """
  use ThreadlinePhoenixWeb, :layout

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_scope, :map, default: nil

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} flash={@flash} />
    <.flash kind={:error} flash={@flash} />
    """
  end
end
