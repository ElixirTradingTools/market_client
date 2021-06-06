defmodule MarketClient.Broker.Ftx.Ws do
  @moduledoc false
  @doc """
  WebSocket client for ftx.com.
  """
  use MarketClient.Behaviors.FtxWs, [:com]
end
