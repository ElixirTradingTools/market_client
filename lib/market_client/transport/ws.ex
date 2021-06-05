defmodule MarketClient.Transport.Ws do
  @moduledoc """
  This is the base layer for all WebSocket connections in MarketClient.
  `MarketClient.Behaviors.WsApi` implements the behavior and
  overridable functions used in every broker module which uses
  WebSocket communication.
  """

  use WebSockex
  alias MarketClient.Resource
  require Logger

  @spec start_link(Resource.t()) :: {:ok, pid} | {:error, any}
  @spec start_link(Resource.t(), keyword) :: {:ok, pid} | {:error, any}
  @spec send_json(binary | list, pid | tuple) :: :ok | {:error, any}
  @spec send_json(binary, WebSockex.Conn.t()) :: :ok | {:error, any}

  def start_link(res = %Resource{}, opts \\ []) do
    mod = MarketClient.get_broker_module(res, :ws)
    url = mod.ws_url(res)
    via = mod.ws_via_tuple(res)

    if Keyword.get(opts, :debug, false) do
      WebSockex.start_link(url, mod, res, name: via, debug: [:trace])
    else
      WebSockex.start_link(url, mod, res, name: via)
    end
  end

  def send_json(json_msg, conn = %WebSockex.Conn{}) when is_binary(json_msg) do
    Logger.info("send_json: #{json_msg}")

    case WebSockex.Frame.encode_frame({:text, json_msg}) do
      {:ok, frame} -> WebSockex.Conn.socket_send(conn, frame)
      other -> other
    end
  end

  def send_json(json_msg, pid) when is_binary(json_msg) and (is_pid(pid) or is_tuple(pid)) do
    Logger.info("send_json: #{json_msg}")
    WebSockex.send_frame(pid, {:text, json_msg})
  end

  def send_json(json_msgs, client) when is_list(json_msgs) do
    case client do
      c when is_pid(c) -> loop_send_json(json_msgs, client)
      %WebSockex.Conn{} -> loop_send_json(json_msgs, client)
      {:via, _, _} -> loop_send_json(json_msgs, client)
      _ -> raise "send_json/2 received invalid type for client arg"
    end
  end

  defp loop_send_json(json_msgs, client) do
    Enum.reduce(json_msgs, :ok, fn
      msg, :ok when is_binary(msg) -> send_json(msg, client)
      _, other -> other
    end)
  end

  def send_pong(via_tuple, id) do
    WebSockex.send_frame(via_tuple, {:pong, id})
  end

  def close(client) do
    WebSockex.cast(client, {:close, ""})
  end

  def handle_cast({:send, {type, msg} = frame}, res) do
    Logger.info("Sending #{type} frame with payload: #{msg}")
    {:noreply, frame, res}
  end

  def handle_cast({:close, frame}, res) do
    Logger.info("Received close message:\n#{inspect({:close, frame})}\nresource: #{inspect(res)}")
    {:close, res}
  end

  def handle_cast({any, frame}, res) do
    Logger.info("Unknown message:\n#{inspect({any, frame})}\nresource: #{inspect(res)}")
    {:noreply, frame, res}
  end

  def handle_frame({:text, msg}, state = %Resource{}) do
    apply(state.listener, [msg])
    {:ok, state}
  end

  def handle_disconnect(status, res) do
    Logger.warn("DISCONNECTED: #{inspect(status)}")
    {:ok, res}
  end

  def terminate(close_reason, state) do
    Logger.info("Connection closed: #{inspect(close_reason)}")
    apply(state.listener, [{:close, close_reason}])
    {:close, state}
  end
end