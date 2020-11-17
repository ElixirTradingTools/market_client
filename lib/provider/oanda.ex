defmodule MarketClient.Provider.Oanda do
  import MarketClient.Shared
  alias MarketClient.Resource
  alias MarketClient.Net.HTTP

  def url(%Resource{broker: {:oanda, %{practice: p}}}) do
    mode = if(p, do: "practice", else: "trade")
    "https://api-fx#{mode}.oanda.com"
  end

  def path(:pricing, %Resource{asset_id: {:forex, {c1, c2}}, broker: {:oanda, %{account_id: aid}}})
      when is_atom(c1) and is_atom(c2) and aid != nil do
    pair = format_asset_id(c1, c2)
    "/v3/accounts/#{aid}/pricing?instruments=#{pair}"
  end

  def format_asset_id(c1, c2) when is_atom(c1) and is_atom(c2) do
    "#{upcase_atom(c1)}_#{upcase_atom(c2)}"
  end

  def headers(%Resource{broker: {:oanda, %{key: k}}}) when is_binary(k) do
    [
      {"authorization", "bearer #{k}"},
      {"keep-alive", "true"}
    ]
  end

  def start_link(res = %Resource{}) do
    HTTP.start_link({:https, url(res), 443})
  end

  def start(pid, res = %Resource{handler: {:func, func}}) do
    HTTP.poll(pid, {"GET", path(:pricing, res), headers(res), ""}, {34, func})
  end

  def stop(pid, _) do
    if Process.alive?(pid) do
      HTTP.halt(pid)
      HTTP.die(pid)
    end
  end
end
