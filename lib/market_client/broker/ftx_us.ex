defmodule MarketClient.Broker.FtxUs do
  def ws_start(res), do: __MODULE__.Ws.ws_start(res)
  def http_start(res), do: __MODULE__.Http.http_start(res)
end

defmodule MarketClient.Broker.FtxUs.Ws do
  use MarketClient.Behaviors.FtxWs, [:us]
end

defmodule MarketClient.Broker.FtxUs.Http do
  use MarketClient.Behaviors.FtxHttp, [:us]
end
