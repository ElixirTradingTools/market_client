# FTX US API cURL Examples

```
curl 'https://ftx.us/api/markets/ETH/USD/candles?resolution=60&start_time=1621200276&end_time=1621201476'
curl 'https://ftx.us/api/markets/eth/usd/candles?resolution=60&limit=50&start_time=0&end_time=1621200227'
```

# Coinbase Candles
```
https://api.pro.coinbase.com/products/btc-usd/candles?start=2020-12-01T00%3A00%3A00.0Z&end=2021-01-01T00%3A00%3A00.0Z&granularity=86400
```

# Finnhub cURL Example

```
curl 'https://finnhub.io/api/v1/forex/symbol?exchange=oanda&token=c30u5m2ad3idae6u4540'
```

# Idea for Time Range Input

start = DateTime.new!(Date.new!(2019, 1, 1), ~T[00:00:00])
stop = DateTime.new!(Date.new!(2020, 1, 1), ~T[00:00:00])
range = {start, stop}
new(:coinbase_pro, {:crypto, :quotes, {:eth, :usd}, range})
|> Stream.each(&IO.puts/1)
|> Stream.run()
