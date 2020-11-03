defmodule MarketClient.Broker.Polygon do
  import MarketClient.Shared
  alias MarketClient.Resource
  alias Jason, as: J
  alias Enum, as: E

  def url(%Resource{asset_id: {class, _}}) do
    case class do
      :forex -> "wss://socket.polygon.io/forex"
      :stock -> "wss://socket.polygon.io/stocks"
      :crypto -> "wss://socket.polygon.io/crypto"
    end
  end

  def format_asset_id({:forex, {c1, c2}}),
    do: "C.#{upcase_atom(c1)}/#{upcase_atom(c2)}"

  def subscribe(%Resource{asset_id: asset_id, api_key: key}) do
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
    |> E.map(&J.encode!/1)
  end

  def unsubscribe(%Resource{asset_id: asset_id}) do
    %{
      "action" => "unsubscribe",
      "params" => format_asset_id(asset_id)
    }
    |> J.encode!()
  end
end
