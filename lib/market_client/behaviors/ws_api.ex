defmodule MarketClient.Behaviors.WsApi do
  @moduledoc """
  WsApi is a behavior and `use` macro for Vendor modules
  """

  alias MarketClient.{
    Resource,
    Shared
  }

  @optional_callbacks stop: 1,
                      start_link: 1,
                      get_asset_id: 1,
                      handle_ping: 2
  @callback ws_url(Resource.t()) :: binary
  @callback start_link(Resource.t()) :: {:ok, pid} | {:error, any}
  @callback stop(pid | Resource.t() | MarketClient.via()) :: :ok | {:error, any}
  @callback get_asset_id({atom, atom, binary | {atom, atom}}) :: binary
  @callback msg_subscribe(Resource.t()) :: binary | list
  @callback msg_unsubscribe(Resource.t()) :: binary | list
  @callback handle_ping(:ping | {:ping, binary}, Resource.t()) ::
              {:ok | :close, any} | {:reply | :close, any, any}

  defmacro __using__([]) do
    unless Shared.is_vendor_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.WsApi is not a public module"
    end

    quote do
      require Logger

      alias MarketClient.{
        Transport.Ws,
        Resource
      }

      @behaviour MarketClient.Behaviors.WsApi

      @spec ws_via_tuple(Resource.t()) :: MarketClient.via()
      @spec start_ws(Resource.t()) :: {:ok, pid}
      @spec child_spec(Resource.t()) :: map
      @spec handle_connect(WebSockex.Conn.t(), any) :: {:ok, any}

      def get_asset_id({_, _, asset_name}) do
        case asset_name do
          name when is_binary(name) -> name
          {a, b} -> "#{to_string(a)}/#{to_string(b)}"
        end
      end

      def ws_via_tuple(res = %Resource{}) do
        {:via, Registry, {MarketClient.Registry, MarketClient.pid_tuple(res, :ws)}}
      end

      def start_ws(res = %Resource{vendor: {vendor, _}, asset_id: asset_id}) do
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, child_spec(res))
      end

      def child_spec(res = %Resource{vendor: {vendor, _}, asset_id: asset_id}) do
        %{
          id: MarketClient.pid_tuple(res, :ws),
          start: {__MODULE__, :start_link, [res]}
        }
      end

      def start_link(res = %Resource{options: opts}) do
        case opts do
          %{debug: true} -> Ws.start_link(res, :debug)
          _ -> Ws.start_link(res)
        end
      end

      def handle_connect(conn, res = %Resource{}) do
        res |> msg_subscribe() |> Ws.send_json(conn)
        {:ok, res}
      end

      def stop(client) do
        case client do
          client when is_pid(client) -> client
          %Resource{} -> client |> ws_via_tuple()
          {:via, _, _} -> client
        end
        |> Ws.close()
      end

      def handle_frame({type, msg}, state) do
        case type do
          :text -> state.listener.(msg)
          _ -> Logger.warn("Unknown frame: #{inspect({type, msg})}")
        end

        {:ok, state}
      end

      def handle_ping(ping_frame, res = %Resource{}) do
        case ping_frame do
          {:ping, id} -> {:reply, {:pong, id}, res}
          :ping -> {:reply, {:pong, ""}, res}
        end
      end

      defoverridable handle_connect: 2,
                     get_asset_id: 1,
                     handle_ping: 2,
                     start_link: 1,
                     start_ws: 1,
                     stop: 1
    end
  end
end
