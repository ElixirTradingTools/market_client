defmodule MarketClient.Vendor.Oanda do
  alias MarketClient.{
    Transport.Http,
    Resource,
    Shared
  }

  def http_url(%Resource{
        broker: {:oanda, %{practice: is_paper_trade, account_id: aid}},
        asset_id: {:forex, {c1, c2}},
        options: %{
          data_type: data_type,
          resolution: {res_count, res_unit},
          stream: is_stream
        }
      })
      when is_atom(c1) and is_atom(c2) and aid != nil do
    mode = if(is_paper_trade, do: "practice", else: "trade")

    url_path =
      case data_type do
        :candlesticks ->
          params =
            Enum.map(
              [
                granularity: "#{get_resolution_unit(res_unit)}#{res_count}",
                instruments: format_asset_id(c1, c2),
                includeUnitsAvailable: "false",
                since: DateTime.to_unix(DateTime.utc_now(), :second) - 50
              ],
              fn {k, v} -> "#{k}=#{v}" end
            )

          "v3/accounts/#{aid}/pricing?#{params}"

        :account ->
          "v3/accounts"
      end

    "https://#{if(is_stream, do: "stream", else: "api")}-fx#{mode}.oanda.com/#{url_path}"
  end

  def get_resolution_unit(atom) do
    case atom do
      :second -> "S"
      :minute -> "M"
      :hour -> "H"
      :week -> "W"
    end
  end

  def format_asset_id(c1, c2) when is_atom(c1) and is_atom(c2) do
    "#{Shared.a2s_upcased(c1)}_#{Shared.a2s_upcased(c2)}"
  end

  def headers(%Resource{broker: {:oanda, %{key: k}}}) when is_binary(k) do
    [{"authorization", "bearer #{k}"}]
  end

  def start_link(
        res = %Resource{
          broker: {:oanda, %{key: key}},
          listener: callback,
          options: %{stream: is_stream}
        }
      )
      when is_function(callback) and is_binary(key) do
    if is_stream do
      Http.stream(http_method(res), http_url(res), [authorization: key], callback)
    else
      case Http.request(res) do
        {:ok, %Finch.Response{body: body}} ->
          body |> Jason.decode!() |> callback.()

        {:error, error} ->
          IO.puts("Error: #{inspect(error)}")
      end
    end
  end

  def http_method(_), do: :get
end
