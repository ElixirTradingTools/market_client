defmodule MarketClient.ConnectionHandler.Http do
  alias Finch
  require Logger

  def request(url, key) do
    {:ok, _pid} = Finch.start_link(name: FinchHttp)

    Finch.build(:get, url, [{"authorization", "bearer #{key}"}])
    |> Finch.request(FinchHttp)
  end

  def stream(url, headers, callback) do
    {:ok, pid} = Finch.start_link(name: FinchHttp)

    Finch.build(:get, url, headers)
    |> Finch.stream(FinchHttp, nil, callback)

    pid
  end
end
