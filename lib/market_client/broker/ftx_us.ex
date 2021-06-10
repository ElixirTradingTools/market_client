defmodule MarketClient.Broker.FtxUs do
  @moduledoc false
  @doc """
  Central logic for this broker. Responsible for directing transport
  clients to execute the sourcing and collating of data to meet the
  specification of the provided `MarketClient.Resource`.
  """
  alias __MODULE__, as: Self
  alias MarketClient.Resource

  @spec start(Resource.t()) :: no_return

  def start(res = %Resource{}) do
    res |> Self.Buffer.start()
    res |> Self.Ws.ws_start()
  end

  # HTTP client still WIP
end
