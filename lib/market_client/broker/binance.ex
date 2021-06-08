defmodule MarketClient.Broker.Binance do
  @moduledoc false
  @doc """
  Central logic for this broker. Responsible for directing transport
  clients to execute the sourcing and collating of data to meet the
  specification of the provided `MarketClient.Resource`.
  """
  alias MarketClient.Resource

  @spec start(Resource.t()) :: :ok

  def start(res = %Resource{}) do
    import DynamicSupervisor, only: [start_child: 2]

    {:ok, _} = start_child(MarketClient.DynamicSupervisor, {__MODULE__.Buffer, res})
    __MODULE__.Ws.ws_start(res)
  end
end
