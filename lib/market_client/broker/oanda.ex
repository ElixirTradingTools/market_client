defmodule MarketClient.Broker.Oanda do
  alias MarketClient.{
    Behaviors.HttpApi,
    Resource,
    Shared
  }

  use HttpApi

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

  @spec get_path(MarketClient.asset_id(), any) :: binary
  @spec get_path_params(Resource.t()) :: binary

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
      {a, b} -> "#{Shared.a2s_upcased(a)}_#{Shared.a2s_upcased(b)}"
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
        :full_tick -> [{"authorization", "bearer #{key}"}, {"connection", "keep-alive"}]
        _ -> [{"authorization", "bearer #{key}"}]
      end
    end
  end

  @impl HttpApi
  def http_method(_), do: :get

  defp get_path({:forex, :full_tick, _}, account_id) do
    "v3/accounts/#{account_id}/pricing"
  end

  defp get_path(asset_id = {:forex, data_type, _}, account_id) when data_type in @ohlc_types do
    "v3/accounts/#{account_id}/instruments/#{http_asset_id(asset_id)}/candles"
  end

  defp get_path_params(%Resource{asset_id: asset_id}) do
    params =
      case asset_id do
        {:forex, :full_tick, _} ->
          [
            "instruments=#{http_asset_id(asset_id)}",
            "includeUnitsAvailable=false",
            "since=#{DateTime.to_unix(DateTime.utc_now(), :second) - 1}"
          ]

        {:forex, data_type, _} when data_type in @ohlc_types ->
          [
            "granularity=#{get_channel(asset_id)}",
            "instruments=#{http_asset_id(asset_id)}",
            "includeUnitsAvailable=false",
            "since=#{DateTime.to_unix(DateTime.utc_now(), :second) - 60}"
          ]
      end

    params |> Enum.join("&")
  end

  def get_channel({:forex, :full_tick, _}), do: raise(":full_tick is not a supported candle size")
  def get_channel({:forex, :ohlc_1second, _}), do: "S5"
  def get_channel({:forex, :ohlc_10second, _}), do: "S10"
  def get_channel({:forex, :ohlc_15second, _}), do: "S15"
  def get_channel({:forex, :ohlc_30second, _}), do: "S30"
  def get_channel({:forex, :ohlc_1minute, _}), do: "M1"
  def get_channel({:forex, :ohlc_2minute, _}), do: "M2"
  def get_channel({:forex, :ohlc_3minute, _}), do: "M3"
  def get_channel({:forex, :ohlc_4minute, _}), do: "M4"
  def get_channel({:forex, :ohlc_5minute, _}), do: "M5"
  def get_channel({:forex, :ohlc_10minute, _}), do: "M10"
  def get_channel({:forex, :ohlc_15minute, _}), do: "M15"
  def get_channel({:forex, :ohlc_30minute, _}), do: "M30"
  def get_channel({:forex, :ohlc_1hour, _}), do: "H1"
  def get_channel({:forex, :ohlc_2hour, _}), do: "H2"
  def get_channel({:forex, :ohlc_3hour, _}), do: "H3"
  def get_channel({:forex, :ohlc_4hour, _}), do: "H4"
  def get_channel({:forex, :ohlc_6hour, _}), do: "H6"
  def get_channel({:forex, :ohlc_8hour, _}), do: "H8"
  def get_channel({:forex, :ohlc_12hour, _}), do: "H12"
  def get_channel({:forex, :ohlc_1day, _}), do: "D"
  def get_channel({:forex, :ohlc_3day, _}), do: "D"
  def get_channel({:forex, :ohlc_1week, _}), do: "W"
  def get_channel({:forex, :ohlc_1month, _}), do: "M"
end
