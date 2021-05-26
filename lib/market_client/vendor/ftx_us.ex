defmodule MarketClient.Vendor.FtxUs do
  alias MarketClient.{
    Behaviors.HttpApi,
    Behaviors.WsApi,
    Resource,
    Shared
  }

  use WsApi
  use HttpApi

  # -- WebSocket -- #

  @impl WsApi
  def ws_url(%Resource{broker: {:ftx_us, _}}) do
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

  # -- HTTP -- #

  @impl HttpApi
  def http_url(res = %Resource{broker: {:ftx_us, _}}) do
    "https://ftx.us/api/markets/#{get_asset_pair(res)}/candles?#{http_query_params(res)}"
  end

  @impl HttpApi
  def http_query_params(%Resource{broker: {:ftx_us, _}}) do
    "resolution=60&limit=10&start_time=0&end_time=#{Shared.unix_now(:sec)}"
  end

  @impl HttpApi
  def http_headers(%Resource{broker: {:ftx_us, _}}) do
    []
  end

  @impl HttpApi
  def http_method(%Resource{broker: {:ftx_us, _}}) do
    :get
  end
end
