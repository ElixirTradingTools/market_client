defmodule MarketClient.Vendor.Polygon do
  alias MarketClient.{
    Behaviors.WsApi,
    Resource,
    Shared
  }

  use WsApi

  @impl WsApi
  def ws_url(%Resource{broker: {:polygon, _}, asset_id: {class, _}}) do
    case class do
      :forex -> "wss://socket.polygon.io/forex"
      :stock -> "wss://socket.polygon.io/stocks"
      :crypto -> "wss://socket.polygon.io/crypto"
    end
  end

  @impl WsApi
  def get_asset_id(%Resource{broker: {:polygon, _}, asset_id: {:stock, ticker}})
      when is_binary(ticker) do
    "Q.#{String.upcase(ticker)}"
  end

  @impl WsApi
  def get_asset_id(%Resource{
        broker: {:polygon, _},
        asset_id: {:forex, {c1, c2}, data_type: data_type}
      }) do
    case data_type do
      :quote -> "C.#{Shared.a2s_upcased(c1)}/#{Shared.a2s_upcased(c2)}"
    end
  end

  @impl WsApi
  def msg_subscribe(res = %Resource{broker: {:polygon, %{key: key}}}) do
    [
      %{
        "action" => "auth",
        "params" => key
      },
      %{
        "action" => "subscribe",
        "params" => get_asset_id(res)
      }
    ]
    |> Enum.map(&Jason.encode!/1)
  end

  @impl WsApi
  def msg_unsubscribe(%Resource{broker: {:polygon, _}, asset_id: asset_id}) do
    %{
      "action" => "unsubscribe",
      "params" => get_asset_id(asset_id)
    }
    |> Jason.encode!()
  end
end
