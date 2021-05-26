defmodule MarketClient.Supervised.Http do
  def child_spec(_) do
    {Finch, name: MarketClient.Transport.Http}
  end
end
