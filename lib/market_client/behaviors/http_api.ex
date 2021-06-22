defmodule MarketClient.Behaviors.HttpApi do
  @moduledoc """
  Reusable core implementation for HTTP client modules. Any supported
  broker with a REST API will use `use HttpApi`. See contributor guide
  and modules like Oanda for help and examples of how to use this.
  """

  alias MarketClient.Resource

  @typep currencies_list :: MarketClient.currencies_list()

  @optional_callbacks push_to_stream: 2,
                      http_asset_id: 1,
                      http_headers: 1,
                      http_request: 2,
                      http_request: 1,
                      http_method: 1,
                      http_start: 1,
                      http_fetch: 2,
                      http_url: 1
  @callback http_asset_id({:forex, currencies_list}) :: binary
  @callback http_headers(MarketClient.resource()) :: MarketClient.http_headers()
  @callback http_request(MarketClient.resource()) :: any
  @callback http_request(MarketClient.resource(), :fetch | :stream) :: any
  @callback http_method(MarketClient.resource()) :: MarketClient.http_method()
  @callback http_start(MarketClient.resource()) :: :ok
  @callback http_fetch(MarketClient.http_conn_attrs(), fun) :: nil
  @callback http_url(MarketClient.resource()) :: binary
  @callback push_to_stream(MarketClient.via_tuple(), binary) :: no_return

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
      @typep data_type :: MarketClient.valid_data_type()
      @typep currencies_list :: MarketClient.currencies_list()

      @spec http_request(MarketClient.resource()) :: http_ok | http_error
      @spec http_request(MarketClient.resource(), :fetch | :stream) :: http_ok | http_error
      @spec get_url_method_headers(MarketClient.resource()) :: MarketClient.http_conn_attrs()
      @spec http_start(MarketClient.resource()) :: :ok
      @spec http_stop(MarketClient.resource()) :: :ok
      @spec http_fetch(MarketClient.http_conn_attrs(), fun) :: nil
      @spec http_asset_id({data_type, currencies_list}) :: binary
      @spec push_to_stream(MarketClient.via_tuple(), binary) :: no_return

      def http_start(res = %Resource{broker: {broker_name, _}, watch: assets}) do
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, {__MODULE__, [res]})
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, {Finch, name: __MODULE__})

        broker_name
        |> MarketClient.get_via(assets, :http)
        |> GenServer.cast(:start)
      end

      def http_stop(res = %Resource{broker: {broker_name, _}, watch: assets}) do
        broker_name
        |> MarketClient.get_via(assets, :http)
        |> GenServer.cast(:stop)
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

      def http_asset_id({dt, list}) do
        MarketClient.default_asset_id({dt, list})
      end

      def get_url_method_headers(res = %Resource{}) do
        {http_url(res), http_method(res), http_headers(res)}
      end

      def push_to_stream(buffer_via, msg) do
        MarketClient.Buffer.push(buffer_via, msg)
      end

      defoverridable http_asset_id: 1,
                     http_request: 2,
                     http_request: 1
    end
  end
end
