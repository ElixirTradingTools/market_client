defmodule MarketClient.Broker.Polygon.Ws do
  @moduledoc false
  @doc """
  WebSocket client for polygon.io.
  """
  alias MarketClient.{
    Behaviors.WsApi,
    Resource,
    Buffer
  }

  use WsApi

  @typep assets_kwl :: MarketClient.assets_kwl()

  @spec ws_url_via({:polygon, any}, {MarketClient.asset_class(), assets_kwl}) ::
          list({binary, via_tuple, any})

  @impl WsApi
  def ws_url_via({:polygon, _}, {class, assets_kwl}) do
    url =
      case class do
        :forex -> "wss://socket.polygon.io/forex"
        :stock -> "wss://socket.polygon.io/stocks"
        :crypto -> "wss://socket.polygon.io/crypto"
        _ -> raise "invalid asset class: #{inspect(class)}"
      end

    via = MarketClient.get_via(:polygon, assets_kwl, :ws)
    [{url, via, assets_kwl}]
  end

  @impl WsApi
  def handle_connect(_, state) do
    {:ok, state}
  end

  @impl WsApi
  def handle_frame({type, msg}, state = %{buffer: via}) when type in [:text, :binary] do
    %Resource{watch: {class, [{dt, list}]}} = state.res
    {:ok, chan_regex} = Regex.compile(~s("ev":"#{get_channel_id({class, dt, list})}"))

    cond do
      msg == ~s([{"ev":"status","status":"connected","message":"Connected Successfully"}]) ->
        Logger.info("Connection success: #{msg}")
        {:reply, {:text, ws_auth(state.res)}, state}

      msg == ~s([{"ev":"status","status":"auth_success","message":"authenticated"}]) ->
        Logger.info("Auth success: #{msg}")
        {:reply, {:text, ws_subscribe(state.res)}, state}

      Regex.match?(~r("ev":"status"), msg) ->
        Logger.info("Status event: #{msg}")
        {:ok, state}

      Regex.match?(chan_regex, msg) ->
        Buffer.push(via, msg)
        {:ok, state}

      true ->
        Logger.warn("Unknown message: #{msg}, regex is: #{inspect(chan_regex)}")
        {:ok, state}
    end
  end

  @impl WsApi
  def ws_asset_id({class, dt, list}) do
    if(dt == :trades, do: raise(":trades data type is not supported with :forex pairs"))
    get_channel_id({class, dt, list}) <> "." <> get_assets_string(list, "-")
  end

  @impl WsApi
  def ws_subscribe(%Resource{broker: {:polygon, _}, watch: {class, kwl}}) do
    for {dt, list} <- kwl do
      ~s({"action":"subscribe","params":"#{ws_asset_id({class, dt, list})}"})
    end
  end

  @impl WsApi
  def ws_unsubscribe(%Resource{broker: {:polygon, _}, watch: {class, kwl}}) do
    for {dt, list} <- kwl do
      ~s({"action":"unsubscribe","params":"#{ws_asset_id({class, dt, list})}"})
    end
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

  defp get_assets_string(list, sep) do
    for ticker <- list do
      case ticker do
        t when is_binary(t) -> String.upcase(t)
        {a, b} -> String.upcase(a <> sep <> b)
      end
    end
    |> Enum.join(",")
  end
end
