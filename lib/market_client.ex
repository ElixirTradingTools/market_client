defmodule MarketClient do
  @moduledoc """
  Unified interface for sourcing historical and real-time market data from various brokers.
  """

  alias MarketClient.Resource
  require Logger

  @open_access_brokers [
    :binance,
    :binance_us,
    :coinbase_pro,
    :ftx,
    :ftx_us
  ]

  @broker_modules [
    finnhub: MarketClient.Broker.Finnhub,
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

  @ohlc_types [
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

  @valid_data_types [:quotes, :trades] ++ @ohlc_types
  @valid_asset_classes [:stock, :forex, :crypto]

  @type url :: binary
  @type broker_name :: :binance | :binance_us | :coinbase_pro | :polygon | :oanda | :ftx_us | :ftx
  @type via_tuple :: {:via, module, {module, tuple}}
  @type asset_id :: {atom, atom, binary | {binary, binary}}
  @type broker_opts :: [{atom, binary}]
  @type http_headers :: [{binary, binary}]
  @type http_conn_attrs :: {url, http_method, http_headers}
  @type http_method ::
          :get | :post | :put | :delete | :patch | :head | :options | :trace | :connect
  @type http_ok :: {:ok, Finch.Response.t()}
  @type http_error :: {:error, Mint.Types.error()}
  @type socket_state :: {:ok | :close, any} | {:reply | :close, any, any}
  @type transport_type :: nil | :ws | :http | :buffer
  @type broker_arg :: broker_name | {broker_name, broker_opts}
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

  @spec validate(Resource.t()) :: {:ok, Resource.t()} | {:error, binary}
  @spec res_id(Resource.t(), transport_type) :: {transport_type, atom, any}
  @spec get_broker_module(Resource.t()) :: module
  @spec get_broker_module(Resource.t(), transport_type) :: module
  @spec get_broker_module(broker_name, :buffer) :: module
  @spec new(broker_arg, asset_id) :: {:ok, Resource.t()} | {:error, binary}
  @spec new(broker_arg, asset_id, keyword) :: {:ok, Resource.t()} | {:error, binary}
  @spec new!(broker_arg, asset_id) :: Resource.t()
  @spec new!(broker_arg, asset_id, keyword) :: Resource.t()
  @spec stream({atom, any}) :: {atom, any} | Stream.t()
  @spec stream(Resource.t()) :: Stream.t()
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

  def ohlc_types, do: @ohlc_types
  def valid_data_types, do: @valid_data_types
  def valid_asset_classes, do: @valid_asset_classes

  def get_broker_module(%Resource{broker: {broker_name, _}}) do
    Keyword.get(@broker_modules, broker_name, nil)
  end

  def get_broker_module(%Resource{broker: {broker_name, _}}, transport) do
    case transport do
      :ws -> Keyword.get(@broker_modules_ws, broker_name, nil)
      :http -> Keyword.get(@broker_modules_http, broker_name, nil)
    end
  end

  def get_broker_module(broker_name, :buffer) when broker_name in @brokers do
    Keyword.get(@broker_modules_buffer, broker_name, nil)
  end

  def new(broker, asset = {class, data_type, _}, opts \\ [])
      when class in @valid_asset_classes and data_type in @valid_data_types and is_list(opts) do
    case broker do
      b when b in @brokers ->
        if b in @open_access_brokers do
          %Resource{broker: {broker, []}, asset_id: asset, options: opts}
          |> validate()
        else
          {:error, "broker #{inspect(b)} requires a key for access"}
        end

      {b, o} when b in @brokers and is_list(o) ->
        %Resource{broker: {b, o}, asset_id: asset, options: opts}
        |> validate()

      b ->
        {:error, "received invalid first argument: #{inspect(b)}"}
    end
  end

  def new!(broker, asset, opts \\ []) do
    case new(broker, asset, opts) do
      {:ok, res} -> res
      {:error, msg} -> raise msg
    end
    |> validate()
    |> case do
      {:ok, res} -> res
      {:error, reason} -> raise reason
    end
  end

  def stream({code, res}) do
    case {code, res} do
      {:ok, %Resource{}} -> stream(res)
      _ -> {code, res}
    end
  end

  def stream(res = %Resource{broker: {broker_name, _}}) do
    via = get_via(broker_name, :buffer)

    Stream.resource(
      fn -> start(res) end,
      fn acc ->
        case GenServer.call(via, :drain, :infinity) do
          {:messages, list} ->
            {list, acc}

          {:error, reason} ->
            Logger.warn("Stream closed due to error: #{reason}")
            {:halt, acc}
        end
      end,
      fn _ -> nil end
    )
  end

  [
    :start_link,
    :start,
    :stop,
    :validate
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
      {a, b} -> "#{String.upcase(a)}/#{String.upcase(b)}"
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
