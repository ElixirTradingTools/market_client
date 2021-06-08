defmodule MarketClient.Behaviors.HttpApi do
  @moduledoc """
  Reusable core implementation for HTTP client modules. Any supported
  broker with a REST API will use `use HttpApi`. See contributor guide
  and modules like Oanda for help and examples of how to use this.
  """

  alias MarketClient.Resource

  @optional_callbacks http_asset_id: 1,
                      http_headers: 1,
                      http_request: 1,
                      http_method: 1,
                      http_start: 1,
                      http_fetch: 2,
                      http_url: 1
  @callback http_asset_id(MarketClient.asset_id()) :: binary
  @callback http_headers(Resource.t()) :: MarketClient.http_headers()
  @callback http_request(Resource.t()) :: any
  @callback http_method(Resource.t()) :: MarketClient.http_method()
  @callback http_start(Resource.t()) :: :ok
  @callback http_fetch(MarketClient.http_conn_attrs(), fun) :: nil
  @callback http_url(Resource.t()) :: binary

  defmacro __using__([]) do
    alias MarketClient.Shared

    unless Shared.is_broker_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.HttpApi is not a public module"
    end

    quote do
      require Logger

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
      @spec http_fetch(MarketClient.http_conn_attrs(), fun) :: nil
      @spec http_asset_id(MarketClient.asset_id()) :: binary

      def http_start(res = %Resource{}) do
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, {__MODULE__, [res]})
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, {Finch, name: __MODULE__})
        res |> MarketClient.get_via(:http) |> GenServer.cast(:start)
      end

      def http_stop(res = %Resource{}) do
        res |> MarketClient.get_via(:http) |> GenServer.cast(:stop)
      end

      def http_fetch({url, method, headers}, callback) do
        Http.fetch({url, method, headers}, __MODULE__, fn
          {:message, text} -> apply(callback, [text])
          {:error, text} -> Logger.error("HTTP error: #{text}")
        end)
      end

      def http_request(res = %Resource{}, type \\ :fetch) do
        apply(Http, type, [get_url_method_headers(res)])
      end

      def http_asset_id(asset_id) do
        MarketClient.default_asset_id(asset_id)
      end

      def get_url_method_headers(res = %Resource{}) do
        {http_url(res), http_method(res), http_headers(res)}
      end

      def push_to_stream(msg, %Resource{broker: {broker, _}}) do
        MarketClient.get_via(broker, :buffer) |> GenServer.cast({:push, msg})
      end

      defoverridable http_request: 1,
                     http_asset_id: 1
    end
  end
end
