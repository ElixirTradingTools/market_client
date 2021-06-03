defmodule MarketClient.Transport.Http do
  @moduledoc """
  All general HTTP connection logic lives here.
  """

  @spec fetch({binary, MarketClient.http_method(), MarketClient.http_headers()}, module, function) ::
          nil

  @spec stream({binary, MarketClient.http_method(), MarketClient.http_headers()}, function) ::
          {:ok, Finch.Response.t()}
          | {:error, Mint.Types.error()}

  def fetch({url, method, headers}, module, callback) do
    method
    |> Finch.build(url, headers)
    |> Finch.request(module)
    |> case do
      {:ok, %Finch.Response{body: str}} -> apply(callback, [{:ok, str}])
      {:error, error} -> apply(callback, [{:error, error}])
    end

    nil
  end

  def stream({url, method, headers}, callback) do
    method
    |> Finch.build(url, headers)
    |> Finch.stream(MarketClient.Registry, nil, callback)
  end
end
