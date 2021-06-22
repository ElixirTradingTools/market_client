defmodule MarketClient.Broker.Finnhub.Ws do
  @moduledoc false
  @doc """
  WebSocket client for finnhub.io.
  """
  alias MarketClient.{
    Behaviors.WsApi,
    Resource
  }

  use WsApi

  @impl WsApi
  def ws_url_via({:finnhub, opts}, {_class, assets_kwl}) do
    if(not Keyword.has_key?(opts, :key), do: raise("broker key not found"))
    key = Keyword.get(opts, :key)
    url = "wss://ws.finnhub.io/api/v1/quote?&token=" <> key
    via = MarketClient.get_via(:finnhub, assets_kwl, :ws)
    [{url, via, assets_kwl}]
  end

  @impl WsApi
  def ws_subscribe(%Resource{broker: {:finnhub, _}, watch: {class, [{dt, l}]}}) do
    ~s({"type":"subscribe","symbol":"#{ws_asset_id({class, dt, l})}"})
  end

  @impl WsApi
  def ws_unsubscribe(%Resource{broker: {:finnhub, _}, watch: {class, [{dt, l}]}}) do
    ~s({"type":"unsubscribe","symbol":"#{ws_asset_id({class, dt, l})}"})
  end
end
