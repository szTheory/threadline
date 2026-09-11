defmodule ThreadlinePhoenixWeb.ThreadlineStressSession do
  @moduledoc false

  @ledger_path Path.expand(
                 "../../../../.planning/design-system-ledger.json",
                 __DIR__
               )
  @recovery_command "mix test examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs"

  def session(_conn) do
    %{"threadline_stress_ledger_entries" => ledger_entries!()}
  end

  defp ledger_entries! do
    with {:ok, bytes} <- File.read(@ledger_path),
         {:ok, %{"entries" => entries}} when is_list(entries) and entries != [] <-
           Jason.decode(bytes),
         true <- Enum.all?(entries, &is_map/1) do
      entries
    else
      error ->
        raise """
        Threadline stress ledger is unavailable or invalid.
        Resolved path: #{@ledger_path}
        Repository-only: true
        Recovery: #{@recovery_command}
        Cause: #{inspect(error)}
        """
    end
  end
end
