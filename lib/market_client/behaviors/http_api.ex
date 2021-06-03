defmodule MarketClient.Behaviors.HttpApi do
  @moduledoc """
  This is the base layer for all HTTP connections in MarketClient.
  `MarketClient.Behaviors.HttpApi` implements the behavior and
  overridable functions used in every broker module which uses
  HTTP communication.
  """

  alias MarketClient.Resource

  @optional_callbacks http_asset_id: 1,
                      http_url: 1
  @callback http_url(Resource.t()) :: binary
  @callback http_request(Resource.t()) :: {:ok, Finch.Response.t()} | {:error, Mint.Types.error()}
  @callback http_asset_id(MarketClient.asset_id()) :: binary
  @callback http_method(Resource.t()) :: MarketClient.http_method()
  @callback http_headers(Resource.t()) :: MarketClient.http_headers()

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

      @spec http_request(Resource.t(), :fetch | :stream) ::
              {:ok, Finch.Response.t()} | {:error, Mint.Types.error()}
      @spec get_url_method_headers(Resource.t()) ::
              {binary, MarketClient.http_method(), MarketClient.http_headers()}

      def http_start(res = %Resource{}) do
        DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, {Finch, name: __MODULE__})

        res
        |> get_url_method_headers()
        |> Http.fetch(__MODULE__, res.listener)
      end

      def http_request(res = %Resource{}, type \\ :fetch) do
        apply(Http, type, [get_url_method_headers(res), res.listener])
      end

      def http_asset_id(asset_id), do: MarketClient.default_asset_id(asset_id)

      defp get_url_method_headers(res) do
        {
          res |> http_url(),
          res |> http_method(),
          res |> http_headers()
        }
      end

      defoverridable http_request: 1,
                     http_asset_id: 1
    end
  end
end
