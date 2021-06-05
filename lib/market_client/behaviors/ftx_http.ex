defmodule MarketClient.Behaviors.FtxHttp do
  defmacro __using__([tld]) when tld in [:us, :com] do
    alias MarketClient.Shared

    unless Shared.is_broker_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.Ftx is not a public module"
    end

    broker_name = if(tld == :us, do: :ftx_us, else: :ftx)

    quote do
      alias MarketClient.{
        Behaviors.HttpApi,
        Shared
      }

      use HttpApi

      @spec http_query_params(MarketClient.Resource.t()) :: binary

      @impl HttpApi
      def http_url(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        query = http_query_params(res)
        asset_id = http_asset_id(res.asset_id)
        "https://ftx.us/api/markets/#{asset_id}/candles?#{query}"
      end

      @impl HttpApi
      def http_headers(%MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        []
      end

      @impl HttpApi
      def http_method(%MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        :get
      end

      def http_query_params(%MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        "resolution=60&limit=10&start_time=0&end_time=#{Shared.unix_now(:sec)}"
      end
    end
  end
end
