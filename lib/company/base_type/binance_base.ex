defmodule MarketClient.Company.BaseType.Binance do
  @allowed_callers [
    MarketClient.Company.BinanceGlobal,
    MarketClient.Company.BinanceUs
  ]

  defmacro __using__([tld]) when tld in [:us, :com] do
    unless __CALLER__.module in @allowed_callers do
      raise "WsApi is only for internal use"
    end

    quote do
      alias MarketClient.{
        Company.BaseType.WsApi,
        Shared
      }

      use WsApi

      @impl WsApi
      def url(res = %MarketClient.Resource{}) do
        "wss://stream.binance.#{unquote(tld) |> to_string()}:9443/ws/#{get_asset_pair(res)}"
      end

      @impl WsApi
      def get_asset_pair(%MarketClient.Resource{asset_id: {:crypto, {c1, c2}}})
          when is_atom(c1) and is_atom(c2) do
        "#{Shared.upcase_atom(c1)}#{Shared.upcase_atom(c2)}"
      end

      @impl WsApi
      def format_asset_id(res = %MarketClient.Resource{}) do
        "#{get_asset_pair(res)}@bookTicker"
      end

      @impl WsApi
      def msg_subscribe(res = %MarketClient.Resource{}) do
        %{
          "id" => 1,
          "method" => "SUBSCRIBE",
          "params" => [format_asset_id(res)]
        }
        |> Jason.encode!()
      end

      @impl WsApi
      def msg_unsubscribe(res = %MarketClient.Resource{}) do
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
