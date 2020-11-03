defmodule MarketClient.Broker.Polygon do
  alias MarketClient.Resource
  alias Jason, as: J
  alias Enum, as: E

  def url, do: "wss://socket.polygon.io/stocks"

  def subscribe(%Resource{asset_id: asset_id, api_key: key}) do
    [
      %{
        "action" => "auth",
        "params" => key
      },
      %{
        "action" => "subscribe",
        "params" => asset_id
      }
    ]
    |> E.map(&J.encode!/1)
  end

  def unsubscribe(%Resource{asset_id: asset_id}) do
    %{
      "action" => "unsubscribe",
      "params" => asset_id
    }
    |> J.encode!()
  end
end
