defmodule MarketClient.Shared do
  @moduledoc false
  @doc """
  Shared helper / utility functions.
  """
  @spec is_broker_module(module) :: boolean
  @spec unix_now(:ms | :sec, none() | binary) :: integer
  @spec term_to_hash(any) :: binary
  @spec sha256(binary) :: binary

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

  def term_to_hash(assets) do
    assets
    |> :erlang.term_to_binary()
    |> sha256()
    |> :base64.encode()
  end

  def sha256(binary) do
    :crypto.hash(:sha256, binary)
  end
end
