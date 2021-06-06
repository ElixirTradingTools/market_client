defmodule MarketClient.Broker.FtxUs.Ws do
  @moduledoc false
  @doc """
  WebSocket client for ftx.us.
  """
  use MarketClient.Behaviors.FtxWs, [:us]
end
