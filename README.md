# MarketClient

## Example Usage
```
res = MarketClient.Resource.new(:coinbase, {:crypto, {:eth, :usd}}, "", {:func, &IO.inspect/1})
res = res |> MarketClient.Socket.start()
res = res |> MarketClient.Socket.stop()

res = MarketClient.Resource.new(:binance, {:crypto, {:eth, :usdt}}, "", {:func, &IO.inspect/1})
res = res |> MarketClient.Socket.start()
res = res |> MarketClient.Socket.stop()

res = MarketClient.Resource.new(:polygon, {:forex, {:gbp, :aud}}, "xxxxxx", {:func, &IO.inspect/1})
res = res |> MarketClient.Socket.start()
res = res |> MarketClient.Socket.stop()
```
