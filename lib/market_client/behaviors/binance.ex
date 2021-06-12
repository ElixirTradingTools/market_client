defmodule MarketClient.Behaviors.Binance do
  defmacro __using__(_) do
    quote do
      alias MarketClient.Resource

      @spec start(Resource.t()) :: no_return

      @valid_data_types MarketClient.valid_data_types()

      def start(res = %Resource{}) do
        res |> MarketClient.Buffer.start()
        res |> __MODULE__.Ws.ws_start()
      end

      def stop(res = %Resource{}) do
        res |> MarketClient.Buffer.stop()
        res |> __MODULE__.Ws.ws_stop()
      end

      def validate(res = %Resource{}) do
        case res.asset_id do
          {:crypto, _, _} -> validate_crypto(res)
          {:forex, _, _} -> {:error, "invalid asset class: :forex"}
          {:stock, _, _} -> {:error, "invalid asset class: :stock"}
          {c, _, _} -> {:error, "invalid asset class: #{inspect(c)}"}
        end
      end

      defp validate_crypto(res) do
        case res.asset_id do
          {_, dt, _} when dt in @valid_data_types -> validate_currency_pair(res)
          {_, dt, _} -> {:error, "invalid data-type: #{inspect(dt)}"}
        end
      end

      defp validate_currency_pair(res) do
        case res.asset_id do
          {_, _, {a, b}} when is_binary(a) and is_binary(b) -> {:ok, res}
          {_, _, pair} -> {:error, "invalid currency pair: #{inspect(pair)}"}
        end
      end
    end
  end
end
