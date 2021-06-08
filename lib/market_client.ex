defmodule MarketClient do
  @moduledoc """
  Unified interface for sourcing historical and real-time market data from various brokers.
  """

  alias MarketClient.Resource
  require Logger

  @broker_modules [
    binance: MarketClient.Broker.Binance,
    binance_us: MarketClient.Broker.BinanceUs,
    coinbase_pro: MarketClient.Broker.CoinbasePro,
    polygon: MarketClient.Broker.Polygon,
    oanda: MarketClient.Broker.Oanda,
    ftx_us: MarketClient.Broker.FtxUs,
    ftx: MarketClient.Broker.Ftx
  ]

  @broker_modules_ws Enum.map(@broker_modules, fn {k, m} ->
                       {k, Module.concat([m, "Ws"])}
                     end)

  @broker_modules_http Enum.map(@broker_modules, fn {k, m} ->
                         {k, Module.concat([m, "Http"])}
                       end)

  @broker_modules_buffer Enum.map(@broker_modules, fn {k, m} ->
                           {k, Module.concat([m, "Buffer"])}
                         end)

  @brokers Enum.map(@broker_modules, fn {a, _} -> a end)

  @type url :: binary
  @type broker_name :: :binance | :binance_us | :coinbase_pro | :polygon | :oanda | :ftx_us | :ftx
  @type via_tuple :: {:via, module, {module, tuple}}
  @type asset_id :: {atom, atom, binary | {atom, atom}}
  @type broker_opts :: [{atom, binary}]
  @type http_headers :: [{binary, binary}]
  @type http_conn_attrs :: {url, http_method, http_headers}
  @type http_method ::
          :get | :post | :put | :delete | :patch | :head | :options | :trace | :connect
  @type http_ok :: {:ok, Finch.Response.t()}
  @type http_error :: {:error, Mint.Types.error()}
  @type socket_state :: {:ok | :close, any} | {:reply | :close, any, any}
  @type transport_type :: nil | :ws | :http | :buffer
  @type ohlc_type ::
          :ohlc_1second
          | :ohlc_10second
          | :ohlc_15second
          | :ohlc_30second
          | :ohlc_1minute
          | :ohlc_2minute
          | :ohlc_3minute
          | :ohlc_4minute
          | :ohlc_5minute
          | :ohlc_10minute
          | :ohlc_15minute
          | :ohlc_30minute
          | :ohlc_1hour
          | :ohlc_2hour
          | :ohlc_3hour
          | :ohlc_4hour
          | :ohlc_6hour
          | :ohlc_8hour
          | :ohlc_12hour
          | :ohlc_1day
          | :ohlc_3day
          | :ohlc_1week
          | :ohlc_1month

  @spec res_id(Resource.t(), transport_type) :: {transport_type, atom, any}
  @spec get_broker_module(Resource.t(), transport_type) :: module
  @spec new(broker_name, asset_id) :: Stream.t()
  @spec new(broker_name, asset_id, keyword) :: Stream.t()
  @spec new({broker_name, broker_opts}, asset_id) :: Stream.t()
  @spec new({broker_name, broker_opts}, asset_id, keyword) :: Stream.t()
  @spec get_resource({broker_name, broker_opts}, asset_id, keyword) :: Stream.t()
  @spec default_asset_id(asset_id) :: binary
  @spec ohlc_types() :: [ohlc_type]

  @spec get_via(broker_name, :buffer) :: via_tuple
  @spec get_via(Resource.t(), transport_type) :: via_tuple
  @spec start_link(Resource.t()) :: any
  @spec start_link(Resource.t(), keyword) :: any
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

  def ohlc_types do
    [
      :ohlc_1second,
      :ohlc_10second,
      :ohlc_15second,
      :ohlc_30second,
      :ohlc_1minute,
      :ohlc_2minute,
      :ohlc_3minute,
      :ohlc_4minute,
      :ohlc_5minute,
      :ohlc_10minute,
      :ohlc_15minute,
      :ohlc_30minute,
      :ohlc_1hour,
      :ohlc_2hour,
      :ohlc_3hour,
      :ohlc_4hour,
      :ohlc_6hour,
      :ohlc_8hour,
      :ohlc_12hour,
      :ohlc_1day,
      :ohlc_3day,
      :ohlc_1week,
      :ohlc_1month
    ]
  end

  def new(broker, asset = {class, data_type, _}, opts \\ [])
      when is_atom(class) and is_atom(data_type) and is_list(opts) do
    case broker do
      b when b in @brokers -> get_resource({broker, []}, asset, opts)
      {b, o} when b in @brokers and is_list(o) -> get_resource({b, o}, asset, opts)
      _ -> raise "MarketClient.new/4 received invalid first argument"
    end
  end

  def get_broker_module(%Resource{broker: {broker_name, _}}, transport \\ nil) do
    case transport do
      nil -> Keyword.get(@broker_modules, broker_name, nil)
      :ws -> Keyword.get(@broker_modules_ws, broker_name, nil)
      :http -> Keyword.get(@broker_modules_http, broker_name, nil)
      :buffer -> Keyword.get(@broker_modules_buffer, broker_name, nil)
    end
  end

  defp get_resource(broker = {broker_name, _}, asset_id, opts) when is_list(opts) do
    res = %Resource{broker: broker, asset_id: asset_id, options: opts}
    via = get_via(broker_name, :buffer)

    Stream.resource(
      fn -> start(res) end,
      fn acc -> stream_resource_iterator(via, acc) end,
      fn _ -> nil end
    )
  end

  defp stream_resource_iterator(via, accumulator) do
    case GenServer.call(via, :drain, :infinity) do
      {:messages, list} ->
        {list, accumulator}

      {:error, reason} ->
        Logger.warn("Stream closed due to error: #{reason}")
        {:halt, accumulator}
    end
  end

  [
    :start_link,
    :start,
    :stop
  ]
  |> Enum.each(fn func_name ->
    def unquote(func_name)(res = %Resource{}) do
      res
      |> get_broker_module()
      |> apply(unquote(func_name), [res])
    end
  end)

  [
    :start_link
  ]
  |> Enum.each(fn func_name ->
    def unquote(func_name)(res = %Resource{}, opts) do
      res
      |> get_broker_module()
      |> apply(unquote(func_name), [res, opts])
    end
  end)

  [
    :ws_start,
    :ws_stop,
    :ws_asset_id,
    :ws_url,
    :ws_subscribe,
    :ws_unsubscribe
  ]
  |> Enum.each(fn func_name ->
    def unquote(func_name)(res = %Resource{}) do
      res
      |> get_broker_module(:ws)
      |> apply(unquote(func_name), [res])
    end
  end)

  [
    :http_start,
    :http_stop,
    :http_fetch,
    :http_url,
    :http_method,
    :http_headers,
    :http_query_params
  ]
  |> Enum.each(fn func_name ->
    def unquote(func_name)(res = %Resource{}) do
      res
      |> get_broker_module(:http)
      |> apply(unquote(func_name), [res])
    end
  end)

  def default_asset_id({_, _, asset_name}) do
    case asset_name do
      name when is_binary(name) -> name
      {a, b} -> "#{to_string(a)}/#{to_string(b)}"
    end
  end

  def get_via(broker, :buffer) when broker in @brokers do
    {:via, Registry, {MarketClient.Registry, {broker, :buffer}}}
  end

  def get_via(res = %Resource{}, transport) when transport in [:ws, :http] do
    {:via, Registry, {MarketClient.Registry, res_id(res, transport)}}
  end

  def res_id(%Resource{broker: {broker, _}, asset_id: asset_id}, transport) do
    {transport, broker, asset_id}
  end
end
