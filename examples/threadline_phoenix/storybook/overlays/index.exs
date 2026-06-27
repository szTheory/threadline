defmodule ThreadlinePhoenixWeb.Storybook.OverlaysIndex do
  use PhoenixStorybook.Index

  def folder_name, do: "Overlays"
  def folder_icon, do: {:fa, "window", :thin}
  def folder_index, do: 4
end
