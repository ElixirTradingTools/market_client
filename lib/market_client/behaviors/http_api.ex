defmodule MarketClient.Behaviors.HttpApi do
  @moduledoc """
  This is the base layer for all HTTP connections in MarketClient.
  `MarketClient.Behaviors.HttpApi` implements the behavior and
  overridable functions used in every broker module which uses
  HTTP communication.
  """

  alias MarketClient.Resource

  @optional_callbacks http_asset_id: 1,
                      http_headers: 1,
                      http_request: 1,
                      http_method: 1,
                      http_start: 1,
                      http_fetch: 1,
                      http_url: 1
  @callback http_asset_id(MarketClient.asset_id()) :: binary
  @callback http_headers(Resource.t()) :: MarketClient.http_headers()
  @callback http_request(Resource.t()) :: any
  @callback http_method(Resource.t()) :: MarketClient.http_method()
  @callback http_start(Resource.t()) :: :ok
  @callback http_fetch(MarketClient.http_conn_attrs()) :: nil
  @callback http_url(Resource.t()) :: binary

  defmacro __using__([]) do
    alias MarketClient.Shared

    unless Shared.is_broker_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.HttpApi is not a public module"
    end

    quote do
      alias MarketClient.{
        Transport.Http,
        Resource
      }

      @behaviour MarketClient.Behaviors.HttpApi

      @typep http_ok :: MarketClient.http_ok()
      @typep http_error :: MarketClient.http_error()

      @spec http_request(Resource.t(), :fetch | :stream) :: http_ok | http_error
      @spec get_url_method_headers(Resource.t()) :: MarketClient.http_conn_attrs()
      @spec http_start(Resource.t()) :: :ok
      @spec http_stop(Resource.t()) :: :ok
      @spec http_fetch(MarketClient.http_conn_attrs()) :: nil
      @spec http_asset_id(MarketClient.asset_id()) :: binary
      @spec http_via_tuple(Resource.t()) :: MarketClient.via_tuple()

      def http_via_tuple(res = %Resource{}) do
        {:via, Registry, {MarketClient.Registry, MarketClient.pid_tuple(res, :http)}}
      end

      def http_start(res = %Resource{}) do
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, {__MODULE__, [res]})
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, {Finch, name: __MODULE__})
        res |> http_via_tuple() |> GenServer.cast(:start)
      end

      def http_stop(res = %Resource{}) do
        res |> http_via_tuple() |> GenServer.cast(:stop)
      end

      def http_fetch({url, method, headers, callback}) do
        Http.fetch({url, method, headers, callback}, __MODULE__)
      end

      def http_request(res = %Resource{}, type \\ :fetch) do
        apply(Http, type, [get_url_method_headers(res)])
      end

      def http_asset_id(asset_id) do
        MarketClient.default_asset_id(asset_id)
      end

      def get_url_method_headers(res = %Resource{}) do
        {http_url(res), http_method(res), http_headers(res), res.listener}
      end

      defoverridable http_request: 1,
                     http_asset_id: 1
    end
  end
end
