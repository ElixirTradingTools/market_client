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

MarketClient.new(:binance_us, {:crypto, :ohlcv_1minute, {:eth, :usd}}, &IO.inspect/1)
|> MarketClient.ws_start()

MarketClient.new({:polygon, [key: "XXXX"]}, {:stock, :full_tick, "msft"}, &IO.inspect/1)
|> MarketClient.ws_start()

MarketClient.new({:polygon, [key: "XXXX"]}, {:forex, :full_tick, {:gbp, :aud}}, &IO.inspect/1)
|> MarketClient.ws_start()

MarketClient.new(
    {:oanda, [account_id: "X", key: "X"]},
    {:forex, :ohlc_1minute, {:aud, :nzd}},
    &IO.inspect/1
)
|> MarketClient.http_start()
```

## How to cURL FTX US API

```
curl 'https://ftx.us/api/markets/ETH/USD/candles?resolution=60&start_time=1621200276&end_time=1621201476'
curl 'https://ftx.us/api/markets/eth/usd/candles?resolution=60&limit=50&start_time=0&end_time=1621200227'
```
