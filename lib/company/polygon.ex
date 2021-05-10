defmodule MarketClient.Company.Polygon do
  alias MarketClient.{
    Company.BaseType.WsApi,
    Resource,
    Shared
  }

  use WsApi

  @impl WsApi
  def url(%Resource{broker: {:polygon, _}, asset_id: {class, _}}) do
    case class do
      :forex -> "wss://socket.polygon.io/forex"
      :stock -> "wss://socket.polygon.io/stocks"
      :crypto -> "wss://socket.polygon.io/crypto"
    end
  end

  @impl WsApi
  def format_asset_id(%Resource{broker: {:polygon, _}, asset_id: {:stock, ticker}})
      when is_binary(ticker) do
    "Q.#{String.upcase(ticker)}"
  end

  @impl WsApi
  def format_asset_id(%Resource{
        broker: {:polygon, _},
        asset_id: {:forex, {c1, c2}, data_type: data_type}
      }) do
    case data_type do
      :quote -> "C.#{Shared.upcase_atom(c1)}/#{Shared.upcase_atom(c2)}"
    end
  end

  @impl WsApi
  def msg_subscribe(%Resource{broker: {:polygon, %{key: key}}, asset_id: asset_id}) do
    [
      %{
        "action" => "auth",
        "params" => key
      },
      %{
        "action" => "subscribe",
        "params" => format_asset_id(asset_id)
      }
    ]
    |> Enum.map(&Jason.encode!/1)
  end

  @impl WsApi
  def msg_unsubscribe(%Resource{broker: {:polygon, _}, asset_id: asset_id}) do
    %{
      "action" => "unsubscribe",
      "params" => format_asset_id(asset_id)
    }
    |> Jason.encode!()
  end
end
