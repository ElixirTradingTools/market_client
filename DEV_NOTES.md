# FTX US API cURL Examples

```
curl 'https://ftx.us/api/markets/ETH/USD/candles?resolution=60&start_time=1621200276&end_time=1621201476'
curl 'https://ftx.us/api/markets/eth/usd/candles?resolution=60&limit=50&start_time=0&end_time=1621200227'
```

start = DateTime.new!(Date.new!(2019, 1, 1), ~T[00:00:00])
stop = DateTime.new!(Date.new!(2020, 1, 1), ~T[00:00:00])
range = {start, stop}
new(:coinbase_pro, {:crypto, :quotes, {:eth, :usd}, range})
|> Stream.each(&IO.puts/1)
|> Stream.run()
