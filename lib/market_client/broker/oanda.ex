defmodule MarketClient.Broker.Oanda do
  @moduledoc false
  @doc """
  Central logic for this broker. Responsible for directing transport
  clients to execute the sourcing and collating of data to meet the
  specification of the provided `MarketClient.Resource`.
  """
  alias __MODULE__, as: Self
  alias MarketClient.Resource

  @spec start(Resource.t()) :: no_return

  @valid_data_types MarketClient.valid_data_types()

  def start(res = %Resource{}) do
    res |> Self.Buffer.start()
    res |> Self.Http.http_start()
  end

  def validate(res = %Resource{}) do
    case res.asset_id do
      {:forex, _, _} -> validate_forex(res)
      {:crypto, _, _} -> {:error, "invalid asset class: :crypto"}
      {:stock, _, _} -> {:error, "invalid asset class: :stock"}
      {c, _, _} -> {:error, "invalid asset class: #{inspect(c)}"}
    end
  end

  defp validate_forex(res) do
    case res.asset_id do
      {_, :trades, _} -> {:error, ":trades data-type not supported"}
      {_, dt, _} when dt in @valid_data_types -> validate_currency_pair(res)
      {_, dt, _} -> {:error, "invalid data-type: #{inspect(dt)}"}
    end
  end

  defp validate_currency_pair(res) do
    case res.asset_id do
      {_, _, {a, b}} when is_binary(a) and is_binary(b) -> {:ok, res}
      {_, _, pair} -> {:error, "invalid currency pair: #{inspect(pair)}"}
    end
  end
end
