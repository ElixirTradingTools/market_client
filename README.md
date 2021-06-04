# MarketClient

A simple universal client for various brokers and data providers. Currently includes (to various degrees):
* Coinbase
* Binance
* Binance US
* FTX
* FTX US
* Polygon
* Oanda

The project is work-in-progress. Features are being added on an as-needed basis. You are encouraged to
use this module in your projects and submit merge requests for any features you'd like to add or modify.
Elixir makes it very easy to use a local directory as a dependency, so clone this project and then add
the following to your `mix.ex` dependencies.
```
{:market_client, path: "/your/local/path/to/this/project"}
```

## Example Usage
```
MarketClient.new(:coinbase, {:crypto, :full_tick, {:eth, :usd}}, &IO.inspect/1)
|> MarketClient.ws_start()

MarketClient.new(:binance, {:crypto, :full_tick, {:eth, :usdt}}, &IO.inspect/1)
|> MarketClient.ws_start()

MarketClient.new(:binance_us, {:crypto, :ohlc_1minute, {:eth, :usd}}, &IO.inspect/1)
|> MarketClient.ws_start()

opts = [key: "X"]
MarketClient.new({:polygon, opts}, {:stock, :full_tick, "msft"}, &IO.inspect/1)
|> MarketClient.ws_start()

opts = [key: "X"]
MarketClient.new({:polygon, opts}, {:forex, :full_tick, {:gbp, :aud}}, &IO.inspect/1)
|> MarketClient.ws_start()

opts = [key: "X", account_id: "X"]
MarketClient.new({:oanda, opts}, {:forex, :ohlc_1minute, {:aud, :nzd}}, &IO.inspect/1)
|> MarketClient.start()
```
