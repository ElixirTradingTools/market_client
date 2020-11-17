defmodule MarketClient.Provider.Polygon do
  import MarketClient.Shared
  alias MarketClient.Resource
  alias MarketClient.Net.WebSocket
  alias Jason, as: J
  alias Enum, as: E

  def url(%Resource{asset_id: {class, _}}) do
    case class do
      :forex -> "wss://socket.polygon.io/forex"
      :stock -> "wss://socket.polygon.io/stocks"
      :crypto -> "wss://socket.polygon.io/crypto"
    end
  end

  def start_link(res = %Resource{}) do
    res
    |> url()
    |> WebSocket.start_link(res)
  end

  def start(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
    res
    |> msg_subscribe()
    |> WebSocket.ws_send(pid)
  end

  def stop(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
    res
    |> msg_unsubscribe()
    |> WebSocket.ws_send(pid)
  end

  def format_asset_id({:forex, {c1, c2}}) do
    "C.#{upcase_atom(c1)}/#{upcase_atom(c2)}"
  end

  def msg_subscribe(%Resource{asset_id: asset_id, broker: {_, %{key: key}}}) do
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

  def msg_unsubscribe(%Resource{asset_id: asset_id}) do
    %{
      "action" => "unsubscribe",
      "params" => format_asset_id(asset_id)
    }
    |> J.encode!()
  end
end
