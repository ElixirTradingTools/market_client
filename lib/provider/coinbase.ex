defmodule MarketClient.Provider.Coinbase do
  import MarketClient.Shared
  alias MarketClient.Resource
  alias MarketClient.Net.WebSocket
  alias Jason, as: J

  def url(_), do: "wss://ws-feed.pro.coinbase.com"

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

  def format_asset_id({:crypto, {c1, c2}}) do
    "#{upcase_atom(c1)}-#{upcase_atom(c2)}"
  end

  def msg_subscribe(%Resource{asset_id: asset_id}) do
    %{
      "type" => "subscribe",
      "channels" => ["ticker"],
      "product_ids" => [format_asset_id(asset_id)]
    }
    |> J.encode!()
  end

  def msg_unsubscribe(%Resource{asset_id: asset_id}) do
    %{
      "type" => "unsubscribe",
      "channels" => ["level2"],
      "product_ids" => [format_asset_id(asset_id)]
    }
    |> J.encode!()
  end
end
