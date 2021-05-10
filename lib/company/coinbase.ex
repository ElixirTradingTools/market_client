defmodule MarketClient.Company.Coinbase do
  alias MarketClient.{
    Company.BaseType.WsApi,
    Resource,
    Shared
  }

  use WsApi

  @impl WsApi
  def url(_) do
    "wss://ws-feed.pro.coinbase.com"
  end

  @impl WsApi
  def format_asset_id(%Resource{asset_id: {:crypto, {c1, c2}}}) do
    "#{Shared.upcase_atom(c1)}-#{Shared.upcase_atom(c2)}"
  end

  @impl WsApi
  def msg_subscribe(res = %Resource{}) do
    %{
      "type" => "subscribe",
      "channels" => ["ticker"],
      "product_ids" => [format_asset_id(res)]
    }
    |> Jason.encode!()
  end

  @impl WsApi
  def msg_unsubscribe(res = %Resource{}) do
    %{
      "type" => "unsubscribe",
      "channels" => ["level2"],
      "product_ids" => [format_asset_id(res)]
    }
    |> Jason.encode!()
  end
end
