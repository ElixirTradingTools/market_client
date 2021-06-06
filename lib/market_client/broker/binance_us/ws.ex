defmodule MarketClient.Broker.BinanceUs.Ws do
  @moduledoc false
  @doc """
  WebSocket client for binance.us.
  """
  use MarketClient.Behaviors.BinanceWs, [:us]
end
