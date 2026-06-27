defmodule ThreadlinePhoenixWeb.Storybook.GroupsIndex do
  use PhoenixStorybook.Index

  def folder_name, do: "Groups"
  def folder_icon, do: {:fa, "objects-column", :thin}
  def folder_index, do: 6
end
