defmodule MarketClient.Resource do
  alias __MODULE__, as: Resource
  alias MarketClient.Broker
  use TypedStruct

  typedstruct do
    field :base_url, String.t()
    field :api_key, String.t(), enforce: true
    field :handler, Tuple.t(), enforce: true
    field :asset_id, String.t(), enforce: true
    field :socket_pid, Process.t() | Tuple.t(), default: nil
    field :broker, :polygon | :coinbase, enforce: true
  end

  def new(broker, asset_id, key, handler, via \\ nil)
      when is_binary(key) and is_binary(asset_id) and broker in [:coinbase, :polygon] do
    case handler do
      {:func, ref} when is_function(ref) ->
        %Resource{
          base_url: Broker.url(broker),
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
              base_url: Broker.url(broker),
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

# def stop(agent_pid) when is_pid(agent_pid) do
#   case Agent.get(agent_pid, fn state -> state end) do
#     resource = %Resource{socket_pid: socket_pid} ->
#       resource
#       |> Broker.unsubscribe()
#       |> Socket.push(socket_pid)
#   end
# end

# def start(agent_pid) when is_pid(agent_pid) do
#   Agent.get(agent_pid, fn
#     resource = %Resource{socket_pid: socket_pid} ->
#       {:ok, pid} = Socket.start_link(resource)

#       resource
#       |> Broker.subscribe()
#       |> Socket.push(socket_pid)

#       {:ok, pid}
#   end)
# end
