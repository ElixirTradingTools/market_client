defmodule MarketClient.Provider.IexCloud do
  import MarketClient.Shared
  alias MarketClient.Resource
  # alias MarketClient.Net.WebSocket
  # alias Jason, as: J
  # alias Enum, as: E

  def url(%Resource{broker: {_, %{key: api_key}}, asset_id: asset_id = {class, _}}) do
    base = "https://cloud-sse.iexapis.com/stable"

    case class do
      :forex -> "#{base}/forex"
      :stock -> "#{base}/stocks"
      :crypto -> "#{base}/cryptoBook?symbols=#{format_asset_id(asset_id)}&token=#{api_key}"
    end
  end

  def format_asset_id({class, {c1, c2}}) when class in [:forex, :crypto] do
    "#{upcase_atom(c1)}#{upcase_atom(c2)}"
  end
end
