defmodule Demo1 do
  alias MarketClient, as: MC

  @message_handler &IO.inspect/1

  def start_oanda(key, account_id) do
    {:oanda, [key: key, account_id: account_id]}
    |> MC.new({:forex, :quotes, {:eur, :usd}}, @message_handler)
    |> MC.start()
  end

  def start_binance_us do
    :binance_us
    |> MC.new({:crypto, :quotes, {:btc, :usd}}, @message_handler)
    |> MC.start()
  end

  def start_binance do
    :binance
    |> MC.new({:crypto, :quotes, {:btc, :usdt}}, @message_handler)
    |> MC.start()
  end

  def start_coinbase do
    :coinbase
    |> MC.new({:crypto, :quotes, {:btc, :usd}}, @message_handler)
    |> MC.start()
  end
end
