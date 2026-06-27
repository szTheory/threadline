defmodule ThreadlinePhoenixWeb.Storybook.PatternsIndex do
  use PhoenixStorybook.Index

  def folder_name, do: "Patterns"
  def folder_icon, do: {:fa, "diagram-project", :thin}
  def folder_index, do: 7
end
