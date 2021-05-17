defmodule MarketClientTest.Shared do
  use ExUnit.Case
  doctest MarketClient

  import MarketClient.Shared

  test "is_vendor_module/1" do
    assert is_vendor_module(MarketClient.Vendor.FtxUs) == true
    assert is_vendor_module(MarketClient.Shared) == false
    assert is_vendor_module(Some.Foreign.Module) == false
  end

  test "as_list/1" do
    assert as_list(1) == [1]
    assert as_list([1]) == [1]
    assert as_list(:a) == [:a]
  end

  test "a2s_upcased/1" do
    assert a2s_upcased(:asdf) == "ASDF"
    assert a2s_upcased(:ASDF) == "ASDF"
  end

  test "a2s_downcased/1" do
    assert a2s_downcased(:asdf) == "asdf"
    assert a2s_downcased(:ASDF) == "asdf"
  end
end
