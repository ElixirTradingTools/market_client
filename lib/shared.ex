defmodule MarketClient.Shared do
  def as_list(thing) do
    case thing do
      s when is_binary(s) -> [s]
      l when is_list(l) -> l
    end
  end
end
