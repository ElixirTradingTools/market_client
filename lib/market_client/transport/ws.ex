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

  @spec start_link(Resource.t()) :: {:ok, pid} | {:error, term}

  def start_link(res = %Resource{}) do
    mod = MarketClient.get_broker_module(res)
    url = mod.ws_url(res)
    via = mod.ws_via_tuple(res)

    WebSockex.start_link(url, mod, res, name: via)
  end

  @spec send_json(binary | List.t(), pid) :: :ok | {:error, term}

  def send_json(json_msg, pid) when is_binary(json_msg) and (is_pid(pid) or is_tuple(pid)) do
    IO.puts("send_json: #{json_msg}")
    WebSockex.send_frame(pid, {:text, json_msg})
  end

  def send_json(json_msgs, pid) when is_list(json_msgs) and (is_pid(pid) or is_tuple(pid)) do
    Enum.reduce(json_msgs, :ok, fn
      msg, :ok -> send_json(msg, pid)
      _, other -> other
    end)
  end

  def handle_cast({:send, frame = {type, msg}}, res) do
    IO.puts("Sending #{type} frame with payload: #{msg}")
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
    case Jason.decode(msg) do
      {:error, _} ->
        state.listener.({:message, msg})
        {:ok, state}

      {:ok, parsed_json} ->
        state.listener.({:data, parsed_json})
        {:ok, state}
    end
  end

  def handle_disconnect(status, res) do
    Logger.warn("DISCONNECTED: #{inspect(status)}")
    {:ok, res}
  end

  def terminate(close_reason, state) do
    IO.puts("Connection closed: #{inspect(close_reason)}")
    state.listener.({:close, close_reason})
    {:close, state}
  end
end
