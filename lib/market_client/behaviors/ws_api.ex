defmodule MarketClient.Behaviors.WsApi do
  @moduledoc """
  WsApi is a behavior and `use` macro for Vendor modules
  """

  alias MarketClient.{
    Resource,
    Shared
  }

  @optional_callbacks start_link: 1,
                      start: 2,
                      stop: 2,
                      get_asset_pair: 1,
                      format_asset_id: 1
  @callback ws_url(Resource.t()) :: binary
  @callback start_link(Resource.t()) :: {:ok, pid} | {:error, term}
  @callback start(pid, Resource.t()) :: {:ok, pid} | {:error, term}
  @callback stop(pid, Resource.t()) :: {:ok, pid} | {:error, term}
  @callback get_asset_pair(Resource.t()) :: binary
  @callback format_asset_id(Resource.t()) :: binary
  @callback msg_subscribe(Resource.t()) :: binary | List.t()
  @callback msg_unsubscribe(Resource.t()) :: binary | List.t()

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

      def ws_via_tuple(res = %Resource{}) do
        {:via, Registry, {MarketClient.Registry, MarketClient.pid_tuple(res, :ws)}}
      end

      @spec start_link(Resource.t()) :: {:ok, pid} | {:error, term}

      def start_link(res = %Resource{}) do
        case Ws.start_link(res) do
          {:ok, pid} ->
            res |> msg_subscribe() |> Ws.send_json(pid)
            {:ok, pid}

          error ->
            error
        end
      end

      @spec child_spec(Resource.t()) :: map

      def child_spec(res = %Resource{broker: {broker, _}, asset_id: asset_id}) do
        %{
          id: MarketClient.pid_tuple(res, :ws),
          start: {__MODULE__, :start_link, [res]}
        }
      end

      @spec start_ws(Resource.t()) :: {:ok, pid}

      def start_ws(res = %Resource{broker: {broker, _}, asset_id: asset_id}) do
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, child_spec(res))
      end

      defoverridable start_ws: 1

      @spec handle_connect(WebSockex.Conn.t(), term) :: {:ok, term}

      def handle_connect(conn, res = %Resource{}) do
        IO.inspect(conn)
        {:ok, res}
      end

      defoverridable handle_connect: 2

      # @spec start(pid, Resource.t()) :: {:ok, pid} | {:error, term}
      # def start(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
      #   res
      #   |> msg_subscribe()
      #   |> Ws.send_json(pid)
      # end

      # defoverridable start: 2

      @spec stop(pid, Resource.t()) :: {:ok, pid} | {:error, term}
      def stop(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
        res
        |> msg_unsubscribe()
        |> Ws.send_json(pid)
      end

      defoverridable stop: 2

      @spec get_asset_pair(Resource.t()) :: binary
      def get_asset_pair(%Resource{asset_id: {:crypto, {c1, c2}}})
          when is_atom(c1) and is_atom(c2) do
        "#{to_string(c1)}/#{to_string(c2)}"
      end

      defoverridable get_asset_pair: 1

      @spec format_asset_id(Resource.t()) :: binary
      def format_asset_id(res = %Resource{}) do
        get_asset_pair(res)
      end

      defoverridable format_asset_id: 1

      def handle_frame({:text, msg}, state) do
        state.listener.(msg)
        {:ok, state}
      end

      def handle_frame({type, msg}, state) do
        IO.inspect({type, msg})
        {:ok, state}
      end
    end
  end
end
