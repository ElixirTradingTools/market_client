defmodule MarketClient do
  alias MarketClient.Resource

  @broker_modules [
    binance_global: MarketClient.Vendor.BinanceGlobal,
    binance_us: MarketClient.Vendor.BinanceUs,
    coinbase: MarketClient.Vendor.Coinbase,
    polygon: MarketClient.Vendor.Polygon,
    ftx_us: MarketClient.Vendor.FtxUs,
    oanda: MarketClient.Vendor.Oanda
  ]

  @brokers Enum.map(@broker_modules, fn {a, _} -> a end)

  @spec get_broker_module(Resource.t()) :: module()

  def child_spec(_) do
    [
      {Finch, name: MarketClient.Transport.Http},
      {MarketClient.Transport.Ws, []}
    ]
  end

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

  [
    :start_link,
    :format_asset_id,
    :ws_url,
    :http_fetch,
    :http_url,
    :http_method,
    :http_headers,
    :http_query_params,
    :msg_subscribe,
    :msg_unsubscribe
  ]
  |> Enum.each(fn func_name ->
    def unquote(func_name)(res = %Resource{}) do
      res
      |> get_broker_module()
      |> apply(unquote(func_name), [res])
    end
  end)

  def start_link(res = %Resource{}, debug \\ false) do
    res
    |> get_broker_module()
    |> apply(:start_link, [res, debug])
  end

  [
    :start,
    :stop
  ]
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
