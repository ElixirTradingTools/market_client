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

  @spec pid_tuple(Resource.t(), :ws | :http) :: {:ws | :http, atom, term}

  def pid_tuple(%Resource{broker: {broker, _}, asset_id: asset_id}, type) do
    {type, broker, asset_id}
  end

  @spec get_broker_module(Resource.t()) :: module

  def get_broker_module(%Resource{broker: {broker_name, _}}) do
    Keyword.get(@broker_modules, broker_name, nil)
  end

  @spec new(atom, {atom, binary | {atom, atom}}, function) :: Resource.t()

  def new(broker, asset_id, listener) when broker in @brokers do
    new({broker, nil}, asset_id, listener, nil)
  end

  @spec new({atom, term}, {atom, binary | {atom, atom}}, function) :: Resource.t()

  def new(broker = {name, _}, asset_id, listener)
      when is_tuple(asset_id) and is_function(listener) and name in @brokers do
    new(broker, asset_id, listener, nil)
  end

  @spec new(atom, {atom, binary | {atom, atom}}, function, map | nil) :: Resource.t()

  def new(broker, asset_id, listener, opts) when broker in @brokers do
    new({broker, nil}, asset_id, listener, opts)
  end

  @spec new({atom, term}, {atom, binary | {atom, atom}}, function, map | nil) :: Resource.t()

  def new(broker = {name, _}, asset_id, listener, opts)
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
    :start_ws,
    :stop_ws,
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

  # def start_link([res = %Resource{}]) do
  #   res
  #   |> get_broker_module
  #   |> apply(:start_link, [res])
  # end

  # def start_link([res = %Resource{}, debug]) when is_boolean(debug) do
  #   res
  #   |> get_broker_module
  #   |> apply(:start_link, [res, debug])
  # end

  ###################

  # [
  #   :start,
  #   :stop
  # ]
  # |> Enum.each(fn func_name ->
  #   def unquote(func_name)(pid, res = %Resource{}) do
  #     res
  #     |> get_broker_module
  #     |> apply(unquote(func_name), [pid, res])
  #   end
  # end)

  # def start(pid, res = %Resource{}, other) do
  #   res
  #   |> get_broker_module
  #   |> apply(:start, [pid, res, other])
  # end
end
