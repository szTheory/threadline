defmodule ThreadlinePhoenixWeb.Storybook.StatesIndex do
  use PhoenixStorybook.Index

  def folder_name, do: "States"
  def folder_icon, do: {:fa, "signal-stream", :thin}
  def folder_index, do: 3
  def folder_open?, do: true

  def entry("data_state"), do: [name: "Data States", index: 0]
end
