defmodule MarketClient.Behaviors.HttpApi do
  @moduledoc """
  This is the base layer for all HTTP connections in MarketClient.
  `MarketClient.Behaviors.HttpApi` implements the behavior and
  overridable functions used in every vendor module which uses
  HTTP communication.
  """

  alias MarketClient.Resource

  @type method :: :get | :post | :put | :delete | :patch | :head | :options | :trace | :connect
  @callback http_url(Resource.t()) :: binary
  @callback http_method(Resource.t()) :: method()
  @callback http_headers(Resource.t()) :: List.t()
  @callback http_query_params(Resource.t()) :: binary

  defmacro __using__([]) do
    alias MarketClient.Shared

    unless Shared.is_vendor_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.HttpApi is not a public module"
    end

    quote do
      alias MarketClient.{
        Transport.Http,
        Resource
      }

      @behaviour MarketClient.Behaviors.HttpApi

      @spec http_fetch(Resource.t()) :: {:ok, Finch.Response.t()} | {:error, Mint.Types.error()}

      def http_fetch(res = %Resource{}) do
        Http.request(res)
      end
    end
  end
end
