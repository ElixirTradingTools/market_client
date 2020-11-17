defmodule MarketClient.Provider.Binance do
  alias MarketClient.Resource
  alias MarketClient.Net.WebSocket
  alias Jason, as: J

  def url(res = %Resource{}) do
    "wss://stream.binance.com:9443/ws/#{get_pair(res)}"
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

  def get_pair(%Resource{asset_id: {:crypto, {c1, c2}}}) when is_atom(c1) and is_atom(c2) do
    "#{to_string(c1)}#{to_string(c2)}"
  end

  def format_asset_id(res = %Resource{}) do
    "#{get_pair(res)}@bookTicker"
  end

  def msg_subscribe(res = %Resource{}) do
    %{
      "id" => 1,
      "method" => "SUBSCRIBE",
      "params" => [format_asset_id(res)]
    }
    |> J.encode!()
  end

  def msg_unsubscribe(res = %Resource{}) do
    %{
      "id" => 1,
      "method" => "UNSUBSCRIBE",
      "params" => [format_asset_id(res)]
    }
    |> J.encode!()
  end
end
