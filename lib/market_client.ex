defmodule MarketClient do
  @moduledoc """
  Unified interface for sourcing historical and real-time market data from various brokers.
  """

  alias MarketClient.{
    Resource,
    Shared
  }

  require Logger

  @open_access_brokers [
    :binance,
    :binance_us,
    :coinbase_pro,
    :ftx,
    :ftx_us,
    :finnhub
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
  @valid_classes [:stock, :forex, :crypto]

  @type valid_data_type ::
          :quotes
          | :trades
          | :ohlc_1second
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
  @type url :: binary
  @type broker_name ::
          :binance | :binance_us | :coinbase_pro | :polygon | :oanda | :ftx_us | :ftx | :finnhub
  @type asset_class :: :crypto | :forex | :stock
  @type resource_id :: {transport_type | :buffer, broker_name, binary}
  @type via_tuple :: {:via, module, {module, resource_id}}
  @type equities_list :: list(binary)
  @type currencies_list :: list({binary, binary})
  @type assets_list :: equities_list | currencies_list
  @type equities_kwl :: list({valid_data_type, equities_list})
  @type currencies_kwl :: list({valid_data_type, currencies_list})
  @type assets_kwl :: list({valid_data_type, equities_list | currencies_list})
  @type class_asset_kwl ::
          {:stock, equities_kwl} | {:forex, currencies_kwl} | {:crypto, currencies_kwl}
  @type resource :: %Resource{
          broker: {broker_name, keyword},
          watch: class_asset_kwl
        }
  @type broker_opts :: keyword
  @type http_headers :: [{binary, binary}]
  @type http_conn_attrs :: {url, http_method, http_headers}
  @type http_method ::
          :get | :post | :put | :delete | :patch | :head | :options | :trace | :connect
  @type http_ok :: {:ok, Finch.Response.t()}
  @type http_error :: {:error, Mint.Types.error()}
  @type socket_state :: {:ok | :close, any} | {:reply | :close, any, any}
  @type transport_type :: :ws | :http
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

  @spec valid_data_types() :: list(valid_data_type)
  @spec validate(%Resource{watch: tuple, broker: tuple}) ::
          {:error, binary}
          | {:ok, %Resource{watch: tuple, broker: tuple}}
  @spec get_broker_module(resource) :: module
  @spec get_broker_module(resource, transport_type) :: module
  @spec get_broker_module(broker_name, :buffer) :: module
  @spec new(broker_arg, class_asset_kwl) :: {:ok, resource} | {:error, binary}
  @spec new(broker_arg, class_asset_kwl, keyword) :: {:ok, resource} | {:error, binary}
  @spec new!(broker_arg, class_asset_kwl) :: resource
  @spec new!(broker_arg, class_asset_kwl, keyword) :: resource
  @spec default_asset_id({asset_class, valid_data_type, assets_list}) :: list
  @spec default_asset_id({asset_class, valid_data_type, assets_list}, :list | :string) ::
          list | binary
  @spec ohlc_types() :: list(ohlc_type)
  @spec get_via(broker_name, any, transport_type | :buffer) :: via_tuple
  @spec res_id(broker_name, any, transport_type | :buffer) :: resource_id
  @spec start_link(resource) :: any
  @spec start_link(resource, keyword) :: any
  @spec ws_start(resource) :: list(MarketClient.DynamicSupervisor.on_start_child())
  @spec ws_stop(resource) :: any
  @spec ws_url_via({broker_name, broker_opts}, class_asset_kwl) ::
          list({binary, via_tuple, any})
  @spec http_start(resource) :: any
  @spec http_stop(resource) :: any
  @spec http_url(resource) :: any
  @spec http_method(resource) :: any
  @spec http_headers(resource) :: any
  @spec http_query_params(resource) :: any
  @spec ws_subscribe(resource) :: any
  @spec ws_unsubscribe(resource) :: any

  def ohlc_types, do: @ohlc_types
  def valid_data_types, do: @valid_data_types

  def get_broker_module(%Resource{broker: {broker_name, _}}) do
    Keyword.get(@broker_modules, broker_name, nil)
  end

  def get_broker_module(%Resource{broker: {broker_name, _}}, transport) do
    case transport do
      :ws -> Keyword.get(@broker_modules_ws, broker_name, nil)
      :http -> Keyword.get(@broker_modules_http, broker_name, nil)
    end
  end

  def get_broker_module(_, :buffer) do
    __MODULE__.Buffer
  end

  def new!(broker, assets, opts \\ []) do
    case new(broker, assets, opts) do
      {:ok, res} -> res
      {:error, msg} -> raise msg
    end
  end

  def new(broker_name, assets, opts \\ []) when is_list(opts) do
    case broker_name do
      b when b in @brokers ->
        if b in @open_access_brokers do
          %Resource{broker: {b, []}, options: opts, watch: assets} |> validate()
        else
          {:error, "broker #{inspect(b)} requires a key for access"}
        end

      {b, o} when b in @brokers and is_list(o) ->
        %Resource{broker: {b, o}, options: opts, watch: assets} |> validate()

      _ ->
        {:error, "received invalid first argument: #{inspect(broker_name)}"}
    end
  end

  def validate(res = %Resource{broker: {broker_name, _}, watch: watch}) do
    try do
      case watch do
        {class, kwl} ->
          if broker_name not in @brokers do
            raise "Invalid broker #{inspect(broker_name)}"
          end

          if class not in @valid_classes do
            raise "Invalid class #{inspect(class)}"
          end

          if not Enum.all?(kwl, fn item -> match?({_dt, _list}, item) end) do
            raise "Invalid assets list, at least one entry is not a keyword entry: #{inspect(kwl)}"
          end

          Enum.each(kwl, fn {data_type, _} ->
            if data_type not in @valid_data_types do
              raise "Invalid data type in assets list: #{inspect(data_type)}"
            end
          end)

        _ ->
          raise "Invalid assets defintion #{inspect(watch)}"
      end

      {:ok, res}
    rescue
      msg -> {:error, msg}
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

  def ws_url_via({broker_name, broker_opts}, {class, assets_kwl}) do
    @broker_modules_ws
    |> Keyword.get(broker_name, nil)
    |> apply(:ws_url_via, [{broker_name, broker_opts}, {class, assets_kwl}])
  end

  [
    :ws_start,
    :ws_stop,
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

  def default_asset_id({_, _, asset_list}, type \\ :list) do
    list =
      for asset <- asset_list do
        case asset do
          {a, b} -> ~s|"#{a}/#{b}"| |> String.upcase()
          name when is_binary(name) -> ~s|"#{name}"| |> String.upcase()
        end
      end

    case type do
      :list -> list
      :string -> list |> Enum.join(",")
    end
  end

  def get_via(broker_name, assets, type) do
    {:via, Registry, {MarketClient.Registry, res_id(broker_name, assets, type)}}
  end

  def res_id(broker_name, assets, transport) do
    {transport, broker_name, Shared.term_to_hash(assets)}
  end

  @spec validate_pairs_list(list) :: boolean
  def validate_pairs_list(list) do
    Enum.all?(list, fn e ->
      is_tuple(e) and is_binary(elem(e, 0)) and is_binary(elem(e, 1))
    end)
  end
end
