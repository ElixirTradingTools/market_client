defmodule MarketClient.Broker.Binance do
  alias MarketClient.Resource

  def start(res = %Resource{}), do: __MODULE__.Ws.ws_start(res)
end
