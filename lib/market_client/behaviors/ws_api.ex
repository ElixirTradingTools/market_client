defmodule MarketClient.Behaviors.WsApi do
  @moduledoc """
  WsApi is a behavior and `use` macro for Broker modules
  """

  alias MarketClient.{
    Resource,
    Shared
  }

  @optional_callbacks start_link: 1,
                      handle_ping: 2,
                      child_spec: 1,
                      ws_via_tuple: 1,
                      ws_start: 1,
                      ws_stop: 1,
                      ws_asset_id: 1
  @callback ws_url(Resource.t()) :: binary
  @callback start_link(Resource.t()) :: {:ok, pid} | {:error, any}
  @callback start_link(Resource.t(), keyword) :: {:ok, pid} | {:error, any}
  @callback ws_subscribe(Resource.t()) :: binary | list
  @callback ws_unsubscribe(Resource.t()) :: binary | list
  @callback handle_ping(:ping | {:ping, binary}, Resource.t()) :: MarketClient.ws_socket_state()
  @callback child_spec(Resource.t()) :: map
  @callback ws_via_tuple(Resource.t()) :: MarketClient.via_tuple()
  @callback ws_start(Resource.t()) :: {:ok, pid}
  @callback ws_stop(pid | Resource.t() | MarketClient.via_tuple()) :: :ok | {:error, any}
  @callback ws_asset_id(MarketClient.asset_id()) :: binary

  defmacro __using__([]) do
    unless Shared.is_broker_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.WsApi is not a public module"
    end

    quote do
      require Logger

      alias MarketClient.{
        Transport.Ws,
        Resource
      }

      @behaviour MarketClient.Behaviors.WsApi

      @ohlc_types MarketClient.ohlc_types()

      @spec child_spec(Resource.t()) :: map
      @spec ws_via_tuple(Resource.t()) :: MarketClient.via_tuple()
      @spec ws_start(Resource.t()) :: {:ok, pid}
      @spec ws_stop(pid | Resource.t() | MarketClient.via_tuple()) :: :ok | {:error, any}
      @spec ws_asset_id(MarketClient.asset_id()) :: binary
      @spec handle_connect(WebSockex.Conn.t(), any) :: {:ok, any}

      def child_spec(res = %Resource{}) do
        %{
          id: MarketClient.pid_tuple(res, :ws),
          start: {__MODULE__, :start_link, [res]}
        }
      end

      def start_link(res = %Resource{}, opts \\ []) do
        Ws.start_link(res, opts)
      end

      def ws_start(res = %Resource{}) do
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, child_spec(res))
      end

      def ws_stop(client = %Resource{}), do: client |> ws_via_tuple() |> Ws.close()
      def ws_stop(client = {:via, _, _}), do: client |> Ws.close()
      def ws_stop(client) when is_pid(client), do: client |> Ws.close()

      def ws_asset_id(asset_id), do: MarketClient.default_asset_id(asset_id)

      def ws_via_tuple(res = %Resource{}) do
        {:via, Registry, {MarketClient.Registry, MarketClient.pid_tuple(res, :ws)}}
      end

      def handle_connect(conn, res = %Resource{}) do
        res |> ws_subscribe() |> Ws.send_json(conn)
        {:ok, res}
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
                     ws_asset_id: 1,
                     handle_ping: 2,
                     start_link: 1,
                     ws_start: 1,
                     ws_stop: 1
    end
  end
end
