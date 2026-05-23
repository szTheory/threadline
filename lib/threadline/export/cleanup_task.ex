defmodule Threadline.Export.CleanupTask do
  use GenServer
  require Logger
  import Ecto.Query

  alias Threadline.Governance.ExportJob

  @lock_key :erlang.phash2("threadline_export_cleanup")
  @default_interval_ms :timer.minutes(60)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    interval_ms = Keyword.get(opts, :interval_ms, @default_interval_ms)

    {:ok, %{repo: repo, interval_ms: interval_ms}}
  end

  @impl true
  def handle_info(:run_cleanup, state) do
    {:noreply, state}
  end
end
