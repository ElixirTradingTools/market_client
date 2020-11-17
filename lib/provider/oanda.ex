defmodule MarketClient.Provider.Oanda do
  import MarketClient.Shared
  alias MarketClient.Resource
  alias MarketClient.Net.HTTP

  def url(%Resource{broker: {:oanda, %{practice: p}}}) do
    mode = if(p, do: "practice", else: "trade")
    "https://api-fx#{mode}.oanda.com"
  end

  def path(%Resource{asset_id: {:forex, {c1, c2}}}) when is_atom(c1) and is_atom(c2) do
    str = format_asset_id(c1, c2)
    "/v3/instruments/#{str}/orderBook"
  end

  def format_asset_id(c1, c2) when is_atom(c1) and is_atom(c2) do
    "#{upcase_atom(c1)}_#{upcase_atom(c2)}"
  end

  def headers(%Resource{broker: {:oanda, %{key: k}}}) when is_binary(k) do
    [
      {"authorization", "bearer: #{k}"},
      {"keep-alive", "true"}
    ]
  end

  def start_link(res = %Resource{}) do
    HTTP.start_link({:https, url(res), 443})
  end

  def start(pid, res = %Resource{}) do
    HTTP.request(pid, path(res), headers(res))
  end
end
