defmodule JumpappBalance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JumpappBalanceWeb.Telemetry,
      JumpappBalance.Repo,
      {DNSCluster, query: Application.get_env(:jumpapp_balance, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: JumpappBalance.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: JumpappBalance.Finch},
      # Start a worker by calling: JumpappBalance.Worker.start_link(arg)
      # {JumpappBalance.Worker, arg},
      # Start to serve requests, typically the last entry
      JumpappBalanceWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JumpappBalance.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JumpappBalanceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
