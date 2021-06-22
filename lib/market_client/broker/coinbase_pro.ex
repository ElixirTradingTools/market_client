defmodule MarketClient.Broker.CoinbasePro do
  @moduledoc false
  @doc """
  Central logic for this broker. Responsible for directing transport
  clients to execute the sourcing and collating of data to meet the
  specification of the provided `MarketClient.Resource`.
  """
  alias MarketClient.Resource

  @spec start(MarketClient.resource()) :: no_return

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
    case res.watch do
      {:crypto, _, _} -> validate_crypto(res)
      {:forex, _, _} -> {:error, "invalid asset class: :forex"}
      {:stock, _, _} -> {:error, "invalid asset class: :stock"}
      {c, _, _} -> {:error, "invalid asset class: #{inspect(c)}"}
    end
  end

  defp validate_crypto(res) do
    case res.watch do
      {_, dt, _} when dt in @valid_data_types -> validate_currency_pair(res)
      {_, dt, _} -> {:error, "invalid data-type: #{inspect(dt)}"}
    end
  end

  defp validate_currency_pair(res) do
    case res.watch do
      {_, _, {a, b}} when is_binary(a) and is_binary(b) -> {:ok, res}
      {_, _, pair} -> {:error, "invalid currency pair: #{inspect(pair)}"}
    end
  end
end
