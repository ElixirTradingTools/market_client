defmodule MarketClient.Broker.Ftx do
  def ws_start(res), do: __MODULE__.Ws.ws_start(res)
  def http_start(res), do: __MODULE__.Http.http_start(res)
end

defmodule MarketClient.Broker.Ftx.Ws do
  use MarketClient.Behaviors.FtxWs, [:com]
end

defmodule MarketClient.Broker.Ftx.Http do
  use MarketClient.Behaviors.FtxHttp, [:com]
end
