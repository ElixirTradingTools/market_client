defmodule MarketClient.Broker.Binance do
  alias MarketClient.Resource
  alias Jason, as: J

  def url(res = %Resource{}) do
    "wss://stream.binance.com:9443/ws/#{get_pair(res)}"
  end

  def get_pair(%Resource{asset_id: {:crypto, {c1, c2}}}) when is_atom(c1) and is_atom(c2) do
    "#{to_string(c1)}#{to_string(c2)}"
  end

  def format_asset_id(res = %Resource{}) do
    "#{get_pair(res)}@bookTicker"
  end

  def subscribe(res = %Resource{}) do
    %{
      "id" => 1,
      "method" => "SUBSCRIBE",
      "params" => [format_asset_id(res)]
    }
    |> J.encode!()
  end

  def unsubscribe(res = %Resource{}) do
    %{
      "id" => 1,
      "method" => "UNSUBSCRIBE",
      "params" => [format_asset_id(res)]
    }
    |> J.encode!()
  end
end
