defmodule ThreadlinePhoenixWeb.Storybook.DataDisplayIndex do
  use PhoenixStorybook.Index

  def folder_name, do: "Data Display"
  def folder_icon, do: {:fa, "table", :thin}
  def folder_index, do: 5
end
