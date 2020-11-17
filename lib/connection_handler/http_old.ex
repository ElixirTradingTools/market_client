defmodule MarketClient.ConnectionHandler.HttpOld do
end

#   require Logger

#   defstruct [:conn, :polling, :target, requests: %{}]

#   def start_link({:https, _host, 443}) do
#   end

#   def request(pid, {method, path, headers, body}) do
#     GenServer.call(pid, {:request, method, path, headers, body})
#   end

#   def poll(pid, target = {_, _, _, _}, {freq_ms, callback}) do
#     Process.send(pid, {:poll_start, target, freq_ms, callback}, [:noconnect])
#   end

#   def halt(pid) do
#     Process.send(pid, :halt, [:noconnect])
#   end

#   def die(pid) do
#     GenServer.cast(pid, :die)
#   end

#   def new_request({method, path, headers, body}, _from, state) do
#     # In both the successful case and the error case, we make sure to update the connection
#     # struct in the state since the connection is an immutable data structure.
#     case Mint.HTTP.request(state.conn, method, path, headers, body) do
#       {:ok, conn, request_ref} ->
#         # We store the caller this request belongs to and an empty map as the response.
#         # The map will be filled with status code, headers, and so on.
#         state = put_in(state.conn, conn)
#         state = put_in(state.requests[request_ref], %{response: %{}})
#         {:ok, state}

#       {:error, conn, reason} ->
#         Logger.error(fn -> "Error: #{reason}" end)
#         state = put_in(state.conn, conn)
#         {:error, reason, state}
#     end
#   end

#   ## Callbacks

#   @impl true
#   def init({scheme, host, port}) do
#     case Mint.HTTP.connect(scheme, host, port) do
#       {:ok, conn} ->
#         state = %MarketClient.ConnectionHandler.HTTP{conn: conn}
#         {:ok, state}

#       {:error, reason} ->
#         Logger.error(fn -> "Error: " <> inspect(reason) end)
#         {:stop, reason}
#     end
#   end

#   @impl true
#   def handle_cast(:die, _) do
#     {:stop, :normal, nil}
#   end

#   @impl true
#   def handle_call({:request, method, path, headers, body}, from, state) do
#     case new_request({method, path, headers, body}, from, state) do
#       {:ok, state} ->
#         {:noreply, state}

#       {:error, reason, state} ->
#         Logger.error(fn -> "Error: " <> inspect(reason) end)
#         {:noreply, state}
#     end
#   end

#   @impl true
#   def handle_info({:poll_start, target, freq_ms, callback}, state) do
#     Process.send_after(self(), :poll, freq_ms)
#     state = put_in(state.polling, {freq_ms, callback})
#     state = put_in(state.target, target)
#     {:noreply, state}
#   end

#   @impl true
#   def handle_info(:poll, state) do
#     case state do
#       %{polling: {freq_ms, _}, target: target} ->
#         case new_request(target, nil, state) do
#           {:ok, state} ->
#             Process.send_after(self(), :poll, freq_ms)
#             {:noreply, state}

#           {:error, reason, state} ->
#             Logger.error(fn -> "Error: " <> inspect(reason) end)
#             {:noreply, state}
#         end

#       msg ->
#         Logger.error(fn -> "Unknown message: " <> inspect(msg) end)
#         {:noreply, state}
#     end
#   end

#   @impl true
#   def handle_info(:halt, state) do
#     state = put_in(state.polling, nil)
#     {:noreply, state}
#   end

#   @impl true
#   def handle_info(message, state) do
#     # We should handle the error case here as well, but we're omitting it for brevity.
#     case Mint.HTTP.stream(state.conn, message) do
#       :unknown ->
#         Logger.error(fn -> "Received unknown message: " <> inspect(message) end)
#         {:noreply, state}

#       {:ok, conn, responses} ->
#         state = put_in(state.conn, conn)
#         state = Enum.reduce(responses, state, &process_response/2)
#         {:noreply, state}
#     end
#   end

#   defp process_response({:status, request_ref, status}, state) do
#     put_in(state.requests[request_ref].response[:status], status)
#   end

#   defp process_response({:headers, request_ref, headers}, state) do
#     put_in(state.requests[request_ref].response[:headers], headers)
#   end

#   defp process_response({:data, request_ref, new_data}, state) do
#     update_in(state.requests[request_ref].response[:data], fn data -> (data || "") <> new_data end)
#   end

#   # When the request is done, we use GenServer.reply/2 to reply to the caller that was
#   # blocked waiting on this request.
#   defp process_response({:done, request_ref}, state) do
#     case pop_in(state.requests[request_ref]) do
#       {%{response: response}, state = %{polling: {_, callback}}} ->
#         callback.(response)
#         state

#       {_, state} ->
#         IO.puts("something went wrong")
#         state
#     end
#   end
# end
