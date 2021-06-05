defmodule MarketClient.Broker.Coinbase do
  alias MarketClient.Resource

  def start(res = %Resource{}), do: __MODULE__.Ws.ws_start(res)
end
