defmodule MarketClient.Company.FtxUs do
  alias MarketClient.{
    Company.BaseType.WsApi,
    Resource
  }

  use WsApi

  @impl WsApi
  def url(_) do
    "wss://ftx.us/ws/"
  end

  @impl WsApi
  def msg_subscribe(res = %Resource{}) do
    %{
      "op" => "subscribe",
      "channel" => "trades",
      "market" => get_asset_pair(res)
    }
    |> Jason.encode!()
  end

  @impl WsApi
  def msg_unsubscribe(res = %Resource{}) do
    %{
      "op" => "unsubscribe",
      "channel" => "trades",
      "params" => get_asset_pair(res)
    }
    |> Jason.encode!()
  end
end
