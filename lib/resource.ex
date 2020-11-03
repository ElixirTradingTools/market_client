defmodule MarketClient.Resource do
  alias __MODULE__, as: Resource
  use TypedStruct

  @brokers [:coinbase, :polygon, :binance]

  typedstruct do
    field :api_key, String.t(), enforce: true
    field :handler, Tuple.t(), enforce: true
    field :asset_id, Tuple.t(), enforce: true
    field :socket_pid, Process.t() | Tuple.t(), default: nil
    field :broker, :polygon | :coinbase | :binance, enforce: true
  end

  def new(broker, asset_id, key, handler, via \\ nil)
      when is_binary(key) and is_tuple(asset_id) and broker in @brokers do
    case handler do
      {:func, ref} when is_function(ref) ->
        %Resource{
          broker: broker,
          asset_id: asset_id,
          api_key: key,
          handler: handler,
          socket_pid: via
        }

      {:file, ref} when is_binary(ref) ->
        case File.open(ref, [:write]) do
          {:ok, fh_ref} ->
            %Resource{
              broker: broker,
              asset_id: asset_id,
              api_key: key,
              handler: {:file, fh_ref},
              socket_pid: via
            }
        end
    end
  end
end
