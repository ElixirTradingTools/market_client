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
                      get_asset_id: 1
  @callback ws_url(Resource.t()) :: binary
  @callback start_link(Resource.t()) :: {:ok, pid} | {:error, term}
  @callback start(pid, Resource.t()) :: {:ok, pid} | {:error, term}
  @callback stop(pid, Resource.t()) :: {:ok, pid} | {:error, term}
  @callback get_asset_id(Resource.t()) :: binary
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
      @spec start_ws(Resource.t()) :: {:ok, pid}
      @spec child_spec(Resource.t()) :: map
      @spec start_link(Resource.t()) :: {:ok, pid} | {:error, term}
      @spec handle_connect(WebSockex.Conn.t(), term) :: {:ok, term}
      @spec stop(pid, Resource.t()) :: {:ok, pid} | {:error, term}
      @spec get_asset_id(Resource.t()) :: binary

      def get_asset_id(%Resource{asset_id: {:crypto, {c1, c2}}})
          when is_atom(c1) and is_atom(c2) do
        "#{to_string(c1)}/#{to_string(c2)}"
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

      def start_link(res = %Resource{}) do
        mod = MarketClient.get_broker_module(res)
        url = mod.ws_url(res)
        via = mod.ws_via_tuple(res)

        Ws.start_link(url, mod, res, name: via)
      end

      def handle_connect(_conn, res = %Resource{}) do
        IO.puts("-- CONNECT --")
        {:ok, res}
      end

      @spec start(pid, Resource.t()) :: {:ok, pid} | {:error, term}
      def start(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
        res
        |> msg_subscribe()
        |> Ws.send_json(pid)
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

      defoverridable start_ws: 1,
                     handle_connect: 2,
                     start: 2,
                     stop: 2,
                     get_asset_id: 1
    end
  end
end
