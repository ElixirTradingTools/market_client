defmodule MarketClient.Broker.Polygon do
  alias MarketClient.{
    Behaviors.WsApi,
    Resource,
    Shared
  }

  use WsApi

  @spec ws_url(Resource.t()) :: binary

  @impl WsApi
  def ws_url(%Resource{broker: {:polygon, _}, asset_id: {class, _, _}}) do
    case class do
      :forex -> "wss://socket.polygon.io/forex"
      :stock -> "wss://socket.polygon.io/stocks"
      :crypto -> "wss://socket.polygon.io/crypto"
    end
  end

  @impl WsApi
  def ws_asset_id({:stock, data_type, ticker}) when is_binary(ticker) do
    case data_type do
      :quote -> "Q.#{String.upcase(ticker)}"
    end
  end

  @impl WsApi
  def ws_asset_id({:forex, data_type, {a, b}}) do
    case data_type do
      :quote -> "C.#{Shared.a2s_upcased(a)}/#{Shared.a2s_upcased(b)}"
    end
  end

  @impl WsApi
  def ws_subscribe(res = %Resource{broker: {:polygon, key: key}}) do
    [
      ~s({"action":"auth","params":"#{key}"}),
      ~s({"action":"subscribe","params":"#{ws_asset_id(res.asset_id)}"})
    ]
  end

  @impl WsApi
  def ws_unsubscribe(res = %Resource{broker: {:polygon, _}}) do
    ~s({"action":"unsubscribe","params":"#{ws_asset_id(res.asset_id)}"})
  end
end
