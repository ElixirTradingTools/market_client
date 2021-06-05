defmodule MarketClient.Broker.Ftx do
  def start(res), do: __MODULE__.Ws.ws_start(res)
  def http_start(res), do: __MODULE__.Http.http_start(res)
end
