defmodule MarketClient.Broker.Polygon.Ws do
  @moduledoc false
  @doc """
  WebSocket client for polygon.io.
  """
  alias MarketClient.{
    Behaviors.WsApi,
    Resource,
    Shared
  }

  use WsApi

  @spec ws_url(Resource.t()) :: binary

  @impl WsApi
  def ws_url(%Resource{broker: {:polygon, _}, asset_id: {class, _, _}}) do
    case class do
      :forex -> "wss://socket.polygon.io/forex"
      :stock -> "wss://socket.polygon.io/stocks"
      :crypto -> "wss://socket.polygon.io/crypto"
    end
  end

  @impl WsApi
  def handle_connect(_, res = %Resource{}), do: {:ok, res}

  @impl WsApi
  def handle_frame({type, msg}, res) when type in [:text, :binary] do
    cond do
      Regex.match?(~r("message":"Connected Successfully"), msg) ->
        {:reply, {:text, ws_auth(res)}, res}

      Regex.match?(~r("message":"authenticated"), msg) ->
        {:reply, {:text, ws_subscribe(res)}, res}

      true ->
        apply(res.listener, [{:ok, msg}])
        {:ok, res}
    end
  end

  @impl WsApi
  def ws_asset_id({:stock, data_type, ticker}) when is_binary(ticker) do
    case data_type do
      :quotes -> "Q.#{String.upcase(ticker)}"
      :trades -> "T.#{String.upcase(ticker)}"
    end
  end

  @impl WsApi
  def ws_asset_id({:crypto, data_type, {a, b}}) do
    case data_type do
      :quotes -> "XQ.#{Shared.a2s_upcased(a)}-#{Shared.a2s_upcased(b)}"
      :trades -> "XT.#{Shared.a2s_upcased(a)}-#{Shared.a2s_upcased(b)}"
    end
  end

  @impl WsApi
  def ws_asset_id({:forex, data_type, {a, b}}) do
    case data_type do
      :quotes -> "Q.#{Shared.a2s_upcased(a)}-#{Shared.a2s_upcased(b)}"
      :trades -> raise ":trades data type is not supported with :forex pairs"
    end
  end

  @impl WsApi
  def ws_subscribe(res = %Resource{broker: {:polygon, _}}) do
    ~s({"action":"subscribe","params":"#{ws_asset_id(res.asset_id)}"})
  end

  @impl WsApi
  def ws_unsubscribe(res = %Resource{broker: {:polygon, _}}) do
    ~s({"action":"unsubscribe","params":"#{ws_asset_id(res.asset_id)}"})
  end

  defp ws_auth(%Resource{broker: {:polygon, opts}}) do
    case Keyword.get(opts, :key, nil) do
      nil -> raise "no entry found for :key in broker options"
      key -> ~s({"action":"auth","params":"#{key}"})
    end
  end
end
