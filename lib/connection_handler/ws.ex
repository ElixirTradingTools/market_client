defmodule MarketClient.ConnectionHandler.Ws do
  alias MarketClient.Resource

  require Logger

  use WebSockex

  def start_link(res = %Resource{}) do
    res
    |> MarketClient.url()
    |> WebSockex.start_link(__MODULE__, res)
  end

  def send_json(json_msg, pid) when is_binary(json_msg) and (is_pid(pid) or is_tuple(pid)) do
    IO.puts("send_json: #{json_msg}")
    WebSockex.send_frame(pid, {:text, json_msg})
  end

  def send_json(json_msgs, pid) when is_list(json_msgs) and (is_pid(pid) or is_tuple(pid)) do
    Enum.each(json_msgs, &send_json(&1, pid))
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
    Logger.info("Received frame:\n#{msg}")

    case Jason.decode(msg) do
      {:error, _} ->
        state.listener.({:message, msg})
        {:ok, state}

      {:ok, parsed_json} ->
        state.listener.({:data, parsed_json})
        {:ok, state}
    end
  end

  def terminate(close_reason, state) do
    IO.puts("Connection closed: #{inspect(close_reason)}")
    state.listener.({:close, close_reason})
    {:close, state}
  end
end
