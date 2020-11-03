defmodule MarketClient.Broker.Coinbase do
  import MarketClient.Shared
  alias MarketClient.Resource
  alias Jason, as: J

  def url, do: "wss://ws-feed.pro.coinbase.com"

  def subscribe(%Resource{asset_id: asset_id}) do
    %{
      "type" => "subscribe",
      "channels" => ["level2"],
      "product_ids" => as_list(asset_id)
    }
    |> J.encode!()
  end

  def unsubscribe(%Resource{asset_id: asset_id}) do
    %{
      "type" => "unsubscribe",
      "channels" => ["level2"],
      "product_ids" => as_list(asset_id)
    }
    |> J.encode!()
  end
end
