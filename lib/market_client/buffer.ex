defmodule MarketClient.Buffer do
  use GenServer

  alias MarketClient.Resource

  @default_state {false, nil, :queue.new()}

  @typep via_tuple :: MarketClient.via_tuple()
  @typep resource :: MarketClient.resource()

  @spec get_via(resource) :: via_tuple
  @spec start_link(via_tuple) :: GenServer.on_start()
  @spec start(resource) :: DynamicSupervisor.on_start_child()
  @spec stop(via_tuple | resource) :: :ok
  @spec push(via_tuple | resource, binary) :: :ok

  ### Client ###

  def start_link(via) do
    GenServer.start_link(__MODULE__, @default_state, name: via)
  end

  def get_via(%Resource{broker: {bn, _}, watch: watch_tuple}) do
    MarketClient.get_via(bn, watch_tuple, :buffer)
  end

  def start(res = %Resource{}) do
    DynamicSupervisor.start_child(MarketClient.DynamicSupervisor, %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [get_via(res)]}
    })
  end

  def stop(id) do
    case id do
      res = %Resource{} -> res |> get_via() |> GenServer.cast({:stop, :normal})
      via = {:via, _, _} -> via |> GenServer.cast({:stop, :normal})
    end
  end

  def push(id, msg) when is_binary(msg) do
    case id do
      via = {:via, _, _} -> GenServer.cast(via, {:push, msg})
      res = %Resource{} -> res |> get_via() |> GenServer.cast({:push, msg})
    end
  end

  ### Server ###

  @impl GenServer
  def init(state), do: {:ok, state}

  @impl GenServer
  def handle_call(:drain, _, {true, _, msgs}) do
    {:reply, {:messages, :queue.to_list(msgs)}, @default_state}
  end

  @impl GenServer
  def handle_call(:drain, from = {pid, _}, {false, _, msgs}) when is_pid(pid) do
    {:noreply, {false, from, msgs}}
  end

  @impl GenServer
  def handle_cast({:push, msgs}, {_, from, q}) when is_binary(msgs) or is_list(msgs) do
    case from do
      nil ->
        {:noreply, {true, nil, q |> update_queue(msgs)}}

      from = {pid, _} when is_pid(pid) ->
        GenServer.reply(from, {:messages, q |> update_queue(msgs) |> :queue.to_list()})
        {:noreply, @default_state}
    end
  end

  @impl GenServer
  def handle_cast({:stop, :normal}, _) do
    {:stop, :normal, nil}
  end

  @impl GenServer
  def terminate(_, _) do
    nil
  end

  defp update_queue(queue, new_msgs) when is_list(new_msgs) do
    Enum.reduce(new_msgs, queue, &:queue.in/2)
  end

  defp update_queue(queue, new_msg) when is_binary(new_msg) do
    :queue.in(new_msg, queue)
  end
end
