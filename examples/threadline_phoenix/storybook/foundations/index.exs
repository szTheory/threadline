defmodule ThreadlinePhoenixWeb.Storybook.FoundationsIndex do
  use PhoenixStorybook.Index

  def folder_name, do: "Foundations"
  def folder_icon, do: {:fa, "palette", :thin}
  def folder_index, do: 0
  def folder_open?, do: true

  def entry("index"), do: [name: "Foundation Rules", index: 0]
end
