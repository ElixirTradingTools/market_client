defmodule MarketClient.Broker do
  alias MarketClient.Resource

  def get_broker_module(%Resource{broker: broker}) do
    case broker do
      :coinbase -> MarketClient.Broker.Coinbase
      :polygon -> MarketClient.Broker.Polygon
      :binance -> MarketClient.Broker.Binance
    end
  end

  def url(res = %Resource{}) do
    res
    |> get_broker_module()
    |> apply(:url, [res])
  end

  def subscribe(res = %Resource{}) do
    res
    |> get_broker_module()
    |> apply(:subscribe, [res])
  end

  def unsubscribe(res = %Resource{}) do
    res
    |> get_broker_module()
    |> apply(:unsubscribe, [res])
  end
end
