defmodule MarketClient.Shared do
  @moduledoc false
  @doc """
  Shared helper / utility functions.
  """
  @spec is_broker_module(module) :: boolean
  @spec unix_now(:ms | :sec, none() | binary) :: integer

  def is_broker_module(module) do
    [Module.split(MarketClient.Broker), Module.split(module)]
    |> Enum.reduce(&List.starts_with?/2)
  end

  def unix_now(unit, timezone \\ "Etc/UTC") do
    case unit do
      :ms -> DateTime.now!(timezone) |> DateTime.to_unix(:millisecond)
      :sec -> DateTime.now!(timezone) |> DateTime.to_unix(:second)
    end
  end
end
