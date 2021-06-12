defmodule MarketClient.Behaviors.WsApi do
  @moduledoc """
  Reusable core implementation for WebSocket client modules. Any supported
  broker with a WebSocket API will use `use WsApi`. See contributor guide
  and modules like Polygon for help and examples of how to use this.
  """

  alias MarketClient.{
    Resource,
    Shared
  }

  @optional_callbacks start_link: 1,
                      handle_ping: 2,
                      handle_connect: 2,
                      child_spec: 1,
                      ws_start: 1,
                      ws_stop: 1,
                      ws_asset_id: 1
  @callback ws_url(Resource.t()) :: binary
  @callback start_link(Resource.t()) :: {:ok, pid} | {:error, any}
  @callback ws_subscribe(Resource.t()) :: binary | list
  @callback ws_unsubscribe(Resource.t()) :: binary | list
  @callback handle_ping(:ping | {:ping, binary}, Resource.t()) :: MarketClient.ws_socket_state()
  @callback child_spec(Resource.t()) :: map
  @callback ws_start(Resource.t()) :: no_return
  @callback ws_stop(pid | Resource.t() | MarketClient.via_tuple()) :: :ok | {:error, any}
  @callback ws_asset_id(MarketClient.asset_id()) :: binary
  @callback handle_connect(WebSockex.Conn.t(), any) :: {:ok, any}
  @callback handle_frame(WebSockex.frame(), any) ::
              {:ok, any}
              | {:reply, WebSockex.frame(), any}
              | {:close, any}
              | {:close, WebSockex.close_frame(), any}

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

      # @buffer_module MarketClient.get_broker_module(unquote(broker_name), :buffer)
      @ohlc_types MarketClient.ohlc_types()

      @spec start_link(Resource.t()) :: {:ok, pid} | {:error, any}
      @spec child_spec(Resource.t()) :: map
      @spec ws_start(Resource.t()) :: no_return
      @spec ws_stop(pid | Resource.t() | MarketClient.via_tuple()) :: :ok | {:error, any}
      @spec ws_asset_id(MarketClient.asset_id()) :: binary
      @spec handle_connect(WebSockex.Conn.t(), any) :: {:ok, any}
      @spec handle_frame(WebSockex.frame(), any) ::
              {:ok, any}
              | {:reply, WebSockex.frame(), any}
              | {:close, any}
              | {:close, WebSockex.close_frame(), any}

      def start_link(res = %Resource{options: opts}) do
        url = ws_url(res)
        via = MarketClient.get_via(res, :ws)
        Ws.start_link(url, __MODULE__, res, via, opts)
      end

      def ws_start(res = %Resource{}) do
        MarketClient.DynamicSupervisor.start_child(child_spec(res))
      end

      def child_spec(res = %Resource{}) do
        %{
          id: MarketClient.res_id(res, :ws),
          start: {__MODULE__, :start_link, [res]}
        }
      end

      def ws_stop(client) do
        case client do
          %Resource{} -> client |> MarketClient.get_via(:ws) |> Ws.close()
          {:via, _, _} -> client |> Ws.close()
          client when is_pid(client) -> client |> Ws.close()
        end
      end

      def ws_asset_id(asset_id), do: MarketClient.default_asset_id(asset_id)

      def handle_connect(conn, res = %Resource{}) do
        res |> ws_subscribe() |> Ws.send_json(conn)
        {:ok, res}
      end

      def handle_frame({type, msg}, res = %Resource{broker: {broker_name, _}}) do
        case type do
          :text ->
            buffer_module = MarketClient.get_broker_module(broker_name, :buffer)
            apply(buffer_module, :push, [res, msg])

          _ ->
            Logger.warn("Unknown frame: #{inspect({type, msg})}")
        end

        {:ok, res}
      end

      def handle_ping(ping_frame, res = %Resource{}) do
        case ping_frame do
          {:ping, id} -> {:reply, {:pong, id}, res}
          :ping -> {:reply, {:pong, ""}, res}
        end
      end

      defoverridable handle_connect: 2,
                     handle_frame: 2,
                     ws_asset_id: 1,
                     handle_ping: 2,
                     start_link: 1,
                     ws_start: 1,
                     ws_stop: 1
    end
  end
end
