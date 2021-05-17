defmodule MarketClient.Transport.Http do
  @moduledoc """
  All general HTTP connection logic lives here.
  """

  alias __MODULE__, as: Http

  @type method :: :get | :post | :put | :delete | :patch | :head | :options | :trace | :connect

  @spec start_link() :: Supervisor.on_start()

  def start_link do
    Finch.start_link(name: Http)
  end

  @spec request(method(), binary(), none() | Keyword.t()) ::
          {:ok, Finch.Response.t()}
          | {:error, Mint.Types.error()}

  def request(method, url, headers \\ []) do
    method
    |> Finch.build(url, headers_from_keywords(headers))
    |> Finch.request(Http)
  end

  @spec stream(method(), binary(), Keyword.t(), function()) ::
          {:ok, Finch.Response.t()}
          | {:error, Mint.Types.error()}

  def stream(method, url, headers, callback) do
    method
    |> Finch.build(url, headers_from_keywords(headers))
    |> Finch.stream(Http, nil, callback)
  end

  @spec headers_from_keywords(Keyword.t()) :: List.t()

  def headers_from_keywords([]), do: []

  def headers_from_keywords(keywords) do
    for word <- keywords, reduce: [] do
      acc -> [header_from_keyword(word) | acc]
    end
  end

  @spec header_from_keyword({atom(), binary()}) :: {binary(), binary()}

  def header_from_keyword({:authorization, val}) do
    {"authorization", "bearer #{val}"}
  end

  def header_from_keyword({key, val}) do
    {key |> to_string() |> String.downcase(), val}
  end
end
