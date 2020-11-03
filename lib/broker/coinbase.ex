defmodule MarketClient.Broker.Coinbase do
  import MarketClient.Shared
  alias MarketClient.Resource
  alias Jason, as: J

  def url(_), do: "wss://ws-feed.pro.coinbase.com"

  def format_asset_id({:crypto, {c1, c2}}) do
    "#{upcase_atom(c1)}-#{upcase_atom(c2)}"
  end

  def subscribe(%Resource{asset_id: asset_id}) do
    %{
      "type" => "subscribe",
      "channels" => ["level2"],
      "product_ids" => [format_asset_id(asset_id)]
    }
    |> J.encode!()
  end

  def unsubscribe(%Resource{asset_id: asset_id}) do
    %{
      "type" => "unsubscribe",
      "channels" => ["level2"],
      "product_ids" => [format_asset_id(asset_id)]
    }
    |> J.encode!()
  end
end
