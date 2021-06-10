defmodule MarketClient.Behaviors.Buffer do
  defmacro __using__([broker]) do
    quote do
      use GenServer

      alias MarketClient.Resource

      @default_state {false, nil, :queue.new()}
      @via MarketClient.get_via(unquote(broker), :buffer)

      ### Client ###

      def start(res = %Resource{}) do
        alias MarketClient, as: MC
        {:ok, _} = DynamicSupervisor.start_child(MC.DynamicSupervisor, child_spec(res))
      end

      def push(res = %Resource{}, msg) when is_binary(msg) do
        GenServer.cast(@via, {:push, msg})
      end

      def child_spec(res = %Resource{broker: {broker_name, _}}) do
        %{
          id: @via,
          start: {__MODULE__, :start_link, [res]}
        }
      end

      def start_link(%Resource{broker: {broker, _}}) do
        GenServer.start_link(__MODULE__, @default_state, name: @via)
      end

      ### Server ###

      @impl true
      def init(state), do: {:ok, state}

      @impl true
      def handle_call(:drain, _, {true, _, msgs}) do
        {:reply, {:messages, :queue.to_list(msgs)}, @default_state}
      end

      @impl true
      def handle_call(:drain, from = {pid, _}, {false, _, msgs}) when is_pid(pid) do
        {:noreply, {false, from, msgs}}
      end

      @impl true
      def handle_cast({:push, msgs}, {_, from, q}) when is_binary(msgs) or is_list(msgs) do
        case from do
          nil ->
            {:noreply, {true, nil, q |> update_queue(msgs)}}

          from = {pid, _} when is_pid(pid) ->
            GenServer.reply(from, {:messages, q |> update_queue(msgs) |> :queue.to_list()})
            {:noreply, @default_state}
        end
      end

      defp update_queue(queue, new_msgs) when is_list(new_msgs) do
        Enum.reduce(new_msgs, queue, &:queue.in/2)
      end

      defp update_queue(queue, new_msg) when is_binary(new_msg) do
        :queue.in(new_msg, queue)
      end
    end
  end
end
