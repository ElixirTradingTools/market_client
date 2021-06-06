defmodule MarketClient.Broker.Binance.Ws do
  @moduledoc false
  @doc """
  WebSocket client for binance.com.
  """
  use MarketClient.Behaviors.BinanceWs, [:com]
end
