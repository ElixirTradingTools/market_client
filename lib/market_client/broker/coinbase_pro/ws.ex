defmodule MarketClient.Broker.CoinbasePro.Ws do
  @moduledoc false
  @doc """
  WebSocket client for pro.coinbase.com.
  """
  alias MarketClient.{
    Behaviors.WsApi,
    Resource,
    Shared
  }

  use WsApi

  @impl WsApi
  def ws_url(%Resource{broker: {:coinbase_pro, _}}) do
    "wss://ws-feed.pro.coinbase.com"
  end

  @impl WsApi
  def ws_asset_id({:crypto, _, {a, b}}) do
    "#{Shared.a2s_upcased(a)}-#{Shared.a2s_upcased(b)}"
  end

  @impl WsApi
  def ws_subscribe(res = %Resource{broker: {:coinbase_pro, _}}) do
    ~s({
      "type":"subscribe",
      "channels":["#{get_channel(res.asset_id)}"],
      "product_ids":["#{ws_asset_id(res.asset_id)}"]
    })
    |> Shared.remove_whitespace()
  end

  @impl WsApi
  def ws_unsubscribe(res = %Resource{broker: {:coinbase_pro, _}}) do
    ~s({
      "type":"unsubscribe",
      "channels":["#{get_channel(res.asset_id)}"],
      "product_ids":["#{ws_asset_id(res.asset_id)}"]
    })
    |> Shared.remove_whitespace()
  end

  def get_channel({:crypto, :quotes, _}), do: "ticker"
  def get_channel({:crypto, :level2, _}), do: "level2"
end
