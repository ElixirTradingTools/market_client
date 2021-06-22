defmodule MarketClient.Broker.Oanda.Http do
  @moduledoc false
  @doc """
  HTTP client for oanda.com.
  """
  alias MarketClient.{
    Behaviors.HttpApi,
    Resource
  }

  use HttpApi
  use GenServer

  @ohlc_types MarketClient.ohlc_types()

  @type state_map :: %{
          polling_interval: nil | integer,
          resource: MarketClient.resource(),
          method: MarketClient.http_method(),
          headers: MarketClient.http_headers(),
          buffer: MarketClient.via_tuple(),
          url: binary
        }
  @spec get_path(MarketClient.asset_id(), any) :: binary
  @spec get_path_params(MarketClient.resource()) :: binary
  @spec get_channel(atom) :: binary
  @spec get_ms_delta(atom) :: integer
  @spec poll(state_map) :: {:noreply, state_map}
  @spec init(MarketClient.resource()) :: {:ok, state_map}

  ### HTTP Polling Worker ###

  def start_link([res = %Resource{broker: {bn, _}, watch: {_, kwl}}]) do
    GenServer.start_link(__MODULE__, res, name: MarketClient.get_via(bn, kwl, :http))
  end

  @impl GenServer
  def init(res = %Resource{broker: {bn, _}, watch: {_, kwl}}) do
    {url, method, headers} = get_url_method_headers(res)

    state = %{
      polling_interval: nil,
      buffer: MarketClient.get_via(bn, kwl, :buffer),
      resource: res,
      headers: headers,
      method: method,
      url: url
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:poll, state), do: poll(state)

  @impl GenServer
  def handle_cast(:start, %{polling_interval: nil, resource: res} = state) do
    with {:forex, [quotes: [pair]]} = res.watch do
      res
      |> Map.put(:watch, {:forex, [first_tick: [pair]]})
      |> get_url_method_headers()
      |> http_fetch(fn _ -> nil end)
    end

    state
    |> Map.put(:polling_interval, get_ms_delta(:quotes))
    |> poll()
  end

  @impl GenServer
  def handle_cast(:stop, state), do: {:stop, :normal, Map.put(state, :polling_interval, nil)}

  defp poll(%{polling_interval: i, url: url, buffer: bv, method: m, headers: h} = state) do
    if is_integer(i) and i > 0 do
      http_fetch({url, m, h}, fn msg -> push_to_stream(bv, msg) end)
      Process.send_after(self(), :poll, i)
    end

    {:noreply, state}
  end

  ### HTTP API Overrides ###

  @impl HttpApi
  def http_url(res = %Resource{broker: {:oanda, broker_opts}, watch: {:forex, [{dt, list}]}}) do
    account_id = Keyword.get(broker_opts, :account_id, nil)
    is_paper_trade = Keyword.get(broker_opts, :practice, true)
    is_stream = Keyword.get(res.options, :stream, false)

    if is_nil(account_id) do
      raise "Invalid resource struct, missing account_id"
    end

    data_mode = if(is_stream, do: "stream", else: "api")
    trade_mode = if(is_paper_trade, do: "practice", else: "trade")
    url_path = get_path({dt, list}, account_id)
    url_query = get_path_params(res)

    "https://#{data_mode}-fx#{trade_mode}.oanda.com/#{url_path}?#{url_query}"
  end

  @impl HttpApi
  def http_asset_id({_, pairs}) do
    for({a, b} <- pairs, do: "#{a}_#{b}")
    |> Enum.join(",")
    |> String.upcase()
  end

  @impl HttpApi
  def http_headers(%Resource{broker: {:oanda, opts}, watch: {:forex, [{dt, _}]}}) do
    key = Keyword.get(opts, :key, nil)

    if !is_binary(key) or String.length(key) != 65 do
      raise "invalid :key received with broker options"
    else
      case dt do
        :quotes -> [{"authorization", "bearer #{key}"}, {"connection", "keep-alive"}]
        _ -> [{"authorization", "bearer #{key}"}]
      end
    end
  end

  @impl HttpApi
  def http_method(_), do: :get

  defp get_path({dt, _pairs}, account_id) when dt in [:quotes, :first_tick],
    do: "v3/accounts/#{account_id}/pricing"

  defp get_path({dt, pairs}, account_id) when dt in @ohlc_types,
    do: "v3/accounts/#{account_id}/instruments/#{http_asset_id({dt, pairs})}/candles"

  defp get_path_params(%Resource{broker: {:oanda, _}, watch: {:forex, [{dt, pairs}]}})
       when dt in [:first_tick, :quotes] do
    [
      "instruments=" <> http_asset_id({dt, pairs}),
      "includeUnitsAvailable=false",
      "since=#{DateTime.to_unix(DateTime.utc_now(), :second) - get_ms_delta(dt)}"
    ]
    |> Enum.join("&")
  end

  defp get_path_params(%Resource{broker: {:oanda, _}, watch: {:forex, [{dt, pairs}]}})
       when dt in @ohlc_types do
    [
      "granularity=" <> get_channel(dt),
      "instruments=" <> http_asset_id({dt, pairs}),
      "includeUnitsAvailable=false",
      "since=#{DateTime.to_unix(DateTime.utc_now(), :second) - 60}"
    ]
    |> Enum.join("&")
  end

  defp get_channel(dt) do
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

  def get_ms_delta(dt) do
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
