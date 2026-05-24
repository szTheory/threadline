import Config

if config_env() == :test do
  import_config "test.exs"
else
  config :threadline,
    storage_adapter: Threadline.Storage.Local,
    export_queue_adapter: Threadline.ExportQueue.TaskAdapter

  config :threadline, Threadline.ExportQueue.Oban,
    oban_name: Oban,
    queue: :threadline_exports

  # Safe library defaults — hosts override in `runtime.exs` / releases.
  config :threadline, :exports,
    cleanup_interval_ms: :timer.hours(1),
    stale_running_cutoff_hours: 24,
    retention_ttl_hours: 24 * 7

  config :threadline, :retention,
    enabled: false,
    keep_days: 90,
    delete_empty_transactions: true,
    interval_ms: :timer.minutes(60),
    sleep_ms: 50
end
