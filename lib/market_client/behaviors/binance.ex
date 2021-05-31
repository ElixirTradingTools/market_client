defmodule MarketClient.Behaviors.Binance do
  defmacro __using__([tld]) when tld in [:us, :com] do
    alias MarketClient.Shared

    unless Shared.is_vendor_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.Binance is not a public module"
    end

    vendor_name = if(tld == :us, do: :binance_us, else: :binance)

    quote do
      alias MarketClient.{
        Behaviors.WsApi,
        Shared
      }

      use WsApi

      @impl WsApi
      def ws_url(res = %MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
        asset_pair = get_asset_pair(res.asset_id)
        tld = to_string(unquote(tld))
        "wss://stream.binance.#{tld}:9443/ws/#{asset_pair}"
      end

      def get_asset_pair({:crypto, _, {a, b}}) do
        "#{Shared.a2s_downcased(a)}#{Shared.a2s_downcased(b)}"
      end

      @impl WsApi
      def get_asset_id(asset_id = {:crypto, data_type, _}) do
        suffix =
          case data_type do
            :ohlcv_1min -> "1m"
            :ohlcv_3min -> "3m"
            :ohlcv_5min -> "5m"
            :ohlcv_15min -> "15m"
            :ohlcv_30min -> "30m"
            :ohlcv_1hour -> "1h"
            :ohlcv_2hour -> "2h"
            :ohlcv_4hour -> "4h"
            :ohlcv_6hour -> "6h"
            :ohlcv_8hour -> "8h"
            :ohlcv_12hour -> "12h"
            :ohlcv_1day -> "1d"
            :ohlcv_3day -> "3d"
            :ohlcv_1week -> "1w"
            :ohlcv_1month -> "1M"
          end

        "#{get_asset_pair(asset_id)}@kline_#{suffix}"
      end

      @impl WsApi
      def msg_subscribe(res = %MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
        ~s({"id":1,"method":"SUBSCRIBE","params":["#{get_asset_id(res.asset_id)}"]})
      end

      @impl WsApi
      def msg_unsubscribe(res = %MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
        ~s({"id":1,"method":"UNSUBSCRIBE","params":["#{get_asset_id(res.asset_id)}"]})
      end
    end
  end
end
