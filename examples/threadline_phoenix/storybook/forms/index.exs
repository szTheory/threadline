defmodule ThreadlinePhoenixWeb.Storybook.FormsIndex do
  use PhoenixStorybook.Index

  def folder_name, do: "Forms"
  def folder_icon, do: {:fa, "input-text", :thin}
  def folder_index, do: 2
  def folder_open?, do: true

  def entry("field"), do: [name: "Field Controls", index: 0]
end
