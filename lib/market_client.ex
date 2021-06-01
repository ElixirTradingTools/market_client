defmodule MarketClient do
  alias MarketClient.Resource

  @vendor_modules [
    binance: MarketClient.Vendor.Binance,
    binance_us: MarketClient.Vendor.BinanceUs,
    coinbase: MarketClient.Vendor.Coinbase,
    polygon: MarketClient.Vendor.Polygon,
    oanda: MarketClient.Vendor.Oanda,
    ftx_us: MarketClient.Vendor.FtxUs,
    ftx: MarketClient.Vendor.Ftx,
  ]

  @type via :: {:via, module, any}

  @vendors Enum.map(@vendor_modules, fn {a, _} -> a end)

  @spec pid_tuple(Resource.t(), :ws | :http) :: {:ws | :http, atom, any}
  @spec get_vendor_module(Resource.t()) :: module
  @spec new(atom, {atom, binary | {atom, atom}}, function) :: Resource.t()
  @spec new({atom, any}, {atom, binary | {atom, atom}}, function) :: Resource.t()
  @spec new(atom, {atom, binary | {atom, atom}}, function, keyword | nil) :: Resource.t()
  @spec new({atom, any}, {atom, binary | {atom, atom}}, function, keyword | nil) :: Resource.t()

  def pid_tuple(%Resource{vendor: {vendor, _}, asset_id: asset_id}, transport_type) do
    {transport_type, vendor, asset_id}
  end

  def get_vendor_module(%Resource{vendor: {vendor_name, _}}) do
    Keyword.get(@vendor_modules, vendor_name, nil)
  end

  def new(vendor, asset_id, listener) when vendor in @vendors do
    new({vendor, nil}, asset_id, listener, nil)
  end

  def new(vendor = {name, _}, asset_id, listener)
      when is_tuple(asset_id) and is_function(listener) and name in @vendors do
    new(vendor, asset_id, listener, nil)
  end

  def new(vendor, asset_id, listener, opts) when vendor in @vendors do
    new({vendor, nil}, asset_id, listener, opts)
  end

  def new(vendor = {name, _}, asset_id, listener, opts)
      when is_tuple(asset_id) and is_function(listener) and name in @vendors do
    %Resource{
      vendor: vendor,
      asset_id: asset_id,
      listener: listener,
      options: opts
    }
  end

  [
    :start_link,
    :start_ws,
    :stop_ws,
    :get_asset_id,
    :ws_url,
    :http_fetch,
    :http_url,
    :http_method,
    :http_headers,
    :http_query_params,
    :msg_subscribe,
    :msg_unsubscribe
  ]
  |> Enum.each(fn func_name ->
    def unquote(func_name)(res = %Resource{}) do
      res
      |> get_vendor_module()
      |> apply(unquote(func_name), [res])
    end
  end)
end
