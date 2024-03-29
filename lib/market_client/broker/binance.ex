defmodule MarketClient.Broker.Binance do
  @moduledoc false
  @doc """
  Central logic for this broker. Responsible for directing transport
  clients to execute the sourcing and collating of data to meet the
  specification of the provided `MarketClient.Resource`.
  """
  use MarketClient.Behaviors.Binance
end
