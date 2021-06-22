defmodule MarketClient.Behaviors.FtxWs do
  @moduledoc """
  Reusable WsApi implementation for FTX & FTX US broker modules.
  """
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

      @tld to_string(unquote(tld))
      @bn unquote(broker_name)

      @spec get_channel(atom) :: binary

      @impl WsApi
      def ws_url_via({@bn, _}, {:crypto, assets_kwl}) do
        url = "wss://ftx.#{@tld}/ws/"
        via = MarketClient.get_via(@bn, assets_kwl, :ws)
        [{url, via, assets_kwl}]
      end

      @impl WsApi
      def ws_subscribe(res = %MarketClient.Resource{broker: {@bn, _}, watch: {:crypto, kwl}}) do
        for {dt, list} <- kwl, reduce: [] do
          msgs ->
            chan = get_channel(dt)

            for m <- ws_asset_id({:crypto, dt, list}), reduce: msgs do
              msgs -> msgs ++ [~s/{"op":"subscribe","channel":#{chan},"market":#{m}}/]
            end
        end
      end

      @impl WsApi
      def ws_unsubscribe(%MarketClient.Resource{broker: {@bn, _}, watch: {:crypto, kwl}}) do
        for {dt, list} <- kwl do
          chan = get_channel(dt)
          params = ws_asset_id({:crypto, dt, list})
          ~s/{"op":"unsubscribe","channel":#{chan},"market":[#{params}]}/
        end
      end

      def get_channel(dt) do
        case dt do
          :quotes -> ~s/"ticker"/
          :trades -> ~s/"trades"/
          dt when dt in @ohlc_types -> raise "OHLC data not supported"
        end
      end
    end
  end
end
