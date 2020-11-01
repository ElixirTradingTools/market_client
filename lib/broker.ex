defmodule MarketClient.Broker do
  alias MarketClient.Resource
  alias Jason, as: J
  alias Enum, as: E

  # ETH-USD, ETH-EUR
  @coinbase_url "wss://ws-feed.pro.coinbase.com"
  @polygon_url "wss://socket.polygon.io/stocks"

  def url(:coinbase), do: @coinbase_url
  def url(:polygon), do: @polygon_url

  # defp coinbase_auth(key), do: %{"k" => key}

  defp coinbase_sub(pair) when is_binary(pair) do
    %{
      "type" => "subscribe",
      "product_ids" => [pair],
      "channels" => [
        "heartbeat",
        %{
          "name" => "ticker",
          "product_ids" => [pair]
        }
      ]
    }
  end

  defp coinbase_unsub(pair) when is_binary(pair) do
    %{
      "type" => "unsubscribe",
      "product_ids" => [pair],
      "channels" => [
        "level2",
        "heartbeat",
        %{
          "name" => "ticker",
          "product_ids" => [pair]
        }
      ]
    }
  end

  defp polygon_auth(key), do: %{"action" => "auth", "params" => key}
  defp polygon_sub(asset_id), do: %{"action" => "subscribe", "params" => asset_id}
  defp polygon_unsub(asset_id), do: %{"action" => "unsubscribe", "params" => asset_id}

  def subscribe(%Resource{api_key: api_key, asset_id: asset_id, broker: broker}) do
    case broker do
      :polygon -> [polygon_auth(api_key), polygon_sub(asset_id)]
      :coinbase -> [coinbase_sub(asset_id)]
    end
    |> E.map(&J.encode!/1)
  end

  def unsubscribe(%Resource{asset_id: asset_id, broker: broker}) do
    case broker do
      :polygon -> [polygon_unsub(asset_id)]
      :coinbase -> [coinbase_unsub(asset_id)]
    end
    |> E.map(&J.encode!/1)
  end
end
