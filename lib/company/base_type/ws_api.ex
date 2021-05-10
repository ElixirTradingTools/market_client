defmodule MarketClient.Company.BaseType.WsApi do
  @allowed_callers [
    MarketClient.Company.BinanceGlobal,
    MarketClient.Company.BinanceUs,
    MarketClient.Company.Coinbase,
    MarketClient.Company.Polygon,
    MarketClient.Company.FtxUs,
    MarketClient.Company.Oanda
  ]

  @optional_callbacks start_link: 1,
                      start: 2,
                      stop: 2,
                      get_asset_pair: 1,
                      format_asset_id: 1

  @callback url(struct()) :: binary()

  @callback start_link(struct()) :: {:ok, pid()} | {:error, term()}

  @callback start(pid(), struct()) :: {:ok, pid()} | {:error, term()}

  @callback stop(pid(), struct()) :: {:ok, pid()} | {:error, term()}

  @callback get_asset_pair(struct()) :: binary()

  @callback format_asset_id(struct()) :: binary()

  @callback msg_subscribe(struct()) :: binary() | List.t()

  @callback msg_unsubscribe(struct()) :: binary() | List.t()

  defmacro __using__([]) do
    unless __CALLER__.module in @allowed_callers do
      raise "WsApi is only for internal use"
    end

    quote do
      alias MarketClient.{
        Resource,
        ConnectionHandler.Ws
      }

      @behaviour MarketClient.Company.BaseType.WsApi

      @spec start_link(struct()) :: {:ok, pid()} | {:error, term()}

      def start_link(res = %Resource{}) do
        res
        |> url()
        |> Ws.start_link(res)
      end

      defoverridable start_link: 1

      @spec start(pid(), struct()) :: {:ok, pid()} | {:error, term()}

      def start(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
        res
        |> msg_subscribe()
        |> Ws.send_json(pid)
      end

      defoverridable start: 2

      @spec stop(pid(), struct()) :: {:ok, pid()} | {:error, term()}
      def stop(pid, res = %Resource{}) when is_pid(pid) or is_tuple(pid) do
        res
        |> msg_unsubscribe()
        |> Ws.send_json(pid)
      end

      defoverridable stop: 2

      @spec get_asset_pair(struct()) :: binary()
      def get_asset_pair(%Resource{asset_id: {:crypto, {c1, c2}}})
          when is_atom(c1) and is_atom(c2) do
        "#{to_string(c1)}/#{to_string(c2)}"
      end

      defoverridable get_asset_pair: 1

      @spec format_asset_id(struct()) :: binary()
      def format_asset_id(res = %Resource{}) do
        get_asset_pair(res)
      end

      defoverridable format_asset_id: 1
    end
  end
end
