defmodule MarketClient.Broker.FtxUs.Http do
  @moduledoc false
  @doc """
  HTTP client for ftx.us.
  """
  use MarketClient.Behaviors.FtxHttp, [:us]
end
