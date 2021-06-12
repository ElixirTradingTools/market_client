defmodule MarketClient.Broker.Finnhub do
  @moduledoc false
  @doc """
  Central logic for this broker. Responsible for directing transport
  clients to execute the sourcing and collating of data to meet the
  specification of the provided `MarketClient.Resource`.
  """
  alias MarketClient.Resource

  @spec start(Resource.t()) :: no_return

  @valid_data_types MarketClient.valid_data_types()

  def start(res = %Resource{}) do
    res |> MarketClient.Buffer.start()
    res |> __MODULE__.Ws.ws_start()
  end

  def stop(res = %Resource{}) do
    res |> MarketClient.Buffer.stop()
    res |> __MODULE__.Ws.ws_stop()
  end

  def validate(res = %Resource{}) do
    case res do
      %{asset_id: {:crypto, _, _}} -> validate_crypto(res)
      %{asset_id: {:forex, _, _}} -> validate_forex(res)
      %{asset_id: {:stock, _, _}} -> validate_stock(res)
      %{asset_id: {c, _, _}} -> {:error, "invalid asset class: #{inspect(c)}"}
    end
  end

  defp validate_crypto(res) do
    case res.asset_id do
      {_, dt, _} when dt in @valid_data_types -> validate_currency_pair(res)
      {_, dt, _} -> {:error, "invalid data-type: #{inspect(dt)}"}
    end
  end

  defp validate_forex(res) do
    case res.asset_id do
      {_, :trades, _} -> validate_currency_pair(res)
      {_, :quotes, _} -> validate_currency_pair(res)
      {_, dt, _} -> {:error, "invalid data-type: #{inspect(dt)}"}
    end
  end

  defp validate_stock(res) do
    case res.asset_id do
      {_, :trades, _} -> validate_stock_ticker(res)
      {_, :quotes, _} -> validate_stock_ticker(res)
      {_, dt, _} -> {:error, "invalid data-type #{inspect(dt)}"}
    end
  end

  defp validate_stock_ticker(res) do
    case res.asset_id do
      {_, _, ticker} when is_binary(ticker) -> {:ok, res}
      {_, _, ticker} -> {:error, "invalid ticker: #{inspect(ticker)}"}
    end
  end

  defp validate_currency_pair(res) do
    case res.asset_id do
      {_, _, {a, b}} when is_binary(a) and is_binary(b) -> {:ok, res}
      {_, _, pair} -> {:error, "invalid currency pair: #{inspect(pair)}"}
    end
  end
end
