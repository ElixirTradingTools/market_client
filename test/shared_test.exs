defmodule MarketClientTest.Shared do
  use ExUnit.Case
  doctest MarketClient

  import MarketClient.Shared

  test "is_broker_module/1" do
    assert is_broker_module(MarketClient.Broker.FtxUs) == true
    assert is_broker_module(MarketClient.Shared) == false
    assert is_broker_module(Some.Foreign.Module) == false
  end
end
