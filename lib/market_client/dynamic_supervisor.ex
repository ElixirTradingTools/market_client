defmodule MarketClient.DynamicSupervisor do
  @moduledoc """
  Supervisor for all processes this library will spawn.
  """
  use DynamicSupervisor

  @type on_start_child :: DynamicSupervisor.on_start_child()

  @spec start_link(any) :: on_start_child

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(child_spec) do
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
