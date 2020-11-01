defmodule MarketClient.Socket do
  alias __MODULE__, as: Socket
  alias MarketClient.Resource
  alias MarketClient.Broker
  use WebSockex

  def start(resource = %Resource{socket_pid: nil}) do
    {:ok, pid} = start_link(resource)
    resource = Map.put(resource, :socket_pid, pid)

    resource
    |> Broker.subscribe()
    |> push(resource)

    resource
  end

  def stop(resource = %Resource{socket_pid: pid}) when is_pid(pid) do
    resource
    |> Broker.unsubscribe()
    |> push(resource)
  end

  def start_link(resource = %Resource{broker: broker}) do
    broker
    |> Broker.url()
    |> WebSockex.start_link(Socket, resource)
  end

  def push(json_msg, %Resource{socket_pid: pid})
      when is_binary(json_msg) and is_pid(pid) do
    WebSockex.send_frame(pid, {:text, json_msg})
  end

  def push(json_msgs, resource = %Resource{socket_pid: pid})
      when is_list(json_msgs) and is_pid(pid) do
    Enum.each(json_msgs, fn msg -> push(msg, resource) end)
  end

  # def parse_payload([%{"s" => t, "v" => v, "vw" => w, "o" => o, "c" => c, "h" => h, "l" => l}]),
  #   do: %{t: trunc(t * 0.001), h: h, l: l, o: o, c: c, v: v, vw: w}

  # def parse_payload(_),
  #   do: nil

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end

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
