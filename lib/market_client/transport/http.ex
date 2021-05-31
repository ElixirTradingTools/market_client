defmodule MarketClient.Transport.Http do
  @moduledoc """
  All general HTTP connection logic lives here.
  """

  alias __MODULE__, as: Http
  alias MarketClient.Resource

  @type method :: :get | :post | :put | :delete | :patch | :head | :options | :trace | :connect

  @spec start(module) :: DynamicSupervisor.on_start_child()
  @spec request(Resource.t()) ::
          {:ok, Finch.Response.t()}
          | {:error, Mint.Types.error()}
  @spec stream(method, binary, keyword, function) ::
          {:ok, Finch.Response.t()}
          | {:error, Mint.Types.error()}
  @spec headers_from_keywords(keyword) :: list
  @spec header_from_keyword({atom, binary}) :: {binary, binary}

  def start(module) do
    DynamicSupervisor.start_child(MarketClient, {Finch, name: module})
  end

  def request(res = %Resource{}) do
    url = res |> MarketClient.http_url()
    method = res |> MarketClient.http_method()
    headers = res |> MarketClient.http_headers() |> headers_from_keywords()

    method
    |> Finch.build(url, headers)
    |> Finch.request(Http)
    |> res.listener.()
  end

  def stream(method, url, headers, callback) do
    method
    |> Finch.build(url, headers_from_keywords(headers))
    |> Finch.stream(Http, nil, callback)
  end

  def headers_from_keywords([]), do: []

  def headers_from_keywords(keywords) do
    for word <- keywords, reduce: [] do
      acc -> [header_from_keyword(word) | acc]
    end
  end

  def header_from_keyword({:authorization, val}) do
    {"authorization", "bearer #{val}"}
  end

  def header_from_keyword({key, val}) do
    {key |> to_string() |> String.downcase(), val}
  end
end
