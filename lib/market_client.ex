defmodule MarketClient do
  alias MarketClient.Resource

  @broker_modules [
    binance: MarketClient.Broker.Binance,
    binance_us: MarketClient.Broker.BinanceUs,
    coinbase: MarketClient.Broker.Coinbase,
    polygon: MarketClient.Broker.Polygon,
    oanda: MarketClient.Broker.Oanda,
    ftx_us: MarketClient.Broker.FtxUs,
    ftx: MarketClient.Broker.Ftx
  ]

  @brokers Enum.map(@broker_modules, fn {a, _} -> a end)

  @type url :: binary
  @type broker_name :: :binance | :binance_us | :coinbase | :polygon | :oanda | :ftx_us | :ftx
  @type via_tuple :: {:via, module, any}
  @type asset_id :: {atom, atom, binary | {atom, atom}}
  @type broker_opts :: [{atom, binary}]
  @type http_headers :: [{binary, binary}]
  @type http_conn_attrs :: {url, http_method, http_headers, function}
  @type http_method ::
          :get | :post | :put | :delete | :patch | :head | :options | :trace | :connect

  @spec pid_tuple(Resource.t(), :ws | :http) :: {:ws | :http, atom, any}
  @spec get_broker_module(Resource.t()) :: module
  @spec new(broker_name, asset_id, function) :: Resource.t()
  @spec new(broker_name, asset_id, function, keyword) :: Resource.t()
  @spec new({broker_name, broker_opts}, asset_id, function) :: Resource.t()
  @spec new({broker_name, broker_opts}, asset_id, function, keyword) :: Resource.t()
  @spec get_resource({broker_name, broker_opts}, asset_id, function, keyword) :: Resource.t()
  @spec default_asset_id(asset_id) :: binary

  @spec start_link(Resource.t()) :: any
  @spec ws_start(Resource.t()) :: any
  @spec ws_stop(Resource.t()) :: any
  @spec ws_asset_id(Resource.t()) :: any
  @spec ws_url(Resource.t()) :: any
  @spec http_start(Resource.t()) :: any
  @spec http_stop(Resource.t()) :: any
  @spec http_url(Resource.t()) :: any
  @spec http_method(Resource.t()) :: any
  @spec http_headers(Resource.t()) :: any
  @spec http_query_params(Resource.t()) :: any
  @spec ws_subscribe(Resource.t()) :: any
  @spec ws_unsubscribe(Resource.t()) :: any

  def pid_tuple(%Resource{broker: {broker, _}, asset_id: asset_id}, transport_type) do
    {transport_type, broker, asset_id}
  end

  def get_broker_module(%Resource{broker: {broker_name, _}}) do
    Keyword.get(@broker_modules, broker_name, nil)
  end

  def new(broker, asset = {class, data_type, _}, listener, opts \\ [])
      when is_atom(class) and is_atom(data_type) and is_function(listener) do
    case broker do
      b when b in @brokers -> get_resource({broker, []}, asset, listener, opts)
      {b, o} when b in @brokers and is_list(o) -> get_resource({b, o}, asset, listener, opts)
      _ -> raise "MarketClient.new/4 received invalid first argument"
    end
  end

  defp get_resource(broker, asset_id, listener, opts) when is_function(listener) do
    %Resource{broker: broker, asset_id: asset_id, listener: listener, options: opts}
  end

  [
    :start_link,
    :ws_start,
    :ws_stop,
    :ws_asset_id,
    :ws_url,
    :ws_via_tuple,
    :http_start,
    :http_stop,
    :http_fetch,
    :http_url,
    :http_method,
    :http_headers,
    :http_via_tuple,
    :http_query_params,
    :ws_subscribe,
    :ws_unsubscribe
  ]
  |> Enum.each(fn func_name ->
    def unquote(func_name)(res = %Resource{}) do
      res
      |> get_broker_module()
      |> apply(unquote(func_name), [res])
    end
  end)

  def default_asset_id({_, _, asset_name}) do
    case asset_name do
      name when is_binary(name) -> name
      {a, b} -> "#{to_string(a)}/#{to_string(b)}"
    end
  end
end
