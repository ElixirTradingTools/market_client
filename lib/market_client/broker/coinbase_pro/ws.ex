defmodule MarketClient.Broker.CoinbasePro.Ws do
  @moduledoc false
  @doc """
  WebSocket client for pro.coinbase.com.
  """
  alias MarketClient.{
    Behaviors.WsApi,
    Resource
  }

  use WsApi

  @impl WsApi
  def ws_url_via({:coinbase_pro, _}, {:crypto, assets_kwl}) do
    url = "wss://ws-feed.pro.coinbase.com"
    via = MarketClient.get_via(:coinbase_pro, assets_kwl, :ws)
    [{url, via, assets_kwl}]
  end

  @impl WsApi
  def ws_asset_id({_, _, list}, type \\ :list) do
    list = for({a, b} <- list, do: String.upcase(~s/"#{a}-#{b}"/))

    case type do
      :list -> list
      :string -> list |> Enum.join(",")
    end
  end

  @impl WsApi
  def ws_subscribe(%Resource{broker: {:coinbase_pro, _}, watch: {:crypto, assets_kwl}}) do
    for {dt, list} <- assets_kwl do
      chan = get_channel(dt)
      ids = ws_asset_id({:crypto, dt, list}, :string)
      ~s/{"type":"subscribe","channels":[#{chan}],"product_ids":[#{ids}]}/
    end
  end

  @impl WsApi
  def ws_unsubscribe(%Resource{broker: {:coinbase_pro, _}, watch: {:crypto, assets_kwl}}) do
    for {dt, list} <- assets_kwl do
      chan = get_channel(dt)
      ids = ws_asset_id({:crypto, dt, list}, :string)
      ~s/{"type":"unsubscribe","channels":[#{chan}],"product_ids":[#{ids}]}/
    end
  end

  def get_channel(:quotes), do: ~s/"ticker"/
  def get_channel(:level2), do: ~s/"level2"/
end
