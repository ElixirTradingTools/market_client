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
      alias MarketClient.{
        Behaviors.WsApi,
        Shared
      }

      use WsApi, [unquote(broker_name)]

      @spec get_start_stop_json_payload(MarketClient.Resource.t(), binary) :: binary
      @spec start(MarketClient.Resource.t()) :: :ok

      def start(res = %MarketClient.Resource{}), do: ws_start(res)

      @impl WsApi
      def ws_url(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        tld = to_string(unquote(tld))
        "wss://stream.binance.#{tld}:9443/ws/" <> get_asset_pair(res.asset_id)
      end

      @impl WsApi
      def ws_subscribe(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        get_start_stop_json_payload(res, "SUBSCRIBE")
      end

      @impl WsApi
      def ws_unsubscribe(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        get_start_stop_json_payload(res, "UNSUBSCRIBE")
      end

      def get_asset_pair({:crypto, _, {a, b}}) do
        "#{Shared.a2s_downcased(a)}#{Shared.a2s_downcased(b)}"
      end

      defp get_start_stop_json_payload(res, method) do
        params = get_asset_pair(res.asset_id) <> get_channel(res.asset_id)
        ~s({"id":1,"method":"#{method}","params":["#{params}"]})
      end

      def get_channel({:crypto, :quotes, _}), do: "@bookTicker"
      def get_channel({:crypto, :ohlc_1minute, _}), do: "@kline_1m"
      def get_channel({:crypto, :ohlc_3minute, _}), do: "@kline_3m"
      def get_channel({:crypto, :ohlc_5minute, _}), do: "@kline_5m"
      def get_channel({:crypto, :ohlc_15minute, _}), do: "@kline_15m"
      def get_channel({:crypto, :ohlc_30minute, _}), do: "@kline_30m"
      def get_channel({:crypto, :ohlc_1hour, _}), do: "@kline_1h"
      def get_channel({:crypto, :ohlc_2hour, _}), do: "@kline_2h"
      def get_channel({:crypto, :ohlc_4hour, _}), do: "@kline_4h"
      def get_channel({:crypto, :ohlc_6hour, _}), do: "@kline_6h"
      def get_channel({:crypto, :ohlc_8hour, _}), do: "@kline_8h"
      def get_channel({:crypto, :ohlc_12hour, _}), do: "@kline_12h"
      def get_channel({:crypto, :ohlc_1day, _}), do: "@kline_1d"
      def get_channel({:crypto, :ohlc_3day, _}), do: "@kline_3d"
      def get_channel({:crypto, :ohlc_1week, _}), do: "@kline_1w"
      def get_channel({:crypto, :ohlc_1month, _}), do: "@kline_1M"
    end
  end
end
