defmodule MarketClient.Supervised.Ws do
  def child_spec([res = %MarketClient.Resource{}]) do
    {MarketClient.Transport.Ws, [res]}
  end
end
