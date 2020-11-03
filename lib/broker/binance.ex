defmodule MarketClient.Broker.Binance do
  alias MarketClient.Resource
  alias Jason, as: J

  def url(%Resource{asset_id: id}) do
    "wss://stream.binance.com:9443/ws/#{get_pair(id)}"
  end

  def get_pair({:crypto, {c1, c2}}) when is_atom(c1) and is_atom(c2),
    do: "#{to_string(c1)}#{to_string(c2)}"

  def format_asset_id(id), do: "#{get_pair(id)}@trade"

  def subscribe(%Resource{asset_id: id}) do
    %{
      "id" => 1,
      "method" => "SUBSCRIBE",
      "params" => [format_asset_id(id)]
    }
    |> J.encode!()
  end

  def unsubscribe(%Resource{asset_id: id}) do
    %{
      "id" => 1,
      "method" => "UNSUBSCRIBE",
      "params" => [format_asset_id(id)]
    }
    |> J.encode!()
  end
end
