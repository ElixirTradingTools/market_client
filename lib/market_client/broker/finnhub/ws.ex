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
  def ws_url(res = %Resource{broker: {:finnhub, opts}}) do
    path =
      case res.asset_id do
        {_, :quotes, _} -> "api/v1/quote"
        {_, :trades, _} -> ""
      end

    case Keyword.get(opts, :key, nil) do
      nil -> raise "broker key not found"
      key -> "wss://ws.finnhub.io/#{path}?&token=#{key}"
    end
  end

  @impl WsApi
  def ws_subscribe(%Resource{broker: {:finnhub, _}, asset_id: aid}) do
    ~s({"type":"subscribe","symbol":"#{ws_asset_id(aid)}"})
  end

  @impl WsApi
  def ws_unsubscribe(%Resource{broker: {:finnhub, _}, asset_id: aid}) do
    ~s({"type":"unsubscribe","symbol":"#{ws_asset_id(aid)}"})
  end

  @impl WsApi
  def ws_asset_id({:stock, _, ticker}) do
    String.upcase(ticker)
  end
end
