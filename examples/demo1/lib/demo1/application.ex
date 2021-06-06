defmodule Demo1.Application do
  use Application

  @impl true
  def start(_type, _args) do
    [
      {Registry, keys: :unique, name: MarketClient.Registry},
      MarketClient.DynamicSupervisor
    ]
    |> Supervisor.start_link(strategy: :one_for_one, name: Demo1.Supervisor)
  end
end
