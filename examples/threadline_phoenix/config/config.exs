# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :threadline_phoenix,
  ecto_repos: [ThreadlinePhoenix.Repo],
  generators: [timestamp_type: :utc_datetime]

config :threadline, ecto_repos: [ThreadlinePhoenix.Repo]

# Configure the endpoint
config :threadline_phoenix, ThreadlinePhoenixWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ThreadlinePhoenixWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ThreadlinePhoenix.PubSub,
  live_view: [signing_salt: "XHJkLPlW"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :threadline_phoenix, Oban,
  repo: ThreadlinePhoenix.Repo,
  queues: [threadline_audit: 10, sigra_mailer: 10],
  plugins: []

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

# Sigra authentication
config :threadline_phoenix, :sigra,
  repo: ThreadlinePhoenix.Repo,
  user_schema: ThreadlinePhoenix.Accounts.User

# Runtime keyword consumed by Sigra admin LiveViews (UsersIndexLive, etc.)
# via Application.get_env/2 — keep in sync with ThreadlinePhoenix.Accounts.sigra_config/0.
config :threadline_phoenix, :sigra_config,
  repo: ThreadlinePhoenix.Repo,
  user_schema: ThreadlinePhoenix.Accounts.User,
  session: [
    store: Sigra.SessionStores.Ecto,
    session_schema: ThreadlinePhoenix.Accounts.UserSession
  ],
  audit: [
    audit_schema: ThreadlinePhoenix.Accounts.AuditEvent
  ]

# Sigra worker runtime config (used by Oban workers)
config :sigra,
  otp_app: :threadline_phoenix,
  repo: ThreadlinePhoenix.Repo,
  user_schema: ThreadlinePhoenix.Accounts.User,
  email_module: ThreadlinePhoenix.Accounts.Emails,
  mailer: ThreadlinePhoenix.Accounts.Mailer

import_config "#{config_env()}.exs"
