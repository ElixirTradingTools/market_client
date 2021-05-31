defmodule MarketClient.Behaviors.WsApi do
  @moduledoc """
  WsApi is a behavior and `use` macro for Vendor modules
  """

  alias MarketClient.{
    Resource,
    Shared
  }

  @optional_callbacks stop: 2,
                      start_link: 1,
                      get_asset_id: 1,
                      handle_ping: 2
  @callback ws_url(Resource.t()) :: binary
  @callback start_link(Resource.t()) :: {:ok, pid} | {:error, term}
  @callback stop(pid, Resource.t()) :: {:ok, pid} | {:error, term}
  @callback get_asset_id(Resource.t()) :: binary
  @callback msg_subscribe(Resource.t()) :: binary | List.t()
  @callback msg_unsubscribe(Resource.t()) :: binary | List.t()
  @callback handle_ping(:ping | {:ping, binary}, Resource.t()) ::
              {:ok | :close, any} | {:reply | :close, any, any}

  defmacro __using__([]) do
    unless Shared.is_vendor_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.WsApi is not a public module"
    end

    quote do
      alias MarketClient.{
        Transport.Ws,
        Resource
      }

      @behaviour MarketClient.Behaviors.WsApi

      @spec ws_via_tuple(Resource.t()) :: {:via, module, {module, {atom, atom, term}}}
      @spec start_ws(Resource.t()) :: {:ok, pid}
      @spec child_spec(Resource.t()) :: map
      @spec handle_connect(WebSockex.Conn.t(), term) :: {:ok, term}
      @spec handle_ping({:ping, binary}, Resource.t()) ::
              {:ok | :close, any} | {:reply | :close, any, any}
      @spec stop(pid, Resource.t()) :: {:ok, pid} | {:error, term}
      @spec get_asset_id(Resource.t()) :: binary

      def get_asset_id(%Resource{asset_id: {:crypto, {a, b}}}) when is_atom(a) and is_atom(b) do
        "#{to_string(a)}/#{to_string(b)}"
      end

      def ws_via_tuple(res = %Resource{}) do
        {:via, Registry, {MarketClient.Registry, MarketClient.pid_tuple(res, :ws)}}
      end

      def start_ws(res = %Resource{broker: {broker, _}, asset_id: asset_id}) do
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, child_spec(res))
      end

      def child_spec(res = %Resource{broker: {broker, _}, asset_id: asset_id}) do
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
        IO.puts("-- CONNECT --")

        res
        |> msg_subscribe()
        |> Ws.send_json(conn)

        {:ok, res}
      end

      def stop(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
        res
        |> msg_unsubscribe()
        |> Ws.send_json(pid)
      end

      def handle_frame({:text, msg}, state) do
        state.listener.(msg)
        {:ok, state}
      end

      def handle_frame({type, msg}, state) do
        IO.puts("Unknown frame: #{inspect(type)}: #{msg}")
        {:ok, state}
      end

      def handle_ping(ping_frame, res = %Resource{}) do
        case ping_frame do
          {:ping, id} -> {:reply, {:pong, id}, res}
          :ping -> {:reply, {:pong, ""}, res}
        end
      end

      defoverridable stop: 2,
                     start_ws: 1,
                     handle_connect: 2,
                     get_asset_id: 1,
                     handle_ping: 2
    end
  end
end
