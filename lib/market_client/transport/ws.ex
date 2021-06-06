defmodule MarketClient.Transport.Ws do
  @moduledoc false
  @doc """
  WebSocket client to be managed by users of WsApi behavior & macro.
  """

  use WebSockex
  require Logger

  @typep via_tuple :: MarketClient.via_tuple()
  @typep url :: MarketClient.url()
  @typep send_frame ::
           :ok
           | none
           | {:error,
              %WebSockex.FrameEncodeError{
                __exception__: term,
                close_code: term,
                frame_payload: term,
                frame_type: term,
                reason: term
              }
              | %WebSockex.ConnError{__exception__: term, original: term}
              | %WebSockex.NotConnectedError{__exception__: term, connection_state: term}
              | %WebSockex.InvalidFrameError{__exception__: term, frame: term}}

  @spec start_link(url, module, any, via_tuple) :: {:ok, pid} | {:error, any}
  @spec start_link(url, module, any, via_tuple, keyword) :: {:ok, pid} | {:error, any}
  @spec send_json(binary | list, pid | tuple) :: send_frame
  @spec send_json(binary, WebSockex.Conn.t()) :: send_frame
  @spec send_pong(via_tuple, binary | integer) :: send_frame
  @spec close(via_tuple | pid) :: :ok

  def start_link(url, module, state, via, opts \\ []) do
    if Keyword.get(opts, :debug, false) do
      WebSockex.start_link(url, module, state, name: via, debug: [:trace])
    else
      WebSockex.start_link(url, module, state, name: via)
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

  def handle_cast({:send, {type, msg} = frame}, state) do
    Logger.info("Sending #{type} frame with payload: #{msg}")
    {:noreply, frame, state}
  end

  def handle_cast({:close, frame}, state) do
    Logger.info("Received close message:\n#{inspect({:close, frame})}\nstate: #{inspect(state)}")
    {:close, state}
  end

  def handle_cast({type, frame}, state) do
    Logger.info("Unknown message:\n#{inspect({type, frame})}\nstate: #{inspect(state)}")
    {:noreply, frame, state}
  end

  def handle_frame({:text, msg}, state) do
    apply(state.listener, [{:message, msg}])
    {:ok, state}
  end

  def handle_disconnect(status, state) do
    Logger.warn("DISCONNECTED: #{inspect(status)}\nstate: #{inspect(state)}")
    apply(state.listener, [{:disconnect, status}])
    {:ok, state}
  end

  def terminate(close_reason, state) do
    Logger.info("Connection closed: #{inspect(close_reason)}")
    apply(state.listener, [{:close, close_reason}])
    {:close, state}
  end
end
