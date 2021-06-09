defmodule MarketClient.Broker.CoinbasePro.Http do
  @moduledoc false
  @doc """
  HTTP client for pro.coinbase.com.
  """
  alias MarketClient.{
    Behaviors.HttpApi,
    Resource
  }

  use HttpApi, [:coinbase_pro]

  def http_url(%Resource{}) do
    # products/BTC-USD/candles?start=2020-12-01T00%3A00%3A00.0Z&end=2021-01-01T00%3A00%3A00.0Z&granularity=86400
    "https://api.pro.coinbase.com"
  end

  def http_method(%Resource{}), do: :get

  def http_headers(%Resource{}) do
    []
  end
end
