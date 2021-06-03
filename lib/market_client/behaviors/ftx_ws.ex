defmodule MarketClient.Behaviors.FtxWs do
  defmacro __using__([tld]) when tld in [:us, :com] do
    alias MarketClient.Shared

    unless Shared.is_broker_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.Ftx is not a public module"
    end

    broker_name = if(tld == :us, do: :ftx_us, else: :ftx)

    quote do
      alias MarketClient.{
        Behaviors.WsApi,
        Shared
      }

      use WsApi

      @spec get_channel({atom, atom, any}) :: binary

      @impl WsApi
      def ws_url(%MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        "wss://ftx.#{to_string(unquote(tld))}/ws/"
      end

      @impl WsApi
      def ws_subscribe(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        chan = get_channel(res.asset_id)
        market = ws_asset_id(res.asset_id)
        ~s({"op":"subscribe","channel":"#{chan}","market":"#{market}"})
      end

      @impl WsApi
      def ws_unsubscribe(res = %MarketClient.Resource{broker: {unquote(broker_name), _}}) do
        chan = get_channel(res.asset_id)
        params = ws_asset_id(res.asset_id)
        ~s({"op":"unsubscribe","channel":"#{chan}","market":"#{params}"})
      end

      def get_channel({:crypto, :full_tick, _}), do: "ticker"
      def get_channel({:crypto, :trades, _}), do: "trades"
    end
  end
end
