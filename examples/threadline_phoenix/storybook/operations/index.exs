defmodule ThreadlinePhoenixWeb.Storybook.OperationsIndex do
  use PhoenixStorybook.Index
  def folder_name, do: "Operations"
  def folder_icon, do: {:fa, "list-check", :thin}
  def folder_index, do: 8
end
