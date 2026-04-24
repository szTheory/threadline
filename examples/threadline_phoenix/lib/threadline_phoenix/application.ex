defmodule ThreadlinePhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ThreadlinePhoenixWeb.Telemetry,
      ThreadlinePhoenix.Repo,
      {DNSCluster,
       query: Application.get_env(:threadline_phoenix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ThreadlinePhoenix.PubSub},
      # Start a worker by calling: ThreadlinePhoenix.Worker.start_link(arg)
      # {ThreadlinePhoenix.Worker, arg},
      # Start to serve requests, typically the last entry
      ThreadlinePhoenixWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ThreadlinePhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ThreadlinePhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
