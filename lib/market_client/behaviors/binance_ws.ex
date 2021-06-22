defmodule MarketClient.Behaviors.BinanceWs do
  @moduledoc """
  Reusable WsApi implementation for Binance & Binance.US broker modules.
  """
  defmacro __using__([tld]) when tld in [:us, :com] do
    alias MarketClient.Shared

    unless Shared.is_broker_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.BinanceWs is not a public module"
    end

    broker_name = if(tld == :us, do: :binance_us, else: :binance)

    quote do
      import String, only: [downcase: 1]

      alias MarketClient.{
        Behaviors.WsApi,
        Shared
      }

      use WsApi

      @typep currencies_list :: MarketClient.currencies_list()

      @spec ws_start(MarketClient.Resource.t()) ::
              list(MarketClient.DynamicSupervisor.on_start_child())
      @spec get_assets_url_path(keyword(currencies_list)) :: binary
      @spec get_assets_json_param({:crypto, keyword({binary, binary})}) :: binary

      @tld to_string(unquote(tld))
      @bn unquote(broker_name)

      @impl WsApi
      def ws_url_via({@bn, _}, {:crypto, assets_kwl}) do
        url = "wss://stream.binance.#{@tld}:9443" <> get_assets_url_path(assets_kwl)
        via = MarketClient.get_via(@bn, assets_kwl, :ws)
        [{url, via, assets_kwl}]
      end

      @impl WsApi
      def ws_subscribe(res = %MarketClient.Resource{broker: {@bn, _}}) do
        sub_unsub_msg(res, "SUBSCRIBE")
      end

      @impl WsApi
      def ws_unsubscribe(res = %MarketClient.Resource{broker: {@bn, _}}) do
        sub_unsub_msg(res, "UNSUBSCRIBE")
      end

      defp get_assets_url_path([{dt, [{a, b}]}]) do
        "/ws/" <> get_pairs_string([{a, b}], get_channel(dt))
      end

      defp get_assets_url_path(assets_kwl) when is_list(assets_kwl) do
        for {dt, pairs} <- assets_kwl, reduce: "/stream?streams=" do
          str ->
            channel = get_channel(dt)
            str <> Enum.join(get_pairs_string(pairs, channel), "/")
        end
      end

      defp get_pairs_string(pairs, channel) do
        for {a, b} <- pairs, do: downcase(a <> b) <> channel
      end

      def get_assets_json_param({:crypto, assets_list}) do
        assets_list
        |> Enum.map(fn {a, b} -> downcase("#{a}/#{b}") end)
        |> Enum.join(",")
      end

      defp sub_unsub_msg(res = %MarketClient.Resource{watch: {:crypto, assets}}, action) do
        for assets_entry <- assets do
          case assets_entry do
            {dt, [{a, b}]} ->
              params = ~s/"#{downcase(a <> b) <> get_channel(dt)}"/
              ~s/{"id":1,"method":"#{action}","params":[#{params}]}/

            {dt, pairs} when length(pairs) > 1 ->
              c = get_channel(dt)
              params = for({a, b} <- pairs, do: ~s/"#{downcase(a <> b) <> c}"/) |> Enum.join(",")
              ~s/{"id":1,"method":"#{action}","params":[#{params}]}/
          end
        end
      end

      def get_channel(dt) do
        case dt do
          :quotes -> "@bookTicker"
          :ohlc_1minute -> "@kline_1m"
          :ohlc_3minute -> "@kline_3m"
          :ohlc_5minute -> "@kline_5m"
          :ohlc_15minute -> "@kline_15m"
          :ohlc_30minute -> "@kline_30m"
          :ohlc_1hour -> "@kline_1h"
          :ohlc_2hour -> "@kline_2h"
          :ohlc_4hour -> "@kline_4h"
          :ohlc_6hour -> "@kline_6h"
          :ohlc_8hour -> "@kline_8h"
          :ohlc_12hour -> "@kline_12h"
          :ohlc_1day -> "@kline_1d"
          :ohlc_3day -> "@kline_3d"
          :ohlc_1week -> "@kline_1w"
          :ohlc_1month -> "@kline_1M"
        end
      end
    end
  end
end
