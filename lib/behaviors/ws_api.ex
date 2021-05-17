defmodule MarketClient.Behaviors.WsApi do
  @moduledoc """
  WsApi is a behavior and `use` macro for Vendor modules
  """

  alias MarketClient.Shared
  alias MarketClient.Resource

  @optional_callbacks start_link: 1,
                      start: 2,
                      stop: 2,
                      get_asset_pair: 1,
                      format_asset_id: 1
  @callback ws_url(Resource.t()) :: binary()
  @callback start_link(Resource.t()) :: {:ok, pid()} | {:error, term()}
  @callback start_link(Resource.t(), boolean()) :: {:ok, pid()} | {:error, term()}
  @callback start(pid(), Resource.t()) :: {:ok, pid()} | {:error, term()}
  @callback stop(pid(), Resource.t()) :: {:ok, pid()} | {:error, term()}
  @callback get_asset_pair(Resource.t()) :: binary()
  @callback format_asset_id(Resource.t()) :: binary()
  @callback msg_subscribe(Resource.t()) :: binary() | List.t()
  @callback msg_unsubscribe(Resource.t()) :: binary() | List.t()

  defmacro __using__([]) do
    unless Shared.is_vendor_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.WsApi is not a public module"
    end

    quote do
      alias MarketClient.{
        Resource,
        Transport.Ws
      }

      @behaviour MarketClient.Behaviors.WsApi

      @spec start_link(Resource.t(), boolean()) :: {:ok, pid()} | {:error, term()}
      def start_link(res = %Resource{}, true), do: Ws.start_link(res, true)

      defoverridable start_link: 2

      @spec start_link(Resource.t()) :: {:ok, pid()} | {:error, term()}
      def start_link(res = %Resource{}), do: Ws.start_link(res)

      defoverridable start_link: 1

      @spec start(pid(), Resource.t()) :: {:ok, pid()} | {:error, term()}

      def start(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
        res
        |> msg_subscribe()
        |> Ws.send_json(pid)
      end

      defoverridable start: 2

      @spec stop(pid(), Resource.t()) :: {:ok, pid()} | {:error, term()}
      def stop(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
        res
        |> msg_unsubscribe()
        |> Ws.send_json(pid)
      end

      defoverridable stop: 2

      @spec get_asset_pair(Resource.t()) :: binary()
      def get_asset_pair(%Resource{asset_id: {:crypto, {c1, c2}}})
          when is_atom(c1) and is_atom(c2) do
        "#{to_string(c1)}/#{to_string(c2)}"
      end

      defoverridable get_asset_pair: 1

      @spec format_asset_id(Resource.t()) :: binary()
      def format_asset_id(res = %Resource{}) do
        get_asset_pair(res)
      end

      defoverridable format_asset_id: 1
    end
  end
end
