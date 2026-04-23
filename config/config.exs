import Config

if config_env() == :test do
  import_config "test.exs"
else
  # Safe library defaults — hosts override in `runtime.exs` / releases.
  config :threadline, :retention,
    enabled: false,
    keep_days: 90,
    delete_empty_transactions: true
end
