defmodule MarketClient.Stream do
  @moduledoc """
  Generate streaming data from `%MarketClient.Resource{}`.
  """
  alias MarketClient.Resource

  require Logger

  @spec new({atom, any}) :: {atom, any} | Stream.t()
  @spec new(Resource.t()) :: Stream.t()

  def new({code, res}) do
    case {code, res} do
      {:ok, %Resource{}} -> new(res)
      _ -> {code, res}
    end
  end

  def new(res = %Resource{}) do
    buffer_via = MarketClient.get_via(res, :buffer)

    Stream.resource(
      fn ->
        res |> MarketClient.start()
      end,
      fn acc ->
        case buffer_via |> GenServer.call(:drain, :infinity) do
          {:messages, list} ->
            {list, acc}

          {:error, reason} ->
            Logger.warn("Stream closed due to error: #{reason}")
            {:halt, acc}
        end
      end,
      fn _ ->
        res |> MarketClient.stop()
        nil
      end
    )
  end
end
