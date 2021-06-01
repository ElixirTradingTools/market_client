defmodule MarketClient.Behaviors.Ftx do
  defmacro __using__([tld]) when tld in [:us, :com] do
    alias MarketClient.Shared

    unless Shared.is_vendor_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.Ftx is not a public module"
    end

    vendor_name = if(tld == :us, do: :ftx_us, else: :ftx)

    quote do
      alias MarketClient.{
        Behaviors.HttpApi,
        Behaviors.WsApi,
        Shared
      }

      use WsApi
      use HttpApi

      @spec get_channel({atom, atom, any}) :: binary

      # -- WebSocket -- #

      @impl WsApi
      def ws_url(%MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
        "wss://ftx.#{to_string(unquote(tld))}/ws/"
      end

      @impl WsApi
      def msg_subscribe(res = %MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
        chan = get_channel(res.asset_id)
        market = get_asset_id(res.asset_id)
        ~s({"op":"subscribe","channel":"#{chan}","market":"#{market}"})
      end

      @impl WsApi
      def msg_unsubscribe(res = %MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
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
      def http_url(res = %MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
        "https://ftx.us/api/markets/#{get_asset_id(res.asset_id)}/candles?#{http_query_params(res)}"
      end

      @impl HttpApi
      def http_query_params(%MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
        "resolution=60&limit=10&start_time=0&end_time=#{Shared.unix_now(:sec)}"
      end

      @impl HttpApi
      def http_headers(%MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
        []
      end

      @impl HttpApi
      def http_method(%MarketClient.Resource{vendor: {unquote(vendor_name), _}}) do
        :get
      end
    end
  end
end
