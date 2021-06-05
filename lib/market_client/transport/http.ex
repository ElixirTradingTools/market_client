defmodule MarketClient.Transport.Http do
  @moduledoc """
  All general HTTP connection logic lives here.
  """

  @typep http_ok :: MarketClient.http_ok()
  @typep http_error :: MarketClient.http_error()
  @spec fetch(MarketClient.http_conn_attrs(), module) :: any
  @spec stream(MarketClient.http_conn_attrs(), module) :: http_ok | http_error

  def fetch({url, method, headers, callback}, module) do
    method
    |> Finch.build(url, headers)
    |> Finch.request(module)
    |> case do
      {:ok, %Finch.Response{body: str}} -> apply(callback, [{:message, str}])
      {:error, error} -> apply(callback, [{:error, error}])
    end
  end

  def stream({url, method, headers, callback}, module) do
    method
    |> Finch.build(url, headers)
    |> Finch.stream(module, nil, callback)
  end
end
