defmodule MarketClient.Broker.Binance do
  import MarketClient.Shared
  alias MarketClient.Resource
  alias Jason, as: J

  def url, do: "wss://dex.binance.org/api/ws"

  def subscribe(%Resource{asset_id: asset_id}) do
    %{
      "method" => "subscribe",
      "topic" => "trades",
      "symbols" => as_list(asset_id)
    }
    |> J.encode!()
  end

  def unsubscribe(%Resource{asset_id: asset_id}) do
    %{
      "method" => "unsubscribe",
      "topic" => "trades",
      "symbols" => as_list(asset_id)
    }
    |> J.encode!()
  end
end
