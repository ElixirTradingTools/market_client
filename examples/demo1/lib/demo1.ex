defmodule Demo1 do
  alias MarketClient, as: MC

  @message_handler &IO.puts/1

  def start_oanda(key, account_id) do
    {:oanda, [key: key, account_id: account_id]}
    |> MC.new({:forex, :quotes, {"eur", "usd"}})
    |> MC.Stream.new()
    |> Stream.each(@message_handler)
    |> Stream.run()
  end

  def start_binance_us do
    :binance_us
    |> MC.new({:crypto, :quotes, {"btc", "usd"}})
    |> MC.Stream.new()
    |> Stream.each(@message_handler)
    |> Stream.run()
  end

  def start_binance do
    :binance
    |> MC.new({:crypto, :quotes, {"btc", "usdt"}})
    |> MC.Stream.new()
    |> Stream.each(@message_handler)
    |> Stream.run()
  end

  def start_coinbase_pro do
    :coinbase_pro
    |> MC.new({:crypto, :quotes, {"btc", "usd"}})
    |> MC.Stream.new()
    |> Stream.each(@message_handler)
    |> Stream.run()
  end

  def multi do
    Process.spawn(fn -> start_coinbase_pro() end, [:link])
    Process.spawn(fn -> start_binance_us() end, [:link])
    Process.spawn(fn -> start_binance() end, [:link])
    :observer.start()
  end
end
