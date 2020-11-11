defmodule MarketClient.Socket do
  alias MarketClient.Resource
  alias MarketClient.Broker
  alias WebSockex, as: WS
  use WebSockex

  def start(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
    res |> Broker.subscribe() |> ws_send(pid)
  end

  def stop(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
    res |> Broker.unsubscribe() |> ws_send(pid)
    WS.cast(pid, :close)
  end

  def start_link(res = %Resource{}) do
    res |> Broker.url() |> WS.start_link(__MODULE__, res)
  end

  def ws_send(json_msg, pid) when is_binary(json_msg) and (is_pid(pid) or is_tuple(pid)) do
    WS.send_frame(pid, {:text, json_msg})
  end

  def ws_send(json_msgs, pid) when is_list(json_msgs) and (is_pid(pid) or is_tuple(pid)) do
    Enum.each(json_msgs, &ws_send(&1, pid))
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end

  def handle_cast(:close, _res),
    do: {:close, nil}

  def terminate(_close_reason, state) do
    case state do
      %{handler: {:file, handle}} ->
        File.close(handle)
        {:close, state}

      _ ->
        {:close, state}
    end
  end

  def handle_frame({:text, msg}, state = %{handler: {:file, handle}}) do
    case Jason.decode!(msg) do
      %{"message" => "unsubscribed" <> _} ->
        {:close, state}

      msg ->
        IO.inspect(msg)
        IO.write(handle, "#{msg}\n")
        {:ok, state}
    end
  end

  def handle_frame({:text, msg}, state = %{handler: {:func, cb}}) when is_function(cb) do
    case Jason.decode!(msg) do
      nil ->
        {:ok, state}

      result ->
        cb.(result)
        {:ok, state}
    end
  end
end
