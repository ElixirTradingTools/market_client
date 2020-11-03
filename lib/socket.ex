defmodule MarketClient.Socket do
  alias __MODULE__, as: Socket
  alias MarketClient.Resource
  alias MarketClient.Broker
  alias WebSockex, as: WS
  use WebSockex

  def start(resource = %Resource{socket_pid: nil}) do
    {:ok, pid} = start_link(resource)
    resource = Map.put(resource, :socket_pid, pid)
    resource |> Broker.subscribe() |> ws_send(resource)
    resource
  end

  def stop(resource = %Resource{socket_pid: pid}) when is_pid(pid) do
    resource |> Broker.unsubscribe() |> ws_send(resource)
    WS.cast(resource.socket_pid, :close)
    Map.put(resource, :socket_pid, nil)
  end

  def start_link(res = %Resource{}) do
    res |> Broker.url() |> WS.start_link(Socket, res)
  end

  def ws_send(json_msg, %Resource{socket_pid: pid})
      when is_binary(json_msg) and is_pid(pid) do
    WS.send_frame(pid, {:text, json_msg})
  end

  def ws_send(json_msgs, resource = %Resource{socket_pid: pid})
      when is_list(json_msgs) and is_pid(pid) do
    json_msgs
    |> Enum.each(&ws_send(&1, resource))
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end

  def handle_cast(:close, _resource), do: {:close, nil}

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
