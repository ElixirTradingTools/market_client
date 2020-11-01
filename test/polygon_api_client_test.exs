defmodule MarketClientTest do
  use ExUnit.Case
  doctest MarketClient

  test "greets the world" do
    assert MarketClient.hello() == :world
  end
end
