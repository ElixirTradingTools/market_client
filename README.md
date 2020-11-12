# MarketClient

## Example Usage
```
res = MarketClient.Resource.new(:coinbase, {:crypto, {:eth, :usd}}, "", {:func, &IO.inspect/1})
{:ok, pid} = MarketClient.Socket.start_link(res)
MarketClient.Socket.start(pid, res)
MarketClient.Socket.stop(pid, res)

res = MarketClient.Resource.new(:binance, {:crypto, {:eth, :usdt}}, "", {:func, &IO.inspect/1})
{:ok, pid} = MarketClient.Socket.start_link(res)
MarketClient.Socket.start(pid, res)
MarketClient.Socket.stop(pid, res)

res = MarketClient.Resource.new(:polygon, {:forex, {:gbp, :aud}}, "xxxxxx", {:func, &IO.inspect/1})
{:ok, pid} = MarketClient.Socket.start_link(res)
MarketClient.Socket.start(pid, res)
MarketClient.Socket.stop(pid, res)
```
