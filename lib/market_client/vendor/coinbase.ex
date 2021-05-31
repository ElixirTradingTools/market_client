defmodule MarketClient.Vendor.Coinbase do
  alias MarketClient.{
    Behaviors.WsApi,
    Resource,
    Shared
  }

  use WsApi

  @impl WsApi
  def ws_url(%Resource{vendor: {:coinbase, _}}) do
    "wss://ws-feed.pro.coinbase.com"
  end

  @impl WsApi
  def get_asset_id({:crypto, _, {a, b}}) do
    "#{Shared.a2s_upcased(a)}-#{Shared.a2s_upcased(b)}"
  end

  @impl WsApi
  def msg_subscribe(res = %Resource{vendor: {:coinbase, _}}) do
    ~s({
      "type":"subscribe",
      "channels":["level2"],
      "product_ids":["#{get_asset_id(res.asset_id)}"]
    })
    |> Shared.remove_whitespace()
  end

  @impl WsApi
  def msg_unsubscribe(res = %Resource{vendor: {:coinbase, _}}) do
    ~s({
      "type":"unsubscribe",
      "channels":["level2"],
      "product_ids":["#{get_asset_id(res.asset_id)}"]
    })
    |> Shared.remove_whitespace()
  end
end
