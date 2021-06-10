defmodule MarketClient.Broker.Finnhub do
  @moduledoc false
  @doc """
  Central logic for this broker. Responsible for directing transport
  clients to execute the sourcing and collating of data to meet the
  specification of the provided `MarketClient.Resource`.
  """
  alias __MODULE__, as: Self
  alias MarketClient.Resource

  @spec start(Resource.t()) :: no_return

  # @valid_data_types MarketClient.valid_data_types()

  def start(res = %Resource{}) do
    res |> Self.Buffer.start()
    res |> Self.Ws.ws_start()
  end

  def validate(res = %Resource{}) do
    {:ok, res}
  end
end
