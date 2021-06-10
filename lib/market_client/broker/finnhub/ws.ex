defmodule MarketClient.Broker.Finnhub.Ws do
  @moduledoc false
  @doc """
  WebSocket client for finnhub.io.
  """
  alias MarketClient.{
    Behaviors.WsApi,
    Resource
  }

  use WsApi, [:finnhub]

  @impl WsApi
  def ws_url(%Resource{broker: {:finnhub, opts}}) do
    case Keyword.get(opts, :key, nil) do
      nil -> raise "broker key not found"
      key -> "wss://ws.finnhub.io?token=#{key}"
    end
  end

  @impl WsApi
  def ws_subscribe(res = %Resource{broker: {:finnhub, _}}) do
    ~s({"type":"subscribe","symbol":"#{ws_asset_id(res.asset_id)}"})
  end

  @impl WsApi
  def ws_unsubscribe(res = %Resource{broker: {:finnhub, _}}) do
    ~s({"type":"unsubscribe","symbol":"#{ws_asset_id(res.asset_id)}"})
  end

  @impl WsApi
  def ws_asset_id({:stock, _, ticker}) do
    String.upcase(ticker)
  end
end
