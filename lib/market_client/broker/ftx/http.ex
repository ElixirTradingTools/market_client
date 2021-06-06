defmodule MarketClient.Broker.Ftx.Http do
  @moduledoc false
  @doc """
  HTTP client for ftx.com.
  """
  use MarketClient.Behaviors.FtxHttp, [:com]
end
