defmodule Demo1 do
  alias MarketClient, as: MC

  def start_oanda(key, account_id) do
    {:oanda, [key: key, account_id: account_id]}
    |> MC.new({:forex, :quotes, {"eur", "usd"}})
    |> MC.stream()
    |> Stream.each(&IO.inspect/1)
    |> Stream.run()
  end

  def start_binance_us do
    :binance_us
    |> MC.new({:crypto, :quotes, {"btc", "usd"}})
    |> MC.stream()
    |> Stream.each(&IO.inspect/1)
    |> Stream.run()
  end

  def start_binance do
    :binance
    |> MC.new({:crypto, :quotes, {"btc", "usdt"}})
    |> MC.stream()
    |> Stream.each(&IO.inspect/1)
    |> Stream.run()
  end

  def start_coinbase_pro do
    :coinbase_pro
    |> MC.new({:crypto, :quotes, {"btc", "usd"}})
    |> MC.stream()
    |> Stream.each(&IO.inspect/1)
    |> Stream.run()
  end
end
