defmodule ThreadlinePhoenixWeb.Storybook.Index do
  use PhoenixStorybook.Index

  def folder_name, do: "Threadline"
  def folder_icon, do: {:fa, "book-open", :light, "psb:mr-1"}
  def folder_open?, do: true

  def entry("foundations"), do: [name: "Foundations", index: 0]
  def entry("primitives"), do: [name: "Primitives", index: 1]
  def entry("forms"), do: [name: "Forms", index: 2]
  def entry("states"), do: [name: "States", index: 3]
  def entry("overlays"), do: [name: "Overlays", index: 4]
  def entry("data_display"), do: [name: "Data Display", index: 5]
  def entry("groups"), do: [name: "Groups", index: 6]
  def entry("patterns"), do: [name: "Patterns", index: 7]
end
