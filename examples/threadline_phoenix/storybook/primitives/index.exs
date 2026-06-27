defmodule ThreadlinePhoenixWeb.Storybook.PrimitivesIndex do
  use PhoenixStorybook.Index

  def folder_name, do: "Primitives"
  def folder_icon, do: {:fa, "shapes", :thin}
  def folder_index, do: 1
  def folder_open?, do: true

  def entry("button"), do: [name: "Buttons And Primitives", index: 0]
end
