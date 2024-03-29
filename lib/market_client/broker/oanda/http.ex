defmodule MarketClient.Broker.Oanda.Http do
  @moduledoc false
  @doc """
  HTTP client for oanda.com.
  """
  alias MarketClient.{
    Behaviors.HttpApi,
    Resource
  }

  use HttpApi, [:oanda]
  use GenServer

  @ohlc_types MarketClient.ohlc_types()

  @type state_map :: %{
          polling_interval: nil | integer,
          resource: Resource.t(),
          method: MarketClient.http_method(),
          headers: MarketClient.http_headers()
        }
  @spec get_path(MarketClient.asset_id(), any) :: binary
  @spec get_path_params(Resource.t()) :: binary
  @spec get_channel(MarketClient.asset_id() | atom) :: binary
  @spec get_ms_delta(MarketClient.asset_id() | atom) :: integer
  @spec poll(state_map) :: {:noreply, state_map}
  @spec init(Resource.t()) :: {:ok, state_map}

  ### HTTP Polling Worker ###

  def start_link([res = %Resource{}]) do
    GenServer.start_link(__MODULE__, res, name: MarketClient.get_via(res, :http))
  end

  @impl true
  def init(res = %Resource{}) do
    {_, method, headers} = get_url_method_headers(res)

    {:ok,
     %{
       polling_interval: nil,
       resource: res,
       method: method,
       headers: headers
     }}
  end

  @impl true
  def handle_info(:poll, state), do: poll(state)

  @impl true
  def handle_cast(:start, %{polling_interval: nil, resource: res} = state) do
    with {:forex, :quotes, pair} = res.asset_id do
      res
      |> Map.put(:asset_id, {:forex, :first_tick, pair})
      |> get_url_method_headers()
      |> http_fetch(fn _ ->
        nil
      end)
    end

    state
    |> Map.put(:polling_interval, get_ms_delta(:quotes))
    |> poll()
  end

  @impl true
  def handle_cast(:stop, state), do: {:stop, :normal, Map.put(state, :polling_interval, nil)}

  defp poll(%{polling_interval: i, resource: r, method: m, headers: h} = state) do
    if is_integer(i) and i > 0 do
      http_fetch({http_url(r), m, h}, fn msg -> push_to_stream(r, msg) end)
      Process.send_after(self(), :poll, i)
    end

    {:noreply, state}
  end

  ### HTTP API Overrides ###

  @impl HttpApi
  def http_url(res = %Resource{broker: {:oanda, broker_opts}}) do
    account_id = Keyword.get(broker_opts, :account_id, nil)
    is_paper_trade = Keyword.get(broker_opts, :practice, true)
    is_stream = Keyword.get(res.options, :stream, false)

    if is_nil(account_id) do
      raise "Invalid resource struct, missing account_id"
    end

    data_mode = if(is_stream, do: "stream", else: "api")
    trade_mode = if(is_paper_trade, do: "practice", else: "trade")
    url_path = get_path(res.asset_id, account_id)
    url_query = get_path_params(res)

    "https://#{data_mode}-fx#{trade_mode}.oanda.com/#{url_path}?#{url_query}"
  end

  @impl HttpApi
  def http_asset_id({:forex, _, pair}) do
    case pair do
      {a, b} -> "#{String.upcase(a)}_#{String.upcase(b)}"
      _ -> raise "received invalid currency pair: #{inspect(pair)}"
    end
  end

  @impl HttpApi
  def http_headers(%Resource{broker: {:oanda, opts}, asset_id: {_, data_type, _}}) do
    key = Keyword.get(opts, :key, nil)

    if !is_binary(key) or String.length(key) != 65 do
      raise "invalid :key received with broker options"
    else
      case data_type do
        :quotes -> [{"authorization", "bearer #{key}"}, {"connection", "keep-alive"}]
        _ -> [{"authorization", "bearer #{key}"}]
      end
    end
  end

  @impl HttpApi
  def http_method(_), do: :get

  defp get_path({:forex, data_type, _}, account_id) when data_type in [:quotes, :first_tick] do
    "v3/accounts/#{account_id}/pricing"
  end

  defp get_path(asset_id = {:forex, data_type, _}, account_id) when data_type in @ohlc_types do
    "v3/accounts/#{account_id}/instruments/#{http_asset_id(asset_id)}/candles"
  end

  defp get_path_params(%Resource{asset_id: asset_id}) do
    case asset_id do
      {:forex, dt, _} when dt in [:first_tick, :quotes] ->
        [
          "instruments=#{http_asset_id(asset_id)}",
          "includeUnitsAvailable=false",
          "since=#{DateTime.to_unix(DateTime.utc_now(), :second) - get_ms_delta(dt)}"
        ]

      {:forex, dt, _} when dt in @ohlc_types ->
        [
          "granularity=#{get_channel(asset_id)}",
          "instruments=#{http_asset_id(asset_id)}",
          "includeUnitsAvailable=false",
          "since=#{DateTime.to_unix(DateTime.utc_now(), :second) - 60}"
        ]
    end
    |> Enum.join("&")
  end

  def get_channel({:forex, dt, _}), do: get_channel(dt)

  def get_channel(dt) when is_atom(dt) do
    case dt do
      :quotes -> raise(":quotes is not a supported candle size")
      :first_tick -> raise(":first_tick is not a supported candle size")
      :ohlc_1second -> "S5"
      :ohlc_10second -> "S10"
      :ohlc_15second -> "S15"
      :ohlc_30second -> "S30"
      :ohlc_1minute -> "M1"
      :ohlc_2minute -> "M2"
      :ohlc_3minute -> "M3"
      :ohlc_4minute -> "M4"
      :ohlc_5minute -> "M5"
      :ohlc_10minute -> "M10"
      :ohlc_15minute -> "M15"
      :ohlc_30minute -> "M30"
      :ohlc_1hour -> "H1"
      :ohlc_2hour -> "H2"
      :ohlc_3hour -> "H3"
      :ohlc_4hour -> "H4"
      :ohlc_6hour -> "H6"
      :ohlc_8hour -> "H8"
      :ohlc_12hour -> "H12"
      :ohlc_1day -> "D"
      :ohlc_3day -> "D"
      :ohlc_1week -> "W"
      :ohlc_1month -> "M"
    end
  end

  def get_ms_delta({:forex, dt, _}), do: get_ms_delta(dt)

  def get_ms_delta(dt) when is_atom(dt) do
    case dt do
      :quotes -> 34
      :first_tick -> 60 * 60 * 1000
      :ohlc_1second -> 1000
      :ohlc_10second -> 10 * 1000
      :ohlc_15second -> 15 * 1000
      :ohlc_30second -> 30 * 1000
      :ohlc_1minute -> 60 * 1000
      :ohlc_2minute -> 2 * 60 * 1000
      :ohlc_3minute -> 3 * 60 * 1000
      :ohlc_4minute -> 4 * 60 * 1000
      :ohlc_5minute -> 5 * 60 * 1000
      :ohlc_10minute -> 10 * 60 * 1000
      :ohlc_15minute -> 15 * 60 * 1000
      :ohlc_30minute -> 30 * 60 * 1000
      :ohlc_1hour -> 60 * 60 * 1000
      :ohlc_2hour -> 2 * 60 * 60 * 1000
      :ohlc_3hour -> 3 * 60 * 60 * 1000
      :ohlc_4hour -> 4 * 60 * 60 * 1000
      :ohlc_6hour -> 6 * 60 * 60 * 1000
      :ohlc_8hour -> 8 * 60 * 60 * 1000
      :ohlc_12hour -> 12 * 60 * 60 * 1000
      :ohlc_1day -> 24 * 60 * 60 * 1000
      :ohlc_3day -> 3 * 24 * 60 * 60 * 1000
      :ohlc_1week -> 7 * 24 * 60 * 60 * 1000
      :ohlc_1month -> trunc(365 * 24 * 60 * 60 * 1000 / 12)
    end
  end
end
