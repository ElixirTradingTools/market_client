defmodule MarketClient.Company.FtxUs do
  alias MarketClient.{
    Company.BaseType.WsApi,
    Resource
  }

  use WsApi

  @impl WsApi
  def url(%Resource{broker: {:ftx_us, _}}) do
    "wss://ftx.us/ws/"
  end

  @impl WsApi
  def msg_subscribe(res = %Resource{broker: {:ftx_us, _}}) do
    %{
      "op" => "subscribe",
      "channel" => "trades",
      "market" => get_asset_pair(res)
    }
    |> Jason.encode!()
  end

  @impl WsApi
  def msg_unsubscribe(res = %Resource{broker: {:ftx_us, _}}) do
    %{
      "op" => "unsubscribe",
      "channel" => "trades",
      "params" => get_asset_pair(res)
    }
    |> Jason.encode!()
  end
end
