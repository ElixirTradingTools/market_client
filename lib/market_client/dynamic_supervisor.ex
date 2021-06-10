defmodule MarketClient.DynamicSupervisor do
  @moduledoc """
  Supervisor for all processes this library will spawn.
  """
  use DynamicSupervisor

  @spec start_link(any) :: Supervisor.on_start()

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(child_spec) do
    {:ok, _} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
