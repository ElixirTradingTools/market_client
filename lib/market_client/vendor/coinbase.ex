defmodule MarketClient.Vendor.Coinbase do
  alias MarketClient.{
    Behaviors.WsApi,
    Resource,
    Shared
  }

  use WsApi

  @impl WsApi
  def ws_url(%Resource{broker: {:coinbase, _}}) do
    "wss://ws-feed.pro.coinbase.com"
  end

  @impl WsApi
  def get_asset_id(%Resource{broker: {:coinbase, _}, asset_id: {:crypto, {c1, c2}}}) do
    "#{Shared.a2s_upcased(c1)}-#{Shared.a2s_upcased(c2)}"
  end

  @impl WsApi
  def msg_subscribe(res = %Resource{broker: {:coinbase, _}}) do
    %{
      "type" => "subscribe",
      "channels" => ["ticker"],
      "product_ids" => [get_asset_id(res)]
    }
    |> Jason.encode!()
  end

  @impl WsApi
  def msg_unsubscribe(res = %Resource{broker: {:coinbase, _}}) do
    %{
      "type" => "unsubscribe",
      "channels" => ["level2"],
      "product_ids" => [get_asset_id(res)]
    }
    |> Jason.encode!()
  end
end
