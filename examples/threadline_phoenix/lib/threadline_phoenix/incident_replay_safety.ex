defmodule ThreadlinePhoenix.IncidentReplaySafety do
  @moduledoc false

  @test_database ~r/\Athreadline_phoenix_test(?:[0-9]+)?\z/

  @doc false
  def disposable_database?("threadline_phoenix_dev"), do: true

  def disposable_database?(database) when is_binary(database) do
    Regex.match?(@test_database, database)
  end

  def disposable_database?(_database), do: false
end
