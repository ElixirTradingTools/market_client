defmodule MarketClient.Broker.Polygon.Ws do
  @moduledoc false
  @doc """
  WebSocket client for polygon.io.
  """
  alias MarketClient.{
    Behaviors.WsApi,
    Resource
  }

  use WsApi, [:polygon]

  @buffer_module MarketClient.get_broker_module(:polygon, :buffer)

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
  def handle_connect(_, res = %Resource{}) do
    {:ok, res}
  end

  @impl WsApi
  def handle_frame({type, msg}, res) when type in [:text, :binary] do
    # aid = get_asset_id(res.asset_id, "/")
    cid = get_channel_id(res.asset_id)
    {:ok, chan_regex} = Regex.compile(~s("ev":"#{cid}"))

    cond do
      msg == ~s([{"ev":"status","status":"connected","message":"Connected Successfully"}]) ->
        Logger.info("Connection success: #{msg}")
        {:reply, {:text, ws_auth(res)}, res}

      msg == ~s([{"ev":"status","status":"auth_success","message":"authenticated"}]) ->
        Logger.info("Auth success: #{msg}")
        {:reply, {:text, ws_subscribe(res)}, res}

      Regex.match?(~r("ev":"status"), msg) ->
        Logger.info("Status event: #{msg}")
        {:ok, res}

      Regex.match?(chan_regex, msg) ->
        apply(@buffer_module, :push, [res, msg])
        {:ok, res}

      true ->
        Logger.warn("Unknown message: #{msg}, regex is: #{inspect(chan_regex)}")
        {:ok, res}
    end
  end

  @impl WsApi
  def ws_asset_id(asset_id) do
    if match?({:forex, :trades, _}, asset_id) do
      raise ":trades data type is not supported with :forex pairs"
    end

    get_channel_id(asset_id) <> "." <> get_asset_id(asset_id, "-")
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

  defp get_channel_id(asset_id) do
    case asset_id do
      {:crypto, :quotes, _} -> "XQ"
      {:crypto, :trades, _} -> "XT"
      {:stock, :quotes, _} -> "Q"
      {:stock, :trades, _} -> "T"
      {:forex, :quotes, _} -> "C"
      {:forex, :trades, _} -> raise ":trades not supported with :forex"
    end
  end

  defp get_asset_id({:stock, _, t}, _) do
    String.upcase(t)
  end

  defp get_asset_id({c, _, {a, b}}, sep) when is_binary(sep) and c in [:forex, :crypto] do
    String.upcase(a) <> sep <> String.upcase(b)
  end
end
