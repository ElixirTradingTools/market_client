defmodule MarketClient do
  alias MarketClient.Resource

  @brokers [
    :binance_global,
    :binance_us,
    :coinbase,
    :polygon,
    :ftx_us,
    :oanda
  ]

  def get_broker_module(%Resource{broker: {broker_name, _}}) do
    case broker_name do
      :binance_global -> MarketClient.Company.BinanceGlobal
      :binance_us -> MarketClient.Company.BinanceUs
      :coinbase -> MarketClient.Company.Coinbase
      :polygon -> MarketClient.Company.Polygon
      :ftx_us -> MarketClient.Company.FtxUs
      :oanda -> MarketClient.Company.Oanda
    end
  end

  def new(broker = {name, _}, asset_id, opts, handler)
      when is_tuple(asset_id) and is_map(opts) and is_tuple(handler) and name in @brokers do
    case handler do
      {:func, ref} when is_function(ref) ->
        %Resource{
          broker: broker,
          asset_id: asset_id,
          handler: handler,
          opts: opts
        }

      {:file, ref} when is_binary(ref) ->
        case File.open(ref, [:write]) do
          {:ok, fh_ref} ->
            %Resource{
              broker: broker,
              asset_id: asset_id,
              handler: {:file, fh_ref},
              opts: opts
            }
        end
    end
  end

  def start(pid, res = %Resource{}) do
    res
    |> get_broker_module()
    |> apply(:start, [pid, res])
  end

  def start(pid, res = %Resource{}, other) do
    res
    |> get_broker_module()
    |> apply(:start, [pid, res, other])
  end

  def start_link(res = %Resource{}) do
    res
    |> get_broker_module()
    |> apply(:start_link, [res])
  end

  def stop(pid, res = %Resource{}) do
    res
    |> get_broker_module()
    |> apply(:stop, [pid, res])
  end

  def url(res = %Resource{}) do
    res
    |> get_broker_module()
    |> apply(:url, [res])
  end

  def msg_subscribe(res = %Resource{}) do
    res
    |> get_broker_module()
    |> apply(:msg_subscribe, [res])
  end

  def msg_unsubscribe(res = %Resource{}) do
    res
    |> get_broker_module()
    |> apply(:msg_unsubscribe, [res])
  end
end
