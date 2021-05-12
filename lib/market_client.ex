defmodule MarketClient do
  alias MarketClient.Resource

  @broker_modules [
    binance_global: MarketClient.Company.BinanceGlobal,
    binance_us: MarketClient.Company.BinanceUs,
    coinbase: MarketClient.Company.Coinbase,
    polygon: MarketClient.Company.Polygon,
    ftx_us: MarketClient.Company.FtxUs,
    oanda: MarketClient.Company.Oanda
  ]

  @brokers Enum.map(@broker_modules, fn {a, _} -> a end)

  def get_broker_module(%Resource{broker: {broker_name, _}}) do
    Keyword.get(@broker_modules, broker_name, nil)
  end

  def new(broker = {name, _}, asset_id, listener, opts \\ nil)
      when is_tuple(asset_id) and is_function(listener) and name in @brokers do
    %Resource{
      broker: broker,
      asset_id: asset_id,
      listener: listener,
      options: opts
    }
  end

  [:start_link, :format_asset_id, :url, :msg_subscribe, :msg_unsubscribe]
  |> Enum.each(fn func_name ->
    def unquote(func_name)(res = %Resource{}) do
      res
      |> get_broker_module()
      |> apply(unquote(func_name), [res])
    end
  end)

  [:start, :stop]
  |> Enum.each(fn func_name ->
    def unquote(func_name)(pid, res = %Resource{}) do
      res
      |> get_broker_module()
      |> apply(unquote(func_name), [pid, res])
    end
  end)

  def start(pid, res = %Resource{}, other) do
    res
    |> get_broker_module()
    |> apply(:start, [pid, res, other])
  end
end
