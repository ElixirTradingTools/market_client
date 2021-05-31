defmodule MarketClient.Vendor.FtxUs do
  alias MarketClient.{
    Behaviors.HttpApi,
    Behaviors.WsApi,
    Resource,
    Shared
  }

  use WsApi
  use HttpApi

  @spec get_channel({atom, atom, any}) :: binary

  # -- WebSocket -- #

  @impl WsApi
  def ws_url(%Resource{vendor: {:ftx_us, _}}) do
    "wss://ftx.us/ws/"
  end

  @impl WsApi
  def msg_subscribe(res = %Resource{vendor: {:ftx_us, _}}) do
    chan = get_channel(res.asset_id)
    market = get_asset_id(res.asset_id)
    ~s({"op":"subscribe","channel":"#{chan}","market":"#{market}"})
  end

  @impl WsApi
  def msg_unsubscribe(res = %Resource{vendor: {:ftx_us, _}}) do
    chan = get_channel(res.asset_id)
    params = get_asset_id(res.asset_id)
    ~s({"op":"unsubscribe","channel":"#{chan}","market":"#{params}"})
  end

  def get_channel({_, data_type, _}) do
    case data_type do
      :trades -> "trades"
    end
  end

  # -- HTTP -- #

  @impl HttpApi
  def http_url(res = %Resource{vendor: {:ftx_us, _}}) do
    "https://ftx.us/api/markets/#{get_asset_id(res.asset_id)}/candles?#{http_query_params(res)}"
  end

  @impl HttpApi
  def http_query_params(%Resource{vendor: {:ftx_us, _}}) do
    "resolution=60&limit=10&start_time=0&end_time=#{Shared.unix_now(:sec)}"
  end

  @impl HttpApi
  def http_headers(%Resource{vendor: {:ftx_us, _}}) do
    []
  end

  @impl HttpApi
  def http_method(%Resource{vendor: {:ftx_us, _}}) do
    :get
  end
end
