defmodule MarketClient.Shared do
  @moduledoc false
  @doc """
  Shared helper / utility functions.
  """
  @spec is_broker_module(module) :: boolean
  @spec a2s_upcased(atom) :: binary
  @spec a2s_downcased(atom) :: binary
  @spec unix_now(:ms | :sec, none() | binary) :: integer

  def is_broker_module(module) do
    [Module.split(MarketClient.Broker), Module.split(module)]
    |> Enum.reduce(&List.starts_with?/2)
  end

  def a2s_upcased(atom) when is_atom(atom) do
    to_string(atom) |> String.upcase()
  end

  def a2s_downcased(atom) when is_atom(atom) do
    to_string(atom) |> String.downcase()
  end

  def unix_now(unit, timezone \\ "Etc/UTC") do
    case unit do
      :ms -> DateTime.now!(timezone) |> DateTime.to_unix(:millisecond)
      :sec -> DateTime.now!(timezone) |> DateTime.to_unix(:second)
    end
  end
end
