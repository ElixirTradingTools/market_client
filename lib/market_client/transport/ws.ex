defmodule MarketClient.Transport.Ws do
  @moduledoc """
  This is the base layer for all WebSocket connections in MarketClient.
  `MarketClient.Behaviors.WsApi` implements the behavior and
  overridable functions used in every vendor module which uses
  WebSocket communication.
  """

  use WebSockex
  alias MarketClient.Resource
  require Logger

  @spec start_link(Resource.t(), atom | nil) :: {:ok, pid} | {:error, any}
  @spec send_json(binary | list, pid | tuple) :: :ok | {:error, any}
  @spec send_json(binary, WebSockex.Conn.t()) :: :ok | {:error, any}

  def start_link(res = %Resource{}, debug \\ nil) do
    mod = MarketClient.get_vendor_module(res)
    url = mod.ws_url(res)
    via = mod.ws_via_tuple(res)

    case debug do
      :debug -> WebSockex.start_link(url, mod, res, name: via, debug: [:trace])
      _ -> WebSockex.start_link(url, mod, res, name: via)
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
    cond do
      is_pid(client) -> loop_send_json(json_msgs, client)
      client == %WebSockex.Conn{} -> loop_send_json(json_msgs, client)
      is_tuple(client) and elem(client, 0) == :via -> loop_send_json(json_msgs, client)
      true -> raise "send_json/2 received invalid client type"
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

  def handle_cast({:send, frame = {type, msg}}, res) do
    Logger.info("Sending #{type} frame with payload: #{msg}")
    {:noreply, frame, res}
  end

  def handle_cast({:close, frame}, res) do
    [
      "Server received close message:",
      "frame: #{inspect(frame)}",
      "resource: #{inspect(res)}"
    ]
    |> Enum.join("\n")
    |> Logger.info()

    {:close, res}
  end

  def handle_cast({any, frame}, res) do
    [
      "Server received unknown message:",
      "type: #{inspect(any)}",
      "message: #{inspect(frame)}",
      "resource: #{inspect(res)}"
    ]
    |> Enum.join("\n")
    |> Logger.info()

    {:noreply, frame, res}
  end

  def handle_frame({:text, msg}, state = %Resource{}) do
    state.listener.(msg)
    {:ok, state}
  end

  def handle_disconnect(status, res) do
    Logger.warn("DISCONNECTED: #{inspect(status)}")
    {:ok, res}
  end

  def terminate(close_reason, state) do
    Logger.info("Connection closed: #{inspect(close_reason)}")
    state.listener.({:close, close_reason})
    {:close, state}
  end
end
