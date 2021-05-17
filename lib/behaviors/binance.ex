defmodule MarketClient.Behaviors.Binance do
  defmacro __using__([tld]) when tld in [:us, :com] do
    alias MarketClient.Shared

    unless Shared.is_vendor_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.Binance is not a public module"
    end

    broker_name = if(tld == :us, do: :binance_us, else: :binance_global)

    quote do
      alias MarketClient.{
        Behaviors.WsApi,
        Shared
      }

      use WsApi

      @impl WsApi
      def ws_url(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        "wss://stream.binance.#{unquote(tld) |> to_string()}:9443/ws/#{get_asset_pair(res)}"
      end

      @impl WsApi
      def get_asset_pair(%MarketClient.Resource{
            broker: {unquote(broker_name), _},
            asset_id: {:crypto, {c1, c2}}
          })
          when is_atom(c1) and is_atom(c2) do
        "#{Shared.a2s_downcased(c1)}#{Shared.a2s_downcased(c2)}"
      end

      @impl WsApi
      def format_asset_id(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        "#{get_asset_pair(res)}@kline_1m"
      end

      @impl WsApi
      def msg_subscribe(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        %{
          "id" => 1,
          "method" => "SUBSCRIBE",
          "params" => [format_asset_id(res)]
        }
        |> Jason.encode!()
      end

      @impl WsApi
      def msg_unsubscribe(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        %{
          "id" => 1,
          "method" => "UNSUBSCRIBE",
          "params" => [format_asset_id(res)]
        }
        |> Jason.encode!()
      end
    end
  end
end
