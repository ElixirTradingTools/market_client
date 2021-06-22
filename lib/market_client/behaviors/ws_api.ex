defmodule MarketClient.Behaviors.WsApi do
  @moduledoc """
  Reusable core implementation for WebSocket client modules. Any supported
  broker with a WebSocket API will use `use WsApi`. See contributor guide
  and modules like Polygon for help and examples of how to use this.
  """

  alias MarketClient.{
    Resource,
    Shared
  }

  @optional_callbacks handle_ping: 2,
                      handle_connect: 2,
                      ws_asset_id: 2,
                      ws_asset_id: 1,
                      ws_start: 1,
                      ws_stop: 1

  @typep resource :: MarketClient.resource()
  @typep via_tuple :: MarketClient.via_tuple()
  @typep broker_opts :: MarketClient.broker_opts()
  @typep assets_list :: MarketClient.equities_list() | MarketClient.currencies_list()
  @typep asset_class :: MarketClient.asset_class()
  @typep valid_data_type :: MarketClient.valid_data_type()
  @typep frame :: WebSockex.frame()
  @typep state :: %{res: resource, buffer: via_tuple}

  @callback ws_url_via({atom, broker_opts}, {asset_class, assets_list}) ::
              list({binary, via_tuple, any})
  @callback ws_subscribe(resource) :: binary | list(binary)
  @callback ws_unsubscribe(resource) :: binary | list(binary)
  @callback handle_ping(:ping | {:ping, binary}, state) :: {:reply, frame, state}
  @callback ws_start(resource) :: list(MarketClient.DynamicSupervisor.on_start_child())
  @callback ws_stop(pid | resource | MarketClient.via_tuple()) ::
              :ok | {:error, any}
  @callback ws_asset_id({asset_class, valid_data_type, assets_list}) :: binary
  @callback ws_asset_id({asset_class, valid_data_type, assets_list}, :list | :string) ::
              list | binary
  @callback handle_connect(WebSockex.Conn.t(), state) :: {:ok, state}
  @callback handle_frame(frame, state) ::
              {:ok, state}
              | {:reply, frame, state}
              | {:close, state}
              | {:close, WebSockex.close_frame(), state}

  defmacro __using__([]) do
    unless Shared.is_broker_module(__CALLER__.module) do
      raise "MarketClient.Behaviors.WsApi is not a public module"
    end

    quote do
      require Logger

      alias MarketClient.{
        Transport.Ws,
        Resource,
        Buffer
      }

      @behaviour MarketClient.Behaviors.WsApi

      @ohlc_types MarketClient.ohlc_types()

      @typep assets_list :: MarketClient.equities_list() | MarketClient.currencies_list()
      @typep valid_data_type :: MarketClient.valid_data_type()
      @typep asset_class :: MarketClient.asset_class()
      @typep via_tuple :: MarketClient.via_tuple()
      @typep resource :: MarketClient.resource()
      @typep frame :: WebSockex.frame()
      @typep state :: %{res: resource, buffer: via_tuple}

      @spec ws_start(resource) :: list(MarketClient.DynamicSupervisor.on_start_child())
      @spec ws_stop(pid | resource | MarketClient.via_tuple()) ::
              :ok | {:error, any}
      @spec ws_asset_id({asset_class, valid_data_type, assets_list}) :: binary
      @spec ws_asset_id({asset_class, valid_data_type, assets_list}, :list | :string) :: binary
      @spec handle_connect(WebSockex.Conn.t(), state) :: {:ok, state}
      @spec handle_frame(frame, state) ::
              {:ok, state}
              | {:reply, frame, state}
              | {:close, state}
              | {:close, WebSockex.close_frame(), state}

      def ws_start(res = %Resource{broker: broker = {bn, _}, watch: watch = {class, _}}) do
        for {url, ws_via, assets_kwl} <- ws_url_via(broker, watch) do
          {:via, _, {_, res_id}} = ws_via

          resource = Map.put(res, :watch, {class, assets_kwl})

          MarketClient.DynamicSupervisor.start_child(%{
            id: res_id,
            start: {__MODULE__, :start_link, [url, resource, ws_via]}
          })
        end
      end

      def start_link(url, res = %Resource{options: opts}, ws_via) do
        state = %{res: res, buffer: Buffer.get_via(res)}

        opts =
          if Keyword.get(opts, :debug, false) do
            [name: ws_via, debug: [:trace]]
          else
            [name: ws_via]
          end

        Ws.start_link(url, __MODULE__, state, opts)
      end

      def ws_stop(client) do
        case client do
          %Resource{broker: {bn, _}, watch: {_, kwl}} -> MarketClient.get_via(bn, kwl, :ws)
          client when is_pid(client) -> client
          {:via, _, _} -> client
        end
        |> Ws.close()
      end

      def ws_asset_id(asset_tuple, type \\ :list) do
        MarketClient.default_asset_id(asset_tuple, type)
      end

      def handle_connect(conn, state) do
        Logger.info("handle_connect")

        %{res: res} = state
        res |> ws_subscribe() |> Ws.send_json(conn)
        {:ok, state}
      end

      def handle_frame({type, msg}, state = %{buffer: via}) do
        case type do
          :text -> MarketClient.Buffer.push(via, msg)
          _ -> Logger.warn("Unknown frame: #{inspect({type, msg})}")
        end

        {:ok, state}
      end

      def handle_ping(ping_frame, state = %{res: res}) do
        case ping_frame do
          {:ping, id} -> {:reply, {:pong, id}, state}
          :ping -> {:reply, {:pong, ""}, state}
        end
      end

      defoverridable handle_connect: 2,
                     handle_frame: 2,
                     handle_ping: 2,
                     ws_asset_id: 2,
                     ws_asset_id: 1,
                     ws_start: 1,
                     ws_stop: 1
    end
  end
end
